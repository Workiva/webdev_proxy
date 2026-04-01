Reference Pills
[![Slack Channel](https://img.shields.io/badge/Support_Channel-Slack-purple)](https://slack.com/app_redirect?channel=support-frontend-dx)
[![Maintainer](https://img.shields.io/badge/maintainer-FEDX-silver)](https://wiki.atl.workiva.net/display/FEF/Frontend+Dev+Experience)
[![Documentation](https://img.shields.io/badge/Additional_Documentation-blue)](https://frontend.workiva.dev)

# webdev_proxy

`webdev_proxy` is a lightweight HTTP proxy for `webdev serve` that adds HTML5 routing support by rewriting not-found requests to your app root (`/index.html`). It is intended for frontend developers running local Dart web applications that rely on client-side routing. Use it as a drop-in development helper when `webdev serve` alone is not enough for SPA route handling.

## Quick Start

### Prerequisites

- Dart SDK `>=2.19.0 <3.0.0`
- `webdev` globally activated (`>=1.0.1 <3.0.0`)

### Installation

```bash
dart pub global activate webdev_proxy
```

### Usage

Run the proxy in front of `webdev serve`:

```bash
webdev_proxy serve
```

Pass through any `webdev serve` arguments after `--`:

```bash
webdev_proxy serve -- --auto=refresh
```

## Documentation

- Package homepage: https://github.com/Workiva/webdev_proxy
- Dart pub global tools docs: https://dart.dev/tools/pub/cmd/pub-global
- `webdev serve` docs: https://github.com/dart-lang/webdev/tree/master/webdev#webdev-serve

## Development

### Setup

Clone the repository and install dependencies:

```bash
dart pub get
```

For local CLI development, activate from source:

```bash
dart pub global activate --source path .
```

### Testing

Run the test suite:

```bash
dart test
```

### Building

Use `webdev` build/serve workflows in your consuming app, or run a local build in this repo when needed:

```bash
dart run build_runner build
```

## Support

For help, reach out in `#support-frontend-dx` on Slack or open an issue in this repository.
