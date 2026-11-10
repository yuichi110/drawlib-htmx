# 2. 属性継承とHCONパーサ

**htmx v4.0.1** は、`src/htmx.js` 内の 2 つの基盤エンジンによって属性設定解析と DOM ツリー継承を統一しています。1 つ目は波括弧不要かつ JSON 互換でプロトタイプ汚染防御を組み込んだ **`HCON`（htmx Configuration Object Notation, `L10–88`）**、2 つ目は `data-hx-` プレフィックス正規化と `metaCharacter` 動的置換を備え、明示的な `:inherited` / `:append` 修飾子によってオプトイン継承を解決する **`__attributeValue()`（`L288–320`）** です。

```drawlib align=center code=fold file=arch_c02_hcon_and_inheritance_hero.png caption="HCON 設定パーサ (L10–88) と明示的 :inherited / :append 属性解決エンジン (L245–320)"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=84, dpi=150)

# Top Panel: HCON Engine (L10–88)
rectangle((78, 62.5), width=146, height=35, style=Styles.Neutral.patch(shape_r=2.5))
phosphor.brackets_curly((11, 75.5), width=4.5, style=Styles.PrimaryBold)
text(
    (80, 75.5),
    "Pillar 1: const HCON — Unified Configuration Lexer, Comma Splitter & Safe Merger (L10–88)",
    style=Styles.DarkBold.patch(text_size=11.2),
)

rectangle((30, 58.5), width=43, height=21, style=Styles.PrimaryNeutral.patch(shape_r=1.8))
text((30, 65.5), "1. HCON.split(str) (L60–62)", style=Styles.PrimaryBold.patch(text_size=10.3))
text(
    (30, 56.0),
    "Top-level comma splitter\nPreserves commas inside:\n[...], (...), <.../>, \"...\", '...'",
    style=Styles.Dark.patch(text_size=9.5),
)

line((51.5, 58.5), (56.5, 58.5), arrow_head="->", style=Styles.PrimaryBold)

rectangle((78, 58.5), width=43, height=21, style=Styles.PrimaryFlat.patch(shape_r=1.8))
text((78, 65.5), "2. HCON.parse(str) (L19–50)", style=Styles.WhiteBold.patch(text_size=10.3))
text(
    (78, 56.0),
    "• startsWith('{') -> JSON.parse\n• 7-group regex + default 'true'\n• reduceRight dotted keys (a.b:1)",
    style=Styles.White.patch(text_size=9.5),
)

line((99.5, 58.5), (104.5, 58.5), arrow_head="->", style=Styles.PrimaryBold)

rectangle((126, 58.5), width=43, height=21, style=Styles.SecondaryNeutral.patch(shape_r=1.8))
text((126, 65.5), "3. HCON.merge(src, dst) (L71)", style=Styles.SecondaryBold.patch(text_size=10.3))
text(
    (126, 56.0),
    "• Deep plain-Object merge\n• Blocks __proto__, constructor,\n  and prototype keys (L75)",
    style=Styles.Dark.patch(text_size=9.5),
)

# Bottom Panel: __attributeValue & Object Evaluation (L245–320, L1875–1893)
rectangle((78, 23.5), width=146, height=35, style=Styles.Neutral.patch(shape_r=2.5))
phosphor.tree_structure((11, 36.5), width=4.5, style=Styles.SecondaryBold)
text(
    (80, 36.5),
    "Pillar 2: __attributeValue() — Explicit :inherited / :append Resolution & Dynamic js: Evaluation",
    style=Styles.DarkBold.patch(text_size=11.2),
)

rectangle((24.5, 19.5), width=32, height=21, style=Styles.White.patch(shape_r=1.8))
text((24.5, 26.5), "1. Self Lookup (L293)", style=Styles.DarkBold.patch(text_size=10.0))
text(
    (24.5, 17.0),
    "__attr(elt, name) ??\n__attr(elt, name+':inherited')\nChecks hx-* & data-hx-*",
    style=Styles.Dark.patch(text_size=9.5),
)

line((40.5, 19.5), (44.5, 19.5), arrow_head="->", style=Styles.DarkBold)

rectangle((60.5, 19.5), width=32, height=21, style=Styles.PrimaryNeutral.patch(shape_r=1.8))
text((60.5, 26.5), "2. :append Chain (L299)", style=Styles.PrimaryBold.patch(text_size=10.0))
text(
    (60.5, 17.0),
    "Resolves ancestor parentVal\nConcatenates (parentVal+','+\nappendVal).replace(/[{}]/g,'')",
    style=Styles.Dark.patch(text_size=9.5),
)

line((76.5, 19.5), (80.5, 19.5), arrow_head="->", style=Styles.DarkBold)

rectangle((96.5, 19.5), width=32, height=21, style=Styles.SecondaryNeutral.patch(shape_r=1.8))
text((96.5, 26.5), "3. :inherited Walk (L311)", style=Styles.SecondaryBold.patch(text_size=10.0))
text(
    (96.5, 17.0),
    "elt.parentNode.closest(\n  [hx-*:inherited] )\nFires implicitInheritance hook",
    style=Styles.Dark.patch(text_size=9.5),
)

line((112.5, 19.5), (116.5, 19.5), arrow_head="->", style=Styles.DarkBold)

rectangle((131.5, 19.5), width=31, height=21, style=Styles.White.patch(shape_r=1.8))
text((131.5, 26.5), "4. Object Eval (L1875)", style=Styles.DarkBold.patch(text_size=10.0))
text(
    (131.5, 17.0),
    "__getAttributeObject()\nStatic -> sync HCON.parse\njs: -> async #AsyncFunction",
    style=Styles.Dark.patch(text_size=9.5),
)

save()
```

