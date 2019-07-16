# Defense

[![Build Status](https://travis-ci.com/defense-cr/defense.svg?branch=master)](https://travis-ci.com/defense-cr/defense)

🔮 *A Crystal HTTP handler for throttling, blocking or tracking mailicious requests* 🔮

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

### Configuration

Defense stores its state in a **Redis** database. You can configure this by setting the `REDIS_URL` environment variable
or by using the `Defense#store=` method:

```crystal
Defense.store = Defense::RedisStore.new(url: "redis://localhost:6379/0")
```

For simple use cases or tests, you can use the **memory store**:

```crystal
Defense.store = Defense::MemoryStore.new
```

Last but not least, you can implement your own **custom store** by extending the abstract class `Defense::Store`.

### Plugging into the application

Defense is built as a Crystal `HTTP::Handler`. You will need to register the Defense handler to your web
application's handler chain. For more information about *handlers* and the *handler chain* follow
[this link](https://crystal-lang.org/api/latest/HTTP/Server.html).

Usually the earlier you register the handler to your handler chain, the better. This ensures that malicious
requests are blocked early own, before other layers (handlers) of your application are reached.

Here's how to plug Defense into some of the most popular Crystal web frameworks:

#### Kemal

In Kemal you would use the `add_handler` method to register the Defense handler:

```crystal
require "kemal"
require "defense"

add_handler(Defense::Handler.new)
```

For more details, check out the [kemal-defense-example repository](https://github.com/defense-cr/kemal-defense-example).

#### Amber

```crystal
# TODO
```

#### Lucky

Within your `src/app_server.cr` file, add the `Defense::Handler` before the `Lucky::RouteHandler`:

```crystal
require "defense"

class AppServer < Lucky::BaseAppServer
  def middleware
    [
      Defense::Handler.new,
      Lucky::RouteHandler.new,
    ]
   end
end
```

#### HTTP::Server (Standalone)

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

Defense provides a set of configureable rules that you can use to throttle, block or track malicious requests based
on your own heuristics.

#### Throttling

```crystal
# TODO
```

#### Safelist

```crystal
# TODO
```

#### Blocklist

```crystal
# TODO
```

#### Fail2Ban

```crystal
# TODO
```

#### Allow2Ban

```crystal
# TODO
```

## Contributing & Development

Contributions are welcome! Make sure to check the existing issues (including the closed ones) before requesting a
feature, reporting a bug or opening a pull requests.

### Getting started

Install dependencies:

```sh
shards install
```

Run tests:

```sh
crystal spec
```

Format the code:

```sh
crystal tool format
```

### Guidelines

- Keep the public interface small. Anything that doesn't have to be public, should explicitly be marked as protected or
private.
- Prefer integration tests over unit tests - at least for now.

### TODOs

- [ ] Add documentation
- [ ] Tracking
- [ ] Figure out how to deal with response matchers (or introduce track blocks instead)

## Maintainers

- [Florin Lipan](https://github.com/lipanski)
- [Rodrigo Pinto](https://github.com/rodrigopinto)

This shard is heavily inspired by [rack-attack](https://github.com/kickstarter/rack-attack).
