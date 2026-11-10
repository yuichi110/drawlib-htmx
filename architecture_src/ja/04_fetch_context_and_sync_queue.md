# 4. Fetchコンテキストと同期キュー

（[第3章](03_trigger_and_selector_parsers.md)で詳述した）合成トリガーハンドラが発火すると、htmx v4.0.1はネイティブの `fetch()`・`AbortController`・要素単位の同期キューを基盤とする単一の可変オブジェクト **Request Context（`ctx`）** パイプライン（`__createRequestContext` -> `__handleTriggerEvent` -> `RequestQueue.admit` -> `__issueRequest`、90〜128行目および333〜705行目）を通じてHTTPライフサイクル全体を駆動します。

```drawlib align=center code=fold file=arch_c04_fetch_pipeline_hero.png caption="htmx v4.0.1 リクエストコンテキスト構築・プリフライト直列化・RequestQueue入場制御・fetch()パイプライン"
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

## 4.1 リクエストコンテキストのコンパイル（`__createRequestContext` と `__determineMethodAndAction`）

`process()` によって初期化された各要素には、`__createHtmxEventHandler(elt)`（375〜384行目）が生成した非同期イベントハンドラがバインドされます。このハンドラは `try / catch` ブロック内で `__createRequestContext(elt, evt)` と `await this.__handleTriggerEvent(ctx)` を実行し、未捕捉の例外を `htmx:error` イベントへとルーティングします。

### HTTPメソッドとアクションURLの解決（`__determineMethodAndAction`、333〜351行目）

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

1. **明示的な `hx-action` + `hx-method` と動詞ショートハンド属性**: htmx はまず `hx-action` を（`allowInheritance = false` で）確認します。未指定の場合は `this.#verbs`（143行目の `["get", "post", "put", "patch", "delete", "query"]`）を順番に走査し、最初に一致した `hx-<verb>` 属性から `action` と `method` を決定します。htmx v4 では従来の5つのRESTメソッドに加え、HTTP `QUERY` メソッドがネイティブに組み込まれています。
2. **ブースト要素のフォールバック（`__isBoosted(elt)`）**: `__maybeBoost`（968行目）によって `elt._htmx.boosted` が設定された `<a>` や `<form>` では、`action` は `evt.submitter?.getAttribute?.("formAction")` または要素自身の `href` / `action` 属性へとフォールバックします。
3. **メソッド決定の優先順位**: `hx-method` または `hx-<verb>` でメソッドが決まらなかった場合、`evt.submitter?.getAttribute?.("formmethod")` -> `elt.getAttribute("method")` -> `"GET"` の順にフォールバックし、`.toUpperCase()` で大文字に正規化されます。

### `ctx` の構築と `hx-config` セキュリティ不変条件の強制（386〜430行目）

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

- **アンカーの分離（`#anchor`、388行目）**: `(action || '').split('#')` によって `fetch()` 呼び出し前にURLフラグメントを `ctx.request.anchor` へ分離します。DOMスワップ完了後、`__handleAnchorScroll(ctx)`（1226〜1230行目）が `document.getElementById(ctx.request.anchor)` をスクロール表示します。
- **コアリクエストヘッダ（`__createCoreHeaders`、436〜447行目）**:
  - `HX-Request: "true"`
  - `HX-Source`: `tagName.toLowerCase()` に加え、`elt.id` が存在する場合は `#${encodeURI(elt.id)}` を連結します（432〜434行目の `__buildIdentifier`）。
  - `HX-Current-URL`: `location.href`
  - `Accept: "text/html"`
  - `HX-Boosted: "true"`（`this.__isBoosted(elt)` が真の場合）
  - `HX-Target`: `__resolveTarget` が `ctx.target`（ブースト時は `document.body`、通常時は `sourceElement` がデフォルト）を解決した直後の420行目で `this.__buildIdentifier(ctx.target)` を設定します。
  - `HX-Request-Type`: `ctx.target === document.body || ctx.select` の場合は `"full"`、それ以外は `"partial"`（すべての設定フックが完了した後の `fetch()` 直前、585行目で設定）。
