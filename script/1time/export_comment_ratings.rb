max_time = '2010-04-18 00:00:00'


#dict={}
#CommentsValoration.find_each(:conditions => "created_on <= '#{max_time}'", :include => :comments_valorations_type) do |cv|
#	dict[cv.user_id] = {} unless dict.keys.include?(cv.user_id)
#	dict[cv.user_id][cv.comment_id] = (cv.comments_valorations_type.direction == -1) ? 0 : 1
#end and nil
#
# this generates a "user_id: cid:0 cid:1 cid:1" kind of file
#fh = open('comments_valorations_per_user.txt', 'w')
#dict.each do |user_id, cvs|
#  ncvs = cvs.collect {|k,v| "#{k}:#{v}"}
#  fh.write("#{user_id} #{ncvs.join(' ')}\n")
#end and nil
#fh.close

# this generates 2 lines for each user, one with comments they liked and another with comments the disliked
max_time = '2010-04-18 00:00:00'
dict={}
CommentsValoration.find_each(:conditions => "created_on <= '#{max_time}'", :include => :comments_valorations_type) do |cv|
	dict[cv.user_id] = {'0' => [], '1' => []} unless dict.keys.include?(cv.user_id)
	if cv.comments_valorations_type.direction == -1
	    dict[cv.user_id]['0'] << cv.comment_id 
	else
	    dict[cv.user_id]['1'] << cv.comment_id if cv.comments_valorations_type.direction != -1
	end
end and nil

fh = open('comments_valorations_2per_user.txt', 'w')
dict.each do |user_id, cvs|
  cvs.each do |label, comments|
	  next if comments.size == 0
    fh.write("#{cvs[label].sort.join(' ')} #{label}\n")
  end
end and nil
fh.close
