# 4. Targeting & Swapping

Once the server responds with an HTML fragment, htmx v4.0.1 determines **where** to place the content (`hx-target` using extended relative CSS selectors) and **how** to integrate it into the live DOM (`hx-swap`, built-in DOM morphing, `hx-preserve`, and the View Transitions API).

```drawlib align=center code=fold file=ch04_swap_positions_and_strategies.png caption="htmx v4.0.1 Swap Insertion Positions, Morphing Modes, and Extended CSS Selectors"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, GridLayout, Panel
from drawlib.styles import Styles

setup(width=174, height=78)

# Left Panel: DOM Swap Insertion Geometry
left_panel = Panel(
    "hx-swap Insertion Positions",
    "Relative to Target Element",
    style=Styles.Neutral,
    header_style=Styles.PrimaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.brackets_angle,
    icon_style=Styles.PrimaryBold,
    header_variant="filled",
    header_height=9.0,
)
left_panel.draw((6.0, 6.0), width=82.0, height=66.0, align="bottom_left")
l_xy, l_w, l_h = left_panel.get_content_box((6.0, 6.0), width=82.0, height=66.0, padding=(3.5, 3.0))

grid = GridLayout(
    num_column=1,
    num_row=5,
    style=Styles.White.patch(shape_r=1.5),
    text_style=Styles.DarkBold.patch(text_size=10.0),
)
grid.add((0, 4), 1, 1, text="before (beforebegin) -> Prior Sibling", style=Styles.SecondaryNeutral.patch(shape_r=1.5))
grid.add((0, 3), 1, 1, text="prepend (afterbegin) -> First Child Inside Target", style=Styles.PrimaryNeutral.patch(shape_r=1.5))
grid.add(
    (0, 2),
    1,
    1,
    text="innerHTML / innerMorph / outerMorph / outerSync",
    style=Styles.PrimaryFlat.patch(shape_r=1.5),
    text_style=Styles.WhiteBold.patch(text_size=10.0),
)
grid.add((0, 1), 1, 1, text="append (beforeend) -> Last Child Inside Target", style=Styles.PrimaryNeutral.patch(shape_r=1.5))
grid.add((0, 0), 1, 1, text="after (afterend) -> Next Sibling", style=Styles.SecondaryNeutral.patch(shape_r=1.5))
grid.draw(l_xy, width=l_w, height=l_h, margin=1.5)

# Right Panel: Extended Relative CSS Selectors
right_panel = Panel(
    "Extended Relative Selectors",
    "ID-Free Component Targeting",
    style=Styles.Neutral,
    header_style=Styles.SecondaryNeutral.patch(shape_line_width=1.2),
    text_style=Styles.DarkBold.patch(text_size=11.0),
    description_style=Styles.Muted.patch(text_size=9.5),
    icon=phosphor.crosshair,
    icon_style=Styles.DarkBold,
    header_variant="filled",
    header_height=9.0,
)
right_panel.draw((94.0, 6.0), width=74.0, height=66.0, align="bottom_left")
r_xy, r_w, r_h = right_panel.get_content_box((94.0, 6.0), width=74.0, height=66.0, padding=(3.5, 3.0))

sel_cards = CardList(
    style=Styles.White,
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Muted.patch(text_size=9.5),
    badge_style=Styles.PrimaryNeutral,
    badge_text_style=Styles.PrimaryBold.patch(text_size=9.5),
    spacing=2.0,
)
sel_cards.add("closest <selector>", "Nearest ancestor (e.g. closest tr, closest .card)", badge_text="UP")
sel_cards.add("find <selector>", "First matching descendant inside element", badge_text="DOWN")
sel_cards.add("next [selector]", "Following sibling in DOM order", badge_text="NEXT")
sel_cards.add("previous [selector]", "Preceding sibling in DOM order", badge_text="PREV")
sel_cards.draw(r_xy, width=r_w, height=r_h)

save()
```

---

## 4.1 Extended Relative CSS Selectors (`hx-target`)

While standard CSS selectors (`#results`, `.panel`) work everywhere in htmx, relying on global IDs inside loops or reusable components leads to brittle templates. htmx v4.0.1 supports **extended relative selectors** in `hx-target`, `hx-include`, `hx-indicator`, `hx-disable`, and `htmx.find()`:

