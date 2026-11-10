# 4. Fetch Context & Sync Queue

When a synthesized trigger handler fires (as detailed in [Chapter 3](03_trigger_and_selector_parsers.md)), htmx v4.0.1 drives the HTTP lifecycle through a unified mutable **Request Context (`ctx`)** pipeline (`__createRequestContext` -> `__handleTriggerEvent` -> `RequestQueue.admit` -> `__issueRequest`, lines 90–128 and 333–705) backed by native `fetch()`, `AbortController`, and per-element synchronization queues.

```drawlib align=center code=fold file=arch_c04_fetch_pipeline_hero.png caption="htmx v4.0.1 Request Context Compilation, Pre-Flight Serialization, RequestQueue Admission, and fetch() Pipeline"
from drawlib.canvas import save, setup
from drawlib.fonts import FontRoboto, FontSourceCode
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.smartarts import ChevronProcess
from drawlib.styles import Styles
from drawlib.text import text

setup(width=144, height=70)

title_s = Styles.DarkBold.patch(text_size=13.5, text_font=FontRoboto.ROBOTO_BOLD)
sub_s = Styles.Dark.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_REGULAR)
card_title_s = Styles.DarkBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
code_s = Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)
white_title_s = Styles.WhiteBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
white_code_s = Styles.White.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)

text((72, 65.5), "End-to-End HTTP Request Context & Synchronization Pipeline", style=title_s)
text((72, 61.5), "src/htmx.js — __createRequestContext (L386), __handleTriggerEvent (L471), RequestQueue (L90) & __issueRequest (L547)", style=sub_s)

pipeline = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD),
    description_style=Styles.Dark.patch(text_size=10.0, text_font=FontRoboto.ROBOTO_REGULAR),
    corner_angle=60.0,
    spacing=1.5,
    flat_left_end=True,
)
pipeline.add("1. Context Build", description="__createRequestContext()", style=Styles.PrimaryNeutral)
pipeline.add("2. Pre-Flight & Form", description="__handleTriggerEvent()", style=Styles.Neutral)
pipeline.add("3. Sync Admission", description="RequestQueue.admit()", style=Styles.PrimaryFlat,
             text_style=Styles.WhiteBold.patch(text_size=11.0),
             description_style=Styles.White.patch(text_size=10.0))
pipeline.add("4. Fetch & Headers", description="__issueRequest(ctx)", style=Styles.SecondaryNeutral)

pipeline.draw(xy=(6, 43), width=132, height=14)

cards = [
    (21.5, "Context & Security", "L333-430: ctx & request", "Method/Action & #anchor\nAbortController & Headers\nLock ctx.request.mode", Styles.Neutral, False),
    (55.0, "Form & URL Params", "L471-545: FormData", "reportValidity() & vals\nhtmx:config:request\nQuery vs URLSearchParams", Styles.PrimaryNeutral, False),
    (88.5, "6-Mode Sync Queue", "L90-128: _htmx_state.rq", "drop / abort / replace\nqueue first / last / all\ncontinue(abortRequest)", Styles.AccentFlat, True),
    (122.0, "Confirm, Fetch, Status", "L547-639 & L2271", "htmx:confirm & s.rc/s.dc\nctx.fetch() & HX-* hdrs\nhx-status:404/40x/4xx", Styles.Neutral, False),
]

for cx, heading, fn_label, body_txt, box_style, is_focal in cards:
    rectangle((cx, 20.5), width=31.0, height=29.0, style=box_style.patch(shape_r=2.0))
    line((cx, 42.5), (cx, 35.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.5))
    t_style = white_title_s if is_focal else card_title_s
    c_style = white_code_s if is_focal else code_s
    text((cx + 2.2, 30.5), heading, style=t_style)
    text((cx, 25.0), fn_label, style=c_style)
    text((cx, 14.5), body_txt, style=c_style)

phosphor.gear((9.5, 30.5), width=3.8, style=Styles.DarkBold)
phosphor.clipboard_text((43.0, 30.5), width=3.8, style=Styles.DarkBold)
phosphor.arrows_left_right((76.5, 30.5), width=3.8, style=Styles.WhiteBold)
phosphor.cloud_arrow_up((110.0, 30.5), width=3.8, style=Styles.DarkBold)

save()
```

---