---

## 1. `HCON`（htmx Configuration Object Notation）パーサ（`L10–88`）

htmx 2.x では、属性ごとに異なる設定構文が混在していました。`hx-vals` や `hx-headers` は二重引用符を強制する厳密な JSON（`hx-vals='{"count": 5}'`）を要求する一方、`hx-swap` や `hx-trigger` は独自の空白・コロントークナイザで解析されていました。**htmx v4.0.1** はこれらの個別パーサをすべて廃止し、標準 JSON との 100% の後方互換性（`if (string.startsWith('{')) return JSON.parse(string)`, `L21`）を維持しつつ波括弧不要のキー・バリュー対を解析する統一ミニ言語 **`HCON`**（`L10–88`）へと統合しました。

`HCON` は `<meta name="htmx-config">`（`L210`）、`hx-trigger` の修飾子解析（`__parseTriggerSpecs`, `L329`）、`HX-Trigger` 応答ヘッダ解析（`__handleTriggerHeader`, `L876`）、`hx-swap` の修飾子解析（`__insertContent`, `L1361`）、`hx-vals` および `hx-headers`（`__getAttributeObject`, `L1891`）、そして `hx-status:*` ステータスコード別オーバライド（`__handleStatusCodes`, `L2282`）のすべてで共通利用されています。

### 1.1 `HCON.parse()` における 7 キャプチャグループ正規表現レキサー（`L19–50`）

`HCON.parse(string)` に `{` で始まらない非空文字列が渡されると、7 つのキャプチャグループを持つ単一のマスター正規表現を用いて `string.matchAll(pattern)`（`L22–24`）を反復処理します。

```javascript
// src/htmx.js L10–88 — Complete HCON Parser, Context-Aware Splitter & Prototype-Safe Deep Merger
const HCON = {
    parse(string) {
        if (!string) return {};
        if (string.startsWith('{')) return JSON.parse(string);
        let pattern = /(?:"([^"]+)"|'([^']+)'|([^\s,:]+))(?:\s*:\s*(?:"([^"]*)"|'([^']*)'|<((?:[^/]|\/(?!>))+)\/>|([^\s,]+)))?(?=\s|,|$)/g;
        let result = {};
        for (let match of string.matchAll(pattern)) {
            let [,
                doubleQuotedKey,    // Group 1: "key"
                singleQuotedKey,    // Group 2: 'key'
                bareKey,            // Group 3:  key
                doubleQuotedValue,  // Group 4: "value"
                singleQuotedValue,  // Group 5: 'value'
                hyperscriptValue,   // Group 6: <value/>
                bareValue,          // Group 7:  value
            ] = match;

            // pick this match's key and value forms
            let key = doubleQuotedKey ?? singleQuotedKey ?? bareKey;
            let value = (doubleQuotedValue ?? singleQuotedValue ?? hyperscriptValue ?? bareValue ?? 'true').trim();

            // JSON-parse if possible (e.g. "5" -> 5; "abc" stays string)
            try { value = JSON.parse(value); } catch {}

            // bare a.b -> {a:{b:...}}; quoted "a.b" -> {"a.b":...}
            let isDottedPath = bareKey?.includes('.');
            let pair = isDottedPath
                ? key.split('.').reduceRight((acc, segment) => ({[segment]: acc}), value)
                : {[key]: value};
            HCON.merge(pair, result);
        }
        return result;
    },

    split(string) {
        return string.split(/,(?![^\[]*\])(?![^(]*\))(?![^<]*\/>)(?=(?:[^"']|"[^"]*"|'[^']*')*$)/);
    },

    merge(source, target) {
        if (typeof source === 'string') source = HCON.parse(source);

        for (let [key, val] of Object.entries(source)) {
            if (['__proto__', 'constructor', 'prototype'].includes(key)) continue;

            let sourceIsObject = val?.constructor === Object;
            let targetIsObject = target[key]?.constructor === Object;

            if (sourceIsObject && targetIsObject) {
                HCON.merge(val, target[key]);
            } else {
                target[key] = val;
            }
        }
        return target;
    },
};
```

