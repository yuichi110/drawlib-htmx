# htmx v4.0.1 User Guide

Welcome to the comprehensive engineering guide for **htmx v4.0.1**—a ground-up modernization of the hypermedia-oriented JavaScript library that empowers any HTML element to issue HTTP requests, stream server updates, and morph DOM state directly from declarative markup.

```drawlib align=center code=fold file=htmx4_hero_overview.png caption="htmx v4.0.1 Hypermedia Runtime & Server Interaction Architecture"
from drawlib import canvas
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=184, height=96)

d = ArchitectureDiagram(
    node_style=Styles.Primary,
    node_text_style=Styles.DarkBold.patch(text_size=10.5),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=10.0),
    node_card_style=Styles.Neutral,
    title="htmx v4.0.1 Hypermedia Runtime & End-to-End Request Pipeline",
)

browser = d.add(NodeGroup(title="Browser Runtime (htmx v4.0.1 Core + Extensions)", padding=6.0), xy=(6.0, 8.0))

dom = browser.add(
    Node("Declarative HTML\n(:inherited / hx-*)", width=28, height=18, icon=PhosphorIcon.CODE, icon_size=7.5),
    xy=(20.0, 52.0),
)
fetch_core = browser.add(
    Node("fetch() Request Core\n(HCON & hx-sync)", width=28, height=18, icon=PhosphorIcon.PAPER_PLANE_TILT, icon_size=7.5, style=Styles.White, card_style=Styles.PrimaryFlat, text_style=Styles.WhiteBold.patch(text_size=10.5)),
    xy=(70.0, 52.0),
)
morph_swap = browser.add(
    Node("Swap & Morph Engine\n(innerMorph / <hx-partial>)", width=30, height=18, icon=PhosphorIcon.STACK, icon_size=7.5, card_style=Styles.PrimaryNeutral),
    xy=(70.0, 18.0),
)
ext_bus = browser.add(
    Node("Extension Hook Bus\n(17 Official Exts)", width=28, height=18, icon=PhosphorIcon.PLUGS_CONNECTED, icon_size=7.5, card_style=Styles.SecondaryNeutral),
    xy=(20.0, 18.0),
)

server = d.add(NodeGroup(title="Hypermedia Server", padding=6.0), xy=(128.0, 8.0))
endpoint = server.add(
    Node("HTML Fragment\nController", width=28, height=18, icon=PhosphorIcon.HARD_DRIVES, icon_size=7.5, card_style=Styles.PrimaryNeutral),
    xy=(18.0, 52.0),
)
streams = server.add(
    Node("Status & Partials\n(hx-status / SSE / WS)", width=28, height=18, icon=PhosphorIcon.BROADCAST, icon_size=7.5),
    xy=(18.0, 18.0),
)

d.connect(dom, fetch_core, label="1. Trigger", padding=1.2)
d.connect(fetch_core, endpoint, label="2. HTTP + HX-*", padding=1.2)
d.connect(endpoint, streams, label="3. Render", padding=1.2)
d.connect(streams, morph_swap, label="4. Fragments", padding=1.2)
d.connect(morph_swap, ext_bus, label="5. Swap Hooks", arrow="<->", padding=1.2)
d.connect(ext_bus, dom, label="6. Hydrate", padding=1.2)

d.draw(xy=(4.0, 4.0))
canvas.save()
```

---

## Why htmx v4.0.1?

htmx 4 reimagines hypermedia-driven development around modern web platform primitives while eliminating legacy complexity from htmx 2. Instead of serializing JSON payloads and maintaining duplicate client-side state stores, your server renders **HTML fragments** that htmx seamlessly integrates into the live document.

| Architectural Pillar | htmx v4.0.1 Capability | Key Engineering Benefit |
| :--- | :--- | :--- |
| **`fetch()` Native Core** | Replaces `XMLHttpRequest` with `fetch()`, `AbortSignal`, and `ReadableStream` | Enables streaming responses (`hx-multipart`, `hx-sse`, `hx-download`) and clean request interception |
| **Explicit Inheritance (`:inherited`)** | Parent attributes only cascade when explicitly marked (e.g., `hx-target:inherited="#main"`) | Eliminates accidental attribute leakage across deeply nested component trees |
| **First-Class Multi-Region Partials** | `<hx-partial hx-target="..." hx-swap="...">` elements in server responses | Cleanly updates multiple independent page regions in a single HTTP round-trip |
| **Built-In DOM Morphing** | `innerMorph`, `outerMorph`, and `outerSync` swap strategies in core | Preserves focus, scroll position, video playback, and CSS animations without external libraries |
| **Declarative Status Routing** | `hx-status:422="target:#errors"` and wildcard `hx-status:5xx` | Routes validation errors and server failures to dedicated UI targets without custom JS |
| **HCON Configuration Notation** | Concise key-value syntax (`defaultSwap:outerHTML, logAll:true`) alongside JSON | Simplifies `<meta name="htmx-config">`, `hx-vals`, `hx-headers`, and `hx-config` |
| **17 Official Extensions & `htmax.js`** | Event-hook extension API (`htmx.registerExtension`) + all-in-one `htmax.js` bundle | Zero `hx-ext` boilerplate; load script files directly or enforce a strict CSP/extension whitelist |

