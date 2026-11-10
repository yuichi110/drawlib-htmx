# htmx v4.0.1 API Surface Overview

htmx `v4.0.1` (`htmx.org@4.0.1`) is a zero-dependency, `fetch()`-powered hypermedia library that extends standard HTML with declarative request attributes, built-in DOM morphing, explicit attribute inheritance, colon-separated lifecycle events, and a modular event-driven extension architecture.

This **API Reference Catalog** provides an exhaustive, source-grounded specification of every HTML attribute, modifier, HCON expression syntax, HTTP request/response header, JavaScript API method, TypeScript type definition (`src/htmx.d.ts`), configuration property, DOM/extension event hook, official extension (`src/ext/*.js`), and CLI migration tool shipped in htmx `v4.0.1`.

| Category | Catalog Page | Primary Symbols & Scope |
| :--- | :--- | :--- |
| **Overview & HCON** | [`00_overview.md`](00_overview.md) | `dist/htmx.js`, `dist/htmx.esm.js`, `dist/htmx.min.js`, `dist/htmax.js`, `dist/htmx.d.ts`, `HCON.parse`, `HCON.split`, `HCON.merge`, `hx-*`, `data-hx-*` |
| **Core Request Attributes** | [`01_core_request_attributes.md`](01_core_request_attributes.md) | `hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, `hx-query`, `hx-action`, `hx-method` |
| **Trigger & Sync Attributes** | [`02_trigger_and_sync_attributes.md`](02_trigger_and_sync_attributes.md) | `hx-trigger` (modifiers, `[filter]`, `every`, `load`, `revealed`, `intersect`), `hx-sync`, `hx-confirm` |
| **Target & Swap Attributes** | [`03_target_and_swap_attributes.md`](03_target_and_swap_attributes.md) | `hx-target`, `hx-swap` (12 styles + 12 modifiers), `hx-swap-oob`, `<hx-partial>`, `hx-select`, `hx-select-oob`, `hx-morph-skip`, `hx-morph-skip-children`, `hx-preserve` |
| **Data & Config Attributes** | [`04_data_and_config_attributes.md`](04_data_and_config_attributes.md) | `hx-vals`, `hx-headers`, `hx-include`, `hx-encoding`, `hx-validate`, `hx-config`, `hx-status:XXX` |
| **UX, History & Control** | [`05_ux_history_and_control_attributes.md`](05_ux_history_and_control_attributes.md) | `hx-boost`, `hx-push-url`, `hx-replace-url`, `hx-history-elt`, `hx-indicator`, `hx-disable`, `hx-ignore`, `hx-on:*`, `:inherited`, `:append` |
| **HTTP Headers** | [`06_http_headers.md`](06_http_headers.md) | Request (`HX-Request`, `HX-Source`, `HX-Target`, `HX-Current-URL`, `HX-Request-Type`, `HX-Boosted`, `HX-History-Restore-Request`) & Response (`HX-Trigger`, `HX-Push-Url`, `HX-Replace-Url`, `HX-Redirect`, `HX-Location`, `HX-Refresh`, `HX-Retarget`, `HX-Reswap`, `HX-Reselect`) |
| **JavaScript API** | [`07_javascript_api.md`](07_javascript_api.md) | `htmx.ajax()`, `htmx.process()`, `htmx.initialize()`, `htmx.swap()`, `htmx.on()`, `htmx.onLoad()`, `htmx.trigger()`, `htmx.find()`, `htmx.findAll()`, `htmx.timeout()`, `htmx.parseInterval()`, `htmx.registerExtension()`, `htmx.version`, TypeScript interfaces |
| **Configuration Options** | [`08_configuration_options.md`](08_configuration_options.md) | `<meta name="htmx-config">`, `htmx.config` (`HtmxConfig`: 23 properties), CSS State Classes (`htmx-request`, `htmx-indicator`, `htmx-swapping`, `htmx-settling`, `htmx-added`) |
| **Events Reference** | [`09_events_reference.md`](09_events_reference.md) | 28 `HtmxEventMap` DOM events (`htmx:phase:action`) & 5 extension-only hooks (`htmx_before_morph_node`, `htmx_before_morph_attr`, `htmx_after_implicitInheritance`, `htmx_process_<type>`, `handle_swap`) |
| **Streaming & Net Extensions** | [`10_extensions_streaming_and_net.md`](10_extensions_streaming_and_net.md) | `hx-sse` (`sse`), `hx-ws` (`ws`), `hx-multipart` (`hx-multipart`), `hx-preload` (`preload`), `hx-ptag` (`ptag`), `hx-download` (`download`) |
| **Reactive & DOM Extensions** | [`11_extensions_reactive_and_dom.md`](11_extensions_reactive_and_dom.md) | `hx-live` & `htmx.live` (`q`/`$`, `HxLive.*`, `take`, `toggle`, `debounce`, `refresh`, `forEvent`, `nextFrame`), `hx-targets`, `hx-upsert`, `hx-head`, `hx-pending`, `hx-browser-indicator` |
| **Security, Compat & CLI** | [`12_extensions_security_compat_and_cli.md`](12_extensions_security_compat_and_cli.md) | `hx-csp`, `hx-history-cache`, `hx-prompt`, `hx-alpine-compat`, `htmx-2-compat`, `internalAPI` (15 methods), CLI `upgrade-check` |

```drawlib align=center code=fold file=cat_00_api_surface_overview.png caption="htmx v4.0.1 API Surface Taxonomy & Runtime Architecture"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=180, height=96, dpi=150)