マッチした各トークンは、以下の 4 段階の変換ステップ（`L36–47`）を経てオブジェクトへ統合されます。

1. **キー・バリュー抽出と値省略時の暗黙 `'true'` 補完（`L36–37`）**：Null 合体演算子（`doubleQuotedKey ?? singleQuotedKey ?? bareKey`）でキーを選択します。値グループ全体 `(?:\s*:\s*...)` が任意（`?`）であるため、`hx-swap="outerHTML transition swap:100ms"` の `outerHTML` や `transition` のようなコロンを持たない単独フラグは自動的に `'true'` へと補完されます。
2. **`JSON.parse()` による日和見型変換（`L40`）**：`try { value = JSON.parse(value); } catch {}` により、数値文字列（`"5"` $\rightarrow$ `5`）、真偽値（`"true"` $\rightarrow$ `true`、`"false"` $\rightarrow$ `false`）、`null`、インライン配列・オブジェクトがネイティブの JavaScript 型へ変換されます。一方、`JSON.parse` が例外を投げた非引用符文字列（`"innerHTML"` や `"100ms"`）はそのまま文字列として保持されます。
3. **非引用符ドットパス展開と引用符付きリテラルキーの区別（`L43–46`）**：`bareKey?.includes('.')` が真の場合に限り、キーを `.` で分割して右から左へ畳み込み（`key.split('.').reduceRight((acc, segment) => ({[segment]: acc}), value)`）、`sse.mode:once` をネストされた `{sse: {mode: "once"}}` へと展開します。もしキーが引用符で囲まれていた場合（`"sse.mode":once` や `'a.b':1`）、`bareKey` は `undefined` となるためドット展開は行われず、フラットなキー `{"sse.mode": "once"}` がそのまま維持されます。
4. **インクリメンタルなディープマージ（`L47`）**：生成された `pair` を `HCON.merge(pair, result)` で `result` にマージするため、`user.name:alice user.role:admin` のような複数のドットキーが `{user: {name: "alice", role: "admin"}}` へと綺麗に統合されます。

| キャプチャグループ | 正規表現サブパターン | 構文例 | 抽出されるトークンと動作 |
| :--- | :--- | :--- | :--- |
| **Group 1 (`doubleQuotedKey`)** | `"([^"]+)"` | `"user.name":alice` | キー `"user.name"`（フラットなプロパティとして保持。ドット展開は無効）。 |
| **Group 2 (`singleQuotedKey`)** | `'([^']+)'` | `'X-CSRF-Token':abc` | キー `"X-CSRF-Token"`（ハイフンやドット等の特殊文字を保持）。 |
| **Group 3 (`bareKey`)** | `([^\s,:]+)` | `swap:100ms` / `a.b:1` | キー `"swap"` またはドットパス `"a.b"`（`reduceRight` で `{a: {b: 1}}` に展開）。 |
| **Group 4 (`doubleQuotedValue`)** | `"([^"]*)"` | `from:".a, .b"` | 値 `".a, .b"`（空白、コロン、カンマを含む文字列を保持）。 |
| **Group 5 (`singleQuotedValue`)** | `'([^']*)'` | `target:'#main > div'` | 値 `"#main > div"`（二重引用符の HTML 属性内でエスケープ不要で記述可能）。 |
| **Group 6 (`hyperscriptValue`)** | `<((?:[^/]\|\/(?!>))+)\/>` | `from:<button:not(.x)/>` | 値 `"button:not(.x)"`（外側の `<.../>` デリミタを除去して抽出）。 |
| **Group 7 (`bareValue`)** | `([^\s,]+)` | `delay:300ms` / `count:5` | 値 `"300ms"`（文字列）または `5`（`JSON.parse` により数値 `number` へ変換）。 |
| **値省略時 (`undefined`)** | *(任意グループ省略)* | `outerHTML transition` | `'true'` にデフォルト補完（`L37`）され、真偽値 `true`（`{outerHTML: true, transition: true}`）へ変換。 |

