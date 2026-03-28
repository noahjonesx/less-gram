# LessGram — Developer Conventions

Last updated: 2026-03-28

This file is the source of truth for how we work together. Update it when conventions change. All contributors are expected to read this before pushing code.

---

## Project Overview

LessGram is an iOS-only Swift/SwiftUI app. It wraps `instagram.com` in a `WKWebView` and injects CSS/JS at document start to remove algorithmically addictive features (Reels, Explore feed, Ads, Suggested posts) while keeping core social functionality (feed, DMs, profiles, posting).

---

## Repository Structure

```
less-gram/
├── CONVENTIONS.md          # This file — always keep updated
├── TRADEOFFS.txt           # Framework decision rationale
├── README.md               # Setup and onboarding
├── .gitignore
└── LessGram/               # Xcode project root (created on Mac)
    ├── LessGram.xcodeproj/
    ├── App.swift               # @main entry point
    ├── ContentView.swift        # Root SwiftUI view
    ├── Views/
    │   └── InstagramWebView.swift   # Core WKWebView wrapper
    └── Scripts/
        ├── blocker.js           # JS: navigation blocking + DOM mutation hiding
        └── hide_distractions.css  # CSS: static element hiding
```

---

## Branching

- `main` — stable, always builds and runs on device
- `<yourname>/dev` — personal dev branch (e.g. `noah/dev`, `alex/dev`). All active work happens here.
- `<yourname>/<short-name>` — short-lived feature/fix branches off your dev branch if needed (e.g. `noah/reels-block`)

No direct pushes to `main`. Open a PR from your dev branch, get one approval.

---

## Commits

Use conventional commits format:

```
feat: add bottom tab bar with feed and DM icons
fix: prevent reels flash on page load
chore: update gitignore for xcuserdata
```

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`

---

## Swift Code Style

- **Indentation:** 4 spaces (no tabs)
- **Line length:** 120 chars max
- **Naming:** Swift standard — `camelCase` for vars/functions, `PascalCase` for types
- **Access control:** default to `private`/`internal`; only use `public` when actually needed
- **No force unwrap (`!`)** in production paths — use `guard let` or `if let`
- One type per file. File name matches type name.
- Mark sections with `// MARK: - Section Name`

---

## Adding / Modifying Content Blocking Rules

All element hiding lives in two files. Do not scatter blocking logic elsewhere.

### CSS rules → `LessGram/Scripts/hide_distractions.css`
Use for static, selector-based hiding. Prefer `aria-label`, `href`, `role`, and
`data-*` attributes over class names (Instagram obfuscates class names and changes
them frequently — selectors based on them will break silently).

```css
/* Good — stable */
a[href="/reels/"] { display: none !important; }

/* Bad — will break when Instagram deploys */
._aano._aaop { display: none !important; }
```

### JS rules → `LessGram/Scripts/blocker.js`
Use for dynamic content (elements injected after page load), navigation interception,
and anything requiring DOM traversal logic. The MutationObserver in blocker.js watches
for new nodes — add new hiding logic inside `hideDistractions()`.

### Navigation blocking → `InstagramWebView.swift` Coordinator
Blocked URL path prefixes live in the `blockedPaths` array in `Coordinator.webView(_:decidePolicyFor:)`.
Add paths there, not in JS, for hard blocks (JS blocks can be bypassed by the SPA router).

---

## What We Block vs Keep

| Feature          | Status  | Reason                              |
|------------------|---------|-------------------------------------|
| Reels feed       | Blocked | Core product decision               |
| Explore page     | Blocked | Algorithmic rabbit hole             |
| Ads / Sponsored  | Blocked | Distraction, no revenue model here  |
| Suggested posts  | Blocked | Algorithmic filler                  |
| Live streams     | Blocked | Reels-adjacent                      |
| Stories          | Keep    | Friend-driven content               |
| Feed             | Keep    | Core use case                       |
| DMs              | Keep    | Core use case                       |
| Profile browsing | Keep    | Intentional navigation              |
| Posting          | Keep    | Core use case                       |

Changes to this table require a PR with discussion — it defines the product.

---

## Xcode Project Setup (one-time, per machine)

1. Install Xcode from the Mac App Store (free)
2. Open Xcode → File → New → Project → iOS → App
3. Product Name: `LessGram`, Interface: `SwiftUI`, Language: `Swift`
4. Save into the `less-gram/` repo directory
5. Delete the generated `ContentView.swift` and replace with files from `LessGram/`
6. Add `LessGram/Scripts/` as a folder reference (not a group) so files are bundled
7. Set minimum deployment target to iOS 16.0

---

## Testing

- No unit test framework set up yet. Manual testing via TestFlight.
- Before any PR, verify on device (not just simulator): login persists, feed loads, Reels tab is gone, /reels/ URL is blocked, DMs work.
- Simulator is acceptable for layout checks only.

---

## Environment

- Xcode 15+ required (macOS required for builds)
- Minimum iOS target: 16.0
- No third-party dependencies — zero CocoaPods, zero SPM packages (keep it lean)
- Editing: Rider with Swift plugin, VS Code with Swift extension, or Xcode all acceptable
