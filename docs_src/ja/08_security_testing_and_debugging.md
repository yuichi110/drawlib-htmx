# 8. セキュリティ・テスト・デバッグ (Security, Testing & Debugging)

htmx はサーバーが描画した HTML をアクティブなドキュメントへ直接挿入するため、本番環境のハイパーメディア駆動アプリケーション（HDA）では **明確な信頼境界（`hx-ignore`）**、**厳格な Content Security Policy 強制（`hx-csp` と Trusted Types）**、**体系的な DevTools オブザーバビリティ（`logAll` と `elt._htmx`）**、および **ヘッドレスブラウザ自動テスト（`@web/test-runner`, `fetch-mock`, Playwright）** が不可欠です。

```drawlib align=center code=fold file=ch08_security_defense_in_depth.png caption="htmx v4.0.1 の多層防御 (Defense-in-Depth) ハイパーメディア・セキュリティアーキテクチャ"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, Pyramid
from drawlib.styles import Styles

setup(width=182, height=74)

# Left: 4-Tier Defense-in-Depth Pyramid
pyr = Pyramid(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.0),
)
pyr.add(
    "L4",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
)
pyr.add("L3: hx-csp Nonce", style=Styles.PrimaryNeutral)
pyr.add("L2: hx-ignore Boundary", style=Styles.SecondaryNeutral)
pyr.add("L1: Server Auto-Escaping & Same-Origin", style=Styles.Neutral)
pyr.draw(xy=(6.0, 8.0), width=68.0, height=58.0, margin=1.8, direction="bottom", order="vertex_to_base")

# Right: Security Controls Breakdown Cards
cards = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=9.5),
    icon_style=Styles.PrimaryBold,
    direction="vertical",
    spacing=2.2,
)
cards.add(
    "Server Auto-Escaping & Same-Origin Fetch",
    "Escape template variables; config.mode defaults to 'same-origin'",
    badge_text="L1",
    icon=phosphor.shield,
)
cards.add(
    "hx-ignore Container Isolation (v4 Rename)",
    "Wrap untrusted Markdown/HTML in <div hx-ignore> to block hx-*",
    badge_text="L2",
    icon=phosphor.prohibit,
)
cards.add(
    "hx-csp Nonce Verification & Scrubbing",
    "Verify hx-nonce on every htmx element & scrub nonces after init",
    badge_text="L3",
    icon=phosphor.key,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    icon_style=Styles.WhiteBold,
)
cards.add(
    "Trusted Types ('htmx') & config.safeEval",
    "Enforce DOM sink policy via api.initSecurity() without eval()",
    badge_text="L4",
    icon=phosphor.lock_key,
)
cards.draw(xy=(80.0, 8.0), width=96.0, height=58.0, align="bottom_left")

save()
```

---

## 8.1 ハイパーメディアの信頼境界と `hx-ignore`

htmx では、ランタイムによって処理された要素が HTTP リクエストの発行やインラインハンドラの実行を行えます。したがって、**信頼できないユーザー入力コンテンツから `hx-*` や `data-hx-*` 属性が注入・実行されないよう厳密に隔離する必要があります**。

1. **サーバー側テンプレートでの徹底した HTML エスケープ**: Jinja2、Go `html/template`、ERB、Razor などの自動エスケープを必ず有効にします。
2. **ユーザー投稿 HTML を `hx-ignore` で囲む**: サニタイズ済みのユーザー投稿 HTML（リッチテキストコメントや Markdown プレビューなど）を表示するコンテナには **`hx-ignore`** を付与します。htmx v4.0.1 はその要素および子孫サブツリーの属性スキャンを完全にスキップします。
3. **同一オリジン通信の強制 (`mode: "same-origin"`)**: `htmx.config.mode` のデフォルトは `"same-origin"` であり、要素単位の `hx-config` から上書きすることはできない設計になっています。

> [!CAUTION]
> **htmx 4 での属性名変更に注意してください！** htmx 2 では `hx-disable` が属性解析の無効化を担っていましたが、htmx v4.0.1 では **`hx-ignore`** がセキュリティ境界（解析無効化）を表す属性であり、`hx-disable` は通信中にボタン等を UI 的に `disabled` にする属性へと変更されています。

