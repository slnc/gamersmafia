module Ads
  module SlotsBehaviours
    ROUNDS_FIELD_SIZE = 50000
    VALID_BEHAVIOURS = ['Random', 'EpsilonGreedy', 'EpsilonFirst', 'EpsilonDecreasing', 'LeastTaken', 'SoftMax', 'Poker'] 
    
    class AbstractBehaviour
      def initialize(ads_slot)
        @ads_slot = ads_slot
      end
      
      def get_ad(game_id)
        raise "abstract method"
      end
    end
    
    class Random < AbstractBehaviour
      def get_ad(game_id)
        @ads_slot.ads_slots_instances.find(:first, :conditions => 'deleted = \'f\'', :order => 'RANDOM()', :include => :ad) # self.ads.find(:a)
      end
    end
    
    class Bandido < AbstractBehaviour
      def behaviour_class
        raise "abstract method"
      end
      
      def epsilon
        nil
      end
      
      def get_ad(game_id)
        # uso abtest_treatment como identificador de juego
        # el round indicado por la columna es el último round jugado
        # la cuenta empieza desde 0
        # TODO init abtest_treaments here
        dbi = User.db_query("UPDATE stats.bandit_treatments SET round = round + 1 where abtest_treatment = '#{game_id}'; SELECT * FROM stats.bandit_treatments WHERE abtest_treatment = '#{game_id}'")
        if dbi.size == 0 # game not initiated yet
          # game initialization
          # Bandido.new(:hid => game_id) # User.db_query
          in1 = ''
          in2 = ''
          @ads_slot.ads.count(:conditions => 'deleted = \'f\'').times do |t|
            in1 << "lever#{t}_reward, "
            #if WINDOWS # TODO postgres 8.3 en windows no funciona
            in2 << "'#{'-' * ROUNDS_FIELD_SIZE}', "
            #else
            #  in2 << "lpad('', #{ROUNDS_FIELD_SIZE}, '0')::bit(#{ROUNDS_FIELD_SIZE}), "
            #end
          end
          dbi = User.db_query("INSERT INTO stats.bandit_treatments (behaviour_class, round, abtest_treatment, #{in1[0..-3]}) VALUES ('#{self.behaviour_class}', 0, '#{game_id}', #{in2[0..-3]}); SELECT * FROM stats.bandit_treatments WHERE abtest_treatment = '#{game_id}';")
        end
        
        dbi = dbi[0]
        
        #raise "ads_slot #{@ads_slot.id}"
        num_levers = @ads_slot.ads.count(:conditions => 'deleted = \'f\'')
        return nil if num_levers == 0
        levers = Array.new(num_levers) { |i| i }
        
        cur_round = dbi['round'].to_i
        #raise "calling #{self.behaviour_class} with #{levers}, #{self.epsilon}, #{ROUNDS_FIELD_SIZE}"
        gambler = Bandit.const_get(self.behaviour_class).new(levers, self.epsilon, ROUNDS_FIELD_SIZE) # rounds_per_test is the horizon
        
        lever = gambler.get_lever(cur_round) # esto devuelve el index del ad a mostrar
        # raise "lever #{lever} taken"
        num_levers.times do |i|
          gambler.load_rewards_for_lever_from_bit_string(i, dbi["lever_#{i}_reward"])  
        end
        
        gambler.observe_result(cur_round, lever, 0) # asumimos que no se pincha
        
        
        # actualizamos la bd solo para el lever tocado
        # select lpad('', 500, '0')::bit(500);
        # ponemos a 0 el bit correspondiente al resultado del round actual, si luego el usuario pincha lo cambiamos a 1
        # innecesario ya que inicializamos al maximo de rounds a jugar
        #if WINDOWS
        #  # new_data = gambler.rewards[lever]['t']
        t_rewards = gambler.rewards[lever]['t']
        #  p t_rewards
        
        User.db_query("UPDATE stats.bandit_treatments 
                          SET lever#{lever}_reward = overlay(lever#{lever}_reward placing '0' from #{cur_round+1} for 1) 
                        WHERE abtest_treatment = '#{game_id}'")
        # else
        #  User.db_query("UPDATE stats.bandit_treatments 
        #                  SET lever#{lever}_reward = lever#{lever}_reward | (lpad('', #{round}, '0') || '0')::bit(#{round + 1}) 
        #                WHERE abtest_treatment = '#{game_id}'")
        #end

        ad = @ads_slot.ads_slots_instances.find(:all, :conditions => 'deleted = \'f\'', :order => 'ads.id', :limit => 1, :offset => lever, :include => :ad)[0] # self.ads.find(:a)
        ad.ad.tmpinfo("ab#{game_id}r#{cur_round.to_s}l#{lever}")
        ad
      end
    end
    
    class EpsilonGreedy < Bandido
      def behaviour_class
        'EpsilonGreedy'
      end
      
      def epsilon
        0.10
      end
    end
    
    class EpsilonFirst < Bandido
      def behaviour_class
        'EpsilonFirst'
      end
      
      def epsilon
        0.10
      end
    end
    
    class EpsilonDecreasing < Bandido
      def behaviour_class
        'EpsilonDecreasing'
      end
      
      def epsilon
        5.0
      end
    end
    
    class LeastTaken < Bandido
      def behaviour_class
        'LeastTaken'
      end
      
      def epsilon
        1.0
      end
    end
    
    class SoftMax < Bandido
      def behaviour_class
        'SoftMax'
      end
      
      def epsilon
        0.10
      end
    end
    
    class Poker < Bandido
      def behaviour_class
        'Poker'
      end
    end
  end
end