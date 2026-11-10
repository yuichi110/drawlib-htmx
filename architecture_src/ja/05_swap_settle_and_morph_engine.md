# 5. スワップ・セトル・モーフエンジン (Swap, Settle & Morph Engine)

`fetch()` パイプラインがレスポンスペイロードを解決しステータスコードによる上書きを適用した後、`Htmx.prototype.swap(ctx)` (`src/htmx.js` `L1267–1326`) は HTML フラグメントのパース、`<hx-*>` テンプレートの書き換え、マルチタスク抽出 (`main`、`oob`、`partial`)、DOM 挿入または Idiomorph 方式のツリー照合 (Reconciliation)、CSS セトルトランジション、および直列化された View Transitions を統括します。

```drawlib align=center code=fold file=arch_c05_swap_settle_pipeline.png caption="htmx v4.0.1 マルチタスクスワップ・セトル・View Transition 実行パイプライン (src/htmx.js L1027–1510)"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, ChevronProcess
from drawlib.styles import Styles
from drawlib.text import text

setup(width=184, height=96)

text(
    (92, 91),
    "htmx v4.0.1 swap(ctx) Multi-Task Extraction & DOM Settle Pipeline",
    style=Styles.DarkBold.patch(text_size=13.5),
)

# Top: 5-Stage End-to-End Swap & Settle Pipeline
stages = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=1.6,
    flat_left_end=True,
)
stages.add("1. __makeFragment", description="TrustedTypes + <hx-*>")
stages.add("2. Extract Tasks", description="OOB -> Partials -> Main", style=Styles.PrimaryNeutral)
stages.add(
    "3. Route Queue",
    description="Immediate vs ViewTrans",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    description_style=Styles.White.patch(text_size=9.5),
)
stages.add("4. __insertContent", description="12 Styles + Pantry", style=Styles.SecondaryNeutral)
stages.add("5. Settle & Process", description="CSS Restore + process()")
stages.draw(xy=(6.0, 70.0), width=172.0, height=15.0)

# Bottom-Left: Phase A — Fragment Parsing & Task Ordering
col_left = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=10.0),
    icon_style=Styles.PrimaryBold,
    direction="vertical",
    spacing=2.8,
)
col_left.add(
    "Pre-Parse Tag Rewriting (L1059)",
    "Rewrites <hx-*> to <template hx>;\nparses via parseHTMLUnsafe(trusted, {})",
    badge_text="A1",
    icon=phosphor.code,
)
col_left.add(
    "OOB & Partial Extraction (L1112)",
    "Extracts hx-select-oob, [hx-swap-oob],\n<template hx> & htmx:process:*",
    badge_text="A2",
    icon=phosphor.scissors,
)
col_left.add(
    "Main Swap Prepending (L1285)",
    "Applies ctx.select, guards empty swap,\nand unshifts mainSwap to index 0",
    badge_text="A3",
    icon=phosphor.list_numbers,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
)
col_left.draw(xy=(6.0, 6.0), width=84.0, height=58.0)

# Bottom-Right: Phase B — DOM Mutation, Pantry & Settle
col_right = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
    icon_style=Styles.DarkBold,
    direction="vertical",
    spacing=2.8,
)
col_right.add(
    "Pantry & Focus Backup (L1027)",
    "Moves [hx-preserve] to hidden pantry\nvia moveBefore(); backs up focus & CSS",
    badge_text="B1",
    icon=phosphor.archive_box,
)
col_right.add(
    "DOM Insertion & Morph (L1360)",
    "Executes innerHTML, outerSync,\ninnerMorph/outerMorph, or handle_swap",
    badge_text="B2",
    icon=phosphor.arrows_merge,
    badge_style=Styles.AccentFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
    icon_style=Styles.WhiteBold,
)
col_right.add(
    "CSS Settle & Re-Hydration (L1476)",
    "Restores pantry & focus, awaits settle,\nand runs process(elt) & scroll",
    badge_text="B3",
    icon=phosphor.sparkle,
)
col_right.draw(xy=(94.0, 6.0), width=84.0, height=58.0)

save()
```

---

## 1. HTML パース、`<hx-*>` 書き換えとパントリー保護 (Pantry Preservation)

DOM ノードの検査や挿入が行われる前に、htmx は生のレスポンス文字列をサニタイズ済みの不活性な `DocumentFragment` へと変換し、テーブル内にネストされたハイパーメディアタグや再生中のマルチメディア要素を保護します (`src/htmx.js` `L1027–1090`、`L1232–1245`)。

### 1.1 Trusted Types と `Document.parseHTMLUnsafe` (`__parseHTML`)

`__parseHTML(resp)` (`L1053–1057`) は、レスポンス文字列を `this.#ttPolicy.createHTML(resp)` (デフォルトでは `L140` の恒等パススルー `{ createHTML: s => s, createScript: s => s }` ですが、`hx-csp` 拡張によって `#internalAPI.initSecurity` 経由で置き換え可能) に通し、モダンな `Document.parseHTMLUnsafe` API (未対応環境では `DOMParser` にフォールバック) を呼び出します。

```javascript
// src/htmx.js L1053–1057
__parseHTML(resp) {
    let trusted = this.#ttPolicy.createHTML(resp);
    // {} works around Chrome 150-156 dropping comments :/
    return Document.parseHTMLUnsafe?.(trusted, {}) || new DOMParser().parseFromString(trusted, 'text/html');
}
```

`Document.parseHTMLUnsafe(trusted, {})` の第 2 引数として空のオプションオブジェクト `{}` を渡しているのは、Chromium 150〜156 において `parseHTMLUnsafe(html)` を 1 引数で呼び出すと HTML コメントノードが暗黙的に削除されてしまうリグレッションを回避するためです。

### 1.2 パース前の `<hx-*>` から `<template hx>` への書き換え (`__makeFragment`)

標準の HTML5 ツリー構築アルゴリズムでは、テーブルコンテキスト (`<table>`、`<thead>`、`<tbody>`、`<tr>`) の内部に厳格な Foster Parenting (里親養育) ルールが適用されます。そのため、`<tr>` の直下に `<hx-partial>` や `<hx-upsert>` のようなカスタム要素を配置してそのままパースすると、ブラウザの HTML パーサーによって `<table>` の**外側**へと強制的に追い出されてしまいます。一方、`<template>` 要素は HTML5 コンテンツモデルにおいて `<table>` や `<tr>` の直下を含む任意の場所に配置することが許可されています。

