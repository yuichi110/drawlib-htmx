# 1. モジュールと状態管理構造

**htmx v4.0.1** は、ハイパーメディアランタイム全体を **2,373 行の単一 ES2022 モジュール**（`src/htmx.js`）内にカプセル化しています。ファイル内部は 3 つのトップレベル構造（`HCON`、`RequestQueue`、`class Htmx`）、ビルド時の `sed` によるプライベートフィールド変換パイプライン（`__` $\rightarrow$ `#`）、CSP に抵触しない Constructable Stylesheets（`CSSStyleSheet`）、要素単位の二層状態ストア（`elt._htmx` と `elt._htmx_state`）、および `process()` と事前コンパイル済み `XPathEvaluator` クエリによる決定論的な DOM サブツリー走査によって構成されています。

```drawlib align=center code=fold file=arch_c01_module_lowering_hero.png caption="src/htmx.js の IIFE クラストポロジーとビルド時の __ から # へのプライベートフィールド変換パイプライン"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=84, dpi=150)

# Left Panel: src/htmx.js Source Topology
rectangle((42, 42), width=74, height=74, style=Styles.Neutral.patch(shape_r=2.5))
phosphor.file_js((10.5, 74.5), width=4.2, style=Styles.DarkBold)
text(
    (45, 74.5),
    "src/htmx.js — Source & Unit Test Target (2,373 LOC)",
    style=Styles.DarkBold.patch(text_size=11.0),
)

# Outer IIFE box inside Left Panel
rectangle((42, 39.5), width=68, height=62, style=Styles.White.patch(shape_r=2.0))
text(
    (42, 67.5),
    "var htmx = (() => { ... return new Htmx() })() (L1–2373)",
    style=Styles.PrimaryBold.patch(text_size=10.2),
)

# Top Two Peer Constructs: HCON & RequestQueue
rectangle((25.5, 58), width=31, height=13, style=Styles.PrimaryNeutral.patch(shape_r=1.5))
text((25.5, 61.2), "const HCON (L10–88)", style=Styles.PrimaryBold.patch(text_size=10.0))
text((25.5, 55.2), "parse() • split() • merge()", style=Styles.Dark.patch(text_size=9.5))

rectangle((58.5, 58), width=31, height=13, style=Styles.SecondaryNeutral.patch(shape_r=1.5))
text((58.5, 61.2), "class RequestQueue (L90)", style=Styles.SecondaryBold.patch(text_size=10.0))
text((58.5, 55.2), "#current • #queue • admit()", style=Styles.Dark.patch(text_size=9.5))

# Main Class Htmx Box
rectangle((42, 29.5), width=64, height=39, style=Styles.Neutral.patch(shape_r=2.0))
text(
    (42, 46.0),
    "class Htmx (L130–2368) — 3 Visibility Tiers",
    style=Styles.DarkBold.patch(text_size=10.5),
)

rectangle((42, 38.5), width=60, height=9.5, style=Styles.SecondaryNeutral.patch(shape_r=1.2))
text(
    (42, 40.8),
    "1. Always-Private # Fields (12 fields, L137–148):",
    style=Styles.SecondaryBold.patch(text_size=9.6),
)
text(
    (42, 36.2),
    "#internalAPI, #Function, #ttPolicy, #hxOnQuery, #verbs",
    style=Styles.Dark.patch(text_size=9.5),
)

rectangle((42, 26.5), width=60, height=11.0, style=Styles.PrimaryFlat.patch(shape_r=1.2))
text(
    (42, 29.2),
    "2. Testable __ Members (68 methods / 4 fields):",
    style=Styles.WhiteBold.patch(text_size=9.8),
)
text(
    (42, 24.0),
    "__HCON, __attributeValue, __issueRequest, __morph\nCallable by test/ suites; lowered to # in dist/ via sed",
    style=Styles.White.patch(text_size=9.5),
)

rectangle((42, 15.5), width=60, height=8.0, style=Styles.White.patch(shape_r=1.2))
text(
    (42, 15.5),
    "3. Public API: process, ajax, swap, find, on, trigger",
    style=Styles.DarkBold.patch(text_size=9.6),
)

# Center Arrow & Build Step
line((79, 42), (103, 42), arrow_head="->", style=Styles.PrimaryBold)
rectangle((91, 53), width=20, height=14, style=Styles.PrimaryNeutral.patch(shape_r=1.5))
text((91, 56.5), "sed Lowering", style=Styles.PrimaryBold.patch(text_size=10.0))
text((91, 50.5), "s/__/#/g\n(__proto__ safe)", style=Styles.Dark.patch(text_size=9.5))

# Right Panel: Production Artifacts (dist/)
rectangle((127, 42), width=46, height=74, style=Styles.Neutral.patch(shape_r=2.5))
phosphor.package((109, 74.5), width=4.2, style=Styles.DarkBold)
text(
    (129, 74.5),
    "dist/ Build Artifacts",
    style=Styles.DarkBold.patch(text_size=11.0),
)

rectangle((127, 58.5), width=41, height=17, style=Styles.PrimaryNeutral.patch(shape_r=1.8))
text((127, 63.5), "dist/htmx.js & .min.js", style=Styles.PrimaryBold.patch(text_size=10.3))
text(
    (127, 56.0),
    "build:iife + terser --mangle\nAll #__ methods become\n#private & mangled",
    style=Styles.Dark.patch(text_size=9.5),
)

rectangle((127, 38.0), width=41, height=17, style=Styles.SecondaryNeutral.patch(shape_r=1.8))
text((127, 43.0), "dist/htmx.esm.js", style=Styles.SecondaryBold.patch(text_size=10.3))
text(
    (127, 35.5),
    "build:esm (L31)\nwindow.htmx = htmx;\nexport default htmx;",
    style=Styles.Dark.patch(text_size=9.5),
)

rectangle((127, 17.5), width=41, height=17, style=Styles.White.patch(shape_r=1.8))
text((127, 22.5), "dist/htmax.js & .min.js", style=Styles.DarkBold.patch(text_size=10.3))
text(
    (127, 15.0),
    "build:htmax (L28)\nCore + 11 extensions\nhistoryCache.disable = true",
    style=Styles.Dark.patch(text_size=9.5),
)

save()
```

