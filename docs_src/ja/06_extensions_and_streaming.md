# 6. 公式拡張とストリーミング (Extensions & Streaming)

htmx v4.0.1 は、洗練された**イベントフック型拡張アーキテクチャ（`htmx.registerExtension`）**を採用し、リアルタイム HTML ストリーミング（`hx-sse`, `hx-ws`, `hx-multipart`）、DOM リアクティブスクリプティング（`hx-live`）、UX 強化（`hx-preload`, `hx-pending`, `hx-browser-indicator`, `hx-targets`, `hx-upsert`, `hx-head`, `hx-download`）、厳格な CSP セキュリティ（`hx-csp`）を網羅する **全 17 種の公式拡張** を提供しています。

```drawlib align=center code=fold file=ch06_streaming_and_extensions.png caption="htmx v4.0.1 の拡張フックアーキテクチャ・HTML ストリーミング通信・公式拡張スイート"
from drawlib import canvas
from drawlib.diagrams.architecture import ArchitectureDiagram, Node, NodeGroup, PhosphorIcon
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=176, height=96)

d = ArchitectureDiagram(
    node_style=Styles.Primary,
    node_text_style=Styles.DarkBold.patch(text_size=10.0),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=9.5),
    node_card_style=Styles.Neutral,
    title="htmx v4.0.1 Extension Runtime & Real-Time HTML Streaming Transports",
)

core_grp = d.add(NodeGroup(title="htmx v4 Core & Extension Bus", padding=5.5), xy=(6.0, 10.0))
reg = core_grp.add(
    Node("htmx.registerExtension\n(init(api) + Hooks)", width=28, height=16, icon=PhosphorIcon.PLUGS_CONNECTED, icon_size=7.0, style=Styles.White, card_style=Styles.PrimaryFlat, text_style=Styles.WhiteBold.patch(text_size=10.0)),
    xy=(18.0, 56.0),
)
api_bus = core_grp.add(
    Node("Internal API & Hooks\n(htmx_*_request / swap)", width=28, height=16, icon=PhosphorIcon.GEAR_SIX, icon_size=7.0, card_style=Styles.SecondaryNeutral),
    xy=(18.0, 35.0),
)
whitelist = core_grp.add(
    Node("config.extensions\n(Optional Whitelist)", width=28, height=16, icon=PhosphorIcon.SHIELD_CHECK, icon_size=7.0, card_style=Styles.PrimaryNeutral),
    xy=(18.0, 14.0),
)

stream_grp = d.add(NodeGroup(title="Streaming HTML Transports", padding=5.5), xy=(60.0, 10.0))
sse = stream_grp.add(
    Node("hx-sse (sse)\ntext/event-stream", width=26, height=16, icon=PhosphorIcon.BROADCAST, icon_size=7.0, card_style=Styles.PrimaryNeutral),
    xy=(17.0, 56.0),
)
ws = stream_grp.add(
    Node("hx-ws (ws)\nBi-Directional WS", width=26, height=16, icon=PhosphorIcon.ARROWS_LEFT_RIGHT, icon_size=7.0, card_style=Styles.SecondaryNeutral),
    xy=(17.0, 35.0),
)
multipart = stream_grp.add(
    Node("hx-multipart\nmultipart/mixed", width=26, height=16, icon=PhosphorIcon.STACK, icon_size=7.0),
    xy=(17.0, 14.0),
)

ux_grp = d.add(NodeGroup(title="Reactive & UX Extensions (htmax.js)", padding=5.5), xy=(114.0, 10.0))
live = ux_grp.add(
    Node("hx-live Reactive\nq() / .data / .aria", width=28, height=16, icon=PhosphorIcon.LIGHTNING, icon_size=7.0, card_style=Styles.PrimaryNeutral),
    xy=(19.0, 56.0),
)
ux_exts = ux_grp.add(
    Node("preload / pending /\nupsert / targets", width=28, height=16, icon=PhosphorIcon.SPARKLE, icon_size=7.0),
    xy=(19.0, 35.0),
)
head_dl = ux_grp.add(
    Node("hx-head / download /\nhistory-cache / csp", width=28, height=16, icon=PhosphorIcon.DOWNLOAD_SIMPLE, icon_size=7.0, card_style=Styles.SecondaryNeutral),
    xy=(19.0, 14.0),
)

d.connect(reg, sse, label="Init", padding=1.0)
d.connect(api_bus, ws, label="Hooks", padding=1.0)
d.connect(whitelist, multipart, label="Gate", padding=1.0)
d.connect(sse, live, label="DOM Events", padding=1.0)
d.connect(ws, ux_exts, label="Swap Tasks", padding=1.0)
d.connect(multipart, head_dl, label="Partials", padding=1.0)

d.draw(xy=(4.0, 4.0))
canvas.save()
```

