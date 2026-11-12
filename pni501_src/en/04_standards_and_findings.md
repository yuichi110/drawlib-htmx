# 4. Audit Standards, Rule Compliance & Findings

The PNI501 workflow evaluated `htmx` `v4.0.1` across **6 executed audit steps** (`security_vulnerability_audit`, `javascript_ast_audit`, `repo_structure_audit`, `container_runtime_audit`, `library_hygiene_audit`, and `javascript_test_audit`) and **14 active engineering rules**. Overall rule compliance stands at **10 PASS, 4 WARN, and 0 FAIL**, with **8 raw findings** consolidated into **7 unique repository locations**.

```drawlib file=04_audit_steps_and_rules.png caption="Executed Audit Step Scores (Weakest -> Strongest) & Rule Compliance Summary"
from drawlib.canvas import save, setup
from drawlib.charts.bar import BarChart
from drawlib.smartarts import Panel, Table
from drawlib.styles import Styles

setup(width=146, height=74, dpi=150)

left_panel = Panel(
    "Audit Step Scores (Sorted Weakest -> Strongest)",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
left_panel.draw((3, 4), width=62, height=66)

bar = BarChart(
    axis_line_style=Styles.Dark,
    grid_style=Styles.MutedThin,
    axis_text_style=Styles.Dark.patch(text_size=9.5),
    value_text_style=Styles.DarkBold.patch(text_size=9.5),
    width=54,
    height=52,
    orientation="horizontal",
    categories=[
        "sec_vuln (A)",
        "js_ast (A)",
        "repo_deps (S)",
        "runtime (S)",
        "lib_hygiene (S)",
        "js_test (S)",
    ],
)
bar.configure_x_axis(min_value=0, max_value=100, tick_step=20)
bar.add_series("Step Score", [88, 89, 90, 92, 94, 94], style=Styles.PrimaryFlat)
bar.draw((7, 7))

right_panel = Panel(
    "Rule Compliance Matrix (WARN -> PASS, 14 Rules)",
    style=Styles.Neutral,
    header_style=Styles.SecondaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
right_panel.draw((68, 4), width=75, height=66)

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
    xy=(71, 60),
    column_widths=[12, 38, 19],
    row_heights=[5.4, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2, 5.2],
    data=[
        ["Status", "Rule ID", "Key Evidence"],
        ["WARN", "common/runtime_verification", "1,849/1,854 pass; 93.5% cov"],
        ["WARN", "common/security_vulnerability", "0 prod CVEs; 5 HIGH dev CVEs"],
        ["WARN", "common/supply_chain", "Lockfile OK; no SECURITY.md"],
        ["WARN", "javascript/code_quality", "4 loose !=; 2 fetch timeouts"],
        ["PASS", "common/architecture", "0 cycles; 15-method API"],
        ["PASS", "common/library_guidelines", "12 public + 86 # private"],
        ["PASS", "common/production_readiness", "60s AbortController timeout"],
        ["PASS", "javascript/testing", "88 suites; fetch-mock"],
        ["PASS", "javascript/typing (+5 more)", "772-line src/htmx.d.ts"],
    ],
    align="top_left",
)

save()
```