## 4.1 Request Context Compilation (`__createRequestContext` & `__determineMethodAndAction`)

Every element initialized by `process()` receives a bound async event handler created by `__createHtmxEventHandler(elt)` (lines 375–384), which wraps `__createRequestContext(elt, evt)` and `await this.__handleTriggerEvent(ctx)` inside a `try / catch` block that routes uncaught exceptions to `htmx:error`.

### Resolving HTTP Method and Action URL (`__determineMethodAndAction`, Lines 333–351)

```javascript
__determineMethodAndAction(elt, evt) {
    let method = this.__attributeValue(elt, "hx-method");
    let action = this.__attributeValue(elt, "hx-action", undefined, undefined, false);
    if (!action) {
        for (let verb of this.#verbs) {
            let verbAction = this.__attributeValue(elt, "hx-" + verb, undefined, undefined, false);
            if (verbAction != null) {
                action = verbAction;
                method = verb;
                break;
            }
        }
    }
    if (this.__isBoosted(elt)) {
        action ||= evt.submitter?.getAttribute?.("formAction") || elt.getAttribute(elt.matches("a") ? "href" : "action");
    }
    method ||= evt.submitter?.getAttribute?.("formmethod") || elt.getAttribute("method") || "GET";
    return {action, method: method.toUpperCase()};
}
```

1. **Explicit `hx-action` + `hx-method` vs. Shorthand Verb Attributes**: htmx first checks `hx-action` (with `allowInheritance = false`). If absent, it iterates through `this.#verbs` (`["get", "post", "put", "patch", "delete", "query"]` at line 143) and selects the first matching `hx-<verb>` attribute on `elt` (unless explicitly inherited via `:inherited`). Notice that htmx v4 natively includes the HTTP `QUERY` verb alongside the classic five REST verbs.
2. **Boosted Element Fallbacks (`__isBoosted(elt)`)**: When an `<a>` or `<form>` has `elt._htmx.boosted` set by `__maybeBoost` (line 968), `action` falls back to `evt.submitter?.getAttribute?.("formAction")` or the element's native `href` / `action` attribute.
3. **Method Precedence**: If `method` was not determined by `hx-method` or `hx-<verb>`, it falls back to `evt.submitter?.getAttribute?.("formmethod")`, then `elt.getAttribute("method")`, and finally `"GET"`, normalized via `.toUpperCase()`.

### Building `ctx` and Enforcing the `hx-config` Security Invariant (Lines 386–430)

```javascript
__createRequestContext(sourceElement, sourceEvent) {
    let {action, method} = this.__determineMethodAndAction(sourceElement, sourceEvent);
    let [fullAction, anchor] = (action || '').split('#');
    let ac = new AbortController();
    let ctx = {
        sourceElement,
        sourceEvent,
        status: "created",
        select: this.__attributeValue(sourceElement, "hx-select"),
        selectOOB: this.__attributeValue(sourceElement, "hx-select-oob"),
        target: this.__attributeValue(sourceElement, "hx-target"),
        swap: this.__attributeValue(sourceElement, "hx-swap") ?? this.config.defaultSwap,
        push: this.__attributeValue(sourceElement, "hx-push-url"),
        replace: this.__attributeValue(sourceElement, "hx-replace-url"),
        transition: this.config.transitions,
        confirm: this.__attributeValue(sourceElement, "hx-confirm"),
        request: {
            validate: "true" === this.__attributeValue(sourceElement, "hx-validate",
                sourceElement.matches('form') && !sourceElement.noValidate && !sourceEvent.submitter?.formNoValidate ? "true" : "false",
                undefined, false),
            action: fullAction,
            anchor,
            method,
            headers: this.__createCoreHeaders(sourceElement),
            abort: ac.abort.bind(ac),
            credentials: "same-origin",
            signal: ac.signal,
            mode: this.config.mode
        }
    };
    if (sourceElement._htmx?.boosted) {
        HCON.merge(sourceElement._htmx.boosted, ctx);
    }
    ctx.target = this.__resolveTarget(sourceElement, ctx.target);
    if (ctx.target) {
        ctx.request.headers["HX-Target"] = this.__buildIdentifier(ctx.target);
    }
    let hxConfig = this.__attributeValue(sourceElement, "hx-config");
    if (hxConfig) {
        HCON.merge(hxConfig, ctx.request);
        ctx.request.mode = this.config.mode;  // mode is security-sensitive, never allow per-element override
    }
    return ctx;
}
```

