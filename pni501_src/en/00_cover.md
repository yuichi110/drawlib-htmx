# htmx v4.0.1 — PNI501 Software Health Diagnostic Report

**Project**: `htmx` (`v4.0.1`) | **Language**: `javascript` (`ES2022` + `TypeScript d.ts`) | **Workflow**: `pni501` (`wf-e3385881`)

```drawlib file=00_cover_scorecard.png caption="PNI501 Software Health Scorecard for htmx v4.0.1 (Overall Score: 91/100, Grade S)"
from drawlib.canvas import save, setup
from drawlib.smartarts import KpiCards, Panel
from drawlib.styles import Styles
from drawlib.text import text

setup(width=146, height=64, dpi=150)

hero_panel = Panel(
    "htmx v4.0.1 — PNI501 Comprehensive Engineering Audit (wf-e3385881)",
    "Evaluated At: 2026-11-10T12:15:56Z | Target Root: . | Archetype: Browser Hypermedia Library + CLI",
    style=Styles.Neutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=12.0),
    description_style=Styles.White.patch(text_size=9.5),
    header_height=11.0,
)
hero_panel.draw((4, 4), width=138, height=56)

kpis = KpiCards(
    style=Styles.PrimaryNeutral,
    metric_style=Styles.PrimaryBold.patch(text_size=16.0),
    text_style=Styles.DarkBold.patch(text_size=10.5),
    description_style=Styles.Dark.patch(text_size=9.5),
    accent_style=Styles.PrimaryFlat,
    accent_position="left_pill",
    metric_layout="left_column",
    metric_width_ratio=0.32,
    spacing=3.5,
)
kpis.add(
    "91 / 100",
    "Overall Score (Grade S)",
    "7-Axis Weighted Synthesis: Arch 93, Quality 88, Typing 93, Testing 93, Deps 88, Security 90, Docs 95",
    style=Styles.SuccessNeutral,
    metric_style=Styles.SuccessBold.patch(text_size=16.0),
    accent_style=Styles.SuccessFlat,
)
kpis.add(
    "10 / 14",
    "Active Rules Passed",
    "10 PASS, 4 WARN, 0 FAIL across common/* and javascript/* engineering standards (1 opt-out DS-0026)",
    style=Styles.PrimaryNeutral,
)
kpis.add(
    "93.5%",
    "Browser Line Coverage",
    "1,849 / 1,854 headless Chromium tests passing (--network=none); 92.3% branch coverage (6,267/6,706 stmts)",
    style=Styles.SecondaryNeutral,
    metric_style=Styles.SecondaryBold.patch(text_size=16.0),
    accent_style=Styles.SecondaryFlat,
)
kpis.add(
    "0 Deps / 8",
    "Runtime Deps & Findings",
    "0 production npm dependencies (0 runtime CVEs, 0 secrets); 8 total findings (3 MEDIUM, 5 LOW)",
    style=Styles.WarningNeutral,
    metric_style=Styles.WarningBold.patch(text_size=15.0),
    accent_style=Styles.WarningFlat,
)
kpis.draw((9, 9), width=128, height=36, columns=2)

save()
```

## Audit Metadata & Scope Summary

| Attribute | Value |
| :--- | :--- |
| **Target Repository** | `htmx` (`v4.0.1`, upstream tag `8d112c71`) |
| **Primary Language & Runtime** | JavaScript (`ES2022` classes & `#` private fields) + TypeScript Declarations (`src/htmx.d.ts`) |
| **Runtime Profiles** | Browser Hypermedia Library (`dist/htmx.js`, `dist/htmx.esm.js`, `dist/htmax.js`) & Node CLI (`src/scripts/upgrade-check.js`) |
| **Workflow & Run ID** | `pni501` (`wf-e3385881`) — Evaluated `2026-11-10T12:15:56+00:00` |
| **Overall Score & Grade** | **91 / 100 (`Grade S`)** |
| **Codebase Footprint** | `18` source files (`5,521` non-blank LOC: `src/htmx.js` at `1,989` LOC + `17` extensions in `src/ext/*.js`) |
| **Hermetic Browser Verification** | `1,854` real-browser tests via `@web/test-runner` + Playwright Chromium (`1,849` passed, `1` timing race, `4` skipped) |
| **Measured V8 Coverage** | **93.5%** line coverage (`6,267 / 6,706` statements) and **92.3%** branch coverage |
| **Companion Portals** | [User Guide](https://htmx.drawlib.com/user_guide/) • [API Reference Catalog](https://htmx.drawlib.com/api/) • [Internal Architecture Guide](https://htmx.drawlib.com/architecture/) |