- **ブーストおよび `hx-config` による HCON オーバーライド（415〜428行目）**:
  - htmx v4 の `hx-boost` は HCON 仕様（例: `hx-boost="swap:outerMorph push:false"`）を受け付けるため、416行目で `ctx.target` 解決前に `sourceElement._htmx.boosted` を `ctx` にマージします。
  - 続いて、`hx-config` を `HCON.merge(hxConfig, ctx.request)` で `ctx.request` にマージし（要素単位の `timeout` や `credentials` などの上書きを許可）、その直後の427行目で `ctx.request.mode = this.config.mode` を再代入します。この **セキュリティ不変条件** により、信頼できないマークアップに注入された `hx-config="mode:cors"` がグローバルの CORS モード（デフォルトは `'same-origin'`）を昇格させることを防ぎます。

---

## 4.2 フォームデータ収集とプリフライトパイプライン（`__handleTriggerEvent` と `__collectFormData`）

`ctx` が生成されると、`__handleTriggerEvent(ctx)`（471〜545行目）が入力値の検証・パラメータ収集・動的な `hx-vals` / `hx-headers` の評価・`htmx:config:request` の発火を行います。

### 外包フォーム規則・HTML5バリデーション・入力値直列化（481〜491行目・1807〜1873行目）

1. **外包フォーム（Enclosing Form）規則（481〜487行目）**:
   ```javascript
   let usesQueryParams = /GET|DELETE/.test(ctx.request.method);
   let form = usesQueryParams
       ? (elt.matches('form') ? elt : null)
       : (elt.form || elt.closest("form"))
   ```
   `GET` および `DELETE` リクエストでは、トリガー発生元の要素 **自身が `<form>` である場合**（`elt.matches('form')`）にのみフォーム全体を直列化します。一方、状態変更やボディ伴うメソッド（`POST`・`PUT`・`PATCH`・`QUERY`）では、`elt.form || elt.closest("form")` によって自動的に外包 `<form>` を特定して直列化します。
2. **HTML5制約バリデーション（`__collectFormData`、1807〜1831行目）**:
   - `ctx.request.validate` が `true` の場合（`novalidate` や `submitter.formNoValidate` のない `<form>` ではデフォルトで `true`）、`form.reportValidity()`（および `elt` や `hx-include` 対象ノードの `.reportValidity()`）を実行します。検証に失敗すると `__collectFormData` は `undefined` を返し、491行目でリクエストが安全に中断されます。
   - **送信ボタン自身の値含有（`#4073`、1811行目）**: フォーム内の `<button type="submit" name="cmd" value="save" hx-post="/save">` が `submit` ではなく自身の `click` で発火した場合、`evt.submitter` は未定義になります。1811行目の `submitter ??= (form && elt.type === 'submit') ? elt : null` により、送信ボタン自身の `name=value` ペアも確実に `formData` に追加されます（1819〜1822行目）。
3. **重複排除付きの入力値収集（`__addInputValues`、1833〜1873行目）**:
   - `form.elements` で初期化した `included = new Set(...)` を保持するため、`hx-include` が外包フォームと重複していても同じ入力要素が二重送信されることはありません。
   - **カスタム要素とボタン（1836行目）**: `tag === 'BUTTON' || tag.includes('-')`（ハイフンを含むすべての Web Component カスタム要素）の場合、内部の `[name]` 子孫を探索せず要素自身のみ（`inputs = [elt]`）を対象とします。さらに `Array.isArray(input.value)`（1864行目）の場合は配列の各要素を個別に `FormData` へ追加します。
   - **非フォームコンテナにおける `GET` と `POST` の違い（1838行目）**: `elt` がフォーム外の `<div>` などの場合、`GET` では子孫入力を収集しませんが、`body` 以外のコンテナ上の `POST` では `this.__queryEltAndDescendants(elt, '[name]:not(button)')` を収集します。
   - 標準コントロールについては、`checkbox`/`radio`（`'checked' in input` を持つカスタム要素を含む）、`input[type="file"]`（`input.files`）、`select-multiple`（`input.selectedOptions`）をそれぞれ適切に展開します。