```drawlib file=04_consolidated_findings_table.png caption="Consolidated Location Findings Evidence Table (7 Unique Locations from 8 Raw Findings)"
from drawlib.canvas import save, setup
from drawlib.smartarts import Panel, Table
from drawlib.styles import Styles

setup(width=146, height=70, dpi=150)

panel = Panel(
    "Consolidated Findings by Location (CRITICAL -> LOW, 7 Locations)",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
panel.draw((3, 3), width=140, height=64)

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
tbl.set_style_cell(Styles.WarningNeutral.shape_fill_color, Styles.DarkBold.patch(text_size=9.5), rows=[1, 2, 3])
tbl.set_style_cell_header(Styles.PrimaryFlat.shape_fill_color, Styles.WhiteBold.patch(text_size=9.5))
tbl.draw_flexible(
    xy=(6, 57),
    column_widths=[12, 28, 38, 28, 28],
    row_heights=[6.0, 6.4, 6.4, 6.4, 6.4, 6.4, 6.4, 6.4],
    data=[
        ["Sev", "Location (file:line)", "Rule ID(s)", "Deterministic Evidence", "Recommended Fix"],
        ["MED", "package-lock.json:1", "common/\nsecurity_vulnerability", "5 HIGH, 15 MED dev CVEs", "npm audit fix / overrides"],
        ["MED", "src/ext/hx-live.js:612", "common/\nsecurity_vulnerability", "Direct innerHTML/outerHTML", "Wrap via #ttPolicy helper"],
        ["MED", "test/tests/ext/hx-ws.js:299", "common/\nruntime_verification", "await htmx.timeout(1) race", "Deterministic mock open"],
        ["LOW", "package.json:1", "javascript/dependencies,\ncommon/supply_chain", "No linter/SECURITY.md", "Add engines, lint, policy"],
        ["LOW", "src/ext/hx-preload.js:54", "common/security", "fetch() without AbortSignal", "Pass ctx.request.signal"],
        ["LOW", "src/htmx.js:2044", "javascript/code_quality", "4 loose != in morph engine", "Use strict !== comparison"],
        ["LOW", "test/web-test-runner...:20", "common/\nruntime_verification", "unpkg CDN chai@4.5.0 script", "Vendor chai.js locally"],
    ],
    align="top_left",
)

save()
```

## Full Rule Compliance & Findings Reference

### 1. Executed Audit Step Scores (Weakest -> Strongest)

| Audit Step ID | Score & Grade | Verdict Counts | Step Synthesis |
| :--- | :---: | :---: | :--- |
| **`security_vulnerability_audit`** | **88 / 100 (`A`)** | `pass=0, warn=2, fail=0` | Production bundles (`dist/htmx.js`, `dist/htmx.esm.js`, `dist/htmax.js`) have `0` runtime dependencies, `0` leaked secrets, and `0` container misconfigurations. `package-lock.json` contains `22` `devDependency` advisories (`5` HIGH, `15` MEDIUM, `2` LOW), and `hx-live.js` / `hx-head.js` assign `.innerHTML` directly without core's `#ttPolicy`. |
| **`javascript_ast_audit`** | **89 / 100 (`A`)** | `pass=5, warn=1, fail=0` | `18` source modules (`5,521` non-blank LOC) with `0` circular dependencies and a `772`-line TypeScript declaration file (`src/htmx.d.ts`). Warnings note `4` loose `!=` checks in morphing and `2` extension `fetch()` calls omitting `AbortSignal`. |
| **`repo_structure_audit`** | **90 / 100 (`S`)** | `pass=5, warn=0, fail=0` | Zero runtime dependencies, `6` pinned `devDependencies` in `package-lock.json`, dual licensing (`LICENSE-HTMX` BSD-0-Clause + `LICENSE` Apache-2.0), and comprehensive multi-target exports in `package.json`. |
| **`container_runtime_audit`** | **92 / 100 (`S`)** | `pass=1, warn=1, fail=0` | Hermetic Node 22 + Playwright Chromium image built in `127.33s`; `1,854` real-browser tests executed with `--network=none` in `61.33s` (`1,849` passed, `4` skipped, `1` timer race at `hx-ws.js:299`), achieving **93.5% line coverage** and **92.3% branch coverage**. |
| **`library_hygiene_audit`** | **94 / 100 (`S`)** | `pass=3, warn=0, fail=0` | Strictly bounded public API (`12` public methods on `htmx`, `86` internal methods lowered via `sed` to ES2022 `#` private fields in `dist/`), silent-by-default logging (`logAll = false`), and multi-format bundles. |
| **`javascript_test_audit`** | **94 / 100 (`S`)** | `pass=1, warn=0, fail=0` | `88` browser test suites (`44` unit, `23` attributes, `6` end2end, `15` ext) with `1,849` Mocha/Chai `it()` blocks, deterministic `fetch-mock.js` isolation, and per-test DOM cleanup. |

### 2. Complete Rule Compliance Matrix (`FAIL -> WARN -> PASS`)

