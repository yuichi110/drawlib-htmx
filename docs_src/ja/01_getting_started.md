# 1. はじめに・導入と htmx 2 からの移行ガイド

**htmx v4.0.1** は標準の HTML を拡張し、`<a>` や `<form>` だけでなくあらゆる HTML 要素から HTTP リクエスト（`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `QUERY`）を発行し、サーバーが描画した **HTML フラグメント** を直接 DOM にスワップできるようにします。

```drawlib align=center code=fold file=ch01_hypermedia_vs_spa.png caption="従来の JSON SPA アーキテクチャと htmx v4.0.1 ハイパーメディア駆動ループの比較"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Panel
from drawlib.styles import Styles

setup(width=168, height=72)

# Left Panel: Traditional JSON SPA Complexity
left_panel = Panel(
    "JSON SPA Pipeline",
    "Client State Sync",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.5),
    description_style=Styles.Muted.patch(text_size=10.0),
    icon=phosphor.warning_circle,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=9.5,
)
left_panel.draw((6.0, 6.0), width=75.0, height=60.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box((6.0, 6.0), width=75.0, height=60.0, padding=(4.0, 3.5))

spa_list = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    spacing=2.2,
)
spa_list.add("1. Fetch JSON API", "Serialize DB models to JSON DTOs", badge_text="1")
spa_list.add("2. Client Store Sync", "Normalize into Redux / Pinia / Zustand", badge_text="2")
spa_list.add("3. Client Validation", "Duplicate server business rules in JS", badge_text="3")
spa_list.add("4. Virtual DOM Hydration", "Large JS bundle parses & reconciles", badge_text="4")
spa_list.draw(l_xy, width=l_w, height=l_h)

# Right Panel: htmx v4.0.1 Hypermedia Simplicity
right_panel = Panel(
    "htmx v4.0.1 Loop",
    "HTML Fragments",
    style=Styles.PrimaryNeutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=11.5),
    description_style=Styles.White.patch(text_size=10.0),
    icon=phosphor.lightning,
    icon_style=Styles.White,
    dot_styles=(
        Styles.DangerFlat.patch(shape_line_width=0),
        Styles.WarningFlat.patch(shape_line_width=0),
        Styles.SuccessFlat.patch(shape_line_width=0),
    ),
    header_variant="window",
    header_height=9.5,
)
right_panel.draw((87.0, 6.0), width=75.0, height=60.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box((87.0, 6.0), width=75.0, height=60.0, padding=(4.0, 3.5))

htmx_list = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    spacing=2.2,
)
htmx_list.add("1. Declarative Attribute", "hx-post, hx-get, hx-trigger on HTML", badge_text="1")
htmx_list.add("2. Native fetch() Request", "Sends HX-Request & HX-Request-Type", badge_text="2")
htmx_list.add("3. Server Renders HTML", "Single source of truth for templates", badge_text="3")
htmx_list.add("4. Swap or Morph DOM", "innerHTML, innerMorph, or <hx-partial>", badge_text="4")
htmx_list.draw(r_xy, width=r_w, height=r_h)

