require 'test_helper'

class SummarizationTest < ActiveSupport::TestCase
  test "extract_sentences_from_string should work" do
  end

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
      'linear constraints',
      'linear diophantine equations',
      'natural numbers',
      'nonstrict inequations',
      'strict inequations',
      'upper bounds',
  ]

  test "summarize_test keyphrase" do
    assert_equal(
        SummarizationTest::PAPER_KEYPHRASE_EXPECTED_SORTED,
        Summarization.summarize_text(SummarizationTest::PAPER_KEYPHRASE_EXTRACTION))
  end


  test "build_graph" do
    assert_equal %w(hello world), Summarization.build_graph(["hello", "world"])
  end

  test "tokenize" do
    assert_equal %w(hello world), Summarization.tokenize("hello world")
  end
end
