cond_cratings = 'created_on >= now() - \'3 months\'::interval'
real_contents = Content.find(:all, :conditions => "id in (select distinct(content_id) from content_ratings where #{cond_cratings})", :include => :user)
contents = real_contents.collect {|c| c.id}.sort

train = contents[0..(contents.size*0.66).ceil]
test = contents[(contents.size*0.66).ceil..-1]

cratings = ContentRating.find(:all, :conditions => cond_cratings)
cr_u_content = {}
cratings.each do |cr|
  cr_u_content[cr.user_id] ||= {}
  cr_u_content[cr.user_id][cr.content_id] = cr.rating if train.include?(cr.content_id)
end


# p cr_u_content

simils = {}
u_ids = cratings.collect { |c| c.user_id }
u_ids_size = u_ids.size
k_ids = contents
k_ids_size = k_ids.size

puts "users: #{u_ids_size} | contents: #{k_ids_size}"

#contents.each do |c|
#  simils[c.id] = Hash[*(k_ids-c.id).zip([0]*k_ids.size).flatten]
#  #c_word_bag = 
#  #base_w_vector = []
#  (contents - c).each do |rc|
#
#  end
#end
 

def dist(c1, c2, cruco)
	# Get the list of mutually rated items
	si={}
  cruco.each do |uid, u|
    #puts "checking if #{u} includes #{c1} and #{c2}"
    if u.include?(c1) && u.include?(c2)
      si[uid] = 1
    end
  end

  # p si
	# Find the number of elements
	n = si.size
#  puts "hoila"
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
    sumEuc += (cruco[uid][c1]-cruco[uid][c2]) ** 2
    #sum1 += cruco[uid][c1]
    #sum2 += cruco[uid][c2]
    #sum1Sq += cruco[uid][c1]**2
    #sum2Sq += cruco[uid][c2]**2
    #pSum += cruco[uid][c1] * cruco[uid][c2]
  end
return 1/(1+sumEuc)

#  puts "fooo"
	# Calculate Pearson score
	num=pSum-(sum1*sum2/n)
	den=Math.sqrt((sum1Sq - sum1**2/n)*(sum2Sq-sum2**2/n))
  return 0 if den == 0
	v_i = num/den
  (v_i+1 - 0)/(2.0-0)*(1.0 - 0) + 0
end

#critics={
#'Lisa Rose': {'Lady in the Water': 2.5, 'Snakes on a Plane': 3.5, 'Just My Luck': 3.0, 'Superman Returns': 3.5, 'You, Me and Dupree': 2.5, 'The Night Listener': 3.0},
#'Gene Seymour': {'Lady in the Water': 3.0, 'Snakes on a Plane': 3.5, 'Just My Luck': 1.5, 'Superman Returns': 5.0, 'The Night Listener': 3.0, 'You, Me and Dupree': 3.5},
#'Michael Phillips': {'Lady in the Water': 2.5, 'Snakes on a Plane': 3.0, 'Superman Returns': 3.5, 'The Night Listener': 4.0},
#'Claudia Puig': {'Snakes on a Plane': 3.5, 'Just My Luck': 3.0, 'The Night Listener': 4.5, 'Superman Returns': 4.0, 'You, Me and Dupree': 2.5},
#'Mick LaSalle': {'Lady in the Water': 3.0, 'Snakes on a Plane': 4.0, 'Just My Luck': 2.0, 'Superman Returns': 3.0, 'The Night Listener': 3.0, 'You, Me and Dupree': 2.0},
#'Jack Matthews': {'Lady in the Water': 3.0, 'Snakes on a Plane': 4.0, 'The Night Listener': 3.0, 'Superman Returns': 5.0, 'You, Me and Dupree': 3.5},
#'Toby': {'Snakes on a Plane':4.5,'You, Me and Dupree':1.0,'Superman Returns':4.0}}
#cr_u_content={
#10=> {1=> 2.5, 2=> 3.5, 3=> 3.0, 4=> 3.5, 5=> 2.5, 6=> 3.0},
#11=> {1=> 3.0, 2=> 3.5, 3=> 1.5, 4=> 5.0, 6=> 3.0, 5=> 3.5},
#12=> {1=> 2.5, 2=> 3.0, 4=> 3.5, 6=> 4.0},
#13=> {2=> 3.5, 3=> 3.0, 6=> 4.5, 4=> 4.0, 5=> 2.5},
#14=> {1=> 3.0, 2=> 4.0, 3=> 2.0, 4=> 3.0, 6=> 3.0, 5=> 2.0},
#15=> {1=> 3.0, 2=> 4.0, 6=> 3.0, 4=> 5.0, 5=> 3.5},
#16=> {2=>4.5,5=>1.0,4=>4.0}}
#
#contents = [1,2,3,4,5,6]
#k_ids = contents
#u_ids = [10,11,12,13,14,15,16]
#k_ids_size = k_ids.size
#simils = {}
## only using ratings
contents.each do |cid|
  simils[cid] = Hash[*(k_ids).zip([0.0]*k_ids_size).flatten]
  (contents - [cid]).each do |ccid|
    if ccid == cid
     next
elsif ccid > cid # we need to calculate it
			simils[cid][ccid] = dist(cid, ccid, cr_u_content)
else # we already calculated it, we are in the lower part of the matrix
    #puts "computing distance between #{cid}, #{ccid}"
    simils[cid][ccid] = simils[ccid][cid]
end
  end
end

# p simils

def predict(uid, cid, simils, user_ratings)
  sum_simil = 0.0
  weighted_simil = 0.0
  (simils.keys - [cid]).each do |ccid|
    next unless user_ratings[uid].include?(ccid)
    
      puts "#{cid} not in simils!!!" if !simils.keys.include?(cid)
      puts "#{ccid} not in simils#{cid}!!!" if !simils[cid].keys.include?(ccid)
    sum_simil += simils[cid][ccid]
    weighted_simil += simils[cid][ccid] * user_ratings[uid][ccid]
  end
  return 5 if sum_simil == 0

  prediction = weighted_simil / sum_simil
  return prediction
end

# now for each user and item get predicted rating
#u_ids.each do |uid|
#  contents.each do |cid|  
#    puts "user: #{uid} | movie: #{cid} | predict: #{predict(uid, cid, simils, cr_u_content)}"
#  end
#end


# now let's measure accuracy
sum_sq_err = 0.0
i = 0
cratings.each do |cr|
  next unless test.include?(cr.content_id)
  i += 1
  prediction = predict(cr.user_id, cr.content_id, simils, cr_u_content)
  #puts "prediction is: #{prediction}"
  if prediction > 6
    puts "I would recommend (#{prediction}>6) #{cr.content.name} to #{cr.user.login} (he voted it as #{cr.rating})"
  end
  sum_sq_err += (cr.rating - prediction) ** 2
  # puts sum_sq_err
end
puts sum_sq_err / i
