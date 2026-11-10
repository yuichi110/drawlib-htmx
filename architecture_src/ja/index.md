# htmx v4.0.1 内部アーキテクチャガイド

**htmx v4.0.1**（コードネーム "The Fetchening"）は、htmx 2.x の 4,000 行超におよぶレガシーな `XMLHttpRequest` クロージャ実装をゼロから再設計したフルスクラッチのリライト版です。`fetch()`、`AbortController`、明示的な `:inherited` 属性解決、独自設定記法 `HCON`（htmx Configuration Object Notation）、組込みの Idiomorph 型 DOM 差分調整（Morphing）エンジン、および 15 個の内部プリミティブを公開する `#internalAPI` 拡張ブリッジを備えた、**2,373 行の単一 ES2022 `Htmx` クラス**（`src/htmx.js`）として構築されています。

```drawlib align=center code=fold file=arch_overview_hero.png caption="htmx v4.0.1 単一ファイル・コアアーキテクチャ (src/htmx.js, 2,373行) と拡張ブリッジ"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=82, dpi=150)

# Outer IIFE Boundary
rectangle((78, 41), width=148, height=74, style=Styles.MutedDashed.patch(shape_r=2.5))
text(
    (78, 74.5),
    "src/htmx.js — var htmx = (() => { HCON + RequestQueue + new Htmx() })() (L1–2373)",
    style=Styles.DarkBold.patch(text_size=12.0),
)

# Top Tier: Static Helpers & State Primitives
rectangle((29, 60), width=44, height=16, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
phosphor.brackets_curly((11, 63.5), width=4.2, style=Styles.PrimaryBold)
text((31, 63.5), "HCON Parser (L10–88)", style=Styles.PrimaryBold.patch(text_size=11.0))
text(
    (29, 56.5),
    "parse() • split() • merge()\nProto-pollution guard (L75)",
    style=Styles.Dark.patch(text_size=10.0),
)

rectangle((78, 60), width=44, height=16, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.queue((60, 63.5), width=4.2, style=Styles.DarkBold)
text((80, 63.5), "RequestQueue (L90–128)", style=Styles.DarkBold.patch(text_size=11.0))
text(
    (78, 56.5),
    "admit() • continue() • abort()\ndrop | abort | replace | queue",
    style=Styles.Dark.patch(text_size=10.0),
)

rectangle((127, 60), width=44, height=16, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
phosphor.database((109, 63.5), width=4.2, style=Styles.SecondaryBold)
text((129, 63.5), "Element State (L353–363)", style=Styles.SecondaryBold.patch(text_size=11.0))
text(
    (127, 56.5),
    "elt._htmx (__htmxProp)\nelt._htmx_state (rq, rc, dc)",
    style=Styles.Dark.patch(text_size=10.0),
)

# Middle Tier: Core Htmx Pipeline Stages
rectangle((29, 36), width=44, height=18, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.magnifying_glass((11, 40.5), width=4.2, style=Styles.DarkBold)
text((31, 40.5), "1. Discovery & Inheritance", style=Styles.DarkBold.patch(text_size=10.8))
text(
    (29, 32.0),
    "process() & #hxOnQuery XPath\n__attributeValue (:inherited)\n__findAllExt() selector engine",
    style=Styles.Dark.patch(text_size=9.8),
)

line((51, 36), (56, 36), arrow_head="->", style=Styles.DarkBold)

rectangle((78, 36), width=44, height=18, style=Styles.PrimaryFlat.patch(shape_r=2.0))
phosphor.arrows_left_right((60, 40.5), width=4.2, style=Styles.WhiteBold)
text((80, 40.5), "2. Trigger & Fetch Pipeline", style=Styles.WhiteBold.patch(text_size=10.8))
text(
    (78, 32.0),
    "__onTrigger() 3-layer closure\n__createRequestContext()\n__issueRequest() & fetch()",
    style=Styles.White.patch(text_size=9.8),
)

line((100, 36), (105, 36), arrow_head="->", style=Styles.DarkBold)

rectangle((127, 36), width=44, height=18, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
phosphor.tree_structure((109, 40.5), width=4.2, style=Styles.PrimaryBold)
text((129, 40.5), "3. Swap, Settle & Morph", style=Styles.PrimaryBold.patch(text_size=10.8))
text(
    (127, 32.0),
    "swap(): Main -> OOB -> Partial\n__morph() & moveBefore()\nView & CSS Transition queues",
    style=Styles.Dark.patch(text_size=9.8),
)

# Bottom Tier: #internalAPI & 17 Official Extensions
line((78, 27), (78, 21), arrow_head="<->", style=Styles.PrimaryBold)

rectangle((78, 13.5), width=142, height=14, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
phosphor.plugs_connected((14, 15.5), width=4.5, style=Styles.SecondaryBold)
text(
    (80, 16.0),
    "#internalAPI Bridge (15 Bound Primitives, L155–175) & __triggerExtensions() Hook Dispatcher (L1529)",
    style=Styles.SecondaryBold.patch(text_size=10.8),
)
text(
    (78, 10.5),
    "17 Official Extensions (src/ext/*.js): hx-csp • hx-live • hx-multipart • hx-sse • hx-ws • hx-history-cache • hx-preload • ...",
    style=Styles.Dark.patch(text_size=10.0),
)

save()
```

