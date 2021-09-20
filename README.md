A simple HTTP proxy for [webdev's serve command][webdev-serve] that adds support
for rewriting certain requests, namely rewriting 404s to instead serve the root
index (`/`).

## Requirements

The latest release of `webdev_proxy` requires the following:

- Dart SDK `2.11` or later
- `webdev` globally activated at a version in the `>=1.0.1 <3.0.0` range
  - Be sure to follow the [installation instructions for webdev][webdev-install]

## Installation

`webdev_proxy` is intended to be ["activated"][pub-global-activate] rather than
installed as a package dependency.

```bash
$ pub global activate webdev_proxy
```

Learn more about activating and using packages [here][pub-global].

## Usage

`webdev_proxy` supports one command: `serve`

### `webdev_proxy serve`

```
Run `webdev serve` (a local web development server) behind a proxy that supports HTML5 routing by rewriting not-found requests to index.html.

Usage: webdev_proxy serve [-- [webdev serve arguments]]
-h, --help                 Print this usage information.
    --[no-]rewrite-404s    Rewrite every request that returns a 404 to /index.html
                           (defaults to on)

Run "webdev_proxy help" to see global options.

You may use any of the following options supported by `webdev serve` by passing them after the `--` separator.

webdev serve --help:
====================

Run a local web development server and a file system watcher that rebuilds on changes.

Usage: webdev serve [arguments] [<directory>[:<port>]]...
-h, --help                        Print this usage information.
-o, --output                      A directory to write the result of a build to. Or a mapping from a top-level directory in the package to the directory to write a filtered build output to. For example
                                  "web:deploy".
                                  A value of "NONE" indicates that no "--output" value should be passed to `build_runner`.
                                  (defaults to "NONE")

-r, --[no-]release                Build with release mode defaults for builders.
    --[no-]build-web-compilers    If a dependency on `build_web_compilers` is required to run.
                                  (defaults to on)

-v, --verbose                     Enables verbose logging.
    --auto                        Automatically performs an action after each build:

                                  restart: Reload modules and re-invoke main (loses current state)
                                  refresh: Performs a full page refresh.
                                  [restart, refresh]

    --chrome-debug-port           Specify which port the Chrome debugger is listening on. If used with launch-in-chrome Chrome will be started with the debugger listening on this port.
    --[no-]debug                  Enable the launching of DevTools (Alt + D). Must use with either --launch-in-chrome or --chrome-debug-port.
    --hostname                    Specify the hostname to serve on.
                                  (defaults to "localhost")

    --[no-]launch-in-chrome       Automatically launches your application in Chrome with the debug port open. Use chrome-debug-port to specify a specific port to attach to an already running chrome instance
                                  instead.

    --log-requests                Enables logging for each request to the server.

Run "webdev help" to see global options.
```

Note that you can configure the underlying `webdev serve` process by passing any
of its supported command-line arguments after the `--` separator.

#### Examples

To run the default server and proxy:

```bash
$ webdev_proxy serve
```

To pass arguments to `webdev serve`, e.g. to enable auto-refresh:

```bash
$ webdev_proxy serve -- --auto=refresh
```

[pub-global]: https://dart.dev/tools/pub/cmd/pub-global
[pub-global-activate]: https://dart.dev/tools/pub/cmd/pub-global#activating-a-package
[webdev-install]: https://github.com/dart-lang/webdev#requirements
[webdev-serve]: https://github.com/dart-lang/webdev/tree/master/webdev#webdev-serve
