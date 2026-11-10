# 2. Architecture & Source Code Structure

`htmx` `v4.0.1` implements a **Microkernel + Event-Driven Extension Hook Architecture**. The core hypermedia engine resides in a single self-contained module (`src/htmx.js`, `1,989` non-blank LOC) that has **zero outgoing imports**, while `17` official opt-in extensions (`src/ext/*.js`, `3,532` combined non-blank LOC) register lifecycle hooks (`htmx_before_request`, `htmx_after_swap`, etc.) via `htmx.registerExtension()` and receive a curated 15-method `#internalAPI` bridge in `init(api)`.

```drawlib file=02_source_structure_tree.png caption="Physical Repository Tree & Top Source Modules by Non-Blank Lines of Code (5,521 Total LOC)"
from drawlib.canvas import save, setup
from drawlib.smartarts import Panel, Table, TreeNode
from drawlib.styles import Styles

setup(width=146, height=74, dpi=150)

left_panel = Panel(
    "Repository & Source Directory Tree",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
left_panel.draw((3, 4), width=56, height=66)

root = TreeNode(
    "htmx (v4.0.1, 5,521 LOC)",
    text_style=Styles.PrimaryBold.patch(text_size=10.0),
    line_style=Styles.MutedBold,
    line_horizontal_margin=1.5,
    line_horizontal_length=3.5,
    line_vertical_margin=3.8,
)
src_node = root.add("src/ (18 JS files + d.ts)", text_style=Styles.DarkBold.patch(text_size=9.5))
src_node.add("htmx.js (1,989 LOC: HCON, RequestQueue, Htmx)", text_style=Styles.Dark.patch(text_size=9.5))
src_node.add("htmx.d.ts (772 LOC: Public TS Declarations)", text_style=Styles.Dark.patch(text_size=9.5))
ext_node = src_node.add("ext/ (17 Official IIFE Extensions)", text_style=Styles.DarkBold.patch(text_size=9.5))
ext_node.add("hx-multipart.js (910 LOC) & hx-live.js (754 LOC)", text_style=Styles.Dark.patch(text_size=9.5))
ext_node.add("hx-ws.js (456 LOC) & hx-sse.js (338 LOC)", text_style=Styles.Dark.patch(text_size=9.5))
ext_node.add("hx-history-cache.js (204) & hx-csp.js (140)", text_style=Styles.Dark.patch(text_size=9.5))
ext_node.add("11 UX/Compat Extensions (630 LOC total)", text_style=Styles.Dark.patch(text_size=9.5))
src_node.add("scripts/upgrade-check.{js,py} (v2->v4 CLI)", text_style=Styles.Dark.patch(text_size=9.5))
src_node.add("skills/*.md (4 Official Developer/AI Guides)", text_style=Styles.Dark.patch(text_size=9.5))
dist_node = root.add("dist/ (IIFE, ESM, Minified & htmax Bundles)", text_style=Styles.DarkBold.patch(text_size=9.5))
test_node = root.add("test/ (88 Suites, 1,854 Browser Tests)", text_style=Styles.DarkBold.patch(text_size=9.5))
root.draw((7, 58))

right_panel = Panel(
    "Source Module Inventory (18 JS Modules, 5,521 Non-Blank LOC)",
    style=Styles.Neutral,
    header_style=Styles.SecondaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
right_panel.draw((62, 4), width=81, height=66)

tbl = Table(
    cell_style=Styles.White,
    text_style=Styles.Dark.patch(text_size=9.5),
    header_cell_style=Styles.PrimaryFlat,
    header_text_style=Styles.WhiteBold.patch(text_size=9.5),
    border_style=Styles.MutedThin,
)
tbl.set_style_cell_evenodd(
    Styles.White.shape_fill_color,
    Styles.Dark.patch(text_size=9.5),
    Styles.Neutral.shape_fill_color,
    Styles.Dark.patch(text_size=9.5),
)
tbl.set_style_cell_header(Styles.PrimaryFlat.shape_fill_color, Styles.WhiteBold.patch(text_size=9.5))
tbl.draw_flexible(
    xy=(65, 60),
    column_widths=[32, 10, 33],
    row_heights=[5.4, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2],
    data=[
        ["Module Path", "LOC", "Architectural Role"],
        ["src/htmx.js", "1,989", "Core Htmx, RequestQueue, HCON & Morph"],
        ["src/ext/hx-multipart.js", "910", "Streaming multipart/mixed swapper"],
        ["src/ext/hx-live.js", "754", "Reactive DOM proxy & q()/$() engine"],
        ["src/ext/hx-ws.js", "456", "Bidirectional WebSocket transport"],
        ["src/ext/hx-sse.js", "338", "SSE EventSource & Fetch stream client"],
        ["src/ext/hx-history-cache.js", "204", "sessionStorage DOM snapshot cache"],
        ["src/ext/hx-csp.js", "140", "Eval-free strict CSP AST interpreter"],
        ["src/ext/hx-head.js", "135", "Document <head> merge & deduplication"],
        ["src/ext/* (10 modules)", "595", "preload, compat, pending, upsert, etc."],
    ],
    align="top_left",
)

save()
```

