```
      .----.__
     / c  ^  _`;
     |     .--'
      \   (
      /  -.\
     / .   \
    /  \    |
   ;    `-. `.
   |      /`'.`.
   |      |   \ \
   |    __|    `'
   ;   /   \
  ,'        |
 (_`'---._ /--,
   `'---._`'---..__
          `''''--, )
            _.-'`,`
             ````
```

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

Then you can compile the interpreter to an escript:

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
* Polish parser combinators:
  * Use a protocol (maybe)
  * Use `with` special form for recovery from parse failure instead of an exception
* Polish `OtterScript.Core`
  * Add syntactic sugar to all functions of a given module
    * Attributes on the function level can help define call-semantics
      * Name that it is exposed as
      * Varargs?
  * Expose more stuff in the core library
* Finish this list of TODOs
* Profit
