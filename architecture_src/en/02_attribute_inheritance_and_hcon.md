# 2. Attribute Inheritance & HCON

**htmx v4.0.1** unifies attribute configuration parsing and DOM inheritance around two foundational mechanisms in `src/htmx.js`: **`HCON` (htmx Configuration Object Notation, `L10–88`)**—a brace-free, JSON-compatible configuration language with built-in prototype-pollution protection—and **`__attributeValue()` (`L288–320`)**, an opt-in attribute resolution engine driven by explicit `:inherited` and `:append` modifiers, `data-hx-` prefix normalization, and custom `metaCharacter` rewriting.

```drawlib align=center code=fold file=arch_c02_hcon_and_inheritance_hero.png caption="HCON Configuration Parser (L10–88) & Explicit :inherited / :append Attribute Resolution Engine (L245–320)"
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

## 1. The `HCON` (htmx Configuration Object Notation) Parser (`L10–88`)

In htmx 2.x, different attributes used incompatible configuration syntaxes: `hx-vals` and `hx-headers` required strict double-quoted JSON (`hx-vals='{"count": 5}'`), whereas `hx-swap` and `hx-trigger` relied on bespoke whitespace/colon tokenizers. **htmx v4.0.1** replaces all of those ad-hoc parsers with **`HCON`** (`L10–88`), a unified mini-language that parses brace-free key-value pairs while remaining 100% backward-compatible with standard JSON (`if (string.startsWith('{')) return JSON.parse(string)` at `L21`).

`HCON` powers `<meta name="htmx-config">` (`L210`), `hx-trigger` modifier parsing (`__parseTriggerSpecs` at `L329`), `HX-Trigger` response headers (`__handleTriggerHeader` at `L876`), `hx-swap` modifier parsing (`__insertContent` at `L1361`), `hx-vals` and `hx-headers` (`__getAttributeObject` at `L1891`), and `hx-status:*` response overrides (`__handleStatusCodes` at `L2282`).

### 1.1 The 7-Group Master Tokenizing Regex in `HCON.parse()` (`L19–50`)

When `HCON.parse(string)` receives a non-empty string that does not start with `{`, it iterates over `string.matchAll(pattern)` (`L22–24`) using a single 7-capture-group regular expression:

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

Each regex match undergoes four transformation steps (`L36–47`):

1. **Key & Value Extraction with Implicit `'true'` Default (`L36–37`)**: The key is chosen via nullish coalescing (`doubleQuotedKey ?? singleQuotedKey ?? bareKey`). Because the entire `(?:\s*:\s*...)` value group is optional (`?`), standalone tokens without a colon—such as `outerHTML` or `transition` in `hx-swap="outerHTML transition swap:100ms"`—default to `'true'`.
2. **Opportunistic `JSON.parse()` Coercion (`L40`)**: `try { value = JSON.parse(value); } catch {}` converts numeric strings (`"5"` $\rightarrow$ `5`), booleans (`"true"` $\rightarrow$ `true`, `"false"` $\rightarrow$ `false`), `null`, and inline arrays/objects into native JavaScript types, while leaving unquoted words (`"innerHTML"`, `"100ms"`) intact as strings when `JSON.parse` throws.
3. **Bare Dotted-Path Expansion vs. Quoted Literal Keys (`L43–46`)**: Only when `bareKey?.includes('.')` is truthy does `HCON.parse` split the key on `.` and fold right-to-left via `key.split('.').reduceRight((acc, segment) => ({[segment]: acc}), value)`—turning `sse.mode:once` into `{sse: {mode: "once"}}`. If the key was quoted (`"sse.mode":once` or `'a.b':1`), `bareKey` is `undefined`, so `isDottedPath` is falsy and the literal flat key `{"sse.mode": "once"}` is preserved.
4. **Incremental Deep Merge (`L47`)**: Each key-value `pair` is merged into `result` via `HCON.merge(pair, result)`, allowing sibling dotted keys like `user.name:alice user.role:admin` to coalesce into `{user: {name: "alice", role: "admin"}}`.

| Capture Group | Regex Sub-Pattern | Syntax Example | Extracted Token & Behavior |
| :--- | :--- | :--- | :--- |
| **Group 1 (`doubleQuotedKey`)** | `"([^"]+)"` | `"user.name":alice` | Key `"user.name"` (flat property; dotted-path expansion disabled). |
| **Group 2 (`singleQuotedKey`)** | `'([^']+)'` | `'X-CSRF-Token':abc` | Key `"X-CSRF-Token"` (preserves special characters and dots). |
| **Group 3 (`bareKey`)** | `([^\s,:]+)` | `swap:100ms` or `a.b:1` | Key `"swap"` or dotted path `"a.b"` (expanded via `reduceRight` to `{a: {b: 1}}`). |
| **Group 4 (`doubleQuotedValue`)** | `"([^"]*)"` | `from:".a, .b"` | Value `".a, .b"` (supports spaces, colons, and commas). |
| **Group 5 (`singleQuotedValue`)** | `'([^']*)'` | `target:'#main > div'` | Value `"#main > div"` (convenient inside double-quoted HTML attributes). |
| **Group 6 (`hyperscriptValue`)** | `<((?:[^/]\|\/(?!>))+)\/>` | `from:<button:not(.x)/>` | Value `"button:not(.x)"` (strips outer `<.../>` delimiters). |
| **Group 7 (`bareValue`)** | `([^\s,]+)` | `delay:300ms` or `count:5` | Value `"300ms"` (string) or `5` (coerced to `number` via `JSON.parse`). |
| **Omitted Value (`undefined`)** | *(Optional value group)* | `outerHTML transition` | Defaults to `'true'` (`L37`) and coerces to boolean `true` (`{outerHTML: true, transition: true}`). |

