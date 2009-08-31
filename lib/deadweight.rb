require 'css_parser'
require 'hpricot'
require 'open-uri'
require 'logger'

class Deadweight
  attr_accessor :root, :stylesheets, :pages, :ignore_selectors, :mechanize, :log_file

  def initialize
    @root = 'http://localhost:3000'
    @stylesheets = []
    @pages = []
    @ignore_selectors = []
    @mechanize = false
    @log_file = STDERR
  end

  # Find all unused CSS selectors and return them as an array.
  def run
    css = CssParser::Parser.new

    @stylesheets.each do |path|
      css.add_block!(fetch(path))
    end

    unused_selectors = []
    total_selectors = 0

    css.each_selector do |selector, declarations, specificity|
      unless unused_selectors.include?(selector)
        total_selectors += 1
        unused_selectors << selector unless selector =~ ignore_selectors
      end
    end

    # Remove selectors with pseudo classes that already have an equivalent
    # without the pseudo class. Keep the ones that don't, we need to test
    # them.
    unused_selectors.reject! do |selector|
      has_pseudo_classes(selector) && unused_selectors.include?(strip(selector))
    end

    pages.each do |page|
      case page
      # TODO this is ugly, but just listing IO doesn't work (since it's a Module)
      when String, StringIO, File, IO
        html = fetch(page)
      else
        result = instance_eval(&page)

        html = case result
               when String
                 result
               else
                 @agent.page.body
               end
      end

      doc = Hpricot(html)

      found_selectors = []

      unused_selectors.each do |selector|
        # We test against the selector stripped of any pseudo classes,
        # but we report on the selector with its pseudo classes.
        unless doc.search(strip(selector)).empty?
          log.info("  #{selector}")
          found_selectors << selector
        end
      end

      unused_selectors -= found_selectors
    end

    log.info "found #{unused_selectors.size} unused selectors out of #{total_selectors} total"

    unused_selectors
  end

  # Returns the Mechanize instance, if +mechanize+ is set to +true+.
  def agent
    @agent ||= initialize_agent
  end

  # Fetch a path, using Mechanize if +mechanize+ is set to +true+.
  def fetch(path)
    # Handle IO objects appropriately
    return path.read if path.respond_to?(:read)

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