- **Anchor Stripping (`#anchor`, line 388)**: `(action || '').split('#')` separates the URL fragment into `ctx.request.anchor` before `fetch()` is called; after the DOM swap finishes, `__handleAnchorScroll(ctx)` (lines 1226–1230) scrolls `document.getElementById(ctx.request.anchor)` into view.
- **Core Request Headers (`__createCoreHeaders`, lines 436–447)**:
  - `HX-Request: "true"`
  - `HX-Source`: `tagName.toLowerCase()` plus `#${encodeURI(elt.id)}` if `elt.id` is present (`__buildIdentifier` at lines 432–434).
  - `HX-Current-URL`: `location.href`
  - `Accept: "text/html"`
  - `HX-Boosted: "true"` (when `this.__isBoosted(elt)` is truthy)
  - `HX-Target`: `this.__buildIdentifier(ctx.target)` added at line 420 after `__resolveTarget` resolves `ctx.target` (defaulting to `document.body` for boosted elements or `sourceElement` otherwise).
  - `HX-Request-Type`: `"full"` if `ctx.target === document.body || ctx.select`, or `"partial"` otherwise (computed right before `fetch()` at line 585 after all config hooks have run).
- **Boost & `hx-config` HCON Overrides (lines 415–428)**:
  - Because `hx-boost` in htmx v4 accepts an HCON specification (e.g., `hx-boost="swap:outerMorph push:false"`), line 416 merges `sourceElement._htmx.boosted` directly into `ctx` *before* resolving `ctx.target`.
  - Next, `hx-config` is merged into `ctx.request` via `HCON.merge(hxConfig, ctx.request)` (allowing per-element `timeout`, `credentials`, etc.), followed immediately by `ctx.request.mode = this.config.mode` (line 427). This **security invariant** prevents untrusted or injected `hx-config="mode:cors"` attributes from escalating `htmx.config.mode` (which defaults to `'same-origin'`).

---

## 4.2 Form Data Collection & Pre-Flight Pipeline (`__handleTriggerEvent` & `__collectFormData`)

Once `ctx` is constructed, `__handleTriggerEvent(ctx)` (lines 471–545) validates inputs, assembles parameters, evaluates dynamic `hx-vals` and `hx-headers`, and dispatches `htmx:config:request`:

### Enclosing Form Rule, HTML5 Validation & Input Serialization (Lines 481–491 & 1807–1873)

1. **The Enclosing Form Rule (lines 481–487)**:
   ```javascript
   let usesQueryParams = /GET|DELETE/.test(ctx.request.method);
   let form = usesQueryParams
       ? (elt.matches('form') ? elt : null)
       : (elt.form || elt.closest("form"))
   ```
   For `GET` and `DELETE` requests, htmx only serializes a `<form>` if the triggered element **is itself** the `<form>` (`elt.matches('form')`). In contrast, state-mutating / payload verbs (`POST`, `PUT`, `PATCH`, `QUERY`) automatically locate and serialize any enclosing form via `elt.form || elt.closest("form")`.
2. **HTML5 Constraint Validation (`__collectFormData`, lines 1807–1831)**:
   - When `ctx.request.validate` is `true` (defaulting to `true` on `<form>` without `novalidate` or `submitter.formNoValidate`), htmx invokes `form.reportValidity()` (or `elt.reportValidity()` / `node.reportValidity()` on `hx-include` targets). If validation fails, `__collectFormData` returns `undefined` and `__handleTriggerEvent` aborts cleanly at line 491.
   - **Submitter Self-Inclusion (`#4073`, line 1811)**: When a `<button type="submit" name="cmd" value="save" hx-post="/save">` inside a form triggers its own `click` handler rather than a `submit` event, `evt.submitter` is undefined. Line 1811 sets `submitter ??= (form && elt.type === 'submit') ? elt : null`, ensuring the button's `name=value` pair is appended to `formData` (lines 1819–1822).
