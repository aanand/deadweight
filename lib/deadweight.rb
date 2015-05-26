require 'css_parser'
require 'bisect'
require 'nokogiri'
require 'open-uri'
require 'deadweight/deadweight_helper'

begin
  require 'colored'
rescue LoadError
  class String
    %w(red green blue yellow).each do |color|
      define_method(color) { self }
    end
  end
end


class Deadweight
  attr_accessor :root, :stylesheets, :rules, :pages, :ignore_selectors, :mechanize, :log_file
  attr_reader :selector_nodes, :selector_tree_root, :unused_selector_nodes, :unsupported_selector_nodes
  include DeadweightHelper

  def initialize
    @root = 'http://localhost:3000'
    @stylesheets = []
    @pages = []
    @rules = ""
    @ignore_selectors = []
    @mechanize = false
    @log_file = STDERR
    yield self and run if block_given?
  end

  def analyze(html, selector_nodes=nil)
    doc = Nokogiri::HTML(html)

    selector_nodes ||= @unused_selector_nodes.dup

    found_nodes = selector_nodes.collect do |selector_node|
      selector = selector_node.selector

      begin
        if doc.css(selector).any?
          log.puts("  #{selector.green}") if selector_node.from_css?
          selector_node
        end
      rescue
        @unused_selector_nodes.delete(selector_node)
        @unsupported_selector_nodes << selector_node
        nil
      end
    end

    found_nodes.compact
  end

  def process!(html)
    selector_nodes = @unused_selector_nodes
    until selector_nodes.empty?
      new_selector_nodes = []

      analyze(html, selector_nodes).each do |found_node|
        @unused_selector_nodes.delete(found_node)
        @unused_selector_nodes.push(*found_node.children)
        new_selector_nodes.push(*found_node.children)
      end

      selector_nodes = new_selector_nodes
    end
  end

  def add_css!(css)
    parser = CssParser::Parser.new
    parser.add_block!(css)

    new_selectors_count = 0

    first_nodes = @selector_tree_root.children.dup

    parser.each_selector do |selector, declarations, specificity|
      next if selector =~ @ignore_selectors || normalize_whitespace(selector) =~ @ignore_selectors
      normalized_selector = normalize(selector)

      selector_node = @selector_nodes[normalized_selector]
      selector_node ||= SelectorTreeNode.new(normalized_selector)

      selector_node.original_selectors << selector
      selector_node.declarations << declarations

      next if @selector_nodes[normalized_selector]

      @selector_nodes[normalized_selector] = selector_node
      new_selectors_count += 1

      if known_unsupported_selector?(normalized_selector)
        @unsupported_selector_nodes << selector_node
      else
        @selector_tree_root.add_node(selector_node)
      end

    end

    new_root_nodes = @selector_tree_root.children - first_nodes
    @unused_selector_nodes.push(*new_root_nodes)

    new_selectors_count
  end

  def reset!
    @unused_selector_nodes = []
    @unsupported_selector_nodes = []
    @selector_nodes = {}
    @selector_tree_root = SelectorTreeRoot.new

    @stylesheets.each do |path|
      new_selector_count = add_css!(fetch(path))
      log.puts("  found #{new_selector_count} selectors".yellow)
    end

    if @rules and !@rules.empty?
      new_selector_count = add_css!(@rules)
      log.puts
      log.puts("Added #{new_selector_count} extra selectors".yellow)
    end

    @total_selectors = (@selector_tree_root.descendants.select(&:from_css?) + @unsupported_selector_nodes).size
  end

  def report
    log.puts
    log.puts "found #{selectors_to_review.size} unused selectors out of #{@total_selectors} total".yellow
    log.puts
  end

  # Find all unused CSS selectors and return them as an array.
  def run
    reset!

    pages.each do |page|
      log.puts

      if page.respond_to?(:read)
        html = page.read
      elsif page.respond_to?(:call)
        result = instance_eval(&page)

        html = case result
               when String
                 result
               else
                 @agent.page.body
               end
      else
        begin
          html = fetch(page)
        rescue FetchError => e
          log.puts(e.message.red)
          next
        end
      end

      process!(html)
    end

    report

    selectors_to_review
  end

  def selectors_to_review(&block)
    (unused_selectors(&block) + unsupported_selectors(&block)).uniq
  end

  def unused_selectors(&block)
    block ||= :original_selectors.to_proc
    @unused_selector_nodes.map{|node| node.and_descendants}.flatten.select(&:from_css?).map(&block).flatten.uniq
  end

  def unsupported_selectors(&block)
    block ||= :original_selectors.to_proc
    @unsupported_selector_nodes.map{|node| node.and_descendants}.flatten.select(&:from_css?).map(&block).flatten.uniq
  end

  def dump(output)
    output.puts(selectors_to_review)
  end

  # Returns the Mechanize instance, if +mechanize+ is set to +true+.
  def agent
    @agent ||= initialize_agent
  end

  # Fetch a path, using Mechanize if +mechanize+ is set to +true+.
  def fetch(path)
    log.puts(path)

    loc = root + path

    if @mechanize
      loc = "file://#{File.expand_path(loc)}" unless loc =~ %r{^\w+://}

      begin
        page = agent.get(loc)
      rescue Mechanize::ResponseCodeError => e
        raise FetchError.new("#{loc} returned a response code of #{e.response_code}")
      end

      log.puts("#{loc} redirected to #{page.uri}".red) unless page.uri.to_s == loc

      page.body
    else
      begin
        open(loc).read
      rescue Errno::ENOENT
        raise FetchError.new("#{loc} was not found")
      rescue OpenURI::HTTPError => e
        raise FetchError.new("retrieving #{loc} raised an HTTP error: #{e.message}")
      end
    end
  end

private

  def normalize(selector)
    normalize_whitespace(remove_simple_pseudo(selector))
  end

  def normalize_whitespace(selector)
    normalized_selector = ''

    tokenize_selector(selector).each do |type, text|
      # We remove all the unnecessary spaces unless it's a significative one, which corresponds to the type :S
      # When it's a significant space, we leave a single one of them.
      normalized_selector << (type == :S ? ' ' : text.strip)
    end
    normalized_selector.strip
  end

  # Nokogiri supports lots of pseudo-classes! Those it doesn't support, we will eventually mark as unsupported if they are reached in the pages.
  # However, some of those unsupported pseudo-classes (and all pseudo-elements) can be implied from other rules.
  # Example, if we find ".hello", then we can pretty safely infer that ".hello:hover" is used (unless it's never actually displayed...)
  def remove_simple_pseudo(selector)
    selector_text_parts = []
    selector_type_parts = []

    tokenize_selector(selector).each do |type, text|
      if %w(hover valid).include?(text) && selector_type_parts[-1] == ':'
        # Discard :hover
        selector_type_parts.pop
        selector_text_parts.pop
        next
      elsif selector_type_parts[-2..-1] == [':', ':']
        # Discard all pseudo-elements (those starting with ::)
        selector_type_parts.pop(2)
        selector_text_parts.pop(2)
        next
      end

      selector_type_parts << type
      selector_text_parts << text
    end

    selector_text_parts.join
  end

  # No idea what we should do with at_rules
  def known_unsupported_selector?(selector)
    tokenize_selector(selector).each do |type, text|
      return true if type == :IDENT && text.start_with?('@')
      return true if type == '@'
    end
    return false
  end

  def log
    @log ||= if @log_file.respond_to?(:puts)
               @log_file
             else
               open(@log_file, 'w+')
             end
  end

  def initialize_agent
    begin
      require 'mechanize'

      unless defined?(Mechanize::VERSION) and Mechanize::VERSION >= "1.0.0"
        log.puts %{
          =================================================================
          A mechanize version of 1.0.0 or above is required.
          Install it like so: gem install mechanize
          =================================================================
        }
      end

      return Mechanize.new
    rescue LoadError
      log.puts %{
        =================================================================
        Couldn't load 'mechanize', which is required for remote scraping.
        Install it like so: gem install mechanize
        =================================================================
      }

      raise
    end
  end

  class FetchError < StandardError; end
end
require 'deadweight/selector_tree_node'
require 'deadweight/selector_tree_root'
require 'deadweight/rake_task'

