# 3. トリガーと拡張セレクタ解析

htmx v4.0.1は、従来の固定的な正規表現による属性パーサを廃止し、`HCON` の上に構築された2つの合成可能なマイクロエンジンに置き換えています。1つ目は **3層トリガークロージャ合成器**（`__parseTriggerSpecs` および `__onTrigger`、322〜331行目・734〜872行目）、2つ目は Shadow DOM 境界・属性継承チェーン・文書順序ビットマスクを横断する **拡張CSSセレクタエンジン**（`__findAllExt`、1895〜1994行目）です。

```drawlib align=center code=fold file=arch_c03_trigger_selector_hero.png caption="htmx v4.0.1 トリガー字句解析器・3層クロージャ合成器・拡張セレクタエンジン"
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

text((72, 65.5), "Trigger Compilation & Extended Selector Resolution Pipeline", style=title_s)
text((72, 61.5), "src/htmx.js — __initializeTriggers (L734), __parseTriggerSpecs (L322), __onTrigger (L744) & __findAllExt (L1900)", style=sub_s)

# Top pipeline using ChevronProcess
pipeline = ChevronProcess(
    style=Styles.Neutral,
    text_style=Styles.DarkBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD),
    description_style=Styles.Dark.patch(text_size=10.0, text_font=FontRoboto.ROBOTO_REGULAR),
    corner_angle=60.0,
    spacing=1.5,
    flat_left_end=True,
)
pipeline.add("1. Default & Lexer", description="HCON.split + HCON.parse", style=Styles.PrimaryNeutral)
pipeline.add("2. Source Resolution", description="from: & __findAllExt()", style=Styles.Neutral)
pipeline.add("3. 3-Layer Closure", description="Guard -> Timed -> Inner", style=Styles.PrimaryFlat,
             text_style=Styles.WhiteBold.patch(text_size=11.0),
             description_style=Styles.White.patch(text_size=10.0))
pipeline.add("4. Lifecycle Wiring", description="DOM / Observer / Timer", style=Styles.SecondaryNeutral)

pipeline.draw(xy=(6, 43), width=132, height=14)

# Bottom architectural detail cards (4 columns aligned under chevrons)
cards = [
    (21.5, "Trigger Spec AST", "__parseTriggerSpecs(L322)", "every 1s [c] -> every[c]\n{name, ...HCON.parse()}", Styles.Neutral, False),
    (55.0, "Extended Selectors", "__findAllExt (L1900)", "global / closest / find\nnext / previous / this", Styles.PrimaryNeutral, False),
    (88.5, "Closure Synthesis", "__onTrigger (L744)", "L1: spec.handler (guard)\nL2: timed (delay/throt)\nL3: inner (changed/once)", Styles.AccentFlat, True),
    (122.0, "Element State", "elt._htmx & _htmx_state", "triggerSpecs / listeners\nchangedValues WeakMap", Styles.Neutral, False),
]

for cx, heading, fn_label, body_txt, box_style, is_focal in cards:
    rectangle((cx, 20.5), width=31.0, height=29.0, style=box_style.patch(shape_r=2.0))
    line((cx, 42.5), (cx, 35.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.5))
    t_style = white_title_s if is_focal else card_title_s
    c_style = white_code_s if is_focal else code_s
    text((cx + 2.2, 30.5), heading, style=t_style)
    text((cx, 25.0), fn_label, style=c_style)
    text((cx, 14.5), body_txt, style=c_style)

phosphor.lightning((9.5, 30.5), width=3.8, style=Styles.DarkBold)
phosphor.magnifying_glass((43.0, 30.5), width=3.8, style=Styles.DarkBold)
phosphor.funnel((76.5, 30.5), width=3.8, style=Styles.WhiteBold)
phosphor.database((110.0, 30.5), width=3.8, style=Styles.DarkBold)

save()
```

---

## 3.1 デフォルトトリガー解決（`__initializeTriggers`）

`process(root)` が `#actionSelector`（`[hx-action],[hx-get],[hx-post],[hx-put],[hx-patch],[hx-delete],[hx-query]`）に一致する要素やブーストされた `<a>`/`<form>` を初期化する際、`__initializeElement(elt)`（365〜373行目）はまず `elt._htmx.eventHandler = this.__createHtmxEventHandler(elt)` を設定し、続いて `__initializeTriggers(elt)`（734〜740行目）を呼び出します。