```drawlib align=center code=fold file=htmx4_pillars_and_lifecycle.png caption="htmx v4.0.1 Core Pillars and 5-Stage Hypermedia Request Lifecycle"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import ChevronProcess, KpiCards
from drawlib.styles import Styles

setup(width=176, height=82)

# Top: 5-Stage Request & Swap Pipeline (Bottom-Left at y=60)
pipeline = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=1.8,
    flat_left_end=True,
)
pipeline.add("1. Trigger", description="Event / Filter / Poll")
pipeline.add("2. Configure", description="HCON / FormData / Sync")
pipeline.add(
    "3. Fetch Core",
    description="HTTP + HX-* Headers",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    description_style=Styles.White.patch(text_size=9.5),
)
pipeline.add("4. Status & Partials", description="hx-status / <hx-partial>", style=Styles.PrimaryNeutral)
pipeline.add("5. Swap & Settle", description="Morph / ViewTransition", style=Styles.SecondaryNeutral)
pipeline.draw(xy=(6.0, 60.0), width=164.0, height=15.0)

# Bottom: 2x3 KPI Grid of v4 Highlights (Bottom-Left at y=6)
kpi = KpiCards(
    style=Styles.Neutral,
    metric_style=Styles.PrimaryBold.patch(text_size=15.0),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    accent_style=Styles.PrimaryFlat,
    icon_style=Styles.PrimaryBold,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.30,
    spacing=3.0,
)
kpi.add("fetch()", "Modern Network Core", "Native Promises & ReadableStream", icon=phosphor.globe)
kpi.add(":inherited", "Explicit Inheritance", "Zero accidental attribute bleed", icon=phosphor.tree_structure)
kpi.add("Morph", "Built-in DOM Diffing", "innerMorph & outerMorph in core", icon=phosphor.arrows_merge)
kpi.add(
    "<hx-partial>",
    "Multi-Region Updates",
    "Declarative out-of-band fragments",
    icon=phosphor.layout,
    metric_style=Styles.AccentBold.patch(text_size=14.0),
    accent_style=Styles.AccentFlat,
    icon_style=Styles.AccentBold,
)
kpi.add("hx-status", "Status Code Routing", "Wildcard 4xx/5xx & 422 targets", icon=phosphor.git_Fork if hasattr(phosphor, "git_Fork") else phosphor.git_branch)
kpi.add("17 Exts", "Official Extension Suite", "SSE, WS, Live, CSP, History Cache", icon=phosphor.plugs)
kpi.draw(xy=(6.0, 6.0), width=164.0, height=48.0, columns=3, align="bottom_left")

save()
```

---

## Quick Taste: Declarative Hypermedia in Action

With htmx v4.0.1, common UI workflows—such as form submission, server-side validation on `HTTP 422`, and multi-region badge updates—require zero custom JavaScript:

```html
<!-- Client HTML: Explicit inheritance, declarative 422 routing, and loading indicator -->
<section hx-target:inherited="#contact-list" hx-indicator:inherited="#save-spinner">
  <form hx-post="/contacts"
        hx-swap="beforeend"
        hx-status:422="target:#form-errors swap:innerHTML"
        hx-disable="find button">
    <input type="email" name="email" placeholder="engineer@example.com" required>
    <div id="form-errors" class="error-banner"></div>
    <button type="submit">Add Contact</button>
    <span id="save-spinner" class="htmx-indicator">Saving...</span>
  </form>

  <ul id="contact-list">
    <li id="contact-1">alice@example.com</li>
  </ul>
</section>
```

When the server accepts the new contact (`HTTP 200 OK`), it returns both the primary list item and an `<hx-partial>` fragment that updates the navigation counter badge simultaneously:

