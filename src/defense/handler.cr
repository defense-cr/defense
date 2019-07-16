require "http/server/handler"

module Defense
  class Handler
    include HTTP::Handler

    def initialize
    end

    def call(ctx : HTTP::Server::Context)
      if Defense.safelisted?(ctx.request)
        call_next(ctx)
      elsif Defense.blocklisted?(ctx.request)
        Defense.blocklisted_response.call(ctx.response)
      elsif Defense.throttled?(ctx.request)
        Defense.throttled_response.call(ctx.response)
      else
        call_next(ctx)
      end
    end
  end
end
