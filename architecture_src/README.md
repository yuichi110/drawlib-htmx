# htmx v4.0.1 Internal Architecture Guide (`architecture_src/`)

This directory contains the bilingual (**English** `en/` and **Japanese** `ja/`) Drawlib `site` source for **Portal 3: htmx v4.0.1 Internal Architecture Guide**.

Every chapter is grounded directly in the htmx `v4.0.1` source tree (`src/htmx.js`, `src/ext/*.js`, and `package.json`) with exact line numbers, method signatures, and embedded declarative Python (`drawlib`) architectural diagrams.

---

## Directory Structure

```text
architecture_src/
├── drawlib.toml                              # Bilingual site config (en, ja) & SEO metadata
├── styles.py                                 # GoogleStyles / GoogleColors design tokens
├── utils.py                                  # Shared Drawlib helper functions
├── style.css                                 # Responsive multi-page documentation theme
├── template.html                             # Jinja2 HTML layout template
├── build.sh / build_html.sh                  # Build scripts (-> docs/architecture/)
├── serve.sh                                  # Local preview & link checker script
├── en/                                       # English source pages
│   ├── navbar.md                             # Persistent sidebar navigation
│   ├── index.md                              # Executive Architecture Overview
│   ├── 01_module_and_state_architecture.md   # Htmx Class, # Lowering, _htmx State, XPath
│   ├── 02_attribute_inheritance_and_hcon.md  # HCON Parser & Explicit :inherited Resolution
│   ├── 03_trigger_and_selector_parsers.md    # Trigger Lexer, Modifiers & Extended Selectors
│   ├── 04_fetch_context_and_sync_queue.md    # Request Context, RequestQueue & fetch() Pipeline
│   ├── 05_swap_settle_and_morph_engine.md    # Multi-Task Swap, Built-in Idiomorph & Transitions
│   └── 06_extension_and_security_internals.md # #internalAPI, hx-csp, hx-live, hx-multipart, SSE/WS
└── ja/                                       # Japanese source pages (100% structural parity)
    ├── navbar.md
    ├── index.md
    ├── 01_module_and_state_architecture.md
    ├── 02_attribute_inheritance_and_hcon.md
    ├── 03_trigger_and_selector_parsers.md
    ├── 04_fetch_context_and_sync_queue.md
    ├── 05_swap_settle_and_morph_engine.md
    └── 06_extension_and_security_internals.md
```

---

## Building the Site

To compile the bilingual HTML site to `docs/architecture/`:

```bash
./architecture_src/build.sh
```

Or run `drawlib` directly to a custom output directory:

```bash
UV_DEFAULT_INDEX=https://pypi.org/simple uvx drawlib@0.3.9 build html architecture_src/ -o docs/architecture/
```

To preview a single embedded diagram with its coordinate grid during development:

```bash
UV_DEFAULT_INDEX=https://pypi.org/simple uvx drawlib@0.3.9 show \
    architecture_src/en/index.md arch_overview_hero.png \
    -s architecture_src/styles.py -u architecture_src/utils.py \
    -g -o .drawlib/scratch/arch_preview_grid.png
```
