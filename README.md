[![Slack Channel](https://img.shields.io/badge/Support_Channel-Slack-purple)](https://slack.com/app_redirect?channel=support-frontend-dx)
[![Maintainer](https://img.shields.io/badge/maintainer-FEDX-silver)](https://wiki.atl.workiva.net/display/FEF/Frontend+Dev+Experience)
[![Documentation](https://img.shields.io/badge/Additional_Documentation-blue)](https://frontend.workiva.dev)

# webdev_proxy

A simple HTTP proxy for [webdev's serve command][webdev-serve] that adds support for rewriting certain requests, namely rewriting 404s to instead serve the root index (`/`). This enables HTML5 routing support for single-page applications during local development.

## Quick Start

### Prerequisites

- Dart SDK `2.11` or later
- `webdev` globally activated at a version in the `>=1.0.1 <3.0.0` range
  - Be sure to follow the [installation instructions for webdev][webdev-install]

### Installation

```bash
dart pub global activate webdev_proxy
```

Learn more about activating and using packages [here][pub-global].

### Usage

`webdev_proxy` supports one command: `serve`

To run the default server and proxy:

```bash
webdev_proxy serve
```

To pass arguments to `webdev serve`, e.g. to enable auto-refresh:

```bash
webdev_proxy serve -- --auto=refresh
```

## Documentation

### `webdev_proxy serve`

```
Run `webdev serve` (a local web development server) behind a proxy that supports HTML5 routing by rewriting not-found requests to index.html.

Usage: webdev_proxy serve [-- [webdev serve arguments]]
-h, --help                 Print this usage information.
    --[no-]rewrite-404s    Rewrite every request that returns a 404 to /index.html
                           (defaults to on)

Run "webdev_proxy help" to see global options.
```

Note that you can configure the underlying `webdev serve` process by passing any of its supported command-line arguments after the `--` separator.

See the [webdev serve documentation][webdev-serve] for all available options.

## Development

### Setup

Clone the repository and ensure you have the Dart SDK installed.

### Testing

```bash
dart test
```

### Building

```bash
dart pub get
```

## Support

For help, questions, or to report issues, reach out via the [#support-frontend-dx](https://slack.com/app_redirect?channel=support-frontend-dx) Slack channel.

[pub-global]: https://dart.dev/tools/pub/cmd/pub-global
[pub-global-activate]: https://dart.dev/tools/pub/cmd/pub-global#activating-a-package
[webdev-install]: https://github.com/dart-lang/webdev#requirements
[webdev-serve]: https://github.com/dart-lang/webdev/tree/master/webdev#webdev-serve