---

## 1. 単一ファイル IIFE とクラス構造（`src/htmx.js` L1–2373）

4,000 行超のクロージャ内に多数のヘルパー関数を並べていた htmx 2.x とは異なり、htmx v4.0.1 は即時実行関数式（`var htmx = (() => { ... return new Htmx() })()`）の内部に以下の 3 つのトップレベル宣言のみを配置するクリーンな構造を採用しています。

1. **`const HCON`（`L10–88`）**：htmx Configuration Object Notation を解析・統合するステートレスなパーサおよびディープマージャ（`HCON.parse`, `HCON.split`, `HCON.merge`）です。詳細は[第2章](02_attribute_inheritance_and_hcon.md)で解説します。
2. **`class RequestQueue`（`L90–128`）**：ネイティブの `#` プライベートフィールド（`#current = null`, `#queue = []`）を用いたコンパクトな有限状態機械（FSM）であり、要素単位の `hx-sync` 並行リクエスト制御（`admit`, `continue`, `abort`）を担います（[第4章](04_fetch_context_and_sync_queue.md)参照）。
3. **`class Htmx`（`L130–2368`）**：`L2370`（`return new Htmx()`）でシングルトンとしてインスタンス化されるコアランタイムクラスであり、グローバル設定（`this.config`）、拡張レジストリ（`__extMethods`, `__registeredExt`）、DOM 走査（`process`, `__cleanup`）、通信パイプライン（`__issueRequest`）、および DOM 差分調整（`swap`, `__morph`）を統括します。

### 1.1 コンストラクタによるブートストラップと遅延初期化（`L150–228`, `L1251–1265`）

`new Htmx()` が実行されると（`L150–182`）、コンストラクタはドキュメント本体の準備が整うまで DOM 走査を遅延させつつ、以下の 6 つの同期ブートストラップ処理を順に実行します。

