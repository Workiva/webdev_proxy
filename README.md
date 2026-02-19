[Reference Pills]
[![Slack Channel](https://img.shields.io/badge/Support_Channel-Slack-purple)](https://slack.com/app_redirect?channel=support-frontend-dx)
[![Maintainer](https://img.shields.io/badge/maintainer-FEDX-silver)](https://wiki.atl.workiva.net/display/FEF/Frontend+Dev+Experience)
[![Documentation](https://img.shields.io/badge/Additional_Documentation-blue)](https://frontend.workiva.dev)

# webdev_proxy

`webdev_proxy` is a lightweight HTTP proxy for `webdev serve` that helps web apps using HTML5 routing. It rewrites 404 responses to the root `index.html`, so client-side routes keep working during local development. This tool is intended for frontend developers working with Dart/webdev-based applications.

## Quick Start

### Prerequisites

- Dart SDK `>=2.19.0 <3.0.0`
- `webdev` globally activated in your Dart environment

### Installation

```bash
dart pub global activate webdev_proxy
```

### Usage

Run the proxy in front of `webdev serve`:

```bash
webdev_proxy serve
```

Pass any supported `webdev serve` options after `--`:

```bash
webdev_proxy serve -- --auto=refresh
```

## Documentation

- Package repository: https://github.com/Workiva/webdev_proxy
- Dart pub global activation docs: https://dart.dev/tools/pub/cmd/pub-global#activating-a-package

## Development

### Setup

Install dependencies and verify the CLI help output:

```bash
dart pub get
dart run bin/webdev_proxy.dart --help
```

### Testing

Run the test suite:

```bash
dart test
```

### Building

Build a standalone executable:

```bash
dart compile exe bin/webdev_proxy.dart -o webdev_proxy
```

## Support

For help or feature discussions, use the Frontend DX support Slack channel: https://slack.com/app_redirect?channel=support-frontend-dx. For maintainer ownership details, see the FEDX wiki page: https://wiki.atl.workiva.net/display/FEF/Frontend+Dev+Experience.
