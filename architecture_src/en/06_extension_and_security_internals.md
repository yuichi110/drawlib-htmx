# 6. Extension & Security Internals

htmx v4.0.1 replaces htmx 2's per-element `hx-ext` attribute lookup with a global **event-driven extension dispatcher** (`registerExtension` & `__triggerExtensions` at `src/htmx.js` `L230–238`, `L1529–1541`), a 15-method privileged **`#internalAPI` bridge** (`L155–175`), a pluggable security and dynamic JavaScript evaluation subsystem (`L890–925`, `src/ext/hx-csp.js`), and **17 official extensions** (`src/ext/*.js`).

```drawlib align=center code=fold file=arch_c06_extension_dispatcher_and_api.png caption="htmx v4.0.1 Event-Driven Extension Dispatcher and 15-Method #internalAPI Bridge (src/htmx.js L155–238, L1512–1541)"
from drawlib import canvas
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=184, height=96)

d = ArchitectureDiagram(
    node_style=Styles.Primary,
    node_text_style=Styles.DarkBold.patch(text_size=10.0),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=9.5),
    node_card_style=Styles.Neutral,
    title="htmx v4.0.1 Extension Registration, #internalAPI Bridge & Event Hook Dispatch",
)

# Left Group: Extension Registration & #internalAPI
reg_group = d.add(NodeGroup(title="1. Registration (L155–238)", padding=5.5), xy=(6.0, 8.0))

reg_gate = reg_group.add(
    Node("registerExtension()\nWhitelist & Dedup", width=32, height=17, icon=PhosphorIcon.SHIELD_CHECK, icon_size=7.0, card_style=Styles.PrimaryNeutral),
    xy=(20.0, 52.0),
)
internal_api = reg_group.add(
    Node("#internalAPI Bridge\n15 Bound Primitives", width=32, height=17, icon=PhosphorIcon.KEY, icon_size=7.0, style=Styles.WhiteBold, card_style=Styles.PrimaryFlat, text_style=Styles.WhiteBold.patch(text_size=10.0)),
    xy=(20.0, 18.0),
)

# Center Group: Hook Storage & Event Dispatcher
disp_group = d.add(NodeGroup(title="2. Hook Dispatch (L1512–1541)", padding=5.5), xy=(64.0, 8.0))

ext_map = disp_group.add(
    Node("__extMethods Map\nHook Function Arrays", width=34, height=17, icon=PhosphorIcon.LIST_BULLETS, icon_size=7.0, card_style=Styles.SecondaryNeutral),
    xy=(21.0, 52.0),
)
trig_ext = disp_group.add(
    Node("__triggerExtensions()\nColon -> Underscore", width=34, height=17, icon=PhosphorIcon.LIGHTNING, icon_size=7.0, style=Styles.WhiteBold, card_style=Styles.AccentFlat, text_style=Styles.WhiteBold.patch(text_size=10.0)),
    xy=(21.0, 18.0),
)

# Right Group: Official Extensions & DOM CustomEvent
dom_group = d.add(NodeGroup(title="3. Extensions & DOM Event", padding=5.5), xy=(124.0, 8.0))

ext_suite = dom_group.add(
    Node("17 Official Extensions\nhx-csp, hx-live, sse, ws", width=34, height=17, icon=PhosphorIcon.PLUGS_CONNECTED, icon_size=7.0, card_style=Styles.PrimaryNeutral),
    xy=(21.0, 52.0),
)
dom_evt = dom_group.add(
    Node("DOM CustomEvent\n!detail.cancelled Gate", width=34, height=17, icon=PhosphorIcon.BROADCAST, icon_size=7.0, card_style=Styles.Neutral),
    xy=(21.0, 18.0),
)

d.connect(reg_gate, internal_api, label="ext.init(api)", padding=1.0)
d.connect(reg_gate, ext_map, label="Store hooks", padding=1.0)
d.connect(ext_map, trig_ext, label="Lookup fn[]", padding=1.0)
d.connect(ext_map, ext_suite, label="handle_swap", padding=1.0)
d.connect(internal_api, trig_ext, label="__trigger()", padding=1.0)
d.connect(trig_ext, dom_evt, label="If !cancelled", padding=1.0)
d.connect(ext_suite, dom_evt, label="Cancel / Emit", arrow="<->", padding=1.0)

d.draw(xy=(4.0, 4.0))
canvas.save()
```

---

## 1. Event-Driven Extension Dispatcher (`registerExtension` & `__triggerExtensions`)

In htmx v4, extensions are registered globally via `htmx.registerExtension(name, extension)` (`src/htmx.js` `L230–238`) and automatically participate in the lifecycle of every element without requiring `hx-ext="..."` attributes in the DOM.

### 1.1 Whitelist Gating, Deduplication & Hook Indexing

When `registerExtension(name, extension)` is called:

```javascript
// src/htmx.js L230–238
registerExtension(name, extension) {
    if (this.__approvedExt && !this.__approvedExt.split(/,\s*/).includes(name)) return false;
    if (this.__registeredExt.has(name)) return false;
    this.__registeredExt.add(name);
    if (extension.init) extension.init(this.#internalAPI);
    Object.entries(extension).forEach(([key, value]) => {
        if(!this.__extMethods.get(key)?.push(value)) this.__extMethods.set(key, [value]);
    });
}
```