save()
```

---

## 1.1 インストールとバンドル種別

`htmx.org@4.0.1` は npm からインストールするか、`<script>` タグでビルド済みバンドルを読み込んで利用します。

```bash
npm install htmx.org@4.0.1
```

htmx v4.0.1 では、`dist/` 配下に主に 3 種類の JavaScript 配布形式（および型定義 `dist/htmx.d.ts` と個別拡張 `dist/ext/*.js`）が用意されています。

| バンドルファイル | モジュール形式 | 含まれる機能 | 推奨ユースケース |
| :--- | :--- | :--- | :--- |
| **`dist/htmx.js`** (`htmx.min.js`) | IIFE (`window.htmx`) | コア `fetch()` エンジン、`:inherited`、`<hx-partial>`、`innerMorph`/`outerMorph`、`hx-status:XXX`、HCON | 標準的な `<script>` 読み込み＋必要な公式拡張のみを個別追加する構成 |
| **`dist/htmx.esm.js`** (`htmx.esm.min.js`) | ES Module (`export default htmx`) | `htmx.js` と同一機能＋ESM デフォルトエクスポート（`window.htmx` も設定） | Vite、Webpack、Rollup、Bun、または `<script type="module">` 環境 |
| **`dist/htmax.js`** (`htmax.min.js`) | オールインワン IIFE (`version: "4.0.1-htmax"`) | コア＋主要 11 拡張（`hx-sse`, `hx-ws`, `hx-preload`, `hx-browser-indicator`, `hx-download`, `hx-pending`, `hx-targets`, `hx-live`, `hx-history-cache`, `hx-upsert`, `hx-alpine-compat`） | ビルドツールなしでストリーミングやリッチ UX を即座に利用したい場合 |

> [!NOTE]
> `htmax.js` では `htmx.config.historyCache` のデフォルト値が `{ disable: true }` に設定されており、明示的に有効化（`htmx.config.historyCache.disable = false`）した場合にのみ `sessionStorage` スナップショットキャッシュが動作します。

```html
<!-- Option A: Classic IIFE Core + Selective Official Extension -->
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.1/dist/htmx.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.1/dist/ext/hx-preload.min.js"></script>

<!-- Option B: Batteries-Included htmax.min.js Bundle -->
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.1/dist/htmax.min.js"></script>

<!-- Option C: ES Module Import -->
<script type="module">
  import htmx from 'htmx.org';
  console.log('Loaded htmx version:', htmx.version); // "4.0.1"
</script>
```

---

## 1.2 ハイパーメディアの基本メンタルモデル

htmx 4 の最も重要な原則は、**「サーバーは JSON ではなく HTML フラグメント（断片）を返す」** という点です。すべてのインタラクションは以下の 4 ステップで完結します。

1. **要素トリガー**: リクエスト属性を持つ要素上でユーザー操作（または `load` / `revealed` などのライフサイクルイベント）が発生します。
2. **Fetch リクエスト送信**: htmx が `HX-*` メタデータヘッダー（`HX-Request: true`、`HX-Source`、`HX-Target`、`HX-Request-Type`）を付与して `fetch()` を実行します。
3. **サーバーによる HTML 描画**: バックエンドが HTML フラグメント（必要に応じて `<hx-partial>` や `HX-*` レスポンスヘッダーを含む）を返します。
4. **ターゲットへのスワップと Settle**: htmx が返却された HTML をターゲット要素へ挿入またはモーフィングし、CSS トランジションを適用します。

```html
<!-- Client HTML -->
<button hx-post="/likes/42" hx-target="this" hx-swap="outerHTML">
  Like (12)
</button>
```

```html
<!-- Server Response (HTTP 200 OK, Content-Type: text/html) -->
<button hx-post="/likes/42" hx-target="this" hx-swap="outerHTML" class="liked">
  Liked (13)
</button>
```

---

## 1.3 コアリクエスト動詞とデフォルトトリガー

htmx v4.0.1 は 6 つの HTTP メソッド属性に加え、URL とメソッドを分離して指定できる `hx-action` / `hx-method` ペアをサポートしています。

| 属性 | HTTP メソッド | 親 `<form>` の入力値を自動送信するか？ | 主な用途 |
| :--- | :--- | :--- | :--- |
| **`hx-get="/url"`** | `GET` | **しない**（必要な場合は `hx-include="closest form"`） | ビュー取得、検索結果、タブ切り替え、遅延読み込み |
| **`hx-post="/url"`** | `POST` | **する** | リソース作成、フォーム送信、状態変更 |
| **`hx-put="/url"`** | `PUT` | **する** | リソース全体のべき等な置換更新 |
| **`hx-patch="/url"`** | `PATCH` | **する** | 既存リソースの部分フィールド更新 |
| **`hx-delete="/url"`** | `DELETE` | **しない**（必要な場合は `hx-include="closest form"`） | テーブル行やアイテムの削除 |
| **`hx-query="/url"`** | `QUERY` | **する** | リクエストボディを伴う安全かつべき等なクエリ検索 |

### 要素種別ごとのデフォルトトリガー

`hx-trigger` を省略した場合、要素の種類に応じて自然な DOM イベントが自動的に選択されます。

- **`<input>`, `<textarea>`, `<select>`**: **`change`** イベントで発火します。
- **`<form>`**: **`submit`** イベントで発火します（`event.preventDefault()` が自動実行されます）。
- **その他すべての要素（`<button>`, `<a>`, `<div>`, `<tr>` など）**: **`click`** イベントで発火します。

> [!TIP]
> `htmx.config.prefix` のデフォルト値は `"data-hx-"` であり、`hx-` に加えて追加のプレフィックスとして機能するため、初期状態で `hx-*` と `data-hx-*` の両方がそのまま動作します。

---

## 1.4 htmx 2 から htmx 4.0.1 への移行ガイド

htmx 4 は `fetch()` を基盤とした全面的な再設計リリースです。既存の htmx 2 コードベースをアップグレードする際は、以下の手順に沿って段階的に進めてください。

```drawlib align=center code=fold file=ch01_migration_roadmap.png caption="htmx 2.x から htmx v4.0.1 への段階的マイグレーションパイプライン"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import Roadmap
from drawlib.styles import Styles

setup(width=174, height=58)

rm = Roadmap(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    spine_style=Styles.DarkBold,
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    icon_style=Styles.PrimaryBold,
    direction="horizontal",
    alternating=True,
    spacing=2.5,
)
rm.add(
    "Step 0: upgrade-check",
    "Scan repo with npx CLI for file:line hits",
    badge_text="S0",
    icon=phosphor.terminal_window,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
rm.add(
    "Step 1: Rename Disable",
    "hx-disable -> hx-ignore FIRST, then hx-disabled-elt -> hx-disable",
    badge_text="S1",
    icon=phosphor.shield_warning,
    badge_style=Styles.AccentFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.AccentBold,
)
rm.add(
    "Step 2: Add :inherited",
    "Mark parent containers with hx-target:inherited",
    badge_text="S2",
    icon=phosphor.tree_structure,
)
rm.add(
    "Step 3: Colon Events",
    "htmx:afterSwap -> htmx:after:swap & detail.ctx",
    badge_text="S3",
    icon=phosphor.broadcast,
)
rm.add(
    "Step 4: Status & Exts",
    "Configure noSwap / hx-status & registerExtension",
    badge_text="S4",
    icon=phosphor.check_circle,
)
rm.draw(xy=(6.0, 6.0), width=162.0, height=46.0, align="bottom_left")

save()
```

### Step 0: 公式 `upgrade-check` CLI スキャナーの実行

htmx v4.0.1 には、プロジェクト内の `.html`, `.php`, `.js`, `.ts`, `.jinja`, `.jinja2`, `.j2`, `.erb`, `.hbs` を走査して修正箇所を `file:line` 形式で出力する CLI ツールが同梱されています。

```bash
# Run the official htmx 4.0.1 upgrade scanner on your project
npx htmx.org@4.0.1 upgrade-check -- ./path/to/project

# Include additional template extensions such as .vue or .svelte
npx htmx.org@4.0.1 upgrade-check --ext .vue ./path/to/project
```

### Step 1: `hx-disable` と `hx-ignore` のリネーム順序（最重要）

> [!CAUTION]
> **必ず最初に `hx-disable` を `hx-ignore` に置換してください！**
> htmx 2 では `hx-disable` が「htmx の属性解析を無効化する（XSS 防止境界）」属性であり、`hx-disabled-elt` が「通信中にボタン等を disabled にする」属性でした。htmx 4 では名前が整理され、解析無効化は **`hx-ignore`**、通信中の要素無効化は **`hx-disable`** になりました。順序を逆にすると 2 つの属性が混ざってしまいます。

| 置換順序 | htmx 2 の属性 | htmx 4 での置換先 | 属性の意味・役割 |
| :--- | :--- | :--- | :--- |
| **1番目（最優先）** | `hx-disable` | **`hx-ignore`** | 信頼できない HTML 内の `hx-*` 属性の解析・実行を完全に無効化 |
| **2番目** | `hx-disabled-elt="find button"` | **`hx-disable="find button"`** | リクエスト進行中に対象要素へ `disabled` 属性を付与 |
| **3番目** | `hx-request='{"timeout":5000}'` | **`hx-config="timeout:5000"`** | 要素単位の Fetch/タイムアウト設定（HCON または JSON） |
| **4番目** | `hx-vars="x: compute()"` | **`hx-vals="js:{x: compute()}"`** | 動的な JavaScript 式によるパラメータ付与 |
| **5番目** | `hx-ext="sse"` | **属性を削除** | 拡張は `<script>` を読み込むだけでページ全体に有効化される |
| **6番目** | `hx-disinherit="*"` / `hx-inherit` | **属性を削除** | 親要素の属性に `:inherited` を付ける明示的継承モデルへ統一 |

### Step 2: htmx 2 と htmx 4.0.1 の主要な挙動差異一覧

| 領域 | htmx 2 の挙動 | htmx 4.0.1 の挙動 | 移行時の対応・互換ブリッジ |
| :--- | :--- | :--- | :--- |
| **属性の継承** | ほぼ全属性が暗黙的に子孫へ継承 | **明示的指定のみ**（例: `hx-target:inherited`） | 親コンテナに `:inherited` を付与、または `htmx.config.implicitInheritance = true` |
| **非 200 応答のスワップ** | `4xx` / `5xx` はデフォルトでスワップしない | `204` / `304` を除く**全ステータスをスワップ** | `hx-status:422` 等で分岐、または `noSwap: [204, 304, "4xx", "5xx"]` を設定 |
| **イベント命名規則** | キャメルケース（`htmx:configRequest`, `htmx:afterSwap`） | **コロン区切り**（`htmx:config:request`, `htmx:after:swap`） | イベント名を更新、または移行期間中 `dist/ext/htmx-2-compat.js` を併用 |
| **イベント詳細 (`detail`)** | `evt.detail.xhr`, `evt.detail.headers` | **`evt.detail.ctx`**（`ctx.request.headers`, `ctx.response.raw`） | イベントリスナー内での参照先を `evt.detail.ctx.request` 等へ変更 |
| **リクエストヘッダー** | `HX-Trigger: btn-id`（ID のみ） | **`HX-Source: button#btn-id`**（`tag#id` 形式） | サーバー側のヘッダー参照を `HX-Source` と `tag#id` 形式へ更新 |
| **`hx-delete` のフォーム値** | 親 `<form>` の入力値を自動送信 | **親 `<form>` を自動送信しない**（`hx-get` と統一） | フォーム内の削除ボタンには `hx-include="closest form"` を追加 |
| **OOB スワップ順序** | メインスワップより**前**に OOB を実行 | メインスワップの**後**に OOB / `<hx-partial>` を実行 | OOB のみでターゲットを空にしたい場合は `swapEmpty:true` 等を指定 |

### 段階的移行のための互換オプション

大規模なコードベースを一度に書き換えられない場合は、設定フラグと `htmx-2-compat.js` 拡張を組み合わせて段階的に移行できます。

```html
<meta name="htmx-config" content='{
  "implicitInheritance": true,
  "noSwap": [204, 304, "4xx", "5xx"]
}'>
<script src="/dist/htmx.min.js"></script>
<script src="/dist/ext/htmx-2-compat.min.js"></script>
```
