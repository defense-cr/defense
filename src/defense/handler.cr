require "http/server/handler"

module Defense
  class Handler
    include HTTP::Handler

    def initialize
    end

    def call(ctx : HTTP::Server::Context)
      if Defense.throttled?(ctx.request, ctx.response)
        ctx.response.status = HTTP::Status::TOO_MANY_REQUESTS
        ctx.response.content_type = "text/plain"
        ctx.response.puts("Retry later\n")
      else
        call_next(ctx)
      end
    end
  end
end
