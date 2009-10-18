require 'css_parser'
require 'hpricot'
require 'open-uri'
require 'logger'

class Deadweight
  attr_accessor :root, :stylesheets, :rules, :pages, :ignore_selectors, :mechanize, :log_file
  attr_reader :unused_selectors, :parsed_rules

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

  def analyze(html)
    doc = Hpricot(html)

    found_selectors = []

    @unused_selectors.collect do |selector, declarations|
      # We test against the selector stripped of any pseudo classes,
      # but we report on the selector with its pseudo classes.
      unless doc.search(strip(selector)).empty?
        log.info("  #{selector}")
        selector
      end
    end
  end

  # Find all unused CSS selectors and return them as an array.
  def run
    css = CssParser::Parser.new

    @stylesheets.each do |path|
      css.add_block!(fetch(path))
    end

    css.add_block!(rules)

    @parsed_rules     = {}
    @unused_selectors = []
    total_selectors   = 0

    css.each_selector do |selector, declarations, specificity|
      unless @unused_selectors.include?(selector)
        total_selectors += 1

        unless selector =~ ignore_selectors
          @unused_selectors << selector
          @parsed_rules[selector] = declarations
        end
      end
    end

    # Remove selectors with pseudo classes that already have an equivalent
    # without the pseudo class. Keep the ones that don't, we need to test
    # them.
    @unused_selectors.each do |selector|
      if has_pseudo_classes(selector) && @unused_selectors.include?(strip(selector))
        @unused_selectors.delete(selector)
      end
    end

    pages.each do |page|
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
        html = fetch(page)
      end

      process!(html)
    end

    log.info "found #{@unused_selectors.size} unused selectors out of #{total_selectors} total"

    @unused_selectors
  end

  def dump(output)
    output.puts(@unused_selectors)
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
    log.info(path)

    loc = root + path

    if @mechanize
      loc = "file://#{File.expand_path(loc)}" unless loc =~ %r{^\w+://}
      page = agent.get(loc)
      log.warn("#{path} redirected to #{page.uri}") unless page.uri.to_s == loc
      page.body
    else
      open(loc).read
    end
  end

private

  def has_pseudo_classes(selector)
    selector =~ /::?[\w\-]+/
  end

  def strip(selector)
    selector.gsub(/::?[\w\-]+/, '')
  end

  def log
    @log ||= Logger.new(@log_file)
  end

  def initialize_agent
    begin
      require 'mechanize'
      return WWW::Mechanize.new
    rescue LoadError
      log.info %{
        =================================================================
        Couldn't load 'mechanize', which is required for remote scraping.
        Install it like so: gem install mechanize
        =================================================================
      }

      raise
    end
  end
end

require 'deadweight/rake_task'

