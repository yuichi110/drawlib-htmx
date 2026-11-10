# 3. Requests & Triggers

htmx v4.0.1 gives you declarative control over **when** a request fires (`hx-trigger`), **what** parameters and headers it carries (`hx-include`, `hx-vals`, `hx-headers`, `hx-config` via HCON), and **how** concurrent in-flight requests are synchronized (`hx-sync`).

```drawlib align=center code=fold file=ch03_trigger_pipeline.png caption="htmx v4.0.1 Event Trigger Evaluation, Filter, and Debounce/Throttle Pipeline"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, ChevronProcess
from drawlib.styles import Styles

setup(width=176, height=76)

# Top: 6-Stage hx-trigger Evaluation Pipeline
pipeline = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=1.5,
    flat_left_end=True,
)
pipeline.add("1. Event Source", description="DOM / from: / Poll")
pipeline.add("2. Phase & Target", description="capture / target:")
pipeline.add("3. JS Filter", description="[ctrlKey] / [expr]", style=Styles.PrimaryNeutral)
pipeline.add("4. State Gate", description="changed / once", style=Styles.SecondaryNeutral)
pipeline.add(
    "5. Timing Control",
    description="delay: / throttle:",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.0),
    description_style=Styles.White.patch(text_size=9.5),
)
pipeline.add("6. Issue Fetch", description="hx-sync & FormData")
pipeline.draw(xy=(6.0, 54.0), width=164.0, height=15.0)

# Bottom: 3 Horizontal Trigger Archetype Cards
cards = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=10.0),
    icon_style=Styles.PrimaryBold,
    direction="horizontal",
    spacing=4.0,
)
cards.add(
    "User & Keyboard Events",
    "click[shiftKey], keyup changed delay:300ms\nhalt (prevent + stop), from:body",
    badge_text="DOM",
    icon=phosphor.cursor_click,
)
cards.add(
    "Viewport & Lifecycle",
    "load, revealed, intersect threshold:0.5\nIdeal for lazy loading & infinite scroll",
    badge_text="VIEW",
    icon=phosphor.eye,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
)
cards.add(
    "Interval Polling",
    "every 2s [document.hasFocus()]\nCombine with hx-ptag for 304 caching",
    badge_text="POLL",
    icon=phosphor.clock_clockwise,
)
cards.draw(xy=(6.0, 6.0), width=164.0, height=42.0, align="bottom_left")

save()
```

---

## 3.1 Deep Dive into `hx-trigger`

By default, `<form>` triggers on `submit`, `<input>`/`<textarea>`/`<select>` trigger on `change`, and all other elements trigger on `click`. Use `hx-trigger` to specify one or more comma-separated trigger specifications.

### Complete `hx-trigger` Modifier Reference

| Modifier | Syntax Example | Behavior in htmx v4.0.1 |
| :--- | :--- | :--- |
| **`once`** | `click once` | Fires at most once during the element's lifetime. |
| **`changed`** | `input changed` | Fires only if the element's `value` has changed since the last trigger. |
| **`delay:<time>`** | `input delay:400ms` | **Debounce**: waits `<time>` (`ms`, `s`, `m`) after the event; resets timer if another event arrives. |
| **`throttle:<time>`** | `scroll throttle:250ms` | **Throttle**: fires immediately on the first event, then ignores events until `<time>` elapses. |
| **`from:<selector>`** | `refreshTable from:body` | Listens on a different element (`document`, `window`, `body`, `closest <sel>`, `find <sel>`, `next`, `previous`). |
| **`target:<selector>`** | `click target:.row-btn` | Fires only if `event.target` matches the CSS selector (event delegation). |
| **`prevent`** | `click prevent` | Calls `event.preventDefault()` when the trigger matches. |
| **`stop` / `consume`** | `click stop` | Calls `event.stopPropagation()` so parent handlers do not fire (`consume` is a synonym). |
| **`halt`** | `click halt` | Shorthand for `prevent stop` (`preventDefault()` + `stopPropagation()`). |
| **`capture`** | `focus capture` | Registers the listener in the DOM **capture phase** instead of the bubble phase. |
| **`passive`** | `touchstart passive` | Registers `{ passive: true }` with the browser for smooth scrolling performance. |