サーバー側のマークアップの記述性を損なわずに Foster Parenting を防ぐため、`__makeFragment(text)` (`L1059–1090`) は `__parseHTML` を呼び出す**前**に、正規表現を用いてすべての `<hx-([a-z]+)>` タグを `<template hx type="$1">` に書き換えます。

```javascript
// src/htmx.js L1059–1090
__makeFragment(text) {
    // Convert <hx-*> tags (e.g. <hx-partial>, <hx-oob>) to <template hx type="*">
    let response = text.replace(/<hx-([a-z]+)(\s+|>)/gi, '<template hx type="$1"$2')
                       .replace(/<\/hx-[a-z]+>/gi, '</template>');
    let title = '';
    response = response.replace(/<head(\s[^>]*)?>[\s\S]*?<\/head>/i, m => (title = this.__parseHTML(m).title, ''));
    let startTag = response.match(/<([a-z][^\/>\x20\t\r\n\f]*)/i)?.[1]?.toLowerCase();

    let doc, fragment;
    if (startTag === 'html' || startTag === 'body') {
        doc = this.__parseHTML(response);
        fragment = document.createDocumentFragment();
        fragment.append(doc.body);
    } else {
        doc = this.__parseHTML(`<template>${response}</template>`);
        fragment = doc.querySelector('template').content;
    }

    if (!title) {
        let titleElt = fragment.querySelector('title:not(svg title)');
        if (titleElt) {
            title = titleElt.textContent;
            titleElt.remove();
        }
    }

    this.__processScripts(fragment);
    return { fragment, title };
}
```

`__makeFragment(text)` 内の主要な処理メカニズムは以下の通りです。
1. **`<head>` の除去とタイトル抽出 (`L1063`、`L1076–1082`)**: レスポンスに `<head>...</head>` ブロックが含まれる場合、htmx はそれを単独でパースして `.title` を抽出し、`response` から `<head>` ブロックを取り除きます (なお、`hx-head` 拡張が読み込まれている場合は、より前の `htmx_before_response` フェーズで `<head>` をインターセプトします)。`<head>` が存在しない場合は、パース後のフラグメント内で `title:not(svg title)` を検索して `textContent` を抽出し、スワップ先の body DOM を汚染しないよう `<title>` 要素を削除します。
2. **完全なドキュメント vs. `<template>` エンベロープ (`L1064–1074`)**: `response` の先頭タグが `<html>` または `<body>` の場合、htmx は完全なドキュメントとしてパースし、新しい `DocumentFragment` に `doc.body` を追加します (これにより `__insertContent` が `<body>` の属性を検査できるよう `BODY` ラッパーが保持されます)。それ以外の場合は、マークアップを `<template>${response}</template>` でラップすることで、`<tr>`、`<td>`、`<option>`、`<colgroup>` などの任意のトップレベルフラグメントを `<body>` なしで正確にパースします。
3. **実行可能な `<script>` の再生成 (`__processScripts` `L1232–1245`)**: `DOMParser` や `<template>` のパースによって生成された `<script>` 要素は、ブラウザ内部の *already started* フラグがセットされているため、そのままドキュメントに挿入しても実行されません。`__processScripts(container)` はすべての `<script>` を走査し、新しい `document.createElement('script')` を割り当てて全属性をコピーし、設定されている場合は `newScript.nonce = this.config.inlineScriptNonce` を刻印した上で、`newScript.textContent = this.#ttPolicy.createScript(oldScript.textContent)` を代入して不活性なスクリプトノードをその場で置き換えます。なお、`__processScripts` はトップレベルの `fragment` (`L1084`) と各 `<template hx type="partial">` のコンテンツツリー (`L1163`) の両方に対して呼び出されます。

### 1.3 アトミックなパントリー保護 (`[hx-preserve]`)

`hx-preserve` が指定された要素 (再生中の `<video>`、`<audio>`、`<iframe>`、WebGL `<canvas>` ノードなど) は、ライブドキュメントツリーから切り離されることなく `innerHTML` や `outerHTML` の置換を生き延びる必要があります。要素が一度でもドキュメントから削除されると、iframe のブラウジングコンテキストやメディアの再生状態が即座にリセットされてしまうためです。

htmx は `__handlePreservedElements(fragment)` と `__restorePreservedElements(pantry)` (`L1027–1051`) において、`document.body` の直後に挿入された非表示の**パントリー (pantry)** `<div>` と、`this.__moveBefore()` によるアトミックな移動を組み合わせることでこれを解決しています。

```javascript
// src/htmx.js L1027–1051
__handlePreservedElements(fragment) {
    let pantry = document.createElement('div');
    pantry.hidden = true;
    document.body.insertAdjacentElement('afterend', pantry);
    let newPreservedElts = fragment.querySelectorAll?.(this.__prefixSelector('[hx-preserve]')) || [];
    for (let preservedElt of newPreservedElts) {
        let currentElt = document.getElementById(preservedElt.id);
        if (currentElt) {
            this.__moveBefore(pantry, currentElt, null);
        }
    }
    return pantry;
}

__restorePreservedElements(pantry) {
    for (let preservedElt of [...pantry.children]) {
        let newElt = document.getElementById(preservedElt.id);
        if (newElt) {
            this.__moveBefore(newElt.parentNode, preservedElt, newElt);
            this.__cleanup(newElt);
            newElt.remove();
        }
    }
    pantry.remove();
}
```

`pantry` はライブな `Document` に接続されている (`document.body.insertAdjacentElement('afterend', pantry)`) ため、スワップ前に `Node.prototype.moveBefore()` で `currentElt` を `pantry` に退避し、スワップ後にプレースホルダー `newElt` の直前へ戻すことで、ノードの接続状態を一切途切れさせずに状態を 100% 維持します。

---

## 2. マルチタスク・スワップパイプライン (`swap(ctx)`)

`swap(ctx)` (`L1267–1326`) は、単一のレスポンスフラグメントを順序付けられた個別のスワップ `tasks` 配列 (`{ type, fragment, target, swapSpec, sourceElement }`) へと分解します。

### 2.1 抽出順序 vs. 実行順序

`swap(ctx)` における極めて重要な設計上のポイントは、**OOB (Out-of-Band) タスクと Partial タスクを最初に `fragment` から抽出** (抽出されたサブツリーを `fragment` から削除して変更) する一方で、**実行時にはメインスワップ (Main Swap) が最初に実行される**という点です。

