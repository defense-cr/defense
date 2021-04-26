# Defense

[![Build Status](https://travis-ci.com/defense-cr/defense.svg?branch=master)](https://travis-ci.com/defense-cr/defense)

🔮 *A Crystal HTTP handler for throttling, blocking and tracking malicious requests* 🔮

## Getting started

### Installation

Add the shard as a dependency to your project's `shards.yml`:

```yaml
dependencies:
  defense:
    github: defense-cr/defense
```

...and install it:

```sh
shards install
```

### Configure the data store

Defense stores its state in a **Redis** database. You can configure this by setting the `REDIS_URL` environment variable or by using the `Defense#store=` method:

```crystal
Defense.store = Defense::RedisStore.new(url: "redis://localhost:6379/0")
```

For simple use cases or tests you can also use the **memory store**:

```crystal
Defense.store = Defense::MemoryStore.new
```

You can always implement your own **custom store** by extending the abstract class `Defense::Store`.

### Plugging into the application

Defense is built as a Crystal `HTTP::Handler`. You will need to register the `Defense::Handler` to your web application's handler chain. For more information about *handlers* and the *handler chain* follow [this link](https://crystal-lang.org/api/latest/HTTP/Server.html).

Usually the earlier you register the handler to your handler chain, the better. This ensures that malicious requests are blocked early own, before other layers (handlers) of your application are reached.

Here's how to plug Defense into some of the **most popular Crystal web frameworks**:

#### Kemal

In Kemal you would use the `add_handler` method to register the Defense handler:

```crystal
require "kemal"
require "defense"

add_handler Defense::Handler.new

# Other handlers...
add_handler SomeOtherHandler.new

get "/" do
  "hello world"
end

Kemal.run
```

For more details, check out the [kemal-defense-example repository](https://github.com/defense-cr/kemal-defense-example).

#### Amber

In Amber you register handlers as part of a pipeline in your `config/routes.cr` file:

```crystal
Amber::Server.configure do |app|
  pipeline :web do
    plug Defense::Handler.new

    # Other handlers...
    plug SomeOtherHandler.new
  end

  routes :web do
    get "/", HomeController, :index
  end
end
```

#### Lucky

In Lucky, you would add the `Defense::Handler` within your `src/app_server.cr` file, somewhere before the `Lucky::RouteHandler`:

```crystal
class AppServer < Lucky::BaseAppServer
  def middleware
    [
      Defense::Handler.new,

      # Other handlers...
      SomeOtherHandler.new,

      Lucky::RouteHandler.new,
    ]
  end
end
```

#### HTTP::Server (Standalone)

When using the standard library `HTTP::Server`, any middleware is registered as part of the initializer:

```crystal
require "defense"
require "http/server"

server = HTTP::Server.new([Defense::Handler.new]) do |context|
  context.response.content_type = "text/plain"
  context.response.print "hello world"
end

server.bind_tcp(8080)
server.listen
```

### Usage

Defense provides a set of configurable rules that you can use to throttle, block and track malicious requests based on your own heuristics:

- [Throttling](#throttling)
- [Configure the throttled response](#configure-the-throttled-response)
- [Blocklist](#blocklist)
- [Configure the blocked response](#configure-the-blocked-response)
- [Fail2Ban](#fail2ban)
- [Allow2Ban](#allow2ban)
- [Safelist](#safelist)

#### Throttling

The `Defense.throttle` method can be used to throttle clients based on a maximum number of requests (*limit*) over a given time frame specified in seconds (*period*).

The method takes a block which receives the `request` as an argument. The return value of the block should either be `nil` (in which case the request will not be counted at all) or a `String` which uniquely identifies the client to throttle. A good identifier is usually the IP address.

The following example throttles clients based on their IP address to a limit of 10 requests per minute:

```crystal
Defense.throttle("throttle requests per minute", limit: 10, period: 60) do |request|
  request.remote_address.to_s
end
```

The following example throttles clients in a similar way but will ignore requests coming from `127.0.0.1`:

```crystal
Defense.throttle("throttle requests per minute except localhost", limit: 10, period: 60) do |request|
  return nil if request.remote_address.to_s == "127.0.0.1"

  request.remote_address.to_s
end
```

#### Configure the throttled response

Throttled requests are responded with:

```http
HTTP/1.1 429 Too Many Requests
content-type: text/plain
content-length: 10

Retry later
```

You can override the default response message by using the `Defense.throttled_response=` method:

```crystal
Defense.throttled_response = ->(response : HTTP::Server::Response) do
  response.status = HTTP::Status::UNAUTHORIZED
  response.content_type = "application/json"
  response.puts("{'hello':'world'}")
end
```

#### Blocklist

The `Defense.blocklist` method can be used to block malicious or unwanted requests.

The method takes a block which receives the `request` as an argument. The return value of the block should either be `true` - in which case the request will be blocked, or `false` - in which case the request will be allowed.

The following example blocks all requests to `/admin/*`:

```crystal
Defense.blocklist("block requests to the admin") do |request|
  request.path.starts_with?("/admin/")
end
```

The following example blocks requests based on a predefined list of malicious IPs:

```crystal
MALICIOUS_IPS = ["1.1.1.1", "2.2.2.2", "3.3.3.3"]

Defense.blocklist("block requests from malicious ips") do |request|
  MALICIOUS_IPS.includes?(request.remote_address.to_s)
end
```

The [Spamhaus DROP lists](https://www.spamhaus.org/drop/) are a great resource for malicious IPs to block.

#### Configure the blocked response

Blocked requests are responded with:

```http
HTTP/1.1 403 Forbidden
content-type: text/plain
content-length: 9

Forbidden
```

You can override the default response message by using the `Defense.blocked_response=` method:

```crystal
Defense.blocked_response = ->(response : HTTP::Server::Response) do
  response.status = HTTP::Status::UNAUTHORIZED
  response.content_type = "application/json"
  response.puts("{'hello':'world'}")
end
```

#### Fail2Ban

The `Defense::Fail2Ban.filter` method can be used within a `Defense.blocklist` block to ban misbehaving clients for a given period of time (*bantime*) after a sequence of blocked requests (*maxretry*) performed over a particular time range (*findtime*).

The method's first argument should be a unique identifier of the client - the IP address is usually a safe bet. It's highly recommended to namespace this identifier, in order to avoid conflicts with other `Fail2Ban` or `Allow2Ban` calls - e.g. `my-fancy-filter:#{request.remote_address.to_s}` would be a good identifier.

The method also takes a block which should return `true` - in which case the request will be blocked and counted for the ban, or `false` - in which case the request will be allowed and excluded from the ban count. Note that the return value of the `#filter` block will also be used as a return value for the `#blocklist` block.

The following example blocks any requests containing `/etc/passwd` inside the path and, once a particular client identified by IP has accumulated 5 requests wihin 60 seconds, it bans him for the next 24 hours:

```crystal
Defense.blocklist("fail2ban pentesters") do |request|
  Defense::Fail2Ban.filter("pentesters:#{request.remote_address.to_s}", maxretry: 5, findtime: 60, bantime: 24 * 60 * 60) do
    request.path.includes?("/etc/passwd")
  end
end
```

#### Allow2Ban

The `Defense::Allow2Ban.filter` method works the same way as `Defense::Fail2Ban.filter` except that it allows requests from misbehaving clients until such time as they reach *maxretry* at which they are cut off as per normal.

The following example allows all `POST /login` requests until a particular client identified by IP has accumulated 5 requests within 60 seconds, at which point it bans him for the next 24 hours:

```crystal
Defense.blocklist("allow2ban too many login attempts") do |request|
  Defense::Allow2Ban.filter("too-many-login-attempts:#{request.remote_address.to_s}", maxretry: 5, findtime: 60, bantime: 24 * 60 * 60) do
    request.method == "POST" && request.path == "/login"
  end
end
```

#### Safelist

The `Defense.safelist` method can be used to exclude requests from any throttling or blocking rules. This method has precedence over all the other rules.

The method takes a block which receives the `request` as an argument. The return value of the block should either be `true` - in which case the request will never be throttled or blocked, or `false` - in which case the request will be checked against the other existing rules and might potentially be throttled or blocked.

The following example marks all requests originating from `127.0.0.1` as safe:

```crystal
Defense.safelist("local requests are safe") do |request|
  request.remote_address.to_s == "127.0.0.1"
end
```

## Contributing & Development

Contributions are welcome. Make sure to check the existing issues (including the closed ones) before requesting a feature, reporting a bug or opening a pull requests.

### Getting started

Install dependencies:

```sh
shards install
```

Run tests using Redis as a backend (requires a running Redis server):

```sh
crystal spec
```

Run tests using the memory store as a backend:

```sh
STORE=memory crystal spec
```

Format the code:

```sh
crystal tool format
```

### Guidelines

- Keep the public interface small. Anything that doesn't have to be public, should explicitly be marked as protected or
private, including classes.
- Be explicit about type declaration (especially on public methods).
- Use the Crystal formatter to format the code.
- For now, prefer integration/system tests over unit tests.

## Maintainers

- [Florin Lipan](https://github.com/lipanski)
- [Rodrigo Pinto](https://github.com/rodrigopinto)

## Credits

This shard is heavily inspired by [rack-attack](https://github.com/kickstarter/rack-attack) ❤
