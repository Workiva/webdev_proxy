[Reference Pills]
[![Slack Channel](https://img.shields.io/badge/Support_Channel-Slack-purple)](https://slack.com/app_redirect?channel=support-frontend-dx)
[![Maintainer](https://img.shields.io/badge/maintainer-FEDX-silver)](https://wiki.atl.workiva.net/display/FEF/Frontend+Dev+Experience)
[![Documentation](https://img.shields.io/badge/Additional_Documentation-blue)](https://frontend.workiva.dev)

# webdev_proxy

`webdev_proxy` is a lightweight HTTP proxy for `webdev serve` that improves local development for apps using HTML5 routing. It can rewrite `404` requests to `index.html` so browser-refresh and direct navigation to nested routes work as expected. This tool is intended for frontend developers using Dart `webdev` workflows.

## Quick Start

### Prerequisites

- Dart SDK `>=2.19.0 <3.0.0`
- `webdev` globally activated (`>=1.0.1 <3.0.0`)

### Installation

```bash
dart pub global activate webdev_proxy
```

### Usage

Run the proxy with default behavior:

```bash
webdev_proxy serve
```

Pass flags through to `webdev serve` after `--`:

```bash
webdev_proxy serve -- --auto=refresh
```

## Documentation

- Dart pub global activation docs: https://dart.dev/tools/pub/cmd/pub-global#activating-a-package
- `webdev serve` docs: https://github.com/dart-lang/webdev/tree/master/webdev#webdev-serve

## Development

### Setup

Install dependencies:

```bash
dart pub get
```

### Testing

Run the test suite:

```bash
dart test
```

### Building

Run a local build/serve workflow:

```bash
dart run webdev serve
```

## Support

For help, questions, or issues, use the `#support-frontend-dx` Slack channel. For FEDX ownership and additional process documentation, see the FEDX wiki page in the maintainer badge above.