3. **Deduplicated Input Harvesting (`__addInputValues`, lines 1833–1873)**:
   - Maintains an `included = new Set(...)` initialized with `form.elements` so no input is serialized twice when `hx-include` overlaps with the enclosing form.
   - **Custom Elements & Buttons (line 1836)**: If `tag === 'BUTTON' || tag.includes('-')` (any Web Component custom element), htmx treats `elt` as a single atomic control (`inputs = [elt]`) rather than querying internal `[name]` descendants. Furthermore, if `Array.isArray(input.value)` (line 1864), each array element is appended individually to `FormData`.
   - **Non-Form Containers on `GET` vs `POST` (line 1838)**: If `elt` is a `<div>` without a form, `GET` sends no child inputs (`!isGet` is false), whereas `POST` on a non-`body` container collects `this.__queryEltAndDescendants(elt, '[name]:not(button)')`.
   - Standard HTML controls handle `checkbox`/`radio` (including custom elements with `'checked' in input`), `input[type="file"]` (`input.files`), and `select-multiple` (`input.selectedOptions`).

### Conditional Async `hx-vals` / `hx-headers` and Action Interception (Lines 492–544)

- **Zero-Microtask HCON Fast Path (`__getAttributeObject`, lines 1875–1893)**: Both `hx-vals` and `hx-headers` are parsed via `__getAttributeObject`. When the attribute has no `js:` or `javascript:` prefix, it parses synchronously via `HCON.parse(hxAttr)` and returns `undefined`; `__handleTriggerEvent` checks `if (valsResult) await valsResult` (line 496) and `if (headersResult) await headersResult` (line 506) so static HCON values never yield to the Promise microtask queue.
- **Pre-Flight Escape Hatches (lines 515–522)**:
  1. `if (!this.__trigger(elt, "htmx:config:request", {ctx: ctx})) return` — Extensions or listeners can mutate `ctx.request` or call `evt.preventDefault()` to cancel.
  2. `if (ctx.request.method === 'DIALOG') return` — Allows native `<form method="dialog">` to close `<dialog>` elements without firing a network request.
  3. **`js:` / `javascript:` Action URLs (lines 518–522)**: If `ctx.request.action` starts with `js:` or `javascript:`, htmx converts `ctx.request.body` into a plain object via `Object.fromEntries(ctx.request.body)`, awaits `this.__executeJavaScript(ctx.sourceElement, data, javascriptContent, false)`, and returns without touching the network.
- **Query String vs Body Encoding (lines 523–542)**:
  - For `GET` and `DELETE` (`usesQueryParams`), parameters in `ctx.request.body` replace matching keys in `url.searchParams` (`url.searchParams.delete(key)` followed by `append`). If `url.origin === location.origin`, `ctx.request.action` is kept as a relative path (`url.pathname + url.search`), and `ctx.request.body` is set to `null`.
  - For other verbs, unless `hx-encoding` or `form.enctype` is `"multipart/form-data"`, `ctx.request.body` (`FormData`) is converted into `new URLSearchParams(ctx.request.body)` (`application/x-www-form-urlencoded`).

---

## 4.3 The `RequestQueue` Admission State Machine (`class RequestQueue` & `hx-sync`)

When `__handleTriggerEvent` calls `__issueRequest(ctx)` (line 547), htmx resolves the element's synchronization queue via `__determineSyncStrategy(elt)` and `__getRequestQueue(elt)` (lines 688–705) and gates execution on `requestQueue.admit(...)` (lines 90–128).

