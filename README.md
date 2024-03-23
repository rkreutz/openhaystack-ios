# <img src="OpenHaystack/Assets/Assets.xcassets/AppIcon.appiconset/openhaystack.png" height=42 width=42 valign=bottom /> OpenHaystack (iOS)

This project is an iOS implementation of the [OpenHaystack macOS app](https://github.com/seemoo-lab/openhaystack). It relies on a proxy server to fetch location records rather than on-device header generation.

## Requirements

- Xcode 15.2 or later.
- Proxy server to fetch records from (refer to [rkreutz/openhaystack-server](https://github.com/rkreutz/openhaystack-server)).
  - An AppleID with SMS enabled, to configure the proxy server.