| ステップ | メソッド (`src/htmx.js`) | 抽出メカニズム | `tasks[]` 内の最終位置 |
| :--- | :--- | :--- | :--- |
| **1. OOB 抽出** | `__processOOB` (`L1112–1133`) & `__createOOBTask` (`L1092–1110`) | 最初に `hx-select-oob` セレクターを `fragment` に対して実行 (カンマ区切りの各トークンを `:(.*)` で `[selector, oobValue = 'true']` に分割) し、次に `[hx-swap-oob]` を検索します。一致した各 `elt` を解決済みターゲットごとの `{ type: 'oob' }` タスクにクローンした後、`fragment` から削除します。 | 最初に追加 (`tasks.push(...oobTasks)`) $\rightarrow$ **2 番目**に実行 (`mainSwap` の後)。 |
| **2. Partial & `<hx-*>` 抽出** | `__processPartials` (`L1154–1184`) | `template[hx]` を検索します。`type === 'partial'` の場合は `__processScripts(templateElt.content)` を実行し、`hx-swap` をパースして `hx-target` (または `#${CSS.escape(templateElt.id)}`) を解決し、`{ type: 'partial' }` タスクを追加します。その他の `type` (例: `<hx-upsert>`) の場合は拡張機能向けに `htmx:process:${type}` (`{ ctx, tasks }`) を発火します。その後 `templateElt` を削除します。 | 2 番目に追加 (`tasks.push(...partialTasks)`) $\rightarrow$ **3 番目**に実行。 |
| **3. メインスワップ構築** | `__processMainSwap` (`L1328–1358`) | OOB と Partial を除去した後に `fragment` に残った内容を検査します。`ctx.select` が設定されていれば適用し、`ctx.sourceElement` がブーストされている場合は `swapSpec.show ||= 'top'` をデフォルト設定して `{ type: 'main' }` を構築します。 | `tasks.unshift(mainSwap)` (`L1285`) で先頭に追加 $\rightarrow$ **1 番目**に実行。 |

`__createOOBTask` (`L1092–1110`) では、コロンの前に空白がない場合にマッチする従来の `swapStyle:selector` 構文 (`/^(\S+):(.+)/`) と、HCON スワップ仕様 (`innerHTML target:#sidebar`) の両方をサポートしています。さらに、`swapSpec.strip ??= !swapSpec.style.startsWith('outer')` により、`innerHTML` や `beforeend` などの非 `outer*` スワップスタイルを使用する際は、外側の OOB 要素ラッパーが自動的にアンラップされます。

### 2.2 空のメインスワップの抑制 (`hasPartials` と `swapEmpty`)

サーバーが `<hx-partial>` や `[hx-swap-oob]` 要素**のみ** (および周囲の空白文字) を返した場合、残った空白文字によってメインの `hx-target` の中身が消去されてしまうことは開発者の意図に反します。`__processMainSwap` (`L1280`、`L1334–1339`) は `hasPartials` を用いて意図しない空スワップを防止します。

```javascript
// src/htmx.js L1280
let hasPartials = partialTasks.length || (oobTasks.length && !this.config.allowEmptySwapAfterOOB);

// src/htmx.js L1334–1339 (inside __processMainSwap)
if (
    swapSpec.style === 'delete' ||    // delete always runs regardless of content
    (fragment.querySelector('body') || fragment).childElementCount > 0 || // or fragment has elements
    fragment.textContent.trim() ||    // or fragment has text
    (swapSpec.swapEmpty ?? !hasPartials)
) { ... }
```

これにより、`<hx-partial>` タスクが存在する場合、または `oobTasks` が存在する場合 (`htmx.config.allowEmptySwapAfterOOB === true` または `hx-swap` に `swapEmpty:true` 修飾子が明示的に指定されている場合を除く) は、残った空のフラグメントによるメインスワップが自動的にスキップされます。また、ストリーミング拡張 (`hx-sse.js` `L311` および `hx-ws.js` `L448`) は `swapEmpty:false` を自動的に付与するため、空メッセージや OOB のみのフレームによってストリームコンテナが消去されることはありません。

### 2.3 ヒストリー更新と View Transition タスクの分割

`tasks` を構築した後、`swap(ctx)` (`L1288–1325`) は以下の順序で処理を進めます。
1. `{ ctx, tasks }` を伴う `htmx:before:swap` を発火します (`L1288`)。`hx-targets` (`src/ext/hx-targets.js` `L20–43`) などの拡張機能はこのイベントをインターセプトし、`main` タスクを複数のターゲットタスクへと分割 (splice) したり、`false` を返してスワップ全体をキャンセルしたりします。
2. `this.__handleHistoryUpdate(ctx)` (`L1292`、`L1699–1719`) を呼び出します。初回ページエントリー時に戻るボタンの遷移をインターセプトできるよう `history.replaceState({htmx: true}, '', location.href)` を刻印した上で、`push` または `replace` URL (`HX-Push-Url`、`HX-Replace-Url`、`hx-push-url`、`hx-replace-url`、または `hx-boost` のデフォルト) を解決し、`htmx:before:history:update` $\rightarrow$ `htmx:after:history:push|replace` $\rightarrow$ `htmx:after:history:update` を順次発火します。
3. `tasks` を即時実行用の `swapPromises` と View Transition 用の `transitionTasks` に分割します (`L1294–1314`)。
   - `task.swapSpec?.transition ?? mainSwap?.transition ?? ctx.transition` が truthy であるタスクは `transitionTasks` に集められ、`cssTransition = false` (`__insertContent(task, false)`) を指定した単一のバッチクロージャとして `this.__submitTransitionTask(tasksWrapper, ctx)` に投入されます。
   - それ以外のすべてのタスクは直ちに `this.__insertContent(task)` を実行します。
4. `Promise.all(swapPromises)` を待機し、元のソース要素が `outerHTML` スワップによって置換されていた場合は `ctx.sourceElement = mainSwap.target` に向き直した上で (`L1316–1318`)、`htmx:after:swap` を発火し、`document.title` の更新と `ctx.request.anchor` へのスクロールを行い、`finally` ブロック内で `htmx:finally:swap` の発火を保証します。

---

## 3. DOM 挿入、セトル、トランジション (`__insertContent`)

`__insertContent(task, cssTransition = true)` (`L1360–1510`) は、単一タスクの DOM 変更を実行し、フォーカスおよび CSS トランジションのスナップショットを管理し、スワップ後のセトル (Settle) ライフサイクルを実行します。