```javascript
__initializeTriggers(elt, initialHandler = elt._htmx.eventHandler) {
    let hxTrigger = this.__attributeValue(elt, "hx-trigger", undefined, undefined, false);
    let trigger = hxTrigger || (elt.matches("form") ? "submit" :
        elt.matches("input:not([type=button]):not([type=submit]),select,textarea") ? "change" :
            "click");
    this.__onTrigger(elt, trigger, initialHandler)
}
```

デフォルトトリガー解決には2つの重要な設計上の不変条件があります。

1. **暗黙的継承の無効化（`allowInheritance = false`）**: `__attributeValue(elt, "hx-trigger", undefined, undefined, false)` は、グローバル設定の `htmx.config.implicitInheritance` が有効であっても暗黙的継承を明示的に無効化します。親要素の `hx-trigger` は、祖先が明示的に `hx-trigger:inherited` を指定した場合にのみ継承されます。
2. **タグ種別に応じた自然なデフォルト**: `hx-trigger` が省略された場合、htmx は `elt.matches(...)` で要素を判定します。
   - `<form>` 要素は `submit` を監視します。
   - 編集可能なフォームコントロール（`input:not([type=button]):not([type=submit]),select,textarea`）は `change` を監視します。
   - その他すべての要素（`<button>`、`<input type="button">`、`<input type="submit">`、`<a>`、`<div>` など）は `click` を監視します。

---

## 3.2 トリガー仕様レキサー（`__parseTriggerSpecs` と `__extractFilter`）

トリガー文字列が決定すると、`__parseTriggerSpecs(spec)`（322〜331行目）は（[第2章](02_attribute_inheritance_and_hcon.md)で解説した）`HCON` を用いて、正規化されたトリガー仕様オブジェクトの配列へとコンパイルします。

```javascript
__parseTriggerSpecs(spec) {
    return HCON.split(spec).flatMap(s => {
        // support `every 1s [cond]` by moving it next to `every`
        s = s.replace(/^\s*every\s+(\S+?)\s*(\[[^\]]*\])/, 'every$2 $1');
        let [,name,rest] = s.match(/^\s*(\S+\[[^\]]*\]|\S+)\s*(.*?)\s*$/) ?? [];
        if (!name) return [];  // skip empty/whitespace-only tokens
        if (/\[[^\]]*$/.test(name)) throw "unterminated:" + name;  // e.g. click[ctrlKey
        return [{name, ...HCON.parse(rest)}];  // spread modifiers (delay, throttle, etc.) onto result
    });
}
```

### マルチステップ字句解析パイプライン

1. **トップレベルカンマ分割（`HCON.split(spec)`）**: ネストされた角括弧 `[...]`・波括弧 `{...}`・クォートを認識しながらカンマ区切りのトリガー定義（例: `hx-trigger="mouseenter once, click[ctrlKey] delay:300ms"`）を分割するため、JSフィルタ式内部のカンマ（`click[a, b]`）が誤って分割されることはありません。
2. **ポーリングフィルタの正規化（`every 1s [cond]` -> `every[cond] 1s`）**: イベント名の直後に角括弧フィルタが続く通常のDOMイベント（`click[ctrlKey]`）とは異なり、ポーリング指定では `every` の後ろに間隔を記述します（`every 2s [ isActive() ]`）。325行目の正規表現置換によって `every <interval> [<cond>]` を `every[<cond>] <interval>` に書き換えることで、`every[<cond>]` を単一の `name` トークンとし、`<interval>` を `rest` 内の HCON キーとして統一的に解析します。
3. **先頭トークン抽出と未閉鎖ブラケット検証**:
   - 正規表現 `/^\s*(\S+\[[^\]]*\]|\S+)\s*(.*?)\s*$/` により、仕様文字列を `name`（イベント名＋任意の `[filter]`）と `rest`（後続の修飾子群）に分離します。
   - `name` に閉じ括弧 `]` のない開き括弧 `[` が含まれる場合、`/\[[^\]]*$/.test(name)` が即座に `"unterminated:" + name`（328行目）をスローし、`process()` または `htmx:error` で捕捉されます。
4. **HCON修飾子のスプレッド展開（`{name, ...HCON.parse(rest)}`）**: `HCON.parse` は単独の単語を `{word: true}`、`key:value` ペアを `{key: "value"}` として解析するため、`once changed delay:500ms from:closest form` のような修飾子列はそのまま次のオブジェクトに展開されます。
   ```javascript
   {
       name: "keyup[key=='Enter']",
       once: true,
       changed: true,
       delay: "500ms",
       from: "closest form"
   }
   ```
