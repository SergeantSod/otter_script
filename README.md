OtterScript
=================

An extremely serious (not really), totally web-scale (not really) functional (really) scripting language.

Getting Started
===============

The OtterScript interpreter is written in elixir. So install elixir first.
Once you have mix ready, you can run the tests:

```bash
mix test
```

Then you can compile the interepreter to an escript:

```bash
mix escript.build
```

Then run some of the examples:

```bash
./otter_script examples/fibonnaci.otter
```

Or look at the parse tree:

```bash
./otter_script --parse examples/fibonnaci.otter
```

TODO:
* Resolve inline TODOs
* Flesh out higher-level plan
