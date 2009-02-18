require 'rubystats/normal_distribution'

#if !defined?(Infinity)
#  Infinity = 1.0/0 
#require 'vendor/plugins/ruby_mixings/lib/ruby_mixings.rb'
#require 'vendor/plugins/ruby_mixings/init.rb'
#end

module Bandit
  class BanditStrategy
    def initialize(levers, epsilon, horizon)
      @levers = levers
      @rewards = {}
      # p @levers
      # raise "#{@levers}"
      @levers.each { |lever_id| @rewards[lever_id] = {'avg' => 0.0, 't' => {}} }
      @epsilon = epsilon
      @horizon = horizon
      @leverSigmaSum = 0
      @leverMeanSum = 0
      @twiceObservedLeverCount = 0
    end
    
    def get_lever(round)
      @round = round
      @observedLeverCount ||= 0
      @twiceObservedLeverCount ||= 0
      lever
    end
    
    def observationCounts(id)
      @rewards[id] ? @rewards[id]['t'].values.size : 0
    end
    
    def load_rewards_for_lever_from_bit_string(lever_id, string)
      # en string - 0 1
      return if string.nil?
      @rewards[lever_id] = {'t' => [], 'avg' => 0.0 }
      round = 0
      string.split('').each do |c|
        round += 1
        next if c == '-'
        @rewards[lever_id]['t'][round] = c.to_i
      end
      @rewards[lever_id]['avg'] = @rewards[lever_id]['t'].mean if @rewards[lever_id]['t'].size > 0
    end
    
    def rewards
      @rewards
    end
    
    def observe_result(t, chosen_lever, reward)
      # puts "observe_result(#{t}, #{chosen_lever}, #{reward})"
      
      # updates "rewards" array with the current reward observer for lever "lever" at round "t"
      @rewards[chosen_lever] ||= {'avg' => 0, 't' => {}}
      
      @observedLeverCount += 1 if @rewards[chosen_lever]['t'].size == 0 
      @twiceObservedLeverCount += 1 if @rewards[chosen_lever]['t'].size == 1 
      
      if @rewards[chosen_lever]['t'].values.size > 0
        @leverMeanSum -= @rewards[chosen_lever]['avg']
      end
      
      @leverSigmaSum -= lever_sigma(chosen_lever) if @rewards[chosen_lever]['t'].values.size > 1
      
      @rewards[chosen_lever]['t'][t] = reward
      @rewards[chosen_lever]['avg'] = @rewards[chosen_lever]['t'].values.mean
      # puts "after observing: @rewards[#{chosen_lever}]"
      # p @rewards[chosen_lever]
      
      if @rewards[chosen_lever]['t'].values.size > 0
        @leverMeanSum += @rewards[chosen_lever]['avg']
      end
      
      @leverSigmaSum += lever_sigma(chosen_lever) if @rewards[chosen_lever]['t'].values.size > 1
    end
    
    def lever_sigma(lever_id)
      # mean = rewardSums[index] / observationCounts(index);
      mean = @rewards[lever_id]['avg']
      variance = Math.variance(@rewards[lever_id]['t'].values)
      Math.sqrt(variance)
    end
    
    def lever
      # levers is an array of ids
      # rewards is a dictionary. Keys are the ids of the arrays and the value contains past rewards and the round in which they were given
      # history[0]['avg'] = average of rewards already taken
      # history[0]['t'][0] = reward at round 0
      # horizon is the number of rounds
      # t is the current round
      #
      # returns the lever to choose
      raise "Abstract method"
    end
    
    protected
    def pick_best_average_reward
      # returns the id of the lever with the max average reward. In case of no maximum returns nil
      best_lever_ids = []
      max = nil
      @rewards.each do |lever_id, history|
        if history['avg'] && (max.nil? || history['avg'] > max)
          max = history['avg']
          best_lever_ids = [lever_id]
        elsif history['avg'] && (max.nil? || history['avg'] == max)
          best_lever_ids<< lever_id
        end
      end
      best_lever_ids.random 
    end    
  end
  
  class EpsilonGreedy < BanditStrategy
    def lever  
      if @rewards.size == 0 || Kernel.rand <= @epsilon  # exploration
        @levers.random
      else # exploitation
        pick_best_average_reward
      end
    end  
  end
  
  class EpsilonFirst < BanditStrategy
    def lever
      if @round < @epsilon * @horizon # exploration
        @levers.random
      else # exploitation
        pick_best_average_reward
      end
    end
  end
  
  class EpsilonDecreasing < BanditStrategy 
    def lever
      round_denom = @round > 0 ? @round : 1
      @cur_epsilon = [1, @epsilon / round_denom].min   
      if Kernel.rand <= @cur_epsilon # exploration
        @levers.random
      else # exploitation
        pick_best_average_reward
      end
    end
  end
  
  class LeastTaken < BanditStrategy
    def lever
      lti = least_taken_info 
      if Kernel.rand <= 4 * @epsilon / (4 + lti['times']**2)
        lti['lever']
      else
        pick_best_average_reward
      end
    end
    
    private
    def least_taken_info
      best_lever_ids = []
      min = nil
      @rewards.each do |lever_id, history|
        if history['avg'] && (max.nil? || history['times'] < min)
          min = history['times']
          best_lever_ids = [lever_id]
        elsif history['avg'] && (max.nil? || history['times'] == min)
          best_lever_ids<< lever_id
        end
      end
      best_lever_ids.random 
    end
  end
  
  class Poker < BanditStrategy
    def lever
      # initialization: observing at least two levers twice
      if @observedLeverCount < 1 || @leverSigmaSum == 0 then        
        if @lastPulledLever && observationCounts(@lastPulledLever) == 1
          return @lastPulledLever 
        else
          @lastPulledLever = @levers.random
          return @lastPulledLever
        end
      end
      
      # computing the delta
      means = []
      @rewards.each do |lever_id, history|      
        means.push(history['avg']) if history && history['t'].values.size > 0
      end
      
      means = means.sort
      k =  Math.sqrt(means.size).ceil.to_i
      delta = means[means.size - 1].to_f - means[means.size - k]
      maxMean = means[means.size - 1].to_f
      
      # if k equals 1, then just play randomly (delta could not be estimated)
      return @levers.random if (k <= 1)   
      delta /= (k - 1)
      
      # computing the prices of the observed levers
      maxPrice = (-1) * Infinity
      maxPriceIndex = -1 # dummy initialization
      
      @levers.each do |i|
        if(observationCounts(i) > 0)
          mean = @rewards[i]['avg']
          
          # empirical estimate of the standard deviation is avaiblable
          sigma = 0.0
          if(observationCounts(i) > 1)
            sigma = lever_sigma(i)
            sigma = @leverSigmaSum / @twiceObservedLeverCount if (sigma == 0)               
            # using the avg standard deviation amoung the levers
          else
            sigma = @leverSigmaSum / @twiceObservedLeverCount
          end
          
          # computing an estimate of the lever optimality probability
          cnd = Rubystats::NormalDistribution.new(mean, sigma / Math.sqrt(observationCounts(i)))
          proba = (1 - cnd.cdf(maxMean + delta))
          price = mean + @horizon * delta * proba # empirical mean + estimated long term gain
          
          if(maxPrice < price)
            maxPrice = price
            maxPriceIndex = i
          end
        end # if observationCounts[i] > 0
      end # LeverCount.times
      
      # computing the price for the unobserved levers
      if(@observedLeverCount < @levers.size)
        unobservedPrice = @leverMeanSum / @observedLeverCount + @horizon * delta / @observedLeverCount
        #puts "unobservedPrice = #{@leverMeanSum} / #{@observedLeverCount} + #{@horizon} * #{delta} / #{@observedLeverCount}"
        #puts "unobservedPrice: #{unobservedPrice}"
        if(unobservedPrice > maxPrice)
          maxPrice = unobservedPrice
          
          # Choosing randomly an unobserved lever
          # TODO this is gonna break if we use ids for levers that have gaps inside
          uIndex = Kernel.rand(@levers.size - @observedLeverCount)
          uCount = 0
          @levers.size.times do |i|
            if(observationCounts(i) == 0)
              if(uCount == uIndex)
                maxPriceIndex = i
                break
              else 
                uCount += 1
              end
            end
          end 
        end
      end
      
      @lastPulledLever = maxPriceIndex
      return maxPriceIndex
    end
  end
  
  class SoftMax < BanditStrategy
    TEMPERATURE = 0.05
    def temperature
      TEMPERATURE
    end
    def lever
      probs = {}
      # 1. first calculate denominator
      denom = 0
      @levers.each do |lever_id, history|
        denom += Math.exp((history ? history['avg'] : 1) / temperature)
      end
      
      # 2. now we calculate probability ranges for each lever
      prev_prob = 0.0
      
      @levers.each do |lever_id, history|
        cur_prob = Math.exp((history ? history['avg'] :  1) / temperature) / denom
        probs[lever_id] = prev_prob + cur_prob
        prev_prob = probs[lever_id] 
      end
      
      # 3. and now we choose which lever to use this round
      rand_v = Kernel.rand
      acum_prob = 0
      last_lever_id = nil
      @levers.each do |lever_id, history|
        last_lever_id = lever_id
        if rand_v <= acum_prob || acum_prob >= 1.0
          return lever_id
        else
          acum_prob += probs[lever_id]
        end
      end
      puts "unreachable point #{acum_prob}"
      last_lever_id
    end
  end
  
  class DecreasingSoftMax < SoftMax
    def temperature
      TEMPERATURE / (@round == 0 ? 1 : @round)
    end
  end
  
  class SoftMix < SoftMax
    def temperature
      t = (@round == 0 ? 1 : @round)
      TEMPERATURE * (Math.log(t) / t)
    end
  end
