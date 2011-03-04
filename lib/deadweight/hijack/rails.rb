if ENV['DEADWEIGHT'] == 'true'
  require 'deadweight'
  require 'deadweight/hijack'
  require 'deadweight/rack/capturing_middleware'

  class Deadweight
    module Hijack
      module Rails
        class Railtie < ::Rails::Railtie
          initializer "deadweight.hijack" do |app|
            root = ::Rails.root

            original_stdout, original_stderr = Deadweight::Hijack.redirect_output(root + 'log/test_')

            dw = Deadweight.new

            dw.root        = root + 'public'
            dw.stylesheets = Dir.chdir(dw.root) { Dir.glob("stylesheets/*.css") }
            dw.log_file    = original_stderr

            dw.reset!

            at_exit do
              dw.report
              dw.dump(original_stdout)
            end

            app.middleware.insert(0, Deadweight::Rack::CapturingMiddleware, dw)
          end
        end
      end
    end
  end
end

