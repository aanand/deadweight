class Deadweight
  module Rack
    class CapturingMiddleware
      def initialize(app, dw)
        @app = app
        @dw  = dw
      end

      def call(env)
        response = @app.call(env)
        process(response)
        response
      end

      def process(rack_response)
        status, headers, response = rack_response

        if response.respond_to?(:body)
          html = response.body
          @dw.process!(html)
        end
      end
    end
  end
end

