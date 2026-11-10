# Data, Validation & Configuration Attributes

htmx v4 provides declarative attributes for assembling request parameters, injecting custom HTTP headers, enforcing HTML5 constraint validation, tuning `fetch()` request options, and routing responses based on HTTP status codes. Unlike htmx 2, htmx v4 parses configuration values through **HCON** (htmx Configuration Object Notation, a superset of JSON), evaluates `js:` expressions both synchronously and asynchronously, and routes `4xx`/`5xx` responses declaratively via `hx-status:XXX`.

| Attribute | Category | Value Format | Default / Inheritance | Core Behavior |
| :--- | :--- | :--- | :--- | :--- |
| [`hx-vals`](#hx-vals) | Request Data | HCON / JSON / `js:<expr>` | Explicit (`:inherited` / `:append`) | Merges static or dynamic key-value pairs into the request `FormData` and exposes them on `ctx.vals`. |
| [`hx-headers`](#hx-headers) | Request Headers | HCON / JSON / `js:<expr>` | Explicit (`:inherited` / `:append`) | Appends or overrides HTTP request headers on `ctx.request.headers` (all values coerced with `String(...)`). |
| [`hx-include`](#hx-include) | Request Data | CSS / Extended Selector | Explicit (`:inherited` / `:append`) | Collects input values from additional DOM elements or enclosing `<form>` containers into the request payload. |
| [`hx-encoding`](#hx-encoding) | Request Encoding | MIME Type String | `application/x-www-form-urlencoded` | Preserves raw `FormData` when set to `multipart/form-data` for binary file uploads on non-`GET`/`DELETE` requests. |
| [`hx-validate`](#hx-validate) | Form Validation | `"true"` \| `"false"` | `"true"` on `<form>` (unless `novalidate`), `"false"` otherwise; not inherited | Runs `reportValidity()` on the enclosing form, triggering element, and `hx-include` targets before `htmx:config:request`. |
| [`hx-config`](#hx-config) | Fetch Configuration | HCON / JSON | Explicit (`:inherited` / `:append`) | Merges per-element `HtmxRequestOptions` (`timeout`, `credentials`, `cache`, extension keys) into `ctx.request` while locking `mode`. |
| [`hx-status:XXX`](#hx-status-xxx) | Response Routing | HCON / JSON | Explicit (`:inherited` / `:append`) | Overrides `ctx` swap/target/select/history properties for matching HTTP status codes (`422`, `50x`, `4xx`, `5xx`). |

```drawlib align=center code=fold file=cat_04_data_config_pipeline.png caption="htmx v4 Request Data Assembly, Fetch Configuration, and HTTP Status Routing Pipeline"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line, lines
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=160, height=70, dpi=150)

# Outer container frame
rectangle((80, 35), width=152, height=62, style=Styles.MutedDashed.patch(shape_r=2.5))
text(
    (80, 62.0),
    "htmx v4 Data Assembly, Fetch Config & Status Routing Pipeline",
    style=Styles.DarkBold.patch(text_size=12.5),
)

# Top Row: 4 Outbound Stages (y = 43)
y_top = 43.0
card_w = 32.0
card_h = 20.0
x_1, x_2, x_3, x_4 = 24.0, 61.0, 98.0, 135.0

# Stage 1: Form & Validation
rectangle((x_1, y_top), width=card_w, height=card_h, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.check_square((x_1 - 12.0, y_top + 5.5), width=4.2, style=Styles.PrimaryBold)
text((x_1 + 2.0, y_top + 5.5), "1. Form & Validate", style=Styles.DarkBold.patch(text_size=10.5))
text(
    (x_1, y_top - 3.5),
    "hx-include selectors\nhx-validate reportValidity()",
    style=Styles.Dark.patch(text_size=10.0),
)

line((x_1 + 16.0, y_top), (x_2 - 16.0, y_top), arrow_head="->", style=Styles.PrimaryBold)

# Stage 2: Dynamic Values & Headers
rectangle((x_2, y_top), width=card_w, height=card_h, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
phosphor.sliders((x_2 - 12.0, y_top + 5.5), width=4.2, style=Styles.PrimaryBold)
text((x_2 + 2.0, y_top + 5.5), "2. Vals & Headers", style=Styles.PrimaryBold.patch(text_size=10.5))
text(
    (x_2, y_top - 3.5),
    "hx-vals -> FormData, ctx.vals\nhx-headers -> String(val)",
    style=Styles.Dark.patch(text_size=10.0),
)

line((x_2 + 16.0, y_top), (x_3 - 16.0, y_top), arrow_head="->", style=Styles.PrimaryBold)

# Stage 3: Fetch Configuration
rectangle((x_3, y_top), width=card_w, height=card_h, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
phosphor.gear((x_3 - 12.0, y_top + 5.5), width=4.2, style=Styles.SecondaryBold)
text((x_3 + 2.0, y_top + 5.5), "3. Fetch Options", style=Styles.SecondaryBold.patch(text_size=10.5))
text(
    (x_3, y_top - 3.5),
    "hx-config -> ctx.request\nmode locked to config.mode",
    style=Styles.Dark.patch(text_size=10.0),
)

line((x_3 + 16.0, y_top), (x_4 - 16.0, y_top), arrow_head="->", style=Styles.PrimaryBold)

# Stage 4: Encoding & Dispatch (Focal Point 1)
rectangle((x_4, y_top), width=card_w, height=card_h, style=Styles.PrimaryFlat.patch(shape_r=2.0))
phosphor.paper_plane_tilt((x_4 - 12.0, y_top + 5.5), width=4.2, style=Styles.WhiteBold)
text((x_4 + 2.0, y_top + 5.5), "4. Encode & Fetch", style=Styles.WhiteBold.patch(text_size=10.5))
text(
    (x_4, y_top - 3.5),
    "GET/DELETE: URL query\nPOST: URLParams / FormData",
    style=Styles.White.patch(text_size=10.0),
)

# Bottom Row: Response & Status Routing (y = 16)
y_bot = 16.0

# Stage 5: HTTP Response Arrival
rectangle((42.5, y_bot), width=69.0, height=18.0, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.arrows_split((14.0, y_bot + 4.5), width=4.2, style=Styles.PrimaryBold)
text((45.0, y_bot + 4.5), "5. HTTP Response & noSwap Check", style=Styles.DarkBold.patch(text_size=10.5))
text(
    (42.5, y_bot - 3.5),
    "4xx/5xx fire htmx:response:error (still swap by default)\nconfig.noSwap [204, 304] sets ctx.swap = 'none'",
    style=Styles.Dark.patch(text_size=10.0),
)

# Stage 6: Status Code Routing (Focal Point 2)
rectangle((118.0, y_bot), width=66.0, height=18.0, style=Styles.AccentFlat.patch(shape_r=2.0))
phosphor.git_branch((91.0, y_bot + 4.5), width=4.2, style=Styles.WhiteBold)
text((120.5, y_bot + 4.5), "6. hx-status:XXX Routing", style=Styles.WhiteBold.patch(text_size=10.5))
text(
    (118.0, y_bot - 3.5),
    "Order: Exact (422) -> Decade (50x) -> Class (5xx)\nMerges target, swap, select, push, replace into ctx",
    style=Styles.White.patch(text_size=10.0),
)

# Connectors between Top Row and Bottom Row
lines([(x_4, y_top - 10.0), (x_4, 29.0), (42.5, 29.0), (42.5, y_bot + 9.0)], arrow_head="->", style=Styles.PrimaryBold)
line((77.0, y_bot), (85.0, y_bot), arrow_head="->", style=Styles.PrimaryBold)

save()
```

---

## Request Payload & Parameter Attributes

### `hx-vals`

Adds static or dynamically computed key-value pairs to the outgoing request payload. In htmx v4, `hx-vals` is parsed with **HCON** (which accepts both concise `key:value` syntax and strict JSON) or evaluated as JavaScript when prefixed with `js:` or `javascript:`.

#### Syntax & Signature

```html
<!-- HCON shorthand syntax -->
<button hx-post="/items" hx-vals="category:books, priority:1, active:true">Create</button>

<!-- Standard JSON syntax -->
<button hx-post="/items" hx-vals='{"category": "books", "priority": 1}'>Create</button>

<!-- Dynamic synchronous or asynchronous JavaScript evaluation -->
<button hx-post="/items" hx-vals="js:{ token: await getAuthToken(), ts: Date.now() }">Create</button>
```

#### Value Formats & Execution Mechanics

| Format / Feature | Syntax Example | Internal Mechanics (`src/htmx.js`) |
| :--- | :--- | :--- |
| **HCON Object** | `hx-vals="page:2, sort:'desc'"` | Parsed synchronously via `HCON.parse(hxAttr)`. Numeric and boolean literals (`2`, `true`) are JSON-parsed automatically. |
| **JSON Object** | `hx-vals='{"page": 2, "sort": "desc"}'` | Any string starting with `{` is delegated directly to `JSON.parse(string)`. |
| **Dynamic Sync JS** | `hx-vals="js:{ width: window.innerWidth }"` | Strips `js:` / `javascript:`, wraps in `{...}` if needed, and executes via `AsyncFunction` with `this` bound to the element and `{ctx}` in scope. |
| **Dynamic Async JS** | `hx-vals="js:{ sig: await signPayload(ctx) }"` | Because `__executeJavaScript` uses `AsyncFunction` (`isAsync = true`), `await` expressions inside `js:` resolve before `htmx:config:request` fires. |
| **Form Override** | `body.set(key, obj[key])` | Iterates over the resolved object and calls `FormData.prototype.set()`, overriding any identically named form or `hx-include` field. |
| **Extension Hook** | `ctx.vals = obj` | Stores the raw unserialized object on `ctx.vals` so JSON or custom serialization extensions can inspect typed values. |
| **Inheritance** | `hx-vals:inherited` / `hx-vals:append` | Requires `:inherited` on ancestor elements. Child elements can merge additional keys with `hx-vals:append="extra:1"`. |

#### Practical Examples

```html
<!-- Static HCON values overriding a form input -->
<form hx-post="/orders">
  <input type="hidden" name="source" value="default">
  <!-- Sends source="quick-buy" and express="true" -->
  <button type="submit" hx-vals="source:'quick-buy', express:true">
    Instant Checkout
  </button>
</form>

<!-- Async Web Crypto signature computed just before htmx:config:request -->
<button hx-post="/transfer"
        hx-vals="js:{ nonce: crypto.randomUUID(), digest: await computeHmac(ctx.request.action) }">
  Authorize Transfer
</button>
```

---

### `hx-headers`

Adds or overrides custom HTTP headers on `ctx.request.headers` before the request is dispatched. Like `hx-vals`, it accepts HCON, JSON, or a `js:` / `javascript:` dynamic expression, and coerces every resolved property value via `String(obj[key])`.

#### Syntax & Signature

```html
<!-- Static HCON headers -->
<button hx-get="/api/widgets" hx-headers="X-Client-Version: 4.0.1, X-Tenant: acme">
  Load Widgets
</button>

<!-- Inherited CSRF header on body or layout root -->
<body hx-headers:inherited='{"X-CSRF-Token": "9f86d081884c7d659a2feaa0c55ad015"}'>
  <button hx-delete="/account/session">Sign Out</button>
</body>
```

#### Value Formats & Execution Mechanics

| Format / Feature | Syntax Example | Internal Mechanics (`src/htmx.js`) |
| :--- | :--- | :--- |
| **HCON / JSON** | `hx-headers="X-Mode:compact"` | Parsed via `__getAttributeObject(elt, "hx-headers", ...)` and assigned to `ctx.request.headers[key] = String(obj[key])`. |
| **Dynamic `js:` Prefix** | `hx-headers="js:{ Authorization: 'Bearer ' + await getJwt() }"` | Evaluates asynchronously with `this` bound to the source element and `ctx` in scope, awaiting any returned `Promise` before `htmx:config:request`. |
| **Core Header Precedence** | Overrides `Accept` or `HX-*` | Executed after `__createCoreHeaders()`, allowing `hx-headers` to override `Accept: text/html` or custom headers before `htmx:config:request`. |
| **Explicit Inheritance** | `hx-headers:inherited="..."` | Place `hx-headers:inherited` on `<body>` or `<main>` to propagate CSRF or tenant headers to all descendant htmx requests. Combine with `:append` on children to add route-specific headers. |

#### Practical Examples

```html
<!-- Global CSRF protection via explicit inheritance + child header append -->
<main hx-headers:inherited="X-CSRF-Token: 'tok_live_88a9c'">
  <button hx-post="/posts/publish"
          hx-headers:append="X-Idempotency-Key: 'pub_2026_01'">
    Publish Article
  </button>
</main>

<!-- Dynamic bearer token lookup per request -->
<div hx-get="/metrics/realtime"
     hx-trigger="every 10s"
     hx-headers="js:{ 'X-Trace-Id': crypto.randomUUID() }">
</div>
```

---

### `hx-include`

Includes additional input elements or form containers in the outgoing request data collection phase (`__collectFormData`). In htmx v4, **only non-`GET`/`DELETE` requests (`POST`, `PUT`, `PATCH`, `QUERY`) automatically include their enclosing `<form>`**; `GET` and `DELETE` requests outside a `<form>` element itself must use `hx-include` to pull in surrounding form controls.

#### Syntax & Signature

```html
<!-- Include an enclosing form on a GET request -->
<form id="filter-form">
  <input type="text" name="q" placeholder="Filter...">
  <select name="status" hx-get="/items" hx-include="closest form" hx-target="#list">
    <option value="open">Open</option>
    <option value="closed">Closed</option>
  </select>
</form>
```

#### Supported Selectors & Collection Rules

| Selector / Rule | Example | Behavior in `__collectFormData` & `__addInputValues` |
| :--- | :--- | :--- |
| **Standard CSS Selector** | `hx-include="#global-filters, .extra-input"` | Queries matching elements in the root node (`document` or `ShadowRoot`) and collects all enabled `[name]:not(button)` descendants. |
| **`closest <selector>`** | `hx-include="closest form"` | Traverses up the DOM via `elt.closest(...)` to include the nearest ancestor form or container. |
| **`find <selector>` / `findAll <selector>`** | `hx-include="find input.active"` | Queries first descendant (`find`) or all descendants (`findAll`) relative to the triggering element. |
| **`next [<selector>]` / `previous [<selector>]`** | `hx-include="previous input"` | Includes adjacent or DOM-ordered sibling inputs before or after the triggering element. |
| **`this`** | `hx-include="this"` | Includes input controls inside the element bearing the `hx-include` attribute (respects inherited `this` via `__findThisElements`). |
| **`GET` / `DELETE` Form Rule** | `usesQueryParams = /GET\|DELETE/.test(method)` | When `method` is `GET` or `DELETE`, htmx only auto-collects `form` if the triggering element **is** the `<form>` (`elt.matches('form')`). Child controls (`<button hx-get>`, `<input hx-get>`) only send their own value unless `hx-include="closest form"` is set. |
| **Deduplication (`included` Set)** | Automatic `Set` tracking | Each input element is tracked in an `included` `Set` so overlapping form and `hx-include` selectors never duplicate values. |

#### Practical Examples

```html
<!-- Bulk DELETE button including checked row checkboxes from a separate table -->
<button hx-delete="/users/bulk"
        hx-include="#users-table input[name='ids']:checked"
        hx-confirm="Delete selected users?"
        hx-target="#users-table">
  Delete Selected
</button>

<table id="users-table">
  <tr><td><input type="checkbox" name="ids" value="101"></td><td>Alice</td></tr>
  <tr><td><input type="checkbox" name="ids" value="102"></td><td>Bob</td></tr>
</table>
```

---

### `hx-encoding`

Specifies the request body encoding format for non-`GET`/`DELETE` requests. By default, htmx converts the collected `FormData` object into `application/x-www-form-urlencoded` (`new URLSearchParams(ctx.request.body)`). Setting `hx-encoding="multipart/form-data"` (or `enctype="multipart/form-data"` on the enclosing `<form>`) preserves the raw `FormData` instance so the browser's `fetch()` API streams binary file uploads with an automatically generated multipart boundary.

#### Syntax & Signature

```html
<!-- On a form or standalone button uploading files -->
<form hx-post="/upload/avatar" hx-encoding="multipart/form-data" hx-target="#preview">
  <input type="file" name="avatar" accept="image/png,image/jpeg" required>
  <button type="submit">Upload Avatar</button>
</form>
```

#### Encoding Values & Behavior

| Value | Enclosing `<form enctype>` Fallback | Resulting `ctx.request.body` Passed to `fetch()` |
| :--- | :--- | :--- |
| *(omitted / default)* | Falls back to `form?.enctype` | Converted to `new URLSearchParams(ctx.request.body)` (`Content-Type: application/x-www-form-urlencoded;charset=UTF-8`). |
| `"multipart/form-data"` | Equivalent to `<form enctype="multipart/form-data">` | Retains the native `FormData` object (`Content-Type: multipart/form-data; boundary=...` set automatically by browser `fetch()`). |
| *(Ignored on `GET`/`DELETE`)* | N/A | `GET` and `DELETE` serialize `ctx.request.body` into `url.searchParams` and set `ctx.request.body = null`. |

#### Practical Examples

```html
<!-- Standalone file upload without a wrapping <form> using hx-encoding + hx-include -->
<div class="uploader">
  <input id="doc-file" type="file" name="documents" multiple>
  <button hx-post="/documents/import"
          hx-encoding="multipart/form-data"
          hx-include="#doc-file"
          hx-indicator="#upload-spinner">
    Import Files
  </button>
  <span id="upload-spinner" class="htmx-indicator">Uploading...</span>
</div>
```

---

## Validation, Fetch Options & Status Routing

### `hx-validate`

Controls whether htmx runs native HTML5 constraint validation (`reportValidity()`) on collected inputs before firing `htmx:config:request` and issuing the network request.

#### Syntax & Signature

```html
<!-- Force validation on a standalone input or button outside a form -->
<input type="email" name="email" required
       hx-post="/newsletter/subscribe"
       hx-validate="true"
       hx-target="#sub-status">
```

#### Validation Rules & Defaults

| Element Context | Default `hx-validate` Value | Validation Target & Behavior (`__collectFormData`) |
| :--- | :--- | :--- |
| `<form>` without `novalidate` | `"true"` (unless submitter has `formnovalidate`) | Calls `form.reportValidity()`. If `false`, aborts immediately before `hx-vals` or `htmx:config:request`. |
| `<form novalidate>` | `"false"` | Skips `form.reportValidity()` unless `hx-validate="true"` is explicitly set on the form. |
| Non-`<form>` element (`<input>`, `<button>`) | `"false"` | When `hx-validate="true"` is set directly on the element, calls `elt.reportValidity()` (if no enclosing form) and `node.reportValidity()` on every element matched by `hx-include`. |
| **Inheritance** | **Not inherited** (`allowInheritance = false`) | Looked up with `this.__attributeValue(sourceElement, "hx-validate", ..., false)` — must be placed directly on the triggering element. |

#### Practical Examples

```html
<!-- Validate both a standalone input and included fields without a <form> tag -->
<div id="profile-fields">
  <input type="text" name="username" minlength="3" required>
  <input type="url" name="website" placeholder="https://example.com">
</div>
<button hx-put="/profile"
        hx-include="#profile-fields"
        hx-validate="true">
  Save Profile
</button>
```

---

### `hx-config`

Provides per-element overrides for the underlying `fetch()` request options (`ctx.request`, typed as `HtmxRequestOptions`), replacing htmx 2's `hx-request` attribute. Accepts HCON or JSON and deep-merges into `ctx.request` during context creation (`__createRequestContext`).

#### Syntax & Signature

```html
<!-- Custom timeout, credentials, and cache mode via HCON -->
<button hx-get="https://api.example.com/feed"
        hx-config="timeout:5s, credentials:include, cache:'no-store'">
  Sync External Feed
</button>
```

#### Configurable `HtmxRequestOptions` Keys

| Key | Type / Values | Default | Description & Security Invariants |
| :--- | :--- | :--- | :--- |
| `timeout` | `number` \| `string` (`5000`, `"5s"`, `"1m"`, `0`) | `htmx.config.defaultTimeout` (`60000`) | Per-request timeout parsed via `htmx.parseInterval()`. Aborts `ctx.request.signal` with reason `'timeout'` and fires `htmx:error`. |
| `credentials` | `'same-origin'` \| `'include'` \| `'omit'` | `'same-origin'` | Controls whether `fetch()` sends cookies and HTTP auth headers on same-origin or cross-origin requests. |
| `cache` | `'default'` \| `'no-store'` \| `'reload'` \| `'no-cache'` \| `'force-cache'` | Browser default | Passed directly to `window.fetch(action, ctx.request)`. |
| `sse.*` / `ws.*` / `<ext>.*` | Dotted HCON path (`sse.mode:once`) | Extension-defined | HCON dotted keys expand into nested objects (`{sse: {mode: 'once'}}`) on `ctx.request` for extensions to read. |
| **`mode` (Locked)** | `'same-origin'` \| `'cors'` \| `'no-cors'` | `htmx.config.mode` (`'same-origin'`) | **Security Invariant**: Immediately after `HCON.merge(hxConfig, ctx.request)`, htmx enforces `ctx.request.mode = this.config.mode`. Per-element `mode` overrides are always ignored to prevent markup injection from escalating CORS privileges. |

#### Practical Examples

```html
<!-- Fast 3-second timeout with no-store cache for a health check button -->
<button hx-get="/healthz"
        hx-config="timeout:3s, cache:'no-store'"
        hx-target="#health-badge">
  Ping Server
</button>

<!-- Inherited request configuration for an admin panel section -->
<section hx-config:inherited='{"timeout": "15s", "credentials": "include"}'>
  <button hx-post="/admin/reindex">Trigger Search Reindex</button>
</section>
```

---

### `hx-status:XXX`

Declaratively reconfigures how htmx swaps, targets, selects, or updates browser history when the server responds with a specific HTTP status code or wildcard range. Unlike htmx 2 (which ignored `4xx`/`5xx` bodies by default), **htmx v4 swaps all status codes except `htmx.config.noSwap` (`[204, 304]`)** and applies `hx-status:XXX` overrides right before calling `htmx.swap(ctx)`.

#### Syntax & Signature

```html
<form hx-post="/users"
      hx-target="#user-list"
      hx-swap="beforeend"
      hx-status:422="target:#form-errors, swap:innerHTML, select:#error-summary"
      hx-status:50x="target:#toast-container, swap:beforeend"
      hx-status:5xx="swap:none">
  <input type="email" name="email" required>
  <div id="form-errors"></div>
  <button type="submit">Create User</button>
</form>
```

#### Pattern Matching Precedence & Supported Context Overrides

htmx evaluates status patterns in strict specificity order (`[str, str.slice(0, 2) + 'x', str[0] + 'xx']`), stopping at the **first matching pattern** in `htmx.config.noSwap` or `hx-status:<pattern>`:

| Precedence / HCON Key | Pattern / Value Type | Behavior in `__handleStatusCodes(ctx)` |
| :--- | :--- | :--- |
| **1. Exact Status (`NNN`)** | `hx-status:422`, `hx-status:404`, `hx-status:201` | Checked first against the exact 3-digit HTTP status code string (e.g. `"422"`). |
| **2. Decade Wildcard (`NNx`)** | `hx-status:50x`, `hx-status:40x` | Checked second if no exact match exists (matches `500`–`509` or `400`–`409`). |
| **3. Class Wildcard (`Nxx`)** | `hx-status:4xx`, `hx-status:5xx`, `hx-status:2xx` | Checked third as a broad fallback for any `400`–`499` or `500`–`599` status code. |
| `swap` | Swap spec string (`innerHTML`, `none`, `outerMorph`) | Overrides `ctx.swap` for the response (e.g., `swap:none` to suppress swapping on `5xx`). |
| `target` | CSS / Extended selector (`#errors`, `closest .card`) | Overrides `ctx.target` (resolved via `__resolveTarget` inside `__processMainSwap`). |
| `select` | CSS selector (`#error-list`) | Overrides `ctx.select` to extract a specific fragment from the error response HTML. |
| `selectOOB` | OOB selector spec (`#flash:outerHTML`) | Overrides `ctx.selectOOB` for out-of-band extractions on that status code. |
| `push` / `replace` | `true` \| `false` \| URL string (`'/login'`) | Overrides `ctx.push` (`hx-push-url`) or `ctx.replace` (`hx-replace-url`) during history resolution. |
| `transition` | `true` \| `false` | Enables or disables View Transitions for the status-specific swap. |

#### Practical Examples

```html
<!-- Global 401/403 & 5xx status policy inherited across an entire application layout -->
<body hx-status:401:inherited="target:#auth-modal, swap:innerHTML, push:false"
      hx-status:5xx:inherited="target:#global-alert, swap:innerHTML, push:false">

  <div id="auth-modal"></div>
  <div id="global-alert"></div>

  <!-- Local 422 validation error routing on a registration form -->
  <form hx-post="/register"
        hx-target="#main-view"
        hx-push-url="/welcome"
        hx-status:422="target:#field-errors, swap:innerMorph, push:false">
    <input type="text" name="handle" required>
    <div id="field-errors"></div>
    <button type="submit">Register</button>
  </form>
</body>
```