| Selector Syntax | Resolution Scope | Practical Example |
| :--- | :--- | :--- |
| **`this`** | The element carrying the attribute (or the inheritance owner when `:inherited`). | `hx-target="this"` on an edit-in-place card. |
| **`closest <selector>`** | Walks up the ancestor chain (`element.closest(sel)`). | `hx-target="closest tr"` on a table row delete button. |
| **`find <selector>`** | Queries the first descendant inside the element (`element.querySelector(sel)`). | `hx-disable="find button, find input"` on a `<form>`. |
| **`next [selector]`** | Finds the next element in document order matching `[selector]` (or immediate sibling). | `hx-target="next .validation-msg"` on an `<input>`. |
| **`previous [selector]`** | Finds the preceding element in document order matching `[selector]`. | `hx-target="previous output"` on a increment button. |

```html
<!-- Zero global IDs needed across repeating table rows -->
<table>
  <tbody>
    <tr>
      <td>Invoice #1042</td>
      <td class="row-status">Pending</td>
      <td>
        <button hx-post="/invoices/1042/approve"
                hx-target="closest tr"
                hx-swap="outerMorph">
          Approve
        </button>
      </td>
    </tr>
  </tbody>
</table>
```

---

## 4.2 Complete `hx-swap` Strategy Reference

htmx v4.0.1 expands `hx-swap` with built-in morphing (`innerMorph`, `outerMorph`, `outerSync`), safe text replacement (`textContent`), and intuitive position shorthands (`before`, `prepend`, `append`, `after`):

| `hx-swap` Value | Legacy Alias | DOM Operation & State Preservation |
| :--- | :--- | :--- |
| **`innerHTML`** *(default)* | — | Replaces all child nodes of the target with parsed HTML. |
| **`outerHTML`** | — | Replaces the entire target element itself with the response HTML. |
| **`outerSync`** | — | **New in v4**: Morphs the target element's own attributes in place, then replaces its children (`innerHTML`). Keeps the target node reference alive. |
| **`innerMorph`** | — | **New in v4**: Morphs the children of the target in place, preserving focus, input values, scroll positions, and animations. |
| **`outerMorph`** | — | **New in v4**: Morphs the target element itself and its children in place. |
| **`textContent`** | — | **New in v4**: Assigns `target.textContent` directly without parsing HTML (ideal for counters or untrusted plain strings). |
| **`before`** | `beforebegin` | Inserts the response immediately before the target element as a preceding sibling. |
| **`prepend`** | `afterbegin` | Inserts the response inside the target before its first child. |
| **`append`** | `beforeend` | Inserts the response inside the target after its last child. |
| **`after`** | `afterend` | Inserts the response immediately after the target element as a following sibling. |
| **`delete`** | — | Removes the target element from the DOM after the request completes (regardless of response body). |
| **`none`** | — | Does not modify the primary target (`<hx-partial>`, `hx-swap-oob`, and response headers still execute). |

---

## 4.3 Built-In DOM Morphing (`innerMorph` & `outerMorph`)

In htmx 2, DOM morphing required external libraries like `idiomorph`. In **htmx v4.0.1, DOM morphing is built directly into the core engine**. When you use `hx-swap="innerMorph"` or `hx-swap="outerMorph"`, htmx diffs the incoming HTML fragment against the live DOM tree and updates only changed attributes and nodes.

```drawlib align=center code=fold file=ch04_morph_decision_flow.png caption="htmx v4.0.1 Built-in DOM Morphing Reconciliation & Freeze Boundaries"
from drawlib import canvas
from drawlib.diagrams.flow import Decision, End, FlowDiagram, Process, Start
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=176, height=78)

flow = FlowDiagram(
    node_style=Styles.Neutral.patch(text_size=9.5),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=9.5),
    title="Built-In DOM Morphing Algorithm (innerMorph / outerMorph)",
)

start = flow.add(Start("Incoming Fragment", width=30, height=11, style=Styles.PrimaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)), xy=(20, 52))
skip_chk = flow.add(Decision("Matches\nhx-morph-skip?", width=34, height=18, style=Styles.WarningNeutral.patch(text_size=9.5)), xy=(60, 52))
keep_node = flow.add(End("Keep Existing\nSubtree Intact", width=32, height=12, style=Styles.SecondaryNeutral.patch(text_size=9.5)), xy=(60, 18))

id_match = flow.add(Process("Match by ID or\nSoft-Match Sibling\n(morphScanLimit=10)", width=36, height=15, style=Styles.PrimaryNeutral.patch(text_size=9.5)), xy=(104, 52))
sync_attr = flow.add(Process("Sync Attributes\n(Skip morphIgnore\ndata-htmx-powered)", width=36, height=15, style=Styles.Neutral.patch(text_size=9.5)), xy=(104, 18))

skip_child = flow.add(Decision("hx-morph-skip\n-children?", width=34, height=18, style=Styles.WarningNeutral.patch(text_size=9.5)), xy=(150, 18))
done = flow.add(End("Recurse Children &\nPreserve Focus/State", width=36, height=13, style=Styles.PrimaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)), xy=(150, 52))

start.connect(skip_chk, padding=1.0)
skip_chk.connect(keep_node, label="Yes", start_side="bottom", end_side="top", padding=1.0)
skip_chk.connect(id_match, label="No", start_side="right", end_side="left", padding=1.0)
id_match.connect(sync_attr, start_side="bottom", end_side="top", padding=1.0)
sync_attr.connect(skip_child, start_side="right", end_side="left", padding=1.0)
skip_child.connect(keep_node, label="Yes (Freeze Children)", start_side="bottom", end_side="bottom", padding=1.0).via((150, 6), (60, 6))
skip_child.connect(done, label="No", start_side="top", end_side="bottom", padding=1.0)

flow.draw(xy=(4.0, 4.0))
canvas.save()
```

