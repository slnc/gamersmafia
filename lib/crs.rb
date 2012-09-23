# This module contains functions and utilities to evaluate different models for
# contents recommendation.
#
# Usage examples:
# Remember that you can run these from the terminal with:
#
#   ./script/rails runner 'RUBY_CODE_HERE'
#
#
# Generate training dataset (must be done from production database or must be
# downloaded from the wiki):
#
#   Crs::Training.GenerateGoldenSet("20120922")
#
#
# Evaluate a model (emit recommendations + measure performance):
#
#   Crs::Eval.TrainAndEvaluateModel("Random", "20120922")
#
#
# To add a new model create a new function in Crs::Models that eventually
# generates a .csv with headers content_id,user_id,interested. The "interested"
# column should be "1" if the model would suggest content_id to user_id and "0"
# otherwise.  You can use RandomRecommendations as a base to your model.
require "csv"
require "set"

module Crs  # Collaborative Recommender System
module Util
  def self.content_user_to_key(content_id, user_id)
    # We assume we won't reach 1M users anytime soon and compressing a key
    # into a int will reduce its mem usage.
    content_id * 1000000 + user_id
  end

  def self.anonymize_id(some_id)
    Zlib.crc32(some_id.to_s)
  end

  def self.bool_to_i(bool)
    bool ? 1 : 0
  end

end

module Training
  TRAINING_SET_CSV_HEADER = (
      "user_id,content_id,interested,has_commented,num_own_comments," +
      "has_recommended,num_recommendations,has_rated_it,rating_value," +
      "rating_positive,rating_negative,is_tracked,first_non_tag_term," +
      "author_is_friend,content_type_id,num_comments,content_author_id")

  # This method generates 3 csv files:
  # - basename_training.csv: dataset to use to train ml models. (60%)
  # - basename_eval.csv: dataset to use to select a winning model. (20%)
  # - basename_test.csv: dataset to use to document generalization error. (20%)
  def self.GenerateGoldenSet(basename)
    # We limit to contents created within the last 3 months because we don't
    # have ground truth (TrackerItem) for further than that. If we don't limit
    # we might have a content that was of interest to a user and he commented
    # but he didn't visit it anymore and therefore in the golden set it would
    # appear as one that he didn't like even though he did. Or maybe he couldn't
    # rate it at that time (no ratings avail). The potential noise is just too
    # high because we have different types of contents and each content has a
    # different relationship with time. Eg: we aren't going to recommend older
    # news or closed topics because people can't comment on them and he just
    # didn't like it. As a first pass a general model for all contents will be
    # an improvement over the existing system. We can build per content_type
    # models later.
    valid_contents = Set.new
    Content.recent.find_each(:batch_size => 10000) do |content|
      valid_contents.add(content.id)
    end

    i = 0
    buckets = {
      :training => [],
      :eval => [],
      :test => [],
    }

    unique_contents = Set.new
    unique_users = Set.new
    TrackerItem.find_each(:batch_size => 10000,
                          :include => [:user, :content]) do |tracker_item|
      i += 1
      if i % 10000 == 0
        puts i
      end

      next unless valid_contents.include?(tracker_item.content_id)

      # We assume we won't reach 1M users anytime soon and compressing a key
      # into a int will reduce its mem usage.
      key = Crs::Util.content_user_to_key(
        tracker_item.content_id, tracker_item.user_id)
      content = tracker_item.content
      # We exclude content owners because they have inherent interest.
      next if content.user_id == tracker_item.user_id

      unique_contents.add(tracker_item.content_id)
      unique_users.add(tracker_item.user_id)

      num_own_comments = content.comments.count(
          :conditions => "user_id = #{tracker_item.user_id}")
      has_commented = (num_own_comments > 0)
      num_recommendations = content.contents_recommendations.count(
          :conditions => "sender_user_id = #{tracker_item.user_id}")
      has_recommended_it = (num_recommendations > 0)
      rating = content.content_ratings.find(
          :first, :conditions => "user_id = #{tracker_item.user_id}")

      if rating
        rating_value = rating.rating
        # Positive points (>5 rating) are worth morethan negative points in
        # terms of interest. (Assumption)
        if rating.rating < 3
          rated_negative = true
          rated_positive = false
        elsif rating.rating >= 6
          rated_negative = false
          rated_positive = true
        end
      else
        rating_value = -1
        rated_negative = false
        rated_positive = false
      end

      # More signal ideas:
      # - tags
      # - impressions, anonymous + non_anonymous (we need to add a ratio, not
      # total else nothing will be learned because contents accumulate
      # impressions the longer they are up.

      # Determining interest
      interested = (
        has_commented ||
        rated_positive ||
        has_recommended_it ||
        tracker_item.is_tracked?
      )

      root_terms = content.terms.collect { |t|
          t.taxonomy != 'ContentsTag' ? t.root.id : nil}.compact

      if root_terms
        first_non_tag_term = root_terms.first
      else
        first_non_tag_term = ""
      end

      author_is_friend = content.user.is_friend_of?(tracker_item.user)

      buckets[self.GetBucketFromKey(key)] << CSV.generate_line([
        Crs::Util.anonymize_id(tracker_item.user_id),
        Crs::Util.anonymize_id(tracker_item.content_id),
        Crs::Util.bool_to_i(interested),
        Crs::Util.bool_to_i(has_commented),
        num_own_comments,
        Crs::Util.bool_to_i(has_recommended_it),
        num_recommendations,
        Crs::Util.bool_to_i(rating_value != -1),
        rating_value,
        Crs::Util.bool_to_i(rated_positive),
        Crs::Util.bool_to_i(rated_negative),
        Crs::Util.bool_to_i(tracker_item.is_tracked?),
        first_non_tag_term,
        Crs::Util.bool_to_i(author_is_friend),
        tracker_item.content.content_type_id,
        content.comments_count,
        Crs::Util.bool_to_i(content.user_id),
      ])
    end

    buckets.each do |bucket_name, csv_lines|
      open("#{basename}_#{bucket_name}.csv", "w").write(
          "#{TRAINING_SET_CSV_HEADER}\n#{csv_lines.join}")
      puts "#{basename}_#{bucket_name}.csv (#{csv_lines.size} samples)."
    end

    puts "Users: #{unique_users.size}, Contents: #{unique_contents.size}"
  end

  def self.GetBucketFromKey(key)
    v = ::Random.rand
    if v < 0.6
      :training
    elsif v < 0.8
      :eval
    else
      :test
    end
  end
