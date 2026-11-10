# 5. Deep Dive: Code Quality, Testing & Runtime

This chapter examines static JavaScript AST quality metrics (`5,521` non-blank LOC across `18` source modules), SIG maintainability indicators, 12-Factor operational readiness, and the hermetic Playwright Chromium browser test execution (`1,854` test cases, **93.5% line coverage**, **92.3% branch coverage**).

```drawlib file=05_module_quality_heatmap.png caption="Module × Quality Dimension Fitness Matrix (HeatmapChart across Core and Key Extensions)"
from drawlib.canvas import save, setup
from drawlib.charts.heatmap import HeatmapChart
from drawlib.smartarts import Panel
from drawlib.styles import Styles

setup(width=146, height=68, dpi=150)

panel = Panel(
    "Module × Engineering Quality Fitness Matrix (0-100 Score Scale)",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
panel.draw((3, 3), width=140, height=62)

hm = HeatmapChart(
    styles=[Styles.WarningNeutral, Styles.PrimaryNeutral, Styles.SuccessFlat],
    x_categories=["Line Cov %", "Branch Cov %", "Import Hygiene", "Encapsulation", "Timeout/PRR"],
    y_categories=[
        "src/htmx.js (1989 LOC)",
        "hx-live.js (754 LOC)",
        "hx-ws.js (456 LOC)",
        "hx-sse.js (338 LOC)",
        "hx-multipart.js (910 LOC)",
        "hx-csp.js (140 LOC)",
        "hx-head.js (135 LOC)",
        "hx-preload.js (88 LOC)",
    ],
    width=102,
    height=46,
    min_value=50.0,
    max_value=100.0,
    cell_gap=0.8,
    cell_r=0.5,
    value_format="{:.0f}%",
    axis_text_style=Styles.DarkBold.patch(text_size=9.5),
    value_text_style=Styles.DarkBold.patch(text_size=9.5),
)
hm.set_data([
    [94.3, 93.1, 100.0, 98.0, 100.0],
    [97.6, 94.0, 100.0, 92.0, 95.0],
    [90.0, 77.0, 100.0, 95.0, 100.0],
    [97.2, 91.5, 100.0, 95.0, 100.0],
    [81.9, 81.9, 100.0, 94.0, 95.0],
    [73.5, 58.1, 100.0, 96.0, 100.0],
    [77.4, 51.5, 100.0, 92.0, 95.0],
    [93.1, 82.7, 100.0, 95.0, 75.0],
])
hm.draw((32, 7))
hm.draw_legend((136, 46), text_style=Styles.Dark.patch(text_size=9.5), orientation="vertical", num_steps=4)

save()
```

```drawlib file=05_runtime_coverage_breakdown.png caption="Hermetic Browser Test Execution Summary & Lowest-Covered Modules (Line vs. Branch Coverage %)"
from drawlib.canvas import save, setup
from drawlib.charts.bar import BarChart
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Styles

setup(width=146, height=70, dpi=150)

left_panel = Panel(
    "Hermetic Chromium Test Execution (--network=none)",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
left_panel.draw((3, 4), width=54, height=62)

kpis = KpiCards(
    style=Styles.PrimaryNeutral,
    metric_style=Styles.PrimaryBold.patch(text_size=13.5),
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Dark.patch(text_size=9.5),
    accent_style=Styles.PrimaryFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.34,
    spacing=2.8,
)
kpis.add(
    "1,849",
    "Passing Browser Tests",
    "Out of 1,854 total tests across 88 suites (61.33s in Playwright Chromium)",
    style=Styles.SuccessNeutral,
    metric_style=Styles.SuccessBold.patch(text_size=13.5),
    accent_style=Styles.SuccessFlat,
)
kpis.add(
    "93.5%",
    "Measured Line Coverage",
    "6,267 / 6,706 statements covered; 92.3% branch coverage across src/",
    style=Styles.PrimaryNeutral,
)
kpis.add(
    "1 Race",
    "Timing-Sensitive Failure",
    "hx-ws.js:299 awaits htmx.timeout(1) vs mockWebSocket open timer",
    style=Styles.WarningNeutral,
    metric_style=Styles.WarningBold.patch(text_size=13.5),
    accent_style=Styles.WarningFlat,
)
kpis.draw((6, 8), width=48, height=48, columns=1)

right_panel = Panel(
    "Lowest-Covered Modules (Line % vs. Branch %, Ascending)",
    style=Styles.Neutral,
    header_style=Styles.SecondaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
right_panel.draw((60, 4), width=83, height=62)

bar = BarChart(
    axis_line_style=Styles.Dark,
    grid_style=Styles.MutedThin,
    axis_text_style=Styles.Dark.patch(text_size=9.5),
    value_text_style=Styles.DarkBold.patch(text_size=9.5),
    width=76,
    height=43,
    orientation="vertical",
    bar_mode="group",
    categories=[
        "hx-csp",
        "hx-head",
        "2-compat",
        "multipart",
        "hx-ws",
        "preload",
        "alpine",
        "download",
    ],
)
bar.configure_y_axis(min_value=0, max_value=105, tick_step=25)
bar.add_series("Line Cov %", [73.5, 77.4, 81.7, 81.9, 90.0, 93.1, 96.4, 96.6], style=Styles.PrimaryFlat)
bar.add_series("Branch Cov %", [58.1, 51.5, 82.4, 81.9, 77.0, 82.7, 84.8, 65.2], style=Styles.SecondaryFlat)
bar.draw((63, 7))
bar.draw_legend((72, 54), text_style=Styles.DarkBold.patch(text_size=9.5), orientation="horizontal", item_gap=18.0)

save()
```