### What Morphing Preserves—and Crucial Caveats

- **Preserved State**: Active keyboard focus, text selection, `<input>` user values, scroll offsets, playing `<video>`/`<audio>` elements, CSS transitions, and attached event listeners on matched nodes.
- **Priority ID Matching**: Elements with matching `id` attributes are matched first across sibling scans (controlled by `htmx.config.morphScanLimit = 10`).

> [!WARNING]
> **Morphing intentionally preserves user-typed `<input>` values!** Do not use `innerMorph` or `outerMorph` when your goal is to reset a form back to blank defaults after submission—use `innerHTML`, `outerHTML`, or `outerSync` to reset form inputs cleanly.

### Freezing Elements During Morph (`hx-morph-skip` & `hx-morph-skip-children`)

When embedding third-party Web Components, rich text editors, or sortable containers inside a morphed region, instruct htmx to skip morphing them via attributes or global config selectors:

```html
<div id="dashboard" hx-get="/dashboard/poll" hx-trigger="every 5s" hx-swap="innerMorph">
  <!-- 1. Freeze the entire element (neither attributes nor children are touched) -->
  <canvas id="webgl-viewport" hx-morph-skip></canvas>

  <!-- 2. Update outer attributes from server, but leave internal DOM children untouched -->
  <sortable-kanban data-column-count="4" hx-morph-skip-children>
    <div class="card">Client-dragged card order stays intact</div>
  </sortable-kanban>
</div>
```

---

## 4.4 Swap Modifiers, `hx-preserve`, and View Transitions

Append space-separated modifiers to any `hx-swap` value to customize timing, scrolling, wrapper stripping, and animations:

| Swap Modifier | Syntax Example | Description |
| :--- | :--- | :--- |
| **`swap:<time>`** | `innerHTML swap:150ms` | Waits `<time>` after applying `htmx-swapping` before inserting new content. |
| **`settle:<time>`** | `innerHTML settle:200ms` | Delay between DOM insertion and removing `htmx-settling` (default `1ms`). |
| **`transition:true`** | `outerMorph transition:true` | Wraps the DOM update in `document.startViewTransition()` (View Transitions API). |
| **`scroll:top\|bottom`** | `innerHTML scroll:top` | Scrolls the target container (or `scrollTarget:<sel>`) to top or bottom. |
| **`show:top\|bottom`** | `afterend show:bottom` | Scrolls the viewport so the target (or `showTarget:<sel>`) is visible. |
| **`focusScroll:true`** | `innerHTML focusScroll:true` | Automatically scrolls the focused element into view after the swap. |
| **`ignoreTitle:true`** | `innerHTML ignoreTitle:true` | Prevents `<title>` tags in the response from updating `document.title`. |
| **`strip:true`** | `innerHTML strip:true` | Strips the outermost wrapper tag from the response before swapping. |
| **`swapEmpty:true`** | `innerHTML swapEmpty:true` | Forces the main swap to run even if only `<hx-partial>` or OOB content was returned. |
| **`target:<selector>`** | `outerHTML target:#modal` | Overrides the swap target inline within the `hx-swap` specification. |

### Preserving Elements Across `innerHTML` Swaps (`hx-preserve`)

When using `innerHTML` or `outerHTML` (rather than morphing), any element with a stable `id` and **`hx-preserve="true"`** (or bare `hx-preserve`) is transplanted intact into the newly swapped DOM so video playback or iframe state never restarts:

```html
<div id="lesson-container" hx-get="/lessons/next" hx-swap="innerHTML transition:true">
  <!-- Video continues playing uninterrupted when #lesson-container swaps -->
  <video id="lecture-stream" hx-preserve="true" src="/streams/intro.mp4" controls></video>
  <article id="lesson-notes">Chapter 1 Notes...</article>
</div>
```