---

## 1. アーキテクチャの進化：htmx 2.x と htmx v4.0.1 の比較

htmx v4.0.1 では、レガシーな互換コードをモジュラー拡張（`src/ext/*.js`）へと分離しつつ、すべてのコアサブシステムを最新のブラウザ標準 API 上で再構築しています。

| アーキテクチャ領域 | htmx 2.x（従来アーキテクチャ） | htmx v4.0.1（`src/htmx.js`） | ソースコード参照箇所 |
| :--- | :--- | :--- | :--- |
| **モジュール構造** | 約4,000行超のモノリシックなクロージャと多数の内部関数群 | IIFE 内の **2,373行** ES2022 `class Htmx` + `HCON` + `RequestQueue` | `src/htmx.js` L1–2373 |
| **プライベートメンバ設計** | クロージャ内関数（外部から単体テストで直接呼び出し不可） | `src/htmx.js` の `__` メソッドをビルド時 `sed` でネイティブ `#` プライベートフィールドへ変換 | `package.json` L30–31 |
| **ネットワーク通信層** | `XMLHttpRequest`（`xhr`）イベントコールバック | `async/await` ベースの `window.fetch()` + `AbortController` + `ReadableStream` 拡張 | `src/htmx.js` L389, L583–598 |
| **設定・属性パーサ** | 属性ごとに個別実装された正規表現パーサ（`hx-swap`, `hx-trigger`, JSON `hx-vals`） | 統一 **`HCON`** パーサ（`HCON.parse`, `HCON.split`, `HCON.merge`） | `src/htmx.js` L10–88 |
| **属性の継承モデル** | ほぼ全 `hx-*` 属性に対する暗黙的な DOM ツリー継承 | 明示的な **`:inherited`** / **`:append`** 修飾子によるオプトイン継承（`implicitInheritance: false`） | `src/htmx.js` L204, L288–320 |
| **イベント命名規則** | キャメルケース混在（`htmx:beforeRequest`, `htmx:afterOnLoad`） | コロン階層型 **`htmx:phase:action`**（`htmx:before:request`, `htmx:after:swap`） | `src/htmx.js` L1512–1541 |
| **マルチSwap・Partial** | `hx-swap-oob` のみ | 統合タスクパイプライン：**Main Swap $\rightarrow$ `hx-swap-oob` $\rightarrow$ `<hx-partial>`** | `src/htmx.js` L1059–1184, L1267–1326 |
| **DOM Morphing** | 外部 `idiomorph` ライブラリが必要 | `Node.prototype.moveBefore` 対応の組込み **`innerMorph` / `outerMorph`** エンジン | `src/htmx.js` L2018–2269 |
| **履歴ナビゲーション** | `popstate` + コア内蔵の `localStorage` HTML キャッシュ | **Navigation API**（`navigation.addEventListener('navigate')`）+ 分離拡張 `hx-history-cache.js` | `src/htmx.js` L1252–1263, L1630–1719 |
| **インジケータ CSS 注入** | `<head>` へのインライン `<style>` 要素挿入（厳格な CSP に抵触） | Constructable Stylesheets（**`new CSSStyleSheet()`**）と `document.adoptedStyleSheets` | `src/htmx.js` L215–228 |

---

## 2. リクエスト・Swap・拡張フックの全体ライフサイクル

htmx v4 におけるすべてのハイパーメディア操作は、トリガーイベント評価（`__onTrigger`）からリクエストコンテキスト生成（`__createRequestContext`）、同期キュー制御（`RequestQueue.admit`）、`fetch()` 通信（`__issueRequest`）、マルチタスク断片抽出（`swap`）、そして DOM 挿入・差分調整（`__insertContent` / `__morph`）に至る決定論的な非同期パイプラインを通過します。

