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
    target_keywords = graph.size / 2
    self.add_cooccurrence_relations(words, graph, Summarization::WINDOW)
    self.converge(graph)
    out = graph.sort_by { |word, node| -node.score }
    ranked_words = out.collect {|word, node| [word, node.score]}
    final_out = []
    target_keywords.times do |i|
      final_out.append(ranked_words[i])
    end
    final_out
    merged_keywords = self.merge_adjacent_keywords(
        words, final_out.collect {|word, score| word})
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
 "the",
 "these",
 "types",
 "upper",
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
 "ocupaba",
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
 "vaya",
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
        puts "new ws for #{word}: #{new_ws[word]}"

        # Update
        convergence_error += (node.score - new_ws[word]).abs
        node.score = new_ws[word]
      end
      puts " --- "

      #graph.each do |word, node|
      #  node.score = new_ws[word]
      #end
      puts "Convergence error: #{convergence_error} (last: #{last_convergence_error})"
      #if iterations > 1 && convergence_error > last_convergence_error
      #  raise "Not converging, exiting.."
      #end
      iterations += 1
    end
    puts " >>>>>>>>>>>> Converged after: #{iterations} (#{convergence_error})"
  end

  def self.calculate_all_summed(word, node, graph)
    puts "calculate_all_summed(#{node}: #{node.neighbors.collect {|node| " " + node.word}}"
    out = 0.0
    node.neighbors.each do |incoming_node|
      numerator = self.weight(incoming_node, node)
      denominator = incoming_node.neighbors.collect { |neighbor|
        self.weight(incoming_node, neighbor)
      }.sum
      puts "neighbor_sum: #{numerator} / #{denominator} * #{node.score}"
      neighbor_sum = (numerator / denominator) * node.score
      out += neighbor_sum
    end
    puts "\n\n"
    out
  end

  def self.weight(src_node, dst_node)
    1.0
  end

  private
  def self.add_cooccurrence_relations(words, graph, window)
    outer_idx = 0
    puts ">>>>>>>>>>> ADDDING COOCURRENCE RELATIONSHIPS"
    words.each do |word|
      puts "-- procesing #{word}"
      node = graph[word]
      puts " --- node: #{node}"
      if node.nil?
        puts "node.nil!"
        next
      end
      first_i = outer_idx + 1
      neighbors = words[first_i..first_i+(window/2)]
      neighbors.each do |neighbor_word|
        puts "  ---- evaluating neighbor: #{neighbor_word}"
        if ARTICLES_ADVERBS_VERBS.include?(neighbor_word)
          next
        end
        puts "  ---- adding!"
        node.bidirectional_link(graph[neighbor_word])
      end
      outer_idx += 1
    end

    puts "=========== FINAL GRAPH ==============="
    graph.each do |word, node|
      puts "node: #{node}: #{node.neighbors}"
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
    some_text.downcase.gsub(".", " ").gsub(",", " ").gsub(/[^a-zA-ZáéíóúñÁÉÍÓÚÑ]{2,}/, " ").split(" ")
  end

  def self.merge_adjacent_keywords(words, target_keywords)
    merged_keyword = true
    copied_target_kws = target_keywords.dup
    puts "#{copied_target_kws} vs #{target_keywords}"
    while merged_keyword
      merged_keyword = false
      i = 0
      (words.size - 1).times do |i|
        if copied_target_kws.include?(words[i]) && copied_target_kws.include?(words[i+1])
          copied_target_kws.delete(words[i])
          copied_target_kws.delete(words[i+1])
          new_kw = "#{words[i]} #{words[i+1]}"
          copied_target_kws<< new_kw
          words[i+1] = new_kw
          puts " going to delete #{words[i]} and replace with #{new_kw}"
          words.delete(i)
          merged_keyword = true
          break
        end
      end
    end
    copied_target_kws
  end
end