1. **デフォルト設定の初期化と `<meta name="htmx-config">` のマージ（`__initHtmxConfig`, `L184–213`）**：`this.version = '4.0.1'` を設定し、`this.config` の全 19 個のデフォルトプロパティを初期化した後、`document.querySelector('meta[name="htmx-config"]')` を検索してその `content` 属性（HCON 記法または JSON）を `HCON.merge(metaConfig.content, this.config)` でマージします。最後に `this.__approvedExt = this.config.extensions` をスナップショット保存し、起動後に許可拡張リストが改ざんされるのを防ぎます。
2. **Constructable Stylesheets によるインジケータ CSS 注入（`__initRequestIndicatorCss`, `L215–228`）**：`this.config.includeIndicatorCSS === false` でない限り、メモリ上で `new CSSStyleSheet()` を生成し、`replaceSync()` で `.htmx-indicator` と `.htmx-request` の透過度・可視性トランジション規則を設定した上で `document.adoptedStyleSheets.push(this.indicatorStyleSheet)` によりドキュメントへ適用します。htmx 2.x のように `<head>` へインライン `<style>` 要素を挿入しないため、**厳格な Content Security Policy（`style-src` で `'unsafe-inline'` を禁止する環境）でも CSP 違反が一切発生しません**。
3. **アクション属性セレクタの事前コンパイル（`#actionSelector`, `L153`）**：`this.__prefixSelector('[hx-action],[hx-get],[hx-post],[hx-put],[hx-patch],[hx-delete],[hx-query]')` を呼び出し、標準の `hx-*` とプレフィックス付き `data-hx-*` の双方にマッチする CSS セレクタ文字列を生成・保持します。
4. **XPath 式の事前コンパイル（`#hxOnQuery`, `L154`）**：`new XPathEvaluator().createExpression(...)` を 1 度だけコンパイルし、JavaScript ループを使わずに任意の DOM サブツリーからワイルドカード属性 `hx-on*` / `data-hx-on*` を高速抽出できるようにします。
5. **拡張ブリッジ `#internalAPI` のバインド（`#internalAPI`, `L155–175`）**：`this` にバインドされた 15 個の内部プリミティブ（`HCON`, `attributeValue`, `parseTriggerSpecs`, `determineMethodAndAction`, `createRequestContext`, `collectFormData`, `getAttributeObject`, `insertContent`, `morph`, `isSoftMatch`, `initSecurity`, `onTrigger`, `htmxProp`, `triggerHtmxEvent`, `executeJavaScript`）をプライベートフィールド `#internalAPI` に格納します。このオブジェクトは `registerExtension()`（`L234`）における `extension.init(this.#internalAPI)` にのみ渡されます。
6. **遅延 `initialize()` スケジューリングと Navigation API 配線（`L176–181`, `L1251–1265`）**：`document.readyState === 'loading'` の場合は `document.addEventListener("DOMContentLoaded", init)` を登録し、すでに読み込み済みの場合は `setTimeout(init)` で次ティックへ遅延させることで、`htmx.js` 直後の `<script>` タグや拡張登録が初回 DOM 走査前に完了できるようにします。`initialize()`（`L1251–1265`）が実行されると、履歴復元リスナを一度だけ初期化（`#historyInitialized = true`）し、Chromium / WebKit 環境では最新の **Navigation API**（`!/firefox/i.test(navigator.userAgent)` で Firefox を除外しつつ `window.navigation.addEventListener('navigate', ...)` で `traverse` ナビゲーションをインターセプト）を優先使用し、非対応環境では `window.addEventListener('popstate', ...)` にフォールバックした上で、`this.process(document.body)` を呼び出します。

```javascript
// src/htmx.js L150–182, L215–228, L1251–1265 — Constructor Bootstrap, CSSStyleSheet & initialize()
constructor() {
    this.__initHtmxConfig();
    this.__initRequestIndicatorCss();
    this.#actionSelector = this.__prefixSelector('[hx-action],[hx-get],[hx-post],[hx-put],[hx-patch],[hx-delete],[hx-query]');
    this.#hxOnQuery = new XPathEvaluator().createExpression(
        `.//*[@*[${this.__prefixes("hx-on").map(p => `starts-with(name(), "${p}")`).join(' or ')}]]`
    );
    this.#internalAPI = {
        HCON,
        attributeValue: this.__attributeValue.bind(this),
        parseTriggerSpecs: this.__parseTriggerSpecs.bind(this),
        // ... 12 additional bound primitives (see Chapter 6)
    };
    let init = () => this.initialize();
    if (document.readyState === 'loading') {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        setTimeout(init);
    }
}

__initRequestIndicatorCss() {
    if (this.config.includeIndicatorCSS !== false) {
        let indicator = this.config.indicatorClass;
        let request = this.config.requestClass;
        try {
            this.indicatorStyleSheet = new CSSStyleSheet();
            this.indicatorStyleSheet.replaceSync(
                `.${indicator}{opacity:0;visibility: hidden} ` +
                `.${request} .${indicator}, .${request}.${indicator}{opacity:1;visibility: visible;transition: opacity 200ms ease-in}`
            );
            document.adoptedStyleSheets.push(this.indicatorStyleSheet);
        } catch {}
    }
}

initialize() {
    if (this.config.history && !this.#historyInitialized) {
        this.#historyInitialized = true;
        if (window.navigation && !/firefox/i.test(navigator.userAgent)) {
            navigation.addEventListener('navigate', (event) => {
                if (event.navigationType === 'traverse' && event.canIntercept && !event.hashChange)
                    event.intercept({handler: () => this.__restoreHistory()});
            });
        } else {
            window.addEventListener('popstate', (event) => this.__restoreHistory(event.state));
        }
    }
    this.process(document.body);
}
```

---

## 2. テスト可能なプライベートフィールド変換トリック（`package.json` L27–37）

JavaScript ライブラリのアーキテクチャ設計における古典的なジレンマは、**ホワイトボックス単体テストの容易性**と**カプセル化およびバンドルサイズ最小化**の両立です。ES2022 ネイティブの `#private` フィールドを使用すると、実行時の完全なカプセル化が保証され、Terser 等のミニファイアがプライベートメンバ名を `#a`, `#b` のような 2 文字トークンへ圧縮（マングリング）できる一方、外部の単体テストコードから内部パーサやヘルパーメソッドを直接呼び出すことができなくなります。

