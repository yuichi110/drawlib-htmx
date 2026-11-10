# htmx v4 User Guide, API Reference, Architecture & PNI501 Audit (`drawlib-htmx`)

> **Unofficial Multi-Portal Documentation & Diagnostic Suite — Built with [Drawlib](https://www.drawlib.com/) & [PNI501](https://pypi.org/project/pni501/)**
>
> This repository hosts an **independent, unofficial** four-portal documentation, API catalog, internal architecture guide, and software diagnostic site covering **[htmx](https://htmx.org/)** (`v4.0.1`, tag `8d112c71`, experimental v4 series: [https://four.htmx.org/](https://four.htmx.org/)).
> For official htmx documentation, essays, release notes, and issue tracking, always visit **[https://htmx.org/](https://htmx.org/)**, **[https://four.htmx.org/](https://four.htmx.org/)**, and **[https://github.com/bigskysoftware/htmx](https://github.com/bigskysoftware/htmx)**.

---

## Live Portals (`https://htmx.drawlib.com/`)

1. **htmx v4 User Guide (`docs_src/` -> `docs/`)**: [https://htmx.drawlib.com/](https://htmx.drawlib.com/) (English & 日本語)
   - Practical user guide covering Hypermedia-Driven Application (HDA) design, core request attributes (`hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, `hx-query`), explicit attribute inheritance (`:inherited` and `:append` modifiers), extended CSS selectors (`closest`, `find`, `next`, `previous`), built-in DOM morphing (`innerMorph`, `outerMorph`, `outerSync`), declarative status routing (`hx-status:422`, `hx-status:5xx`), multi-region partial updates (`<hx-partial>` and `hx-swap-oob`), HCON configuration syntax, colon-separated lifecycle events (`htmx:config:request`, `htmx:after:swap`), streaming extensions (`hx-sse`, `hx-ws`, `hx-multipart`), reactive DOM scripting (`hx-live`), and strict CSP security boundaries (`hx-ignore`, `hx-csp`).
2. **htmx v4 API Reference Catalog (`api_src/` -> `docs/api/`)**: [https://htmx.drawlib.com/api/](https://htmx.drawlib.com/api/) (English & 日本語)
   - Searchable symbol & attribute catalog (`type = "catalog"`) covering every HTML attribute, modifier (`:inherited`, `:append`), HCON expression syntax, HTTP request & response header (`HX-Request`, `HX-Source`, `HX-Target`, `HX-Request-Type`, `HX-Trigger`, `HX-Retarget`, `HX-Reswap`, `HX-Location`), JavaScript API method (`htmx.ajax()`, `htmx.process()`, `htmx.swap()`, `htmx.registerExtension()`), `htmx.config` property, `HtmxEventMap` event payload, all 17 official extensions (`src/ext/*.js`), `htmax.js` bundle, and the `upgrade-check` CLI tool in htmx `v4.0.1`.
3. **htmx v4 Internal Architecture Guide (`architecture_src/` -> `docs/architecture/`)**: [https://htmx.drawlib.com/architecture/](https://htmx.drawlib.com/architecture/) (English & 日本語)
   - Source-level walkthrough of how htmx `v4.0.1` (`src/htmx.js` and `src/ext/*.js`) works internally: single-class `Htmx` IIFE/ESM architecture and `__` $\rightarrow$ `#` private field build lowering, `elt._htmx` state binding & `XPathEvaluator` `hx-on:*` discovery, `HCON` recursive config parser & explicit `:inherited` attribute resolution, `parseTriggerSpecs` lexer & `RequestQueue` (`hx-sync`) admission state machine, `fetch()` request pipeline & `<hx-partial>` / `hx-swap-oob` task extraction, built-in Idiomorph-style `morph()` DOM tree reconciliation & View Transitions queue, and the `#internalAPI` extension hook dispatcher.
4. **PNI501 Engineering & Architecture Diagnostic Report (`reports_src/pni501_src/` -> `docs/reports/pni501/`)**: [https://htmx.drawlib.com/reports/pni501/](https://htmx.drawlib.com/reports/pni501/) ([PDF](https://htmx.drawlib.com/reports/pni501/pni501.pdf))
   - Deterministic 15-stage JavaScript AST, module dependency DAG, zero-dependency library hygiene, hermetic Node 22 + Playwright Chromium `@web/test-runner` + V8 coverage container runtime, and supply-chain diagnostic audit.

---

## Repository Layout

```text
drawlib-htmx/
├── src/                      # Upstream htmx v4.0.1 source (src/htmx.js, src/htmx.d.ts, src/ext/*.js, src/scripts/, src/skills/)
├── dist/                     # Upstream htmx v4.0.1 compiled IIFE, ESM, htmax, and extension bundles
├── test/                     # Upstream htmx v4.0.1 @web/test-runner + Playwright browser test suite
├── scripts/                  # Upstream htmx v4.0.1 helper scripts
├── editors/                  # Upstream editor metadata (JetBrains web-types, VS Code custom data)
├── package.json              # Upstream htmx v4.0.1 package manifest (BSD-0-Clause, unmodified)
├── package-lock.json         # Upstream deterministic npm lockfile (unmodified)
├── CHANGELOG.md              # Upstream changelog (unmodified)
├── LICENSE-HTMX              # Upstream Zero-Clause BSD License (Big Sky Software)
├── LICENSE                   # Apache-2.0 License for original documentation, diagrams & audit assets
├── .pni/                     # PNI501 workflow & JavaScript audit configuration
├── docs_src/                 # Portal 1: htmx v4 User Guide source (bilingual en/ja, type = "site")
├── api_src/                  # Portal 2: htmx v4 API Reference source (bilingual en/ja, type = "catalog")
├── architecture_src/         # Portal 3: htmx v4 Internal Architecture Guide source (bilingual en/ja, type = "site")
├── reports_src/
│   └── pni501_src/           # Portal 4: PNI501 diagnostic report source (type = "doc")
└── docs/                     # Unified compiled GitHub Pages output (CNAME: htmx.drawlib.com)
    ├── index.html            # User Guide root
    ├── api/                  # API Reference Catalog
    ├── architecture/         # Internal Architecture Guide
    └── reports/
        └── pni501/           # PNI501 HTML & PDF report
```

---

## Installation & Quickstart (htmx v4)

Include `htmx.min.js` via `<script>` tag or install `htmx.org` via `npm`:

```bash
npm install htmx.org@4.0.1
```

Or load directly in HTML and issue declarative `fetch()` requests that swap server-rendered HTML fragments into the DOM:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="htmx-config" content="defaultSwap:innerHTML, transitions:true">
  <script src="/dist/htmx.min.js"></script>
</head>
<body>
  <!-- Explicit attribute inheritance in htmx 4 via :inherited -->
  <main hx-target:inherited="#results" hx-indicator:inherited="#spinner">
    <input type="search" name="q"
           hx-get="/contacts/search"
           hx-trigger="input changed delay:300ms, keyup[key=='Enter']"
           placeholder="Search contacts...">
    <span id="spinner" class="htmx-indicator">Loading...</span>

    <form hx-post="/contacts"
          hx-status:422="target:#form-errors swap:innerHTML">
      <input type="email" name="email" required>
      <div id="form-errors"></div>
      <button type="submit">Add Contact</button>
    </form>

    <section id="results"></section>
  </main>
</body>
</html>
```

---

## Reproducing Locally with `uvx`

`src/`, `dist/`, `test/`, `package.json`, and `package-lock.json` remain unmodified from upstream htmx `v4.0.1`; `drawlib` and `pni501` run ephemerally via `uvx` without polluting the JavaScript repository with Python virtual environments:

```bash
# Build all 4 portals (User Guide + API Catalog + Internal Architecture + PNI501 HTML/PDF) & check links
./build.sh

# Or build each portal individually:
./docs_src/build_html.sh
./api_src/build_html.sh
./architecture_src/build_html.sh
uvx --default-index https://pypi.org/simple --from pni501@0.1.3 pni report build pni501 \
  --src-dir reports_src \
  --html-output-dir docs/reports/pni501 \
  --output-dir docs/reports/pni501 \
  -f html -f pdf

# Preview locally & verify zero broken links
uvx --default-index https://pypi.org/simple drawlib@0.3.9 serve docs/ --check
uvx --default-index https://pypi.org/simple drawlib@0.3.9 serve docs/
```

---

## Testing, Contributing & Security

- **Automated Browser Test Suite**: Run `npm ci && npm test` (`@web/test-runner --browsers chromium --config test/web-test-runner.config.mjs --playwright`) to execute unit, attribute, end-to-end, and extension tests in headless Chromium with V8 coverage over [`src/htmx.js`](./src/htmx.js).
- **Upgrade Checker CLI**: Run `npx htmx.org@4.0.1 upgrade-check -- ./path/to/project` (or `node dist/scripts/upgrade-check.js`) to scan templates for htmx 2 $\rightarrow$ htmx 4 migration items.
- **Security Considerations**: Always sanitize untrusted user content on the server before returning HTML fragments, mark untrusted user-generated DOM containers with `hx-ignore`, and pair strict Content Security Policies with [`src/ext/hx-csp.js`](./src/ext/hx-csp.js) and `htmx.config.inlineScriptNonce`.

---

## Licensing & Attribution Notice

- **Upstream htmx Snapshot (`src/`, `dist/`, `test/`, `scripts/`, `editors/`, `dev/`, `package.json`, `package-lock.json`, `CHANGELOG.md`)**:
  Distributed by Big Sky Software under the **Zero-Clause BSD (`0BSD`) License** — see [`LICENSE-HTMX`](./LICENSE-HTMX).
- **Original Documentation, API Catalog, Diagrams & PNI501 Audit (`docs_src/`, `api_src/`, `architecture_src/`, `reports_src/`, `docs/`, `.pni/`, build scripts)**:
  Copyright (c) 2026 Yuichi Ito. Distributed under the **Apache License, Version 2.0** — see [`LICENSE`](./LICENSE).
- **Attribution**:
  htmx is created and maintained by Carson Gross and Big Sky Software. This repository is an independent community documentation and architecture study built with [Drawlib](https://www.drawlib.com/) and [PNI501](https://pypi.org/project/pni501/) and is not affiliated with, sponsored by, or endorsed by Carson Gross or Big Sky Software.