---

## 6.1 v4 拡張アーキテクチャ (`htmx.registerExtension`)

htmx 2 では HTML 要素に `hx-ext="name"` 属性を記述し、単一の `onEvent(name, evt)` コールバックで分岐していましたが、**htmx v4.0.1** では以下のように刷新されました。

1. **`hx-ext` 属性が不要に**: `htmx.js` の後に `<script src="hx-preload.js"></script>` を読み込むだけで、ページ全体で自動的に拡張が有効化されます。
2. **オプションのホワイトリスト制御 (`htmx.config.extensions`)**: デフォルト（`""`）では読み込まれたすべての拡張が登録されます。`<meta name="htmx-config" content='extensions:"preload, sse, hx-live"'>` のように指定すると、**登録名**がリストに含まれる拡張のみが有効化されます。
3. **アンダースコア区切りのイベントフック**: イベント名 `htmx:phase:action` のコロンをアンダースコアに置き換えたメソッド名（`htmx_before_request`, `htmx_after_swap`, `htmx_before_morph_node`, `htmx_process_<type>`）に加え、`init(internalAPI)` や `handle_swap(swapStyle, target, fragment, swapSpec)` を直接定義できます。

```javascript
(() => {
  let api;
  htmx.registerExtension('my-timing-header', {
    init: (internalAPI) => {
      api = internalAPI;
    },
    htmx_config_request: (elt, { ctx }) => {
      if (!api.attributeValue(elt, 'hx-timing')) return;
      ctx.request.headers['X-Request-Sent-At'] = String( performance.now() );
    }
  });
})();
```

### 公式同梱17拡張の完全カタログ

> [!IMPORTANT]
> 下表の **登録名 (`registerExtension`)** に注目してください。`htmx.config.extensions` ホワイトリストにはファイル名ではなく登録名を指定します（例: `hx-sse.js` は `sse`、`hx-preload.js` は `preload` として登録されます）。

| スクリプトファイル | 登録名 (`registerExtension`) | `htmax.js` 同梱 | 主な機能と用途 |
| :--- | :--- | :--- | :--- |
| **`hx-sse.js`** | `sse` | **同梱** | Server-Sent Events (`text/event-stream`) による HTML ストリーム受信・イベント発火 |
| **`hx-ws.js`** | `ws` | **同梱** | WebSocket による双方向 HTML ストリーミングとフォームデータ送信 |
| **`hx-multipart.js`** | `hx-multipart` | 個別読込 | 単一の `multipart/mixed` HTTP レスポンスで複数の HTML チャンクを順次ストリーム反映 |
| **`hx-live.js`** | `hx-live` | **同梱** | DOM 状態ベースのリアクティブスクリプト（`:text`, `:class`, `q()`, `.data`, `.aria`, `take()`） |
| **`hx-preload.js`** | `preload` | **同梱** | `mousedown` や `mouseover` 等のトリガーで `hx-get` を事前フェッチ・キャッシュ |
| **`hx-pending.js`** | `hx-pending` | **同梱** | リクエスト進行中にターゲット要素内へプレースホルダー HTML を一時表示 |
| **`hx-browser-indicator.js`** | `browser-indicator` | **同梱** | Navigation API を活用し、通信中にブラウザタブ自体のネイティブスピナーを表示 |
| **`hx-targets.js`** | `hx-targets` | **同梱** | `hx-targets="<selector>"` に一致する複数すべての要素へ同一レスポンスをスワップ |
| **`hx-upsert.js`** | `upsert` | **同梱** | 既存 ID があれば置換更新し、なければ挿入・ソートする `hx-swap="upsert"` を追加 |
| **`hx-download.js`** | `download` | **同梱** | 進捗イベント（`htmx:download:progress`）付きでファイルをストリームダウンロード |
| **`hx-history-cache.js`** | `history-cache` | **同梱** *(初期無効)* | 戻る/進む操作時に `sessionStorage` から DOM・入力値・スクロール位置を即座に復元 |
| **`hx-alpine-compat.js`** | `alpine-compat` | **同梱** | Alpine.js のリアクティブ状態と htmx のモーフィング・ライフサイクルを安全に連携 |
| **`hx-head.js`** | `hx-head` | 個別読込 | レスポンス内の `<head>` タグ（スタイルシートや `<script defer>`）を差分マージ |
| **`hx-ptag.js`** | `ptag` | 個別読込 | 要素単位の `HX-PTag` ヘッダーによる `304 Not Modified` 条件付きポーリング |
| **`hx-csp.js`** | `hx-csp` | 個別読込 | 厳格な CSP 強制（`hx-nonce` 検証、Trusted Types ポリシー、`safeEval`） |
| **`hx-prompt.js`** | `hx-prompt` | 個別読込 | htmx 2 の `hx-prompt` 入力ダイアログと `HX-Prompt` ヘッダーを復元 |
| **`htmx-2-compat.js`** | `compat` | 個別読込 | htmx 2 の旧キャメルケースイベント発火と旧属性名の互換マッピングを提供 |

