require 'optparse'
require 'deadweight'

class Deadweight
  class CLI
    attr_reader :stdout, :stdin, :stderr
    attr_reader :arguments, :options
    attr_reader :output

    def self.execute(stdout, stdin, stderr, arguments = [])
      @options = {
        :root       => "",
        :log_file   => stderr,
        :output     => stdout,
        :proxy_port => 8002
      }

      self.parse_options(arguments)
      self.new(stdout, stdin, stderr, arguments, @options).execute!
    end

    def self.option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] <url> [<url> ...]"

        @options[:stylesheets] = []

        opts.on("-L", "--lyndon", "Pre-process HTML with Lyndon") do
          @options[:lyndon] = true
        end

        opts.on("-l", "--log FILE", "Where to write log messages") do |v|
          @options[:log_file] = v
        end

        opts.on("-P", "--proxy", "Run in proxy mode") do
          @options[:proxy] = true
        end

        opts.on("-p", "--proxy-port", "Port to run the proxy on") do |v|
          @options[:proxy] = true
          @options[:proxy_port] = v.to_i
        end

        opts.on("-O", "--output FILE",
                "Where to output orphaned CSS rules") do |v|
          @options[:output] = File.new(v, "w")
        end

        opts.on("-s", "--stylesheet FILE",
                "Apply the specified stylesheet to the target") do |v|
          @options[:stylesheets] << v
        end

        opts.on("-r", "--root URL-OR-PATH",
                "Specify a root for all urls/paths") do |r|
          @options[:root] = r
        end

        opts.on("-w", "--whitelist URL-PREFIX",
                "Specifies a prefix for URLs to process") do |v|
          @options[:whitelist] ||= []
          @options[:whitelist] << v
        end
      end
    end

    def self.parse_options(arguments = [])
      self.option_parser.parse!(arguments)
      @options
    end

    def initialize(stdout, stdin, stderr, arguments = [], options = {})
      @stdout = stdout
      @stdin  = stdin
      @stderr = stderr
      @arguments = arguments
      @options = options
      @output = options[:output]
    end

    def execute!
      if options[:proxy]
        proxy
      elsif arguments.empty?
        stdout.puts self.class.option_parser.help
      else
        process
      end
    end

    def process
      # TODO pass stylesheets + pages as args
      dw = Deadweight.new

      # TODO this should be the default
      dw.root = options[:root]

      dw.log_file = options[:log_file]

      dw.stylesheets = options[:stylesheets]

      dw.rules = stdin.read if stdin.stat.size > 0

      if options[:lyndon]
        arguments.each do |file|
          dw.pages << IO.popen("cat #{file} | lyndon 2> /dev/null")
        end
      else
        dw.pages = arguments
      end

      dw.run
      dw.dump(output)
    end

    def proxy
      dw = Deadweight.new

      # TODO note the boilerplate shared with #process
      dw.root = options[:root]
      dw.log_file = options[:log_file]
      dw.stylesheets = options[:stylesheets]
      dw.rules = stdin.read if stdin.stat.size > 0

      # initialize selectors
      dw.run

      stdout.puts "#{dw.unused_selectors.length} rules loaded."

      require 'webrick/httpproxy'

      @proxy = WEBrick::HTTPProxyServer.new \
        :AccessLog           => [
          [options[:log_file], WEBrick::AccessLog::COMMON_LOG_FORMAT],
          [options[:log_file], WEBrick::AccessLog::REFERER_LOG_FORMAT]
        ],
        :Logger              => WEBrick::Log.new(options[:log_file]),
        :Port                => options[:proxy_port],
        :ProxyContentHandler => lambda { |request, response|

          parse_this = false

          if options[:whitelist]
            options[:whitelist].each do |x|
              sliced_request_uri = response.request_uri.to_s[0..x.length - 1]
              if sliced_request_uri.downcase == x.downcase
                parse_this = true
                break 
              end
            end
          else
            parse_this = true
          end

          if parse_this && response.header["content-type"] =~ /text\/html/
            # TODO this slows things down significantly; better would be to
            # remove the Accept-Encoding header during the request phase
            body = if response.header["content-encoding"] == "gzip"
              Zlib::GzipReader.new(StringIO.new(response.body)).read
            elsif response.header["content-encoding"] == "deflate"
              Zlib::Inflate.inflate(response.body)
            else
              response.body
            end
            dw.process!(body)

            stdout.puts "After reviewing <#{response.request_uri}>, there were #{dw.unused_selectors.length} rules left"
            # stdout.puts "After reviewing <#{response.request_uri}>, these were left:"
            # dw.unused_selectors.each do |k,v|
            #   stdout.puts "#{k} { #{v} }"
            # end
          end
        }

      trap('INT') do
        @proxy.shutdown 

        # dump the remaining CSS rules if output is set
        unless options[:output] == STDOUT
          dw.unused_selectors.each do |k,v|
            output.puts "#{k} { #{v} }"
          end
        end
      end

      @proxy.start
    end
  end
end