htmx v4 は、`src/htmx.js` における 2 段階の命名規則と `package.json` のビルド時 `sed` 変換パイプラインを組み合わせることで、このトレードオフを鮮やかに解決しています。

- **`src/htmx.js` でも常時 `#private` なフィールド（`L137–148`）**：12 個のフィールド（`#internalAPI`, `#Function`, `#AsyncFunction`, `#ttPolicy`, `#actionSelector`, `#boostSelector`, `#verbs`, `#hxOnQuery`, `#transitionQueue`, `#historyAbort`, `#historyInitialized`, `#processingTransition`）はソースコード段階からネイティブ `#` 構文で宣言されています。これにより、`#Function` や `#ttPolicy`、`#internalAPI` といったセキュリティ上重要な参照が外部スクリプトから改ざんされることを防ぎます。
- **`src/htmx.js` における二重アンダースコア `__` メンバ**：4 個の内部フィールド（`__HCON`, `__extMethods`, `__approvedExt`, `__registeredExt`, `L132–135`）および全 68 個の内部メソッド（`__attributeValue`, `__parseTriggerSpecs`, `__issueRequest`, `__morph` など）は先頭に `__` を付与しています。`web-test-runner` が `src/htmx.js` に対して単体テストを実行する際、テストスイートは `htmx.__HCON.parse(...)` や `htmx.__parseTriggerSpecs(...)` を直接呼び出して検証できます。
- **単一アンダースコアの `_loc` フック（`L136`）**：`_loc = window.location` は単一アンダースコアで定義されているため、`sed` 変換後もパブリックプロパティとして残り、ビルド済みバンドルに対する結合テストでもロケーション状態をモック可能です。
- **ビルド時の `sed` による `#` への一括変換（`build:iife` & `build:esm`, `package.json` L30–31）**：ビルド実行時、`sed` はまず `HCON.merge`（`L75`）のプロトタイプ汚染ガード内に含まれる `__proto__` を一時プレースホルダ `@@PROTOKEY@@` に退避させた上で、残るすべての `__` を `#` に置換し、最後に `__proto__` を復元します。

```bash
# package.json L28, L30–32 — Private field lowering, minification, and htmax bundle assembly
# 1. Lower __ to native ES2022 # private fields for IIFE distribution (protecting __proto__ at L75)
sed -e 's/__proto__/@@PROTOKEY@@/g' -e 's/__/#/g' -e 's/@@PROTOKEY@@/__proto__/g' src/htmx.js > dist/htmx.js

# 2. Lower __ to # and append ESM default export + global window binding
sed -e 's/__proto__/@@PROTOKEY@@/g' -e 's/__/#/g' -e 's/@@PROTOKEY@@/__proto__/g' src/htmx.js > dist/htmx.esm.js && \
  printf '\nif (typeof window !== "undefined") window.htmx = htmx;\nexport default htmx;\n' >> dist/htmx.esm.js

# 3. Compress and mangle private # fields with Terser
terser --compress --mangle --source-map -o dist/htmx.min.js dist/htmx.js

# 4. Assemble dist/htmax.js (Core + 11 official extensions pre-bundled)
EXTS='hx-sse hx-ws hx-preload hx-browser-indicator hx-download hx-pending hx-targets hx-live hx-history-cache hx-upsert hx-alpine-compat'; \
  { cat dist/htmx.js; printf '\nhtmx.version += "-htmax";\nhtmx.config.historyCache ??= { disable: true };\n'; \
    for e in $EXTS; do cat dist/ext/$e.js; done; } > dist/htmax.js
```