# Outer frame
rectangle((90, 48), width=174, height=90, style=Styles.MutedDashed.patch(shape_r=3.0))
text((90, 88.5), "htmx v4.0.1 Complete API Surface (src/htmx.js + src/htmx.d.ts + src/ext/*.js)", style=Styles.DarkBold.patch(text_size=13.0))

# Top Row: Declarative HTML Attributes & HCON Parser
rectangle((34, 67), width=56, height=26, style=Styles.PrimaryFlat.patch(shape_r=2.0))
phosphor.code((11, 74.5), width=4.8, style=Styles.WhiteBold)
text((36, 74.5), "1. Declarative HTML Attributes", style=Styles.WhiteBold.patch(text_size=11.0))
text((34, 62.5), "• Verbs: hx-get/post/put/patch/delete\n• Control: hx-trigger, hx-sync, hx-target\n• Swap: hx-swap (12 styles + modifiers)\n• Inheritance: :inherited & :append", style=Styles.White.patch(text_size=10.0))

rectangle((100, 67), width=44, height=26, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
phosphor.brackets_curly((83, 74.5), width=4.8, style=Styles.PrimaryBold)
text((102, 74.5), "2. HCON & Config", style=Styles.PrimaryBold.patch(text_size=11.0))
text((100, 62.5), "• HCON.parse / split / merge\n• <meta name='htmx-config'>\n• htmx.config (23 options)\n• hx-* & data-hx-* prefixes", style=Styles.Dark.patch(text_size=10.0))

rectangle((151, 67), width=44, height=26, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.arrows_left_right((134, 74.5), width=4.8, style=Styles.DarkBold)
text((153, 74.5), "3. HTTP Headers", style=Styles.DarkBold.patch(text_size=11.0))
text((151, 62.5), "• 7 Request (HX-Source,\n  HX-Target, HX-Request-Type)\n• 9 Response (HX-Trigger,\n  HX-Retarget, HX-Location)", style=Styles.Dark.patch(text_size=10.0))

# Arrows down to Bottom Row
line((34, 54), (34, 43), arrow_head="->", style=Styles.PrimaryBold)
line((100, 54), (100, 43), arrow_head="->", style=Styles.PrimaryBold)
line((151, 54), (151, 43), arrow_head="->", style=Styles.PrimaryBold)

# Bottom Row: JS API, Events, Extensions & CLI
rectangle((34, 26), width=56, height=32, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
phosphor.terminal_window((11, 36.5), width=4.8, style=Styles.SecondaryBold)
text((36, 36.5), "4. JavaScript API & Types", style=Styles.SecondaryBold.patch(text_size=11.0))
text((34, 22.0), "• htmx.ajax(), process(), swap()\n• on(), onLoad(), trigger(), find/All()\n• timeout(), parseInterval()\n• registerExtension(), version\n• HtmxRequestCtx / Options", style=Styles.Dark.patch(text_size=10.0))

rectangle((100, 26), width=44, height=32, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.lightning((83, 36.5), width=4.8, style=Styles.PrimaryBold)
text((102, 36.5), "5. Lifecycle Events", style=Styles.PrimaryBold.patch(text_size=11.0))
text((100, 22.0), "• 28 HtmxEventMap events\n• htmx:phase:action format\n• Element / Request / Swap\n• History & ViewTransition\n• 5 Extension-only hooks", style=Styles.Dark.patch(text_size=10.0))

rectangle((151, 26), width=44, height=32, style=Styles.AccentFlat.patch(shape_r=2.0))
phosphor.puzzle_piece((134, 36.5), width=4.8, style=Styles.WhiteBold)
text((153, 36.5), "6. 17 Ext + CLI", style=Styles.WhiteBold.patch(text_size=11.0))
text((151, 22.0), "• sse, ws, hx-multipart\n• hx-live (htmx.live.q/$)\n• hx-csp, history-cache\n• internalAPI (15 methods)\n• npx upgrade-check CLI", style=Styles.White.patch(text_size=10.0))

save()
```

---

## Package Exports & Distribution Bundles

The `htmx.org@4.0.1` npm package compiles [`src/htmx.js`](https://github.com/bigskysoftware/htmx) and [`src/ext/*.js`](https://github.com/bigskysoftware/htmx) into five primary distribution artifacts in `dist/`. During build (`npm run build:iife` / `npm run build:esm`), internal methods prefixed with `__` in `src/htmx.js` are lowered to native ECMAScript `#` private class fields.

| Artifact | Package Field | Format | Description |
| :--- | :--- | :--- | :--- |
| [`dist/htmx.js`](#dist-htmx-js) | `"main"` | IIFE (`var htmx`) | Unminified global browser script defining `window.htmx` with `#` private fields. |
| [`dist/htmx.esm.js`](#dist-htmx-esm-js) | `"module"` | ES Module (`export default htmx`) | ES module build for bundlers (Vite, Rollup, Webpack) and native `<script type="module">`. |
| [`dist/htmx.min.js`](#dist-htmx-min-js) | `"jsdelivr"`, `"unpkg"` | Minified IIFE + `.map` + `.br` | Terser-minified production bundle (`dist/htmx.esm.min.js` also provided for ESM). |
| [`dist/htmax.js`](#dist-htmax-js) | Standalone Bundle | IIFE (`4.0.1-htmax`) | All-in-one bundle combining `htmx.js` with 11 popular extensions (`dist/htmax.min.js` minified). |
| [`dist/htmx.d.ts`](#dist-htmx-d-ts) | `"types"` | TypeScript Declarations | Complete TypeScript ambient & module declarations (`Htmx`, `HtmxConfig`, `HtmxEventMap`, `HxLive`). |

### `dist/htmx.js`

Unminified IIFE bundle that instantiates the `Htmx` singleton (`var htmx = (() => { ... return new Htmx() })()`). In the build step (`npm run build:iife`), `sed` replaces internal `__` identifiers (except `__proto__`) with `#` private class members so internal state (`#internalAPI`, `#Function`, `#AsyncFunction`, `#ttPolicy`, `#transitionQueue`) is encapsulated at the JavaScript engine level.

```html
<!-- Load unminified IIFE build during local development -->
<script src="/dist/htmx.js"></script>
```

### `dist/htmx.esm.js`

Standard ECMAScript module distribution (`npm run build:esm`). Appends `if (typeof window !== "undefined") window.htmx = htmx; export default htmx;` to the core bundle so both named bundler imports and inline `hx-on:*` handlers have access to `htmx`.

```javascript
import htmx from 'htmx.org';

htmx.config.transitions = true;
htmx.ajax('GET', '/api/dashboard', '#main-panel');
```

### `dist/htmx.min.js`

Production-ready minified IIFE bundle (`npm run build:minify`) compressed with Terser (`--compress --mangle --source-map`) and pre-compressed with Brotli (`dist/htmx.min.js.br`). Served by default by CDNs via the `"jsdelivr"` and `"unpkg"` fields in `package.json`.

```html
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.1/dist/htmx.min.js"></script>
```

### `dist/htmax.js`

Batteries-included distribution (`npm run build:htmax`, plus minified `dist/htmax.min.js`) that concatenates core `dist/htmx.js` with 11 official extensions, appends `"-htmax"` to `htmx.version` (`"4.0.1-htmax"`), and sets `htmx.config.historyCache ??= { disable: true }` so `sessionStorage` history caching remains opt-in.

| Bundled Extension File | Registration Name | Purpose in `htmax.js` |
| :--- | :--- | :--- |
| `dist/ext/hx-sse.js` | `sse` | Server-Sent Events (`text/event-stream`) streaming |
| `dist/ext/hx-ws.js` | `ws` | Bidirectional WebSocket streaming and form sending |
| `dist/ext/hx-preload.js` | `preload` | Prefetch `GET` links and buttons on hover/mousedown/touchstart |
| `dist/ext/hx-browser-indicator.js` | `browser-indicator` | Native browser tab loading spinner via Navigation API |
| `dist/ext/hx-download.js` | `download` | Streaming file downloads (`hx-swap="download"`, `HX-Download`) |
| `dist/ext/hx-pending.js` | `hx-pending` | Optimistic/pending template placeholders during in-flight requests |
| `dist/ext/hx-targets.js` | `hx-targets` | Multi-element swap fan-out (`hx-targets=".card"`) |
| `dist/ext/hx-live.js` | `hx-live` | Reactive DOM expressions (`hx-live`, `:attr`, `htmx.live.q`) |
| `dist/ext/hx-history-cache.js` | `history-cache` | `sessionStorage` LRU history cache (disabled by default in `htmax.js`; enable via `historyCache.disable:false`) |
| `dist/ext/hx-upsert.js` | `upsert` | Sorted/keyed insert-or-update swap strategy (`hx-swap="upsert"`) |
| `dist/ext/hx-alpine-compat.js` | `alpine-compat` | Seamless Alpine.js state preservation across morphs and swaps |

```html
<!-- Load htmx core + 11 extensions in a single request -->
<script src="/dist/htmax.min.js"></script>
<meta name="htmx-config" content="historyCache.disable:false">
```

### `dist/htmx.d.ts`

Official TypeScript declaration file (`src/htmx.d.ts` copied to `dist/htmx.d.ts`). Exports the `Htmx` interface, `HtmxConfig`, `HtmxRequestCtx`, `HtmxRequestOptions`, `HtmxResponse`, `HtmxSwapContext`, `HtmxAjaxOptions`, `HtmxHistoryDetail`, `HtmxEventMap`, `HtmxEvent<K>`, and the `HxLive` namespace, and augments global `HTMLElementEventMap`, `DocumentEventMap`, and `WindowEventMap` for strongly-typed `addEventListener()` and `htmx.on()` calls.

```typescript
import htmx, { type HtmxEvent, type HtmxRequestCtx } from 'htmx.org';

htmx.on('htmx:config:request', (evt: HtmxEvent<'htmx:config:request'>) => {
  const ctx: HtmxRequestCtx = evt.detail.ctx;
  ctx.request.headers['X-Client-Version'] = htmx.version;
});
```

---

## HCON (htmx Configuration Object Notation)

HCON is htmx v4's concise configuration language used across `<meta name="htmx-config">`, `hx-config`, `hx-vals`, `hx-headers`, `hx-status:XXX`, `hx-swap`, `hx-trigger`, `HX-Location`, and `HX-Trigger`. Any string starting with `{` is parsed directly via `JSON.parse()`, making HCON a strict superset of JSON Objects while eliminating brace and quote noise in HTML attributes.

| Method / Feature | Signature | Description |
| :--- | :--- | :--- |
| [`HCON.parse`](#hcon-parse) | `HCON.parse(string: string): Record<string, any>` | Parses an HCON or JSON string into a nested JavaScript object. |
| [`HCON.split`](#hcon-split) | `HCON.split(string: string): string[]` | Splits a string at top-level commas while preserving commas inside `[]`, `()`, `<.../>`, `"..."`, and `'...'`. |
| [`HCON.merge`](#hcon-merge) | `HCON.merge(source: string \| object, target: object): object` | Deep-merges an HCON string or object into `target` with prototype-pollution protection. |

### `HCON.parse`

```javascript
HCON.parse(string: string): Record<string, any>
```

Parses an HCON string or JSON object literal into a plain JavaScript object. Exposed to extensions via `internalAPI.HCON.parse` (and on `htmx` internally as `#HCON.parse`).

| Grammar Rule | Syntax Form | Parsed Output Example | Notes |
| :--- | :--- | :--- | :--- |
| **Empty / Falsy** | `""` or `null` / `undefined` | `{}` | Returns a fresh empty object. |
| **JSON Passthrough** | `'{"defaultSwap": "outerHTML"}'` | `{ defaultSwap: "outerHTML" }` | Any string starting with `{` delegates to `JSON.parse(string)`. |
| **Space or Comma Delimiters** | `'swap:100ms, settle:200ms'` or `'swap:100ms settle:200ms'` | `{ swap: "100ms", settle: "200ms" }` | Pairs may be separated by whitespace, commas, or both. |
| **Implicit Boolean `true`** | `'once changed prevent'` | `{ once: true, changed: true, prevent: true }` | A bare key without `:value` defaults its value to `true`. |
| **JSON Value Coercion** | `'count:5 active:true ratio:0.5'` | `{ count: 5, active: true, ratio: 0.5 }` | Values are passed through `JSON.parse()` when valid, falling back to trimmed strings. |
| **Dotted Path Expansion** | `'sse.reconnectDelay:1000'` | `{ sse: { reconnectDelay: 1000 } }` | Bare keys containing `.` expand into nested objects and deep-merge via `HCON.merge()`. |
| **Quoted Keys** | `'"a.b":1'` or `'\"X-CSRF-Token\":\"abc\"'` | `{ "a.b": 1 }` | Double- or single-quoted keys preserve literal dots, spaces, and colons. |
| **Quoted & `<.../>` Values** | `'from:<form input, select/>'` | `{ from: "form input, select" }` | Values with spaces or commas can be wrapped in `"..."`, `'...'`, or hyperscript-style `<.../>`. |

```html
<!-- Equivalent HCON and JSON declarations in <meta name="htmx-config"> -->
<meta name="htmx-config" content="defaultSwap:outerMorph, transitions:true, live.inputDebounce:150">
<meta name="htmx-config" content='{"defaultSwap":"outerMorph","transitions":true,"live":{"inputDebounce":150}}'>
```

### `HCON.split`

```javascript
HCON.split(string: string): string[]
```

Splits a comma-separated specification string (such as multiple triggers in `hx-trigger` or multiple selectors in `hx-target` / `hx-include`) at top-level commas only, using the lookahead regex `/,(?![^\[]*\])(?![^(]*\))(?![^<]*\/>)(?=(?:[^"']|"[^"]*"|'[^']*')*$)/`.

| Protected Delimiter | Example Input | `HCON.split()` Result |
| :--- | :--- | :--- |
| **Brackets `[...]`** | `'click[a, b], keyup[key=="Enter"]'` | `['click[a, b]', ' keyup[key=="Enter"]']` |
| **Parentheses `(...)`** | `'find :is(.a, .b), closest div'` | `['find :is(.a, .b)', ' closest div']` |
| **Angle Quotes `<.../>`** | `'from:<.btn, .link/>, load'` | `['from:<.btn, .link/>', ' load']` |
| **String Quotes `"..."` / `'...'`** | `'from:".a, .b", every 2s'` | `['from:".a, .b"', ' every 2s']` |

```javascript
// Inside an htmx extension init(api) hook:
const parts = api.HCON.split('input changed delay:300ms, keyup[key=="Enter"]');
// -> ['input changed delay:300ms', ' keyup[key=="Enter"]']
```

### `HCON.merge`

```javascript
HCON.merge(source: string | Record<string, any>, target: Record<string, any>): Record<string, any>
```

Deep-merges `source` (if `source` is a string, it is first parsed via `HCON.parse(source)`) into `target` and returns `target`.

| Behavior | Specification |
| :--- | :--- |
| **Recursive Object Merge** | If both `source[key]` and `target[key]` are plain objects (`val?.constructor === Object`), `HCON.merge()` recurses into `target[key]`. Otherwise `target[key] = val` overwrites the target property. |
| **Prototype Pollution Guard** | Explicitly skips keys named `'__proto__'`, `'constructor'`, and `'prototype'`. |

```javascript
// Merging an HCON string into an existing configuration object
const target = { sse: { reconnect: true, reconnectDelay: 500 } };
api.HCON.merge('sse.reconnectDelay:2000, transitions:true', target);
// target -> { sse: { reconnect: true, reconnectDelay: 2000 }, transitions: true }
```

---

## Attribute Prefixing (`hx-*` & `data-hx-*`)

htmx v4 supports two attribute prefixes simultaneously out of the box: the primary `hx-` prefix and a configurable secondary prefix (`htmx.config.prefix`, which defaults to `"data-hx-"`).

| Prefix Form | Config Controlling It | Mutability | Example |
| :--- | :--- | :--- | :--- |
| [`hx-*`](#hx) | Built-in primary prefix (always active) | Always enabled | `hx-get="/items"`, `hx-target:inherited="#list"` |
| [`data-hx-*`](#data-hx) | `htmx.config.prefix` (default: `"data-hx-"`) | Startup only (`<meta name="htmx-config">`) | `data-hx-get="/items"`, `data-hx-target:inherited="#list"` |

### `hx-*`

```html
<button hx-post="/items" hx-target="#item-list" hx-swap="beforeend">Add Item</button>
```

The canonical attribute prefix checked first by internal `#attr(elt, name)` and `#prefixSelector(s)`. Every core attribute (`hx-get`, `hx-trigger`, `hx-swap`, `hx-on:*`, `hx-status:*`, etc.) and extension attribute (`hx-sse:connect`, `hx-ws:connect`, `hx-live`, `hx-preload`, etc.) supports `hx-*`.

### `data-hx-*`

```html
<button data-hx-post="/items" data-hx-target="#item-list" data-hx-swap="beforeend">Add Item</button>
```

HTML5 validator-compliant secondary prefix enabled by default via `htmx.config.prefix = "data-hx-"`. Because `#actionSelector` and `#hxOnQuery` (`XPathEvaluator`) are compiled inside `new Htmx()` when the script loads, changing `prefix` (or disabling it with `prefix:""`) **must** be done via `<meta name="htmx-config">`:

```html
<!-- Disable data-hx-* lookup or replace with a custom secondary prefix -->
<meta name="htmx-config" content='prefix:""'>
```

---

## Cross-Portal Documentation Suite Links

This API Reference Catalog is **Portal 2** of the four-portal htmx `v4.0.1` documentation and engineering suite hosted at `https://htmx.drawlib.com/`:

| Portal | URL | Focus & Audience |
| :--- | :--- | :--- |
| **Portal 1: htmx v4 User Guide** | [`https://htmx.drawlib.com/`](https://htmx.drawlib.com/) | Practical Hypermedia-Driven Application (HDA) tutorials, UI patterns, morphing workflows, and htmx 2 $\rightarrow$ 4 migration guide. |
| **Portal 2: htmx v4 API Reference Catalog** | [`https://htmx.drawlib.com/api/`](https://htmx.drawlib.com/api/) | Complete bilingual symbol, attribute, modifier, HTTP header, JS method, event, extension, and CLI dictionary (this portal). |
| **Portal 3: htmx v4 Internal Architecture Guide** | [`https://htmx.drawlib.com/architecture/`](https://htmx.drawlib.com/architecture/) | Source-level walkthrough of `src/htmx.js` internals: `HCON`, `RequestQueue`, `fetch()` pipeline, Idiomorph engine, and `#internalAPI`. |
| **Portal 4: PNI501 Diagnostic Audit Report** | [`https://htmx.drawlib.com/reports/pni501/`](https://htmx.drawlib.com/reports/pni501/) | Deterministic 15-stage JavaScript AST, dependency DAG, `@web/test-runner` V8 coverage, and supply-chain audit report (HTML & PDF). |