```drawlib align=center code=fold file=arch_c04_request_queue_matrix.png caption="RequestQueue State Machine (L90-128) and hx-sync Admission Strategies"
from drawlib.canvas import save, setup
from drawlib.fonts import FontRoboto, FontSourceCode
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.smartarts import Table
from drawlib.styles import Colors, Styles
from drawlib.text import text

setup(width=144, height=84)

title_s = Styles.DarkBold.patch(text_size=13.5, text_font=FontRoboto.ROBOTO_BOLD)
sub_s = Styles.Dark.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_REGULAR)
hdr_s = Styles.DarkBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
code_s = Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)
white_hdr_s = Styles.WhiteBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
white_code_s = Styles.White.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)

text((72, 79.5), "class RequestQueue (L90-128) & hx-sync Admission State Machine", style=title_s)
text((72, 75.5), "Scoped per syncElt via this.__htmxState(syncElt).rq ||= new RequestQueue() (L695-705)", style=sub_s)

# Top Row: 3 State Machine Lifecycles
rectangle((26, 62), width=40, height=13, style=Styles.Neutral.patch(shape_r=2.0))
text((26, 65.2), "1. Idle Slot (!#current)", style=hdr_s)
text((26, 59.5), "#current = {strategy, abort}\nreturn 'run' (L96-99)", style=code_s)

rectangle((72, 62), width=42, height=13, style=Styles.PrimaryFlat.patch(shape_r=2.0))
text((72, 65.2), "2. Busy Slot (#current != null)", style=white_hdr_s)
text((72, 59.5), "Evaluate 6 hx-sync strategies\nreturn 'run' | 'queued' | 'dropped'", style=white_code_s)

rectangle((118, 62), width=40, height=13, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
text((118, 65.2), "3. finally: continue(abort)", style=hdr_s)
text((118, 59.5), "if (#current.abort === abort)\n#current=null; #queue.shift()()", style=code_s)

line((46.5, 62), (50.5, 62), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))
line((93.5, 62), (97.5, 62), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))

# Bottom Table: 6 Strategies in RequestQueue.admit() when #current is active
data = [
    ["hx-sync Strategy", "Condition Checked (L100-115)", "Queue & Abort Mutation", "Return"],
    ["replace", "strategy === 'replace'", "#queue=[]; #current.abort()", "'run'"],
    ["non-abort vs abort", "strategy!=='abort' && cur==='abort'", "#queue=[]; #current.abort()", "'run'"],
    ["queue all", "strategy === 'queue all'", "#queue.push(runRequest)", "'queued'"],
    ["queue last", "strategy === 'queue last'", "#queue = [runRequest]", "'queued'"],
    ["queue first (default)", "not abort/drop && #queue.length===0", "#queue.push(runRequest)", "'queued'"],
    ["drop / busy abort", "All other busy cases (L114)", "No mutation (discarded)", "'dropped'"],
]

tbl = Table(
    cell_style=Styles.White,
    text_style=Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO),
    header_cell_style=Styles.AccentFlat,
    header_text_style=Styles.WhiteBold.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_BOLD),
    border_style=Styles.Neutral.patch(line_width=1.0),
    has_header=True,
)
tbl.set_style_cell_evenodd(
    even_color=Colors.White,
    even_text_style=Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO),
    odd_color=Colors.Light,
    odd_text_style=Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO),
)
tbl.set_style_cell_header(
    background_color=Colors.Accent,
    text_style=Styles.WhiteBold.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_BOLD),
)
tbl.draw_flexible(
    xy=(6.0, 52.0),
    column_widths=[30.0, 44.0, 40.0, 18.0],
    row_heights=[6.8, 6.5, 6.5, 6.5, 6.5, 6.5, 6.5],
    data=data,
    align="top_left",
)

save()
```

### Scoping `RequestQueue` via `hx-sync` (Lines 688–705)

`hx-sync` accepts three syntactic forms:

1. **Strategy only (`hx-sync="replace"`)**: `__getRequestQueue` sees that `hxSync` matches `/^(drop|abort|replace|queue)/`, keeps `syncElt = elt`, and `__determineSyncStrategy` returns `"replace"`.
2. **Selector only (`hx-sync="closest form"`)**: `__getRequestQueue` resolves `syncElt = this.__findOrWarn(elt, "closest form", "hx-sync") || elt`, while `__determineSyncStrategy` falls back to the default `"queue first"`.
3. **Selector + Strategy (`hx-sync="#search-form:abort"`)**: Splits on the **last** colon (`hxSync.lastIndexOf(":")`) so CSS pseudo-classes inside the selector (e.g., `form:first-of-type:replace`) remain intact! The `RequestQueue` instance is lazily created on `this.__htmxState(syncElt).rq ||= new RequestQueue()`.

### The `RequestQueue` Implementation (Lines 90–128)