```drawlib align=center code=fold file=arch_c05_swap_styles_and_transitions.png caption="12 種類の組み込みスワップスタイルおよび CSS セトル vs. 直列化 View Transition 実行エンジン"
from drawlib.canvas import save, setup
from drawlib.smartarts import CardList, GridLayout
from drawlib.styles import Styles
from drawlib.text import text

setup(width=184, height=92)

text(
    (92, 87),
    "htmx v4.0.1 Swap Strategies & Dual Transition Engines (__insertContent L1360–1510)",
    style=Styles.DarkBold.patch(text_size=13.5),
)

# Left: 3x4 GridLayout of the 12 Swap Styles (Bottom-Left at x=6, y=8)
text(
    (48, 78),
    "12 Built-In Swap Styles (+ handle_swap Ext Hook)",
    style=Styles.DarkBold.patch(text_size=11.5),
)

grid = GridLayout(
    num_column=3,
    num_row=4,
    style=Styles.Neutral.patch(shape_r=1.5),
    text_style=Styles.DarkBold.patch(text_size=10.0),
)
# Row 3 (Top): Morph & Sync (v4 Flagships)
grid.add(
    position=(0, 3),
    width=1,
    height=1,
    text="innerMorph\n(Morph Children)",
    style=Styles.PrimaryFlat.patch(shape_r=1.5),
    text_style=Styles.WhiteBold.patch(text_size=10.0),
)
grid.add(
    position=(1, 3),
    width=1,
    height=1,
    text="outerMorph\n(Morph Self)",
    style=Styles.PrimaryFlat.patch(shape_r=1.5),
    text_style=Styles.WhiteBold.patch(text_size=10.0),
)
grid.add(
    position=(2, 3),
    width=1,
    height=1,
    text="outerSync\n(Attrs + Children)",
    style=Styles.PrimaryNeutral.patch(shape_r=1.5),
)
# Row 2: Core Replacement
grid.add(position=(0, 2), width=1, height=1, text="innerHTML\n(replaceChildren)", style=Styles.PrimaryNeutral.patch(shape_r=1.5))
grid.add(position=(1, 2), width=1, height=1, text="outerHTML\n(Insert + Remove)", style=Styles.PrimaryNeutral.patch(shape_r=1.5))
grid.add(position=(2, 2), width=1, height=1, text="textContent\n(Escaped Text)", style=Styles.Neutral.patch(shape_r=1.5))
# Row 1: Positional Insertions (Aliases: before, prepend, append, after)
grid.add(position=(0, 1), width=1, height=1, text="beforebegin\n(Alias: before)", style=Styles.SecondaryNeutral.patch(shape_r=1.5))
grid.add(position=(1, 1), width=1, height=1, text="afterbegin\n(Alias: prepend)", style=Styles.SecondaryNeutral.patch(shape_r=1.5))
grid.add(position=(2, 1), width=1, height=1, text="beforeend\n(Alias: append)", style=Styles.SecondaryNeutral.patch(shape_r=1.5))
# Row 0 (Bottom): Afterend & Control Styles
grid.add(position=(0, 0), width=1, height=1, text="afterend\n(Alias: after)", style=Styles.SecondaryNeutral.patch(shape_r=1.5))
grid.add(position=(1, 0), width=1, height=1, text="delete\n(Remove Target)", style=Styles.Neutral.patch(shape_r=1.5))
grid.add(position=(2, 0), width=1, height=1, text="none\n(Skip Swap)", style=Styles.Neutral.patch(shape_r=1.5))

grid.draw(
    xy=(6.0, 8.0),
    width=84.0,
    height=65.0,
    margin=1.5,
    outer_style=Styles.MutedDashed.patch(shape_r=2.0),
)

# Right: Dual Transition & Settle Architecture (Bottom-Left at x=96, y=8)
text(
    (138, 78),
    "Settle & View Transition Engines (L2288–2341)",
    style=Styles.DarkBold.patch(text_size=11.5),
)

trans_cards = CardList(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=10.0),
    direction="vertical",
    spacing=2.5,
)
trans_cards.add(
    "1. Swap Delay (.htmx-swapping)",
    "Adds .htmx-swapping and awaits\nswapSpec.swap interval before DOM edit",
    badge_text="T1",
)
trans_cards.add(
    "2. CSS Snapshot (__startCSSTransitions)",
    "Copies class/style/width/height from\nold [id] nodes onto incoming [id] nodes",
    badge_text="T2",
    badge_style=Styles.SecondaryNeutral,
    badge_text_style=Styles.DarkBold.patch(text_size=10.0),
)
trans_cards.add(
    "3. Settle Delay (.htmx-settling)",
    "Awaits settleDelay (1ms default),\nthen restores target CSS attributes",
    badge_text="T3",
)
trans_cards.add(
    "4. ViewTransition Queue (#transitionQueue)",
    "Serializes startViewTransition(task)\ncalls via #processingTransition lock",
    badge_text="VT",
    badge_style=Styles.AccentFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=10.0),
)
trans_cards.draw(xy=(96.0, 8.0), width=82.0, height=65.0)

save()
```

### 3.1 スワップスタイルの正規化、`BODY` の昇格、全 12 種類のスワップ戦略

`__parseSwapSpec(swapStr)` (`L1143–1152`) は、先頭のスワップスタイルトークンと後続の HCON 修飾子 (`swap:100ms settle:20ms scroll:top show:#header:top transition:true strip:true focusScroll:true ignoreTitle:true swapEmpty:true`) を分割し、`__normalizeSwapStyle(style)` (`L273–278`) によって短縮エイリアスを正規化します。

- `before` $\rightarrow$ `beforebegin`
- `after` $\rightarrow$ `afterend`
- `prepend` $\rightarrow$ `afterbegin`
- `append` $\rightarrow$ `beforeend`

スワップを実行する前に、`__insertContent` (`L1372–1380`) は `BODY` の自動処理と外側要素のストリップを適用します。
- `fragment.firstElementChild?.tagName === 'BODY'` の場合、htmx は `keepBody = target === document.body && swapStyle.startsWith('outer')` を確認します。
- `keepBody` が `true` かつ `swapStyle === 'outerHTML'` の場合、ブラウザでは body レベルのリスナーを失わずに `outerHTML` 挿入で `document.body` を置換することができないため、htmx は **`outerHTML` を `outerSync` へと自動的に昇格**させます (`L1374`)。
- `keepBody` が `false` の場合、`swapSpec.strip` のデフォルトは `true` となり、`<body>` タグがアンラップされてその子ノードのみがターゲットに挿入されます。