---

## 6.2 HTML ストリーミング (`hx-sse`・`hx-ws`・`hx-multipart`)

htmx v4.0.1 は `fetch()` と `ReadableStream` を基盤としているため、持続的接続を通じたリアルタイム HTML ストリーミングを宣言的に扱えます。

### 1. Server-Sent Events (`hx-sse.js`)

SSE エンドポイント（`Content-Type: text/event-stream`）に接続し、ストリームされる HTML イベントをそのまま DOM にスワップします。

```html
<script src="/dist/ext/hx-sse.min.js"></script>

<!-- Connect to /events/stream and swap 'message' events into #live-feed -->
<div hx-sse="connect:/events/stream">
  <div id="live-feed" hx-sse="swap:message" hx-swap="afterbegin"></div>

  <!-- Or trigger a standard hx-get whenever a specific SSE event arrives -->
  <div hx-get="/metrics/summary" hx-trigger="sse:metricsUpdated"></div>
</div>
```

### 2. 双方向 WebSocket (`hx-ws.js`)

`hx-ws="connect:/chat"` で WebSocket 接続を確立し、`hx-ws="send"` を付けたフォームからメッセージを双方向送受信します。

```html
<script src="/dist/ext/hx-ws.min.js"></script>

<section hx-ws="connect:/ws/chatroom">
  <div id="chat-messages"></div>

  <form hx-ws="send" hx-on:htmx:ws:after:send="this.reset()">
    <input type="text" name="chat_message" placeholder="Type a message..." required>
    <button type="submit">Send</button>
  </form>
</section>
```

### 3. チャンク分割 HTTP ストリーミング (`hx-multipart.js`)

AI の段階的応答や複数クエリを含む重いダッシュボードなど、1 回の HTTP リクエストの中で準備できた HTML フラグメントから順次画面に反映したい場合は、`hx-multipart.js` を使ってサーバーから `Content-Type: multipart/mixed; boundary=...` を返却します。

---

## 6.3 `hx-live` によるリアクティブ DOM スクリプティング

ドメイン状態はサーバーで管理しつつ、ドロワーの開閉・文字数カウント・タブのアクティブクラス切り替え・ARIA 属性の同期といったクライアント完結のマイクロインタラクションを軽快に記述できるのが公式拡張 **`hx-live` (`htmx.live`)** です。`hx-live` では **DOM 自身の属性（`data-*`, `aria-*`, `attr`, `class`）がそのままリアクティブな状態ストア**として機能します。

