# 7. History, Caching & UX Patterns

htmx v4.0.1 provides progressive enhancement (`hx-boost`), clean browser history navigation (`hx-push-url`, `hx-replace-url`, `hx-history-elt`), opt-in `sessionStorage` snapshot caching (`hx-history-cache`), flicker-free loading indicators (`hx-indicator`, `hx-disable`), and bandwidth-saving conditional polling (`hx-ptag`).

```drawlib align=center code=fold file=ch07_history_and_cache_flow.png caption="htmx v4.0.1 Browser History Navigation, Core AJAX Restore, and hx-history-cache Flow"
from drawlib import canvas
from drawlib.diagrams.flow import Decision, End, FlowDiagram, Process, Start
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=192, height=82)

flow = FlowDiagram(
    node_style=Styles.Neutral.patch(text_size=9.5),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=9.5),
    title="Browser Back/Forward (popstate) Restoration Pipeline in htmx v4.0.1",
)

pop = flow.add(Start("Browser Back/Forward\n(popstate Event)", width=34, height=13, style=Styles.PrimaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)), xy=(22, 48))
cfg_chk = flow.add(Decision("config.history\nMode?", width=34, height=18, style=Styles.PrimaryNeutral.patch(text_size=9.5)), xy=(66, 48))
reload_end = flow.add(End("location.reload()\nHard Browser Refresh", width=36, height=13, style=Styles.SecondaryNeutral.patch(text_size=9.5)), xy=(66, 16))

ext_chk = flow.add(Decision("hx-history-cache\nHit in sessionStorage?", width=40, height=20, style=Styles.SecondaryNeutral.patch(text_size=9.5)), xy=(114, 48))
cache_hit = flow.add(
    End("Instant outerSync Swap\nRestore Input & Scroll\n(Zero Network Call)", width=44, height=16, style=Styles.PrimaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)),
    xy=(164, 64),
)
core_fetch = flow.add(
    End("Core Fetch GET URL\nHX-History-Restore-Request\nSwap [hx-history-elt] / body", width=44, height=16, style=Styles.PrimaryNeutral.patch(text_size=9.5)),
    xy=(164, 22),
)

pop.connect(cfg_chk, padding=1.0)
cfg_chk.connect(reload_end, label='"reload"', start_side="bottom", end_side="top", padding=1.0)
cfg_chk.connect(ext_chk, label="true", start_side="right", end_side="left", padding=1.0)
ext_chk.connect(cache_hit, label="Cache Hit", start_side="top", end_side="left", padding=1.0)
ext_chk.connect(core_fetch, label="Miss / Core Only", start_side="bottom", end_side="left", padding=1.0)

flow.draw(xy=(4.0, 4.0))
canvas.save()
```

---

## 7.1 Progressive Enhancement with `hx-boost:inherited="true"`

Adding `hx-boost:inherited="true"` to `<body>` or a navigation container upgrades standard `<a href="...">` links and `<form>` submissions into AJAX requests targeting `document.body` while preserving graceful fallback if JavaScript is disabled:

```html
<!-- Boost all internal links and forms inside the application shell -->
<body hx-boost:inherited="true">
  <header>
    <nav>
      <a href="/projects">Projects</a>
      <a href="/billing">Billing</a>
      <!-- Opt a specific link out of boosting -->
      <a href="/legacy-app" hx-boost="false">Legacy Portal</a>
    </nav>
  </header>

  <main id="app-content" hx-history-elt>
    <h1>Welcome</h1>
  </main>
</body>
```

> [!IMPORTANT]
> Because `hx-boost` is almost always placed on a parent container (`<body>`, `<nav>`, `<main>`) for its descendant links and forms, **always include the `:inherited` modifier** (`hx-boost:inherited="true"`) in htmx v4.0.1!

---

## 7.2 Browser History Management (`hx-push-url`, `hx-replace-url`, `hx-history-elt`)

In htmx 2, history navigation serialized DOM snapshots into `localStorage`, which frequently caused quota issues and stale UI bugs. **In htmx v4.0.1 core, history restoration is clean and stateless**: when a user clicks Back or Forward, htmx issues an AJAX `GET` request with `HX-History-Restore-Request: true` and `HX-Request-Type: full`.

| Attribute / Config | Values | Behavior in htmx v4.0.1 |
| :--- | :--- | :--- |
| **`hx-push-url`** | `"true"`, `"false"`, or custom URL | Pushes the request URL (or custom URL) via `history.pushState()` after swap. |
| **`hx-replace-url`** | `"true"`, `"false"`, or custom URL | Replaces the current URL via `history.replaceState()` without adding a history entry. |
| **`hx-history-elt`** | Boolean attribute on container | Marks the element (e.g. `<main hx-history-elt>`) to swap during history restoration instead of `document.body`. |
| **`htmx.config.history`** | `true` *(default)*, `false`, `"reload"` | `true`: AJAX restore on Back/Forward; `false`: disables history; `"reload"`: runs `location.reload()` on Back/Forward. |

---

## 7.3 Instant Snapshot Restoration with `hx-history-cache`

When you want instantaneous zero-network Back/Forward restoration that also preserves user-typed `<input>` values, checkboxes, and scroll offsets, load the official **`hx-history-cache.js`** extension (`registers as: 'history-cache'`).

