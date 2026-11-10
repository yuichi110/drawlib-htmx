# 6. Deep Dive: Security, Supply Chain & API Surface

`htmx` `v4.0.1` ships **zero production runtime dependencies** (`dependencies: {}` in `package.json`), meaning end-user browsers loading `dist/htmx.js`, `dist/htmx.esm.js`, or `dist/htmax.js` inherit **zero third-party npm supply-chain vulnerabilities**. This chapter dissects the Trivy container/lockfile scan results, CWE-tagged DOM sinks, and built-in hypermedia security boundaries.

```drawlib file=06_supply_chain_cve_breakdown.png caption="Supply-Chain & Container CVE Attribution (Shipped Browser Bundle vs. Dev Lockfile vs. Harness npm CLI)"
from drawlib.canvas import save, setup
from drawlib.charts.bar import BarChart
from drawlib.smartarts import Panel, Table
from drawlib.styles import Styles

setup(width=146, height=70, dpi=150)

left_panel = Panel(
    "CVE Attribution by Scope (0 Shipped Production CVEs)",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
left_panel.draw((3, 4), width=64, height=62)

bar = BarChart(
    axis_line_style=Styles.Dark,
    grid_style=Styles.MutedThin,
    axis_text_style=Styles.Dark.patch(text_size=9.5),
    value_text_style=Styles.DarkBold.patch(text_size=9.5),
    width=56,
    height=42,
    orientation="vertical",
    bar_mode="group",
    categories=[
        "Shipped dist/\n(0 Deps)",
        "Dev Lockfile\n(package-lock)",
        "Harness npm CLI\n(Non-Shipped)",
    ],
)
bar.configure_y_axis(min_value=0, max_value=22, tick_step=5)
bar.add_series("CRITICAL", [0, 0, 1], style=Styles.DangerFlat)
bar.add_series("HIGH", [0, 5, 19], style=Styles.WarningFlat)
bar.add_series("MEDIUM", [0, 15, 8], style=Styles.PrimaryFlat)
bar.draw((7, 7))
bar.draw_legend((8, 53), text_style=Styles.DarkBold.patch(text_size=9.5), orientation="horizontal", item_gap=16.0)

right_panel = Panel(
    "Key Advisories in Dev Lockfile & Harness Image",
    style=Styles.Neutral,
    header_style=Styles.SecondaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
right_panel.draw((70, 4), width=73, height=62)

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
    xy=(73, 56),
    column_widths=[12, 18, 22, 15],
    row_heights=[5.8, 5.8, 5.8, 5.8, 5.8, 5.8, 5.8, 5.8],
    data=[
        ["Sev", "Scope", "Package @ Version", "Fixed Version"],
        ["HIGH", "dev_lockfile", "cross-spawn@7.0.3", "7.0.5"],
        ["HIGH", "dev_lockfile", "ip-address@9.0.5", "10.3.1"],
        ["HIGH", "dev_lockfile", "basic-ftp@5.3.1", "6.2.1"],
        ["MED", "dev_lockfile", "qs@6.15.3", "6.16.0"],
        ["MED", "dev_lockfile", "postcss-sel...@6.1.0", "6.1.5 / 7.1.6"],
        ["CRIT", "harness_npm", "tar@6.2.1 (global npm)", "7.5.19"],
        ["HIGH", "harness_npm", "brace-exp...@2.0.1", "2.1.6 / 5.0.11"],
    ],
    align="top_left",
)

save()
```

```drawlib file=06_cwe_sinks_and_defenses.png caption="AST Dangerous Code Sinks (CWE-79 / CWE-338) & Built-In Hypermedia Security Architecture"
from drawlib.canvas import save, setup
from drawlib.smartarts import CardList, Panel, Table
from drawlib.styles import Styles

setup(width=146, height=70, dpi=150)

left_panel = Panel(
    "AST Dangerous Code Sinks (8 Total: 4 CWE-79, 4 CWE-338)",
    style=Styles.Neutral,
    header_style=Styles.WarningFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
left_panel.draw((3, 4), width=76, height=62)

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
tbl.set_style_cell(Styles.WarningNeutral.shape_fill_color, Styles.DarkBold.patch(text_size=9.5), rows=[1, 2, 3, 4])
tbl.set_style_cell_header(Styles.PrimaryFlat.shape_fill_color, Styles.WhiteBold.patch(text_size=9.5))
tbl.draw_flexible(
    xy=(6, 56),
    column_widths=[12, 28, 30],
    row_heights=[5.4, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2],
    data=[
        ["CWE", "Location", "Sink & Audit Verdict"],
        ["CWE-79", "src/ext/hx-head.js:59", "htmlDoc.innerHTML (wrap #ttPolicy)"],
        ["CWE-79", "src/ext/hx-live.js:612", "elt.innerHTML (wrap #ttPolicy)"],
        ["CWE-79", "src/ext/hx-live.js:613", "elt.outerHTML (wrap #ttPolicy)"],
        ["CWE-79", "src/ext/hx-live.js:796", "elt.innerHTML (wrap #ttPolicy)"],
        ["CWE-338", "hx-history-cache.js:26", "Math.random() (UI cache ID only)"],
        ["CWE-338", "src/ext/hx-multipart.js:18", "Math.random() (stream ID only)"],
        ["CWE-338", "src/ext/hx-sse.js:208", "Math.random() (backoff jitter)"],
        ["CWE-338", "src/ext/hx-ws.js:246", "Math.random() (backoff jitter)"],
    ],
    align="top_left",
)

right_panel = Panel(
    "Built-In htmx v4 Browser Security Defenses",
    style=Styles.Neutral,
    header_style=Styles.SuccessFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
right_panel.draw((82, 4), width=61, height=62)

defenses = CardList(
    style=Styles.SuccessNeutral,
    text_style=Styles.DarkBold.patch(text_size=9.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    badge_shape="rounded_rect",
    badge_style=Styles.SuccessFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    direction="vertical",
    spacing=2.5,
)
defenses.add(
    "W3C Trusted Types (#ttPolicy)",
    "Htmx.__initSecurity (src/htmx.js:230) wraps HTML fragments through trustedTypes.createPolicy.",
    badge_text="D1",
)
defenses.add(
    "hx-ignore Subtree Sandboxing",
    "Replaces v2 hx-disable; skips htmx attribute and hx-on:* processing inside untrusted user HTML.",
    badge_text="D2",
)
defenses.add(
    "HCON Prototype Pollution Guard",
    "HCON.merge (src/htmx.js:75) explicitly rejects __proto__, constructor, and prototype keys.",
    badge_text="D3",
)
defenses.add(
    "Eval-Free Strict CSP (hx-csp.js)",
    "Tokenizes and interprets inline expressions via AST without Function() or AsyncFunction().",
    badge_text="D4",
)
defenses.draw((85, 7), width=55, height=48)

save()
```

