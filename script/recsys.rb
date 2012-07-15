# -*- encoding : utf-8 -*-
module CRF
  def dist_euclidean(c1, c2, cruco)
    # Get the list of mutually rated items
    si={}
    cruco.each do |uid, u|
      if u.include?(c1) && u.include?(c2)
        si[uid] = 1
      end
    end
    
    # Find the number of elements
    n = si.size
    # if they are no ratings in common, return 0
    return 0 if n == 0
    
    # Add up all the preferences
    sumEuc = 0.0
    si.each do |uid, u|
      sumEuc += (cruco[uid][c1]-cruco[uid][c2]) ** 2
    end
    return 1/(1+sumEuc)
  end
  
  def dist_pearson(c1, c2, cruco)
    # Get the list of mutually rated items
    si={}
    cruco.each do |uid, u|
      if u.include?(c1) && u.include?(c2)
        si[uid] = 1
      end
    end
    
    # Find the number of elements
    n = si.size
    # if they are no ratings in common, return 0
    return 0 if n == 0
    
    # Add up all the preferences
    sum1 = 0.0
    sum2 = 0.0
    sum1Sq = 0.0
    sum2Sq = 0.0
    pSum = 0.0
    sumEuc = 0.0
    si.each do |uid, u|
      sum1 += cruco[uid][c1]
      sum2 += cruco[uid][c2]
      sum1Sq += cruco[uid][c1]**2
      sum2Sq += cruco[uid][c2]**2
      pSum += cruco[uid][c1] * cruco[uid][c2]
    end
    
    # Calculate Pearson score
    num=pSum-(sum1*sum2/n)
    den=Math.sqrt((sum1Sq - sum1**2/n)*(sum2Sq-sum2**2/n))
    return 0 if den == 0
    v_i = num/den
     (v_i+1 - 0)/(2.0-0)*(1.0 - 0) + 0
  end
  
  def predict(uid, cid, simils, user_ratings)
    sum_simil = 0.0
    weighted_simil = 0.0
     (simils.keys - [cid]).each do |ccid|
      next unless user_ratings.include?(uid) && user_ratings[uid].include?(ccid)
      
      # puts "#{cid} not in simils!!!" if !simils.keys.include?(cid)
      # puts "#{ccid} not in simils#{cid}!!!" if !simils[cid].keys.include?(ccid)
      sum_simil += simils[cid][ccid]
      weighted_simil += simils[cid][ccid] * user_ratings[uid][ccid]
    end
    return 5 if sum_simil == 0
    
    prediction = weighted_simil / sum_simil
    return prediction
  end
  
  def compute_similarity_matrix(items, users, scored_items_by_users)
    total = (contents.size ** 2) # / 2 - contents.size
    puts "total: #{total}"
    i = 0.0
    prev_pcent = -1
    contents.each do |cid|
      simils[cid] = Hash[*(k_ids).zip([0.0]*k_ids_size).flatten]
       (contents - [cid]).each do |ccid|
        i += 1
        if ccid > cid # we need to calculate it
          simils[cid][ccid] = dist(cid, ccid, cr_u_content)
        else # we already calculated it, we are in the lower part of the matrix
          # puts "computing distance between #{cid}, #{ccid}"
          simils[cid][ccid] = simils[ccid][cid]
        end
      end
      if (i/total*100).to_i != prev_pcent
        prev_pcent = (i/total*100).to_i
        puts "#{prev_pcent}%"
      end
      
    end
    
  end
  
  def build_scored_items_by_users(items, users)
    cr_u_content = {}
    
    total = users_involved.size * real_contents.size
    i = 0.0
    prev_pcent = -1
    users_involved.each do |uid|
      cr_u_content[uid] ||= {}
      u = User.find(uid)
      real_contents.each do |c|
        i += 1
        cr_u_content[u.id][c.id] = u.latent_rating(c)
        if (i/total*100).to_i != prev_pcent
          prev_pcent = (i/total*100).to_i
          puts "#{prev_pcent}%"
        end
      end
    end
    cr_u_content
  end
end

cache = "rec.model.3.weeks"
cond_cratings = 'lastseen_on >= now() - \'3 days\'::interval'
cond_cratings2 = 'created_on >= now() - \'3 weeks\'::interval and content_id in (select id from contents where created_on >= now() - \'2 week\'::interval)'

real_contents = Content.find(:all, :conditions => "id in (select distinct(content_id) from content_ratings where #{cond_cratings2})")
contents = real_contents.collect {|c| c.id}.sort
cratings = ContentRating.find(:all, :conditions => cond_cratings2)
users_involved = cratings.collect {|cr| cr.user_id}.compact.sort

puts "contents: #{contents.size}"
puts "users: #{users_involved.size}"

train = real_contents[0..(real_contents.size*0.66).ceil]
test = real_contents[(real_contents.size*0.66).ceil..-1]

cr_u_contents = build_scored_items_by_users(real_contents, users_involved)
puts "first stage done, computing matrix"

simils = {}
u_ids = users_involved
u_ids_size = u_ids.size
k_ids = contents
k_ids_size = k_ids.size

puts "users: #{u_ids_size} | contents: #{k_ids_size}"

if !File.exists?(cache)
  simils = compute_similarity_matrix(contents, users, cr_u_contents)
  File.open(cache, "wb").write(Marshal::dump(simils))
else
  simils = Marshal::load(File.open(cache))
end


THRESHOLD_TO_RECOMMEND = 6.0

# now let's measure accuracy against rated contents
sum_sq_err = 0.0
precision_error = 0.0
precision_total = 0.0
recall_error = 0.0
gold_good = 0.0
recall_total = 0.0
i = 0
cratings.each do |cr|
  next if cr.user_id.nil?
  next unless test.include?(cr.content_id)
  
  gold_good += 1 if cr.rating >= THRESHOLD_TO_RECOMMEND
  
  i += 1
  prediction = predict(cr.user_id, cr.content_id, simils, cr_u_content)
  # puts "prediction is: #{prediction}"
  if cr.rating >= THRESHOLD_TO_RECOMMEND
    recall_total += 1
  end
  
  if prediction > 6
    puts "I would recommend (#{prediction}>#{THRESHOLD_TO_RECOMMEND}) #{cr.content.name} to #{cr.user.login} (he voted it as #{cr.rating})"
  else
    puts "NOT recommend (#{prediction}<#{THRESHOLD_TO_RECOMMEND}) #{cr.content.name} to #{cr.user.login} (he voted it as #{cr.rating})"
  end
  
  if prediction >= THRESHOLD_TO_RECOMMEND && cr.rating < THRESHOLD_TO_RECOMMEND or prediction < THRESHOLD_TO_RECOMMEND && cr.rating >= THRESHOLD_TO_RECOMMEND
    precision_error += 1
  end
  if prediction < THRESHOLD_TO_RECOMMEND && cr.rating >= THRESHOLD_TO_RECOMMEND
    #rec_error += 1
  end
  
  sum_sq_err += (cr.rating - prediction) ** 2
  # puts sum_sq_err
end

precision_total = i

puts "MSE: #{sum_sq_err / i}"
puts "Accuracy/Recall: #{1-precision_error/precision_total}/#{1-precision_error/recall_total}"
