require 'css_parser'
require 'nokogiri'
require 'open-uri'

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
  attr_reader :unused_selectors, :parsed_rules

  def initialize
    @root = 'http://localhost:3000'
    @stylesheets = []
    @pages = []
    @rules = ""
    @ignore_selectors = []
    @error_selectors = []
    @mechanize = false
    @log_file = STDERR
    yield self and run if block_given?
  end

  def analyze(html)
    doc = Nokogiri::HTML(html)

    @unused_selectors.collect do |selector, declarations|
      # We test against the selector stripped of any pseudo classes,
      # but we report on the selector with its pseudo classes.
      stripped_selector = strip(selector)

      next if stripped_selector.empty?

      begin
        if doc.search(stripped_selector).any?
          log.puts("  #{selector.green}")
          selector
        end
      rescue Nokogiri::CSS::SyntaxError => e
        log.puts("  #{selector.red}")
        @error_selectors << selector
      end
    end
  end

  def add_css!(css)
    parser = CssParser::Parser.new
    parser.add_block!(css)

    selector_count = 0

    parser.each_selector do |selector, declarations, specificity|
      next if @unused_selectors.include?(selector)
      next if selector =~ @ignore_selectors
      next if has_pseudo_classes(selector) and @unused_selectors.include?(strip(selector))

      @unused_selectors << selector
      @parsed_rules[selector] = declarations

      selector_count += 1
    end

    selector_count
  end

  def reset!
    @parsed_rules     = {}
    @unused_selectors = []

    @stylesheets.each do |path|
      new_selector_count = add_css!(fetch(path))
      log.puts("  found #{new_selector_count} selectors".yellow)
    end

    if @rules and !@rules.empty?
      new_selector_count = add_css!(@rules)
      log.puts
      log.puts("Added #{new_selector_count} extra selectors".yellow)
    end

    @total_selectors = @unused_selectors.size
  end

  def report
    log.puts
    log.puts "found #{@unused_selectors.size} unused selectors out of #{@total_selectors} total".yellow
    log.puts "found #{@error_selectors.size} which could not be parsed".red
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

    @unused_selectors
  end

  def dump(output)
    output.puts(@unused_selectors)
    output.puts "== Error"
    output.puts(@error_selectors)
  end

  def process!(html)
    analyze(html).each do |selector|
      @unused_selectors.delete(selector)
    end
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

  def has_pseudo_classes(selector)
    selector =~ /::?[\w\-]+/
  end

  def strip(selector)
    selector = selector.gsub(/^@.*/, '') # @-webkit-keyframes ...
    selector = selector.gsub(/:.*/, '')  # input#x:nth-child(2):not(#z.o[type='file'])
    selector
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

require 'deadweight/rake_task'

