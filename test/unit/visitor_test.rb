require "test_helper"

# Most of the visitor tests generate a tree from the the expression `1 + x * 3`.
# The S-expression below serves as visual documentation for the generated tree.
#
# (expression
#   (sum
#     (number)
#     ("+")
#     (product
#       (variable)
#       ("*")
#       (number))))
class VisitorTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new("math")
  end

  def test_default_on_hook
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:on) { |node| acc << node.type }
    visitor.visit

    assert_equal(
      %i(expression sum number + product variable * number),
      acc,
    )
  end

  def test_custom_visitor_hooks
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    method = ->(node) { acc << node.type }
    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:on_sum, method)
    visitor.define_singleton_method(:on_number, method)
    visitor.define_singleton_method(:on_expression, method)
    visitor.visit

    assert_equal(
      %i(expression sum number number),
      acc,
    )
  end

  def test_default_on_hook_doesnt_run_when_a_custom_hook_is_defined
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:on) { |node| acc << node.type }
    visitor.define_singleton_method(:on_sum) { |node| acc << :custom_sum }
    visitor.visit

    assert_equal(
      %i(expression custom_sum number + product variable * number),
      acc,
    )
  end

  def test_default_around_hook
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    method = ->(node, &block) do
      acc << "before:#{node.type}"
      block.call
      acc << "after:#{node.type}"
    end
    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:around, method)
    visitor.visit

    assert_equal(
      %w(
        before:expression
        before:sum
        before:number
        after:number
        before:+
        after:+
        before:product
        before:variable
        after:variable
        before:*
        after:*
        before:number
        after:number
        after:product
        after:sum
        after:expression
      ),
      acc,
    )
  end

  def test_custom_around_hooks
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    method = ->(node, &block) do
      acc << "before:#{node.type}"
      block.call
      acc << "after:#{node.type}"
    end
    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:around_sum, method)
    visitor.define_singleton_method(:around_number, method)
    visitor.define_singleton_method(:around_expression, method)
    visitor.visit

    assert_equal(
      %w(
        before:expression
        before:sum
        before:number
        after:number
        before:number
        after:number
        after:sum
        after:expression
      ),
      acc,
    )
  end

  def test_around_hooks_traverse_children_only_when_yielding
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:on) { |node| acc << node.type }
    visitor.define_singleton_method(:around_product) { |node, &block| }
    visitor.visit

    assert_equal(
      %i(expression sum number + product),
      acc,
    )
  end

  def test_default_around_hook_doesnt_run_when_a_custom_hook_is_defined
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    acc = []

    method = ->(node, &block) do
      acc << "before:#{node.type}"
      block.call
      acc << "after:#{node.type}"
    end
    visitor = TreeStand::Visitor.new(tree.root_node)
    visitor.define_singleton_method(:around, method)
    visitor.define_singleton_method(:around_sum) { |node| acc << "around:sum" }
    visitor.visit

    assert_equal(
      %w(
        before:expression
        around:sum
        after:expression
      ),
      acc,
    )
  end
end