### 1.2 文脈認識型カンマ分割（`HCON.split`）とプロトタイプ汚染防御付きマージ（`HCON.merge`）

```drawlib align=center code=fold file=arch_c02_hcon_parser_pipeline.png caption="HCON.split() の先読みガード、HCON.parse() のドットキー畳み込み、および HCON.merge() のプロトタイプ汚染防御"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import ChevronProcess, Table
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=78, dpi=150)

text(
    (78, 73.5),
    "HCON Parsing & Deep-Merge Pipeline (src/htmx.js L10–88)",
    style=Styles.DarkBold.patch(text_size=12.0),
)

steps = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=10.2),
    description_style=Styles.Dark.patch(text_size=9.5),
    corner_angle=60.0,
    spacing=1.2,
    flat_left_end=True,
)
steps.add(
    "1. JSON Fast-Path",
    description="string.startsWith('{')\n-> JSON.parse(string) (L21)",
    style=Styles.Neutral,
)
steps.add(
    "2. 7-Group Lexer",
    description="matchAll(pattern) (L24)\nKeys, Values & <.../>",
    style=Styles.PrimaryNeutral,
)
steps.add(
    "3. Type Coercion",
    description="Default 'true' (L37)\ntry JSON.parse(val) (L40)",
    style=Styles.SecondaryNeutral,
)
steps.add(
    "4. Dotted Folding",
    description="bareKey?.includes('.')\nreduceRight nesting (L45)",
    style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.2),
    description_style=Styles.White.patch(text_size=9.5),
)
steps.add(
    "5. Safe Deep Merge",
    description="HCON.merge(pair, res)\nBlocks __proto__ (L75)",
    style=Styles.PrimaryNeutral,
)
steps.draw(xy=(6, 54), width=144, height=15)

table = Table(
    cell_style=Styles.White,
    text_style=Styles.Dark.patch(text_size=9.8),
    header_cell_style=Styles.PrimaryFlat,
    header_text_style=Styles.WhiteBold.patch(text_size=10.2),
    border_style=Styles.MutedThin,
)
table.draw_flexible(
    xy=(6, 48),
    column_widths=[36.0, 52.0, 56.0],
    row_heights=[6.8, 6.8, 6.8, 6.8, 6.8, 6.8],
    data=[
        ["HCON Operation", "Input Attribute / Expression", "Resulting JavaScript Value / Security Behavior"],
        ["Valueless Flags & Coercion", "HCON.parse('outerHTML swap:100ms count:5')", "{ outerHTML: true, swap: '100ms', count: 5 }"],
        ["Bare Dotted vs. Quoted Key", "HCON.parse('a.b:1 \"c.d\":2')", "{ a: { b: 1 }, 'c.d': 2 } (only bareKey folds)"],
        ["Hyperscript <.../> Value", "HCON.parse('from:<button.active, a.nav/>')", "{ from: 'button.active, a.nav' }"],
        ["Context-Aware HCON.split()", "HCON.split('click[a,b], from:\".x, .y\", load')", "['click[a,b]', ' from:\".x, .y\"', ' load']"],
        ["Prototype Pollution Guard", "HCON.parse('__proto__.polluted:true')", "{} — Key '__proto__' skipped at L75!"],
    ],
)

save()
```

- **文脈認識型カンマ分割（`HCON.split`, `L60–62`）**：
  `hx-trigger='click[ctrlKey, shiftKey], keyup from:".a, .b", intersect root:<#vp, .box/>'` のような属性では、カンマがトップレベルの区切り文字としてだけでなく、フィルタ角括弧内や CSS セレクタ文字列内、あるいは `<.../>` リテラル内にも出現します。`HCON.split` は `,` の直後に 4 つの先読みアサーション（Lookahead）を配置することで、トップレベルのカンマのみを正確に分割します。
  - `(?![^\[]*\])`：開き `[` を挟まずに閉じ `]` が続く位置（`[filter]` 角括弧の内部）では分割しない。
  - `(?![^(]*\))`：`(...)` 丸括弧の内部（`:not(.a, .b)` や関数呼び出し引数）では分割しない。
  - `(?![^<]*\/>)`：`<.../>` Hyperscript セレクタリテラルの内部では分割しない。
  - `(?=(?:[^"']|"[^"]*"|'[^']*')*$)`：文字列末尾までに残る `"..."` および `'...'` の引用符ペアが偶数個（バランスしている状態）である位置でのみ分割する。