> [!TIP]
> When a `from:` or `target:` selector contains spaces or commas, wrap the selector in quotes or angle brackets: `from:'form input'`, `from:"form input"`, or `from:<form input/>`.

### Bracketed JavaScript Filters, Viewport Events, and Polling

Attach a boolean JavaScript expression in square brackets `[...]` directly after the event name or polling interval to gate execution:

```html
<!-- 1. Active search: debounced input OR immediate Enter key -->
<input type="search" name="q"
       hx-get="/search"
       hx-trigger="input changed delay:350ms, keyup[key=='Enter'] halt"
       hx-target="#search-results">

<!-- 2. Viewport intersection: lazy-load chart when 50% visible -->
<div hx-get="/charts/q4-revenue"
     hx-trigger="intersect once threshold:0.5"
     hx-swap="outerHTML">
  Loading chart...
</div>

<!-- 3. Conditional polling: poll every 5s only while browser tab is visible -->
<div hx-get="/jobs/status"
     hx-trigger="every 5s [!document.hidden]"
     hx-swap="innerMorph">
  Checking job status...
</div>
```

---

## 3.2 Form Data Semantics (`GET`/`DELETE` vs. `POST`/`PUT`/`PATCH`/`QUERY`)

One of the most important cleanups in htmx v4.0.1 is consistent HTTP form data inclusion:

- **Non-GET/DELETE (`hx-post`, `hx-put`, `hx-patch`, `hx-query`)**: Automatically collect and serialize all inputs from the **enclosing `<form>`** (plus the triggering element itself if it has a `name`).
- **`hx-get` and `hx-delete`**: Do **NOT** automatically include the enclosing `<form>`'s inputs! Only the triggering element's own value (if it is an input) and explicit `hx-include` / `hx-vals` parameters are sent.

```html
<form id="bulk-actions">
  <input type="hidden" name="workspace_id" value="ws-42">
  <input type="checkbox" name="ids" value="101" checked>
  <input type="checkbox" name="ids" value="102" checked>

  <!-- POST automatically includes workspace_id and checked ids -->
  <button type="button" hx-post="/items/archive">Archive Selected</button>

  <!-- DELETE in htmx 4 requires explicit hx-include="closest form" to include form inputs -->
  <button type="button" hx-delete="/items/delete" hx-include="closest form">
    Delete Selected
  </button>
</form>
```

---

## 3.3 `hx-vals`, `hx-headers`, `hx-config`, and HCON Notation

htmx v4.0.1 introduces **HCON (htmx Configuration Object Notation)**—a relaxed superset of JSON used across `<meta name="htmx-config">`, `hx-vals`, `hx-headers`, and `hx-config`. With HCON, outer braces `{}` and quotes around simple keys/strings are optional:

```html
<!-- HCON shorthand (no outer braces or quotes required for simple tokens) -->
<button hx-post="/items/sort"
        hx-vals="column:created_at, direction:desc, limit:25"
        hx-headers="X-Client-View:compact-grid"
        hx-config="timeout:10000, credentials:include">
  Sort Newest
</button>

<!-- Dynamic JavaScript values using the js: prefix -->
<button hx-post="/telemetry/click"
        hx-vals="js:{
          viewportW: window.innerWidth,
          viewportH: window.innerHeight,
          timestamp: Date.now()
        }">
  Record Viewport
</button>
```

| Attribute | Accepts HCON / JSON? | Supports `:inherited` & `:append`? | Description |
| :--- | :--- | :--- | :--- |
| **`hx-vals`** | Yes (plus `js:` prefix) | Yes | Appends static or dynamically computed key-value pairs to the request parameters. |
| **`hx-headers`** | Yes | Yes | Attaches custom HTTP request headers to the outgoing `fetch()` call. |
| **`hx-config`** | Yes | Yes | Per-element Fetch options (`timeout`, `credentials`, `cache`). Cannot override `htmx.config.mode`. |
| **`hx-include`** | Extended CSS Selector | Yes | Includes input values from additional elements (e.g. `closest form`, `#filter-bar`). |
| **`hx-encoding`** | `"multipart/form-data"` | Yes | Switches request encoding for `<input type="file">` uploads. |
| **`hx-validate`** | `"true"` / `"false"` | Yes | Enforces HTML5 `checkValidity()` on inputs before issuing non-form requests. |

