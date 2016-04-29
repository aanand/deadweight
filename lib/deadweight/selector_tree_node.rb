class Deadweight
  class SelectorTreeNode
    include Comparable
    include DeadweightHelper

    attr_accessor :selector, :original_selectors, :declarations, :children

    def initialize(selector)
      self.selector = selector
      self.original_selectors = []
      self.declarations = []
      self.children = []
    end

    def from_css?
      !original_selectors.empty?
    end

    def <=>(other)
      return false unless other.is_a?(SelectorTreeNode)
      selector <=> other.selector
    end

    def inspect
      "{#{selector.inspect} => #{children.inspect}}"
    end

    def add_node(node)
      insert_location = Bisect.bisect_left(children, node)

      # Already there
      return if children[insert_location] == node

      if children[insert_location-1] && node.implies?(children[insert_location-1])
        children[insert_location-1].add_node(node)
      elsif children[insert_location] && children[insert_location].implies?(node)
        node.add_node(children[insert_location])
        children[insert_location] = node
      else
        children.insert(insert_location, node)
      end
      self
    end

    def and_descendants
      [self] + descendants
    end

    def descendants
      children + children.map(&:descendants).flatten
    end

    # .hello is implied by .hello.world, because if something matches .hello.world, it has to also match .hello.
    # Need to watch out for .hello and .hello_world, since that is not implied
    def implies?(other)
      return true if other.selector == selector
      return false unless selector.start_with?(other.selector)
      # If other ends on a symbol like a ] or a ), then it can't be a case of .hello and .hello_world
      return true if other.selector[-1] =~ /[^\w-]/

      !!(selector[other.selector.size] =~ /[^\w-]/)
    end

  end

end