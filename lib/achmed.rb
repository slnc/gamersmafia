require 'yaml'

module Achmed
  COMMENTS_P_UNIGRAM_FILE_BAD = "#{Rails.root}/public/storage/achmed/comments_bad"
  UNK_TAG = '---unk---'
  COMMENTS_P_UNIGRAM_FILE_GOOD = "#{Rails.root}/public/storage/achmed/comments_good"
  COMMENTS_MODELS_BASE = "#{Rails.root}/public/storage/achmed/comments"
  COMMENTS_JOB_MAX_CREATED_ON = '2008-09-01 00:00:00'

  STOP_WORDS = ['.', ',', ':', '...', '?', '¿', '¡', '!', '$', '&', '/', '=', 'este', 'esta', 'xd', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'hasta', 'me', 'mi', ')', '(']
  SENTENCE_BOUNDARIES = ['.', '...', '?', '!']
  SENTENCE_BOUNDARIES_REGEXP = /(\.\.\.)|(\.)|(!)(\?)/
  def self.cross_pending_done
	  total = Comment.count(:conditions => " id in (SELECT comment_id
                                                                  FROM comment_violation_opinions
                                                              GROUP BY comment_id )
                                                     AND created_on <= '#{COMMENTS_JOB_MAX_CREATED_ON}'::timestamp")
	  done = Comment.count(:conditions => " id in (SELECT comment_id
                                                                  FROM comment_violation_opinions
                                                              GROUP BY comment_id
                                                                HAVING count(*) = 3)
                                                     AND created_on <= '#{COMMENTS_JOB_MAX_CREATED_ON}'::timestamp")
						     puts "total: #{total} | done: #{done}"
						     return done / total.to_f

  end

  def self.get_comment_to_classify_for_user(user)
    # User.db_query("SELECT id from comment_violation_opinions where user_id <> #{user.id} group by user_id having count(*)
    cross_pending = Comment.find(:first, :conditions => " id in (SELECT comment_id
                                                                  FROM comment_violation_opinions
                                                                 WHERE user_id <> #{user.id}
                                                              GROUP BY comment_id
                                                                HAVING count(*) < 3)
				 		     AND id not in (select comment_id from comment_violation_opinions where user_id = #{user.id})
                                                     AND created_on <= '#{COMMENTS_JOB_MAX_CREATED_ON}'::timestamp AND id >= random() * (select max(id) from comments)")

    return cross_pending # if cross_pending # && Kernel.rand < 0.3

    # else return a random comment
    bad_words_cond = " and (comment like '%puta%' or comment like '%polla%' or comment like '%puto%' or comment like '%tacuna%' or comment like '%cancer%' or comment like '%cáncer%' or comment like '%cabrón%' or comment like '% cabron%' or comment like '%marica%' or comment like '%aborto%' or comment like '%mierda%' or comment like '%lesbiana%' or comment like '%negro%')"

    base_cond = "id not in (select comment_id from comment_violation_opinions) AND id >= random() * (select max(id) from comments) AND created_on <='#{COMMENTS_JOB_MAX_CREATED_ON}'::timestamp"
    base_cond << bad_words_cond if Kernel.rand < 0.1

    limit = 10
    c = Comment.find(:first, :conditions => base_cond)
    i = 0
    while c.nil? && i < limit
      c = Comment.find(:first, :conditions => base_cond)
      i += 1
    end
    c
  end

  def self.build_index(corpus)
    index = {}
    i = 0
    corpus.each do |sentence|
      j = 0
      if !sentence.nil?
          sentence.each do |w|
            index[w] ||= []
            index[w] += [[i, j],]
            j += 1
          end
      end
      i += 1
    end
    index
  end

  def self.clean_comment(comment_text)
    comment_text.downcase.gsub(Cms::URL_REGEXP, '').gsub('<br />', '.').gsub('...', ' ... ').gsub(/\s{2,}/, ' ').gsub(/<\/?[^>]*>/, "").gsub(',', ' , ').gsub('.', ' . ').gsub('!', ' ! ').gsub('¡', ' ¡ ').gsub(/:[a-z]+:/, '').gsub('[IMAGEN]', '')
  end

  def self.split_corpus_in_sentences(corpus)
    # convert from list of comments texts to list of sentences with starting <s> and ending </s>
    corpus.split(SENTENCE_BOUNDARIES_REGEXP).delete_if { |l| SENTENCE_BOUNDARIES.include?(l) || l  == ''}.compact.collect { |s| ['<s>'] + self.clean_comment(s).split(' ') + ['</s>'] }

    # corpus.split(SENTENCE_BOUNDARIES_REGEXP).delete_if { |l| SENTENCE_BOUNDARIES.include?(l) || l  == ''}.compact.collect { |s|  + s }
  end

  module Bigram
    def self.train(corpus)
        list_of_lists_of_sentences = corpus.collect { |comment| Achmed::split_corpus_in_sentences(comment) }
        corpus = []
        list_of_lists_of_sentences.each { |l| corpus << l[0] }

        index = Achmed::build_index(corpus)

        iv = {}
        max = 0
        mazzz = index['<s>'].size
        puts mazzz
        index.each do |word, occur|
            iv[occur.size] ||= 0
            iv[occur.size] += 1
            if occur.size > max && occur.size != mazzz
                max = occur.size
        #        puts "new max: #{word}"
            end
        end

        max.times do |i|
            iv[i] ||= 0
        end

        (iv.keys - [mazzz]).sort.each do |k|
            puts "#{k} #{iv[k]}"
        end
        puts "\n\n"
        #raise "bar"


        index.each do |word, occur|
            if occur.size < 100
                occur.each do |i, j|
                    # puts "replacing #{i} #{j} word: #{word} occur.size: #{occur.size}"
                    # puts "replacing #{i} #{j} #{corpus[i].size}"
                    corpus[i][j] = UNK_TAG
                    index[UNK_TAG] ||= []
                    index[UNK_TAG] += occur
                end
                index.delete(word)
            end
        end

        bigram = {}
        # count total number of tokens
        total = 0.0

        index.each do |w, occur|
            total += occur.size
            bigram[w] = {}
        end


        # build an associative array where bigram[word1][word] has the frequency
        # of "word1 word" in the corpus
        index.each do |word, occur|
            occur.each do |i,j|
              next if j == 0
              # we are evaluating '<s>'. we skip because it
              # cannot have a word before it

              word1 = corpus[i][j-1]
              bigram[word1] = {} unless bigram.include?(word1)
              bigram[word1][word] = 0 unless bigram[word1].include?(word)
              bigram[word1][word] += 1
              bigram[word1][UNK_TAG] ||= 0 unless bigram[word1].include?(UNK_TAG)
            end
        end
        bigram[UNK_TAG][UNK_TAG] ||= 0 unless bigram[UNK_TAG].include?(UNK_TAG)

        # we convert frequencies to probabilities
        bigram_p = {}
        bigram.keys.each do |word1|
            bigram_p[word1] = {}

            # count total number of tokens that appear after word1
            word1_total = bigram[word1].values().sum.to_f

            # calculate and store P(word | word1).
            # BE CAREFUL: It will be stored as [word1][word]
            bigram[word1].each do |word, freq|
              bigram_p[word1][word] = freq / word1_total
            end
        end

        #bigram_p.each do |k,v|
        #    puts k
        #    v.each do |kk,vv|
        #        puts "  #{kk}: #{vv}"
        #    end
        #end
        # raise "barbredi!!!"

        bigram_p
    end

    def self.most_likely_spam?(comment)
      bad = self.bigrams[0]
      good = self.bigrams[1]
      l_bad = self.likelihood(bad, comment)
      l_good = self.likelihood(good, comment)

      puts "comparing #{l_bad} > #{l_good} " #   (#{(l_bad - l_good).abs / [l_bad, l_good].max})"
      l_bad > l_good
    end

    def self.bigrams
      model = Achmed::Bigram.to_s
      @@bigrams ||= [File.open("#{COMMENTS_MODELS_BASE}/#{model.gsub('::', '_')}_bad") { |yf| YAML::load(yf) }, File.open("#{COMMENTS_MODELS_BASE}/#{model.gsub('::', '_')}_good") { |yf| YAML::load(yf) } ]
    end

    def self.likelihood(bigram, comment)
        sentences = Achmed::split_corpus_in_sentences(comment)
        i = 0 # on purpose, not 1, it will refer to the previous word
        total_prob = 0.0
        total_probs = [0.0]
        sentences.each do |sentence|
            sentence_prob = 0.0
            sentence[1..-1].each do |w|
                if !bigram.include?(sentence[i]) && bigram[UNK_TAG].include?(w)
                    sentence_prob += Math.log(bigram[UNK_TAG][w])
                elsif !bigram.include?(sentence[i]) && !bigram[UNK_TAG].include?(w)
                    sentence_prob += Math.log(bigram[UNK_TAG][UNK_TAG])
                elsif bigram[sentence[i]].include?(w)
                    sentence_prob += Math.log(bigram[sentence[i]][w])
                # We don't have P(w|w-1). Let's try to use P(w|UNK)
                elsif bigram[UNK_TAG].include?(w)
                    sentence_prob += Math.log(bigram[UNK_TAG][w])
                # No luck, we will then assign P(UNK | UNK) to this unseen event
                else
                    sentence_prob += Math.log(bigram[UNK_TAG][UNK_TAG])
                end
                i += 1
            end
            total_prob += Math.exp(sentence_prob)
            total_probs << Math.exp(sentence_prob)
            # puts "total_prob for sentence: #{total_prob} (sentence_prob: #{sentence_prob}) (#{sentence[1..-1]})"
        end
        total_prob / sentences.size
        total_probs.max
    end
  end

  def self.ngram_train(model, bad_comments_cond, good_comments_cond)
    # spam class
    bad_comments_count = Comment.count(:conditions => bad_comments_cond)
    ngram_bad = model.train(Comment.find(:all, :conditions => bad_comments_cond).collect { |c| Achmed.clean_comment(c.comment) } )

    # nospam class
    ngram_good = model.train(Comment.find(:all, :conditions => good_comments_cond, :order => 'id', :limit => bad_comments_count).collect { |c| Achmed.clean_comment(c.comment) } )

    FileUtils.mkdir_p(COMMENTS_MODELS_BASE) unless File.exists?(COMMENTS_MODELS_BASE)
    puts "writing to #{COMMENTS_MODELS_BASE}/#{model.to_s.gsub('::', '_')}_bad"
    File.open("#{COMMENTS_MODELS_BASE}/#{model.to_s.gsub('::', '_')}_bad", 'w' ) { |out| YAML.dump(ngram_bad, out ) }
    File.open("#{COMMENTS_MODELS_BASE}/#{model.to_s.gsub('::', '_')}_good", 'w' ) { |out| YAML.dump(ngram_good, out ) }
  end


  module Unigram
    def self.train(comments)
      # we build the freq table
      unigram = {}
      comments.each do |c|
          c.split(' ').each do |w|
            unigram[w] ||= 0.0
            unigram[w] += 1
          end
      end

      # normalize
      p_unigram = {}
      max = unigram.values.sum
      unigram.each { |w, v| p_unigram[w] = v / max }


      # smooth it (good turing)
      w1 = 0.0
      unigram.each do |w, v|
          w1 += 1 if v == 1.0
      end

      # puts "Prob mass to give to unk: #{w1 / unigram.values.sum}"
      # puts "\n\n"

      pctg = 1 - w1 / unigram.values.sum
      p_unigram.each { |w, v| p_unigram[w] *= pctg }

      p_unigram[UNK_TAG] = w1 / unigram.values.sum
      p_unigram
    end


    def self.atrain_ngram(bad_comments_cond, good_comments_cond)
      # spam class
      bad_comments_count = Comment.count(:conditions => comments_bad_cond)
      p_unigram_bad = self.train_unigram(Comment.find(:all, :conditions => 'netiquette_violation = \'t\' and id < (select id from comments order by id desc offset 10000 limit 1)').collect { |c| Achmed.clean_comment(c.lastowner_version) } )

      # nospam class
      p_unigram_good = self.train_unigram(Comment.find(:all, :conditions => good_comments_cond, :order => 'id', :limit => bad_comments_count).collect { |c| Achmed.clean_comment(c.comment) } )

      FileUtils.mkdir_p("#{Rails.root}/public/storage/achmed") unless File.exists?("#{Rails.root}/public/storage/achmed")
      File.open(COMMENTS_P_UNIGRAM_FILE_BAD, 'w' ) { |out| YAML.dump(p_unigram_bad, out ) }
      File.open(COMMENTS_P_UNIGRAM_FILE_GOOD, 'w' ) { |out| YAML.dump(p_unigram_good, out ) }
    end

    def self.unigrams
      @@unigrams ||= [File.open("#{COMMENTS_MODELS_BASE}/Achmed_Unigram_bad") { |yf| YAML::load(yf) }, File.open("#{COMMENTS_MODELS_BASE}/Achmed_Unigram_good") { |yf| YAML::load(yf) } ]
    end

    def self.most_likely_spam?(comment)
      bad = self.bigrams[0]
      good = self.bigrams[1]
      l_bad = self.likelihood(bad, comment)
      l_good = self.likelihood(good, comment)

      puts "comparing #{l_bad} > #{l_good}    (#{(l_bad - l_good).abs / [l_bad, l_good].max})"
      l_bad > l_good
    end

    def self.likelihood(punigram, text)
      text = text.downcase.gsub('<br />', ' ').gsub('...', ' ... ').gsub(/\s{2,}/, ' ').gsub(/<\/?[^>]*>/, "").gsub(',', ' , ').gsub('.', ' . ').gsub('!', ' ! ').gsub('¡', ' ¡ ').gsub(/:[a-z]+:/, '').gsub('[IMAGEN]', '')
      p = 0
      text.split(' ').each do |w|
          if punigram.include?(w)
              p += Math.log(punigram[w])
          else
              # p += Math.log(punigram[UNK_TAG])
          end
      end

      Math.exp(p)
    end
  end


  def self.test
    #bad_comments_cond = 'netiquette_violation = \'t\' and lastedited_by_user_id in (22776, 10818, 29957, 22776) and id < (select id from comments order by id desc offset 10000 limit 1)'
    #good_comments_cond = 'netiquette_violation = \'f\' and id > (select id from comments where netiquette_violation = \'t\' order by id limit 1) and id < (select id from comments order by id desc offset 10000 limit 1)'
    bad_comments_cond = 'id IN (SELECT distinct(comment_id) FROM comment_violation_opinions WHERE cls=0 group by comment_id,cls having count(*) > 1) and comment is not null'
    good_comments_cond = 'id IN (SELECT distinct(comment_id) FROM comment_violation_opinions WHERE cls=1 group by comment_id,cls having count(*) > 1) and comment is not null'
    all_comments = 'id IN (SELECT distinct(comment_id) FROM comment_violation_opinions WHERE cls<>2 group by comment_id,cls having count(*) > 1) and comment is not null'
    model = Achmed::Bigram

    self.ngram_train(model, bad_comments_cond, good_comments_cond)

    err = 0.0
    total_good = 0.0
    count_good = 0
    total_bad  = 0.0
    count_bad = 0
    false_positives = 0
    false_negatives = 0

    #Comment.find(:all, :conditions => 'not (netiquette_violation=\'t\' and lastedited_by_user_id not in (22776, 10818, 29957, 22776)) AND id > (select id from comments order by id desc offset 10000 limit 1)').each do |c|
    Comment.find(:all, :conditions => all_comments).each do |c|
      bad_comment = CommentViolationOpinion.count(:conditions => ['comment_id = ?', c.id]) > 2
      if bad_comment
          count_bad += 1
      else
          count_good += 1
      end

      tag_as_spam = model.most_likely_spam?(c.comment)
      err += 1.0 if (bad_comment && !tag_as_spam) || (!bad_comment && tag_as_spam)

      if (bad_comment && !tag_as_spam)
          puts "bad mouth but didn't detect"
          false_negatives += 1
      elsif (!bad_comment && tag_as_spam)
          puts "good mouth but suspected from him #{self.clean_comment(c.comment)[0..150]}"
          false_positives += 1
      end
      #
      #tag_as_spam = model.most_likely_spam?(c.netiquette_violation ? c.lastowner_version : c.comment)

      #err += 1.0 if (c.netiquette_violation && !tag_as_spam) || (!c.netiquette_violation && tag_as_spam)

      #if (c.netiquette_violation && !tag_as_spam)
      #    puts "bad mouth but didn't detect"
      #    false_negatives += 1
      #elsif (!c.netiquette_violation && tag_as_spam)
      #    puts "good mouth but suspected from him #{self.clean_comment(c.comment)[0..150]}"
      #    false_positives += 1
      #end
    end

    puts "count_bad: #{count_bad} | count_good: #{count_good}"
    puts "\nError: #{err / (count_bad + count_good)} (failed with #{err} comments out of #{count_bad + count_good}) | false pos: #{false_positives}  false neg:#{false_negatives}"
  end
end