- **`HCON.merge(source, target)` におけるプロトタイプ汚染防御（`L71–87`）**：
  `HCON.parse` はドット区切りキーを展開し（`__proto__.isAdmin:true` $\rightarrow$ `{ ["__proto__"]: { isAdmin: true } }`）、またサーバからの `HX-Trigger` 応答ヘッダや DOM 属性文字列をマージするため、`HCON.merge` は以下の 2 つの厳格なセキュリティガードを実装しています。
  1. **危険なキー名の明示的ブラックリスト（`L75`）**：`if (['__proto__', 'constructor', 'prototype'].includes(key)) continue;` により、`Object.prototype` への汚染を完全に遮断します。
  2. **厳密なプレーンオブジェクト判定（`L77–80`）**：`val?.constructor === Object && target[key]?.constructor === Object` を検証することで、配列や DOM ノード、カスタムクラスのインスタンスに対して誤って再帰マージが行われるのを防ぎます。

---

## 2. プレフィックスフォールバックとカスタム `metaCharacter` 正規化（`L245–263`, `L2360–2366`）

htmx v4 は、HTML5 バリデータ準拠の `data-hx-*` 記述や、コロン文字 `:` を予約構文として使用するテンプレートエンジン（Vue の `:attr` 省略記法や XML 名前空間パーサなど）との衝突を回避するため、`src/htmx.js` 内に以下の 4 つの正規化ヘルパーを備えています。

1. **デュアル属性値ルックアップ（`__attr(elt, name)`, `L245–248`）**：まず `elt.getAttribute(name)`（例：`hx-get`）を検索し、存在しない場合は `this.config.prefix`（デフォルト `"data-hx-"`）に置換した `elt.getAttribute(name.replace('hx-', p))` へフォールバックします。
2. **一致属性名の解決（`__attrName(elt, name)`, `L250–253`）**：要素 `elt` 上に実際に存在する属性名（`hx-vals:append` または `data-hx-vals:append`）を返します。`__attributeValue()`（`L299–301`）がプレフィックスの有無に関わらず `:append` 属性値を読み取るために使用されます。
3. **CSS セレクタのプレフィックス展開（`__prefixes(s)` & `__prefixSelector(s)`, `L255–263`）**：任意のセレクタ文字列 `s` に含まれる `'hx-'` を `this.config.prefix` に置換した文字列を複製して `,` で結合します（例：`[hx-target:inherited]` $\rightarrow$ `[hx-target:inherited],[data-hx-target:inherited]`）。
4. **カスタム `metaCharacter` による動的置換（`__maybeAdjustMetaCharacter(string)`, `L2360–2366`）**：`this.config.metaCharacter` が設定されている場合（例：`htmx.config.metaCharacter = '@'` や `'_'`）、内部の `:inherited` 修飾子、`:append` 修飾子（`L289–291`）、`hx-on` の区切り文字（`L1726`）、および発火するすべての `htmx:phase:action` イベント名（`__trigger` `L1513`）に含まれる `:` が動的に `this.config.metaCharacter` へと書き換えられます。

```javascript
// src/htmx.js L245–263, L2360–2366 — Prefix Fallback & metaCharacter Normalization
__attr(elt, name) {
    let p = this.config.prefix;
    return elt.getAttribute(name) ?? (p ? elt.getAttribute(name.replace('hx-', p)) : null);
}

__attrName(elt, name) {
    let p = this.config.prefix && name.replace('hx-', this.config.prefix);
    return elt.hasAttribute(name) ? name : (p && elt.hasAttribute(p) ? p : null);
}

__prefixSelector(s) {
    return this.__prefixes(s).join(',');
}

__prefixes(s) {
    let result = [s];
    if (this.config.prefix) result.push(s.replaceAll('hx-', this.config.prefix));
    return result;
}

__maybeAdjustMetaCharacter(string) {
    if (this.config.metaCharacter) {
        return string.replace(/:/g, this.config.metaCharacter);
    } else {
        return string;
    }
}
```