---

## 3.4 Request Coordination with `hx-sync`

When multiple elements (such as an `<input>` validating an email address and its parent `<form>` submitting registration) can trigger overlapping requests, `hx-sync` coordinates their in-flight execution using a target selector and a strategy:

```drawlib align=center code=fold file=ch03_sync_and_formdata.png caption="Form Data Inclusion Rules and hx-sync Request Coordination Strategies"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel
from drawlib.styles import Styles

setup(width=172, height=74)

# Left Panel: Form Data Inclusion by HTTP Method
left_panel = Panel(
    "Form Data Inclusion Rules (v4)",
    "Enclosing <form> Behavior",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.textbox,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=9.0,
)
left_panel.draw((6.0, 6.0), width=76.0, height=62.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box((6.0, 6.0), width=76.0, height=62.0, padding=(3.5, 3.5))

form_cards = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    spacing=2.5,
)
form_cards.add(
    "POST / PUT / PATCH / QUERY",
    "Automatically serializes enclosing <form> inputs",
    badge_text="AUTO",
)
form_cards.add(
    "GET / DELETE (v4 Change)",
    "Excludes enclosing <form> by default for safety",
    badge_text="EXCL",
    badge_style=Styles.AccentFlat,
)
form_cards.add(
    "Explicit hx-include",
    'Add hx-include="closest form" when GET/DELETE needs form',
    badge_text="INCL",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=9.5),
)
form_cards.draw(l_xy, width=l_w, height=l_h)

# Right Panel: hx-sync Coordination Strategies
right_panel = Panel(
    "hx-sync Concurrency Strategies",
    "Synchronize In-Flight Requests",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.arrows_left_right,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=9.0,
)
right_panel.draw((90.0, 6.0), width=76.0, height=62.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box((90.0, 6.0), width=76.0, height=62.0, padding=(3.5, 3.5))

sync_cards = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=9.5),
    spacing=2.0,
)
sync_cards.add("drop", "Ignore new request if synced element is busy", badge_text="DROP")
sync_cards.add(
    "abort / replace",
    "abort: cancel if target fires | replace: abort old & send new",
    badge_text="ABRT",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
)
sync_cards.add("queue first / last / all", "Buffer subsequent requests until active fetch finishes", badge_text="QUEUE")
sync_cards.draw(r_xy, width=r_w, height=r_h)

save()
```

### `hx-sync` Strategy Reference

| Strategy | Syntax Example | Behavior |
| :--- | :--- | :--- |
| **`drop`** | `hx-sync="this:drop"` | Drops any new trigger while an existing request on the synced element is still in flight. |
| **`replace`** | `hx-sync="this:replace"` | Aborts the currently in-flight request (`AbortController.abort()`) and immediately issues the new one. |
| **`abort`** | `hx-sync="closest form:abort"` | Aborts this element's in-flight request if the target (`closest form`) starts a request. |
| **`queue first`** | `hx-sync="this:queue first"` | Queues the first triggered request that occurs while busy; drops subsequent ones. |
| **`queue last`** *(default)* | `hx-sync="this:queue last"` | Queues only the most recent triggered request to run after the current request finishes. |
| **`queue all`** | `hx-sync="this:queue all"` | Queues and executes every triggered request sequentially in FIFO order. |

```html
<!-- Submitting the form immediately aborts any in-flight username availability check -->
<form hx-post="/register">
  <input name="username"
         hx-post="/check-username"
         hx-trigger="input changed delay:400ms"
         hx-target="next .status"
         hx-sync="closest form:abort">
  <span class="status"></span>
  <button type="submit">Create Account</button>
</form>
```
