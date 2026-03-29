# LessGram — Developer Conventions

Last updated: 2026-03-28

---

## Stack

Expo SDK 51 · React Native · TypeScript · `react-native-webview`

Wraps `instagram.com` in a controlled WebView. CSS/JS injected before content loads. See `TRADEOFFS.txt` for framework decisions.

---

## Structure

```
less-gram/
├── App.tsx                     # Entry point
├── src/
│   └── InstagramWebView.tsx    # All blocking logic lives here
├── app.json                    # Expo config
├── package.json
├── tsconfig.json
└── babel.config.js
```

---

## Branching

- `main` — stable, runs cleanly in Expo Go
- `<name>/dev` — personal dev branch (e.g. `noah/dev`, `will/dev`)
- `<name>/<short-name>` — short-lived branches off dev (e.g. `noah/fix-reels`)

No direct pushes to `main`. PR + one approval required.

---

## Commits

```
feat: add dm tab
fix: reels flash on load
chore: bump deps
```

Types: `feat` `fix` `chore` `refactor` `docs` `test`

---

## Code Style

- 2 space indent, 120 char line limit
- `camelCase` vars/functions, `PascalCase` components/types
- No `any` — use proper types or `unknown`
- Default exports for components only, named exports elsewhere
- `StyleSheet.create()` for all styles, no inline objects

---

## Content Blocking

All logic in `src/InstagramWebView.tsx`. Three layers:

| Layer | Mechanism | When to use |
|---|---|---|
| CSS | `style.textContent` array in `INJECTED_JS` | Static element hiding |
| JS (SPA nav) | `BLOCKED` array in `INJECTED_JS` pushState override | Block client-side route changes |
| Hard block | `BLOCKED_PATHS` array → `onShouldStartLoadWithRequest` | Block before any load commits |

Use stable selectors (`href`, `aria-label`, `role`, `data-*`). Never class names — Instagram obfuscates them.

Dynamic elements (ads, suggested posts) → add to `hideDistractions()` inside `INJECTED_JS`.

---

## Block List

| Feature          | Status  |
|------------------|---------|
| Reels            | Blocked |
| Explore          | Blocked |
| Ads / Sponsored  | Blocked |
| Suggested posts  | Blocked |
| Live streams     | Blocked |
| Stories          | Keep    |
| Feed             | Keep    |
| DMs              | Keep    |
| Profiles         | Keep    |
| Posting          | Keep    |

Changes require a PR with discussion.

---

## Setup

```bash
yarn install
yarn expo start
```

Scan QR with **Expo Go** (App Store, free).

---

## CI

Pushes to `main` and `*/dev` run a TS type check. Red = fix before merging.

---

## Testing

Expo Go on device before every PR. Verify: login persists, feed loads, Reels gone, DMs work.