1. **Whitelist Enforcement (`this.__approvedExt` `L212`, `L231`)**: During `__initHtmxConfig()`, `this.__approvedExt` is initialized from `this.config.extensions` (typically configured via `<meta name="htmx-config" content='extensions:"hx-csp, hx-live"'>`). If `this.__approvedExt` is non-empty and does not include `name`, `registerExtension` immediately returns `false`, refusing to initialize or store the extension.
2. **Idempotent Registration (`this.__registeredExt` `L232–233`)**: `this.__registeredExt` (`Set<string>`) prevents duplicate script inclusions from registering the same extension hooks twice.
3. **Privileged Initialization (`extension.init(this.#internalAPI)` `L234`)**: Passes the bound `#internalAPI` object to `extension.init` once at registration time.
4. **Hook Table Population (`this.__extMethods` `L235–237`)**: Every property on `extension` is appended to an array in `this.__extMethods: Map<string, Function[]>`.

### 1.2 Colon-to-Underscore Event Mapping & Cancellation Protocol

Whenever core calls `this.__trigger(on, eventName, detail, bubbles)` (`L1512–1527`), htmx executes extension hooks **synchronously before** dispatching the DOM `CustomEvent`:

```javascript
// src/htmx.js L1524–1541, L1586–1597
on = this.__normalizeElement(on);
this.__triggerExtensions(on, eventName, detail);
return this.trigger(on, this.__maybeAdjustMetaCharacter(eventName), detail, bubbles);

__triggerExtensions(elt, eventName, detail = {}) {
    let methods = this.__extMethods.get(eventName.replace(/:/g, '_'));
    if (methods) {
        detail.cancelled = false;
        for (const fn of methods) {
            if (fn(elt, detail) === false || detail.cancelled) {
                detail.cancelled = true;
                return false;
            }
        }
    }
    return true;
}
```

- **Colon-to-Underscore Mapping (`L1530`)**: Any htmx event name `htmx:phase:action` is converted via `eventName.replace(/:/g, '_')` into a valid JavaScript identifier (`htmx_phase_action`). For example:
  - `htmx:before:request` $\rightarrow$ `htmx_before_request(elt, detail)`
  - `htmx:before:morph:node` $\rightarrow$ `htmx_before_morph_node(elt, detail)`
  - `htmx:process:upsert` $\rightarrow$ `htmx_process_upsert(templateElt, detail)`
  - `htmx:scope` $\rightarrow$ `htmx_scope(elt, detail)`
- **Non-Event Hooks**: Two special keys in `__extMethods` are invoked directly rather than through `__triggerExtensions`:
  - `init(internalAPI)` — called once during `registerExtension` (`L234`).
  - `handle_swap(swapStyle, target, fragment, swapSpec)` — called by `__insertContent` (`L1456–1470`) when `swapStyle` does not match any of the 12 built-in swap styles.
- **Short-Circuit Cancellation (`L1532–1538`, `L1595`)**: If any extension hook returns `false` or sets `detail.cancelled = true`, `__triggerExtensions` sets `detail.cancelled = true`, halts the remaining extension hooks for that event, and causes `this.trigger()` (`!detail?.cancelled && target.dispatchEvent(evt)` at `L1595`) to skip dispatching the DOM `CustomEvent` and return `false` to the caller.

---

## 2. The `#internalAPI` Bridge (`src/htmx.js` `L155–175`)

Because `Htmx` methods prefixed with `__` are rewritten into ES2022 private `#` methods during the `npm run build:iife` and `build:esm` build step (`sed -e 's/__/#/g'`), external extensions cannot call `htmx.#attributeValue()` directly on the global `htmx` instance. Instead, `constructor()` constructs `this.#internalAPI` (`L155–175`) exposing **15 bound internal primitives** to `extension.init(api)`:

| `#internalAPI` Key | Bound Target (`src/htmx.js`) | Signature & Extension Use Cases |
| :--- | :--- | :--- |
| **`HCON`** | `HCON` (`L8–92`, `L156`) | `{ parse(str), merge(str, target), split(str) }` parser used by `hx-sse`, `hx-ws`, and custom config attributes. |
| **`attributeValue`** | `this.__attributeValue` (`L288–318`) | `(elt, name, defaultVal?, eltCollector?, allowInheritance?)` — reads `hx-*` / `data-hx-*` attributes with `:inherited` and `:append` resolution. |
| **`parseTriggerSpecs`** | `this.__parseTriggerSpecs` (`L523–601`) | `(specStr)` — parses trigger strings into structured `{ name, filters, delay, timeout, ... }` specs (used by `hx-preload`). |
| **`determineMethodAndAction`** | `this.__determineMethodAndAction` (`L429–463`) | `(elt, evt)` — resolves `{ method, action }` from `hx-get`..`hx-delete`, `hx-action`, or boosted `<a>`/`<form>` (used by `hx-preload`). |
| **`createRequestContext`** | `this.__createRequestContext` (`L354–427`) | `(sourceElement, sourceEvent)` — builds a full request `ctx` object including `HX-*` headers (used by `hx-preload` and `hx-ws`). |
| **`collectFormData`** | `this.__collectFormData` (`L1807–1831`) | `(elt, form, submitter, validate?, isGet?)` — gathers `FormData` respecting `hx-include` and submitters (used by `hx-preload` and `hx-ws`). |
| **`getAttributeObject`** | `this.__getAttributeObject` (`L1875–1893`) | `(elt, attrName, callback, scope?)` — parses HCON/JSON or evaluates `js:` expressions for `hx-vals` / `hx-headers`. |
| **`insertContent`** | `this.__insertContent` (`L1360–1510`) | `async (task, cssTransition?)` — executes a single swap and settle task. |
| **`morph`** | `this.__morph` (`L2018–2032`) | `(oldNode, fragment, innerHTML)` — invokes the Idiomorph engine directly (used by `hx-alpine-compat` to morph `_x_teleport` targets at `L74`). |
| **`isSoftMatch`** | `this.__isSoftMatch` (`L2153–2160`) | `(oldNode, newNode) => boolean` — **mutable property** on `#internalAPI` called by `__findBestMatch` (`L2129`). Overridden by `hx-alpine-compat` (`L24–31`) so Alpine `x-bind:id` / `:id` elements soft-match despite dynamic ID changes! |
| **`initSecurity`** | Arrow closure (`L166–170`) | `(ttPolicy, syncFn, asyncFn)` — replaces `this.#ttPolicy`, `this.#Function`, and `this.#AsyncFunction` (used by `hx-csp`). |
| **`onTrigger`** | `this.__onTrigger` (`L622–758`) | `(elt, specString, handler)` — wires full htmx trigger specs (events, `load`, `revealed`, `intersect`, `every`, queues, filters) to a custom `handler` (used by `hx-sse`, `hx-ws`, `hx-multipart`). |
| **`htmxProp`** | `this.__htmxProp` (`L345–347`) | `(elt) => elt._htmx ||= {}` — returns or initializes the per-element `_htmx` state bag. |
| **`triggerHtmxEvent`** | `this.__trigger` (`L1512–1527`) | `(on, eventName, detail?, bubbles?)` — logs via `logAll`, runs `__triggerExtensions`, and dispatches a cancellable DOM `CustomEvent`. |
| **`executeJavaScript`** | `this.__executeJavaScript` (`L911–925`) | `(thisArg, obj, code, expression?, isAsync?, compile?)` — evaluates or pre-compiles JS expressions with `htmx:scope` injection (used by `hx-live`). |

