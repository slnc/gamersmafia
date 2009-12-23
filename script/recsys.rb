cache = "rec.model.3.weeks"
cond_cratings = 'lastseen_on >= now() - \'3 days\'::interval'
cond_cratings2 = 'created_on >= now() - \'3 weeks\'::interval and content_id in (select id from contents where created_on >= now() - \'2 week\'::interval)'
#tis = TrackerItem.find(:all, :conditions => cond_cratings, :include => [:content, :user])
#puts "tis: #{tis.size}"
#real_contents = []
#contents = []
#users_involved = []
#tis.each do |ti|
#next if ti.content_id.nil? or ti.user_id.nil?
#contents<< ti.content_id unless contents.include?(ti.content_id)
#users_involved<< ti.user_id unless users_involved.include?(ti.user_id)
#end
#contents.sort!
#users_involved.sort!
#

#real_contents = Content.find(:all, :conditions => "id in (select distinct(content_id) from content_ratings where #{cond_cratings})", :include => :user)
#contents = real_contents.compact.collect {|c| c.id}.sort
#users_involved = tis.collect {|ti| ti.user if ti.user.cache_karma_points > 1000}.uniq.compact
real_contents = Content.find(:all, :conditions => "id in (select distinct(content_id) from content_ratings where #{cond_cratings2})")
contents = real_contents.collect {|c| c.id}.sort
cratings = ContentRating.find(:all, :conditions => cond_cratings2)
users_involved = cratings.collect {|cr| cr.user_id}.compact.sort

puts "contents: #{contents.size}"
puts "users: #{users_involved.size}"

train = contents[0..(contents.size*0.66).ceil]
test = contents[(contents.size*0.66).ceil..-1]
#contents = []

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
#puts u.id
#    cr_u_content[uid] ||= {}
#    User.find(uid).contents_visited_between(2.week.ago, Time.now).each do |c|
#	if c.nil?
#puts "c.nil!"
#next
#end
#	contents<< c
#      cr_u_content[u.id][c.id] = u.latent_rating(c)
#    end
#end
#contents = contents.uniq.collect {|c| c.id}
#
#cratings.each do |cr|
#  cr_u_content[cr.user_id] ||= {}
#  cr_u_content[cr.user_id][cr.content_id] = cr.rating if train.include?(cr.content_id)
#end
#
puts "first stage done, computing matrix"
# p cr_u_content

simils = {}
u_ids = users_involved
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
if !File.exists?(cache)
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
    #puts "computing distance between #{cid}, #{ccid}"
simils[cid][ccid] = simils[ccid][cid]
    end
  end
if (i/total*100).to_i != prev_pcent
prev_pcent = (i/total*100).to_i
puts "#{prev_pcent}%"
end

end

File.open(cache, "wb").write(Marshal::dump(simils))
else
simils = Marshal::load(File.open(cache))
end

# p simils

def predict(uid, cid, simils, user_ratings)
  sum_simil = 0.0
  weighted_simil = 0.0
  (simils.keys - [cid]).each do |ccid|
    next unless user_ratings.include?(uid) && user_ratings[uid].include?(ccid)
    
      #puts "#{cid} not in simils!!!" if !simils.keys.include?(cid)
      #puts "#{ccid} not in simils#{cid}!!!" if !simils[cid].keys.include?(ccid)
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
  #puts "prediction is: #{prediction}"
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