```drawlib align=center code=fold file=arch_lifecycle_pipeline.png caption="ハイパーメディアリクエスト・キュー制御・Fetch・マルチタスクSwapの全体パイプライン"
from drawlib.canvas import save, setup
from drawlib.smartarts import ChevronProcess, Table
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=82, dpi=150)

text(
    (78, 77.0),
    "htmx v4.0.1 Execution Pipeline: From DOM Trigger to Settled DOM",
    style=Styles.DarkBold.patch(text_size=12.5),
)

pipeline = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    corner_angle=75.0,
    spacing=1.2,
    flat_left_end=True,
)
pipeline.add(
    "1. Trigger",
    description="__onTrigger (L744)\nGuard / Delay",
    style=Styles.PrimaryNeutral,
)
pipeline.add(
    "2. Context",
    description="Request Context\nFormData (L386)",
    style=Styles.Neutral,
)
pipeline.add(
    "3. Queue",
    description="RequestQueue\nadmit() (L555)",
    style=Styles.SecondaryNeutral,
)
pipeline.add(
    "4. Fetch",
    description="ctx.fetch() (L588)\nHX-* & Status",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    description_style=Styles.White.patch(text_size=9.5),
)
pipeline.add(
    "5. Swap",
    description="swap(ctx) (L1267)\nMain / OOB / Partial",
    style=Styles.PrimaryNeutral,
)
pipeline.add(
    "6. Settle",
    description="__insertContent\nMorph & process()",
    style=Styles.SecondaryNeutral,
)
pipeline.draw(xy=(6, 57), width=144, height=15)

table = Table(
    cell_style=Styles.White,
    text_style=Styles.Dark.patch(text_size=10.0),
    header_cell_style=Styles.PrimaryFlat,
    header_text_style=Styles.WhiteBold.patch(text_size=10.2),
    border_style=Styles.MutedThin,
)
table.draw_flexible(
    xy=(6, 52),
    column_widths=[30.0, 52.0, 62.0],
    row_heights=[6.5, 8.5, 8.5, 8.5, 8.5, 8.5],
    data=[
        ["Pipeline Stage", "Primary Htmx Methods (src/htmx.js)", "Lifecycle Events & Extension Hooks"],
        ["1. Init & Trigger", "process() (L935)\n__onTrigger() (L744)", "htmx:before:process, htmx:before:init\nhtmx:after:init, htmx:after:process"],
        ["2. Context & Config", "__createRequestContext() (L386)\n__handleTriggerEvent() (L471)", "htmx:config:request\n(cancels on false or DIALOG)"],
        ["3. Queue & Confirm", "RequestQueue.admit() (L95)\n__issueRequest() (L547)", "htmx:confirm (Promise suspension)\nhtmx:abort (AbortController)"],
        ["4. Network Fetch", "ctx.fetch() (L588)\n__extractHxHeaders() (L643)", "htmx:before:request, htmx:before:response\nhtmx:after:request, htmx:response:error"],
        ["5. Swap & Settle", "swap() (L1267), __morph() (L2018)\n__insertContent() (L1360)", "htmx:before:swap, htmx:before:settle\nhtmx:after:settle, htmx:after:swap"],
    ],
)

save()
```

---

## 3. コアサブシステム一覧（`src/htmx.js`）

`src/htmx.js` の全 2,373 行は、以下の 9 つの論理サブシステムで構成されています。

