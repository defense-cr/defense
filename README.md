# Defense

[![Build Status](https://travis-ci.com/defense-cr/defense.svg?branch=master)](https://travis-ci.com/defense-cr/defense)

🔮 Crystal HTTP handler for throttling and blocking requests.

### TODO

- [x] Finish the `MemoryStore`
- [x] Throttle
- [x] Implement the HTTP::Handler
- [x] Use Namespace on Redis Store to keep safe data isolated.
- [x] Safelist
- [x] Blocklist
- [x] Custom Response
- [x] Fail2ban
- [ ] Add travis ci configuration to run specs. (config. to run against store's matrix)
- [ ] Allow2ban
- [ ] Add documentation
- [ ] Tracking
- [ ] Figure out how to deal with response matchers (or introduce track blocks instead)

## Usage

TODO

## Contributing

TODO

## Maintainers

- [Florin Lipan](https://github.com/lipanski)
- [Rodrigo Pinto](https://github.com/rodrigopinto)

## Inspiration

Shard was inspired by [rack-attack][1].

[1]: https://github.com/kickstarter/rack-attack