5. **フィルタ抽出（`__extractFilter`、868〜872行目）**: `__onTrigger` 内部で `__extractFilter(spec.name)` が `/^([^\[]*)\[([^\]]*)]/` によって `name` を `[eventName, filter]`（ブラケットがない場合は `[str, null]`）に分割します。

---

## 3.3 3層イベントハンドラ・クロージャ合成（`__onTrigger`）

`__onTrigger(elt, specString, handler)`（744〜866行目）は、`hx-trigger` と `hx-on:*` の双方が共有するコアイベントコンパイラです。`specs` を解析して `this.__htmxProp(elt).triggerSpecs` に追加した後、各仕様に対して **外側ガード（`spec.handler`）-> タイミングラッパー（`timed`）-> 内側実行クロージャ（`inner`）** という **3層ネストクロージャ** を合成します。

```drawlib align=center code=fold file=arch_c03_three_layer_closure.png caption="__onTrigger()（L744-866）における3層クロージャ合成とライフサイクルトリガーディスパッチャ"
from drawlib.canvas import save, setup
from drawlib.fonts import FontRoboto, FontSourceCode
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=144, height=84)

title_s = Styles.DarkBold.patch(text_size=13.5, text_font=FontRoboto.ROBOTO_BOLD)
sub_s = Styles.Dark.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_REGULAR)
hdr_s = Styles.DarkBold.patch(text_size=11.5, text_font=FontRoboto.ROBOTO_BOLD)
code_s = Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)
white_hdr_s = Styles.WhiteBold.patch(text_size=11.5, text_font=FontRoboto.ROBOTO_BOLD)
white_code_s = Styles.White.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)

text((72, 79.5), "__onTrigger() 3-Layer Closure Synthesis & Lifecycle Triggers", style=title_s)
text((72, 75.5), "Pre-timing guards execute synchronously before debounce/throttle timers; state mutations run only when timers fire", style=sub_s)

# Left Column: Trigger Sources (DOM + Synthetic)
rectangle((24, 39.5), width=36, height=63, style=Styles.Neutral.patch(shape_r=2.5))
text((24, 67.2), "Event & Synthetic Sources", style=hdr_s)

sources = [
    (56.2, "DOM addEventListener", "fromElts (elt / doc / ext)\ncapture & passive flags", Styles.PrimaryNeutral),
    (42.2, "IntersectionObserver", "intersect / revealed (L824)\nroot, rootMargin, threshold", Styles.SecondaryNeutral),
    (28.2, "setInterval Polling", "every <interval> (L843)\nisConnected ? fire : clear", Styles.PrimaryNeutral),
    (14.2, "Immediate Load", "load (L852) -> CustomEvent\nno DOM listener registered", Styles.SecondaryNeutral),
]
for cy, s_title, s_desc, s_style in sources:
    rectangle((24, cy), width=32, height=11.5, style=s_style.patch(shape_r=1.5))
    text((24, cy + 2.8), s_title, style=Styles.DarkBold.patch(text_size=10.5))
    text((24, cy - 2.0), s_desc, style=code_s)

# Right Column: 3-Layer Closure Pipeline (Top to Bottom)
# Layer 1: spec.handler
rectangle((95, 59.5), width=86, height=22, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
text((95, 67.2), "Layer 1: Guarded Outer Handler — spec.handler(evt) (L804-821)", style=hdr_s)
text((95, 56.8), "1. Auto-Cancel: if (__shouldCancel(evt)) evt.preventDefault()\n2. Origin/Target: from==='self' | from==='outside' | target.matches()\n3. Sync Filter: __executeJavaScript(elt, evtArgs, filter, true, false)\n4. Timer Reset: clear other.timeout & other.throttledEvent on elt", style=code_s)

# Layer 2: timed(evt)
rectangle((95, 38.5), width=86, height=14, style=Styles.Neutral.patch(shape_r=2.0))
text((95, 42.5), "Layer 2: Timing Wrapper — timed(evt) (L778-801)", style=hdr_s)
text((95, 36.2), "spec.delay: clearTimeout(timeout) -> setTimeout(inner, parseInterval)\nspec.throttle: leading inner(evt) + trailing throttledEvent replay", style=code_s)

# Layer 3: inner(evt)
rectangle((95, 18.0), width=86, height=19.5, style=Styles.PrimaryFlat.patch(shape_r=2.0))
text((95, 24.5), "Layer 3: Inner Execution Closure — inner(evt) (L759-775)", style=white_hdr_s)
text((95, 15.8), "1. Propagation: halt/prevent -> preventDefault | halt/stop/consume\n2. spec.changed: __htmxState(elt).changedValues WeakMap diff check\n3. spec.once: removeEventListener() across all spec.listeners[]\n4. Execute: handler(evt) -> __createHtmxEventHandler(elt)", style=white_code_s)

# Connections from sources to Layer 1, then Layer 1 -> Layer 2 -> Layer 3
line((42.5, 59.5), (51.5, 59.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.8))
line((95, 48.2), (95, 45.8), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.8))
line((95, 31.2), (95, 28.2), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.8))

save()
```