```drawlib file=02_architecture_thermal_flow.png caption="Layered Microkernel Dependency Graph with Thermal Risk Overlay (HeatmapOverlay) & Execution Flows"
from drawlib.canvas import save, setup
from drawlib.charts.heatmap import HeatmapOverlay
from drawlib.diagrams.class_diagram import ClassDiagram, ClassNode
from drawlib.smartarts import Panel, Roadmap
from drawlib.styles import Styles

setup(width=146, height=84, dpi=150)

left_panel = Panel(
    "Component Dependency Graph & Thermal Hotspot Overlay",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
left_panel.draw((3, 4), width=86, height=76)

cd = ClassDiagram(
    node_style=Styles.Neutral.patch(text_size=9.5),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.Dark.patch(text_size=9.5),
    header_style=Styles.PrimaryFlat,
)

core_node = ClassNode(
    "src/htmx.js (1,989 LOC)",
    stereotype="core microkernel",
    width=36,
    style=Styles.Neutral.patch(text_size=9.5),
    header_style=Styles.PrimaryFlat,
)
core_node.add_attribute("#internalAPI", "15 bound methods", is_public=False)
core_node.add_method("process / ajax / swap", "elt, ctx", "Promise")
core_node.add_method("registerExtension", "name, hooks", "void")
cd.add(core_node, (45, 54))

stream_node = ClassNode(
    "Streaming Extensions",
    stereotype="hx-multipart / ws / sse",
    width=34,
    style=Styles.Neutral.patch(text_size=9.5),
    header_style=Styles.SecondaryFlat,
)
stream_node.add_attribute("hx-multipart.js", "910 LOC (risk 0.12)")
stream_node.add_attribute("hx-ws.js / hx-sse.js", "794 LOC (risk 0.12)")
cd.add(stream_node, (24, 20))

live_node = ClassNode(
    "Reactive & Security Exts",
    stereotype="hx-live / csp / head",
    width=34,
    style=Styles.Neutral.patch(text_size=9.5),
    header_style=Styles.WarningFlat,
)
live_node.add_attribute("hx-live.js", "754 LOC (risk 0.45)")
live_node.add_attribute("hx-csp.js / hx-head.js", "275 LOC")
cd.add(live_node, (66, 20))

cd.connect(stream_node, core_node, "dependency", directed=True, label="init(api)")
cd.connect(live_node, core_node, "dependency", directed=True, label="init(api)")
cd.draw()

overlay = HeatmapOverlay(
    styles=[Styles.SuccessNeutral, Styles.WarningNeutral, Styles.DangerFlat],
    width=86,
    height=80,
    min_value=0.0,
    max_value=0.5,
    default_radius=15.0,
    max_alpha=0.35,
    show_contour_lines=False,
)
overlay.add_spot((66, 20), value=0.45, radius=15.0, label="hx-live (0.45)", label_style=Styles.DangerBold.patch(text_size=9.5))
overlay.add_spot((45, 54), value=0.20, radius=15.0, label="htmx.js (0.20)", label_style=Styles.WarningBold.patch(text_size=9.5))
overlay.add_spot((24, 20), value=0.12, radius=14.0, label="ws/sse/mp (0.12)", label_style=Styles.PrimaryBold.patch(text_size=9.5))
overlay.draw((3, 4))

right_panel = Panel(
    "Core Runtime Execution Flows",
    style=Styles.Neutral,
    header_style=Styles.SecondaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
right_panel.draw((92, 4), width=51, height=76)

rm = Roadmap(
    style=Styles.PrimaryNeutral,
    text_style=Styles.DarkBold.patch(text_size=9.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    spine_style=Styles.PrimaryBold,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    direction="vertical",
    spacing=3.5,
)
rm.add(
    "1. DOM Subtree Processing",
    "process(root) skips hx-ignore,\nbinds hx-on:* & HCON triggers.",
    badge_text="F1",
)
rm.add(
    "2. Fetch & RequestQueue Sync",
    "Resolves :inherited, admits via\nRequestQueue, executes fetch().",
    badge_text="F2",
    style=Styles.SecondaryNeutral,
    badge_style=Styles.SecondaryFlat,
)
rm.add(
    "3. Partial/OOB & Morph Swap",
    "Runs Main -> <hx-partial> -> OOB,\nexecutes __morph & settles DOM.",
    badge_text="F3",
    style=Styles.SuccessNeutral,
    badge_style=Styles.SuccessFlat,
)
rm.draw((95, 8), width=45, height=60)

save()
```

## Architectural Assessment & Module Inventory

### 1. Four-Layer Structural Separation