Unlike htmx 2's `localStorage` cache, `hx-history-cache` in htmx v4.0.1:
- Stores entries in per-tab **`sessionStorage`** keyed by a unique `history.state.htmxId` UUID.
- Annotates and restores form input values (`input`, `textarea`, `select`, excluding `password` and `file`) and scroll positions (`scrollTop`, `scrollLeft`).
- Swaps cached HTML using **`outerSync`** by default to keep the root container node stable.
- Automatically skips caching any page containing `<div hx-history="false">`.

```html
<script src="/dist/htmx.min.js"></script>
<script src="/dist/ext/hx-history-cache.min.js"></script>
<script>
  // Optional customization (if using htmax.js, set disable: false to activate)
  htmx.config.historyCache = {
    size: 15,              // Max LRU snapshots in sessionStorage (default: 10)
    refreshOnMiss: false,  // If true, runs location.reload() on cache miss
    disable: false,        // Set to false when enabling inside htmax.js
    swapStyle: 'outerSync' // Default swap style on cache hit
  };
</script>
```

---

## 7.4 Flicker-Free Loading Indicators & Disabling Controls

Fast requests (`< 150ms`) should feel instantaneous without flashing a spinner, while slower requests should clearly communicate progress and prevent double-submissions.

```drawlib align=center code=fold file=ch07_indicator_and_ptag.png caption="Flicker-Free Loading Indicator CSS Timeline and hx-ptag Conditional 304 Polling"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel
from drawlib.styles import Styles

setup(width=174, height=74)

# Left Panel: Flicker-Free Indicator & hx-disable
left_panel = Panel(
    "Flicker-Free Loading UX",
    "hx-indicator + hx-disable",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.spinner_gap,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=9.0,
)
left_panel.draw((6.0, 6.0), width=78.0, height=62.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box((6.0, 6.0), width=78.0, height=62.0, padding=(3.5, 3.0))

ux_cards = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    spacing=2.2,
)
ux_cards.add("1. Request Starts (0ms)", "htmx adds .htmx-request & disables hx-disable targets", badge_text="0ms")
ux_cards.add(
    "2. CSS Transition Delay (200ms)",
    "Fast responses (<200ms) finish before spinner shows",
    badge_text="200ms",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=9.5),
)
ux_cards.add(
    "3. Slow Request (>200ms)",
    "Spinner fades in smoothly; hx-browser-indicator spins tab",
    badge_text="SLOW",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=9.5),
)
ux_cards.draw(l_xy, width=l_w, height=l_h)

# Right Panel: Conditional Polling with hx-ptag
right_panel = Panel(
    "Conditional Polling (hx-ptag)",
    "Zero-DOM-Churn 304 Responses",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.arrows_clockwise,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=9.0,
)
right_panel.draw((90.0, 6.0), width=78.0, height=62.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box((90.0, 6.0), width=78.0, height=62.0, padding=(3.5, 3.0))

ptag_cards = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=9.5),
    spacing=2.2,
)
ptag_cards.add("1. Initial hx-ptag='v1'", "Element stores current version tag on elt._htmx.ptag", badge_text="INIT")
ptag_cards.add("2. Poll Sends HX-PTag: v1", "htmx_config_request attaches HX-PTag request header", badge_text="REQ")
ptag_cards.add(
    "3. 304 Not Modified or 200 + v2",
    "304 skips swap via config.noSwap; 200 updates ptag to v2",
    badge_text="304",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
)
ptag_cards.draw(r_xy, width=r_w, height=r_h)

save()
```

### Combining `hx-indicator`, `transition-delay`, and `hx-disable`

```css
/* Delay spinner visibility by 200ms so fast responses never flash a loading icon */
.htmx-indicator {
  opacity: 0;
  transition: opacity 150ms ease-in;
}
.htmx-request .htmx-indicator,
.htmx-request.htmx-indicator {
  opacity: 1;
  transition: opacity 200ms ease-in 200ms;
}
```

```html
<form hx-post="/orders/submit"
      hx-indicator="#submit-spinner"
      hx-disable="find button, find input">
  <input type="text" name="coupon_code" placeholder="Promo code">
  <button type="submit">
    Place Order
    <span id="submit-spinner" class="htmx-indicator">Processing...</span>
  </button>
</form>
```

---

## 7.5 Conditional Polling with `hx-ptag` (`HX-PTag`)

When polling an endpoint frequently (`hx-trigger="every 3s"`), re-rendering and swapping identical HTML wastes bandwidth and CPU. The official **`hx-ptag.js`** extension (`registers as: 'ptag'`) attaches a per-element entity tag header (`HX-PTag`) to each request:

1. Seed the element with `hx-ptag="<initial-hash>"` (or let the first response set the `HX-PTag` response header).
2. On every subsequent request, `hx-ptag` sends `HX-PTag: <current-value>`.
3. If the underlying data has not changed, your server returns **`HTTP 304 Not Modified`** with an empty body (which htmx automatically skips swapping because `304` is in `htmx.config.noSwap`). When data changes, the server returns `HTTP 200 OK` with the new HTML and an updated `HX-PTag: <new-hash>` response header.

```html
<script src="/dist/ext/hx-ptag.min.js"></script>

<div id="live-scoreboard"
     hx-get="/scores/live"
     hx-trigger="every 3s"
     hx-ptag="score-rev-41"
     hx-swap="innerMorph">
  Team A: 2 — Team B: 1
</div>
```