### レイヤー1: ガード付き外側ハンドラ（`spec.handler`、804〜821行目）

`spec.handler` は `addEventListener` に直接登録される関数です。`delay` によってHTTPリクエストの発行が遅延される場合でも、ブラウザのデフォルト遷移を即座に抑止できるよう、イベント発火時に同期実行されます。

```javascript
spec.handler = (evt) => {
    if (this.__shouldCancel(evt)) evt.preventDefault();
    if (spec.from === 'self' && evt.target !== elt) return;
    if (spec.from === 'outside' && elt.contains(evt.target)) return;
    if (spec.target && !evt.target?.matches?.(spec.target)) return;
    if (filter) {
        let evtArgs = {}; for (let k in evt) if (/^[a-z]+$/i.test(k)) evtArgs[k] = evt[k];
        if (!this.__executeJavaScript(elt, evtArgs, filter, true, false)) return;
    }
    // a new trigger replaces any pending delayed or throttled trigger on this element
    if (eventName !== 'every') {
        for (let other of this.__htmxProp(elt).triggerSpecs) {
            clearTimeout(other.timeout);
            other.throttledEvent = null;
        }
    }
    timed(evt);
};
```

レイヤー1における主要な設計上のポイントは以下の通りです。

- **自動キャンセル判定（`__shouldCancel(evt)`、712〜732行目）**: 以下の3つの条件のいずれかに該当する場合に `true` を返し、`evt.preventDefault()` を呼び出します。
  1. `<form>` 要素における `evt.type === 'submit'`。
  2. `<form>` に関連付けられた有効な送信ボタン（`button[type="submit"]`、`input[type="submit"]`、`input[type="image"]`、または `type` 属性なしの `<button>`）に対する主ボタン `click`（`evt.button === 0`）。
  3. ページ内フラグメント（`#section`）以外の `href` を持つ `<a href="...">` 内部での主ボタン `click`。なお、リンクに対する修飾キー付きクリック（`ctrlKey`、`metaKey`、`shiftKey`）は後続の `__handleTriggerEvent` 内で `__isModifierKeyClick(evt)`（707〜710行目）によってスキップされるため、ブーストされたリンクでも Cmd/Ctrl クリックによる新規タブ表示が維持されます。
- **発生元およびターゲットフィルタリング（`from` と `target`）**:
  - `from:self` は `elt` 自身を監視し（`fromElts = [elt]`）、バブリングしてきた `evt.target !== elt` のイベントをレイヤー1で破棄します。
  - `from:outside` はリスナーを `document` に登録し（755行目の `fromElts = [document]`）、`elt.contains(evt.target)` が真である内側からのイベントをすべて破棄します。
  - `target:<selector>` は `evt.target?.matches?.(spec.target)` を検証します。
- **同期的JSフィルタ評価（`filter`、809〜812行目）**: `evt` から英字のみのプロパティ（`/^[a-z]+$/i`：`ctrlKey`、`key`、`detail`、`target` など）を `evtArgs` にコピーし、`expression = true` かつ `isAsync = false` で `__executeJavaScript(elt, evtArgs, filter, true, false)` を呼び出します。`#AsyncFunction` ではなく同期の `#Function` を使用するため、マイクロタスクキューに制御を譲ることなく即座に真偽値を判定できます。
- **クロストリガー・タイマーキャンセル（814〜819行目）**: `every` 以外のトリガーが `elt` のレイヤー1ガードを通過すると、htmx はその要素上のすべての `this.__htmxProp(elt).triggerSpecs` を走査し、`other.timeout` のクリアと `other.throttledEvent = null` のリセットを行います。たとえば `<input hx-trigger="keyup delay:500ms, change">` において `change` が発火した場合、保留中の `keyup` デバウンスタイマーが即座にキャンセルされ、重複リクエストの送信が防止されます。