---

## 3. 明示的 `:inherited` / `:append` 属性解決エンジン（`__attributeValue` L288–320）

htmx 2.x では、ほぼすべての `hx-*` 属性（`hx-target`, `hx-swap`, `hx-select`, `hx-confirm`, `hx-vals`, `hx-headers`, `hx-boost` など）が DOM ツリー全体にわたって暗黙的に継承されていたため、コンテナ要素に指定した属性が意図せず深い子孫コンポーネントにまで波及し、`hx-disinherit` による打ち消しを強いられる問題がありました。

**htmx v4.0.1** では、`this.config.implicitInheritance` のデフォルト値が **`false`**（`L204`）に変更されました。属性継承は、`__attributeValue()`（`L288–320`）が解決する以下の 2 つの明示的なサフィックス修飾子を用いたオプトイン方式となっています。

- **`hx-<attr>:inherited="..."`**：祖先要素に指定された値を、その祖先自身および `hx-<attr>` を上書きしていないすべての子孫要素に継承させます。
- **`hx-<attr>:append="..."` および `hx-<attr>:inherited:append="..."`**：祖先から継承した値を上書きするのではなく、カンマ区切りで追加の値（追加の `hx-vals` キー、`hx-headers` エントリ、`hx-include` セレクタ、`hx-indicator` ターゲットなど）を末尾に連結します。

```drawlib align=center code=fold file=arch_c02_attribute_inheritance_flow.png caption="__attributeValue(elt, name, defaultVal, eltCollector, allowInheritance) における属性・祖先解決フロー"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=156, height=82, dpi=150)

text(
    (78, 77.5),
    "__attributeValue(elt, name, defaultVal, eltCollector, allowInheritance) (L288–320)",
    style=Styles.DarkBold.patch(text_size=12.0),
)

# Step 1: Meta-character & Self Lookup
rectangle((40, 62), width=64, height=18, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
phosphor.magnifying_glass((12, 66.5), width=4.2, style=Styles.PrimaryBold)
text((42, 66.5), "Step 1: Direct Self Lookup (L289–294)", style=Styles.PrimaryBold.patch(text_size=10.5))
text(
    (40, 58.0),
    "val = __attr(elt, name) ?? __attr(elt, name + ':inherited')\n"
    "If val != null -> return eltCollector ? eltCollector(val, elt) : val",
    style=Styles.Dark.patch(text_size=9.5),
)

line((72, 62), (84, 62), arrow_head="->", style=Styles.DarkBold)

# Step 2: Build Escaped Selector
rectangle((116, 62), width=64, height=18, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.funnel((88, 66.5), width=4.2, style=Styles.DarkBold)
text((118, 66.5), "Step 2: CSS.escape Ancestor Selector (L296–298)", style=Styles.DarkBold.patch(text_size=10.5))
text(
    (116, 58.0),
    "n1 = CSS.escape(allowInheritance ? name : name + ':inherited')\n"
    "n2 = CSS.escape(name + ':inherited:append')\n"
    "inheritSelector = __prefixSelector('[' + n1 + '],[' + n2 + ']')",
    style=Styles.Dark.patch(text_size=9.5),
)

line((116, 53), (116, 46), arrow_head="->", style=Styles.DarkBold)

# Step 3: Local :append / :inherited:append Branch
rectangle((116, 34), width=64, height=24, style=Styles.PrimaryFlat.patch(shape_r=2.0))
phosphor.git_merge((88, 41.5), width=4.2, style=Styles.WhiteBold)
text((118, 41.5), "Step 3: :append / :inherited:append (L299–309)", style=Styles.WhiteBold.patch(text_size=10.5))
text(
    (116, 30.0),
    "If elt has 'name:append' or 'name:inherited:append':\n"
    "1. parent = elt.parentNode?.closest(inheritSelector)\n"
    "2. parentVal = __attributeValue(parent, name, ...)\n"
    "3. Return (parentVal + ',' + appendValue).replace(/[{}]/g, '')\n"
    "   (Strips JSON braces so HCON.parse merges seamlessly!)",
    style=Styles.White.patch(text_size=9.5),
)

line((84, 34), (72, 34), arrow_head="->", style=Styles.DarkBold)

# Step 4: Ancestor :inherited Walk
rectangle((40, 34), width=64, height=24, style=Styles.SecondaryNeutral.patch(shape_r=2.0))
phosphor.arrow_fat_lines_up((12, 41.5), width=4.2, style=Styles.SecondaryBold)
text((42, 41.5), "Step 4: Ancestor closest() Lookup (L311–319)", style=Styles.SecondaryBold.patch(text_size=10.5))
text(
    (40, 30.0),
    "parent = elt.parentNode?.closest(inheritSelector)\n"
    "If parent found -> val = __attributeValue(parent, name, ...)\n"
    "If allowInheritance -> fires 'htmx:after:implicitInheritance'\n"
    "Else -> return defaultVal",
    style=Styles.Dark.patch(text_size=9.5),
)

# Bottom Callout: Non-Inheritable Attributes
rectangle((78, 11.5), width=140, height=13, style=Styles.Neutral.patch(shape_r=2.0))
phosphor.shield_check((14, 11.5), width=4.5, style=Styles.DarkBold)
text(
    (80, 14.0),
    "Hard-Coded Non-Inheritable Attributes (allowInheritance = false even if config.implicitInheritance === true)",
    style=Styles.DarkBold.patch(text_size=10.3),
)
text(
    (78, 9.0),
    "hx-action (L335) • hx-get / hx-post / hx-put / hx-patch / hx-delete / hx-query (L338) • hx-validate (L403) • hx-trigger (L735)",
    style=Styles.Dark.patch(text_size=9.6),
)

save()
```

