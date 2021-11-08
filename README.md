# YourBot

Web Application for building and hosting Discord bots.

## Development

* Install Erlang and Elixir via [asdf-vm](https://github.com/asdf-vm/asdf-elixir)
* Follow the [Phoenix installation guide](https://hexdocs.pm/phoenix/installation.html) guide
* Install google chrome driver for your host OS
* Install [minio](https://min.io/)

## Testing

### Wallaby Tests

Most of the tests as of right now are written via [wallaby](https://hexdocs.pm/wallaby/readme.html).
It uses `chromedriver` and your browser. If you wish to Skip the wallaby tests, you can run with
`--exclude wallaby` with your test suite. For example:

```bash
mix test --exclude wallaby
```

If a wallaby feature test is failing, there will be a screenshot of the browser placed in the `screenshots`
folder. If you need more info about a failing test, you can run the test with the `SHOW_BROWSER` variable set.
For example:

```bash
SHOW_BROWSER=1 mix test test/fw_pizza_web/features/devices_live_test.exs
```

### Test Coverage

To get code coverage stats, the project use [excoveralls](https://hexdocs.pm/excoveralls/). To collect
the coverage report, run:

```baash
mix coveralls
```

To get something a little nicer to view, use:

```bash
mix coveralls.html
firefox cover/excoveralls.html
```