```javascript
class RequestQueue {
    #current = null
    #queue = []

    /** Returns "run", "queued", or "dropped" */
    admit(strategy, runRequest, abortRequest) {
        if (!this.#current) {
            this.#current = {strategy, abort: abortRequest}
            return "run"
        }
        if (strategy === "replace" || (strategy !== "abort" && this.#current.strategy === "abort")) {
            this.#queue = []
            this.#current.abort?.()
            this.#current = {strategy, abort: abortRequest}
            return "run"
        }
        if (strategy === "queue all") {
            this.#queue.push(runRequest)
        } else if (strategy === "queue last") {
            this.#queue = [runRequest]
        } else if (strategy !== "abort" && strategy !== "drop" && this.#queue.length === 0) {
            // default queue first
            this.#queue.push(runRequest)
        } else {
            return "dropped"
        }
        return "queued"
    }

    continue(abortRequest) {
        if (this.#current?.abort !== abortRequest) return
        this.#current = null    // free current slot
        this.#queue.shift()?.() // run next request
    }

    abort() {
        this.#current?.abort?.()
    }
}
```

Two subtle concurrency guarantees in `RequestQueue` deserve special attention:

- **Asymmetric `abort` Preemption (line 100)**: When an element specifies `hx-sync="closest form:abort"` (such as an autosave or background validation input inside a form), its in-flight request is tagged with `this.#current.strategy === "abort"`. If another `abort` request arrives while `#current` is active, it falls through to line 114 and returns `"dropped"`. However, if the user submits the form with the default `"queue first"` strategy (`strategy !== "abort" && this.#current.strategy === "abort"`), line 100 **immediately aborts the in-flight `abort` request and runs the form submission right away** instead of queuing behind the background check!
- **Ownership-Verified Slot Release (`continue(abortRequest)`, lines 119–123)**: When an aborted request's `fetch()` rejects and enters its `finally` block (line 637), a `replace` request may have *already* taken ownership of `this.#current`. By comparing `if (this.#current?.abort !== abortRequest) return`, the replaced request's `finally` block is prevented from clearing the new request's `#current` slot or prematurely shifting `#queue`.

---

## 4.4 Async `htmx:confirm`, Ref-Counted Indicators, `fetch()` & Status Routing (`__issueRequest`)

Once `requestQueue.admit(syncStrategy, () => this.__issueRequest(ctx), abortRequest)` returns `"run"` (lines 555–559), `__issueRequest(ctx)` transitions `ctx.status = "issuing"` and executes the network and response header pipeline.

```drawlib align=center code=fold file=arch_c04_issue_request_sequence.png caption="__issueRequest() Execution Flow (L547-639), Ref-Counted Indicators, and Hierarchical Status Code Routing"
from drawlib.canvas import save, setup
from drawlib.fonts import FontRoboto, FontSourceCode
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=144, height=82)

title_s = Styles.DarkBold.patch(text_size=13.5, text_font=FontRoboto.ROBOTO_BOLD)
sub_s = Styles.Dark.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_REGULAR)
hdr_s = Styles.DarkBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
code_s = Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)
white_hdr_s = Styles.WhiteBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
white_code_s = Styles.White.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)

text((72, 77.5), "__issueRequest(ctx) Lifecycle, HX-* Headers & Status Code Routing", style=title_s)
text((72, 73.5), "Runs only after RequestQueue.admit() === 'run'; guarantees cleanup and queue advancement in finally (L623-638)", style=sub_s)

# Row 1: Pre-Fetch (Left -> Center -> Right)
rectangle((26, 59), width=40, height=16, style=Styles.Neutral.patch(shape_r=2.0))
text((26, 64.0), "1. Async Confirm (L567)", style=hdr_s)
text((26, 56.8), "htmx:confirm {issueRequest}\njs: __executeJavaScript()\nelse window.confirm()", style=code_s)

rectangle((72, 59), width=40, height=16, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
text((72, 64.0), "2. Timeout & Ref-Counts", style=hdr_s)
text((72, 56.8), "__initTimeout (abort('timeout'))\n__showIndicators: ++s.rc\n__disableElements: ++s.dc", style=code_s)

rectangle((118, 59), width=40, height=16, style=Styles.PrimaryFlat.patch(shape_r=2.0))
text((118, 64.0), "3. Network Fetch (L583)", style=white_hdr_s)
text((118, 56.8), "HX-Request-Type: full|partial\nhtmx:before:request\nawait ctx.fetch(action, req)", style=white_code_s)

line((46.5, 59), (51.5, 59), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))
line((92.5, 59), (97.5, 59), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))

# Row 2: Response Processing (Right -> Center -> Left)
line((118, 50.5), (118, 45.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))

rectangle((118, 36.5), width=40, height=17, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
text((118, 42.0), "4. Extract & Read Body", style=hdr_s)
text((118, 34.0), "__extractHxHeaders -> ctx.hx\nhtmx:before:response\nctx.text = await resp.text()\nhtmx:after:request / :error", style=code_s)

rectangle((72, 36.5), width=40, height=17, style=Styles.Neutral.patch(shape_r=2.0))
text((72, 42.0), "5. Early-Return Headers", style=hdr_s)
text((72, 34.0), "HX-Refresh -> _loc.reload()\nHX-Redirect -> _loc.href\nHX-Location -> this.ajax()\nsets ctx.keepIndicators=true", style=code_s)

rectangle((26, 36.5), width=40, height=17, style=Styles.AccentFlat.patch(shape_r=2.0))
text((26, 42.0), "6. Overrides & Status", style=white_hdr_s)
text((26, 34.0), "HX-Retarget/Reswap/Reselect\n__handleStatusCodes (L2271)\n[404, 40x, 4xx] -> HCON.merge\nawait this.swap(ctx)", style=white_code_s)

line((97.5, 36.5), (92.5, 36.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))
line((51.5, 36.5), (46.5, 36.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))

# Row 3: Finally Block (Full Width)
line((26, 27.5), (26, 21.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))

rectangle((72, 13.0), width=132, height=16, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
text((72, 17.8), "7. Guaranteed finally Block (L623-638)", style=hdr_s)
text((72, 10.2), "await ctx.extensionPromise  |  clearTimeout(ctx.requestTimeout)  |  if (ctx.hx?.trigger) __handleTriggerHeader()\nhtmx:finally:request  |  if (!ctx.keepIndicators) { --s.rc; --s.dc }  |  requestQueue.continue(abortRequest)", style=code_s)

save()
```

