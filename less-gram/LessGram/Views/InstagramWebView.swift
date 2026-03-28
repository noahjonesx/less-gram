import SwiftUI
import WebKit

// MARK: - InstagramWebView

/// Loads instagram.com in a persistent WKWebView and injects blocking scripts
/// at document start to strip algorithmically addictive features before they render.
struct InstagramWebView: UIViewRepresentable {

    // iPhone 15 Pro user agent — tells Instagram to serve the full mobile web UI
    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    private static let instagramURL = URL(string: "https://www.instagram.com/")!

    // MARK: UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = Self.userAgent
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.load(URLRequest(url: Self.instagramURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Configuration

    private func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        // Persistent data store keeps the user logged in across launches
        config.websiteDataStore = .default()

        let controller = WKUserContentController()
        controller.addUserScript(cssInjectionScript())
        controller.addUserScript(jsBlockerScript())
        config.userContentController = controller

        return config
    }

    // MARK: - CSS Injection

    /// Injects static CSS rules at document start to hide known distraction elements.
    /// Uses stable selectors (href, aria-label, role) — never obfuscated class names.
    private func cssInjectionScript() -> WKUserScript {
        let source = """
        (function() {
            var style = document.createElement('style');
            style.id = 'lessgram-css';
            style.textContent = \(cssContent.debugDescription);
            var inject = function() {
                if (document.head && !document.getElementById('lessgram-css')) {
                    document.head.appendChild(style);
                }
            };
            inject();
            document.addEventListener('DOMContentLoaded', inject);
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    // MARK: - JS Blocker

    private func jsBlockerScript() -> WKUserScript {
        return WKUserScript(source: jsBlockerContent, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

// MARK: - Coordinator (Navigation Delegate)

extension InstagramWebView {

    class Coordinator: NSObject, WKNavigationDelegate {

        /// Hard-blocked URL path prefixes — the JS layer also blocks these,
        /// but WKNavigationDelegate is the authoritative gate.
        private let blockedPaths = [
            "/reels/",
            "/explore/",
            "/live/",
        ]

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url,
                  url.host?.contains("instagram.com") == true else {
                decisionHandler(.allow)
                return
            }

            let path = url.path
            if blockedPaths.contains(where: { path.hasPrefix($0) }) {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}

// MARK: - Inline Script Content
// These are inlined so the app works without file bundle references.
// If scripts grow large, move them to LessGram/Scripts/ and load via Bundle.main.

private let cssContent = """
/* === LessGram: Hide distracting elements === */

/* Reels and Explore nav links */
a[href="/reels/"],
a[href="/reels"],
a[href="/explore/"],
a[href="/explore"] {
    display: none !important;
}

/* Live badge on stories */
[aria-label="Live"] {
    display: none !important;
}

/* Shopping tab */
a[href*="/shopping/"] {
    display: none !important;
}

/* Suppress the "Try Instagram on the app" banner */
[id="iab-link"],
[data-testid="app-promo-banner"] {
    display: none !important;
}

/* Reel icons inside feed posts (the film-strip icon on video thumbnails) */
[aria-label="Reel"] {
    display: none !important;
}
"""

private let jsBlockerContent = """
(function() {
    'use strict';

    const BLOCKED = ['/reels/', '/reels', '/explore/', '/explore', '/live/'];

    function isBlocked(path) {
        return BLOCKED.some(function(b) {
            return path === b || path.startsWith(b + '?') || path.startsWith('/reels/') || path.startsWith('/explore/') || path.startsWith('/live/');
        });
    }

    // Intercept SPA pushState / replaceState navigation
    const _push = history.pushState.bind(history);
    const _replace = history.replaceState.bind(history);

    history.pushState = function(state, title, url) {
        if (url && isBlocked(String(url))) return;
        return _push(state, title, url);
    };

    history.replaceState = function(state, title, url) {
        if (url && isBlocked(String(url))) return;
        return _replace(state, title, url);
    };

    // Catch popstate (back/forward) to blocked pages
    window.addEventListener('popstate', function() {
        if (isBlocked(window.location.pathname)) {
            history.back();
        }
    });

    // MutationObserver: hide dynamic elements injected after page load
    function hideDistractions() {
        // Sponsored / ad posts
        document.querySelectorAll('span').forEach(function(span) {
            if (span.childElementCount === 0 && span.textContent.trim() === 'Sponsored') {
                var el = span;
                for (var i = 0; i < 10; i++) {
                    el = el.parentElement;
                    if (!el) break;
                    if (el.tagName === 'ARTICLE') {
                        el.style.setProperty('display', 'none', 'important');
                        break;
                    }
                }
            }
        });

        // "Suggested for you" sections
        document.querySelectorAll('span, h2').forEach(function(el) {
            if (el.textContent.trim() === 'Suggested for you') {
                var container = el;
                for (var i = 0; i < 6; i++) {
                    container = container.parentElement;
                    if (!container) break;
                    if (container.tagName === 'SECTION') {
                        container.style.setProperty('display', 'none', 'important');
                        break;
                    }
                }
            }
        });

        // Reels and Explore nav items (belt-and-suspenders over CSS)
        document.querySelectorAll('a[href="/reels/"], a[href="/reels"], a[href="/explore/"], a[href="/explore"]').forEach(function(a) {
            var li = a.closest('li') || a.parentElement;
            if (li) li.style.setProperty('display', 'none', 'important');
        });
    }

    var observer = new MutationObserver(hideDistractions);

    function startObserver() {
        if (document.body) {
            hideDistractions();
            observer.observe(document.body, { childList: true, subtree: true });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', startObserver);
    } else {
        startObserver();
    }
})();
"""