```drawlib align=center code=fold file=ch06_hxlive_reactive_scopes.png caption="hx-live のリアクティブ状態プロキシ (.data, .aria, .attr, .class) とクエリ操作 API"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel
from drawlib.styles import Styles

setup(width=174, height=74)

# Left Panel: Reactive State Bags
left_panel = Panel(
    "hx-live Reactive State Bags",
    "DOM Attributes as Reactive Store",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.database,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=9.0,
)
left_panel.draw((6.0, 6.0), width=78.0, height=62.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box((6.0, 6.0), width=78.0, height=62.0, padding=(3.5, 3.0))

bags = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    spacing=2.0,
)
bags.add("data.*", "Typed data-* state resolved from nearest owner", badge_text="DATA")
bags.add("aria.*", "Typed WAI-ARIA 1.2 state (aria.expanded, aria.hidden)", badge_text="ARIA", badge_style=Styles.PrimaryNeutral, badge_text_style=Styles.PrimaryBold.patch(text_size=9.5))
bags.add("attr.* & class.*", "Reactive HTML attributes & boolean class toggles", badge_text="ATTR", badge_style=Styles.SecondaryNeutral, badge_text_style=Styles.DarkBold.patch(text_size=9.5))
bags.add(":text / :class / :hidden", "Short reactive attribute bindings (bindPrefix: ':')", badge_text="BIND")
bags.draw(l_xy, width=l_w, height=l_h)

# Right Panel: Query & Action Utilities
right_panel = Panel(
    "htmx.live Query & Action API",
    "Declarative UI Micro-Interactions",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.lightning,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=9.0,
)
right_panel.draw((90.0, 6.0), width=78.0, height=62.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box((90.0, 6.0), width=78.0, height=62.0, padding=(3.5, 3.0))

helpers = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=9.5),
    spacing=2.0,
)
helpers.add("q(sel) / $(sel)", "Query proxy supporting next, previous, closest, in", badge_text="QUERY")
helpers.add("take('active')", "Move class or attribute from siblings to target", badge_text="TAKE", badge_style=Styles.PrimaryFlat, badge_text_style=Styles.WhiteBold.patch(text_size=9.5))
helpers.add("toggle('data-theme', 'light|dark')", "Flip boolean class/attr or cycle through values", badge_text="TOG")
helpers.add("forEvent() & debounce()", "Await events/timeouts or debounce async animations", badge_text="ASYNC")
helpers.draw(r_xy, width=r_w, height=r_h)

save()
```

### `hx-live` の実践コード例 (`data.*`, `aria.*`, `take()`, `toggle()`)

```html
<script src="/dist/ext/hx-live.min.js"></script>

<!-- 1. Reactive Counter & Panel Toggle using data-* and :text / :hidden bindings -->
<div data-count="0" data-open="false">
  <button hx-on:click="data.count++">Increment</button>
  <span :text="`Count: ${data.count}`">Count: 0</span>

  <button hx-on:click="data.open = !data.open"
          :aria-expanded="data.open">
    Toggle Details
  </button>
  <div :hidden="!data.open">Reactive Drawer Content</div>
</div>

<!-- 2. Tab Active Class Coordination with take() -->
<nav role="tablist" hx-target:inherited="#tab-panel">
  <button role="tab" class="active" hx-get="/tabs/1" hx-on:click="take('active')">Tab 1</button>
  <button role="tab" hx-get="/tabs/2" hx-on:click="take('active')">Tab 2</button>
  <button role="tab" hx-get="/tabs/3" hx-on:click="take('active')">Tab 3</button>
</nav>
<div id="tab-panel"></div>
```

---

## 6.4 UX を高める公式拡張群 (`preload`, `pending`, `upsert`, `download`, `head`)

```html
<!-- 1. hx-preload: Prefetch GET response on mousedown or mouseover -->
<a href="/reports/annual" hx-get="/reports/annual" hx-target="#main" hx-preload="mousedown">
  Annual Report (Instant Load)
</a>

<!-- 2. hx-pending: Display skeleton placeholder inside #results during the request -->
<button hx-get="/analytics/heavy"
        hx-target="#results"
        hx-pending="<div class='skeleton'>Computing analytics...</div>">
  Run Query
</button>

<!-- 3. hx-upsert: Update matching IDs or insert sorted by data-score descending -->
<button hx-get="/leaderboard/latest"
        hx-target="#leaderboard-list"
        hx-swap="upsert key:data-score sort:desc">
  Refresh Leaderboard
</button>

<!-- 4. hx-download: Stream binary file download with progress bar events -->
<button hx-get="/exports/archive.zip"
        hx-swap="download"
        hx-on:htmx:download:progress="q('#dl-bar').attr.value = event.detail.percent">
  Download Archive
</button>
<progress id="dl-bar" max="100" value="0"></progress>
```
