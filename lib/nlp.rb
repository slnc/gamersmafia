# -*- encoding : utf-8 -*-
module Nlp
  module Extractor
    def self.extract_texts(object)
      case object.class.name
      when 'String'
        self.extract_texts_from_string(object)
      else  # Assume it's an ActsAsContent object
        self.extract_texts_from_content(object)
      end
    end

    def self.extract_texts_from_content(content)
      sentences = []
      sentences<< self.extract_texts(content.title) if content.respond_to?(:title)
      if content.respond_to?(:description)
        sentences<< self.extract_texts_from_string(content.description)
      end
      if content.respond_to?(:main)
        sentences<< self.extract_texts_from_string(content.main)
      end

      content.comments.each do |comment|
        sentences<< self.extract_texts_from_string(comment.comment)
      end
      sentences.join(". ")
    end

    def self.extract_texts_from_string(some_string)
      return [] unless some_string
      some_string.split("<br />")
    end
  end

  module Dictionary
    # Returns a dict of word frequencies for the last 90 days.
    def self.word_frequencies
      frequencies = {}
      Content.find(
            :all,
            :conditions => "created_on >= now() - '6 months'::interval",
            :order => 'created_on DESC').each do |content|
        text = Nlp::Extractor.extract_texts_from_content(content)
        Nlp::Summarization::TextRank.tokenize(text).each do |word|
          frequencies[word] = 0 unless frequencies.has_key?(word)
          frequencies[word] = frequencies[word] + 1
        end
      end
      frequencies.sort_by { |word, frequency| -frequency }
    end

    def self.word_frequencies_to_csv(output_filename)
      CSV.open(output_filename, "w") do |csv|
        csv << ["word", "frequency"]
        self.word_frequencies.each do |word, frequency|
          csv << [word, frequency]
        end
      end
    end

    # TODO(slnc): add a more accurate POS Tagger
  end

  module PosTagger
    POS_NOUN = 1
    POS_ADJECTIVE = 2
    POS_OTHER = 3
    POS_VARIES = 4

    MAPPING_POS = {
      :adjective => POS_ADJECTIVE,
      :noun => POS_NOUN,
      :other => POS_OTHER,
      :varies => POS_VARIES,
    }

    NON_CONTENT_POS_TYPES = [POS_OTHER, POS_VARIES]

    # Extracts all content words from text.
    #
    # An unseen word will be used to be a content word.
    def self.extract_content_words(text)
      words = Nlp::Tokenizer.tokenize(text)
      dictionary_words = DictionaryWord.find(
          :all,
          :conditions => ['name IN (?) AND pos_type IN (?)',
                          words.uniq, Nlp::PosTagger::NON_CONTENT_POS_TYPES])

      invalid_words = dictionary_words.collect { |word| word.name }
      final_words = []
      words.each do |word|
        next if invalid_words.include?(word)
        final_words<< word
      end
      final_words
    end
  end

  module Tokenizer
    # Convert a text into a sequence of words.
    #
    # Anything not matching RE_WORD will be treated as a word separator.
    # Urls will be removed.
    # Numbers will be removed.
    # The output string will be lowercased.
    def self.tokenize(some_text)
      some_text = some_text.downcase
      some_text.gsub!(/(<[^>]+>)/, " ")
      some_text.gsub!("&nbsp;", " ")
      some_text.gsub!("&aacute;", "á")
      some_text.gsub!("&ntilde;", "ñ")
      some_text.gsub!("&eacute;", "é")
      some_text.gsub!("&gt;", ",")
      some_text.gsub!("&lt;", ",")
      some_text.gsub!("&iacute;", "í")
      some_text.gsub!("&oacute;", "ó")
      some_text.gsub!("&uacute;", "ú")
      some_text.gsub!("&quot;", " ")
      some_text.gsub!(")", ",")
      some_text.gsub!("(", ",")
      some_text.gsub!(/http:\/\/[\S]+/, " ")
      words = some_text.downcase.gsub(
          /[^a-zA-ZáéíóúñÁÉÍÓÚÑ]{2,}/, " ").split(" ")
      words.delete_if { |w| w.size == 1 }
    end

    # Converts a string into a sequence of words.
    #
    # Works like tokenize but it preserves punctuation.
    def self.tokenize_with_punctuation(some_text)
      some_text = some_text.downcase
      some_text.gsub!(/(<[^>]+>)/, " ")
      some_text.gsub!("&nbsp;", " ")
      some_text.gsub!("&aacute;", "á")
      some_text.gsub!("&eacute;", "é")
      some_text.gsub!("&ntilde;", "ñ")
      some_text.gsub!("&iacute;", "í")
      some_text.gsub!("&oacute;", "ó")
      some_text.gsub!("&uacute;", "ú")
      some_text.gsub!("&quot;", " ")
      some_text.gsub!(")", ",")
      some_text.gsub!("(", ",")
      some_text.gsub!(/http:\/\/[\S]+/, " ")
      words = some_text.downcase.gsub(/([.,¡!¿?])/, " \\1 ").gsub(
          /[^.,¡!?¿a-zA-ZáéíóúñÁÉÍÓÚÑ]{2,}/, " ").split(" ")
    end
  end

  module Summarization
    CONVERGENCE_LIMIT = 0.0001
    MAX_ITERATIONS = 30
    WINDOW = 10


    if nil
      def self.summarize(content, desired_summary_word_length)
        sentences = self.extract_sentences(content)
        sentences_graph = self.build_graph_from_sentences(sentences)
        self.compute_pairwise_similarity(sentences_graph)
        self.compute_ranks(sentences_graph)
        self.build_summary(sentences_graph, desired_summary_word_length)
      end

    end

    module TextRank
      def self.summarize_text(some_text)
        content_words = Nlp::PosTagger.extract_content_words(some_text)
        words = Nlp::Tokenizer.tokenize(some_text)
        non_content_words = words - content_words
        graph = self.build_graph(content_words)
        target_keywords = graph.size / 3
        target_keywords = 15 if target_keywords > 15
        self.add_cooccurrence_relations(words, graph, Summarization::WINDOW)
        self.converge(graph)
        out = graph.sort_by { |word, node| -node.score }
        ranked_words = out.collect {|word, node| [word, node.score]}
        final_out = []
        target_keywords.times do |i|
          final_out.append(ranked_words[i])
        end
        final_out
        tokenized_with_punctuation = Nlp::Tokenizer.tokenize_with_punctuation(
            some_text)
        self.merge_adjacent_keywords(
            tokenized_with_punctuation, target_keywords, graph)
      end

      class Node
        attr_accessor :score, :neighbors
        attr_reader :word

        def initialize(word)
          @word = word
          @neighbors = []
          @score = 1.0
        end

        def to_s
          "#{@word} #{@score} #{@neighbors.size}"
        end

        # Two nodes are considered equal if they have the same word, the same
        # score and the same number of neighbors.
        def ==(another_node)
          if self.word != another_node.word || self.score != another_node.score
            return false
          end

          # We compare neighbors
          ours = self.neighbors.collect { |neighbor| neighbor.to_s }
          theirs = another_node.neighbors.collect { |neighbor| neighbor.to_s }
          ours.sort == theirs.sort
        end

        def bidirectional_link(neighbor)
          return if neighbor == self
          self.neighbors<< neighbor if !self.neighbors.include?(neighbor)
          neighbor.neighbors<< self if !neighbor.neighbors.include?(self)
        end
      end

      private
      def self.converge(graph, d=0.85)
        iterations = 0
        convergence_error = CONVERGENCE_LIMIT + 1
        while (convergence_error > Summarization::CONVERGENCE_LIMIT &&
               iterations < Summarization::MAX_ITERATIONS)
          last_convergence_error = convergence_error
          convergence_error = 0
          new_ws = {}
          graph.each do |word, node|
            all_summed = self.calculate_all_summed(word, node, graph)
            new_ws[word] = (1 - d) + d * (all_summed)

            # Update
            convergence_error += (node.score - new_ws[word]).abs
            node.score = new_ws[word]
          end

          Rails.logger.debug(
              "Convergence error: #{convergence_error} (last:" +
              "  #{last_convergence_error})")
          iterations += 1
        end
        Rails.logger.debug(
            "Converged after: #{iterations} (#{convergence_error})")
      end

      def self.calculate_all_summed(word, node, graph)
        out = 0.0
        node.neighbors.each do |incoming_node|
          numerator = self.weight(incoming_node, node)
          denominator = incoming_node.neighbors.collect { |neighbor|
            self.weight(incoming_node, neighbor)
          }.sum
          neighbor_sum = (numerator / denominator) * node.score
          out += neighbor_sum
        end
        out
      end

      # Returns the weight of the edge between src and dst.
      def self.weight(src, dst)
        1.0
      end

      # Adds bidirectional edges between cooccurring words.
      #
      # Two words are cooccurring if there are less than 'window_size/2' words
      # between them.
      def self.add_cooccurrence_relations(words, graph, window_size)
        outer_idx = 0
        words.each do |word|
          node = graph[word]
          if node.nil?
            next
          end
          first_i = outer_idx + 1
          right_idx = first_i+(window_size/2 + window_size % 2)
          right_neighbors = words[first_i..right_idx]
          right_neighbors.each do |neighbor_word|
            if !graph.has_key?(neighbor_word)
              next
            end
            node.bidirectional_link(graph[neighbor_word])
          end
          outer_idx += 1
        end
      end

      def self.build_graph(words)
        out = {}
        words.each do |word|
          if !out.has_key?(word)
            out[word] = Node.new(word)
          end
        end
        out
      end

      def self.tag_candidate_keywords(all_words, graph)
        tagged_words = []
        all_words.each do |word|
          if graph.include?(word)
            tagged_words<< "#{word}/k"
          else
            tagged_words<< word
          end
        end
        tagged_words
      end

      def self.merge_adjacent_keywords_p(tagged_words)
        keywords_merged = true
        while keywords_merged
          keywords_merged = false
          tagged_words.size.times do |i|
            cur_word = tagged_words[i]
            next_word = tagged_words[i+1]
            break if next_word.nil?
            if cur_word.include?("/k") && next_word.include?("/k")
              tagged_words[i] = "#{cur_word} #{next_word}".gsub("/k", "") + "/k"
              tagged_words.delete_at(i+1)
              i += 1
              keywords_merged = true
            end
          end
        end
      end

      # Removes unigrams that are also part of non-unigram keyphrases.
      #
      # Eg: if keyphrases contains ['hello', 'hello world'] then the output will
      # be ['hello world'].
      def self.remove_unigrams_part_of_compounds(keyphrases)
        # Collect all words that are part of compound words
        unigrams_part_of_compound = []
        keyphrases.each do |keyphrase|
          next if !keyphrase.include?(" ")
          keyphrase.split(" ").each do |single_keyword|
            unigrams_part_of_compound<< single_keyword
          end
        end

        # Remove all single words that are also part of compound words
        keyphrases.size.times do |i|
          break if i >= keyphrases.size
          keyphrase = keyphrases[i]
          next if keyphrase.include?(" ")

          if unigrams_part_of_compound.include?(keyphrase)
            keyphrases.delete_at(i)
            i += 1
          end
        end
      end

      # Retrieves all keyphrases from a list of tagged words.
      def self.get_keyphrases(tagged_words)
        # Collect keyphrases
        final_keyphrases = []
        tagged_words.each do |word|
          final_keyphrases<< word.gsub("/k", "") if word.include?("/k")
        end
        final_keyphrases.uniq || []
      end

      # Merges keywords into keyphrases respecting scores and max words.
      #
      # When 2 or 3 more adjacent keywords are merged the max score of the group
      # is selected.
      #
      # Args:
      # - all_words: sequence of words with the original text with punctuation
      #     preserved. Eg: ["hello", "world", ".", "how", "are", "you"].
      # - graph: the TextRank graph for the corresponding text with final
      #     weights.
      # - max_keyphrases: int with number of max words to include
      def self.merge_adjacent_keywords(all_words, max_keyphrases, graph)
        tagged_words = self.tag_candidate_keywords(all_words, graph)
        self.merge_adjacent_keywords_p(tagged_words)
        keyphrases = self.get_keyphrases(tagged_words)

        self.remove_unigrams_part_of_compounds(keyphrases)
        sorted_keyphrases = self.sort_by_keyphrase_score(keyphrases, graph)

        top_keyphrases = sorted_keyphrases[0..max_keyphrases-1]
        top_keyphrases = top_keyphrases.collect {|word, score| word}
        top_keyphrases.sort
      end

      # Sorts a list of keyphrases by their TextRank score.
      #
      # In non-unigram keyphrases the score of the keyphrase will be the max
      # individual score of any keyword contained within it.
      def self.sort_by_keyphrase_score(keyphrases, graph)
        keyphrases_rank = {}
        keyphrases.each do |keyphrase|
          words = keyphrase.split(" ")
          words.each do |word|
            if !graph.include?(word)
              raise "Graph.include?('#{word}') is false ('#{keyphrase}')"
            end
          end
          scores = words.collect {|word| graph[word].score }
          keyphrases_rank[keyphrase] = scores.max
        end

        keyphrases_rank.sort_by {|word, score| -score }
      end
    end
  end
end