| スワップスタイル | `__insertContent` 内の実装 (`src/htmx.js` `L1387–1471`) | クリーンアップとターゲットの挙動 |
| :--- | :--- | :--- |
| **`innerHTML`** *(デフォルト)* | すべての `target.children` に対して `this.__cleanup(child)` を呼び出し、`target.replaceChildren(...fragment.childNodes)` を実行します (`L1413–1417`)。 | `target` 要素を保持し、フォーカスのバックアップと `__startCSSTransitions` を実行します。 |
| **`outerHTML`** | `target` の直前に `fragment` を挿入し、`this.__cleanup(target)` を呼び出して `target` を削除し、`target = newContent.find(n => n.nodeType === 1) \|\| parentNode` に更新します (`L1423–1429`)。 | `target === document.body` の場合は `outerSync` に昇格されます。 |
| **`outerSync`** | `this.__copyAttributes(target, fragment.firstElementChild)` を呼び出し、`target.children` をクリーンアップした上で `target.replaceChildren(...fragment.firstElementChild.childNodes)` を実行します (`L1430–1436`)。 | `document.body` のスワップおよび `hx-history-cache` の復元 (`L1656`) で使用されます。 |
| **`textContent`** | `target.querySelectorAll('[data-htmx-powered]')` に対して `this.__cleanup(child)` を呼び出し、`target.textContent = fragment.textContent` を設定します (`L1418–1422`)。 | HTML として解釈せず生のテキストとして描画します。 |
| **`innerMorph`** | `this.__morph(target, fragment, true)` を呼び出します (`L1437–1439`)。 | 組み込みの Idiomorph エンジンにより `target` の子ノードをインプレースで照合・更新します。 |
| **`outerMorph`** | `this.__morph(target, fragment, false)` を呼び出します (`L1440–1442`)。 | `target.parentNode` 内で `target` 自体を含めて照合・更新します。 |
| **`beforebegin` / `before`** | `this.__insertNodes(parentNode, target, fragment)` を呼び出します (`L1443–1446`)。 | `target` の直前に兄弟ノードとして挿入します。 |
| **`afterbegin` / `prepend`** | `this.__insertNodes(target, target.firstChild, fragment)` を呼び出します (`L1447–1449`)。 | `target.firstChild` の直前に先頭挿入します。 |
| **`beforeend` / `append`** | `this.__insertNodes(target, null, fragment)` を呼び出します (`L1450–1451`)。 | `target.lastChild` の直後に末尾追加します。 |
| **`afterend` / `after`** | `this.__insertNodes(parentNode, target.nextSibling, fragment)` を呼び出します (`L1452–1454`)。 | `target` の直後に兄弟ノードとして挿入します。 |
| **`delete`** | 任意の `swapSpec.swap` 遅延を待機した後、`this.__cleanup(target)` を実行して `target.parentNode` から `target` を削除し、早期リターンします (`L1387–1393`)。 | 空のレスポンスであっても `__processMainSwap` 内で常に実行されます (`L1335`)。 |
| **`none`** | `.htmx-swapping` を付与する前の `L1370` で即座にリターンします。 | `204`/`304` ステータスコード (`config.noSwap`) や OOB のみの更新で使用されます。 |
| *カスタム (`handle_swap`)* | `this.__extMethods.get('handle_swap')` を反復処理します (`L1456–1470`、例: `hx-upsert.js` の `upsert`)。 | いずれの拡張も truthy を返さない場合は `Error('Unknown swap style: ...')` をスローします。 |

### 3.2 フォーカスと選択範囲の復元、CSS トランジション、セトルライフサイクル

`innerHTML` および `outerHTML` スワップでは、DOM ノードを単純に置き換えると入力フォーカスや CSS トランジションの連続性が失われてしまうため、変更前後で状態をブリッジする仕組みが備わっています。

1. **フォーカスとカーソル選択範囲のバックアップ (`L1401–1406`、`L1477–1483`)**:
   `document.activeElement` が `id` を持っている場合、htmx は `{ elt: activeElt, start: activeElt.selectionStart, end: activeElt.selectionEnd }` を記録します。スワップとパントリーの復元後、元の要素が `:focus` に一致しなくなっている場合、htmx は `document.getElementById(focusInfo.elt.id)` を検索し、`__setFocus(newElt, { preventScroll }, focusInfo.start, focusInfo.end)` (`L1186–1195`) を呼び出してキーボードフォーカスと正確なテキスト選択範囲の両方を復元します。
2. **属性スナップショットによる CSS トランジション (`__startCSSTransitions` `L2324–2341`)**:
   `cssTransition` が有効かつ `settleDelay > 0` (デフォルト `defaultSettleDelay: 1` ms) の場合、`__startCSSTransitions(fragment, target)` は旧 `target` と新しい `fragment` の両方に存在する、同一の `id` および `tagName` を持つすべての `[id]` 要素を検索します。一致した各要素について、新しい要素を浅くクローン (`let clone = elt.cloneNode(false)`) し、挿入前に新しい `elt` の `['class', 'style', 'width', 'height']` を**旧要素**の属性値で一時的に上書きした上で、復元タスクのクロージャ (`() => this.__copyAttributes(elt, clone)`) を返します。
3. **セトル (Settle) フェーズ (`L1485–1510`)**:
   - `htmx:before:settle` (`{ task, newContent, settleTasks }`) を発火します。
   - `newContent` 内のすべての要素に `.htmx-added` クラスを付与します。
   - `settleTasks.length > 0` の場合、`target` に `.htmx-settling` を付与し、`this.timeout(settleDelay)` を待機 (ブラウザに旧 CSS 状態で 1 フレーム描画させる時間を提供) した後、すべての `settleTask()` を実行して新しい `class`/`style`/`width`/`height` 属性を適用 (これにより滑らかな CSS トランジションが発火) し、`.htmx-settling` を削除します。
   - `htmx:after:settle` を発火し、`.htmx-added` を削除し、新しく挿入されたノードの `hx-*` 属性を配線するために `this.process(elt)` を呼び出し、`this.__handleAutoFocus(elt)` (`[autofocus]`) および `this.__handleScroll(swapSpec, target)` を実行します。

### 3.3 直列化された View Transitions キュー (`#transitionQueue`)

ブラウザの View Transitions API (`document.startViewTransition()`) では、ある View Transition の実行中に新しい View Transition を開始すると、実行中のトランジションが即座に中断 (abort) されてしまいます。複数の独立したコンポーネントやストリーミング Partial が同時にスワップし得るハイパーメディアアプリケーションにおいて、`startViewTransition()` を無秩序に呼び出すと画面のちらつきやアニメーションの中断が発生します。