| サブシステム | 行番号範囲 | 主要クラス / メソッド | 役割と責務 |
| :--- | :--- | :--- | :--- |
| **1. `HCON` パーサ** | `L10–88` | `HCON.parse`, `HCON.split`, `HCON.merge` | 波括弧不要のキー・値設定文字列の解析、トップレベルカンマ分割、プロトタイプ汚染防御付きディープマージ。 |
| **2. `RequestQueue` 状態機械** | `L90–128` | `RequestQueue.admit`, `.continue`, `.abort` | 要素単位のリクエスト同期制御（`drop`, `abort`, `replace`, `queue first`, `queue last`, `queue all`）。 |
| **3. 初期化・設定・拡張登録** | `L130–238` | `constructor`, `__initHtmxConfig`, `__initRequestIndicatorCss`, `registerExtension` | `htmx.config` 初期化、`<meta name="htmx-config">` 読込、`CSSStyleSheet` 注入、`#internalAPI` バインド。 |
| **4. 属性解決・継承エンジン** | `L240–320`, `L1875–1893` | `__attr`, `__attributeValue`, `__getAttributeObject` | `hx-*` / `data-hx-*` 解決、`:inherited` / `:append` 継承チェーン探索、`js:` 動的オブジェクト評価。 |
| **5. トリガー字句解析・イベント配線** | `L322–331`, `L734–888` | `__parseTriggerSpecs`, `__onTrigger`, `__extractFilter` | `hx-trigger` 仕様を3層クロージャ（ガード、`delay`/`throttle`、`changed`/`once`）、`IntersectionObserver`、`every` タイマーへ変換。 |
| **6. コンテキスト構築・`fetch()` 実行** | `L333–705`, `L1807–1873`, `L2271–2286` | `__createRequestContext`, `__collectFormData`, `__issueRequest`, `__handleStatusCodes` | `FormData` 構築、`RequestQueue` 制御、`htmx:confirm` 待機、`fetch()` 実行、`HX-*` 応答ヘッダ処理、`hx-status:*` ルーティング。 |
| **7. サブツリー走査・`hx-on:*`** | `L890–1025`, `L1721–1755` | `process`, `__cleanup`, `#hxOnQuery`, `__handleHxOnAttributes`, `__executeJavaScript` | XPath `#hxOnQuery` による高速探索、アクション/Boost要素の初期化、スコープ付き JS 評価、`__cleanup` によるリソース解放。 |
| **8. マルチタスクSwap・トランジション** | `L1027–1510`, `L1630–1719`, `L2288–2341` | `__makeFragment`, `__processOOB`, `__processPartials`, `swap`, `__insertContent` | `<hx-*>` タグ変換、隠し Pantry による `[hx-preserve]` 保護、Main/OOB/Partial 実行、履歴更新、View/CSS トランジション。 |
| **9. 拡張セレクタ・DOM Morph** | `L1895–2269` | `__findAllExt`, `__morph`, `__morphChildren`, `__findBestMatch`, `__moveBefore` | `compareDocumentPosition` による `next`/`previous` 走査、永続 ID マップと `moveBefore()` を用いた組込み DOM Morphing。 |

---

## 4. チャプター構成とナビゲーション

本ガイドは以下の 6 つの詳細チャプターで構成されています：

1. **[第1章 — モジュールと状態管理構造](01_module_and_state_architecture.md)**
   単一ファイル `Htmx` クラスの全体構造、`package.json` における `sed` `__` $\rightarrow$ `#` プライベートフィールド変換トリック、Constructable `CSSStyleSheet` 注入、`elt._htmx` と `elt._htmx_state` の二層状態ストア、`process(root, force)`、および `#hxOnQuery` `XPathEvaluator` 高速探索。
2. **[第2章 — 属性継承とHCONパーサ](02_attribute_inheritance_and_hcon.md)**
   `HCON` 正規表現レキサー、ドット区切りキー展開、`HCON.merge` のプロトタイプ汚染ガード、`data-hx-` プレフィックスと `metaCharacter` 正規化、および `__attributeValue` による明示的 `:inherited` / `:append` 解決アルゴリズム。
3. **[第3章 — トリガーと拡張セレクタ解析](03_trigger_and_selector_parsers.md)**
   `__parseTriggerSpecs` トークナイザ、`__onTrigger` における 3 層イベントリスナ合成（`delay`, `throttle`, `changed` `WeakMap`, `once`, `IntersectionObserver`, `every`）、および `Node.prototype.compareDocumentPosition` を用いた `__findAllExt` 拡張 CSS セレクタエンジン。
4. **[第4章 — Fetchコンテキストと同期キュー](04_fetch_context_and_sync_queue.md)**
   `__createRequestContext`、`FormData` 収集（`__collectFormData` & `__addInputValues`）、`RequestQueue` 状態機械（`hx-sync`）、`AbortController` タイムアウト、`htmx:confirm` 非同期中断、`HX-*` ヘッダ処理、および階層型 `hx-status:Nxx` ルーティング。
5. **[第5章 — Swap・SettleとMorphエンジン](05_swap_settle_and_morph_engine.md)**
   `__makeFragment` における `<hx-*>` $\rightarrow$ `<template hx>` 書き換え、`[hx-preserve]` の Pantry 退避・復元、`swap(ctx)` のタスク順序（Main $\rightarrow$ OOB $\rightarrow$ `<hx-partial>`）、組込み Idiomorph 差分調整（`__morph`, `__createIdMaps`, `morphScanLimit`, `Node.prototype.moveBefore`）、および直列化 View Transitions キュー。
6. **[第6章 — 拡張機構とセキュリティ内部構造](06_extension_and_security_internals.md)**
   `registerExtension` と `__triggerExtensions` によるコロン $\rightarrow$ アンダースコア拡張フックディスパッチ、15 個のプリミティブを公開する `#internalAPI` ブリッジ、`__executeJavaScript` と Trusted Types、`src/ext/hx-csp.js` の 3 層 CSP 防御（`hx-nonce`, `safeEval`）、および主要公式拡張（`hx-live.js`, `hx-multipart.js`, `hx-sse.js`, `hx-ws.js`）の内部実装。