### Why `htmx:confirm`, Timeouts, and Indicators Run After Queue Admission

1. **Async Confirmation (`ctx.confirm`, lines 567–576)**:
   ```javascript
   if (ctx.confirm) {
       let confirmed = await new Promise(resolve => {
           let detail = {ctx, issueRequest: () => resolve(true), dropRequest: () => resolve(false)};
           if (this.__trigger(elt, "htmx:confirm", detail)) {
               let js = this.__extractJavascriptContent(ctx.confirm);
               resolve(js ? this.__executeJavaScript(elt, {ctx}, js, true) : window.confirm(ctx.confirm));
           }
       });
       if (!confirmed) return;
   }
   ```
   Because `htmx:confirm` runs *after* `requestQueue.admit()` returns `"run"`, queued requests never pop up overlapping confirmation dialogs simultaneously. Custom modal listeners can call `evt.preventDefault()` on `htmx:confirm` and later invoke `evt.detail.issueRequest()` or `evt.detail.dropRequest()` asynchronously; if `confirmed` is `false`, the `finally` block still runs `requestQueue.continue(abortRequest)` to unblock the next queued request.
2. **Timeout Timer (`__initTimeout`, lines 679–686)**: Starts *after* confirmation resolves (`ctx.requestTimeout = setTimeout(() => ctx.request?.abort?.('timeout'), timeout)`), so time spent by the user reading a confirmation dialog never counts against `defaultTimeout` (`60000ms`). Notice in `catch (error)` (line 622) that normal `AbortError` cancellations are silent, whereas `ctx.request.signal.reason === 'timeout'` explicitly dispatches `htmx:error`.
3. **Reference-Counted Indicators & Disabled Elements (`s.rc` & `s.dc`, lines 1757–1805)**:
   - `__showIndicators(ctx)` resolves `hx-indicator` (or `[elt]` when omitted and `elt !== document.body`), increments `this.__htmxState(indicator).rc = (s.rc || 0) + 1`, and adds `htmx-request`.
   - `__disableElements(ctx)` resolves `hx-disable`, increments `this.__htmxState(el).dc = (s.dc || 0) + 1`, and sets `el.disabled = true`.
   - In `finally`, `__hideIndicators` and `__enableElements` decrement `--s.rc` and `--s.dc`, only removing `htmx-request` or restoring `disabled = false` when the reference count reaches `<= 0` (so concurrent requests sharing a global spinner never flicker).

### Response Header Normalization (`__extractHxHeaders`) & Early-Return Redirects

