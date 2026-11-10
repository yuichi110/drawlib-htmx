ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-bookworm-slim

ENV CI=true \
    NODE_ENV=test \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 10001 --create-home --shell /bin/bash pni \
    && mkdir -p /workspace /out /ms-playwright /tmp/cov \
    && chown -R pni:pni /workspace /out /ms-playwright /tmp/cov \
    && chmod 0777 /out /tmp/cov

WORKDIR /workspace

COPY --chown=pni:pni . /workspace

# Install npm dependencies, Playwright Chromium + system deps, and cache chai@4.5.0 locally for --network=none execution
RUN npm ci --ignore-scripts \
    && npx playwright install --with-deps chromium \
    && curl -fsSL https://unpkg.com/chai@4.5.0/chai.js -o /workspace/test/lib/chai.js \
    && cat << 'EOF' > /workspace/pni-wtr.config.mjs
import fs from 'node:fs';
import { summaryReporter, defaultReporter } from '@web/test-runner';

function collectTests(suite, prefix = '', acc = []) {
  if (!suite) return acc;
  const suiteName = prefix ? (suite.name ? `${prefix} > ${suite.name}` : prefix) : (suite.name || 'htmx');
  for (const t of suite.tests || []) {
    acc.push({ classname: suiteName, name: t.name || 'test', passed: !!t.passed, skipped: !!t.skipped, error: t.error });
  }
  for (const s of suite.suites || []) {
    collectTests(s, suiteName, acc);
  }
  return acc;
}

function junitFileReporter(outPath) {
  return {
    stop({ sessions }) {
      const cases = [];
      for (const session of sessions || []) {
        if (session.testResults) {
          collectTests(session.testResults, session.id || 'suite', cases);
        }
      }
      const total = cases.length;
      const skipped = cases.filter(c => c.skipped).length;
      const failed = cases.filter(c => !c.passed && !c.skipped).length;
      const esc = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<testsuites tests="${total}" failures="${failed}" errors="0" skipped="${skipped}">\n  <testsuite name="htmx-wtr" tests="${total}" failures="${failed}" errors="0" skipped="${skipped}">\n`;
      for (const c of cases) {
        xml += `    <testcase classname="${esc(c.classname)}" name="${esc(c.name)}">`;
        if (c.skipped) {
          xml += `<skipped/>`;
        } else if (!c.passed) {
          const msg = c.error?.message || 'Test failed';
          xml += `<failure message="${esc(msg)}">${esc(c.error?.stack || msg)}</failure>`;
        }
        xml += `</testcase>\n`;
      }
      xml += `  </testsuite>\n</testsuites>\n`;
      try { fs.writeFileSync(outPath, xml, 'utf8'); } catch {}
    }
  };
}

export default {
  testRunnerHtml: (testFramework) => `
  <html lang="en">
<head>
    <meta charset="utf-8" />
    <title>htmx Tests</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="htmx-config" content='{"logAll":false}'>
</head>
<body>
<h2>Htmx Test Suite</h2>
<script src="test/lib/chai.js"></script>
<script src="test/lib/fetch-mock.js"></script>
<script src="src/htmx.js"></script>
<script class="mocha-init">
    window.should = window.chai.should()
    window.assert = window.chai.assert
</script>
<script src="test/lib/helpers.js"></script>
<script type="module" src="${testFramework}"></script>
<div id="test-playground"></div>
</body>
</html>`,
  nodeResolve: true,
  coverage: true,
  coverageConfig: {
    include: ['src/htmx.js', 'src/ext/*.js'],
    reportDir: '/tmp/cov',
    reporters: ['json-summary', 'lcov']
  },
  files: ['test/tests/**/*.js'],
  reporters: [
    summaryReporter({ flatten: false, reportTestLogs: false, reportTestErrors: true }),
    defaultReporter({ reportTestProgress: true, reportTestResults: true }),
    junitFileReporter('/out/junit.xml')
  ]
};
EOF

RUN chown -R pni:pni /workspace /ms-playwright \
    && chmod -R a+rX /workspace /ms-playwright

USER pni
CMD ["node", "--version"]