---

## 3. Security Architecture, Dynamic JS Evaluation & `hx-csp.js`

htmx v4 centralizes all dynamic JavaScript evaluation and HTML/script sink creation through three private fields on `Htmx` (`#Function`, `#AsyncFunction`, and `#ttPolicy` at `L138–140`), enabling the `hx-csp` extension (`src/ext/hx-csp.js`, 220 lines) to enforce strict Content Security Policies without modifying core logic.

```drawlib align=center code=fold file=arch_c06_csp_three_layer_defense.png caption="Three-Layer CSP Enforcement in src/ext/hx-csp.js: Nonce Gating, Trusted Types & safeEval Script Compilation"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, ChevronProcess
from drawlib.styles import Styles
from drawlib.text import text

setup(width=184, height=94)

text(
    (92, 89),
    "htmx v4.0.1 Three-Layer Content Security Policy Architecture (src/ext/hx-csp.js)",
    style=Styles.DarkBold.patch(text_size=13.5),
)

# Top: 3-Layer Defense Overview
layers = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=2.0,
    flat_left_end=True,
)
layers.add(
    "Layer 1: Nonce Gate",
    description="hx-nonce === pageNonce",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    description_style=Styles.White.patch(text_size=9.5),
)
layers.add("Layer 2: Trusted Types", description="trustedTypes.createPolicy('htmx')", style=Styles.PrimaryNeutral)
layers.add(
    "Layer 3: safeEval Cache",
    description="<script nonce> Compilation",
    style=Styles.AccentFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    description_style=Styles.White.patch(text_size=9.5),
)
layers.draw(xy=(6.0, 68.0), width=172.0, height=15.0)

# Bottom-Left: Layer 1 & 2 — DOM & Response Nonce Enforcement
col_left = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=10.0),
    icon_style=Styles.PrimaryBold,
    direction="vertical",
    spacing=2.6,
)
col_left.add(
    "Fail-Closed Nonce & TT (L103–120)",
    "Reads script[nonce].nonce and creates\n'htmx' TT policy (or blocks all htmx)",
    badge_text="L1a",
    icon=phosphor.lock_key,
)
col_left.add(
    "Init & Request Gate (checkNonce)",
    "Strips hx-* on mismatch; blocks js: URLs\nand unnonced formaction submitters",
    badge_text="L1b",
    icon=phosphor.shield_warning,
)
col_left.add(
    "Response Nonce Scrub (L174–193)",
    "Scrubs stolen pageNonce from raw text;\npromotes same-origin CSP response nonces",
    badge_text="L1c",
    icon=phosphor.arrows_clockwise,
)
col_left.draw(xy=(6.0, 6.0), width=84.0, height=56.0)

# Bottom-Right: Layer 3 — __executeJavaScript & safeEval Compilation
col_right = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    icon_style=Styles.DarkBold,
    direction="vertical",
    spacing=2.6,
)
col_right.add(
    "Scope Assembly (htmx.js L911–925)",
    "Merges __apiMethods(thisArg), htmx:scope\nextension helpers, and event objects",
    badge_text="L3a",
    icon=phosphor.brackets_curly,
)
col_right.add(
    "Eval-Time Nonce Re-Check (L135)",
    "Verifies getNonce(thisArg) === pageNonce\non every call; fires security:violation",
    badge_text="L3b",
    icon=phosphor.check_circle,
)
col_right.add(
    "Nonced <script> & safeEvalCache",
    "Compiles window.__htmx_eval_N without\nunsafe-eval; caches by 'keys|body'",
    badge_text="L3c",
    icon=phosphor.cpu,
    badge_style=Styles.AccentFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
)
col_right.draw(xy=(94.0, 6.0), width=84.0, height=56.0)

save()
```

### 3.1 Core Dynamic JS Evaluation (`__executeJavaScript` & `__apiMethods`)

Whenever htmx evaluates an `hx-on:*` handler (`L1729`), an `hx-vals="js:..."` / `hx-headers="js:..."` expression (`L1886`), a bracketed trigger filter `click[ctrlKey]` (`L702`), or an `hx-live` reactive binding, it calls `__executeJavaScript` (`src/htmx.js` `L890–925`):

