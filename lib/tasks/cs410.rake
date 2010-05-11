namespace :cs410 do
  desc "Exports a line for each user with each comment rated by them cid1:0 cid2:-1 cid3:0 cid4:1 ..."
  task :one_line_per_user => :environment do
    dict={}
    CommentsValoration.find_each(:conditions => "created_on <= '#{max_time}'", :include => :comments_valorations_type) do |cv|
      dict[cv.user_id] = {} unless dict.keys.include?(cv.user_id)
      dict[cv.user_id][cv.comment_id] = (cv.comments_valorations_type.direction == -1) ? 0 : 1
    end and nil
    
    # this generates a "user_id: cid:0 cid:1 cid:1" kind of file
    
    fh = open('comments_valorations_per_user.txt', 'w')
    dict.each do |user_id, cvs|
      ncvs = cvs.collect {|k,v| "#{k}:#{v}"}
      fh.write("#{user_id} #{ncvs.join(' ')}\n")
    end and nil
    fh.close
  end
  
  desc "Outputs 2 lines per user, one with comments they liked and another with comments they disliked"
  task :export_comments_liked_disliked_per_user => :environment do
    # this generates 2 lines for each user, one with comments they liked and another with comments the disliked
    max_time = '2010-04-18 00:00:00'
    dict = {}
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
  end
  
  desc "For each rating it outputs the features of the comment being rated"
  task :export_featured_dataset => :enviroment do
    max_time = '2010-04-18 00:00:00'
    dict = {}
    CommentsValoration.find_each(:conditions => "created_on <= '#{max_time}'", :include => [:comments_valorations_type, :comment]) do |cv|
      direction = cv.comments_valorations_type.direction
      content = cv.comment.content
      maincat = content.real_content.main_category
      if maincat
        forum_id = maincat.root.id
      else
        forum_id = -1
      end
      
      author_commented_before_on_same_topic = content.comments.count(:conditions => ['created_on < ? AND user_id = ?', cv.comment.created_on, cv.comment.user_id]) > 0
      
    end and nil
  end
  


  def self.train_bayes(classn, find_each_opts)
    #puts "#{classn} #{find_each_opts}"
    dict = {0 => {}, 1 => {}, -1 => {}}
    global_dict = {}
    ActiveRecord::Base.uncached do
    classn.find_each(find_each_opts) do |cv|
      direction = cv.comments_valorations_type.direction
      comment = cv.comment
      next if comment.nil? || comment.comment.nil? || comment.deleted
      comment.comment.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        dict[direction][word] = 0 unless dict[direction][word] 
        dict[direction][word] += 1
        global_dict[word] = 0 unless global_dict[word]
        global_dict[word] += 1 
      end
    end
    end
    #
    # now convert freqs to probs
    pdict = {0 => {}, 1 => {}, -1 => {}}
    pglobal_dict = {}
    total_word_count = global_dict.values.sum.to_f
    global_dict.each do |word, global_word_count|
      pglobal_dict[word] = global_word_count / total_word_count
      [0, 1, -1].each do |direction|
        pdict[direction][word] = (dict[direction][word] || 0.0) / global_dict[word].to_f
      end
    end
    model = {:pglobal_dict => pglobal_dict, :pdict => pdict}
    base = "#{RAILS_ROOT}/public/storage/cs410"
    FileUtils.mkdir_p(base) unless File.exists?(base)
    open("#{base}/unigram.model", 'w') do |f| f.write(model.to_json) end

    "#{base}/unigram.model"
  end
  

  class Experiment
    def initialize(model, test_obj, test_method)
      @model = model
      @test_obj = test_obj
      @test_method = test_method
    end

    def run
      max_time = '2010-04-18 00:00:00'.to_time
      vals = [
      0.00033, # 104
      0.00066, # 205
      0.00099, # 205
      0.0033,  # 988
      0.0066,  # 1971
      0.0099,  # 2978
      0.033,   # 9779
      0.066,   # 19449
      0.099,   # 29162
      0.33,    # 97722
      0.66,    # 195477
      1.00]    # 296048
  
      vals.each do |v|
      folds = 10
      fold = 0
      errors = []
      while fold < folds
      	model_file = @model.train(CommentsValoration, {:conditions => "id % 10 <> #{fold} AND created_on <= '#{max_time}' AND randval <= #{v}", :include => [:comments_valorations_type, :comment]})
  
  	errors<< @test_obj.send(@test_method, @model.new(model_file), CommentsValoration, {:conditions => "id % 10 = #{fold} AND created_on <= '#{max_time}' AND randval <= #{v}", :include => [:comments_valorations_type, :comment]})
          fold += 1
      end
      puts "#{v}: Mean error: #{Math.mean(errors)} | Sd error: #{Math.standard_deviation(errors)}"
      end
    end
  end

  class NaiveBayes2c
    def initialize(model_file)
      @model = JSON.parse(open(model_file).read)
    end

    def classify(text)
      prob_pos = 0.0
      prob_neg = 0.0
      #prob_neutral = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model['pdict']['1'][word].to_f) if @model['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model['pdict']['-1'][word].to_f) if @model['pdict']['-1'][word].to_f > 0
        #prob_neutral += Math.log(@model['pdict']['0'][word].to_f) if @model['pdict']['0'][word].to_f > 0
      end
      #puts "Prob pos: #{prob_pos} | Prob neg: #{prob_neg}"
      prob_pos >= prob_neg ? 1 : -1
    end

    def self.train(classn, find_each_opts)
      dict = {0 => {}, 1 => {}, -1 => {}}
      global_dict = {}
      ActiveRecord::Base.uncached do
      classn.find_each(find_each_opts) do |cv|
        direction = cv.comments_valorations_type.direction
        comment = cv.comment
        next if comment.nil? || comment.comment.nil? || comment.deleted || direction == 0
        comment.comment.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
          dict[direction][word] = 0 unless dict[direction][word] 
          dict[direction][word] += 1
          global_dict[word] = 0 unless global_dict[word]
          global_dict[word] += 1 
        end
      end
      end
      #
      # now convert freqs to probs
      pdict = {0 => {}, 1 => {}, -1 => {}}
      pglobal_dict = {}
      total_word_count = global_dict.values.sum.to_f
      global_dict.each do |word, global_word_count|
        pglobal_dict[word] = global_word_count / total_word_count
        [1, -1].each do |direction|
          pdict[direction][word] = (dict[direction][word] || 0.0) / global_dict[word].to_f
        end
      end
      model = {:pglobal_dict => pglobal_dict, :pdict => pdict}
      base = "#{RAILS_ROOT}/public/storage/cs410"
      FileUtils.mkdir_p(base) unless File.exists?(base)
      open("#{base}/unigram.model", 'w') do |f| f.write(model.to_json) end
  
      "#{base}/unigram.model"
    end
  end

  class NaiveBayes2cIDF < NaiveBayes2c
    def classify(text)
      prob_pos = 0.0
      prob_neg = 0.0
      #prob_neutral = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model['pdict']['1'][word].to_f / @model['pglobal_dict'][word]) if @model['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model['pdict']['-1'][word].to_f / @model['pglobal_dict'][word]) if @model['pdict']['-1'][word].to_f > 0
        #prob_neutral += Math.log(@model['pdict']['0'][word].to_f) if @model['pdict']['0'][word].to_f > 0
      end
      #puts "Prob pos: #{prob_pos} | Prob neg: #{prob_neg}"
      prob_pos >= prob_neg ? 1 : -1
    end
  end

  class NaiveBayes3c < NaiveBayes2c
    def classify(text)
      prob_pos = 0.0
      prob_neg = 0.0
      prob_neutral = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model['pdict']['1'][word].to_f) if @model['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model['pdict']['-1'][word].to_f) if @model['pdict']['-1'][word].to_f > 0
        prob_neutral += Math.log(@model['pdict']['0'][word].to_f) if @model['pdict']['0'][word].to_f > 0
      end
      #puts "Prob pos: #{prob_pos} | Prob neg: #{prob_neg} | Prob neutral: #{prob_neutral}"

      positive = -2*prob_pos + prob_neg + prob_neutral
      negative = -2*prob_neg + prob_pos + prob_neutral
      neutral  = -2*prob_neutral + prob_pos + prob_neg
      final = {positive => 1, negative => -1, neutral => 0}
      #[-1, 0, 1].each do |direction|
      #  final.delete(direction) if final[0.0] == direction # TODO this will only remove one class if TWO classes have 0 probability
      #end
      final[final.keys.max]
    end
  end

  class NaiveBayes3cIDF < NaiveBayes3c
    def classify(text)
      prob_pos = 0.0
      prob_neg = 0.0
      prob_neutral = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model['pdict']['1'][word].to_f / @model['pglobal_dict'][word]) if @model['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model['pdict']['-1'][word].to_f / @model['pglobal_dict'][word]) if @model['pdict']['-1'][word].to_f > 0
        prob_neutral += Math.log(@model['pdict']['0'][word].to_f / @model['pglobal_dict'][word]) if @model['pdict']['0'][word].to_f > 0
      end

      positive = 2*prob_pos - prob_neg - prob_neutral
      negative = 2*prob_neg - prob_pos - prob_neutral
      neutral  = 2*prob_neutral - prob_pos - prob_neg
      final = {positive => 1, negative => -1, neutral => 0}
      final[final.keys.max]
    end
  end

  def self.test_model2c(model, classn, find_each_opts)
    error = 0.0
    i = 0
    classn.find_each(find_each_opts) do |cv|
      comment = cv.comment
      next if comment.nil? || comment.comment.nil? || comment.deleted || cv.comments_valorations_type.direction == 0
      classif = model.classify(cv.comment.comment)
      if classif != cv.comments_valorations_type.direction
        error += 1
      end
      i += 1
    end
    error / i
  end

  def self.test_model3c(model, classn, find_each_opts)
    error = 0.0
    i = 0
    classn.find_each(find_each_opts) do |cv|
      comment = cv.comment
      next if comment.nil? || comment.comment.nil? || comment.deleted
      classif = model.classify(cv.comment.comment)
      error_hops = ((classif + 1) - (cv.comments_valorations_type.direction + 1)).abs
      #puts "error_hops: #{error_hops} | classif: #{classif} | actual: #{cv.comments_valorations_type.direction}"
      if error_hops > 1
	error += 2
      elsif error_hops > 0
	error += 1
      end
      i += 1
    end
    error / i
  end

  desc "Bayes Classifier experiment (2 classes)"
  task :bayes2c_experiment => :environment do
    Experiment.new(NaiveBayes2c, self, :test_model2c).run
  end

  desc "Bayes Classifier experiment (3 classes)"
  task :bayes3c_experiment => :environment do
    Experiment.new(NaiveBayes3c, self, :test_model3c).run
  end

  desc "Bayes Classifier IDF experiment (2 classes)"
  task :bayes2cidf_experiment => :environment do
    Experiment.new(NaiveBayes2cIDF, self, :test_model2c).run
  end

  desc "Bayes Classifier IDF experiment (3 classes)"
  task :bayes3cidf_experiment => :environment do
    Experiment.new(NaiveBayes3cIDF, self, :test_model3c).run
  end

end