### 1.2 Context-Aware Comma Splitting (`HCON.split`) & Prototype-Safe Merging (`HCON.merge`)

```drawlib align=center code=fold file=arch_c02_hcon_parser_pipeline.png caption="HCON.split() Lookahead Guards, HCON.parse() Dotted-Key Folding, and HCON.merge() Prototype-Pollution Defense"
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

- **Context-Aware Comma Splitting (`HCON.split`, `L60–62`)**:
  Attributes like `hx-trigger='click[ctrlKey, shiftKey], keyup from:".a, .b", intersect root:<#vp, .box/>'` use commas both as top-level item delimiters and inside filter brackets, CSS selector strings, or hyperscript `<.../>` literals. `HCON.split` uses four regex lookaheads after `,`:
  - `(?![^\[]*\])`: Do not split if followed by a closing `]` without an intervening `[` (inside `[filter]` brackets).
  - `(?![^(]*\))`: Do not split inside `(...)` parentheses (e.g., `:not(.a, .b)` or function calls).
  - `(?![^<]*\/>)`: Do not split inside `<.../>` hyperscript selector literals.
  - `(?=(?:[^"']|"[^"]*"|'[^']*')*$)`: Only split when an even number of matched `"..."` and `'...'` quotes remain until the end of the string.
- **Prototype-Pollution Defense in `HCON.merge(source, target)` (`L71–87`)**:
  Because `HCON.parse` expands dotted keys (`__proto__.isAdmin:true` $\rightarrow$ `{ ["__proto__"]: { isAdmin: true } }`) and merges untrusted server headers (`HX-Trigger`) or DOM attribute strings, `HCON.merge` enforces two strict guards:
  1. **Explicit Key Blacklist (`L75`)**: `if (['__proto__', 'constructor', 'prototype'].includes(key)) continue;` prevents any modification of `Object.prototype`.
  2. **Exact Plain-Object Constructor Check (`L77–80`)**: `val?.constructor === Object && target[key]?.constructor === Object` ensures recursive merging only descends into plain objects (never arrays, DOM nodes, or custom class instances).

---

## 2. Prefix Fallback & Custom `metaCharacter` Normalization (`L245–263`, `L2360–2366`)

htmx v4 supports strict HTML5 validator compliance (`data-hx-*`) and template engines that reserve the colon character `:` (such as Vue's `:attr` shorthand or XML namespace parsers) through five lightweight normalization helpers in `src/htmx.js`:

1. **Dual-Attribute Value Lookup (`__attr(elt, name)`, `L245–248`)**: Checks `elt.getAttribute(name)` first (e.g., `hx-get`), then falls back to `this.config.prefix` (`"data-hx-"` by default) via `elt.getAttribute(name.replace('hx-', p))`.
2. **Matched Attribute Name Resolution (`__attrName(elt, name)`, `L250–253`)**: Returns the exact attribute name present on `elt` (`hx-vals:append` or `data-hx-vals:append`), used by `__attributeValue()` (`L299–301`) to read `:append` attributes regardless of prefix.
3. **CSS Selector Prefix Expansion (`__prefixes(s)` & `__prefixSelector(s)`, `L255–263`)**: Duplicates any selector string `s` by replacing all occurrences of `'hx-'` with `this.config.prefix` and joining with `,` (turning `[hx-target:inherited]` into `[hx-target:inherited],[data-hx-target:inherited]`).
4. **Custom `metaCharacter` Rewriting (`__maybeAdjustMetaCharacter(string)`, `L2360–2366`)**: When `this.config.metaCharacter` is configured (for example, `htmx.config.metaCharacter = '@'` or `'_'`), every internal `:inherited` modifier, `:append` modifier (`L289–291`), `hx-on` separator (`L1726`), and dispatched `htmx:phase:action` event name (`__trigger` at `L1513`) dynamically replaces `:` with `this.config.metaCharacter`.

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

## 3. Explicit `:inherited` & `:append` Resolution Engine (`__attributeValue` L288–320)

In htmx 2.x, almost all `hx-*` attributes (`hx-target`, `hx-swap`, `hx-select`, `hx-confirm`, `hx-vals`, `hx-headers`, `hx-boost`, etc.) inherited implicitly down the DOM tree, frequently causing unintended side effects on nested components unless authors manually added `hx-disinherit`.

In **htmx v4.0.1**, `this.config.implicitInheritance` defaults to **`false`** (`L204`). Inheritance is opt-in on ancestor elements via two explicit attribute suffixes resolved by `__attributeValue()` (`L288–320`):

- **`hx-<attr>:inherited="..."`**: Declares a value on an ancestor element that applies both to the ancestor itself and to all descendants that do not override `hx-<attr>`.
- **`hx-<attr>:append="..."` and `hx-<attr>:inherited:append="..."`**: Appends additional comma-separated values (such as extra `hx-vals` keys, `hx-headers` entries, `hx-include` selectors, or `hx-indicator` targets) onto the inherited ancestor value rather than replacing it.

```drawlib align=center code=fold file=arch_c02_attribute_inheritance_flow.png caption="Step-by-Step Attribute & Ancestor Resolution in __attributeValue(elt, name, defaultVal, eltCollector, allowInheritance)"
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

### 3.1 Step-by-Step Trace of `__attributeValue()` (`L288–320`)

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

Four implementation details in `__attributeValue()` deserve special attention:

1. **Native C++ Ancestor Jumps via `CSS.escape` & `closest()` (`L296–298`, `L302`, `L311`)**: Rather than walking `elt = elt.parentElement` in a JavaScript `while` loop, htmx escapes the colons in `hx-attr:inherited` and `hx-attr:inherited:append` via `CSS.escape()` and delegates the ancestor search to `elt.parentNode?.closest?.(inheritSelector)`, jumping directly to the nearest matching ancestor in native browser code.
2. **Brace-Stripping `:append` Composition (`L306`)**: When a child element specifies `hx-vals:append='{"b": 2}'` (or `b:2`) and an ancestor specifies `hx-vals:inherited='{"a": 1}'`, concatenating them with a comma and stripping curly braces via `(parentVal + "," + appendValue).replace(/[{}]/g, '')` produces `"a": 1, "b": 2`. Because `HCON.parse()` natively parses double-quoted keys and values alongside bare HCON pairs, **JSON and HCON attributes can be mixed and appended across arbitrary DOM depths**.
3. **Resolving Multiple `this` Targets Across `:append` Chains (`__findThisElements`, `L280–286`)**: When `hx-indicator:inherited="this"` is placed on a `<form>` and `hx-indicator:append="this"` is placed on a child `<button>`, `__findAllExt()` (`L1936`) calls `__findThisElements(elt, "hx-indicator")`. By passing an `eltCollector` callback into `__attributeValue()`, htmx visits every element in the `:append` chain that contributed `"this"` and returns both `[button, form]`.
4. **Hard-Coded Non-Inheritable Attributes (`allowInheritance = false`)**: Action attributes (`hx-action` at `L335` and `hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, `hx-query` at `L338`), `hx-validate` (`L403`), and `hx-trigger` (`L735`) explicitly pass `false` for `allowInheritance`. Even if an application enables `htmx.config.implicitInheritance = true` (or loads `src/ext/htmx-2-compat.js`, which listens to the `htmx:after:implicitInheritance` hook at `L315`), HTTP verbs and triggers never bleed onto descendant elements unless `:inherited` is explicitly written.

---

## 4. Synchronous vs. Dynamic Attribute Object Evaluation (`__getAttributeObject` L1875–1893)

Attributes that evaluate to key-value maps—specifically **`hx-headers`** (`L480`) and **`hx-vals`** (`L489`)—are resolved through `__getAttributeObject(elt, attrName, callback, scope)` (`L1875–1893`).

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

This bifurcated design optimizes both performance and flexibility:

- **Zero-Microtask Synchronous Fast-Path (`L1889–1892`)**: When `hx-vals` or `hx-headers` contains static HCON or JSON (`hx-vals="page:2 sort:'asc'"`), `__extractJavascriptContent(hxAttr)` returns `undefined`. `__getAttributeObject` immediately invokes `callback(HCON.parse(hxAttr))` synchronously and returns `undefined`, avoiding `Promise` allocation or microtask queue delay prior to `htmx:config:request`.
- **Asynchronous `js:` / `javascript:` Evaluation (`L1880–1888`)**: When prefixed with `js:` or `javascript:` (e.g., `hx-vals="js:{ token: await getAuthToken(), ts: Date.now() }"` or bare `hx-vals="js:ts: Date.now()"`), htmx wraps bare key-value expressions in `{...}` (`L1882–1884`) and executes the code via `this.__executeJavaScript(elt, scope, javascriptContent, true)`. Because `__executeJavaScript` defaults to `this.#AsyncFunction` (`L911, L922`), dynamic `hx-vals` and `hx-headers` natively support `await` expressions and return a `Promise` that `__handleTriggerEvent` (`L480–495`) awaits via `await Promise.all(promises)`.