```javascript
// src/htmx.js L890–925
__apiMethods(thisArg) {
    let bound = {};
    let proto = Object.getPrototypeOf(this);
    for (let name of Object.getOwnPropertyNames(proto)) {
        if (name !== 'constructor' && typeof this[name] === 'function') {
            if (["find", "findAll"].includes(name)) {
                bound[name] = (arg1, arg2) => {
                    if (arg2 === undefined) {
                        return this[name](thisArg, arg1);
                    } else {
                        return this[name](arg1, arg2);
                    }
                };
            } else {
                bound[name] = this[name].bind(this);
            }
        }
    }
    return bound;
}

__executeJavaScript(thisArg, obj, code, expression = true, isAsync = true, compile = false) {
    let args = {};
    Object.assign(args, this.__apiMethods(thisArg));
    let scope = {};
    let detail = { scope, code };
    this.__triggerExtensions(thisArg, "htmx:scope", detail);
    code = detail.code;
    Object.assign(args, scope);
    Object.assign(args, obj);
    let keys = Object.keys(args);
    let values = Object.values(args);
    let FunctionConstructor = isAsync ? this.#AsyncFunction : this.#Function;
    let func = new FunctionConstructor(...keys, expression ? `return (${code})` : code);
    return compile ? () => func.call(thisArg, ...values) : func.call(thisArg, ...values);
}
```