| Layer | Repository Paths | Allowed Dependencies | Responsibility & Boundary Notes |
| :--- | :--- | :--- | :--- |
| **Core Hypermedia Runtime & DOM Reconciler** | `src/htmx.js`, `src/htmx.d.ts` | *(None — zero imports)* | Implements `HCON` relaxed configuration parser, `RequestQueue` concurrency coordinator, explicit `:inherited` attribute lookup, `fetch()` orchestration, `<hx-partial>` / OOB task extraction, and built-in Idiomorph DOM tree reconciliation. |
| **Streaming & Transport Extensions** | `src/ext/hx-sse.js`, `src/ext/hx-ws.js`, `src/ext/hx-multipart.js`, `src/ext/hx-preload.js`, `src/ext/hx-ptag.js`, `src/ext/hx-download.js` | `src/htmx.js` | Extends the Fetch and event lifecycle with Server-Sent Events (`EventSource` + `ReadableStream`), bidirectional WebSockets with exponential backoff, `multipart/mixed` streaming swaps, speculative prefetching, and `HX-PTag` conditional polling. |
| **Reactive Scripting, DOM & Security Extensions** | `src/ext/hx-live.js`, `src/ext/hx-csp.js`, `src/ext/hx-history-cache.js`, `src/ext/hx-head.js`, `src/ext/hx-targets.js`, `src/ext/hx-upsert.js`, `src/ext/hx-pending.js`, `src/ext/hx-browser-indicator.js`, `src/ext/hx-prompt.js`, `src/ext/hx-alpine-compat.js`, `src/ext/htmx-2-compat.js` | `src/htmx.js` | Provides reactive DOM state proxies (`hx-live`), strict CSP AST expression evaluation without `eval` (`hx-csp`), `sessionStorage` history snapshot caching, `<head>` merging, and htmx 2 / Alpine.js compatibility bridges. |
| **Migration & Tooling Scripts** | `src/scripts/upgrade-check.js`, `src/scripts/upgrade-check.py` | *(Standalone CLI)* | Scans `.html`, `.js`, `.ts`, `.jinja`, `.erb`, and `.php` templates for htmx 2 to htmx 4 migration patterns (`hx-disable` -> `hx-ignore`, colon-separated events, explicit `:inherited`). |

### 2. Complete Source Code Module Inventory & Thermal Hotspots

| Module Path | Non-Blank LOC | Thermal Risk (`risk_score`) | Triggered Rules & Findings |
| :--- | :---: | :---: | :--- |
| `src/ext/hx-live.js` | `754` | **`0.45`** | `common/security_vulnerability` (`1 MEDIUM`: direct `.innerHTML`/`.outerHTML` at lines `612, 613, 796` bypassing `#ttPolicy`) |
| `src/htmx.js` | `1,989` | **`0.20`** | `javascript/code_quality` (`1 LOW`: `4` loose `!=` comparisons in `__morphChildren`, `__findBestMatch`, `__morphNode`) |
| `package-lock.json` | *(Lockfile)* | **`0.15`** | `common/security_vulnerability` (`1 MEDIUM`: `5 HIGH` / `15 MEDIUM` transitive `devDependency` CVEs) |
| `test/tests/ext/hx-ws.js` | *(Test Suite)* | **`0.15`** | `common/runtime_verification` (`1 MEDIUM`: `1ms` `htmx.timeout(1)` race at line `299`) |
| `src/ext/hx-multipart.js` | `910` | **`0.12`** | `0` findings (`81.9%` line coverage across `1,191` statements) |
| `src/ext/hx-ws.js` | `456` | **`0.12`** | `0` findings (`90.0%` line coverage across `588` statements) |
| `src/ext/hx-sse.js` | `338` | **`0.12`** | `0` findings (`95.0%+` line coverage) |
| `src/ext/hx-history-cache.js` | `204` | **`0.12`** | `0` findings (`sessionStorage` history snapshot cache) |
| `src/ext/hx-csp.js` | `140` | `< 0.10` | `0` findings (`73.5%` line coverage; eval-free recursive AST interpreter) |
| `src/ext/hx-head.js` | `135` | `< 0.10` | Grouped under `hx-live.js:612` Trusted Types recommendation (`htmlDoc.innerHTML` at line `59`) |
| `src/ext/hx-preload.js` | `88` | `< 0.10` | `common/security` (`1 LOW`: `fetch()` at line `54` omits `AbortSignal` timeout) |
| `src/ext/hx-alpine-compat.js` | `84` | `< 0.10` | `0` findings (`96.4%` line coverage) |
| `src/ext/htmx-2-compat.js` | `83` | `< 0.10` | `0` findings (`81.7%` line coverage) |
| `src/ext/hx-pending.js` | `82` | `< 0.10` | `0` findings (`100%` line coverage) |
| `src/ext/hx-upsert.js` | `70` | `< 0.10` | `0` findings (`100%` line coverage) |
| `src/ext/hx-browser-indicator.js` | `69` | `< 0.10` | `0` findings (`100%` line coverage) |
| `src/ext/hx-download.js` | `60` | `< 0.10` | Grouped under `hx-preload.js:54` (`fetch()` at line `33` omits `AbortSignal`) |
| `src/ext/hx-targets.js` | `27` | `< 0.10` | `0` findings (`100%` line coverage) |
| `src/ext/hx-ptag.js` | `18` | `< 0.10` | `0` findings (`100%` line coverage) |
| `src/ext/hx-prompt.js` | `14` | `< 0.10` | `0` findings (`100%` line coverage) |
