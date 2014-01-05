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

            system 'rake assets:clobber DEADWEIGHT=false' # Remove existing assets! This seems to be necessary to make sure that they don't exist twice, see http://stackoverflow.com/questions/20938891
            system 'rake assets:precompile DEADWEIGHT=false'

            dw.root        = root + 'public'
            dw.stylesheets = Dir.chdir(dw.root) { Dir.glob("assets/*.css") }
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