```html
<!-- Untrusted user comment body is fenced inside hx-ignore -->
<article class="comment-body" hx-ignore>
  <!-- Even if a sanitizer allows an attribute through, htmx will never process it -->
  <p>User comment content rendered here...</p>
</article>
```

---

## 8.2 厳格な Content Security Policy 対応 (`hx-csp` と Trusted Types)

`'unsafe-inline'` や `'unsafe-eval'` を一切許可しない厳格な Content Security Policy (CSP) 環境向けに、htmx v4.0.1 は以下の機能を備えています。

- **`htmx.config.inlineScriptNonce`**: スワップ時に挿入される `<script>` タグへ指定の nonce を自動付与します。
- **公式拡張 `hx-csp.js`（登録名: `'hx-csp'`）**: 内部セキュリティフック `api.initSecurity(ttPolicy, syncFn, asyncFn)` を通じて 3 層の保護を提供します。
  1. **Nonce ゲート (`hx-nonce`)**: ページ読み込み時に `document.querySelector('script[nonce]')?.nonce` からページ nonce を取得します。すべての htmx 要素は一致する `hx-nonce="<nonce>"` を持つ必要があり、不一致または欠落している場合は全 `hx-*` 属性が即座に剥奪され `htmx:security:strip` イベントが発火します。また同一オリジン応答では `Content-Security-Policy` ヘッダーから新しいレスポンス nonce を抽出して現在のページ nonce へ安全に書き換えます（盗用されたページ nonce がレスポンス本文に含まれていた場合は自動的に無害化・除去します）。
  2. **Trusted Types (`trusted-types htmx`)**: `'htmx'` という名前の Trusted Types ポリシーを生成し、CSP でブロックされた場合はフェイルクローズ（全動作停止）します。
  3. **Safe Eval (`htmx.config.safeEval = true`)**: `Function` / `AsyncFunction` コンストラクタによる動的評価を、nonce 付き `<script>` インジェクション＋キャッシュ機構に置き換えます。これにより、CSP ヘッダーに **`'unsafe-eval'` を追加することなく** `hx-on:*`、`hx-vals="js:..."`、`hx-live` を安全に実行できます。

```html
<!-- HTTP Header: Content-Security-Policy: script-src 'self' 'nonce-r4nd0m99'; require-trusted-types-for 'script'; trusted-types htmx; -->
<meta name="htmx-config" content='extensions:"hx-csp", safeEval:true'>
<script src="/dist/htmx.min.js" nonce="r4nd0m99"></script>
<script src="/dist/ext/hx-csp.min.js" nonce="r4nd0m99"></script>

<!-- Every htmx-powered element must carry hx-nonce matching the script nonce -->
<button hx-post="/account/rotate-key"
        hx-nonce="r4nd0m99"
        hx-target="#key-status"
        hx-on:htmx:after:swap="console.log('Key rotated safely without unsafe-eval')">
  Rotate API Key
</button>
```

---

## 8.3 デバッグ手法 (`logAll`・`elt._htmx`・イベントモニター)

リクエストが発火しない、または意図した通りにスワップされない場合は、以下の診断ワークフローで原因を特定できます。

