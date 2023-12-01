require "http/server/handler"

module Defense
  class Handler
    include HTTP::Handler

    def initialize
    end

    def call(context : HTTP::Server::Context)
      if Defense.safelisted?(context.request)
        call_next(context)
      elsif Defense.blocklisted?(context.request)
        Defense.blocklisted_response.call(context.response)
      elsif Defense.throttled?(context.request)
        Defense.throttled_response.call(context.response)
      else
        call_next(context)
      end
    end
  end
end