### 3.1 `__attributeValue()` のステップバイステップ解析（`L288–320`）

```javascript
// src/htmx.js L280–320 — __findThisElements() and __attributeValue()
__findThisElements(elt, attrName) {
    let result = [];
    this.__attributeValue(elt, attrName, undefined, (val, elt) => {
        if (val?.split(/\s*[,:]\s*/).includes('this')) result.push(elt);
    });
    return result;
}

__attributeValue(elt, name, defaultVal, eltCollector, allowInheritance = this.config.implicitInheritance) {
    name = this.__maybeAdjustMetaCharacter(name);
    let inherited = this.__maybeAdjustMetaCharacter(":inherited");
    let append = this.__maybeAdjustMetaCharacter(":append");

    let val = this.__attr(elt, name) ?? this.__attr(elt, name + inherited);
    if (val != null) return eltCollector ? eltCollector(val, elt) : val;

    let n1 = CSS.escape(allowInheritance ? name : name + inherited);
    let n2 = CSS.escape(name + inherited + append);
    let inheritSelector = this.__prefixSelector(`[${n1}],[${n2}]`);
    let appendName = this.__attrName(elt, name + append) ?? this.__attrName(elt, name + inherited + append);
    if (appendName) {
        let appendValue = elt.getAttribute(appendName);
        let parent = elt.parentNode?.closest?.(inheritSelector);
        if (eltCollector) eltCollector(appendValue, elt);
        if (parent) {
            let parentVal = this.__attributeValue(parent, name, undefined, eltCollector, allowInheritance);
            return parentVal ? (parentVal + "," + appendValue).replace(/[{}]/g, '') : appendValue;
        }
        return appendValue;
    }

    let parent = elt.parentNode?.closest?.(inheritSelector);
    if (parent) {
        val = this.__attributeValue(parent, name, undefined, eltCollector);
        if (!eltCollector && val && allowInheritance) {
            this.__triggerExtensions(elt, "htmx:after:implicitInheritance", {elt, name, parent});
        }
        return val;
    }
    return defaultVal;
}
```

`__attributeValue()` の実装には、4 つの重要なアーキテクチャ上の工夫が込められています。