htmx v4 は、内部の FIFO Promise キュー (`L2288–2322` の `#transitionQueue` と `#processingTransition`) によってこれを解決しています。

```javascript
// src/htmx.js L2288–2322
__submitTransitionTask(task, ctx) {
    return new Promise((resolve) => {
        this.#transitionQueue ||= [];
        this.#transitionQueue.push({ task, resolve, ctx });
        if (!this.#processingTransition) {
            this.__processTransitionQueue();
        }
    });
}

async __processTransitionQueue() {
    if (this.#transitionQueue.length === 0 || this.#processingTransition) {
        return;
    }

    this.#processingTransition = true;
    let { task, resolve, ctx } = this.#transitionQueue.shift();

    try {
        if (document.startViewTransition) {
            let detail = {task, ctx};
            this.__trigger(ctx.sourceElement, "htmx:before:viewTransition", detail);
            await document.startViewTransition(detail.task).finished;
            this.__trigger(ctx.sourceElement, "htmx:after:viewTransition", detail);
        } else {
            await task();
        }
    } catch (e) {
        // Transitions can be skipped/aborted - this is normal
    } finally {
        this.#processingTransition = false;
        resolve();
        this.__processTransitionQueue();
    }
}
```

`document.startViewTransition(detail.task)` を呼び出す**前**に `detail = { task, ctx }` が `htmx:before:viewTransition` に渡される点に注目してください。これにより、イベントリスナーや拡張機能が `detail.task` をラップし、旧状態のスクリーンショットがキャプチャされる前に動的に `view-transition-name` プロパティを設定するといった高度な制御が可能になります。

---

## 4. 組み込み Idiomorph 方式 DOM 照合エンジン (`__morph`)

htmx 2 では DOM モーフィングを行うために外部の `idiomorph` ライブラリを読み込む必要がありました。htmx v4.0.1 では、洗練された Idiomorph アルゴリズムが `src/htmx.js` (`L2018–2269`、約 250 行) に直接組み込まれ、`innerMorph` と `outerMorph` を駆動しています。

```drawlib align=center code=fold file=arch_c05_morph_reconciliation_flow.png caption="htmx v4.0.1 Idiomorph 事前パス ID マッピングと 3 段階兄弟照合エンジン (src/htmx.js L2018–2269)"
from drawlib import canvas
from drawlib.diagrams.flow import Decision, End, FlowDiagram, Process, Start
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=188, height=98)

flow = FlowDiagram(
    node_style=Styles.Neutral,
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=9.5),
    title="htmx v4.0.1 __morph() ID-Set Pre-Pass & __findBestMatch() Sibling Reconciliation",
)

nt = Styles.DarkBold.patch(text_size=10.0)
wt = Styles.WhiteBold.patch(text_size=10.0)

# Column 1 (x=24), Column 2 (x=70), Column 3 (x=118), Column 4 (x=164)
start = flow.add(
    Start("__morph()\nEntry", width=26, height=12, style=Styles.PrimaryFlat, text_style=wt),
    xy=(24, 76),
)
id_maps = flow.add(
    Process("__createIdMaps()\npersistentIds & idMap", width=34, height=13, style=Styles.PrimaryNeutral, text_style=nt),
    xy=(70, 76),
)
find_match = flow.add(
    Process("__findBestMatch()\nScan <= 10 Siblings", width=34, height=13, style=Styles.PrimaryNeutral, text_style=nt),
    xy=(70, 46),
)
match_dec = flow.add(
    Decision("Sibling\nMatch?", width=28, height=16, style=Styles.SecondaryNeutral, text_style=nt),
    xy=(118, 46),
)
rescue_dec = flow.add(
    Decision("In persistentIds?\n(Target / Pantry)", width=32, height=16, style=Styles.SecondaryNeutral, text_style=nt),
    xy=(164, 46),
)

insert_new = flow.add(
    Process("Insert Node or\nidMap Placeholder", width=32, height=13, style=Styles.Neutral, text_style=nt),
    xy=(164, 76),
)
recurse = flow.add(
    Process("Advance Sibling\n& Prune Old", width=32, height=13, style=Styles.SecondaryNeutral, text_style=nt),
    xy=(118, 76),
)

move_before = flow.add(
    Process("Rescue by ID &\n__moveBefore()", width=32, height=13, style=Styles.AccentFlat, text_style=wt),
    xy=(164, 14),
)
evict_inter = flow.add(
    Process("Evict Skipped &\n__moveBefore()", width=32, height=13, style=Styles.Neutral, text_style=nt),
    xy=(118, 14),
)
morph_node = flow.add(
    Process("__morphNode() &\n__copyAttributes()", width=34, height=13, style=Styles.PrimaryNeutral, text_style=nt),
    xy=(70, 14),
)
done = flow.add(
    End("Cleanup Pantry\n& Finish", width=28, height=12, style=Styles.PrimaryFlat, text_style=wt),
    xy=(24, 14),
)

# Orthogonal Non-Crossing Connections
start.connect(id_maps, start_side="right", end_side="left", padding=1.0)
id_maps.connect(find_match, start_side="bottom", end_side="top", padding=1.0)
find_match.connect(match_dec, start_side="right", end_side="left", padding=1.0)

match_dec.connect(evict_inter, label="Yes", start_side="bottom", end_side="top", padding=1.0)
match_dec.connect(rescue_dec, label="No", start_side="right", end_side="left", padding=1.0)

rescue_dec.connect(move_before, label="Yes", start_side="bottom", end_side="top", padding=1.0)
rescue_dec.connect(insert_new, label="No", start_side="top", end_side="bottom", padding=1.0)

move_before.connect(evict_inter, start_side="left", end_side="right", padding=1.0)
evict_inter.connect(morph_node, start_side="left", end_side="right", padding=1.0)
insert_new.connect(recurse, start_side="left", end_side="right", padding=1.0)
morph_node.connect(done, start_side="left", end_side="right", padding=1.0)

flow.draw(xy=(4.0, 4.0))
canvas.save()
```

### 4.1 ボトムアップの `idMap` と `persistentIds` 事前パス (`L2229–2269`)

一般的な仮想 DOM (Virtual DOM) の差分アルゴリズムは現在のツリー階層における兄弟ノード同士のみを単純比較するため、安定した `id` を持つノードが新しいコンテナ `<div>` でラップされたり、1 階層上へアンラップされたりすると状態を失ってしまいます。Idiomorph は、ツリーの走査を開始する前に旧ツリーと新ツリーの全体にわたって**永続 ID セット (persistent ID sets)** を事前計算することでこれを解決します。

