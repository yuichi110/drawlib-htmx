#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"

echo "=== [1/5] Building htmx v4 User Guide (user_guide_src/ -> docs/user_guide/) ==="
./user_guide_src/build.sh

echo "=== [2/5] Building htmx v4 API Reference Catalog (api_src/ -> docs/api/) ==="
./api_src/build.sh

echo "=== [3/5] Building htmx v4 Internal Architecture Guide (architecture_src/ -> docs/architecture/) ==="
./architecture_src/build.sh

echo "=== [4/5] Building PNI501 Diagnostic Report (pni501_src/ -> docs/pni501/) ==="
./pni501_src/build.sh

echo "htmx.drawlib.com" > docs/CNAME
touch docs/.nojekyll

echo "=== [5/5] Regenerating Unified Root Sitemap (docs/sitemap.xml) ==="
python3 - <<'PY'
import re
from pathlib import Path

base_url = "https://htmx.drawlib.com"
docs_dir = Path("docs")
urls = [f"{base_url}/", f"{base_url}/index.html"]

for portal in ["user_guide", "api", "architecture", "pni501"]:
    portal_sitemap = docs_dir / portal / "sitemap.xml"
    if portal_sitemap.exists():
        content = portal_sitemap.read_text(encoding="utf-8")
        for loc in re.findall(r"<loc>(.*?)</loc>", content):
            if loc not in urls:
                urls.append(loc)
    for html_file in sorted((docs_dir / portal).rglob("*.html")):
        rel = html_file.relative_to(docs_dir).as_posix()
        full_url = f"{base_url}/{rel}"
        if full_url not in urls:
            urls.append(full_url)

lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
]
for u in urls:
    lines.append("  <url>")
    lines.append(f"    <loc>{u}</loc>")
    lines.append("  </url>")
lines.append("</urlset>")
(docs_dir / "sitemap.xml").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {len(urls)} URLs to docs/sitemap.xml")
PY

echo "All 4 portals and docs/sitemap.xml built successfully!"
