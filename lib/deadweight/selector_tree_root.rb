class Deadweight
  class SelectorTreeRoot < SelectorTreeNode

    def initialize
      super('ROOT')
    end

    def inspect
      "<#{selector.inspect} => #{children.inspect}>"
    end

    def add_node(node)
      super(node)
      generate_implied_selectors(node.selector).each do |implied_selector|
        super(SelectorTreeNode.new(implied_selector))
      end
    end

    def generate_implied_selectors(selector)
      operator_types = [:PLUS, :GREATER, :TILDE, :S]
      selector_types = [:IDENT, :HASH, "*"]

      selectors = []
      built_selector = ""
      tokenize_selector(selector).each do |type, text|
        break unless operator_types.include?(type) || selector_types.include?(type) || type == '.'
        break if type == :IDENT && text.start_with?("@")
        built_selector << text

        selectors << built_selector.dup.strip if selector_types.include?(type)
      end

      selectors.uniq
    end
  end

end