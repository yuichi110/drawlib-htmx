# htmx v4.0.1 API Reference Catalog (`api_src/`)

> **Portal 2 of the Unofficial htmx v4 Multi-Portal Suite (`type = "catalog"`)**
>
> Live Site: **[https://htmx.drawlib.com/api/](https://htmx.drawlib.com/api/)** (English & 日本語)

This directory contains the bilingual source files for **Portal 2: htmx v4.0.1 API Reference Catalog**, built with **[Drawlib](https://www.drawlib.com/)** (`type = "catalog"`). It documents every HTML attribute, modifier, HCON expression syntax, HTTP header, JavaScript method, TypeScript interface, `htmx.config` property, `HtmxEventMap` lifecycle event, official extension (`src/ext/*.js`), `htmax.js` bundle, and the `upgrade-check` CLI tool in htmx `v4.0.1`.

---

## Directory Structure

```text
api_src/
├── drawlib.toml                                # Catalog project manifest (type = "catalog", en & ja)
├── styles.py                                   # Shared GoogleStyles / GoogleColors design tokens
├── utils.py                                    # Reusable Drawlib helper functions
├── style.css                                   # Responsive 2-column catalog stylesheet with semantic badges
├── template.html                               # Jinja2 catalog layout with sidebar filter & scroll-spy
├── _assets/                                    # Logos, favicon, and OpenGraph social card
├── build.sh                                    # Master build script (compiles to docs/api/)
├── build_html.sh                               # Static HTML builder (uvx drawlib@0.3.9 build html)
├── serve.sh                                    # Local preview server + link/anchor checker
├── en/                                         # English catalog pages (00..12)
│   ├── 00_overview.md                          # API Surface Overview, Package Exports, HCON & Prefixes
│   ├── 01_core_request_attributes.md           # hx-get, hx-post, hx-put, hx-patch, hx-delete, hx-query, hx-action, hx-method
│   ├── 02_trigger_and_sync_attributes.md       # hx-trigger (modifiers, filters, polling, observers), hx-sync, hx-confirm
│   ├── 03_target_and_swap_attributes.md        # hx-target, hx-swap (12 styles + 12 modifiers), hx-swap-oob, <hx-partial>, morphing
│   ├── 04_data_and_config_attributes.md        # hx-vals, hx-headers, hx-include, hx-encoding, hx-validate, hx-config, hx-status:XXX
│   ├── 05_ux_history_and_control_attributes.md # hx-boost, hx-push-url, hx-replace-url, hx-indicator, hx-disable, hx-ignore, hx-on:*, :inherited, :append
│   ├── 06_http_headers.md                      # 7 Request Headers & 9 Response Headers
│   ├── 07_javascript_api.md                    # 13 htmx.* JS methods & 5 TypeScript context/options interfaces
│   ├── 08_configuration_options.md             # <meta name="htmx-config">, 23 HtmxConfig options & 5 CSS state classes
│   ├── 09_events_reference.md                  # 28 HtmxEventMap DOM events & 5 extension-only hooks
│   ├── 10_extensions_streaming_and_net.md      # hx-sse, hx-ws, hx-multipart, hx-preload, hx-ptag, hx-download
│   ├── 11_extensions_reactive_and_dom.md       # hx-live & htmx.live, hx-targets, hx-upsert, hx-head, hx-pending, hx-browser-indicator
│   └── 12_extensions_security_compat_and_cli.md# hx-csp, hx-history-cache, hx-prompt, hx-alpine-compat, htmx-2-compat, internalAPI, upgrade-check
└── ja/                                         # Japanese catalog pages (100% file, section & symbol parity)
    └── 00_overview.md .. 12_extensions_security_compat_and_cli.md
```

---

## Building & Verifying Locally

From the repository root (`drawlib-htmx/`):

```bash
# Build the bilingual HTML catalog into docs/api/
./api_src/build_html.sh

# Or build to an isolated scratch output directory for verification
UV_DEFAULT_INDEX=https://pypi.org/simple uvx drawlib@0.3.9 build html api_src/ -o .drawlib/scratch/cat_html_out/

# Verify zero broken links or missing anchors
UV_DEFAULT_INDEX=https://pypi.org/simple uvx drawlib@0.3.9 serve .drawlib/scratch/cat_html_out/ --check

# Preview locally
./api_src/serve.sh
```

---

## Related Portals

- **Portal 1 — htmx v4 User Guide (`user_guide_src/`)**: [https://htmx.drawlib.com/user_guide/](https://htmx.drawlib.com/user_guide/)
- **Portal 2 — htmx v4 API Reference Catalog (`api_src/`)**: [https://htmx.drawlib.com/api/](https://htmx.drawlib.com/api/)
- **Portal 3 — htmx v4 Internal Architecture Guide (`architecture_src/`)**: [https://htmx.drawlib.com/architecture/](https://htmx.drawlib.com/architecture/)
- **Portal 4 — PNI501 Engineering & Architecture Diagnostic Report (`pni501_src/`)**: [https://htmx.drawlib.com/pni501/](https://htmx.drawlib.com/pni501/)