### 条件付き非同期 `hx-vals` / `hx-headers` とアクション横取り（492〜544行目）

- **マイクロタスクを発生させない HCON 高速経路（`__getAttributeObject`、1875〜1893行目）**: `hx-vals` と `hx-headers` はともに `__getAttributeObject` で処理されます。属性値に `js:` または `javascript:` プレフィックスがない場合、`HCON.parse(hxAttr)` で同期的に解析して `undefined` を返し、`__handleTriggerEvent` 側は `if (valsResult) await valsResult`（496行目）および `if (headersResult) await headersResult`（506行目）と判定するため、静的な HCON では Promise のマイクロタスク待機が一切発生しません。
- **プリフライトの脱出ハッチ（515〜522行目）**:
  1. `if (!this.__trigger(elt, "htmx:config:request", {ctx: ctx})) return` — 拡張機能やリスナーが `ctx.request` を書き換えたり `evt.preventDefault()` で送信を中止できます。
  2. `if (ctx.request.method === 'DIALOG') return` — ネイティブの `<form method="dialog">` がネットワーク通信を行わずに `<dialog>` を閉じられるようにします。
  3. **`js:` / `javascript:` アクションURL（518〜522行目）**: `ctx.request.action` が `js:` または `javascript:` で始まる場合、`Object.fromEntries(ctx.request.body)` でフォームデータをオブジェクトに変換し、`await this.__executeJavaScript(ctx.sourceElement, data, javascriptContent, false)` を実行してネットワーク通信なしで終了します。
- **クエリ文字列とリクエストボディの直列化（523〜542行目）**:
  - `GET` および `DELETE`（`usesQueryParams`）では、`ctx.request.body` の各キーで既存の `url.searchParams` を上書き（`delete(key)` 後に `append`）します。同一オリジン（`url.origin === location.origin`）であれば `ctx.request.action` を相対パス（`url.pathname + url.search`）に保ち、`ctx.request.body = null` とします。
  - その他のメソッドでは、`hx-encoding` または `form.enctype` が `"multipart/form-data"` でない限り、`ctx.request.body`（`FormData`）を `new URLSearchParams(ctx.request.body)`（`application/x-www-form-urlencoded`）に変換します。

---

## 4.3 `RequestQueue` 入場制御ステートマシン（`class RequestQueue` と `hx-sync`）

`__handleTriggerEvent` が `__issueRequest(ctx)`（547行目）を呼び出すと、htmx は `__determineSyncStrategy(elt)` と `__getRequestQueue(elt)`（688〜705行目）によって対象要素の同期キューを特定し、`requestQueue.admit(...)`（90〜128行目）で実行可否を判定します。

```drawlib align=center code=fold file=arch_c04_request_queue_matrix.png caption="RequestQueue ステートマシン（L90-128）と hx-sync 入場制御戦略マトリクス"
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

### `hx-sync` による `RequestQueue` のスコープ解決（688〜705行目）

`hx-sync` は以下の3つの構文形式をサポートします。

1. **戦略のみ（`hx-sync="replace"`）**: `__getRequestQueue` は `hxSync` が `/^(drop|abort|replace|queue)/` に一致することを検出し、`syncElt = elt` を維持したまま `__determineSyncStrategy` が `"replace"` を返します。
2. **セレクタのみ（`hx-sync="closest form"`）**: `__getRequestQueue` が `syncElt = this.__findOrWarn(elt, "closest form", "hx-sync") || elt` を解決し、`__determineSyncStrategy` はデフォルトの `"queue first"` を返します。
3. **セレクタ＋戦略（`hx-sync="#search-form:abort"`）**: セレクタ内のCSS擬似クラス（例: `form:first-of-type:replace`）を壊さないよう、**最後のコロン**（`hxSync.lastIndexOf(":")`）で分割します。解決された `syncElt` の `this.__htmxState(syncElt).rq ||= new RequestQueue()` にキューインスタンスが遅延生成されます。

### `RequestQueue` の実装詳細（90〜128行目）

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

`RequestQueue` における2つの重要な並行制御の保証に注目してください。

- **非対称な `abort` プリエンプション（100行目）**: 要素に `hx-sync="closest form:abort"`（フォーム内の自動保存や非同期バリデーション入力など）が指定されている場合、実行中のリクエストは `this.#current.strategy === "abort"` として記録されます。実行中に別の `abort` リクエストが到着した場合は114行目に落ちて `"dropped"` となりますが、ユーザーがフォーム本体をデフォルトの `"queue first"` 戦略で送信した場合（`strategy !== "abort" && this.#current.strategy === "abort"`）、100行目の条件が成立し、**実行中の `abort` リクエストを即座に中断（`#current.abort?.()`）してフォーム送信を直ちに実行**します。
- **所有者検証付きスロット解放（`continue(abortRequest)`、119〜123行目）**: 中断されたリクエストの `fetch()` が reject されて `finally` ブロック（637行目）に入った時点では、すでに後続の `replace` リクエストが `this.#current` の所有権を取得している可能性があります。`if (this.#current?.abort !== abortRequest) return` で関数参照を比較することで、中断された側の古いリクエストが新しいリクエストの `#current` スロットを誤って解放したり `#queue` を早まって進めてしまう競合を防止しています。