Key architectural features:
1. **Context-Bound Public API (`__apiMethods` `L890–909`)**: Automatically injects all public `Htmx.prototype` methods (`ajax`, `trigger`, `process`, `swap`, `timeout`, `parseInterval`, `on`, `onLoad`) into the expression scope, while currying `find(sel)` and `findAll(sel)` so single-argument calls resolve relative to `thisArg`!
2. **`htmx:scope` Extension Hook (`L915–918`)**: Fires `this.__triggerExtensions(thisArg, "htmx:scope", { scope, code })`, allowing `hx-live` (`src/ext/hx-live.js` `L839–844`) to inject reactive helpers (`q`, `data`, `aria`, `attr`, `local`, `closest`, `toggle`, `take`, `debounce`, `forEvent`, `nextFrame`, `insert`, `matches`, `style`) into `detail.scope` and rewrite reserved `class.foo` tokens into `attr.class.foo` in `detail.code`.
3. **Reusable Pre-Compilation (`compile = true` `L924`)**: When `compile === true` (used by `hx-live`'s `registerLive` at `L764`), `__executeJavaScript` constructs `func` once and returns a zero-argument closure `() => func.call(thisArg, ...values)` so reactive ticks never re-run scope assembly or `new FunctionConstructor()`.

### 3.2 Three-Layer CSP Enforcement (`src/ext/hx-csp.js`)

Loading `src/ext/hx-csp.js` hardens htmx against HTML injection and XSS attacks via three interlocking layers:

1. **Layer 1 — Nonce Gating & Stolen-Nonce Scrubbing (`L40–108`, `L168–216`)**:
   - **Fail-Closed Initialization (`L103–108`)**: Reads `pageNonce = document.querySelector('script[nonce]')?.nonce || null` (using the DOM `.nonce` property, which remains readable in JS even after browsers blank the `nonce=""` HTML attribute to defeat CSS attribute-selector exfiltration). If no `pageNonce` exists, `hx-csp` logs an error and leaves `pageNonce = null`, causing all hooks to return `false` and block htmx entirely.
   - **Element Initialization Gate (`checkNonce` `L44–48`, `stripHxAttributes` `L79–94`)**: Hooked to both `htmx_before_init` and `htmx_before_on_init`. Reads `hx-nonce` (supporting `:inherited` via `internalApi.attributeValue(elt, 'hx-nonce')`). If `eltNonce !== pageNonce`, `stripHxAttributes` removes every `hx-*` / `data-hx-*` attribute from `elt`, logs an error, fires `htmx:security:strip` (`{ reason: 'missing-nonce' | 'nonce-mismatch', stripped }`), and cancels initialization.
   - **Response Nonce Scrub & Same-Origin Promotion (`htmx_after_request` `L174–193`)**:
     - First, **always scrubs `pageNonce`** from raw `ctx.text` (`rewriteNoncesInText(ctx.text, pageNonce, '')` at `L180`). Because the server generates a fresh nonce per HTTP response and cannot know the client's original `pageNonce`, any occurrence of `pageNonce` in a server response indicates a reflected/stored stolen-nonce attack!
     - Second, verifies that `new URL(ctx.response.raw.url).origin === location.origin`. Only for verified same-origin responses, `hx-csp` extracts the response's fresh nonce from the `Content-Security-Policy` header (`extractNonceFromCSP` anchored to `script-src`/`default-src` at `L51–53`) or `<meta http-equiv="Content-Security-Policy">` (`extractNonceFromMetaTag` `L57–61`) and rewrites `nonce="${responseNonce}"` to `nonce="${pageNonce}"` in `ctx.text` before `__makeFragment` parses it.
   - **Request Action & Submitter Gate (`htmx_config_request` `L198–216`)**: Blocks any request whose `action` starts with `js:` or `javascript:` (`reason: 'javascript-url'`), and blocks boosted `<form>` submissions where a submit button overrides `formaction` without a valid `hx-nonce` (`reason: 'unnonced-submitter'`), firing `htmx:security:violation` and setting `detail.cancelled = true`.
2. **Layer 2 — Trusted Types Policy (`L112–120`)**:
   Calls `trustedTypes.createPolicy('htmx', { createHTML: s => s, createScript: s => s })` and passes it to `api.initSecurity(...)`. If the page's CSP `trusted-types` directive does not whitelist `'htmx'`, policy creation throws, and `hx-csp` sets `pageNonce = null` to fail closed.
3. **Layer 3 — `safeEval` Nonce-Stamped Script Compilation (`L122–165`)**:
   `makeGatedConstructor(isAsync)` replaces `#Function` and `#AsyncFunction`:
   - On every invocation, it re-verifies `getNonce(thisArg) === pageNonce` (`L135`), blocking execution and firing `htmx:security:violation` (`{ reason: 'nonce-mismatch-at-eval' }`) if an attacker mutated the DOM after init.
   - When `htmx.config.safeEval: true` is enabled, it avoids `new Function()` (so CSP requires **no `'unsafe-eval'`**) by compiling expressions via a transient `<script nonce="${pageNonce}">` element appended to and immediately removed from `document.head` (`L146–155`), caching the compiled function in `safeEvalCache: Map<string, Function>` keyed by `keys.join(',') + '|' + body`.

---

## 4. Deep Dive into the 17 Official Extensions (`src/ext/*.js`)

### 4.1 Complete Inventory of the 17 Official Extensions

The `src/ext/` directory ships 17 official extensions totaling **4,529 lines of code**. As defined in `package.json` (`build:htmax` at `L28`), 11 of these extensions are bundled into the all-in-one `dist/htmax.js` distribution (with `history-cache` pre-configured as `htmx.config.historyCache ??= { disable: true }`):

| File (`src/ext/`) | Registered Name | LOC | In `htmax`? | Primary Extension Hooks & Architectural Purpose |
| :--- | :--- | :---: | :---: | :--- |
| **`hx-multipart.js`** | `'hx-multipart'` | 1,192 | No | `htmx_config_request`, `htmx_after_process`, `htmx_before_response`, `htmx_before_cleanup`. Streaming `multipart/mixed` & `multipart/parallel` parser + `Response.prototype.parts()` prollyfill. |
| **`hx-live.js`** | `'hx-live'` | 847 | **Yes** | `htmx_after_process`, `htmx_before_swap`, `htmx_finally_swap`, `htmx_before_cleanup`, `htmx_before_morph_attr`, `htmx_scope`. Reactive `:attr`/`hx-live` bindings & `q()` proxy engine. |
| **`hx-ws.js`** | `'ws'` | 589 | **Yes** | `htmx_after_process`, `htmx_before_cleanup`. Bidirectional WebSocket lifecycle (`hx-ws:connect`, `hx-ws:send`), serialized send/receive queues, and auto-reconnect. |
| **`hx-sse.js`** | `'sse'` | 444 | **Yes** | `htmx_config_request`, `htmx_before_response`, `htmx_after_process`, `htmx_before_cleanup`. Fetch-based `text/event-stream` reader (`parseSSE`), `Last-Event-ID` reconnect, and `extensionPromise`. |
| **`hx-history-cache.js`** | `'history-cache'` | 250 | **Yes** *(off)* | `htmx_before_history_update`, `htmx_after_history_update`, `htmx_before_history_restore`. LRU `sessionStorage` page snapshot cache preserving input values and scroll offsets. |
| **`hx-csp.js`** | `'hx-csp'` | 220 | No | `init` (`initSecurity`), `htmx_before_init`, `htmx_before_on_init`, `htmx_after_request`, `htmx_config_request`. Nonce gating, Trusted Types policy, and `safeEval`. |
| **`hx-head.js`** | `'hx-head'` | 191 | No | `htmx_before_response`, `htmx_after_swap`, `htmx_history_cache_before_restore`, `htmx_history_cache_after_restore`. Diffs/merges `<head>` tags, awaiting blocking CSS/JS before swap. |
| **`hx-alpine-compat.js`** | `'alpine-compat'` | 111 | **Yes** | `init` (overrides `api.isSoftMatch`), `htmx_before_swap`, `htmx_before_morph_node`, `htmx_after_swap`, `htmx_finally_request`, `htmx_history_cache_*`. Bridges Alpine `_x_dataStack` & `_x_teleport` across morphs. |
| **`hx-pending.js`** | `'hx-pending'` | 103 | **Yes** | `htmx_config_request`, `htmx_before_request`, `htmx_before_swap`, `htmx_error`. Renders optimistic `<template>` placeholders stamped with request body `data-*` attributes during in-flight requests. |
| **`hx-preload.js`** | `'preload'` | 103 | **Yes** | `htmx_after_init`, `htmx_before_request`, `htmx_before_cleanup`. Prefetches `GET` responses on `mousedown`/`touchstart` (or custom trigger) with 5s TTL cache (`ctx.fetch = () => prefetch`). |
| **`htmx-2-compat.js`** | `'compat'` | 94 | No | `init`, 16 `htmx_*` hooks. Enables `implicitInheritance = true`, adds `"4xx", "5xx"` to `noSwap`, and re-dispatches legacy camelCase htmx 2 events (`htmx:afterRequest`, etc.). |
| **`hx-upsert.js`** | `'upsert'` | 90 | **Yes** | `htmx_process_upsert`, `handle_swap`. Implements `<hx-upsert>` and `hx-swap="upsert"`, updating existing elements by `id` or inserting sorted by `key` (`localeCompare` with `numeric: true`). |
| **`hx-browser-indicator.js`** | `'browser-indicator'` | 89 | **Yes** | `htmx_before_history_update`, `htmx_before_request`, `htmx_finally_request`. Triggers the native browser tab loading spinner via the Navigation API (`navigation.navigate` + `event.intercept`). |
| **`hx-download.js`** | `'download'` | 89 | **Yes** | `htmx_before_response`. Intercepts `hx-swap="download"`, `Content-Disposition: attachment`, or `HX-Download` headers, streaming chunks with `htmx:download:progress` into a Blob download. |
| **`hx-targets.js`** | `'hx-targets'` | 46 | **Yes** | `htmx_before_swap`. Expands `hx-targets="<selector>"` by splicing the `main` swap task into one cloned task per matched target element. |
| **`hx-ptag.js`** | `'ptag'` | 37 | No | `htmx_after_init`, `htmx_config_request`, `htmx_after_request`. Stores per-element polling tags (`hx-ptag` / `HX-PTag` header) so servers can return `304 Not Modified`. |
| **`hx-prompt.js`** | `'hx-prompt'` | 24 | No | `htmx_config_request`. Prompts via `window.htmxPrompt || window.prompt`, fires cancellable `htmx:prompt`, and sets the `HX-Prompt` request header. |

```drawlib align=center code=fold file=arch_c06_live_multipart_sse_ws_engines.png caption="Internal Architecture of the Four Major Runtime Extensions: hx-live, hx-multipart, hx-sse & hx-ws"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList
from drawlib.styles import Styles
from drawlib.text import text

setup(width=184, height=92)

text(
    (92, 87),
    "htmx v4.0.1 Flagship Extension Engines: Reactivity & Streaming Internals",
    style=Styles.DarkBold.patch(text_size=13.5),
)

# Left Column: hx-live & hx-multipart
col_left = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
    direction="vertical",
    spacing=3.5,
)
col_left.add(
    "1. hx-live.js — Reactive Proxy (847 LOC)",
    "• XPath discovers [hx-live] & :attr bindings\n"
    "• MutationObserver -> queueMicrotask tick\n"
    "• Detaches observer on write; pauses on swap\n"
    "• qProxy + makeStateScope(data,aria,class,attr)",
    badge_text="LIVE",
    icon=phosphor.lightning,
)
col_left.add(
    "2. hx-multipart.js — Stream Parser (1,192 LOC)",
    "• Prollyfills Response.prototype.parts()\n"
    "• Boyer-Moore-Horspool + chunk carry tail\n"
    "• 7-state FSM + ReadableStream backpressure\n"
    "• mixed vs parallel swap + HX-Last-Part-ID",
    badge_text="MIME",
    icon=phosphor.stack,
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=10.0),
    icon_style=Styles.PrimaryBold,
)
col_left.draw(xy=(6.0, 6.0), width=84.0, height=74.0)

# Right Column: hx-sse & hx-ws
col_right = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    icon_style=Styles.DarkBold,
    direction="vertical",
    spacing=3.5,
)
col_right.add(
    "3. hx-sse.js — EventStream Engine (444 LOC)",
    "• Intercepts text/event-stream before core\n"
    "• Holds lifecycle via ctx.extensionPromise\n"
    "• parseSSE(): 0xFEFF BOM & \\r\\n|\\r|\\n split\n"
    "• Backoff + jitter reconnect w/ Last-Event-ID",
    badge_text="SSE",
    icon=phosphor.broadcast,
)
col_right.add(
    "4. hx-ws.js — WebSocket Engine (589 LOC)",
    "• Normalizes URLs to ws(s)://; pagehide 1000\n"
    "• Serialized receiving/sending Promise chains\n"
    "• waitUntil() middleware + 100-msg send queue\n"
    "• Routes JSON {content, target, swap} or HTML",
    badge_text="WS",
    icon=phosphor.arrows_left_right,
    badge_style=Styles.AccentFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
)
col_right.draw(xy=(94.0, 6.0), width=84.0, height=74.0)

save()
```

### 4.2 Reactive DOM & Proxy Engine (`src/ext/hx-live.js`, 847 LOC)

`hx-live.js` adds spreadsheet-like reactive attribute bindings (`:disabled="!data.valid"`, `:text="data.count"`, `:.active="data.open"`, `?hidden`) and side-effect blocks (`hx-live="..."`) directly on top of the DOM without maintaining a separate virtual DOM or shadow state store:

1. **Microtask Batching & Swap Suspension (`ensureActive` & `schedule` `L22–70`, `L833–838`)**:
   - Registers a global `MutationObserver` on `document.documentElement` (`{ childList: true, subtree: true, attributes: true, characterData: true }`), a capture-phase `change` listener, and a capture-phase `input` listener debounced by `htmx.config.live?.inputDebounce ?? 100` ms.
   - `schedule()` coalesces multiple mutations within the same turn via `queueMicrotask()`. Inside the microtask, it **disconnects `observer` before evaluating `fns`** (`observer?.disconnect()` at `L55`) so DOM writes performed by reactive bindings do not recursively re-trigger the `MutationObserver`, then re-attaches `observer` afterward (`L66`). If a single evaluation pass exceeds `16ms` (one 60Hz frame), it logs a one-time performance warning (`L59–62`).
   - During htmx swaps, `htmx_before_swap` increments `swaps++` and `htmx_finally_swap` decrements `--swaps`, deferring all reactive recomputations until multi-task swaps finish (`if (swaps > 0) return` at `L51`).
2. **XPath Discovery & Pre-Compiled Closures (`buildLiveQuery` `L683–703`, `registerLive` `L747–781`)**:
   - Constructs a compiled `XPathEvaluator` expression matching `.//*[@*[starts-with(name(), "hx-live:") or starts-with(name(), ":")] or @hx-live]` (automatically disabling the shorthand `:` prefix if `window.Alpine` is detected at `L690–693`).
   - `registerLive(elt, code, attrName)` pre-compiles each expression once via `exec ||= api.executeJavaScript(elt, { debounce }, code, binding, isAsync, true)` (`L764`). If an `hx-live` effect contains `await`, `overlapping = !binding && hasAwait` prevents concurrent overlapping runs of the same async effect (`L752`, `L761`).
3. **Reactive `Proxy` Hierarchy (`qProxy`, `makeStateScope`, `makeClosest` `L140–362`, `L631–679`)**:
   - **`makeStateScope(elts, cascades)` (`L313–322`)**: Lazily constructs 4 specialized proxies:
     - `data`: `makeAttrProxy(elts, cascades, null, 'data-')` — converts camelCase properties to `data-kebab-case` attributes and automatically parses/stringifies JSON values (`readData` / `writeData` `L212–215`, `L378–381`).
     - `aria`: `makeAttrProxy(elts, cascades, null, 'aria-')` — handles string ARIA attributes, space-separated ID-ref lists (`controls`, `labelledby`), and JSON boolean ARIA values (`L231–232`, `L364–376`).
     - `class`: `makeClassProxy(elts, cascades)` — supports `.class.foo = true`, `.class.toggle('foo')`, `.class.add()`, `.class.remove()`, `.class.replace()`, and `.class.assign({ active: true })` (`L246–311`).
     - `attr`: `makeAttrProxy(elts, cascades, scope, '')` — coerces `PROPERTY_BINDING_ATTRS` (`checked`, `value`, `selected`, `hidden`), `BOOLEAN_ATTRS` (`disabled`, `open`, `inert`, etc.), `NUMERIC_ATTRS` (`tabindex`, `min`, `max`), and `valueAsNumber` on `<input type="number|range">` (`L72–115`).
   - **`makeClosest(elts)` (`L327–340`)**: Wraps a callable `function(){}` in a `Proxy` with both an `apply` trap (`closest('.card')` returns a `qProxy` of nearest matching ancestors) and a `get` trap (`closest.data.count` walks up `parentElement` to read/write the nearest ancestor owning `data-count`). In `makeExpressionScope(elt)` (`L357`), bare `data` is aliased to `closest.data` so components naturally share state with ancestor containers!
   - **`makeQ(ctx)` & `qProxy(elts)` (`L552–679`)**: Supports scoped queries (`q('.item in #list')`, `q('.btn in this')`) and directional queries (`q('next .panel')`, `q('previous .tab')`, `q('closest tr')`, `q('first li')`, `q('last li')` using `compareDocumentPosition` bitmasks `& 4` and `& 2`), returning a multi-element `qProxy` that forwards array methods (`map`, `filter`, `forEach`), DOM methods, and reactive property assignments across all matched elements.

### 4.3 Streaming Multipart Boundary Parser (`src/ext/hx-multipart.js`, 1,192 LOC)

`hx-multipart.js` enables a single HTTP response (`Content-Type: multipart/mixed` or `multipart/parallel`) to stream multiple HTML fragments over time, each with its own `HX-Target`, `HX-Swap`, `HX-Select`, `HX-Trigger`, or `HX-Part-ID` headers:

1. **Request Interception (`htmx_before_response` `L409–429`)**:
   When the response `Content-Type` is `multipart/mixed` or `multipart/parallel`, `hx-multipart` clears `ctx.requestTimeout` (`clearTimeout(ctx.requestTimeout)`) and overrides `ctx.response.raw.text = async () => { await handleMultipartResponse(ctx, type); ctx.swap = 'none'; return ''; }`. Core awaits `response.text()`, holding the request lifecycle open while `handleMultipartResponse` consumes the stream and sets `ctx.swap = 'none'` afterward.
2. **Vendored `MultipartParser` & `Response.prototype.parts()` Prollyfill (`L436–1190`)**:
   - **Boyer-Moore-Horspool Byte Search (`createSearch` `L469–486`)**: Precomputes a 256-entry `Uint8Array` skip table over the UTF-8 encoded `\r\n--${boundary}` needle for fast sub-linear scanning across incoming `Uint8Array` network chunks.
   - **Cross-Chunk Boundary Tail Detection (`createPartialTailSearch` `L490–512` & `#analyzeCarryBoundary` `L785–809`)**: If a chunk ends with a prefix of `\r\n--${boundary}`, the parser holds only that trailing suffix in `this.#buffer` (routing all preceding bytes immediately to the active `BodyPart`) and reconciles it when the next chunk arrives.
   - **7-State Parser FSM (`State` `L516–531`)**: Transitions through `START` (discarding RFC 2046 preamble bytes before `--boundary`) $\rightarrow$ `READING_BOUNDARY_SUFFIX` (`\r\n` vs closing `--`) $\rightarrow$ `READING_HEADERS` (scanning for `\r\n\r\n`) $\rightarrow$ either `READING_BODY_WITH_CONTENT_LENGTH` (fast path when the part declares `Content-Length`, followed by `EXPECTING_BOUNDARY`) or `READING_BODY_UNTIL_BOUNDARY` $\rightarrow$ `DONE`.
   - **Pull-Driven Backpressure (`BodyPart` & `iterateStreamParts` `L833–990`, `L1109–1173`)**: `parser.onPull` only calls `reader.read()` on the underlying fetch stream when the active `BodyPart`'s `ReadableStreamDefaultController` has `desiredSize > 0` (`part._wantsMore()`), propagating consumer backpressure all the way to the network socket.
3. **Sequential vs. Parallel Swapping & Ordered Checkpoint Reconnect (`L231–335`)**:
   - For each yielded `part`, `handleMultipartResponse` fires `htmx:multipart:before:part` (supporting `detail.waitUntil(promise)` async middleware at `L248–256`), extracts per-part `HX-*` headers (`extractPartActions`), and runs `htmx.swap(...)`.
   - In `multipart/mixed`, each part swap is awaited sequentially (`await handling` at `L315`). In `multipart/parallel`, `handling` promises are added to a `pending` `Set` (`L308–313`) so parts swap concurrently as soon as their bodies finish streaming.
   - **In-Order Checkpoint Tracking (`checkpoints` `L269–303`)**: Because concurrent `multipart/parallel` parts can finish out of order, `connection.lastPartId` is only advanced through a contiguous prefix of completed `checkpoints` (`while (checkpoints[checkpointIndex]?.completed)`). On reconnect (with exponential backoff, jitter, and `visibilitychange` background pause), `HX-Last-Part-ID` is sent so the server can resume from the last contiguous checkpoint (`L180–185`).

### 4.4 Server-Sent Events & WebSockets (`hx-sse.js` 444 LOC & `hx-ws.js` 589 LOC)

Both streaming transport extensions integrate directly with `htmx.swap()` and `#internalAPI`:

- **`src/ext/hx-sse.js` (Registered as `'sse'`)**:
  1. **`ctx.extensionPromise` Lifecycle Control (`L125–132`, `L292`, `L313`, `L406–415`)**: In `htmx_before_response`, when `Content-Type` includes `text/event-stream`, `hx-sse` clears `ctx.requestTimeout`, assigns `ctx.extensionPromise = new Promise(resolve => releaseRequest = resolve)`, and returns `false` (preventing core from reading the body as a single HTML response while core's `finally` block awaits `ctx.extensionPromise`). Depending on `config.releaseOn`, `release()` is called `'immediate'` (default for `hx-sse:connect`), on the `'first'` swapped message, when the server sends a named `event: hx:release` message (`L292`), or at stream `'end'` (default for standard `hx-get` requests returning `text/event-stream`).
  2. **Spec-Compliant `parseSSE(connection)` Async Generator (`L37–111`)**: Reads `currentResponse.body.getReader()` via `TextDecoder({ stream: true })`, strips a leading UTF-8 BOM (`0xFEFF` at `L55`), splits lines on `/\r\n|\r|\n/`, ignores `:` comment lines, accumulates multi-line `data:` fields joined by `\n`, tracks `id:` (ignoring values containing null bytes `\0` per WHATWG SSE spec at `L95`), updates `retry:` reconnection delay, and releases the reader lock in `finally` on the same tick as `connection.reader = null`.
  3. **Routing & Reconnection (`L184–326`)**: Named SSE events (`detail.message.event`) are dispatched as DOM events on `element` via `htmx.trigger(element, detail.message.event, { data, id })` (and close the stream if matching `hx-sse:close`). Unnamed messages are swapped directly via `await htmx.swap(ctx)` with `swapEmpty:false` appended (`L308–312`). On disconnect, `handleSSEResponse` reconnects with exponential backoff (`reconnectDelay: 500`, `reconnectMaxDelay: 60000`, `reconnectJitter: 0.3`), sending `Last-Event-ID` and pausing when the tab is hidden (`pauseOnBackground`).
- **`src/ext/hx-ws.js` (Registered as `'ws'`)**:
  1. **URL Normalization & Pagehide Cleanup (`L46–77`, `L577–586`)**: `normalizeWebSocketUrl(url)` converts `http://` $\rightarrow$ `ws://`, `https://` $\rightarrow$ `wss://`, protocol-relative `//host/path`, root-relative `/path`, and document-relative paths into full `ws(s)://` URLs. A `window.addEventListener('pagehide', ...)` listener cleanly closes all active sockets with code `1000` on navigation.
  2. **Serialized Promise Chains & Middleware (`connection.receiving` `L190` & `connection.sending` `L333`)**: Incoming WebSocket `message` events are chained onto `connection.receiving = connection.receiving.then(() => handleMessage(...))` so async `waitUntil(promise)` hooks in `htmx:ws:before:message:incoming` and async `htmx.swap()` calls always execute strictly in arrival order. Similarly, `sendMessage` chains onto `connection.sending`, collects `HX-*` headers via `api.createRequestContext`, serializes `FormData` (preserving multi-value arrays for checkboxes/multi-selects) plus `hx-vals` (preserving native JS numbers/booleans in JSON at `L331`), and buffers up to `maxOutgoingMessagesQueueSize: 100` messages while the socket is connecting.
  3. **JSON Envelope vs. Raw HTML Routing (`handleMessage` `L420–462`)**: If an incoming message parses as JSON and contains a `content` (or legacy `payload`) property, `hx-ws` swaps `json.content` using per-message overrides `json.target`, `json.swap`, and `json.select` (falling back to the element's `hx-target` / `hx-swap` / `hx-select` attributes). If the message is non-JSON text, the raw string is swapped directly as HTML; if it is JSON without `content`/`payload`, it is treated as a data-only event payload without triggering a DOM swap.
  4. **Selective Close-Code Reconnection (`L22–30`, `L209`)**: Automatically schedules exponential-backoff reconnection only when the close event code is in `reconnectCodes: [1001, 1005, 1006, 1011, 1012, 1013, 1014]` (skipping normal `1000` closures).

---

Return to the [Architecture Overview](index.md) or review [Chapter 5: Swap, Settle & Morph Engine](05_swap_settle_and_morph_engine.md) to trace how extension-generated tasks flow through DOM insertion and reconciliation.