1. **`__createPersistentIds(oldIdElements, newIdElements)` (`L2256–2269`)**:
   `oldNode` と `newContent` 内のすべての `[id]` 要素をスキャンします。ある `id` が `persistentIds: Set<string>` に追加されるのは、以下のすべての条件を満たす場合のみです。
   - `oldNode` と `newContent` の**両方**に存在すること。
   - 両方の要素が完全に同一の `tagName` を共有していること。
   - `oldNode` 内または `newContent` 内でその `id` が重複していないこと (`duplicateIds` は `L2267` で除外されます)。
2. **`__populateIdMapWithTree(idMap, persistentIds, root, elements)` (`L2229–2244`)**:
   `id` が `persistentIds` に含まれるすべての要素について、htmx は `root` (旧ツリーでは `oldNode.parentElement`、新フラグメントでは `newContent`) に到達するまで `current = current.parentElement` を辿って**ボトムアップに上方向へ**走査し、経路上にあるすべての祖先要素の `idMap.get(current): Set<string>` に `elt.id` を登録します。

この結果、トップダウン走査中の `O(1)` 時間で、`ctx.idMap.get(node)` を参照するだけで「`node` のサブツリー内の**どこか**に含まれているすべての永続 `id` の正確な集合」を `__findBestMatch` が即座に把握できます。

### 4.2 3 段階の兄弟マッチングとスキャンウィンドウ (`__findBestMatch` `L2118–2151`)

`__morphChildren` (`L2034–2105`) が `newParent` の各 `newChild` を反復処理する際、`__findBestMatch(ctx, newChild, insertionPoint, endPoint)` を呼び出して `insertionPoint` から後続の既存兄弟ノードを前方スキャンします。

```javascript
// src/htmx.js L2118–2151
__findBestMatch(ctx, node, startPoint, endPoint) {
    // text nodes match positionally (patch in place via __morphNode), 3 = TEXT_NODE
    if (node.nodeType === 3) return startPoint?.nodeType === 3 ? startPoint : null;
    if (!(node instanceof Element)) return null;
    let softMatch = null, displaceMatchCount = 0, scanLimit = this.config.morphScanLimit;
    let newSet = ctx.idMap.get(node), nodeMatchCount = newSet?.size || 0;
    // If node has a non-persistent ID, insert instead of soft matching
    if (node.id && !newSet) return null;
    let cursor = startPoint;
    while (cursor && cursor != endPoint) {
        let oldSet = ctx.idMap.get(cursor);
        if (this.#internalAPI.isSoftMatch(cursor, node)) {
            // Hard match: matching IDs found in both nodes
            if (oldSet && newSet && [...oldSet].some(id => newSet.has(id))) return cursor;
            if (!oldSet) {
                // Exact match: nodes are identical
                if (scanLimit > 0 && cursor.isEqualNode(node)) return cursor;
                // Soft match: same tag/type, save as fallback
                if (!softMatch) softMatch = cursor;
            }
        }
        // Stop if too many ID elements would be displaced
        displaceMatchCount += oldSet?.size || 0;
        if (displaceMatchCount > nodeMatchCount) break;
        // Don't move elements containing a focused typeable input
        if (document.activeElement?.selectionStart != null && cursor.contains(document.activeElement)) break;
        // Stop scanning if limit reached and no IDs to match
        if (--scanLimit < 1 && nodeMatchCount === 0) break;
        cursor = cursor.nextSibling;
    }
    // Only return fallback softMatch if it does not match upcoming content
    if (softMatch && this.__matchesUpcomingSibling(ctx, softMatch, node)) return null;
    return softMatch;
}
```

`__findBestMatch` の各行には重要な不変条件 (Invariant) が組み込まれています。
- **位置ベースのテキストノード照合 (`L2120`)**: テキストノード (`nodeType === 3`) は、`startPoint` もテキストノードであれば即座にマッチ (`__morphNode` 内で `oldNode.nodeValue = newNode.nodeValue` を更新) し、テキスト更新時の不要な DOM ノード再生成を回避します。
- **非永続 ID ガード (`L2125`)**: `node` が `ctx.idMap` に含まれない `id` を持っている場合 (新規に導入された `id` であるか、または `tagName` が変更された場合)、ソフトマッチによって無名の兄弟要素を誤って上書きしないよう、即座に `null` を返して新規挿入させます。
- **3 段階のマッチ優先度 (`L2129–2137`)**:
   1. **ハード ID マッチ (Hard ID Match)**: `cursor` と `node` の両方がソフト互換 (`this.#internalAPI.isSoftMatch(cursor, node)`) であり、かつサブツリー内に少なくとも 1 つの共通する永続 ID を持つ場合 (`[...oldSet].some(id => newSet.has(id))`)、即座に `cursor` を返します。
   2. **完全一致ノードマッチ (Exact Node Match)**: `cursor` が永続 ID を持たず (`!oldSet`)、`scanLimit` (`morphScanLimit: 10`) 以内にあり、かつ `cursor.isEqualNode(node)` が `true` の場合、即座に `cursor` を返します。
   3. **フォールバック・ソフトマッチ (Fallback Soft Match)**: `!oldSet` かつ `isSoftMatch(cursor, node)` (`oldNode.tagName === newNode.tagName`、`<script>` の場合は `oldNode.isEqualNode(newNode)`、および `L2153–2160` の `!oldNode.id || oldNode.id === newNode.id`) を満たす最初の `cursor` を候補として記録します。
- **3 つの早期終了スキャンガード (`L2140–2145`)**:
   1. **ID 退避バジェット (`displaceMatchCount > nodeMatchCount`)**: `node` 自身がマッチできる永続 ID の数よりも**多くの**永続 ID を含む候補サブツリーを飛び越えてスキャンし続けることを防ぎます。
   2. **フォーカス中のテキスト入力保護 (`document.activeElement?.selectionStart != null && cursor.contains(document.activeElement)`)**: ユーザーが現在フォーカスして入力中のテキスト入力を含む祖先要素を飛び越えたり移動させたりすることを防ぎ、カーソル位置の安定性と IME 変換状態を保護します。
   3. **上限付きスキャンウィンドウ (`--scanLimit < 1 && nodeMatchCount === 0`)**: 永続 ID を持たない無名の Exact/Soft マッチを探す際、兄弟の先読み数を `htmx.config.morphScanLimit` (`10`) に制限することで、最悪ケースの兄弟スキャン計算量を `O(N²)` ではなく `O(N)` に抑えます。