1. **`CSS.escape` と `closest()` によるネイティブ C++ 祖先ジャンプ（`L296–298`, `L302`, `L311`）**：JavaScript の `while (elt = elt.parentElement)` ループで 1 階層ずつ親を辿るのではなく、`CSS.escape()` で `hx-attr:inherited` や `hx-attr:inherited:append` のコロンをエスケープした上で `elt.parentNode?.closest?.(inheritSelector)` を呼び出し、ブラウザのネイティブ C++ セレクタエンジンによって最も近い継承元祖先へ一気にジャンプします。
2. **波括弧除去 `.replace(/[{}]/g, '')` による JSON と HCON のシームレス連結（`L306`）**：祖先要素が JSON 形式で `hx-vals:inherited='{"a": 1}'` を指定し、子要素が `hx-vals:append='{"b": 2}'`（または HCON 形式の `b:2`）を指定した場合、`(parentVal + "," + appendValue).replace(/[{}]/g, '')` によって中括弧 `{}` が取り除かれ、`"a": 1, "b": 2` という連結文字列が生成されます。`HCON.parse()` は引用符付きキーと裸の HCON キーの混在をそのまま解析できるため、**任意の DOM 階層にわたって JSON 記法と HCON 記法を自在に `:append` 合成できます**。
3. **`:append` チェーン全体の `this` 要素を収集する `eltCollector` パターン（`__findThisElements`, `L280–286`）**：親 `<form>` に `hx-indicator:inherited="this"`、子 `<button>` に `hx-indicator:append="this"` が指定されている場合、`__findAllExt()`（`L1936`）は `__findThisElements(elt, "hx-indicator")` を呼び出します。`__attributeValue()` に `eltCollector` コールバックを渡すことで、`:append` 継承チェーン上で `"this"` を宣言したすべての要素 `[button, form]` を漏れなく収集します。
4. **暗黙継承がハードコードで禁止された属性群（`allowInheritance = false`）**：アクション属性（`L335` の `hx-action` および `L338` の `hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, `hx-query`）、`hx-validate`（`L403`）、および `hx-trigger`（`L735`）は第 5 引数 `allowInheritance` に明示的に `false` を渡します。これにより、仮に `htmx.config.implicitInheritance = true` を有効化した場合（または `L315` の `htmx:after:implicitInheritance` フックを監視する `src/ext/htmx-2-compat.js` を読み込んだ場合）であっても、`:inherited` を明記しない限り HTTP メソッドやトリガーが子要素へ誤って継承されることはありません。

---

## 4. 静的 HCON の同期評価と動的 `js:` オブジェクトの非同期評価（`__getAttributeObject` L1875–1893）

キー・バリューマップを返す属性（具体的には `L480` の **`hx-headers`** と `L489` の **`hx-vals`**）は、`__getAttributeObject(elt, attrName, callback, scope)`（`L1875–1893`）を通じて評価されます。

```javascript
// src/htmx.js L1875–1893, L1996–2004 — Synchronous HCON Fast-Path vs. Async js: Evaluation
__getAttributeObject(elt, attrName, callback, scope = {}) {
    let hxAttr = this.__attributeValue(elt, attrName);
    if (!hxAttr) return null;

    let javascriptContent = this.__extractJavascriptContent(hxAttr);
    if (javascriptContent) {
        // Wrap in braces if not already wrapped (for htmx 2.x compatibility)
        if (javascriptContent.indexOf('{') !== 0) {
            javascriptContent = '{' + javascriptContent + '}';
        }
        // Return promise for async evaluation
        return this.__executeJavaScript(elt, scope, javascriptContent, true).then(obj => {
            callback(obj);
        });
    } else {
        // Synchronous path - return the parsed object directly
        callback(HCON.parse(hxAttr));
    }
}

__extractJavascriptContent(string) {
    if (string != null) {
        if (string.startsWith("js:")) {
            return string.substring(3);
        } else if (string.startsWith("javascript:")) {
            return string.substring(11);
        }
    }
}
```

この分岐設計により、パフォーマンスと柔軟性の双方が最適化されています。

- **マイクロタスク遅延ゼロの同期ファストパス（`L1889–1892`）**：`hx-vals` や `hx-headers` が静的な HCON または JSON（例：`hx-vals="page:2 sort:'asc'"`）である場合、`__extractJavascriptContent(hxAttr)` は `undefined` を返します。`__getAttributeObject` は即座に `callback(HCON.parse(hxAttr))` を同期実行して `undefined` を返すため、`htmx:config:request` 発火前に不要な `Promise` アロケーションやマイクロタスク待機が一切発生しません。
- **非同期 `js:` / `javascript:` 評価パス（`L1880–1888`）**：`js:` または `javascript:` プレフィックスが付与されている場合（例：`hx-vals="js:{ token: await getAuthToken(), ts: Date.now() }"` や波括弧なしの `hx-vals="js:ts: Date.now()"`）、先頭が `{` でなければ `{...}` でラップ（`L1882–1884`）した上で `this.__executeJavaScript(elt, scope, javascriptContent, true)` を実行します。`__executeJavaScript` はデフォルトで `this.#AsyncFunction`（`L911, L922`）を使用するため、動的な `hx-vals` や `hx-headers` の内部で `await` 式をそのまま記述でき、`__handleTriggerEvent`（`L480–495`）は返された `Promise` を `await Promise.all(promises)` で待機します。
