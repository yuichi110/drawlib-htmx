# 3. Recommended Remediation Roadmap

The PNI501 workflow identified **8 prioritized engineering action items** (`0` `P0` blockers, `3` `P1` high-value improvements, and `5` `P2` hardening & polish enhancements). Because `htmx` `v4.0.1` already achieves `Grade S` (`91 / 100`) with zero production dependencies, this roadmap focuses on dev-lockfile CVE hygiene, Trusted Types consistency across extensions, and 100% deterministic offline browser testing.

```drawlib file=03_remediation_timeline.png caption="Phased Remediation Roadmap (P1 High-Value Improvements -> P2 Hardening & Offline CI Polish)"
from drawlib.canvas import save, setup
from drawlib.smartarts import Panel, Roadmap
from drawlib.styles import Styles

setup(width=146, height=66, dpi=150)

p1_panel = Panel(
    "Phase 1 (P1): High-Value Security, Trusted Types & Test Determinism",
    style=Styles.Neutral,
    header_style=Styles.WarningFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
p1_panel.draw((3, 4), width=68, height=58)

rm_p1 = Roadmap(
    style=Styles.WarningNeutral,
    text_style=Styles.DarkBold.patch(text_size=10.0),
    description_style=Styles.Dark.patch(text_size=9.5),
    spine_style=Styles.WarningBold,
    badge_style=Styles.WarningFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    direction="vertical",
    spacing=3.5,
)
rm_p1.add(
    "P1-1: Refresh Transitive devDependencies",
    "Bump cross-spawn >=7.0.5, ip-address >=10.7.1,\nbasic-ftp >=6.2.1, qs >=6.16.0 in lockfile.",
    badge_text="P1",
)
rm_p1.add(
    "P1-2: Trusted Types in hx-live & hx-head",
    "Expose core #ttPolicy helper on #internalAPI;\nwrap innerHTML in hx-live.js & hx-head.js.",
    badge_text="P1",
)
rm_p1.add(
    "P1-3: Fix 1ms Timer Race in hx-ws.js Test",
    "Replace await htmx.timeout(1) at hx-ws.js:299\nwith deterministic mockWebSocket open control.",
    badge_text="P1",
)
rm_p1.draw((6, 8), width=62, height=45)

p2_panel = Panel(
    "Phase 2 (P2): Code Quality, Offline Test Runner & Governance Polish",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
p2_panel.draw((75, 4), width=68, height=58)

rm_p2 = Roadmap(
    style=Styles.PrimaryNeutral,
    text_style=Styles.DarkBold.patch(text_size=9.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    spine_style=Styles.PrimaryBold,
    badge_style=Styles.PrimaryFlat,
    badge_text_style=Styles.WhiteBold.patch(text_size=9.5),
    direction="vertical",
    spacing=2.2,
)
rm_p2.add(
    "P2-1: AbortSignal on Extension fetch()",
    "Pass ctx.request.signal or defaultTimeout to\nfetch() in hx-preload.js:54 & hx-download.js:33.",
    badge_text="P2",
)
rm_p2.add(
    "P2-2: Strict !== in DOM Morphing Engine",
    "Replace 4 loose != checks at src/htmx.js:2044,\n2100, 2127, 2194 with strict !==.",
    badge_text="P2",
)
rm_p2.add(
    "P2-3: Add engines.node & Static Linter",
    "Declare engines.node >=20.0.0 and configure\nBiome/ESLint check in package.json.",
    badge_text="P2",
)
rm_p2.add(
    "P2-4: Add SECURITY.md & Dependabot",
    "Publish SECURITY.md & dependabot.yml;\nvendor chai.js for offline tests (P2-5).",
    badge_text="P2",
)
rm_p2.draw((78, 7), width=62, height=46)

save()
```

```drawlib file=03_action_plan_matrix.png caption="Action Plan Traceability Matrix (Priority, Target Files, Related Rules/CVEs, and Expected Impact)"
from drawlib.canvas import save, setup
from drawlib.smartarts import Panel, Table
from drawlib.styles import Styles

setup(width=146, height=74, dpi=150)

panel = Panel(
    "Prioritized Action Plan Traceability Matrix (P1 -> P2, 8 Total Items)",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
panel.draw((3, 3), width=140, height=68)

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
    xy=(6, 61),
    column_widths=[10, 36, 30, 26, 32],
    row_heights=[6.0, 6.2, 6.2, 6.2, 6.2, 6.2, 6.2, 6.2, 6.2],
    data=[
        ["Prio", "Action Item Title", "Target Files", "Related Rules / CVEs", "Expected Impact"],
        ["P1", "Refresh devDependencies in lockfile", "package-lock.json", "CVE-2024-21538, +3", "Resolves 5 HIGH dev CVEs"],
        ["P1", "Route innerHTML via Trusted Types", "src/ext/hx-live.js, +2", "CWE-79, security_vuln", "Full strict CSP compatibility"],
        ["P1", "Fix 1ms timer race in hx-ws test", "test/tests/ext/hx-ws.js", "runtime_verification", "100% deterministic CI runs"],
        ["P2", "Attach AbortSignal to ext fetch()", "src/ext/hx-preload.js", "common/security", "Prevents hung prefetch I/O"],
        ["P2", "Use strict !== in DOM morphing", "src/htmx.js", "javascript/code_quality", "Eliminates coercive != checks"],
        ["P2", "Declare engines.node & linter", "package.json", "javascript/dependencies", "Catches syntax issues early"],
        ["P2", "Add SECURITY.md & Dependabot", "package.json", "common/supply_chain", "OpenSSF Scorecard compliance"],
        ["P2", "Vendor chai.js for offline WTR", "test/web-test-runner...", "runtime_verification", "Out-of-box --network=none"],
    ],
    align="top_left",
)

save()
```