- **後続兄弟の先読みチェック (`__matchesUpcomingSibling` `L2107–2116`、`L2149`)**: フォールバックの `softMatch` を返す前に、htmx は**新しい**フラグメント内で `node` の後ろに続く最大 `morphScanLimit` (`10`) 個の兄弟ノードを先読みします。もし後続の兄弟に対して `softMatch.isEqualNode(sibling)` が成立する場合、`softMatch` は `ctx.futureMatches` (`WeakSet`) にキャッシュされ、`__findBestMatch` は `null` を返します。これにより、`softMatch` を誤って上書きする代わりに `softMatch` の直前に `node` が綺麗に挿入されます。

### 4.3 パントリー退避、ツリー横断レスキュー、アトミックな `moveBefore`

`__morphChildren` (`L2046–2097`) が兄弟リストを前進する際、以下の処理が行われます。
1. **先行する未マッチ兄弟の退避 (`L2047–2059`)**: `matchedNode` が `insertionPoint` より前方で見つかった場合、`insertionPoint` と `matchedNode` の間にあるスキップされた各ノード `tempNode` が検査されます。
   - `ctx.idMap.has(tempNode)` または `this.__matchesUpcomingSibling(ctx, tempNode, newChild)` が真であれば、後のループで再利用できるよう `this.__moveBefore(oldParent, tempNode, endPoint)` によって `oldParent` の末尾へ移動されます。
   - それ以外の場合は、`this.__removeNode(ctx, tempNode)` (`L2162–2169`) によって、永続 ID を持つ場合は `ctx.pantry` へ移動され、持たない場合はクリーンアップ (`this.__cleanup(node)`) されて DOM から削除されます。
2. **ツリー横断の永続 ID レスキュー (`L2063–2077`)**: `__findBestMatch` が `null` を返した場合 (たとえば永続 `id` を持つ要素が子コンテナから外へ移動されたか、先に `ctx.pantry` へ退避されていた場合)、htmx は `[id="${escapedId}"]` によって `ctx.target` または `ctx.pantry` からその要素を直接救出 (レスキュー) し、旧祖先の `idMap` セットからその `id` を削除した上で、`this.__moveBefore(oldParent, matchedNode, insertionPoint)` によって `insertionPoint` へアトミックに移動させます。
3. **サブツリー ID プレースホルダーの生成 (`L2087–2096`)**: `newChild` 自体は新規のラッパーコンテナ (`!matchedNode`) であるものの、その子孫に永続 ID が含まれている (`ctx.idMap.has(newChild)`) 場合、htmx は `newChild` をそのまま直接挿入**しません** (`newChild` を直接挿入してしまうと、ライブ DOM から永続 ID 要素をレスキューする前に重複する ID 要素が挿入されてしまうためです)。代わりに、空の `placeholder = document.createElement(newChild.tagName)` を作成して挿入し、`placeholder` と `newChild` を再帰的にモーフさせることで、ライブ DOM 内の永続 ID 子孫要素を `__moveBefore` 経由で `placeholder` の中へと安全にレスキューします。
4. **アトミックな DOM 再配置 (`__moveBefore` `L2171–2181`)**:
   ```javascript
   // src/htmx.js L2171–2181
   __moveBefore(parentNode, element, after) {
       if (parentNode.moveBefore) {
           try {
               parentNode.moveBefore(element, after);
               return;
           } catch (e) {
               // ignore and insertBefore instead
           }
       }
       parentNode.insertBefore(element, after);
   }
   ```
   Web プラットフォームの `Node.prototype.moveBefore()` API を活用することで、htmx v4 はリストアイテムの並び替えやツリー階層を跨ぐ `[id]` 要素の移動を行う際にも、CSS アニメーション、`<iframe src>` のブラウジングコンテキスト、`<video>` の再生状態、およびフォーカス状態を完全に維持します。

### 4.4 ノードおよび属性のパッチ適用 (`__morphNode` と `__copyAttributes`)

`oldNode` と `newNode` のペアが確定すると、`__morphNode(oldNode, newNode, ctx)` (`L2183–2202`) と `__copyAttributes(destination, source)` (`L2204–2227`) がインプレースで状態を同期します。

- **スキップセレクターと拡張フック (`L2188–2191`、`L2197`)**:
  - `oldNode.matches(this.config.morphSkip)` (デフォルトは `[hx-morph-skip]`) に一致する場合、`__morphNode` は即座にリターンし、要素とそのサブツリー全体を一切変更せずに維持します。
  - `this.__triggerExtensions(oldNode, "htmx:before:morph:node", { oldNode, newNode })` を発火します。`false` が返された場合はそのノードのモーフィングをキャンセルします。
  - `oldNode.matches(this.config.morphSkipChildren)` (デフォルトは `[hx-morph-skip-children]`) に一致する場合、`oldNode` 自体の属性は同期されますが、`__morphChildren` はスキップされます。
- **属性の同期とライブ入力値の保護 (`__copyAttributes` `L2204–2227`)**:
  - `this.config.morphIgnore` (デフォルトは `["data-htmx-powered"]`) に一致する属性は無視されるため、サーバー側の HTML によって初期化済みマーカーが剥がされることはありません。
  - 変更された各属性を設定または削除する前に `htmx:before:morph:attr` (`{ attrName, newValue }`) を発火します (`hx-live` はこれをフックして変更された `:attr` バインディングをクリーンアップします)。
  - `HTMLInputElement` (`type !== "file"` かつ `document.activeElement !== destination` の場合) の `destination.value = attr.value` を更新し、`HTMLTextAreaElement` (`document.activeElement !== oldNode && oldNode.defaultValue != newNode.defaultValue` の場合) の `oldNode.value = newNode.value` を更新します。
  - **`hx-*` 属性変更時の自動再初期化 (`needsReinit` `L2206–2226`)**: 追加・変更・削除された属性のいずれかが `hx-` (または `config.prefix`) で始まる場合、`needsReinit` が `true` に設定され、`__copyAttributes` は `this.__cleanup(destination, true)` を実行して `destination._htmx` を削除します。これにより、続くセトルフェーズでの `this.process(elt)` 呼び出し時に、更新された `hx-*` 属性が確実に再配線されます。

---

続いて [第 6 章: 拡張機能とセキュリティの内部構造](06_extension_and_security_internals.md) に進み、`registerExtension`、`#internalAPI`、`hx-csp`、`hx-live`、`hx-multipart`、`hx-sse`、および `hx-ws` がこのパイプラインにどのようにフックするかを詳しく見ていきましょう。
