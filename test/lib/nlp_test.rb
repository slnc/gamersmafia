require 'test_helper'

TextRank = Nlp::Summarization::TextRank

class TextRankTest < ActiveSupport::TestCase

  PAPER_KEYPHRASE_EXTRACTION = <<-END
  Compatibility of systems of linear constraints over the set of natural numbers.
  Criteria of compatibility of a system of linear Diophantine equations, strict
  inequations, and nonstrict inequations are considered. Upper bounds for
  components of a minimal set of solutions and algorithms of construction of
  minimal generating sets of solutions for all types of systems are given.
  These criteria and the corresponding algorithms for constructing a minimal
  supporting set of solutions can be used in solving all the considered types
  systems and systems of mixed types.
  END

  PAPER_KEYPHRASE_EXPECTED_SORTED = [
      "compatibility",
      "criteria",
      "linear constraints",
      "linear diophantine equations",
      "nonstrict inequations",
      "strict inequations",
      "upper bounds",
  ]

  test "summarize_test keyphrase" do
    actual_summary = TextRank.summarize_text(
        TextRankTest::PAPER_KEYPHRASE_EXTRACTION)
    assert_equal(
        TextRankTest::PAPER_KEYPHRASE_EXPECTED_SORTED, actual_summary)
  end

  test "build_graph" do
    node_hello = TextRank::Node.new("hello")
    node_world = TextRank::Node.new("world")
    expected_graph = {"hello" => node_hello, "world" => node_world}
    assert_equal(
        expected_graph, TextRank.send(:build_graph, ["hello", "world"]))
  end

  test "node bidirectional_link" do
    node_hello = TextRank::Node.new("hello")
    node_world = TextRank::Node.new("world")
    assert_equal 0, node_world.neighbors.size
    assert_equal 0, node_hello.neighbors.size

    node_hello.bidirectional_link(node_world)

    assert_equal [node_hello], node_world.neighbors
    assert_equal [node_world], node_hello.neighbors
  end

  [
    ["", %w()],
    ["Hello World", %w(hello world)],
    ["hello.,world", %w(hello world)],
    ["hello-world", %w(hello-world)],
    ["hell&oacute;", %w(helló)],
    ["hello world http://www.example.com/fuul?foo=bar", %w(hello world)],
    ["<a href=\"http://google.com/\">Google</a>", %w(google)],
  ].each do |input, expected_out|
    test "tokenize #{input} #{expected_out}" do
      assert_equal expected_out, Nlp::Tokenizer.send(:tokenize, input)
    end
  end

  [
    ["", %w()],
    ["Hello World", %w(hello world)],  # downcase
    ["hello.,world", %w(hello . , world)],
    ["hello-world", %w(hello-world)],
    ["hello world http://www.example.com/fuul?foo=bar", %w(hello world)],
  ].each do |input, expected_out|
    test "tokenize_with_punctuation #{input} #{expected_out}" do
      assert_equal expected_out, Nlp::Tokenizer.send(
          :tokenize_with_punctuation, input)
    end
  end


  test "add_cooccurrence_relations simple" do
    # Build input_graph
    node_hello = TextRank::Node.new("hello")
    node_world = TextRank::Node.new("world")
    input_graph = {"hello" => node_hello, "world" => node_world}

    # Build expected_graph
    node_hello = TextRank::Node.new("hello")
    node_world = TextRank::Node.new("world")
    node_hello.neighbors<< node_world
    node_world.neighbors<< node_hello
    expected_graph = {"hello" => node_hello, "world" => node_world}

    TextRank.send(
        :add_cooccurrence_relations, ["hello", "world"], input_graph, 10)

    assert_equal(expected_graph, input_graph)
  end

  test "merge_adjacent_keywords 1" do
    graph = self.setup_graph(%w(hello world bar))
    merged_kws = TextRank.send(
      :merge_adjacent_keywords, %w(hello world foo bar), 10, graph)
    assert_equal ["bar", "hello world"], merged_kws
  end

  test "merge_adjacent_keywords 2" do
    graph = self.setup_graph(%w(hello world))
    merged_kws = TextRank.send(
      :merge_adjacent_keywords, %w(hello world), 10, graph)
    assert_equal ["hello world"], merged_kws
  end

  test "merge_adjacent_keywords 3" do
    graph = self.setup_graph(%w(hello world))
    merged_kws = TextRank.send(
      :merge_adjacent_keywords, %w(one hello room world), 10, graph)
    assert_equal %w(hello world), merged_kws
  end

  test "merge_adjacent_keywords 4" do
    graph = self.setup_graph(%w(linear constraints diophantine equations))
    merged_kws = TextRank.send(
        :merge_adjacent_keywords,
        %w(linear constraints foo linear diophantine equations),
        10,
        graph)
    assert_equal(
        ["linear constraints", "linear diophantine equations"], merged_kws)
  end

  def setup_graph(words)
    graph = {}
    words.each do |word|
      graph[word] = TextRank::Node.new(word)
      graph[word].score = 1
    end
    graph
  end
end
