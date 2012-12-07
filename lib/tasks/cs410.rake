# -*- encoding : utf-8 -*-
require 'ai4r'

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
      maincat = content.main_category
      forum_id = maincat ? maincat.root.id : -1
      author_commented_before_on_same_topic = content.comments.count(:conditions => ['created_on < ? AND user_id = ?', cv.comment.created_on, cv.comment.user_id]) > 0

    end and nil
  end



  def self.train_bayes(classn, find_each_opts)
    # puts "#{classn} #{find_each_opts}"
    dict = {0 => {}, 1 => {}, -1 => {}}
    global_dict = {}
    #ActiveRecord::Base.uncached do
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
    #end
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
    base = "#{Rails.root}/public/storage/cs410"
    FileUtils.mkdir_p(base) unless File.exists?(base)
    open("#{base}/unigram.model", 'w') do |f| f.write(model.to_json) end

    "#{base}/unigram.model"
  end


  class Experiment
    def initialize(model_cls, test_obj, test_method, model_opts={}, experiment_id=nil, vals=nil)
      @model_cls = model_cls
      @model = model_cls.new(model_opts)
      @test_obj = test_obj
      @test_method = test_method
      @experiment_id = experiment_id
      @vals = vals
      @vals = [
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
      1.00] unless @vals   # 296048

    end

    def run
      puts "\n#{@experiment_id ? @experiment_id : @model.class.name}.run!"
      max_time = '2010-04-18 00:00:00'.to_time
            #vals = [0.33,
      #        0.66,
      #        1.00]


      @vals.each do |v|
        folds = 10
        fold = 0
        errors = []
        while fold < folds
          @model.train(CommentsValoration, {:conditions => "id % 10 <> #{fold} AND created_on <= '#{max_time}' AND randval <= #{v}", :include => [:comments_valorations_type, :comment]})

          errors<< @test_obj.send(@test_method, @model, CommentsValoration, {:conditions => "id % 10 = #{fold} AND created_on <= '#{max_time}' AND randval <= #{v}", :include => [:comments_valorations_type, :comment]})
          fold += 1
        end
        puts "#{v}: Mean error: #{Math.mean(errors)} | Sd error: #{Math.standard_deviation(errors)}"
      end
    end
  end

  class NaiveBayes2c
    def initialize(opts={})
      @opts = {:idf => false}.merge(opts)
    end

    def classify(text, user_id, cv)
      prob_pos = 0.0
      prob_neg = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model['pdict']['1'][word].to_f / (@opts[:idf] ? @model['pglobal_dict'][word] : 1)) if @model['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model['pdict']['-1'][word].to_f / (@opts[:idf] ? @model['pglobal_dict'][word] : 1)) if @model['pdict']['-1'][word].to_f > 0
      end
      prob_pos >= prob_neg ? 1 : -1
    end

    def train(classn, find_each_opts)
      dict = {0 => {}, 1 => {}, -1 => {}}
      global_dict = {}
      #ActiveRecord::Base.uncached do
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
      #end
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
      @model = {:pglobal_dict => pglobal_dict, :pdict => pdict}
    end
  end


  class NaiveBayes3c < NaiveBayes2c
    def classify(text, user_id)
      prob_pos = 0.0
      prob_neg = 0.0
      prob_neutral = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model['pdict']['1'][word].to_f / (@opts[:idf] ? @model['pglobal_dict'][word] : 1)) if @model['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model['pdict']['-1'][word].to_f / (@opts[:idf] ? @model['pglobal_dict'][word] : 1)) if @model['pdict']['-1'][word].to_f > 0
        prob_neutral += Math.log(@model['pdict']['0'][word].to_f / (@opts[:idf] ? @model['pglobal_dict'][word] : 1)) if @model['pdict']['0'][word].to_f > 0
      end
      # puts "Prob pos: #{prob_pos} | Prob neg: #{prob_neg} | Prob neutral: #{prob_neutral}"

      positive = -2*prob_pos + prob_neg + prob_neutral
      negative = -2*prob_neg + prob_pos + prob_neutral
      neutral  = -2*prob_neutral + prob_pos + prob_neg
      final = {positive => 1, negative => -1, neutral => 0}

      final[final.keys.max]
    end
  end


  # PER USER ------------------------------------------------------
  class NaiveBayes2cPerUser
    def initialize(opts={})
      @opts = {:idf => false}.merge(opts)
    end

    def classify(text, user_id, cv)
      prob_pos = 0.0
      prob_neg = 0.0
      text.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
        prob_pos += Math.log(@model[user_id.to_s]['pdict']['1'][word].to_f / (@opts[:idf] ? @model[user_id.to_s]['pglobal_dict'][word] : 1)) if @model[user_id.to_s] && @model[user_id.to_s]['pdict']['1'][word].to_f > 0
        prob_neg += Math.log(@model[user_id.to_s]['pdict']['-1'][word].to_f / (@opts[:idf] ? @model[user_id.to_s]['pglobal_dict'][word] : 1)) if @model[user_id.to_s] && @model[user_id.to_s]['pdict']['-1'][word].to_f > 0
      end
      prob_pos >= prob_neg ? 1 : -1
    end

    def train(classn, find_each_opts)
      dict = {} # 0 => {}, 1 => {}, -1 => {}}
      global_dict = {}
      #ActiveRecord::Base.uncached do
        classn.find_each(find_each_opts) do |cv|
          direction = cv.comments_valorations_type.direction
          comment = cv.comment
          next if comment.nil? || comment.comment.nil? || comment.deleted || direction == 0
          comment.comment.gsub(Cms::URL_REGEXP, '').downcase.gsub(/[^a-zA-ZáéíóúÁÉÍÓÚüÜ]+/, ' ').split(' ').each do |word|
            dict[cv.user_id] = {0 => {}, 1 => {}, -1 => {}} unless dict[cv.user_id]
            dict[cv.user_id][direction][word] = 0 unless dict[cv.user_id][direction][word]
            dict[cv.user_id][direction][word] += 1
            global_dict[cv.user_id] = {} unless global_dict[cv.user_id]
            global_dict[cv.user_id][word] = 0 unless global_dict[cv.user_id][word]
            global_dict[cv.user_id][word] += 1
          end
        end
      #end
      #
      # now convert freqs to probs
      pdict = {}
      pglobal_dict = {}
      total_word_count = {}
      dict.each do |user_id, vvv|
        total_word_count[user_id] = global_dict[user_id].values.sum.to_f
      end

      global_dict.each do |user_id, packed|
        packed.each do |word, global_word_count|
          pglobal_dict[user_id] = {} unless pglobal_dict[user_id]
          pglobal_dict[user_id][word] = global_word_count / total_word_count[user_id]
          [1, -1].each do |direction|
            pdict[user_id] = {0 => {}, 1 => {}, -1 => {}} unless pdict[user_id]
            pdict[user_id][direction][word] = (pdict[user_id][direction][word] || 0.0) / pglobal_dict[user_id][word].to_f
          end
        end
      end
      @model = {:pglobal_dict => pglobal_dict, :pdict => pdict}
    end
  end

  class DT2cPerUser
    def initialize(opts={})
      @opts = {:features => %w(comment_author_id), :default_classification => 1}.merge(opts)
    end

    def classify(text, user_id, cv)
      if @model[user_id]
        begin
          @model[user_id].eval(extract_features(cv)).to_i
        rescue
          @opts[:default_classification]
        end
      else
        @opts[:default_classification]
      end
    end

    def train(classn, find_each_opts)
      trees = {}
      data_sets = {}
      #ActiveRecord::Base.uncached do
        classn.find_each(find_each_opts) do |cv|
          direction = cv.comments_valorations_type.direction
          comment = cv.comment
          next if comment.nil? || comment.comment.nil? || comment.deleted || direction == 0
          data_sets[cv.user_id] = [] unless data_sets[cv.user_id]
          data_sets[cv.user_id]<< self.extract_features(cv)
        end
      #end

      data_sets.each do |user_id, data_set|
        trees[user_id] = Ai4r::Classifiers::ID3.new.build(Ai4r::Classifiers::DataSet.new(:data_items=> data_set, :data_labels=> self.features_labels))
      end

      @model = trees
    end

    def features_labels
      @opts[:features] + ['direction']
    end

    def extract_features(cv)
      features = []
      @opts[:features].each { |f| features << self.send("_extract_feature_#{f}", cv) }
      features << cv.comments_valorations_type.direction.to_s
      features
    end

    def _extract_feature_comment_author_id(cv)
      cv.comment.user_id
    end

    def _extract_feature_forum_id(cv)
      maincat = cv.comment.content.main_category
      maincat ? maincat.root.id : -1
    end

    def _extract_feature_comments_direction(cv)
      cv.comment.user.comments_direction
    end

    def _extract_feature_rater_commented_before(cv)
      cv.comment.content.comments.count(:conditions => ['user_id = ? AND created_on < ?', cv.user_id, cv.comment.created_on]) > 0
    end

    def _extract_feature_commenter_commented_before(cv)
      cv.comment.content.comments.count(:conditions => ['user_id = ? AND created_on < ?', cv.comment.user_id, cv.comment.created_on]) > 0
    end
  end


  # 2f comment_author_id + forum_id
  # 3f comment_author_id + forum_id + comments_direction
  # 5f comment_author_id + forum_id + comments_direction + rater_commented_before + commenter_commented_before
  # 6f forum_id
  class DT3cPerUser < DT2cPerUser
    def train(classn, find_each_opts)
      trees = {}
      data_sets = {}
      #ActiveRecord::Base.uncached do
        classn.find_each(find_each_opts) do |cv|
          direction = cv.comments_valorations_type.direction
          comment = cv.comment
          next if comment.nil? || comment.comment.nil? || comment.deleted
          data_sets[cv.user_id] = [] unless data_sets[cv.user_id]
          data_sets[cv.user_id]<< DT2cPerUser.extract_features_basic(cv)
        end
      #end

      data_sets.each do |user_id, data_set|
        trees[user_id] = Ai4r::Classifiers::ID3.new.build(Ai4r::Classifiers::DataSet.new(:data_items=> data_set, :data_labels=> FEATURES_BASIC_LABELS))
      end

      @model = trees
    end
  end


  def self.test_model2c(model, classn, find_each_opts)
    error = 0.0
    i = 0
    classn.find_each(find_each_opts) do |cv|
      comment = cv.comment
      next if comment.nil? || comment.comment.nil? || comment.deleted || cv.comments_valorations_type.direction == 0
      classif = model.classify(cv.comment.comment, cv.user_id, cv)
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
      classif = model.classify(cv.comment.comment, cv.user_id, cv)
      error_hops = ((classif + 1) - (cv.comments_valorations_type.direction + 1)).abs
      # puts "error_hops: #{error_hops} | classif: #{classif} | actual: #{cv.comments_valorations_type.direction}"
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

  desc "Bayes Classifier IDF experiment (2 classes, per user)"
  task :bayes2cpu_experiment => :environment do
    Experiment.new(NaiveBayes2cPerUser, self, :test_model2c).run
  end

  desc "DT experiment (2 classes, per user)"
  task :dt2cpu_experiment => :environment do
    Experiment.new(DT2cPerUser, self, :test_model2c).run
  end

  desc "DT experiment (3 classes, per user)"
  task :dt3cpu_experiment => :environment do
    Experiment.new(DT3cPerUser, self, :test_model3c).run
  end

  desc "DT experiment (2 classes, per user), 2f"
  task :dt2cpu2f_experiment => :environment do
    Experiment.new(DT2cPerUser2f, self, :test_model2c).run
  end

  desc "DT experiment (2 classes, per user), 3f"
  task :dt2cpu3f_experiment => :environment do
    Experiment.new(DT2cPerUser3f, self, :test_model2c).run
  end

  desc "DT experiment (2 classes, per user), 5f"
  task :dt2cpu5f_experiment => :environment do
    Experiment.new(DT2cPerUser5f, self, :test_model2c).run
  end


  desc "DT experiment (2 classes, per user), 5f"
  task :dt2cpu6f_experiment => :environment do
    Experiment.new(DT2cPerUser6f, self, :test_model2c).run
  end

  desc "DT Single"
  task :dt_single => :environment do
    #Experiment.new(DT2cPerUser, self, :test_model2c).run
    #Experiment.new(DT3cPerUser, self, :test_model3c).run
    #Experiment.new(DT2cPerUser2f, self, :test_model2c).run
    #Experiment.new(DT2cPerUser3f, self, :test_model2c).run
    #Experiment.new(DT2cPerUser5f, self, :test_model2c).run
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id)}, 'DT2cPerUser.comment_author_id').run
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id)}, 'DT2cPerUser.forum_id').run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(forum_id)}, 'DT2cPerUser.forum_id').run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comments_direction)}, 'DT2cPerUser.comments_direction').run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(rater_commented_before)}, 'DT2cPerUser.rater_commented_before').run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(commenter_commented_before)}, 'DT2cPerUser.commenter_commented_before').run
  end

  desc "DT Single"
  task :dt_single_limited => :environment do
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comments_direction)}, 'DT2cPerUser.comments_direction', [0.066, 0.099, 0.33]).run
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(rater_commented_before)}, 'DT2cPerUser.rater_commented_before', [0.066, 0.099, 0.33]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(commenter_commented_before)}, 'DT2cPerUser.commenter_commented_before', [0.066, 0.099, 0.33]).run
  end

  desc "DT Mixed"
  task :dt_mixed => :environment do
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id comments_direction)}, 'DT2cPerUser.mix1', [0.00033, 0.00066, 0.00099, 0.0033, 0.0066, 0.0099, 0.033]).run
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id forum_id comments_direction)}, 'DT2cPerUser.mix2', [0.00033, 0.00066, 0.00099, 0.0033, 0.0066, 0.0099, 0.033]).run
    #Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(forum_id comments_direction)}, 'DT2cPerUser.mix3', [0.00033, 0.00066, 0.00099, 0.0033, 0.0066, 0.0099, 0.033]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id comments_direction)}, 'DT2cPerUser.mix1', [0.066, 0.099, 0.33]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id forum_id comments_direction)}, 'DT2cPerUser.mix2', [0.066, 0.099, 0.33]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(forum_id comments_direction)}, 'DT2cPerUser.mix3', [0.066, 0.099, 0.33]).run
  end

  desc "All"
  task :bayes_all => :environment do
    Experiment.new(NaiveBayes2c, self, :test_model2c).run
    Experiment.new(NaiveBayes2cIDF, self, :test_model2c).run
    Experiment.new(NaiveBayes3c, self, :test_model3c).run
    Experiment.new(NaiveBayes3cIDF, self, :test_model3c).run
  end

  desc "Remaining"
  task :remaining => :environment do
    #Experiment.new(NaiveBayes2cPerUser, self, :test_model2c, {}, nil, [0.33, 0.66, 1.0]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id forum_id)}, 'DT2cPerUser2f(comment_author_id, forum_id)', [0.66,1.00]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id forum_id comments_direction)}, 'DT2cPerUser3f', [0.066, 0.099, 0.33,0.66,1.00]).run
    Experiment.new(DT2cPerUser, self, :test_model2c, {:features => %w(comment_author_id forum_id comments_direction rater_commented_before commenter_commented_before)}, 'DT2cPerUser5f', [0.33,0.66,1.00]).run
  end
end
