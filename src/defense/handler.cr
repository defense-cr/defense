require "http/server/handler"

module Defense
  class Handler
    include HTTP::Handler

    DEFAULT_THROTTLED_RESPONSE = ->(response : HTTP::Server::Response) do
      response.status = HTTP::Status::TOO_MANY_REQUESTS
      response.content_type = "text/plain"
      response.puts("Retry later\n")
    end

    def initialize
    end

    def call(ctx : HTTP::Server::Context)
      if Defense.throttled?(ctx.request, ctx.response)
        DEFAULT_THROTTLED_RESPONSE.call(ctx.response)
      else
        call_next(ctx)
      end
    end
  end
end