| Status | Rule ID | Source Action | Deterministic Evidence & Summary |
| :---: | :--- | :--- | :--- |
| **WARN** | `common/runtime_verification` | `runtime_verification` | `harness_build=passed (127.33s)`; offline tests `total=1854, passed=1849, failed=1` (`hx-ws.js:299` `1ms` timer race), `skipped=4`; V8 coverage `line=93.5%, branch=92.3%` (`6,267/6,706` statements); `smoke_check=passed`. |
| **WARN** | `common/security_vulnerability` | `security_vulnerability_audit` | `0` production runtime dependencies in `package.json`; `0` secrets; `0` misconfigs; `22` `devDependencies` CVEs in `package-lock.json` (`5` HIGH: `CVE-2024-21538`, `CVE-2026-69192`, `CVE-2026-102990`, `CVE-2026-19693`, `CVE-2026-56876`); direct `innerHTML` assignments in `src/ext/hx-head.js:59` and `src/ext/hx-live.js:612,613,796` bypass core Trusted Types policy. |
| **WARN** | `common/supply_chain` | `security_vulnerability_audit` | `package-lock.json` committed (`0` unpinned specs); `LICENSE` present; `SECURITY.md=False`; `dependency_automation=False`. |
| **WARN** | `javascript/code_quality` | `ast_and_quality` | `4` loose equality (`!=`) checks in `src/htmx.js:2044,2100,2127,2194`; `6` intentional progressive-fallback `catch {}` blocks in `src/htmx.js`; `2` `fetch()` calls without `AbortSignal` timeout in `src/ext/hx-download.js:33` and `src/ext/hx-preload.js:54`. |
| **PASS** | `common/architecture` | `ast_and_quality` | `0` circular dependencies across `18` modules; clean hub-and-spoke extension architecture via `htmx.registerExtension()` and `#internalAPI`. |
| **PASS** | `common/documentation` | `repo_and_deps` | Root `README.md`, `CHANGELOG.md`, `4` official skill guides in `src/skills/*.md`, `772`-line JSDoc-annotated `src/htmx.d.ts`, and `4` Diataxis portals. |
| **PASS** | `common/git_workflow` | `repo_and_deps` | `.gitignore` (`230` lines) excludes `node_modules/`, `coverage/`, `.drawlib/`, and `.pni/cache/` while tracking upstream `dist/` and lockfiles. |
| **PASS** | `common/library_guidelines` | `library_hygiene` | `package.json` exports `main`, `module`, `jsdelivr`, `unpkg`, `types`, and `web-types`; build scripts lower all `__` internal methods to `#` private fields; `0` runtime dependencies. |
| **PASS** | `common/maintainability` | `ast_and_quality` | `5,521` non-blank LOC across `18` files (`src/htmx.js` `1,989` LOC, `hx-multipart.js` `910` LOC, `hx-live.js` `754` LOC); `98` well-factored methods in `Htmx` class. |
| **PASS** | `common/production_readiness` | `runtime_verification` | Core requests enforce `defaultTimeout=60000ms` via `AbortController` (`__initTimeout` in `src/htmx.js:679`); `hx-ws.js` and `hx-sse.js` implement exponential backoff with jitter. |
| **PASS** | `common/security` | `repo_and_deps` | `0` committed secret files; `HCON.merge` explicitly blocks `__proto__`, `constructor`, and `prototype` (`src/htmx.js:75`); `#ttPolicy` Trusted Types hook and `hx-csp.js` extension. |
| **PASS** | `javascript/dependencies` | `repo_and_deps` | `0` runtime dependencies; all `6` build/test packages isolated in `devDependencies`. |
| **PASS** | `javascript/testing` | `test_health` | `88` test files across `test/tests/{unit,attributes,end2end,ext}/*.js` (`1,849` `it()` blocks); deterministic HTTP mocking via `test/lib/fetch-mock.js`. |
| **PASS** | `javascript/typing` | `ast_and_quality` | Companion `src/htmx.d.ts` (`772` lines) provides full TypeScript contracts for `Htmx`, `HtmxConfig`, `HtmxRequestCtx`, `HtmxEventMap`, and `HxLive`. |

### 3. Configured Design Waivers (`pni.toml` `[[opt_out]]`)

- **`DS-0026`** (scope: `.pni/dockerfiles/**`, matched: `0`): Hermetic batch test container exits upon `@web/test-runner` completion; daemon `HEALTHCHECK` is not applicable.