### レイヤー2: タイミングラッパー（`timed`、778〜801行目）

`spec.delay` も `spec.throttle` も指定されていない場合、`timed` は `inner` を直接参照します。指定がある場合は `parseInterval(str)`（1578〜1584行目：`ms` -> `×1`、`s` -> `×1000`、`m` -> `×60000`、または数値をミリ秒に変換）を用いて `inner` をラップします。

- **デバウンス（`spec.delay`、779〜783行目）**: `clearTimeout(spec.timeout)` で既存タイマーを破棄し、`setTimeout(() => inner(evt), this.parseInterval(spec.delay))` を再スケジュールします。
- **リーディング＋トレーリング・スロットル（`spec.throttle`、784〜800行目）**:
  - **最初のイベント**（`!spec.throttled`）では `spec.throttled = true` を設定して即座に `inner(evt)` を実行（リーディングエッジ）し、`spec.throttleTimeout` を開始します。
  - `spec.throttled` が真の期間中に到着したイベントは、最新の1件を `spec.throttledEvent = evt` に保持します。
  - `spec.throttleTimeout` 満了時に `spec.throttled = false` に戻し、期間中に `spec.throttledEvent` が記録されていればそれを取り出して `timed(e)` を再帰呼び出し（トレーリングエッジ再生）します。

### レイヤー3: 内側実行クロージャ（`inner`、759〜775行目）

`inner(evt)` はタイミングラッパーが解決した後にのみ実行されます。

```javascript
let inner = (evt) => {
    if (spec.halt || spec.prevent) evt.preventDefault();
    if (spec.halt || spec.stop || spec.consume) evt.stopPropagation();
    if (spec.changed) {
        let values = this.__htmxState(elt).changedValues ??= new WeakMap();
        let target = evt.target;
        if (!['checkbox', 'radio'].includes(target?.type)) {
            let value = target?.value;
            if (values.has(target) && values.get(target) === value) return;
            values.set(target, value);
        }
    }
    if (spec.once) {
        for (let info of spec.listeners) info.fromElt.removeEventListener(info.eventName, info.handler, info);
    }
    handler(evt);
};
```

- **イベント伝播修飾子**: `prevent` は `evt.preventDefault()`、`stop` と `consume` は `evt.stopPropagation()`、`halt` はその両方を呼び出します。
- **ターゲット単位の `changed` 追跡（`WeakMap`、762〜770行目）**: `elt` に単一の文字列を保存するのではなく、`this.__htmxState(elt).changedValues` に `evt.target` をキーとする `WeakMap` を初期化します。これにより、親コンテナに `hx-trigger="keyup changed delay:300ms from:findAll input"` を指定した場合でも、各子 `<input>` の前回 `.value` を個別に追跡でき、要素削除時のメモリリークも発生しません。なお、チェックボックスとラジオボタン（`!['checkbox', 'radio'].includes(target?.type)`）は除外されます。
- **ワンショットリスナー解除（`spec.once`、771〜773行目）**: `handler(evt)` を呼び出す直前に `spec.listeners` を走査し、登録済みのすべてのイベントリスナーを自己解除します。

### 合成ライフサイクルトリガー（824〜855行目）

`fromElts` にDOMリスナーを登録する前に、`__onTrigger` は4つの特殊なライフサイクルトリガー名を処理します。

| トリガートークン | 使用するブラウザプリミティブ | ライフサイクルとクリーンアップの仕組み（`src/htmx.js`） |
| :--- | :--- | :--- |
| `intersect` | `new IntersectionObserver`（L824–840） | `{rootMargin: spec.rootMargin, root: __findOrWarn(elt, spec.root), threshold: parseFloat(spec.threshold)}` を構築し、`eventName = 'intersect'` に書き換えて全 `fromElts` を監視します。`entries[i].isIntersecting` が真になるとバブリングなしの `'intersect'` カスタムイベントを発火します。 |
| `revealed` | `new IntersectionObserver`（L824–840） | `isRevealed = true` として `intersect` と同じオブザーバ経路を共有し、最初の交差が検出された時点で即座に `spec.observer.disconnect()`（L833）を呼び出します。 |
| `every <interval>` | `setInterval`（L843–849） | 間隔キー（`Object.keys(spec).find(k => k !== 'name')`）を抽出し、各ティックで `if (elt.isConnected) this.__trigger(elt, 'every', {}, false)` を実行します。要素がDOMから切り離されていれば `clearInterval(spec.interval)` で自己停止します。 |
| `load` | `new CustomEvent('load')`（L852–855） | 初期化中に `spec.handler(new CustomEvent('load'))` を即座に呼び出し、`continue` によって `addEventListener` への登録をスキップします。 |

