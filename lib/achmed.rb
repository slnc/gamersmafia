require 'yaml'

module Achmed
  COMMENTS_P_UNIGRAM_FILE_BAD = "#{RAILS_ROOT}/public/storage/achmed/comments_bad"
  UNK_TAG = '---unk---'
  COMMENTS_P_UNIGRAM_FILE_GOOD = "#{RAILS_ROOT}/public/storage/achmed/comments_good"

  STOP_WORDS = ['.', ',', ':', '...', '?', '¿', '¡', '!', '$', '&', '/', '=', 'este', 'esta', 'xd', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'hasta', 'me', 'mi', ')', '(']

  def self.train_unigram(collection)
    comments = collection

    # cleaning
    comments.collect! do |c|
        c = c.downcase.gsub('<br />', ' ').gsub('...', ' ... ').gsub(/\s{2,}/, ' ').gsub(/<\/?[^>]*>/, "").gsub(',', ' , ').gsub('.', ' . ').gsub('!', ' ! ').gsub('¡', ' ¡ ').gsub(/:[a-z]+:/, '')
    end


    # let's try with unigram
    # we build the freq table
    unigram = {}
    comments.each do |c|
        c.split(' ').each do |w|
            #if STOP_WORDS.include?(w)
            #    unigram['UNKKKNOW'] += 1
            #else
                unigram[w] ||= 0.0
                unigram[w] += 1
            #end
        end
    end

    # remove# words with freq less than 5
    #puts "UNIGRAM"
    #unigram.each do |k,v|
#if v < 30
#        unigram.delete(k) 
#        else
#        puts "#{k}          #{v}"
#    end
    #end


    
    # normalize
    puts "UNIGRAM --------"
    p_unigram = {}
    max = unigram.values.sum
    unigram.each do |w, v|
        p_unigram[w] = v / max
        puts "#{w} #{p_unigram[w]}"
    end


    # smooth it (good turing)
    w1 = 0.0
    unigram.each do |w, v|
        w1 += 1 if v == 1.0
    end
    
    puts "Prob mass to give to unk: #{w1 / unigram.values.sum}"
    puts "\n\n"

    pctg = 1 - w1 / unigram.values.sum
    p_unigram.each do |w, v|
        p_unigram[w] *= pctg
        puts "#{w} #{p_unigram[w]}"
    end
    
    p_unigram[UNK_TAG] = w1 / unigram.values.sum

    p_unigram
  end

  def self.train
    # spam class
    bad_comments_count = Comment.count(:conditions => 'netiquette_violation = \'t\' and lastedited_by_user_id in (22776, 10818, 29957, 22776) and id < (select id from comments order by id desc offset 10000 limit 1)')
    p_unigram_bad = self.train_unigram(Comment.find(:all, :conditions => 'netiquette_violation = \'t\' and id < (select id from comments order by id desc offset 10000 limit 1)').collect { |c| c.lastowner_version } )

    # nospam class
    p_unigram_good = self.train_unigram(Comment.find(:all, :conditions => 'netiquette_violation = \'f\' and id > (select id from comments where netiquette_violation = \'t\' order by id limit 1) and id < (select id from comments order by id desc offset 10000 limit 1)', :order => 'id', :limit => bad_comments_count).collect { |c| c.comment } )

    FileUtils.mkdir_p("#{RAILS_ROOT}/public/storage/achmed") unless File.exists?("#{RAILS_ROOT}/public/storage/achmed")
    File.open(COMMENTS_P_UNIGRAM_FILE_BAD, 'w' ) { |out| YAML.dump(p_unigram_bad, out ) }
    File.open(COMMENTS_P_UNIGRAM_FILE_GOOD, 'w' ) { |out| YAML.dump(p_unigram_good, out ) }
  end


  def self.is_comment_suspicious?(c)
    l = self.likelihood(c.comment, unigram)
    l >= SUSPICIOUS_THRESHOLD
  end

  def self.unigrams
    @@unigrams ||= [File.open(COMMENTS_P_UNIGRAM_FILE_BAD) { |yf| YAML::load(yf) }, File.open(COMMENTS_P_UNIGRAM_FILE_GOOD) { |yf| YAML::load(yf) } ]
  end

  SUSPICIOUS_THRESHOLD = -30.0

  def self.most_likely_spam?(comment)
    bad = self.unigrams[0]
    good = self.unigrams[1]
    l_bad = self.likelihood(bad, comment)
    l_good = self.likelihood(good, comment)
    
    puts "comparing #{l_bad} > #{l_good}    (#{(l_bad - l_good).abs / [l_bad, l_good].max})"
    l_bad > l_good
  end

  def self.test
    self.train
        # test on last 5000 comments
        err = 0.0
        total_good = 0.0
        count_good = 0
        total_bad  = 0.0
        count_bad = 0
        threshold = SUSPICIOUS_THRESHOLD
        problematic_moderatos = {}
        Comment.find(:all, :conditions => 'deleted = \'f\' AND id > (select id from comments order by id desc offset 10000 limit 1)').each do |c|
        #Comment.find_each(:conditions => 'deleted = \'f\' and id > (select id from comments where netiquette_violation = \'t\' order by id limit 1)') do |c|
            #l = self.most_likely_class(c.comment)
            # l = self.likelihood(c.comment, punigram)
            if c.netiquette_violation
                count_bad += 1
                #total_bad += l
                #puts format("likelihood for netiquette violation: #{l}")
            else
                count_good += 1
                #total_good += l
            end

            tag_as_spam = self.most_likely_spam?(c.comment)
            
            err += 1.0 if (c.netiquette_violation && !tag_as_spam) || (!c.netiquette_violation && tag_as_spam)

            #err += 1.0 if (c.netiquette_violation && l < threshold) || (!c.netiquette_violation && l >= threshold)

            #if l >= threshold
            #    puts "--------- FOUND BAD MOUTHER!!!"
            #end

            if (c.netiquette_violation && !tag_as_spam) 
                puts "bad mouth but didn't detect"
            elsif (!c.netiquette_violation && tag_as_spam)
                puts "good mouth but suspected from him #{c.comment[0..150]}"
            end
        end

        puts "count_bad: #{count_bad} | count_good: #{count_good}"
        #puts "total_bad: #{total_bad} | total_good: #{total_good}"
        #puts "avg_bad: #{(total_bad / count_bad)} | avg_good: #{(total_good / count_good)}"
        puts "\nError: #{err / (count_bad + count_good)} (failed with #{err} comments out of #{count_bad + count_good})"
      end

      def self.likelihood(punigram, text)
        text = text.downcase.gsub('<br />', ' ').gsub('...', ' ... ').gsub(/\s{2,}/, ' ').gsub(/<\/?[^>]*>/, "").gsub(',', ' , ').gsub('.', ' . ').gsub('!', ' ! ').gsub('¡', ' ¡ ').gsub(/:[a-z]+:/, '')
        p = 0
        text.split(' ').each do |w|
            if punigram.include?(w)
                p += Math.log(punigram[w]) 
                else
                p += Math.log(punigram[UNK_TAG]) 
                end
        end

        Math.exp(p)
        # p
  end
end
