# Defense
🔮 Crystal HTTP handler for throttling and blocking requests.

[![Build Status](https://travis-ci.com/defense-cr/defense.svg?branch=master)](https://travis-ci.com/defense-cr/defense)

## Usage


### Install

Add `defense` as dependency to the `shards.yml`.

```yaml
dependencies:
  defense:
    github: defense-cr/defense
```

Install it.

`$ shards install`
	
### Connecting to the application


#### Kemal

Create a `config/defense.cr` file and add:

```crystal
require "defense"

Defense.blocklist do |req, _|
  (req.query =~ /BLOCK/) != nil
end

# add other rules here
```

Add the handler to the main application. At the `src/app.cr` add:


```crystal
require "../config/defense"
require "kemal"

add_handler Defense::Handler.new

# ...
```

See the [kemal-defense-example](https://github.com/defense-cr/kemal-defense-example) 


## Contributing

1. Fork it (<https://github.com/defense-cr/defense/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Development

1. Install the dependencies.

	```bash
	$ shards install
	```

2. Implement and test your changes.

	```bash
	$ crystal spec
	```


3. Run fomart tool to verify code style.

	```bash
	$ crystal tool format
	```

### TODO's

- [ ] Add documentation
- [ ] Tracking
- [ ] Figure out how to deal with response matchers (or introduce track blocks instead)

## Maintainers

- [Florin Lipan](https://github.com/lipanski)
- [Rodrigo Pinto](https://github.com/rodrigopinto)

## Inspiration

Shard was inspired by [rack-attack][1].

[1]: https://github.com/kickstarter/rack-attack
