# htmx v4.0.1 User Guide (`docs_src/`)

This directory contains the Drawlib source files for **Portal 1: htmx v4.0.1 User Guide**, a bilingual (English and Japanese) multi-page documentation website (`type = "site"`) covering hypermedia-driven application (HDA) architecture, core attributes, request triggers, DOM morphing, status routing, official extensions, history management, and security/testing best practices for `htmx@4.0.1`.

## Directory Structure

```text
docs_src/
├── drawlib.toml          # Multi-locale site configuration (en, ja) & SEO metadata
├── styles.py             # Shared GoogleColors / GoogleStyles theme configuration
├── utils.py              # Reusable Drawlib helper utilities
├── style.css             # Site stylesheet
├── template.html         # HTML page template
├── build.sh              # Full build script
├── build_html.sh         # HTML site build script (preserves subportals)
├── serve.sh              # Local preview server script
├── en/                   # English documentation source
│   ├── navbar.md
│   ├── index.md
│   ├── 01_getting_started.md
│   ├── 02_hypermedia_architecture.md
│   ├── 03_requests_and_triggers.md
│   ├── 04_targeting_and_swapping.md
│   ├── 05_headers_events_and_status.md
│   ├── 06_extensions_and_streaming.md
│   ├── 07_history_caching_and_ux.md
│   └── 08_security_testing_and_debugging.md
└── ja/                   # Japanese documentation source (100% structural parity)
    ├── navbar.md
    ├── index.md
    ├── 01_getting_started.md
    ├── 02_hypermedia_architecture.md
    ├── 03_requests_and_triggers.md
    ├── 04_targeting_and_swapping.md
    ├── 05_headers_events_and_status.md
    ├── 06_extensions_and_streaming.md
    ├── 07_history_caching_and_ux.md
    └── 08_security_testing_and_debugging.md
```

## Building and Verifying Locally

To compile the HTML site into a scratch directory for verification:

```bash
UV_DEFAULT_INDEX=https://pypi.org/simple uvx drawlib@0.3.9 build html docs_src/ -o .drawlib/scratch/ug_html_out/
```

To inspect an individual embedded diagram with the coordinate grid:

```bash
UV_DEFAULT_INDEX=https://pypi.org/simple uvx drawlib@0.3.9 show docs_src/en/index.md htmx4_hero_overview.png \
    -s docs_src/styles.py -u docs_src/utils.py \
    -g -o .drawlib/scratch/ug_preview_grid.png
```

To build the production `docs/` output while preserving companion subportals (`api/`, `architecture/`, `reports/`):

```bash
./docs_src/build_html.sh
```