end

module Eval

  def self.TrainAndEvaluateModel(model_name, golden_set_csv_basename)
    model_module = Crs::Models.const_get(model_name)
    training_csv = "#{golden_set_csv_basename}_training.csv"
    eval_csv = "#{golden_set_csv_basename}_eval.csv"
    labeled_samples_csv = "#{golden_set_csv_basename}_#{model_name}.csv"
    puts "Training.."
    model_module.Train(training_csv)
    puts "Evaluating.."
    model_module.Eval(eval_csv, labeled_samples_csv)
    self.GetModelPerformance(eval_csv, labeled_samples_csv)
  end

  # Calculates the score of a model against a golden set.
  # http://en.wikipedia.org/wiki/F1_score
  # http://en.wikipedia.org/wiki/Precision_(information_retrieval)
  def self.GetModelPerformance(golden_set_csv_file, model_csv_file)
    golden_set = LoadModel(golden_set_csv_file)
    model = LoadModel(model_csv_file)
    (f1, precision, recall) = self.GetPerformanceScore(golden_set, model)
    formatted_f1 = format("%.2f", f1)
    formatted_precision = format("%.2f", precision)
    formatted_recall = format("%.2f", recall)
    puts ("f1: #{formatted_f1}, precision: #{formatted_precision}, recall:" +
          " #{formatted_recall} (#{model_csv_file})")
  end

  # Loads a model's output and returns a dict with interesting
  # user_id,content_id tuples.
  #
  # csv_file must contain user_id,content_id,interested headers.
  # user_id: string with consistent hash of actual user_id
  # content_id: string with consistent hash of actual content_id
  # interested: string with "0" or "1"
  def self.LoadModel(csv_file)
    model = {}
    CSV.foreach(csv_file, :headers => true) do |row|
      user_id = row["user_id"].to_i
      content_id = row["content_id"].to_i
      interested = row["interested"]
      if user_id.nil? || content_id.nil? || interested.nil?
        raise "Missing required CSV fields (user_id, content_id, interested)."
      end
      key = Crs::Util.content_user_to_key(content_id, user_id)
      model[key] = (interested == "1")
    end
    model
  end

  # Measures the performance of a model against a golden set.
  # golden_set and model are both hashes with the same key. Values are bools and
  # represent the binary class interesting, not_interesting. If model doesn't
  # include a key it's assumed that model assigns false to that key (it was not
  # recommended).
  def self.GetPerformanceScore(golden_set, model)
    tp = 0
    tn = 0
    fp = 0
    fn = 0
    golden_set.each do |key, interested|
      if model.include?(key) && model[key]
        if interested
          tp += 1
        else
          fp += 1
        end
      else
        if interested
          fn += 1
        else
          tn += 1
        end
      end
    end
    precision = tp.to_f / ((tp + fp))
    recall = tp.to_f / ((tp + fn))
    precision = 0 if precision.nan?
    recall = 0 if recall.nan?
    f1 = (1 + 0.5**2) * (precision * recall) / (0.5**2 * precision + recall)
    [f1, precision, recall]
  end