| メンバ階層 | `src/htmx.js` での構文 | `dist/htmx.js` での構文 | 代表的なメンバ例（`src/htmx.js`） | 設計目的と可視性 |
| :--- | :--- | :--- | :--- | :--- |
| **セキュリティ・シングルトン状態** | `#name` | `#name`（`.min.js` で短縮） | `#internalAPI`, `#Function`, `#AsyncFunction`, `#ttPolicy`, `#hxOnQuery`, `#transitionQueue`（`L137–148`） | `src/` と `dist/` の双方で `class Htmx` 外部からアクセス不可。CSP / 動的関数コンストラクタを保護。 |
| **テスト可能なエンジン内部実装** | `__name` | `#name`（`.min.js` で短縮） | `__HCON`, `__extMethods`, `__attributeValue`, `__onTrigger`, `__issueRequest`, `__morph` | `src/htmx.js` テスト時はパブリック。`dist/` ビルド時にネイティブ ES2022 `#` プライベートメンバへ変換。 |
| **モック用テストフック** | `_loc` | `_loc` | `_loc = window.location`（`L136`） | 単一アンダースコアにより `sed` 置換を回避し、ナビゲーションテストでの URL モックを許容。 |
| **パブリック Hypermedia API** | `name` | `name` | `process`, `initialize`, `ajax`, `swap`, `find`, `findAll`, `on`, `trigger`, `registerExtension`, `config` | `window.htmx` に公開され、`__apiMethods()`（`L890–909`）でインライン JS スコープにも注入される公開 API。 |

---

## 3. 要素単位の二層状態ストア：`elt._htmx` と `elt._htmx_state`（`L353–363`）

htmx v4 は、DOM 要素に紐づくすべてのメタデータを単一のオブジェクトに詰め込むのではなく、その状態が**静的な属性配線ライフサイクル**に属するか、あるいは**進行中の通信・ランタイム協調状態**に属するかに基づいて、**`elt._htmx`**（`__htmxProp(elt)`）と **`elt._htmx_state`**（`__htmxState(elt)`）という 2 つの独立した Expando プロパティに分離しています。

```drawlib align=center code=fold file=arch_c01_element_state_stores.png caption="要素単位の二層 Expando ストア：ライフサイクル連動の elt._htmx と再初期化後も永続する elt._htmx_state"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=78, dpi=150)

# Top DOM Element Node
rectangle((78, 69), width=116, height=12, style=Styles.PrimaryFlat.patch(shape_r=2.0))
phosphor.code((26, 71.0), width=4.2, style=Styles.WhiteBold)
text(
    (80, 71.0),
    'DOM Element (elt) — Stamped with data-htmx-powered="true" (L356)',
    style=Styles.WhiteBold.patch(text_size=11.0),
)
text(
    (78, 66.5),
    'Ignored during DOM morphing via config.morphIgnore: ["data-htmx-powered"] (L199, L2205)',
    style=Styles.White.patch(text_size=9.6),
)

# Branches to two stores
line((54, 63), (41, 55), arrow_head="->", style=Styles.PrimaryBold)
line((102, 63), (115, 55), arrow_head="->", style=Styles.SecondaryBold)

# Left Store: elt._htmx (__htmxProp)
rectangle((41, 31), width=70, height=48, style=Styles.PrimaryNeutral.patch(shape_r=2.2))
phosphor.sliders_horizontal((12, 50.5), width=4.2, style=Styles.PrimaryBold)
text(
    (43, 50.5),
    "elt._htmx — __htmxProp(elt) (L353–359)",
    style=Styles.PrimaryBold.patch(text_size=11.0),
)
text(
    (41, 45.8),
    "Wiring & Extension Store (Torn down by __cleanup)",
    style=Styles.DarkBold.patch(text_size=9.8),
)

rectangle((41, 33.5), width=64, height=18, style=Styles.White.patch(shape_r=1.5))
text(
    (41, 39.5),
    "Core Wiring Fields:",
    style=Styles.PrimaryBold.patch(text_size=10.0),
)
text(
    (41, 31.0),
    "• initialized: true (L368) • boosted: hxBoost (L968)\n"
    "• onInitialized: true (L1738) • abortInitialized: true (L2009)\n"
    "• eventHandler: async (evt) => ... (L369)\n"
    "• listeners: [{fromElt, eventName, handler, capture, passive}]\n"
    "• triggerSpecs: [{name, listeners, timeout, interval, observer}]",
    style=Styles.Dark.patch(text_size=9.5),
)

rectangle((41, 15.5), width=64, height=13, style=Styles.Neutral.patch(shape_r=1.5))
text(
    (41, 19.3),
    "Extension Namespaces (via #internalAPI.htmxProp):",
    style=Styles.DarkBold.patch(text_size=9.8),
)
text(
    (41, 13.0),
    "• sse (EventSource) • ws (WebSocket) • multipart\n"
    "• preload • liveRuns (hx-live reactive scopes)",
    style=Styles.Dark.patch(text_size=9.5),
)

# Right Store: elt._htmx_state (__htmxState)
rectangle((115, 31), width=70, height=48, style=Styles.SecondaryNeutral.patch(shape_r=2.2))
phosphor.activity((86, 50.5), width=4.2, style=Styles.SecondaryBold)
text(
    (117, 50.5),
    "elt._htmx_state — __htmxState(elt) (L361–363)",
    style=Styles.SecondaryBold.patch(text_size=11.0),
)
text(
    (115, 45.8),
    "Ephemeral Runtime Store (Survives process(elt, true))",
    style=Styles.DarkBold.patch(text_size=9.8),
)

rectangle((115, 33.5), width=64, height=18, style=Styles.White.patch(shape_r=1.5))
text(
    (115, 39.5),
    "Concurrency & Reference Counters:",
    style=Styles.SecondaryBold.patch(text_size=10.0),
)
text(
    (115, 31.0),
    "• rq: new RequestQueue() (L704) — hx-sync active & queued\n"
    "  requests; preserved even if element attributes re-initialize\n"
    "• rc: number (L1770) — Active .htmx-request indicator ref count\n"
    "• dc: number (L1792) — Active hx-disable element ref count",
    style=Styles.Dark.patch(text_size=9.5),
)

rectangle((115, 15.5), width=64, height=13, style=Styles.Neutral.patch(shape_r=1.5))
text(
    (115, 19.3),
    "Stateful Trigger Memory:",
    style=Styles.DarkBold.patch(text_size=9.8),
)
text(
    (115, 13.0),
    "• changedValues: WeakMap<Element, string> (L763)\n"
    "  Tracks last seen input value for 'changed' modifier",
    style=Styles.Dark.patch(text_size=9.5),
)

save()
```

