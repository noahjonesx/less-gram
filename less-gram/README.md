# LessGram

Built with Expo + React Native. iOS only. Test with Expo Go — no Mac required.

---

## Quick Start

```bash
npm install
npx expo start
```
---

## How It Works

- Loads `instagram.com` in a `react-native-webview`
- Injects CSS/JS **before content loads** via `injectedJavaScriptBeforeContentLoaded` (no flash)
- `onShouldStartLoadWithRequest` provides a hard navigation block for `/reels/`, `/explore/`, `/live/`
- SPA navigation intercepted via `pushState`/`replaceState` override
- MutationObserver hides dynamically injected ads and suggested posts
- Cookie and localStorage persistence keeps you logged in across launches

See [CONVENTIONS.md](CONVENTIONS.md) before contributing.