## Detailed Security & Supply-Chain Audit Data

### 1. Supply-Chain & Trivy Vulnerability Breakdown

- **Production Browser Bundles (`dist/htmx.js`, `dist/htmx.esm.js`, `dist/htmax.js`)**: **0 dependencies, 0 CVEs**.
- **Secrets & Container IaC Hardening**: `0` hardcoded secrets (`SecurityFacts.secrets = []`, `AstFacts.hardcoded_secrets = []`, `committed_secret_files = []`) and `0` Dockerfile misconfigurations (`misconfigurations = []`).
- **Development Lockfile (`package-lock.json` `dev_or_optional` scope — `22` total CVEs: `0` CRITICAL, `5` HIGH, `15` MEDIUM, `2` LOW)**:
  - `[HIGH]` `CVE-2024-21538` in `cross-spawn@7.0.3` -> fix=`7.0.5, 6.0.6` (ReDoS in dev test runner subprocess spawning)
  - `[HIGH]` `CVE-2026-69192` in `ip-address@9.0.5` -> fix=`10.3.1` (IP address parsing inconsistency in dev server dependency)
  - `[HIGH]` `CVE-2026-102990` in `basic-ftp@5.3.1` -> fix=`6.2.1` (DoS via crafted directory listing in Playwright browser downloader dependency)
  - `[HIGH]` `CVE-2026-19693` & `CVE-2026-56876` in `extract-zip@2.0.1` (Symlink validation in Playwright zip extraction helper)
  - `[MEDIUM]` `CVE-2026-82417` in `qs@6.15.3` -> fix=`6.16.0`
  - `[MEDIUM]` `CVE-2026-104844` in `postcss-selector-parser@6.0.10` / `6.1.0` -> fix=`7.1.6, 6.1.5`
- **Test Harness Global `npm` CLI (`/usr/local/lib/node_modules/npm` inside non-shipped `node:22-bookworm` image — `29` findings)**:
  - Trivy's container image scan flagged `29` advisories in the base image's global `npm` CLI packages (`tar@6.2.1` `CVE-2026-59873` -> `7.5.19`, `brace-expansion@2.0.1` `CVE-2026-102276` -> `5.0.10`, `glob@10.4.2` `CVE-2025-64756` -> `10.5.0`, `minimatch@9.0.5` `CVE-2026-26996` -> `9.0.6`, `pacote@18.0.6` `CVE-2026-9496` -> `21.5.1`). These belong to the container's pre-installed `/usr/local/lib/node_modules/npm` binary and are never part of `htmx`.

### 2. Static CWE Sink Audit (`AstFacts.dangerous_sinks`, 8 Locations)

| Severity | CWE ID | Location | Expression | Engineering Verdict & Remediation |
| :---: | :---: | :--- | :--- | :--- |
| `HIGH` | `CWE-79` (`xss`) | `src/ext/hx-head.js:59` | `htmlDoc.innerHTML = text` | Parses `<head>` markup from server responses; should wrap `text` via core's `#ttPolicy` helper for strict Trusted Types compatibility. |
| `HIGH` | `CWE-79` (`xss`) | `src/ext/hx-live.js:612` | `elt.innerHTML = val` | Reactive `q().html` setter; should route `val` through core's `#ttPolicy` wrapper (`P1-2`). |
| `HIGH` | `CWE-79` (`xss`) | `src/ext/hx-live.js:613` | `elt.outerHTML = val` | Reactive outerHTML setter; should route `val` through core's `#ttPolicy` wrapper (`P1-2`). |
| `HIGH` | `CWE-79` (`xss`) | `src/ext/hx-live.js:796` | `elt.innerHTML = ...` | Template initialization in `hx-live`; should route through `#ttPolicy` (`P1-2`). |
| `LOW` | `CWE-338` | `src/ext/hx-history-cache.js:26` | `Math.random()` | Generates non-security local cache key suffix; benign in browser context. |
| `LOW` | `CWE-338` | `src/ext/hx-multipart.js:18` | `Math.random()` | Generates internal multipart stream correlation ID; benign. |
| `LOW` | `CWE-338` | `src/ext/hx-sse.js:208` | `Math.random()` | Computes exponential backoff jitter for SSE reconnection; benign. |
| `LOW` | `CWE-338` | `src/ext/hx-ws.js:246` | `Math.random()` | Computes exponential backoff jitter for WebSocket reconnection; benign. |

### 3. API Endpoint Attack Surface (`api_endpoints`)

- **Extracted Server HTTP Routes**: `0` (`htmx` is a client-side browser hypermedia library and CLI migration scanner; dynamic server penetration testing `SEC-06` is `not_applicable`).