```drawlib align=center code=fold file=ch08_debugging_and_testing_loop.png caption="htmx v4.0.1 の体系的デバッグ診断フローと自動ブラウザテスト環境"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, ChevronProcess
from drawlib.styles import Styles

setup(width=176, height=76)

# Top: 5-Stage Diagnostic & Verification Pipeline
pipeline = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=1.6,
    flat_left_end=True,
)
pipeline.add("1. Check Version", description="htmx.version == 4.0.1")
pipeline.add("2. Inspect Element", description="elt._htmx & :inherited")
pipeline.add(
    "3. Enable logAll",
    description="htmx.config.logAll = true",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.0),
    description_style=Styles.White.patch(text_size=9.5),
)
pipeline.add("4. Mock Fetch", description="fetchMock.mockResponse", style=Styles.PrimaryNeutral)
pipeline.add("5. Playwright E2E", description="@web/test-runner CI", style=Styles.SecondaryNeutral)
pipeline.draw(xy=(6.0, 54.0), width=164.0, height=15.0)

# Bottom: 3 Horizontal Cards for DevTools & Test Harness
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
    "DevTools Console & DOM",
    "Check $0._htmx state, htmx.find(),\nand htmx.config.logAll = true",
    badge_text="DBG",
    icon=phosphor.bug,
)
cards.add(
    "Fast Unit Tests (fetch-mock)",
    "createProcessedHTML() + mockResponse()\nAwait forRequest() (htmx:finally:request)",
    badge_text="UNIT",
    icon=phosphor.flask,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
)
cards.add(
    "Multi-Browser Playwright",
    "web-test-runner across Chromium,\nFirefox, and WebKit with coverage",
    badge_text="E2E",
    icon=phosphor.browsers,
)
cards.draw(xy=(6.0, 6.0), width=164.0, height=42.0, align="bottom_left")

save()
```

### ブラウザ DevTools コンソールでの実践デバッグスニペット

```javascript
// 1. Enable verbose logging of every colon-separated htmx:* event
htmx.config.logAll = true;

// 2. Verify that htmx has initialized an element (selected as $0 in DevTools Elements panel)
console.log($0._htmx);

// 3. Attach a concise lifecycle tracer for all requests and swaps
[
  'htmx:config:request',
  'htmx:before:request',
  'htmx:after:request',
  'htmx:before:swap',
  'htmx:after:swap',
  'htmx:response:error',
  'htmx:error',
  'htmx:finally:request'
].forEach((evtName) => {
  document.body.addEventListener(evtName, (e) => {
    console.log(
      `[htmx] ${evtName}`,
      e.detail?.ctx?.request?.action,
      e.detail?.ctx?.response?.status,
      e.detail
    );
  });
});
```

---

## 8.4 htmx UI の自動テスト (`@web/test-runner`・`fetch-mock`・Playwright)

htmx v4.0.1 は標準の `window.fetch()` を使用しているため、`@web/test-runner` と `@web/test-runner-playwright`、および `fetch-mock` を組み合わせて、実ブラウザ（Chromium, Firefox, WebKit）上で高速かつ決定論的な自動テストを実行できます。

```bash
# Run the full test suite in headless Chromium via Playwright
npm test

# Run across Chromium, Firefox, and WebKit
npm run test:all
```

### `fetch-mock` を使ったハイパーメディア自動テストの記述例

`createProcessedHTML()` でテスト対象の HTML を `#test-playground` にマウントして初期化し、`mockResponse()` でサーバー応答を定義した上で、クリック操作後に `forRequest()`（`htmx:finally:request` の完了）を `await` します。

```javascript
describe('htmx v4.0.1 status routing and <hx-partial> swaps', () => {
  afterEach(() => {
    cleanupTest(); // Cleans #test-playground and resets fetchMock
  });

  it('routes HTTP 422 validation errors via hx-status:422 and updates partials', async () => {
    mockResponse(
      'POST',
      '/users',
      `<span class="field-error">Email already registered</span>
       <hx-partial hx-target="#status-badge" hx-swap="textContent">Error</hx-partial>`,
      { status: 422 }
    );

    const container = createProcessedHTML(`
      <div>
        <span id="status-badge">Idle</span>
        <form hx-post="/users"
              hx-target="#main-out"
              hx-status:422="target:#err-out swap:innerHTML">
          <input name="email" value="taken@example.com">
          <button id="submit-btn" type="submit">Save</button>
        </form>
        <div id="main-out"></div>
        <div id="err-out"></div>
      </div>
    `);

    const reqDone = forRequest();
    find('#submit-btn').click();
    await reqDone;

    assertTextContentIs('#err-out', 'Email already registered');
    assertTextContentIs('#status-badge', 'Error');
    assertTextContentIs('#main-out', '');
  });
});
```