## Static AST Quality & Containerized Runtime Analysis

### 1. Static AST Quality & SIG Maintainability Metrics

| Metric Category | Deterministic Value | Technical Interpretation |
| :--- | :---: | :--- |
| **Codebase Size** | `18` files / `5,521` LOC | `src/htmx.js` (`1,989` non-blank LOC) + `17` extensions in `src/ext/*.js` (`3,532` non-blank LOC). |
| **Circular Dependencies** | `0` | Strictly acyclic hub-and-spoke topology (`src/htmx.js` has `0` outgoing imports). |
| **Global State Usages** | `1` (`src/htmx.js:1`) | Top-level `var htmx = (() => { ... })()` singleton required for `<script src="/htmx.js">` browser globals. |
| **Loose Inequality (`!=`)** | `4` (`src/htmx.js:2044..2194`) | Located in `__morphChildren`, `__findBestMatch`, and `__morphNode`; recommended to standardize on `!==`. |
| **Empty `catch {}` Blocks** | `6` (`src/htmx.js:40..2315`) | Deliberate progressive feature fallbacks (`HCON.parse` JSON probe, `CSSStyleSheet` indicator injection, `focus()`, `Element.moveBefore()`, View Transitions). |
| **Missing `AbortSignal` Timeouts** | `2` (`hx-preload.js:54`, `hx-download.js:33`) | Core `Htmx.__initTimeout` (`src/htmx.js:679`) enforces a `60,000ms` `AbortController` timeout on all primary requests; `hx-preload` and `hx-download` invoke `fetch()` directly without attaching `AbortSignal`. |
| **Console Logging** | `2` (`src/htmx.js:1522`, `htmx-2-compat.js:30`) | `src/htmx.js:1522` is strictly gated behind `if (this.config.logAll)`; `htmx-2-compat.js:30` emits deliberate developer migration warnings. |
| **Assertion-Free Test Candidates** | `47` (all verified) | All `47` AST-flagged test blocks delegate assertions to shared helpers in `test/lib/helpers.js` (`assertTextContentIs`, `assertInnerHtmlIs`). |

### 2. Hermetic Container Runtime & Browser Test Verification

- **Container Harness Build**: Built `.pni/dockerfiles/root/Dockerfile` (`node:22-bookworm` + Playwright Chromium + local `chai@4.5.0` cache) in `127.33s` (`status=passed`).
- **Offline Browser Test Suite (`--network=none`)**: Executed `1,854` browser tests across `88` suites in `61.33s`:
  - **Passed**: `1,849` (`99.73%` of active tests)
  - **Skipped**: `4`
  - **Failed**: `1` timing-sensitive race in `test/tests/ext/hx-ws.js:299`:
    ```text
    [FAILURE] JEOsiBLigWWJDrt4YZ0H1 > hx-ws WebSocket extension > Message Sending.queues a message until the initial connection opens:
    AssertionError: expected +0 to equal 1
    ```
    *Root Cause*: Line `299` executes `await htmx.timeout(1)` before asserting `expect(connection.queue.length).to.equal(1)`. Under parallel multi-tab Chromium execution, the `1ms` timer can fire after `mockWebSocket`'s auto-open callback has already flushed the queue (`length === 0`).
- **Startup Smoke Check (`library+cli`)**: Verified both `dist/htmx.js` and `node src/scripts/upgrade-check.js --help` (`status=passed`, exit code `0`).

### 3. Lowest-Covered Modules (Measured V8 Coverage, Ascending)

| Module Path | Line Coverage | Branch Coverage | Statements Covered | Notes |
| :--- | :---: | :---: | :---: | :--- |
| `src/ext/hx-csp.js` | `73.5%` | `58.1%` | `161 / 219` | Uncovered branches correspond to defensive AST operator/syntax error paths. |
| `src/ext/hx-head.js` | `77.4%` | `51.5%` | `147 / 190` | Uncovered branches handle edge-case `<head>` script/link re-evaluation fallbacks. |
| `src/ext/htmx-2-compat.js` | `81.7%` | `82.4%` | `76 / 93` | Legacy htmx 2 event/attribute translation shims. |
| `src/ext/hx-multipart.js` | `81.9%` | `81.9%` | `975 / 1,191` | Streaming boundary chunk split and malformed header edge cases. |
| `src/ext/hx-ws.js` | `90.0%` | `77.0%` | `529 / 588` | WebSocket reconnect backoff and close-code branches. |
| `src/ext/hx-preload.js` | `93.1%` | `82.7%` | `95 / 102` | Speculative mouseover/mousedown prefetch triggers. |
| `src/htmx.js` *(Core Engine)* | **94.3%** | **93.1%** | `2,914 / 3,090` | Core `HCON`, `RequestQueue`, `Htmx`, `fetch()`, and Idiomorph engine. |
| `src/ext/hx-alpine-compat.js` | `96.4%` | `84.8%` | `106 / 110` | Alpine.js morph/swap state synchronization bridge. |
| `src/ext/hx-download.js` | `96.6%` | `65.2%` | `85 / 88` | Blob download and `Content-Disposition` filename extraction. |
| `src/ext/hx-live.js` | **97.6%** | **94.0%** | `1,042 / 1,068` | Reactive DOM state proxies and `q()`/`$()` query wrappers. |