end

module Models

  CSV_LABELED_SAMPLES_HEADER = "user_id,content_id,interested"

module Random
  def self.Train(csv_training)
    # this model doesn't need to train
  end

  # Model that randomly decides whether a content is recommended to a user.
  def self.Eval(csv_training, csv_labeled_samples)
    labeled_samples = CSV.generate do |csv|
      CSV.foreach(csv_training, :headers => true) do |row|
        if ::Random.rand < 0.5
          csv << [row["user_id"], row["content_id"], 1]
        end
      end
    end
    open(csv_labeled_samples, "w").write(
      "#{Crs::Models::CSV_LABELED_SAMPLES_HEADER}\n#{labeled_samples}")
  end
end

# Model that mimicks the current (2012-09-22) content recommendation system
# where users decide which contents they recommend to other users.
module UsersRecommendations
  def self.Train(csv_training)
    # this model doesn't need to train
  end

  def self.Eval(csv_training, csv_labeled_samples)
    valid_contents = Set.new
    Content.recent.find_each(:batch_size => 10000) do |content|
      valid_contents.add(content.id)
    end

    valid_items = Set.new
    i = 0
    TrackerItem.find_each(:batch_size => 10000) do |tracker_item|
      next unless valid_contents.include?(tracker_item.content_id)
      key = tracker_item.content_id * 1000000 + tracker_item.user_id
      valid_items.add(key)
      i += 1
      if i % 10000 == 0
        puts i
      end
    end

    puts "done loading tracker items"

    i = 0
    labeled_samples = CSV.generate do |csv|
      ContentsRecommendation.find_each(:batch_size => 10000) do |recommendation|
        i += 1
        if i % 10000 == 0
          puts i
        end

        key = Crs::Util.content_user_to_key(
            recommendation.content_id, recommendation.receiver_user_id)
        next unless valid_items.include?(key)
        csv << [
            Crs::Util.anonymize_id(recommendation.receiver_user_id),
            Crs::Util.anonymize_id(recommendation.content_id),
            "1",
        ]
      end
    end

    open(csv_labeled_samples, "w").write(
      "#{Crs::Models::CSV_LABELED_SAMPLES_HEADER}\n#{labeled_samples}")
  end
end

end  # Models
end  # Crs
