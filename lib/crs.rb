# -*- encoding : utf-8 -*-
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
require "msgpack"

# Collaborative Recommender System module
module Crs

  def self.recommend_from_interests
    Term.find(:all, :conditions => "id IN (SELECT DISTINCT(entity_id) from user_interests)").each do |t|
      t.contents_terms.find(:all, :conditions => "created_on >= now() - '2 weeks'::interval").each do |content_term|
        Crs.recommend_from_contents_term(content_term)
      end
    end
  end

  # Looks for people who might be interested in a given content
  def self.recommend_from_contents_term(contents_term)
    # TODO(slnc): don't recommend very old news or closed topics, just in case
    # we backfill this.
    # Look for all users who have the term as an interest and haven't visited
    # already the content.
    User.with_interest("Term", contents_term.term_id).find_each do |user|
      rec = user.contents_recommendations.create(
          :content_id => contents_term.content_id,
          :sender_user_id => Ias.jabba.id,
          :comment => "Relacionado con '#{contents_term.term.name}' (interés)")
    end
  end

  # Returns the last built model
  def self.latest_known_model
    Pathname.glob(
        "#{Rails.root}/config/models/crs/*/").map(&:basename).sort.last.to_s
  end

  def self.current_model_name
    Time.now.strftime("%Y%m%d")
  end

  def self.rebuild_model
    model_id = self.current_model_name
    raise "No model found" if model_id.empty?

    model_base = "#{Rails.root}/config/models/crs/#{model_id}"
    training_csv = "#{model_base}_training.csv"
    Crs::Training.GenerateGoldenSet(
        "#{Rails.root}/config/models/crs/#{model_id}", [1.0, 0.0], false)
    Crs::Models::UserSimilarity.Train(training_csv, "#{model_base}/")
  end

  def self.generate_recommendations
    # For each user get all unvisited content_ids created in the last 15 days
    # (via SQL).
    # For each active user look at all the contents they have visited
    # We generate recommendations for active users only and for
    user_ids = {}
    i = 0
    User.non_zombies.find_each(:conditions => "cache_karma_points > 0") do |user|
      i += 1
      user_ids[user.id] = []
      # We delete items from tracker_items after 3 months so we don't look back
      # longer than that.
      Content.published.recent.find_each(
          :conditions => ["id NOT IN (SELECT content_id
                                      FROM tracker_items
                                      WHERE user_id = #{user.id})
                         AND id not IN (SELECT content_id
                                        FROM contents_recommendations
                                        WHERE user_id = #{user.id}
                                        AND seen_on IS NULL)"],
          :batch_size => 10000) do |content|
        user_ids[user.id].append(content.id)
      end
    end

    i = 0
    eval_samples = ["user_id,content_id\n"]
    user_ids.each do |user_id, contents|
      contents.each do |content_id|
        i += 1
        # TODO(slnc): this csv should have all the features from
        # GenerateGoldenSet. We don't populate it right now for perf reasons
        # because the current model doesn't use any of them.
        eval_samples << CSV.generate_line([user_id, content_id])
      end
    end
    puts "#{i} samples generated"

    model_id = self.latest_known_model
    model_base = "#{Rails.root}/config/models/crs/#{model_id}"
    eval_csv = "#{model_base}_eval.csv"
    labeled_samples_csv = "#{model_base}_UserSimilarity.csv"
    open(eval_csv, "wb").write(eval_samples.join)
    puts "Generated #{eval_samples.size} labeled samples"
    Crs::Models::UserSimilarity.Eval(
        eval_csv, labeled_samples_csv, "#{model_base}/")
    recommendations = 0
    CSV.foreach(labeled_samples_csv, :headers => true) do |row|
      next unless row["interested"] == "1"
      ContentsRecommendation.create({
          :sender_user_id => Ias.jabba.id,
          :receiver_user_id => row["user_id"].to_i,
          :content_id => row["content_id"].to_i,
          :confidence => row["confidence"].to_f,
          :comment => "#{(row["confidence"].to_f * 100).to_i}% interesante",
      })
      recommendations += 1
      puts "#{recommendations} generated" if i % 10000 == 0
    end
    puts "Generated #{recommendations} recommendations"
  end

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

  def self.setup_work_dir(work_dir)
    FileUtils.mkdir_p(work_dir) unless File.exists?(work_dir)
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
  # bucket_rations: list with 2 floats, where each float determines the upper
  # probability that a sample will go to a given bucket. Eg: [0.8, 0.1] will
  # assign 98% of the samples to the training set, 10% to the eval set and 10%
  # (implicit) to the test set.
  def self.GenerateGoldenSet(basename, bucket_sizes=nil, anonymize=true)
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
    bucket_sizes = [0.6, 0.2] if bucket_sizes.nil?
    valid_contents = Set.new
    Content.published.recent.find_each(:batch_size => 10000) do |content|
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

#      root_terms = content.terms.collect { |t|
#          t.taxonomy != 'ContentsTag' ? t.root.id : nil}.compact
#
#      if root_terms
#        first_non_tag_term = root_terms.first
#      else
#        first_non_tag_term = ""
#      end
#
#      author_is_friend = content.user.is_friend_of?(tracker_item.user)

      buckets[self.GetBucketFromKey(key, bucket_sizes)] << CSV.generate_line([
        anonymize ? Crs::Util.anonymize_id(tracker_item.user_id) : tracker_item.user_id,
        anonymize ? Crs::Util.anonymize_id(tracker_item.content_id) : tracker_item.content_id,
        Crs::Util.bool_to_i(interested),
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        #
#        Crs::Util.bool_to_i(has_commented),
#        num_own_comments,
#        Crs::Util.bool_to_i(has_recommended_it),
#        num_recommendations,
#        Crs::Util.bool_to_i(rating_value != -1),
#        rating_value,
#        Crs::Util.bool_to_i(rated_positive),
#        Crs::Util.bool_to_i(rated_negative),
#        Crs::Util.bool_to_i(tracker_item.is_tracked?),
#        first_non_tag_term,
#        Crs::Util.bool_to_i(author_is_friend),
#        tracker_item.content.content_type_id,
#        content.comments_count,
#        Crs::Util.bool_to_i(content.user_id),
      ])

#      buckets[self.GetBucketFromKey(key, bucket_sizes)] << CSV.generate_line([
#        anonymize ? Crs::Util.anonymize_id(tracker_item.user_id) : tracker_item.user_id,
#        anonymize ? Crs::Util.anonymize_id(tracker_item.content_id) : tracker_item.content_id,
#        Crs::Util.bool_to_i(interested),
#        Crs::Util.bool_to_i(has_commented),
#        num_own_comments,
#        Crs::Util.bool_to_i(has_recommended_it),
#        num_recommendations,
#        Crs::Util.bool_to_i(rating_value != -1),
#        rating_value,
#        Crs::Util.bool_to_i(rated_positive),
#        Crs::Util.bool_to_i(rated_negative),
#        Crs::Util.bool_to_i(tracker_item.is_tracked?),
#        first_non_tag_term,
#        Crs::Util.bool_to_i(author_is_friend),
#        tracker_item.content.content_type_id,
#        content.comments_count,
#        Crs::Util.bool_to_i(content.user_id),
#      ])
    end

    basedir = File.dirname(basename)
    FileUtils.mkdir_p(basedir) unless File.exists?(basedir)

    buckets.each do |bucket_name, csv_lines|
      open("#{basename}_#{bucket_name}.csv", "w").write(
          "#{TRAINING_SET_CSV_HEADER}\n#{csv_lines.join}")
      puts "#{basename}_#{bucket_name}.csv (#{csv_lines.size} samples)."
    end

    puts "Users: #{unique_users.size}, Contents: #{unique_contents.size}"
  end

  def self.GetBucketFromKey(key, bucket_sizes)
    v = ::Random.rand
    if v <= bucket_sizes[0]
      :training
    elsif v < bucket_sizes[1]
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
    model_module.Train(training_csv, "#{golden_set_csv_basename}/")
    puts "Evaluating.."
    model_module.Eval(
        eval_csv, labeled_samples_csv, "#{golden_set_csv_basename}/")
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

  CSV_LABELED_SAMPLES_HEADER = "user_id,content_id,interested,confidence"

module AuthorIsFriend
  def self.Train(csv_training, work_dir)
    # this model doesn't need to train
  end

  # Model that randomly decides whether a content is recommended to a user.
  def self.Eval(csv_eval, csv_labeled_samples, work_dir)
    labeled_samples = CSV.generate do |csv|
      CSV.foreach(csv_eval, :headers => true) do |row|
        label = (row["author_is_friend"] == "1") ? 1 : 0
        csv << [row["user_id"], row["content_id"], label, 1.0]
      end
    end
    open(csv_labeled_samples, "w").write(
      "#{Crs::Models::CSV_LABELED_SAMPLES_HEADER}\n#{labeled_samples}")
  end
end

module Random
  def self.Train(csv_training, work_dir)
    # this model doesn't need to train
  end

  # Model that randomly decides whether a content is recommended to a user.
  def self.Eval(csv_eval, csv_labeled_samples, work_dir)
    labeled_samples = CSV.generate do |csv|
      CSV.foreach(csv_eval, :headers => true) do |row|
        if ::Random.rand < 0.5
          csv << [row["user_id"], row["content_id"], 1, 1.0]
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
  def self.Train(csv_training, work_dir)
    # this model doesn't need to train
  end

  def self.Eval(csv_eval, csv_labeled_samples, work_dir)
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
            1.0,
        ]
      end
    end

    open(csv_labeled_samples, "w").write(
      "#{Crs::Models::CSV_LABELED_SAMPLES_HEADER}\n#{labeled_samples}")
  end