---

## 3.4 拡張CSSセレクタエンジン（`__findAllExt`）

`hx-target`・`hx-include`・`hx-indicator`・`hx-disable`・`hx-sync`・`hx-trigger="... from:<sel>"` など、htmx 全体のセレクタ解決はすべて `__findAllExt(eltOrSelector, maybeSelector, thisAttr, global)`（1900〜1956行目）および単一要素ラッパーの `__findExt` / `__findOrWarn` を通じて行われます。

```drawlib align=center code=fold file=arch_c03_selector_engine_flow.png caption="__findAllExt()（L1895-1994）における拡張CSSセレクタ解決パイプライン"
from drawlib.canvas import save, setup
from drawlib.fonts import FontRoboto, FontSourceCode
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.styles import Styles
from drawlib.text import text

setup(width=144, height=78)

title_s = Styles.DarkBold.patch(text_size=13.5, text_font=FontRoboto.ROBOTO_BOLD)
sub_s = Styles.Dark.patch(text_size=10.5, text_font=FontRoboto.ROBOTO_REGULAR)
hdr_s = Styles.DarkBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
code_s = Styles.Dark.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)
white_hdr_s = Styles.WhiteBold.patch(text_size=11.0, text_font=FontRoboto.ROBOTO_BOLD)
white_code_s = Styles.White.patch(text_size=10.0, text_font=FontSourceCode.ROBOTO_MONO)

text((72, 73.5), "__findAllExt(eltOrSelector, maybeSelector, thisAttr, global) Engine", style=title_s)
text((72, 69.5), "Splits composite selectors via HCON.split(), resolves relative/Shadow DOM tokens, and deduplicates results", style=sub_s)

# Top Row: Pre-processing stages
rectangle((26, 58.5), width=40, height=12, style=Styles.Neutral.patch(shape_r=2.0))
text((26, 61.3), "1. Prefix & Root Scope", style=hdr_s)
text((26, 56.1), "global -> slice(7), global=true\ngetRootNode({composed})", style=code_s)

rectangle((72, 58.5), width=40, height=12, style=Styles.PrimaryNeutral.patch(shape_r=2.0))
text((72, 61.3), "2. HCON.split & <.../> Strip", style=hdr_s)
text((72, 56.1), "HCON.split(selector)\nstrip '<' and '/>' wrapper", style=code_s)

rectangle((118, 58.5), width=40, height=12, style=Styles.Neutral.patch(shape_r=2.0))
text((118, 61.3), "3. Token Router Loop", style=hdr_s)
text((118, 56.1), "for (const part of parts)\nrelative vs standard CSS", style=code_s)

line((46.5, 58.5), (51.5, 58.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))
line((92.5, 58.5), (97.5, 58.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.6))

# Stem down from box 3 to horizontal bus at y=50.5
line((118.0, 52.5), (118.0, 50.5), style=Styles.DarkBold.patch(line_width=1.4))
line((21.5, 50.5), (122.0, 50.5), style=Styles.DarkBold.patch(line_width=1.4))

# Middle Row: 4 Token Categories
categories = [
    (21.5, "Subtree & Ancestor", "closest <sel>\n -> elt.closest()\nfind <sel>\n -> elt.querySelector()\nfindAll <sel>\n -> querySelectorAll()", Styles.Neutral, False),
    (55.0, "Document-Order Scan", "next / previous\n -> next/prevSibling\nnext <sel> (mask === 2)\n -> __scanForwardQuery()\nprevious <sel> (mask===4)\n -> __scanBackwards()", Styles.PrimaryFlat, True),
    (88.5, "Context & Inheritance", "this (with thisAttr):\n -> __findThisElements()\nthis (default) -> elt\nhost -> rootNode.host\ndocument / window / body", Styles.PrimaryNeutral, False),
    (122.0, "Standard CSS Batch", "unprocessed.join(',')\nrootNode = __getRootNode(\n  elt, !!global\n)\nrootNode.querySelectorAll\n  (standardSelector)", Styles.SecondaryNeutral, False),
]

for cx, c_title, c_body, c_style, is_focal in categories:
    rectangle((cx, 33.0), width=31.0, height=25.0, style=c_style.patch(shape_r=2.0))
    line((cx, 50.5), (cx, 46.0), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.4))
    line((cx, 20.0), (cx, 15.5), arrow_head="->", style=Styles.DarkBold.patch(line_width=1.4))
    text((cx, 42.0), c_title, style=white_hdr_s if is_focal else hdr_s)
    text((cx, 30.2), c_body, style=white_code_s if is_focal else code_s)

# Bottom Row: Set Deduplication Output
rectangle((72, 9.5), width=132, height=11, style=Styles.AccentFlat.patch(shape_r=2.0))
text((72, 11.8), "4. Order-Preserving Deduplication — return [...new Set(result)] (L1955)", style=white_hdr_s)
text((72, 7.2), "__findExt() returns result[0]  |  __findOrWarn() logs console.warn() if result[0] is undefined", style=white_code_s)

save()
```

