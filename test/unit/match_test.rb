require "test_helper"

class MatchTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new("math")
    @tree = @parser.parse_string(nil, <<~MATH)
      1 + x * 3 + 2
    MATH
  end

  def test_single_match
    matches = @tree.query(<<~QUERY)
      (sum
        left: (number)
        right: (product))
    QUERY

    assert_equal(1, matches.length)
    assert_predicate(matches.first.captures, :empty?)
  end

  def test_multiple_matches
    matches = @tree.query(<<~QUERY)
      (sum)
    QUERY

    assert_equal(2, matches.length)

    matches.map(&:captures).each do |captures|
      assert_predicate(captures, :empty?)
    end
  end

  def test_single_match_with_capture
    matches = @tree.query(<<~QUERY)
      (sum
        left: (number)
        right: (product)) @1_plus_x_times
    QUERY

    assert_equal(1, matches.length)
    assert_equal(1, matches.first.captures.size)
    assert_equal("1 + x * 3", matches.dig(0, "1_plus_x_times").node.text)
  end

  def test_mutliple_matches_with_captures
    matches = @tree.query(<<~QUERY)
      (sum) @sum
    QUERY

    assert_equal(2, matches.length)

    matches.map(&:captures).each do |captures|
      assert_equal(1, captures.size)
    end

    assert_equal("1 + x * 3 + 2", matches.dig(0, "sum").node.text)
    assert_equal("1 + x * 3", matches.dig(1, "sum").node.text)
  end

  def test_match_with_multiple_captures
    match = @tree.query(<<~QUERY).first
      (sum
        left: (number) @number
        right: (product) @product) @1_plus_x_times
    QUERY

    assert_equal(3, match.captures.size)
    assert_equal("1", match["number"].node.text)
    assert_equal("x * 3", match["product"].node.text)
    assert_equal("1 + x * 3", match["1_plus_x_times"].node.text)
  end
end
