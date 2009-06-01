require "json"

module Bobette
  class JSON
    def initialize(app, &block)
      @app   = app
      @input = block || proc { |env|
        "".inject(env["rack.input"]) { |s, c| s << c}
      }
    end

    def call(env)
      env["bobette.payload"] = ::JSON.parse(@input.call(env))

      @app.call(env)
    rescue ::JSON::JSONError
      Rack::Response.new("Unparsable payload", 400).finish
    end
  end
end