```html
<!-- Server HTTP 200 Response: Main fragment + explicit <hx-partial> update -->
<li id="contact-2">engineer@example.com</li>

<hx-partial hx-target="#contacts-count" hx-swap="textContent">
  2
</hx-partial>
```

---

## User Guide Chapters

Explore the 8 structured chapters of this guide to master htmx v4.0.1 from foundational concepts to production security:

| Chapter | Topic & Core Features Covered |
| :--- | :--- |
| **[1. Getting Started](01_getting_started.md)** | Installation (`npm install htmx.org@4.0.1`), bundle variants (`htmx.js`, `htmx.esm.js`, `htmax.js`), hypermedia mental model, request verbs (`hx-get`..`hx-query`), default triggers, and migrating from htmx 2 with `upgrade-check`. |
| **[2. Hypermedia Architecture](02_hypermedia_architecture.md)** | Hypermedia-Driven Application (HDA) design, explicit `:inherited` and `:append` modifiers vs `implicitInheritance`, `HX-Request-Type: partial \| full`, and 4 multi-region update patterns (`<hx-partial>`, `hx-swap-oob`, `HX-Trigger`, target expansion). |
| **[3. Requests & Triggers](03_requests_and_triggers.md)** | `hx-trigger` modifiers (`once`, `changed`, `delay`, `throttle`, `from`, `target`, `halt`), bracketed JS filters, `intersect` & polling, why `GET`/`DELETE` exclude enclosing forms, `hx-vals` & HCON (`js:`), `hx-headers`, `hx-config`, and `hx-sync`. |
| **[4. Targeting & Swapping](04_targeting_and_swapping.md)** | Extended relative CSS selectors (`this`, `closest`, `find`, `next`, `previous`), all 12 swap strategies (`innerHTML`, `outerSync`, `textContent`, etc.), built-in DOM morphing (`innerMorph`, `outerMorph`, `hx-morph-skip`), swap modifiers, `hx-preserve`, and View Transitions. |
| **[5. Headers, Events & Status](05_headers_events_and_status.md)** | Request headers (`HX-Source`, `HX-Target` as `tag#id`) and response headers (`HX-Trigger`, `HX-Retarget`, `HX-Location`), declarative `hx-status:XXX` routing, colon-separated `htmx:phase:action` events, `detail.ctx`, `hx-on:*`, and async `htmx:confirm`. |
| **[6. Extensions & Streaming](06_extensions_and_streaming.md)** | `htmx.registerExtension()` lifecycle & `extensions` whitelist, streaming HTML (`hx-sse`, `hx-ws`, `hx-multipart`), reactive DOM scripting with `hx-live` (`q()`, `.data`, `.aria`, `take()`, `toggle()`), UX extensions, and `htmax.js`. |
| **[7. History, Caching & UX](07_history_caching_and_ux.md)** | Progressive enhancement with `hx-boost:inherited="true"`, history navigation (`hx-push-url`, `hx-replace-url`, `hx-history-elt`, `htmx.config.history`), `sessionStorage` snapshots via `hx-history-cache`, flicker-free `hx-indicator`, and `hx-ptag` conditional polling. |
| **[8. Security, Testing & Debugging](08_security_testing_and_debugging.md)** | Hypermedia security boundaries (`hx-ignore` for untrusted content vs `hx-disable`), strict CSP (`hx-csp`, `hx-nonce`, `safeEval`, Trusted Types), debugging with `logAll` and `elt._htmx`, and automated testing with `@web/test-runner`, `fetch-mock`, and Playwright. |

---

## Companion Documentation Portals

This User Guide is part of a four-portal engineering documentation suite for `htmx v4.0.1`:

| Portal | URL | Description |
| :--- | :--- | :--- |
| **Portal 1: User Guide** *(Current)* | `https://htmx.drawlib.com/` | Practical tutorials, HDA design patterns, migration workflows, and feature guides. |
| **Portal 2: API Reference Catalog** | [https://htmx.drawlib.com/api/](https://htmx.drawlib.com/api/) | Exhaustive specification of every `hx-*` attribute, JS API method, event, header, config option, and extension. |
| **Portal 3: Internal Architecture Guide** | [https://htmx.drawlib.com/architecture/](https://htmx.drawlib.com/architecture/) | Deep dive into `src/htmx.js` internals: HCON parser, morph algorithm, task queue, and extension runtime. |
| **Portal 4: PNI501 Diagnostic Report** | [https://htmx.drawlib.com/reports/pni501/](https://htmx.drawlib.com/reports/pni501/) | Codebase quality metrics, test suite coverage analysis, bundle size breakdown, and security audit findings. |