### 正規化・`global` スコープ・複合セレクタ分割

```javascript
__stringHyperscriptStyleSelector(selector) {
    let s = selector.trim();
    return s.startsWith('<') && s.endsWith('/>') ? s.slice(1, -2) : s;
}

__findAllExt(eltOrSelector, maybeSelector, thisAttr, global) {
    let selector = maybeSelector ?? eltOrSelector;
    let elt = maybeSelector ? (this.__normalizeElement(eltOrSelector) || document.body) : document;
    if (selector.startsWith('global ')) {
        return this.__findAllExt(elt, selector.slice(7), thisAttr, true);
    }
    let parts = selector ? HCON.split(selector) : [];
```

1. **2種類の引数シグネチャ対応**: `htmx.find(eltOrSelector, selector)` と同様、`__findAllExt` は `(selector)`（`elt` は `document` にフォールバック）または `(elt, selector, thisAttr, global)` の両方を受け付けます。
2. **Shadow DOM 境界の突破（`global ` プレフィックス、1903〜1905行目・1975〜1981行目）**: デフォルトでは `__getRootNode(elt, false)` が `elt.getRootNode({composed: false})` を呼び出すため、標準CSSクエリや `next`/`previous` 走査は現在の `ShadowRoot` または `Document` 内に閉じ込められます。セレクタ先頭に `global ` を付与すると `global = true` で再帰呼び出しされ、`elt.getRootNode({composed: true})` によって Shadow DOM の境界を越えて最上位の `document` まで探索範囲が広がります。
3. **Hyperscript 風 `<.../>` ラッパーの除去（`__stringHyperscriptStyleSelector`、1895〜1898行目）**: `HCON.split(selector)` で分割された各パートは前後の空白が除去され、任意の `<` と `/>` デリミタが取り除かれます（例: `<closest tr/>` -> `closest tr`）。

### 相対トークン・継承対応の `this`・`host`

`for (const part of parts)` ループ（1909〜1947行目）の内部では、標準CSSセレクタとして処理する前に以下の相対トークンおよび特殊トークンを評価します。

| セレクタトークン | DOM解決式（`src/htmx.js` L1912–1942） | アーキテクチャ上の特徴 |
| :--- | :--- | :--- |
| `closest <sel>` | `elt.closest(selector.slice(8))` | `elt` 自身を含む祖先チェーンを上方向に探索します。 |
| `find <sel>` | `elt.querySelector(selector.slice(5))` | `elt` 内部で最初に一致する子孫要素を返します。 |
| `findAll <sel>` | `result.push(...elt.querySelectorAll(selector.slice(8)))` | `elt` 内部で一致するすべての子孫要素を追加します。 |
| `next` / `nextElementSibling` | `elt.nextElementSibling` | 同一親要素内の直後の兄弟要素を返します。 |
| `next <sel>` | `this.__scanForwardQuery(elt, selector.slice(5), !!global)` | 文書順序で `elt` より後ろにある最初の `<sel>` 一致要素を返します。 |
| `previous` / `previousElementSibling` | `elt.previousElementSibling` | 同一親要素内の直前の兄弟要素を返します。 |
| `previous <sel>` | `this.__scanBackwardsQuery(elt, selector.slice(9), !!global)` | 文書順序で `elt` より前にある直近の `<sel>` 一致要素を返します。 |
| `document` / `window` / `body` | `document` / `window` / `document.body` | グローバルなイベント・スクロール対象（`from:window` などで有効）です。 |
| `host` | `(elt.getRootNode()).host` | 現在の `ShadowRoot` をホストしているカスタム要素を解決します。 |
| `this` | `__findThisElements(elt, thisAttr)` または `elt` | `thisAttr` 指定時は属性継承チェーンを遡って自己参照要素を特定します。 |