---

## 4.4 非同期 `htmx:confirm`・参照カウント方式インジケータ・`fetch()`・ステータスルーティング（`__issueRequest`）

`requestQueue.admit(syncStrategy, () => this.__issueRequest(ctx), abortRequest)` が `"run"` を返すと（555〜559行目）、`__issueRequest(ctx)` は `ctx.status = "issuing"` に遷移し、ネットワーク通信およびレスポンスヘッダ処理を実行します。

```drawlib align=center code=fold file=arch_c04_issue_request_sequence.png caption="__issueRequest() の実行フロー（L547-639）・参照カウント方式インジケータ・階層的ステータスコードルーティング"
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

### なぜ `htmx:confirm`・タイムアウト・インジケータはキュー入場後に実行されるのか

1. **非同期確認ダイアログ（`ctx.confirm`、567〜576行目）**:
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
   `htmx:confirm` は `requestQueue.admit()` が `"run"` を返した**後**に実行されるため、キュー待ちのリクエストが同時に複数の確認ダイアログを表示してしまうことはありません。カスタムモーダルを実装するリスナーは `htmx:confirm` で `evt.preventDefault()` を呼び出し、後から非同期に `evt.detail.issueRequest()` または `evt.detail.dropRequest()` を実行できます。`confirmed` が `false` の場合でも、`finally` ブロックが確実に `requestQueue.continue(abortRequest)` を呼び出して次のキュー待ちリクエストを起動します。
2. **タイムアウトタイマー（`__initTimeout`、679〜686行目）**: 確認ダイアログの解決後にタイマーを開始（`ctx.requestTimeout = setTimeout(() => ctx.request?.abort?.('timeout'), timeout)`）するため、ユーザーが確認ダイアログを読んでいる時間が `defaultTimeout`（`60000ms`）を消費することはありません。また、`catch (error)`（622行目）では通常の `AbortError` はサイレントに無視されますが、`ctx.request.signal.reason === 'timeout'` の場合は明示的に `htmx:error` が発火されます。
3. **参照カウント方式のインジケータと要素無効化（`s.rc` と `s.dc`、1757〜1805行目）**:
   - `__showIndicators(ctx)` は `hx-indicator`（未指定かつ `elt !== document.body` の場合は `[elt]`）を解決し、`this.__htmxState(indicator).rc = (s.rc || 0) + 1` をインクリメントして `htmx-request` クラスを付与します。
   - `__disableElements(ctx)` は `hx-disable` を解決し、`this.__htmxState(el).dc = (s.dc || 0) + 1` をインクリメントして `el.disabled = true` を設定します。
   - `finally` ブロックでは `__hideIndicators` と `__enableElements` が `--s.rc` と `--s.dc` をデクリメントし、参照カウントが `<= 0` になった時点で初めてクラス除去や `disabled = false` の復元を行うため、複数の並行リクエストが同一のグローバルスピナーを共有していてもちらつきが発生しません。

### レスポンスヘッダの正規化（`__extractHxHeaders`）と早期リターン処理

`let response = await ctx.fetch(ctx.request.action, ctx.request)`（588行目）が解決すると直ちに、`__extractHxHeaders(ctx)`（643〜650行目）が `ctx.response.raw.headers` から `hx-` で始まるすべてのヘッダを走査し、`hx-` プレフィックスとハイフンを除去した小文字キーとして `ctx.hx` に格納します。

| HTTPレスポンスヘッダ | `ctx.hx` プロパティ | 処理段階と動作（`src/htmx.js`） |
| :--- | :--- | :--- |
| `HX-Refresh: true` | `ctx.hx.refresh` | `__handleHeadersAndMaybeReturnEarly`（L655）：`this._loc.reload()` を呼び出し、`ctx.keepIndicators = true` を設定してスワップをスキップします。 |
| `HX-Redirect: <url>` | `ctx.hx.redirect` | `__handleHeadersAndMaybeReturnEarly`（L659）：`this._loc.href = ctx.hx.redirect` を設定し、`ctx.keepIndicators = true` としてスワップをスキップします。 |
| `HX-Location: <spec>` | `ctx.hx.location` | `__handleHeadersAndMaybeReturnEarly`（L663）：HCON または文字列パスを解析し、`ctx.indicators` と `ctx.disabledElements` を `opts` に引き継いで `this.ajax('GET', path, opts)` を呼び出します。`ctx.keepIndicators = true` により、後続の `ajax()` 完了までインジケータ表示が途切れず維持されます。 |
| `HX-Retarget: <sel>` | `ctx.hx.retarget` | スワップ前上書き（L610）：`ctx.target = ctx.hx.retarget` を設定します（`__processMainSwap` で要素に解決）。 |
| `HX-Reswap: <spec>` | `ctx.hx.reswap` | スワップ前上書き（L611）：`ctx.swap = ctx.hx.reswap` を設定します。 |
| `HX-Reselect: <sel>` | `ctx.hx.reselect` | スワップ前上書き（L612）：`ctx.select = ctx.hx.reselect` を設定します。 |
| `HX-Push-Url` / `HX-Replace-Url` | `ctx.hx.pushurl` / `ctx.hx.replaceurl` | `swap(ctx)` 内の `__handleHistoryUpdate(ctx)` で処理されます（[第5章](05_swap_settle_and_morph_engine.md)で詳述）。 |
| `HX-Trigger: <spec>` | `ctx.hx.trigger` | `finally` ブロック（L628–630）で `__handleTriggerHeader(ctx.hx.trigger, ctx.sourceElement)`（L874–888）により実行され、カンマ区切りイベント名と HCON オブジェクト（`{myEvent: {level: "info", target: "#toast"}}`）の両方をサポートします。 |

### 階層的ステータスコードルーティング（`__handleStatusCodes`、2271〜2286行目）

`await this.swap(ctx)`（616行目）を呼び出す直前に、htmx は `__handleStatusCodes(ctx)` を実行してHTTPステータスコードに応じた宣言的ルールを適用します。

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

1. **3段階の具体度カスケード（`[str, str.slice(0, 2) + 'x', str[0] + 'xx']`）**: たとえばステータスコード `404` に対して、完全一致 `"404"` -> 10の位ワイルドカード `"40x"` -> 100の位ワイルドカード `"4xx"` の順で評価します。
2. **`config.noSwap` の照合**: 各具体度ステップで最初に `this.config.noSwap`（203行目のデフォルトは `[204, 304]`）を照合し、一致した場合は `ctx.swap = "none"` を設定して即座にリターンします。
3. **`HCON.merge(statusValue, ctx)` によるコンテキスト書き換え**: 要素（または `:inherited` を持つ祖先）に `hx-status:<pattern>`（例: `hx-status:422="target:#form-errors swap:innerHTML select:#errors"` や `hx-status:5xx="swap:none confirm:false"`）が定義されている場合、その HCON 仕様をトップレベルの `ctx` オブジェクトへ直接マージしてリターンし、[第5章](05_swap_settle_and_morph_engine.md)で解説する `await this.swap(ctx)` へと処理を引き渡します。