Immediately after `let response = await ctx.fetch(ctx.request.action, ctx.request)` resolves (line 588), `__extractHxHeaders(ctx)` (lines 643–650) scans `ctx.response.raw.headers` for any header starting with `hx-`, strips the `hx-` prefix and hyphens, and stores it in lowercase on `ctx.hx`:

| HTTP Response Header | `ctx.hx` Property | Processing Stage & Behavior (`src/htmx.js`) |
| :--- | :--- | :--- |
| `HX-Refresh: true` | `ctx.hx.refresh` | `__handleHeadersAndMaybeReturnEarly` (L655): Calls `this._loc.reload()`, sets `ctx.keepIndicators = true`, and skips swap. |
| `HX-Redirect: <url>` | `ctx.hx.redirect` | `__handleHeadersAndMaybeReturnEarly` (L659): Sets `this._loc.href = ctx.hx.redirect`, sets `ctx.keepIndicators = true`, and skips swap. |
| `HX-Location: <spec>` | `ctx.hx.location` | `__handleHeadersAndMaybeReturnEarly` (L663): Parses HCON or string path, forwards `ctx.indicators` and `ctx.disabledElements` into `opts`, invokes `this.ajax('GET', path, opts)`, and sets `ctx.keepIndicators = true` so the follow-up `ajax()` call inherits the active indicators seamlessly. |
| `HX-Retarget: <sel>` | `ctx.hx.retarget` | Pre-swap override (L610): Sets `ctx.target = ctx.hx.retarget` (resolved later in `__processMainSwap`). |
| `HX-Reswap: <spec>` | `ctx.hx.reswap` | Pre-swap override (L611): Sets `ctx.swap = ctx.hx.reswap`. |
| `HX-Reselect: <sel>` | `ctx.hx.reselect` | Pre-swap override (L612): Sets `ctx.select = ctx.hx.reselect`. |
| `HX-Push-Url` / `HX-Replace-Url` | `ctx.hx.pushurl` / `ctx.hx.replaceurl` | Consumed during `swap(ctx)` in `__handleHistoryUpdate(ctx)` (covered in [Chapter 5](05_swap_settle_and_morph_engine.md)). |
| `HX-Trigger: <spec>` | `ctx.hx.trigger` | Executed in `finally` (L628–630) via `__handleTriggerHeader(ctx.hx.trigger, ctx.sourceElement)` (L874–888), supporting both comma-separated event names and HCON objects (`{myEvent: {level: "info", target: "#toast"}}`). |

### Hierarchical Status Code Routing (`__handleStatusCodes`, Lines 2271–2286)

Right before calling `await this.swap(ctx)` (line 616), htmx invokes `__handleStatusCodes(ctx)` to apply declarative HTTP status code rules:

```javascript
__handleStatusCodes(ctx) {
    let status = ctx.response.raw.status;
    let noSwapStrings = this.config.noSwap.map(x => x + "");
    let str = status + ""
    for (let pattern of [str, str.slice(0, 2) + 'x', str[0] + 'xx']) {
        if (noSwapStrings.includes(pattern)) {
            ctx.swap = "none";
            return
        }
        let statusValue = this.__attributeValue(ctx.sourceElement, "hx-status:" + pattern);
        if (statusValue) {
            HCON.merge(statusValue, ctx);
            return;
        }
    }
}
```

1. **3-Tier Specificity Cascade (`[str, str.slice(0, 2) + 'x', str[0] + 'xx']`)**: For a status code such as `404`, htmx checks patterns in order of decreasing specificity: exact `"404"`, decade wildcard `"40x"`, and class wildcard `"4xx"`.
2. **`config.noSwap` Matching**: At each specificity tier, htmx first checks `this.config.noSwap` (which defaults to `[204, 304]` at line 203). If matched, `ctx.swap = "none"` is set and the loop returns immediately.
3. **Full Context Mutation via `HCON.merge(statusValue, ctx)`**: If the element (or an ancestor via `:inherited`) defines `hx-status:<pattern>` (for example, `hx-status:422="target:#form-errors swap:innerHTML select:#errors"` or `hx-status:5xx="swap:none confirm:false"`), htmx merges that HCON specification directly into the top-level `ctx` object and returns before handing `ctx` to `await this.swap(ctx)` (covered in [Chapter 5](05_swap_settle_and_morph_engine.md)).
