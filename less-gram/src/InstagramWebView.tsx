import { StyleSheet } from 'react-native';
import { WebView, WebViewNavigation } from 'react-native-webview';

const INSTAGRAM_URL = 'https://www.instagram.com/';

// iPhone 15 Pro — tells Instagram to serve the full mobile web UI
const USER_AGENT =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

// Paths that are hard-blocked. onShouldStartLoadWithRequest fires before navigation commits.
const BLOCKED_PATHS = ['/reels/', '/reels', '/explore/', '/explore', '/live/'];

function isBlocked(url: string): boolean {
  try {
    const path = new URL(url).pathname;
    return BLOCKED_PATHS.some((b) => path === b || path.startsWith(b));
  } catch {
    return false;
  }
}

// Injected before content loads — equivalent to WKUserScript atDocumentStart.
// MUST return true at the end or react-native-webview will throw.
const INJECTED_JS = `
(function() {
  'use strict';

  // ── CSS: hide distraction elements ──────────────────────────────────────────
  var style = document.createElement('style');
  style.id = 'lessgram-css';
  style.textContent = [
    'a[href="/reels/"], a[href="/reels"] { display: none !important; }',
    'a[href="/explore/"], a[href="/explore"] { display: none !important; }',
    'a[href*="/shopping/"] { display: none !important; }',
    '[aria-label="Live"] { display: none !important; }',
    '[aria-label="Reel"] { display: none !important; }',
    '[data-testid="app-promo-banner"] { display: none !important; }',
  ].join('\\n');

  function injectStyle() {
    if (document.head && !document.getElementById('lessgram-css')) {
      document.head.appendChild(style);
    }
  }
  injectStyle();
  document.addEventListener('DOMContentLoaded', injectStyle);

  // ── JS: block SPA navigation to restricted routes ────────────────────────────
  var BLOCKED = ['/reels/', '/reels', '/explore/', '/explore', '/live/'];

  function isBlockedPath(url) {
    try {
      var path = new URL(url, 'https://www.instagram.com').pathname;
      return BLOCKED.some(function(b) { return path === b || path.startsWith(b + '?') || path.startsWith('/reels/') || path.startsWith('/explore/') || path.startsWith('/live/'); });
    } catch(e) { return false; }
  }

  var _push = history.pushState.bind(history);
  var _replace = history.replaceState.bind(history);

  history.pushState = function(state, title, url) {
    if (url && isBlockedPath(String(url))) return;
    return _push(state, title, url);
  };

  history.replaceState = function(state, title, url) {
    if (url && isBlockedPath(String(url))) return;
    return _replace(state, title, url);
  };

  window.addEventListener('popstate', function() {
    if (isBlockedPath(window.location.href)) history.back();
  });

  // ── MutationObserver: hide dynamic elements (ads, suggested posts) ───────────
  function hideDistractions() {
    // Sponsored posts
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
true;
`;

export default function InstagramWebView() {
  function handleNavigationRequest(request: WebViewNavigation): boolean {
    if (isBlocked(request.url)) return false;
    return true;
  }

  return (
    <WebView
      style={styles.webview}
      source={{ uri: INSTAGRAM_URL }}
      userAgent={USER_AGENT}
      injectedJavaScriptBeforeContentLoaded={INJECTED_JS}
      onShouldStartLoadWithRequest={handleNavigationRequest}
      sharedCookiesEnabled={true}
      domStorageEnabled={true}
      thirdPartyCookiesEnabled={true}
      allowsBackForwardNavigationGestures={true}
      javaScriptEnabled={true}
    />
  );
}

const styles = StyleSheet.create({
  webview: {
    flex: 1,
  },
});