end

module UserSimilarity
  def self.cache_from_work_dir(work_dir)
    "#{work_dir}/similarity_matrix"
  end

  def self.Train(csv_training, work_dir)
    Crs::Util.setup_work_dir(work_dir)
    cache_file = self.cache_from_work_dir(work_dir)
    return if File.exists?(cache_file)
    user_ratings = self.build_user_ratings(csv_training)
    similarity_matrix = self.compute_similarity_matrix(
        csv_training, user_ratings)
    File.open(cache_file, "wb").write(
        [similarity_matrix, user_ratings].to_msgpack)
  end

  # Builds a hash keyed by user with all the contents for which we know whether
  # they are of interest or not to the user.
  def self.build_user_ratings(csv_training)
    user_ratings = {}
    CSV.foreach(csv_training, :headers => true) do |row|
      user_id = row["user_id"].to_i
      if !user_ratings.include?(user_id)
        user_ratings[user_id] = {}
      end
      user_ratings[user_id][row["content_id"].to_i] = (row["interested"] == "1")
    end
    user_ratings
  end

  def self.compute_similarity_matrix(csv_training, user_ratings)
    puts "compute_similarity_matrix"
    users = Set.new
    contents = Set.new
    CSV.foreach(csv_training, :headers => true) do |row|
      users.add(row["user_id"].to_i)
      contents.add(row["content_id"].to_i)
    end

    similarities = {}
    base_row = {}
    contents.sort.each do |content|
      base_row[content] = 0.0
    end
    puts "Total: #{contents.size ** 2}"
    i = 0
    contents.sort.each do |content|
      similarities[content] = base_row.clone
      # puts "content: #{content}: #{similarities[content]}"

      contents.sort.each do |content_i|
        next if content_i == content
        i += 1
        puts i if i % 10000 == 0
        # puts "content_i: #{content_i}"
        if content_i > content
          # we need to calculate it
          similarities[content][content_i] = self.distance(
              content, content_i, user_ratings)
        else
          # we already calculated it, we are in the lower part of the matrix
          similarities[content][content_i] = similarities[content_i][content]
        end
      end
    end
    puts "done with similarities"
    similarities
  end

  def self.distance(item1, item2, user_ratings)
    common_items={}
    user_ratings.each do |user, rated_items|
      if rated_items.include?(item1) && rated_items.include?(item2)
        common_items[user] = 1
      end
    end

    return 0 if common_items.size == 0

    # Add up all the preferences
    sumEuc = 0.0
    common_items.each do |user, _|
      same_interest = (user_ratings[user][item1] == user_ratings[user][item2])
      sumEuc += (same_interest ? 1 : 0) ** 2
    end

    eudistance = 1 / (1 + sumEuc)
    # puts "Euclidean distance between #{item1} and #{item2}: #{eudistance}"
    eudistance
  end

  PREDICTION_THRESHOLD = 0.5

  def self.Eval(csv_eval, csv_labeled_samples, work_dir)
    cache_file = self.cache_from_work_dir(work_dir)
    (similarity_matrix, user_ratings) = MessagePack.unpack(
        File.open(cache_file).read)
    puts "data loaded"

    labeled_samples = []
    i = 0
    CSV.foreach(csv_eval, :headers => true) do |row|
      i += 1
      if i % 10000 == 0
        puts "#{i} samples predicted"
      end
      # puts "predicting #{row["content_id"]} for #{row["user_id"]}"
      prediction = self.predict(
          row["user_id"].to_i,
          row["content_id"].to_i,
          similarity_matrix,
          user_ratings)
      label = (prediction > PREDICTION_THRESHOLD) ? 1 : 0
      next if label == 0  # We don't need this class of samples for anything
      confidence = prediction
      labeled_samples << [
          row["user_id"], row["content_id"], label.to_s, confidence].join(",")
    end
    open(csv_labeled_samples, "w").write(
      "#{Crs::Models::CSV_LABELED_SAMPLES_HEADER}\n#{labeled_samples.join("\n")}")
  end

  # Predicts whether content is going to be liked by a user based on a
  # similarity matrix and based on the interests of other users on content.
  def self.predict(uid, cid, simils, user_ratings)
    sum_simil = 0.0
    weighted_simil = 0.0
    cids_without_ratings = 0
    missing_tuples_simil = 0
    simils.keys.each do |ccid|
      next if ccid == cid
      # puts ccid
      if !(user_ratings.include?(uid) && user_ratings[uid].include?(ccid))
        cids_without_ratings += 1
        next
      end

      if !simils.include?(cid) || !simils[cid].include?(ccid)
        missing_tuples_simil += 1
        next  # unknown item
      end

      # Because interests are binary (0: no interest or 1: interest) we need to
      # use 1, 2 instead of 0, 1 because else we will zero out all dinterests.
      rating = user_ratings[uid][ccid] ? 2 : 1

      sum_simil += simils[cid][ccid]
      weighted_simil += simils[cid][ccid] * rating
    end
    # puts "#{cids_without_ratings} #{missing_tuples_simil} out of #{simils.keys.size}"
    return 0 if sum_simil == 0

    # puts "#{weighted_simil} / #{sum_simil}"
    (weighted_simil / sum_simil) - 1
  end
end  # UserSimilarity

end  # Models
end  # Crs