end


def read_randomized_data
  data = []
  File.open("lib/univ-latencies.txt") do |f|
    f.read.split("\n").each do |l|
      data<< l.split(',')
    end
  end
  data = data.reverse
  data.pop # remove first line
  data
end

SOY_UN_PUTO_LAMER = false
if SOY_UN_PUTO_LAMER
  # load data
  t_start = Time.now.to_i
  
  avg_grand_total = 0
  time_to_run_tests = 1000
  rounds_per_test = 130
  data = read_randomized_data
  time_to_run_tests.times do |i_round|
    new_r = Kernel.rand
    data = data.sort_by{new_r}
    levers = Array.new(data[0].size) { |i| i } 
    latency_sum = 0
    gambler = Bandit::EpsilonGreedy.new(levers, 0.5, rounds_per_test) # rounds_per_test is the horizon
    
    rounds_per_test.times do |round|
      lever = gambler.get_lever(round)
      # puts "round #{round} | lever #{lever}"
      get_reward = data[round][lever].to_i * (-1) # son latencias
      gambler.observe_result(round, lever, get_reward)
      latency_sum += data[round][lever].to_i
    end
    
    puts "round (#{i_round}) total latency: #{latency_sum} | avg: #{latency_sum/rounds_per_test.to_f}"
    avg_grand_total += latency_sum/rounds_per_test.to_f
  end
  
  puts "\n\nDecreasingSoftMax(0.05, #{time_to_run_tests}, #{rounds_per_test}) avg latency: #{avg_grand_total/time_to_run_tests.to_f}"
  puts "Time taken: #{Time.now.to_i - t_start}s"
end