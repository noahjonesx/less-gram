# LessGram

Instagram without the algorithm. No Reels. No Explore. No Ads. Just your feed, DMs, and profiles.

Built with Swift/SwiftUI + WKWebView. iOS only.

---

## Quick Start (Mac required for builds)

1. Clone the repo
2. Open `LessGram/LessGram.xcodeproj` in Xcode 15+
3. Set your Apple Developer team in Signing & Capabilities
4. Build and run on device or simulator (`Cmd+R`)

See [CONVENTIONS.md](CONVENTIONS.md) before contributing.

---

## How It Works

- Loads `instagram.com` in a `WKWebView` with cookie persistence (you stay logged in)
- Injects CSS at document start to hide Reels nav, Explore, Ads, and Suggested posts
- Injects JS to intercept SPA navigation and block routes like `/reels/`, `/explore/`
- `WKNavigationDelegate` provides a hard block at the network level as a second layer
- User agent is set to iPhone Safari so Instagram serves the correct mobile web UI

## Distribution

TestFlight (internal). See CONVENTIONS.md for device testing requirements before merging.
