module Summarization
  WINDOW = 10

  if nil
    def self.summarize(content, desired_summary_word_length)
      sentences = self.extract_sentences(content)
      sentences_graph = self.build_graph_from_sentences(sentences)
      self.compute_pairwise_similarity(sentences_graph)
      self.compute_ranks(sentences_graph)
      self.build_summary(sentences_graph, desired_summary_word_length)
    end

    def self.extract_sentences(object)
      case object.class.name
      when 'String':
        self.extract_sentences_from_string(object)
      else  # Assume it's an ActsAsContent object
        self.extract_sentences_from_content(object)
      end
    end

    def self.extract_sentences_from_content(content)
      sentences = []
      sentences<< self.extract_sentences(content.title)
      if content.respond_to?(:description)
        sentences<< self.get_all_text(content.description)
      end
      if content.respond_to?(:main)
        sentences<< self.extract_sentences(content.main)
      end

      content.comments.each do |comment|
        sentences<< self.extract_sentences(comment.comment)
      end
    end

    def self.extract_sentences_from_string(some_string)
      some_string.split("<br />")
    end
  end

  def self.summarize_text(some_text)
    words = self.tokenize(some_text)
    graph = self.build_graph(words)
    target_keywords = graph.size / 3
    self.add_cooccurrence_relations(words, graph, Summarization::WINDOW)
    self.converge(graph)
    out = graph.sort_by { |word, node| -node.score }
    ranked_words = out.collect {|word, node| [word, node.score]}
    final_out = []
    target_keywords.times do |i|
      final_out.append(ranked_words[i])
    end
    final_out
    tokenized_with_punctuation = self.tokenize_with_punctuation(some_text)
    merged_keywords = self.merge_adjacent_keywords(
        tokenized_with_punctuation, target_keywords, graph)
  end

  ARTICLES_ADVERBS_VERBS = [
 "a",
 "all",
 "and",
 "are",
 "be",
 "can",
 "considered",
 "constructing",
 "corresponding",
 "for",
 "generating",
 "given",
 "in",
 "mixed",
 "of",
 "over",
 "solving",
 "supporting",
 "set",
 "the",
 "these",
 "types",
 "used",

 # SPANISH
 "abrimos",
 "acuerdo",
 "agolpara",
 "aguantó",
 "ahorrarte",
 "ahorrarte",
 "al",
 "algo",
 "allí",
 "ansiábamos",
 "ante",
 "anunciado",
 "aparece",
 "apaña",
 "armado",
 "asi",
 "así",
 "aun",
 "aunque",
 "bajarse",
 "bajo",
 "bastante",
 "bien",
 "cambiar",
 "cambiarla",
 "casi",
 "cito",
 "con",
 "congelarse",
 "conmigo",
 "constantemente",
 "contará",
 "contemplaban",
 "continuas",
 "convertido",
 "creo",
 "cuenta",
 "da",
 "de",
 "del",
 "den",
 "desarrollado",
 "desde",
 "dios",
 "disponible",
 "divertían",
 "el",
 "el",
 "ella",
 "ellos",
 "ellos",
 "empieza",
 "en",
 "encabeza",
 "encuentra",
 "entre",
 "es",
 "eso",
 "estará",
 "estas",
 "este",
 "esto",
 "estoy",
 "evitar",
 "fue",
 "fueran",
 "funciona",
 "funcionar",
 "funcione",
 "funciono",
 "guardar",
 "ha",
 "hacer",
 "hacerse",
 "han",
 "hará",
 "hasta",
 "hay",
 "haya",
 "he",
 "hecho",
 "hechos",
 "hice",
 "hola",
 "importante",
 "ir",
 "iria",
 "joder",
 "jugaba",
 "la",
 "lanzado",
 "lanzando",
 "lanzó",
 "las",
 "le",
 "llamar",
 "lleva",
 "llevara",
 "lo",
 "los",
 "marca",
 "marginados",
 "mas",
 "me",
 "mejor",
 "mejorado",
 "mete",
 "mi",
 "mientras",
 "misma",
 "mismo",
 "modo",
 "momento",
 "momento",
 "mucho",
 "más",
 "nada",
 "nadie",
 "ninguna",
 "nisu",
 "no",
 "nosotros",
 "nueva",
 "o",
 "gastar",
 "cuanto",
 "poniendo",
 "ocupaba",
 "ello",
 "debes",
 "demás",
 "guardadas",
 "pagar",
 "par",
 "para",
 "parar",
 "pero",
 "personaliazble",
 "peta",
 "poco",
 "pocos",
 "poner",
 "por desgracia",
 "por",
 "porque",
 "posee",
 "primera",
 "pronto",
 "pueda",
 "puedo",
 "pues",
 "que",
 "queden",
 "quería",
 "quiero",
 "realizada",
 "rechazados",
 "reiniciarse",
 "responde",
 "sabido",
 "se",
 "sea",
 "segunda",
 "ser",
 "si",
 "siguiente",
 "sistema",
 "situada",
 "sobre",
 "solo",
 "su",
 "subir",
 "sus",
 "sustituirlo",
 "tan",
 "tanto",
 "tarde",
 "te",
 "tengas",
 "tengo",
 "tenéis",
 "tiene",
 "tienes",
 "tienes",
 "tirando",
 "todo",
 "todos",
 "tras",
 "través",
 "tu",
 "tuvimos",
 "un",
 "una",
 "unas",
 "unos",
 "unos",
 "vale",
 "entrar",
 "recomendamos",
 "otra",
 "parte",
 "estamos",
 "vaya",
 "siguiente",
 "siguientes",
 "consta",
 "perderás",
 "podremos",
 "empezar",
 "asimilar",
 "atestigua",
 "veces",
 "venirse",
 "vez",
 "vuelve",
 "y",
 "ya",
 "yo",
  ]

  # TODO(slnc): proper POS Tagger

  MAX_ITERATIONS = 30
  CONVERGENCE_LIMIT = 0.0001

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

    # Two nodes are considered equal if they have the same word, the same score
    # and the same number of neighbors.
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

      Rails.logger.debug("Convergence error: #{convergence_error} (last: #{last_convergence_error})")
      iterations += 1
    end
    Rails.logger.debug("Converged after: #{iterations} (#{convergence_error})")
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

  def self.weight(src_node, dst_node)
    1.0
  end

  private
  def self.add_cooccurrence_relations(words, graph, window)
    outer_idx = 0
    words.each do |word|
      node = graph[word]
      if node.nil?
        next
      end
      first_i = outer_idx + 1
      neighbors = words[first_i..first_i+(window/2)]
      neighbors.each do |neighbor_word|
        if ARTICLES_ADVERBS_VERBS.include?(neighbor_word)
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
      if !out.has_key?(word) && !ARTICLES_ADVERBS_VERBS.include?(word)
        out[word] = Node.new(word)
      end
    end
    out
  end

  def self.tokenize(some_text)
    some_text = some_text.downcase
    some_text.gsub!(/http:\/\/[\S]+/, " ")
    words = some_text.downcase.gsub(/[^a-zA-ZáéíóúñÁÉÍÓÚÑ]{2,}/, " ").split(" ")
    words.delete_if { |w| w.size == 1 }
  end

  def self.tokenize_with_punctuation(some_text)
    some_text = some_text.downcase
    some_text.gsub!(/http:\/\/[\S]+/, " ")
    words = some_text.downcase.gsub(/([.,¡!¿?])/, " \\1 ").gsub(/[^.,¡!?¿a-zA-ZáéíóúñÁÉÍÓÚÑ]{2,}/, " ").split(" ")
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

  def self.remove_unigrams_part_of_compounds(final_keyphrases)
    # remove single words that also appear as part of a keyphrase
    # Collect all words that are part of compound words
    single_words_part_of_compound = []
    final_keyphrases.each do |final_keyphrase|
      next if !final_keyphrase.include?(" ")
      final_keyphrase.split(" ").each do |single_keyword|
        single_words_part_of_compound<< single_keyword
      end
    end

    # Remove all single words that are also part of compound words
    final_keyphrases.size.times do |i|
      break if i >= final_keyphrases.size
      final_keyphrase = final_keyphrases[i]
      next if final_keyphrase.include?(" ")

      if single_words_part_of_compound.include?(final_keyphrase)
        final_keyphrases.delete_at(i)
        i += 1 # final_keyphrase.count(final_keyphrase)
      end
    end
  end

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
  # When 2 or 3 more adjacent keywords are merged the max score of the group is
  # selected.
  #
  # Args:
  # - all_words: sequence of words with the original text with punctuation
  #     preserved. Eg: ["hello", "world", ".", "how", "are", "you"].
  # - graph: the TextRank graph for the corresponding text with final weights.
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

  def self.sort_by_keyphrase_score(final_keyphrases, graph)
    # Calculate rank of keyphrases by taking max rank of any given word in a
    # keyphrase
    keyphrases_rank = {}
    final_keyphrases.each do |keyphrase|
      single_words = keyphrase.split(" ")
      single_words.each do |single_word|
        if !graph.include?(single_word)
          raise "Graph doesn't include #{single_word} which is in #{keyphrase}"
        end
      end
      scores = single_words.collect {|word| graph[word].score }
      rank = scores.max
      keyphrases_rank[keyphrase] = rank
    end

    keyphrases_rank.sort_by {|word, score| -score }
  end
end