### 3.1 なぜ 2 つの独立した状態ストアが存在するのか

1. **`elt._htmx`（`__htmxProp(elt)`, `L353–359`）— 属性配線およびクリーンアップ対象ストア**：
   - 要素に対して `hx-*` アクション、`hx-boost`、`hx-on:*`、`htmx:abort` リスナ、または拡張状態が配線される際に遅延生成されます。
   - 生成と同時に `elt.setAttribute('data-htmx-powered', 'true')`（`L356`）を DOM 属性として刻印します。この属性はネイティブ C++ セレクタエンジン用の高速インデックスとして機能し、`__cleanup(elt, force)`（`L1008`）が JavaScript で全 DOM ノードを走査することなく `elt.querySelectorAll('[data-htmx-powered]')` の一発呼び出しで配下の全 htmx 要素を収集できるようにします。
   - さらに `config.morphIgnore` のデフォルト値に `["data-htmx-powered"]`（`L199`）が登録されているため、DOM Morphing 時の属性同期（`__copyAttributes` `L2205–2225`）においてサーバ応答断片（`data-htmx-powered` を持たない）によってこの属性が誤って削除されることはありません。`hx-*` 属性自体が変更された場合（`needsReinit = true`, `L2226`）にのみ `__cleanup(destination, true)` が呼ばれて再初期化されます。
2. **`elt._htmx_state`（`__htmxState(elt)`, `L361–363`）— 再初期化を跨いで生存するランタイム状態**：
   - リクエスト通信中に `htmx.process(elt, true)` や Morphing による属性更新（`__copyAttributes` `L2226` $\rightarrow$ `__cleanup(destination, true)`）が発生して `elt._htmx` が破棄・再構築された場合でも、**絶対に失われてはならない実行時状態**を保持します。
   - **インジケータ参照カウント（`rc`, `L1770–1781`）と Disable 参照カウント（`dc`, `L1792–1803`）**：複数の並行リクエストが同一のスピナー（`hx-indicator="#global-spinner"`）や同一の送信ボタン（`hx-disable="#submit-btn"`）を共有する場合があります。`__showIndicators` は `s.rc = (s.rc || 0) + 1` をインクリメントし、`__hideIndicators` は `--s.rc <= 0` になった時点でのみ `.htmx-request` クラスを除去して `s.rc` を削除します。同様に `__disableElements` は `s.dc` を加算し、`__enableElements` は `--s.dc <= 0` になった時点でのみ `indicator.disabled = false` に戻します。

---

## 4. サブツリー走査（`process`）、XPath 高速探索、およびリソース解放（`__cleanup`）

htmx v4.0.1 では、htmx 2.x が `document.body` に常駐させていたグローバルな `MutationObserver` を完全に廃止しました。代わりに、コアの DOM 初期化は以下の 3 つの明確なライフサイクル境界でのみ決定論的に実行されます。

1. **初回ドキュメント起動時**：`initialize()` が `this.process(document.body)`（`L1264`）を呼び出します。
2. **Swap 完了後の Settle フェーズ**：`__insertContent()` が 새로挿入された各要素に対して `this.process(elt)`（`L1505`）を呼び出します。
3. **Morph プレースホルダの水和（Hydration）**：`__morphChildren()` が永続 ID を含む新規サブツリーの挿入時に `this.process(placeholder)`（`L2091`）を呼び出します。

