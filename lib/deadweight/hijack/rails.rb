if ENV['DEADWEIGHT'] == 'true'
  require 'deadweight'
  require 'deadweight/rack/capturing_middleware'

  class Deadweight
    module Hijack
      module Rails
        class Railtie < ::Rails::Railtie
          initializer "deadweight.hijack" do |app|
            root = ::Rails.root

            dw = Deadweight.new

            # TODO: use `rake assets:clean` for Rails < 4!
            system 'rake assets:clobber DEADWEIGHT=false' # Remove existing assets! This seems to be necessary to make sure that they don't exist twice, see http://stackoverflow.com/questions/20938891
            system 'rake assets:precompile DEADWEIGHT=false'

            dw.root        = root + 'public'
            dw.stylesheets = Dir.chdir(dw.root) { Dir.glob("assets/*.css") }

            dw.reset!

            at_exit do
              dw.report
            end

            app.middleware.insert(0, Deadweight::Rack::CapturingMiddleware, dw)
          end
        end
      end
    end
  end
end