## Detailed Action Items (`P1` -> `P2`)

1. **`[P1]` Refresh transitive `devDependencies` in `package-lock.json` to resolve 5 HIGH CVEs** (`dependencies`)
   - **Target Files**: `package-lock.json`, `package.json`
   - **Related Rules / CVEs**: `common/security_vulnerability`, `CVE-2024-21538`, `CVE-2026-69192`, `CVE-2026-102990`, `CVE-2026-82417`
   - **Action**: Update `package-lock.json` via `npm audit fix` or `package.json` `overrides` to bump `cross-spawn` to `>=7.0.5`, `ip-address` to `>=10.7.1`, `basic-ftp` to `>=6.2.1`, and `qs` to `>=6.16.0`.
   - **Expected Impact**: Eliminates all fixable HIGH and MEDIUM CVEs in the development and test toolchain lockfile.

2. **`[P1]` Route `innerHTML`/`outerHTML` assignments in `hx-live.js` and `hx-head.js` through core Trusted Types policy** (`security`)
   - **Target Files**: `src/ext/hx-live.js`, `src/ext/hx-head.js`, `src/htmx.js`
   - **Related Rules / CVEs**: `common/security_vulnerability`, `CWE-79`
   - **Action**: Expose a Trusted Types helper on `#internalAPI` in `src/htmx.js` and use it in `src/ext/hx-live.js:612,613,796` and `src/ext/hx-head.js:59` before assigning to `.innerHTML` or `.outerHTML`.
   - **Expected Impact**: Ensures full compatibility with `require-trusted-types-for 'script'` CSP policies across all official extensions.

3. **`[P1]` Eliminate 1ms timer race in `hx-ws.js` message queue unit test** (`testing`)
   - **Target Files**: `test/tests/ext/hx-ws.js`
   - **Related Rules**: `common/runtime_verification`, `javascript/testing`
   - **Action**: In `test/tests/ext/hx-ws.js:293-310`, trigger `mockWebSocket` open deterministically (or increase mock auto-open latency) after asserting `connection.queue.length === 1` instead of relying on `await htmx.timeout(1)`.
   - **Expected Impact**: Makes the 1,854-test Playwright browser suite 100% deterministic under high parallel concurrency.

4. **`[P2]` Attach `AbortSignal` timeout to extension `fetch()` calls in `hx-preload` and `hx-download`** (`code_quality`)
   - **Target Files**: `src/ext/hx-preload.js`, `src/ext/hx-download.js`
   - **Related Rules**: `common/security`, `javascript/code_quality`
   - **Action**: Propagate `ctx.request.signal` or `AbortSignal.timeout(htmx.config.defaultTimeout)` into the `fetch()` options in `src/ext/hx-preload.js:54` and `src/ext/hx-download.js:33`.
   - **Expected Impact**: Prevents hung background prefetch or download requests from leaking browser connections.

5. **`[P2]` Standardize strict equality (`!==`) in DOM morphing routines** (`code_quality`)
   - **Target Files**: `src/htmx.js`
   - **Related Rules**: `javascript/code_quality`
   - **Action**: Replace loose `!=` checks at lines `2044`, `2100`, `2127`, and `2194` of `src/htmx.js` with strict `!==` comparisons.
   - **Expected Impact**: Eliminates coercive equality checks in hot DOM tree reconciliation loops.

6. **`[P2]` Declare `engines.node` and static lint script in `package.json`** (`dependencies`)
   - **Target Files**: `package.json`
   - **Related Rules**: `javascript/dependencies`
   - **Action**: Add an `engines` field specifying `Node >=20` and configure Biome or ESLint in `devDependencies` for static syntax/style verification.
   - **Expected Impact**: Enforces consistent Node runtime expectations and catches syntax regressions prior to browser test runs.

7. **`[P2]` Add `SECURITY.md` and Dependabot configuration for automated supply-chain hygiene** (`security`)
   - **Target Files**: `package.json`
   - **Related Rules**: `common/supply_chain`
   - **Action**: Create `SECURITY.md` with vulnerability reporting instructions and `.github/dependabot.yml` for automated `npm` lockfile PRs.
   - **Expected Impact**: Satisfies OpenSSF Scorecard supply-chain governance checks and prevents `devDependency` drift.

8. **`[P2]` Vendor or declare `chai` in `devDependencies` for offline test execution** (`testing`)
   - **Target Files**: `test/web-test-runner.config.mjs`, `package.json`
   - **Related Rules**: `common/runtime_verification`, `javascript/dependencies`
   - **Action**: Vendor `chai.js` under `test/lib/chai.js` (or add `chai` to `devDependencies`) and replace the `https://unpkg.com/chai@4.5.0/chai.js` script URL in `test/web-test-runner.config.mjs`.
   - **Expected Impact**: Allows `npm test` to execute in air-gapped and `--network=none` CI environments without external CDN access.