*(※ なお、リアクティブバインディング拡張である `src/ext/hx-live.js` のみが、`[hx-live]` スコープがマウントされた際に独自の `MutationObserver` を使用します。)*

```drawlib align=center code=fold file=arch_c01_process_and_cleanup.png caption="process(root, force) における決定論的3フェーズ走査と __cleanup(elt, force) によるリソース解放"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.smartarts import ChevronProcess
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=78, dpi=150)

text(
    (78, 73.5),
    "process(root, force) — Guard Checks & 3-Phase Subtree Initialization (L935–960)",
    style=Styles.DarkBold.patch(text_size=12.0),
)

# Top Row: Guards & Pre-Process
guards = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Dark.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=1.2,
    flat_left_end=True,
)
guards.add(
    "1. Connected & Root",
    description="!root?.isConnected -> exit\nShadowRoot -> recurse children",
    style=Styles.Neutral,
)
guards.add(
    "2. Force Teardown",
    description="if (force)\n__cleanup(root, true) (L941)",
    style=Styles.SecondaryNeutral,
)
guards.add(
    "3. Ignore Guard",
    description="__ignore(root) (L240)\nclosest('[hx-ignore]')",
    style=Styles.Neutral,
)
guards.add(
    "4. Before Event",
    description="htmx:before:process (L943)\nCancelable via preventDefault()",
    style=Styles.PrimaryNeutral,
)
guards.draw(xy=(6, 54), width=144, height=15)

# Middle Row: 3 Initialization Phases
rectangle((28, 33), width=44, height=26, style=Styles.PrimaryFlat.patch(shape_r=2.0))
phosphor.lightning((10, 41.5), width=4.0, style=Styles.WhiteBold)
text((30, 41.5), "Phase 1: #hxOnQuery XPath", style=Styles.WhiteBold.patch(text_size=10.3))
text(
    (28, 29.5),
    "L944–952 & L1723–1755\n"
    "• Single C++ XPathEvaluator pass\n"
    "• Fires htmx:before:on:init\n"
    "• Parses inline 'event -> code'\n"
    "• Expands 'hx-on::' -> 'htmx:'",
    style=Styles.White.patch(text_size=9.5),
)

line((50, 33), (56, 33), arrow_head="->", style=Styles.DarkBold)

rectangle((78, 33), width=44, height=26, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
phosphor.play_circle((60, 41.5), width=4.0, style=Styles.PrimaryBold)
text((80, 41.5), "Phase 2: #actionSelector", style=Styles.PrimaryBold.patch(text_size=10.3))
text(
    (78, 29.5),
    "__initializeElement(elt) (L365)\n"
    "• Matches [hx-action], [hx-get],\n"
    "  [hx-post], [hx-put], [hx-patch],\n"
    "  [hx-delete], [hx-query]\n"
    "• Wires __initializeTriggers(elt)",
    style=Styles.Dark.patch(text_size=9.5),
)

line((100, 33), (106, 33), arrow_head="->", style=Styles.DarkBold)

rectangle((128, 33), width=44, height=26, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
phosphor.rocket_launch((110, 41.5), width=4.0, style=Styles.SecondaryBold)
text((130, 41.5), "Phase 3: #boostSelector", style=Styles.SecondaryBold.patch(text_size=10.3))
text(
    (128, 29.5),
    "__maybeBoost(elt) (L962–984)\n"
    "• Scans 'a,form' with hx-boost\n"
    "• Verifies __isSameOrigin(url)\n"
    "• Skips [download], '#' anchors,\n"
    "  target!='_self', method='dialog'",
    style=Styles.Dark.patch(text_size=9.5),
)

# Bottom Panel: __cleanup(elt, force)
rectangle((78, 10), width=144, height=13, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.broom((16, 12.5), width=4.0, style=Styles.DarkBold)
text(
    (80, 12.5),
    "__cleanup(elt, force) (L1007–1025) — Deterministic Resource Teardown via [data-htmx-powered]",
    style=Styles.DarkBold.patch(text_size=10.5),
)
text(
    (78, 7.5),
    "Clears spec.interval, spec.timeout, spec.throttleTimeout • Disconnects spec.observer • Removes DOM listeners • Deletes elt._htmx if force=true",
    style=Styles.Dark.patch(text_size=9.5),
)

save()
```

### 4.1 `XPathEvaluator` による高速探索と 2 種類の `hx-on` 構文（`L154`, `L944–952`, `L1721–1755`）