**なぜ `this` に `__findThisElements(elt, thisAttr)`（280〜286行目）が必要なのか**:
親要素 `<div hx-target:inherited="this">` の中に子要素 `<button hx-get="/items">` があるケースを考えます。子ボタンがクリックされたとき、`elt` は `<div>` ではなく `<button>` です。もし `this` が単純に `elt` を返してしまうと、`hx-target:inherited="this"` を宣言した親 `<div>` ではなくボタン自身がレスポンスで置き換えられてしまいます。そこで `thisAttr`（`"hx-target"`・`"hx-indicator"`・`"hx-disable"` など）を渡すことで、`__findThisElements` は `eltCollector` コールバック付きで `__attributeValue` を呼び出し（282〜284行目）、継承チェーン（`:inherited` や `:append`）を辿って属性値に `'this'` トークンを実際に記述した祖先要素群を正確に収集します。

### 文書順序ビットマスク走査（`next <sel>` と `previous <sel>`）

`nextElementSibling` とは異なり、`next <sel>` と `previous <sel>` はルートツリー内のあらゆる階層にある要素（たとえば、あるテーブルセル内の `<input>` から次の行の `<input>` へのジャンプなど）にマッチします。htmx は手動のツリーウォーカーを書く代わりに、`rootNode.querySelectorAll(match)` と `Node.prototype.compareDocumentPosition` を組み合わせることで簡潔に実装しています（1958〜1973行目）。

```javascript
__scanForwardQuery(start, match, global) {
    return this.__scanUntilComparison(
        this.__getRootNode(start, global).querySelectorAll(match),
        start,
        Node.DOCUMENT_POSITION_PRECEDING
    );
}

__scanBackwardsQuery(start, match, global) {
    let results = [...this.__getRootNode(start, global).querySelectorAll(match)].reverse()
    return this.__scanUntilComparison(results, start, Node.DOCUMENT_POSITION_FOLLOWING);
}

__scanUntilComparison(results, start, comparison) {
    for (const elt of results) {
        if (elt.compareDocumentPosition(start) === comparison) {
            return elt
        }
    }
}
```

ビットマスク比較の動作原理は以下の通りです。

1. **`elt.compareDocumentPosition(start)`** は、候補要素 `elt` を基準としたときの起点 `start` の相対位置をビットマスクとして返します。
2. **前方走査（`next <sel>`）**: 候補要素を文書順（`querySelectorAll` の順）に走査し、`elt.compareDocumentPosition(start) === Node.DOCUMENT_POSITION_PRECEDING`（`2`）を判定します。厳密等価演算子（`===`）を使用しているため、`start` を内包する祖先要素（`DOCUMENT_POSITION_CONTAINS = 8` が立つためビットマスクは `2 | 8 = 10` となる）は自動的に除外され、`start` が純粋に先行する最初の要素 `elt` だけが返されます。
3. **後方走査（`previous <sel>`）**: `querySelectorAll` の結果配列を `.reverse()` で逆順にし、`elt.compareDocumentPosition(start) === Node.DOCUMENT_POSITION_FOLLOWING`（`4`）を判定します。ここでも厳密等価（`=== 4`）により `start` の祖先コンテナ（ビットマスクに `CONTAINS = 8` や `CONTAINED_BY = 16` が含まれる）が除外され、文書順序で直前に位置する要素が返されます。
4. **標準CSSの一括クエリと重複排除（1949〜1955行目）**: 特殊トークンに一致しなかったセレクタパートは `,` で結合されて1回の `rootNode.querySelectorAll(standardSelector)` で一括検索され、最後に `[...new Set(result)]` で順序を保ったまま重複排除されてから、[第4章](04_fetch_context_and_sync_queue.md)で詳述するリクエストパイプラインへと渡されます。