標準の CSS セレクタ（`querySelectorAll`）は完全一致の属性名（`[hx-on]`）や属性値の前方一致（`[class^="foo"]`）にはマッチできますが、`hx-on:click` や `hx-on:keyup`、`hx-on::before:request` のような**ワイルドカード属性名にマッチする構文を一切持っていません**。

JavaScript で全 DOM 要素とその `elt.attributes` を総当たり走査するオーバーヘッドを回避するため、htmx v4 はコンストラクタ（`L154`）で以下の XPath 1.0 式を事前コンパイルします。

```text
.//*[@*[starts-with(name(), "hx-on") or starts-with(name(), "data-hx-on")]]
```

`process(root, force)` のフェーズ 1（`L944–952`）において、`this.#hxOnQuery.evaluate(root)` はブラウザのネイティブ C++ XPath エンジン内で実行され、該当する全子孫ノードのイテレータを返します（`root` 自身も `L944` で `hxOnNodes` の先頭に追加されます）。`__ignore` で除外されておらず `htmx:before:on:init` イベントがキャンセルされなかった各ノードに対し、`__handleHxOnAttributes(node)`（`L1723–1755`）は `this.__htmxProp(node).onInitialized = true` を設定し、以下の 2 つのイベントバインディング構文を処理します。

1. **マルチハンドラ・インライン矢印構文（`hx-on="click once -> doA(); blur -> doB()"`, `L1741–1747`）**：属性名にサフィックスがない場合（`!rest`）、後続に `->` を伴うセミコロン（`/;(?=[^;]*->)/`）で属性値を分割し、`->` の左辺にあるトリガー仕様（`click once` や `keyup delay:300ms` などの全修飾子をサポート）と右辺のハンドラコードを抽出して `this.__onTrigger(node, triggerSpec, handler(code))` で配線します。
2. **イベント名サフィックス属性構文（`hx-on:click="..."` & `hx-on::before:request="..."`, `L1749–1754`）**：属性名の残余部分が `mc`（`this.config.metaCharacter || ':'`）で始まる場合、先頭の `mc` を取り除きます。もし残りのイベント名がさらに 2 つ目の `mc` で始まっている場合（`hx-on::before:request`）、二重コロン省略記法を `'htmx' + mc + eventName.substring(1)`（$\rightarrow$ `htmx:before:request`）へと展開します。いずれの構文でも、ハンドラ本体は `with(event?.detail||{}){${code}}`（`L1730`）でラップされるため、イベントの `detail` プロパティをインライン式から直接参照できます。

```javascript
// src/htmx.js L935–960, L1007–1025, L1723–1755 — process(), __cleanup(), and __handleHxOnAttributes()
process(root, force) {
    if (!root?.isConnected) return;
    if (!(root instanceof Element)) { // ShadowRoot traversal
        for (let elt of root.children || []) this.process(elt, force);
        return;
    }
    if (force) this.__cleanup(root, true);
    if (this.__ignore(root)) return;
    if (!this.__trigger(root, "htmx:before:process")) return;
    let hxOnNodes = [root];
    let iter = this.#hxOnQuery.evaluate(root);
    let node = null;
    while (node = iter.iterateNext()) hxOnNodes.push(node);
    for (let hxOnNode of hxOnNodes) {
        if (!this.__ignore(hxOnNode) && this.__trigger(hxOnNode, "htmx:before:on:init", {}, true)) {
            this.__handleHxOnAttributes(hxOnNode);
        }
    }
    for (let elt of this.__queryEltAndDescendants(root, this.#actionSelector)) {
        this.__initializeElement(elt);
    }
    for (let elt of this.__queryEltAndDescendants(root, this.#boostSelector)) {
        this.__maybeBoost(elt);
    }
    this.__trigger(root, "htmx:after:process");
}

__cleanup(elt, force) {
    let elts = [elt, ...elt.querySelectorAll?.('[data-htmx-powered]') ?? []];
    for (let e of elts) {
        if (!e._htmx) continue;
        this.__trigger(e, "htmx:before:cleanup");
        for (let spec of e._htmx.triggerSpecs || []) {
            if (spec.interval) clearInterval(spec.interval);
            if (spec.timeout) clearTimeout(spec.timeout);
            if (spec.throttleTimeout) clearTimeout(spec.throttleTimeout);
            spec.observer?.disconnect();
        }
        for (let info of e._htmx.listeners || []) {
            info.fromElt.removeEventListener(info.eventName, info.handler, info);
        }
        e.removeAttribute('data-htmx-powered');
        this.__trigger(e, "htmx:after:cleanup");
        if (force) delete e._htmx;
    }
}
```
