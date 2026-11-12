# 2. Hypermedia Architecture

Designing a clean **Hypermedia-Driven Application (HDA)** in htmx v4.0.1 centers on three architectural mechanisms: **explicit attribute inheritance** (`:inherited` and `:append`), **partial vs. full request negotiation** (`HX-Request-Type`), and **multi-region page updates** (`<hx-partial>`, `hx-swap-oob`, and `HX-Trigger`).

```drawlib align=center code=fold file=ch02_inheritance_and_request_type.png caption="Explicit Attribute Inheritance (:inherited / :append) and Server Partial/Full Negotiation"
from drawlib import canvas
from drawlib.diagrams.flow import Data, Decision, End, FlowDiagram, Process, Start
from drawlib.styles import Styles

canvas.clear()
canvas.setup(width=164, height=88)

flow = FlowDiagram(
    node_style=Styles.Neutral.patch(text_size=9.5),
    edge_style=Styles.DarkBold,
    edge_text_style=Styles.DarkBold.patch(text_size=9.5),
    title="HDA Request Resolution & Server Rendering Pipeline",
    width=154,
    height=78,
    lane_orientation="vertical",
)

# 3 Vertical Swimlanes: 52 + 50 + 52 = 154 (Centers at X = 26, 77, 128)
flow.add_lane("DOM Inheritance Scope", width=52, style=Styles.Neutral, header_style=Styles.PrimaryNeutral)
flow.add_lane("htmx Fetch Dispatcher", width=50, style=Styles.Neutral, header_style=Styles.SecondaryNeutral)
flow.add_lane("Hypermedia Server", width=52, style=Styles.Neutral, header_style=Styles.PrimaryNeutral)

parent = flow.add(
    Start("Parent Container\nhx-target:inherited", width=38, height=13, style=Styles.PrimaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)),
    xy=(26, 60),
)
child = flow.add(
    Process("Child Trigger\nhx-include:inherited:append", width=42, height=13, style=Styles.PrimaryNeutral.patch(text_size=9.5)),
    xy=(26, 38),
)
isolated = flow.add(
    Data("Unmarked Parent\n(No Leakage to Child)", width=38, height=12, style=Styles.Neutral.patch(text_size=9.5)),
    xy=(26, 15),
)

headers = flow.add(
    Process("Attach HX-Request &\nHX-Request-Type", width=38, height=13, style=Styles.SecondaryNeutral.patch(text_size=9.5)),
    xy=(77, 58),
)
check_type = flow.add(
    Decision("HX-Request-Type\n== 'partial'?", width=38, height=20, style=Styles.PrimaryNeutral.patch(text_size=9.5)),
    xy=(128, 44),
)
partial_resp = flow.add(
    End("Return Fragment +\n<hx-partial> Tags", width=38, height=13, style=Styles.PrimaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)),
    xy=(77, 16),
)
full_resp = flow.add(
    End("Return Full HTML\nLayout + Shell", width=38, height=13, style=Styles.SecondaryFlat.patch(text_size=9.5), text_style=Styles.WhiteBold.patch(text_size=9.5)),
    xy=(128, 16),
)

parent.connect(child, label=":inherited", padding=1.0)
child.connect(headers, start_side="right", end_side="left", padding=1.0)
headers.connect(check_type, label="HTTP Request", start_side="right", end_side="top", padding=1.0)
check_type.connect(partial_resp, label="Yes (partial)", start_side="left", end_side="top", padding=1.0)
check_type.connect(full_resp, label="No (full)", start_side="bottom", end_side="top", padding=1.0)

flow.draw(xy=(5.0, 5.0))
canvas.save()
```

---

## 2.1 Designing Hypermedia-Driven Applications (HDA)

In a Hypermedia-Driven Application, the browser does not maintain a parallel domain model in JavaScript memory. Instead, **HTML is the engine of application state (HATEOAS)**:

- **State Lives on the Server**: Authentication, permissions, pagination cursors, and business validation rules execute in your backend language (Python, Go, Rust, Ruby, Java, TypeScript, PHP).
- **Hypermedia Controls Encode Next Actions**: Returned HTML fragments carry their own `hx-post`, `hx-delete`, `hx-target`, and `hx-status:XXX` attributes representing valid state transitions.
- **Scoped Component Boundaries**: By combining explicit `:inherited` attributes on section containers with relative selectors (`closest tr`, `find .status`), templates remain modular and free of brittle global IDs.

---

## 2.2 Explicit Attribute Inheritance (`:inherited` & `:append`)

In htmx 2, nearly every attribute (`hx-target`, `hx-swap`, `hx-confirm`, `hx-boost`, `hx-include`) cascaded implicitly to all descendant elements. In complex layouts—such as modals or nested cards—parent attributes often leaked into child components unexpectedly.

**In htmx v4.0.1, attribute inheritance is explicit by default.** A parent attribute only applies to descendant elements when you attach the **`:inherited`** modifier:

```html
<!-- Parent container explicitly shares hx-target, hx-swap, and hx-headers with descendants -->
<div hx-target:inherited="#workspace-panel"
     hx-swap:inherited="innerMorph"
     hx-headers:inherited='X-Workspace-Id: "ws-900"'>

  <!-- Both buttons inherit target="#workspace-panel", swap="innerMorph", and the header -->
  <button hx-get="/workspace/overview">Overview</button>
  <button hx-get="/workspace/metrics">Metrics</button>

  <!-- A nested widget can override hx-target locally without affecting siblings -->
  <button hx-post="/workspace/ping" hx-target="this" hx-swap="textContent">
    Ping Server
  </button>
</div>
```

### Appending to Inherited Attributes (`:inherited:append`)

For cumulative attributes—such as `hx-include`, `hx-vals`, and `hx-headers`—you can extend an ancestor's inherited value rather than overwriting it by chaining **`:inherited:append`** (or `:append` on the child):

```html
<!-- Ancestor provides the CSRF token selector -->
<section hx-include:inherited="[name='csrf_token']">

  <!-- Sub-container appends a filter form selector while keeping csrf_token -->
  <div hx-include:inherited:append="#active-filters">
    <button hx-post="/reports/export" hx-include:inherited:append="[name='format']">
      Export CSV
    </button>
  </div>
</section>
```

| Inheritance Mechanism | Syntax Example | Behavior in htmx v4.0.1 |
| :--- | :--- | :--- |
| **Local Only (Default)** | `<div hx-target="#out">` | Applies **only** to the `<div>` itself; children do not inherit `#out`. |
| **Explicit Inheritance** | `<div hx-target:inherited="#out">` | Applies to the `<div>` and cascades to all descendants without their own `hx-target`. |
| **Append Inheritance** | `<div hx-vals:inherited:append="role:admin">` | Merges/appends values onto any ancestor `hx-vals:inherited` definition. |
| **Custom Meta-Character** | `<meta name="htmx-config" content="metaCharacter:@">` | Allows writing `hx-target@inherited` when server templates reserve `:`. |
| **Global Implicit Fallback** | `htmx.config.implicitInheritance = true` | Restores htmx 2 automatic inheritance across all containers (for legacy migration). |

---

## 2.3 Partial vs. Full Page Requests (`HX-Request` & `HX-Request-Type`)

A hallmark of resilient HDA design is supporting both **in-page partial updates** and **direct browser navigation / full-page refreshes** from the same URL route. htmx v4.0.1 sends two complementary headers on every request:

1. **`HX-Request: true`**: Always sent on every htmx-initiated `fetch()` call.
2. **`HX-Request-Type: "partial" | "full"`**: New in htmx 4! Indicates whether htmx expects a targeted HTML fragment or a full document:
   - **`"partial"`**: Sent when `hx-target` points to a specific element (not `body`) and `hx-select` is not extracting from a full page.
   - **`"full"`**: Sent when targeting `document.body` (e.g., via `hx-boost:inherited="true"`), restoring history, or when `hx-select` is used to slice a fragment out of a full page response.

```python
# Example Server Controller (Python / FastAPI / Flask style)
def list_projects(request):
    projects = db.query_projects(filter=request.GET.get("q"))

    # When htmx requests a targeted partial update, render only the table fragment
    if request.headers.get("HX-Request-Type") == "partial":
        return render_template("partials/project_rows.html", projects=projects)

    # For direct browser visits, boosted body navigations, or history restores:
    return render_template("pages/projects_full.html", projects=projects)
```

---

## 2.4 Updating Multiple Page Regions

Real-world interfaces frequently need a single user action—such as adding an item to a cart or archiving a ticket—to update **multiple independent regions** of the page (e.g., the main table, a sidebar counter badge, and a toast notification area). htmx v4.0.1 provides four structured patterns for multi-region updates:

```drawlib align=center code=fold file=ch02_multi_region_strategies.png caption="Four Architectural Patterns for Updating Multiple Page Regions in htmx v4.0.1"
from drawlib.canvas import save, setup
from drawlib.icons import phosphor
from drawlib.smartarts import CardList, GridLayout
from drawlib.styles import Styles

setup(width=172, height=78)

grid = GridLayout(
    num_column=2,
    num_row=2,
    style=Styles.Neutral.patch(shape_r=2.0),
    text_style=Styles.DarkBold.patch(text_size=11.0),
)

# Top-Left (row=1, col=0): Pattern 1 - <hx-partial> (Preferred in v4)
grid.add(
    position=(0, 1),
    width=1,
    height=1,
    text="1. <hx-partial> Elements (v4 Preferred)\nExplicit hx-target & hx-swap per fragment\nCleanest multi-region server response",
    style=Styles.PrimaryFlat.patch(shape_r=2.0),
    text_style=Styles.WhiteBold.patch(text_size=10.5),
)

# Top-Right (row=1, col=1): Pattern 2 - Expand the Target
grid.add(
    position=(1, 1),
    width=1,
    height=1,
    text="2. Expand the Target Container\nWrap adjacent regions in a shared parent\nCombine with innerMorph to preserve state",
    style=Styles.PrimaryNeutral.patch(shape_r=2.0),
)

# Bottom-Left (row=0, col=0): Pattern 3 - Out-of-Band (hx-swap-oob)
grid.add(
    position=(0, 0),
    width=1,
    height=1,
    text="3. Out-of-Band Swaps (hx-swap-oob)\nPiggyback ID-matched elements on response\nRuns AFTER the main swap in htmx v4",
    style=Styles.SecondaryNeutral.patch(shape_r=2.0),
)

# Bottom-Right (row=0, col=1): Pattern 4 - HX-Trigger Events
grid.add(
    position=(1, 0),
    width=1,
    height=1,
    text="4. Event-Driven Refresh (HX-Trigger)\nServer emits HX-Trigger: cartUpdated\nDecoupled components fetch own state",
    style=Styles.Neutral.patch(shape_r=2.0),
)

grid.draw(
    xy=(8.0, 8.0),
    width=156.0,
    height=62.0,
    margin=3.5,
    outer_style=Styles.MutedDashed.patch(shape_r=2.5),
)
save()
```

### Pattern 1: `<hx-partial>` Tags (Recommended in htmx 4)

New in htmx 4, `<hx-partial>` lets the server response package multiple self-contained updates, each declaring its own `hx-target` and `hx-swap` strategy:

```html
<!-- Server Response using <hx-partial> -->
<hx-partial hx-target="#todo-list" hx-swap="beforeend">
  <li id="todo-108">Deploy htmx v4.0.1 to production</li>
</hx-partial>

<hx-partial hx-target="#pending-count" hx-swap="textContent">
  4 items left
</hx-partial>

<hx-partial hx-target="#toast-container" hx-swap="afterbegin">
  <div class="toast success">Task created!</div>
</hx-partial>
```

> [!IMPORTANT]
> When a server response contains `<hx-partial>` elements and no remaining main content, htmx v4.0.1 automatically skips the empty main swap so your primary target is never accidentally blanked out. If you intentionally want an empty main response to clear the primary target alongside partials, add the `swapEmpty:true` modifier to `hx-swap`.

### Pattern 2: Expand the Target Container (Paired with `innerMorph`)

When two regions live close together in the DOM, wrap them in a shared container and use `hx-swap="innerMorph"` so focus and input state remain untouched:

```html
<div id="checkout-panel">
  <ul id="cart-items">...</ul>
  <div id="order-summary">Total: $49.00</div>
  <button hx-post="/cart/apply-coupon"
          hx-target="#checkout-panel"
          hx-swap="innerMorph">
    Apply Coupon
  </button>
</div>
```

### Pattern 3: Out-of-Band Swaps (`hx-swap-oob`)

Any top-level element in the server response carrying `hx-swap-oob="true"` (or `hx-swap-oob="<swap-style>:<css-selector>"`) is extracted and swapped into the matching DOM target **after** the main content swap completes:

```html
<!-- Main response swapped into primary hx-target -->
<tr id="row-12"><td>Updated Item</td><td>$25.00</td></tr>

<!-- Out-of-band element swapped into #cart-total after the main swap -->
<span id="cart-total" hx-swap-oob="true">$125.00</span>

<!-- Out-of-band append into #audit-log -->
<tbody hx-swap-oob="beforeend:#audit-log">
  <tr><td>Item 12 updated at 12:00 UTC</td></tr>
</tbody>
```

### Pattern 4: Server-Sent `HX-Trigger` Events

When a mutation affects loosely coupled widgets (such as charts or independent dashboard panels), have the server emit an `HX-Trigger` response header and let interested elements listen for that event on `body`:

```http
HTTP/1.1 200 OK
Content-Type: text/html
HX-Trigger: {"invoicePaid": {"invoiceId": 942}, "refreshMetrics": true}
```

```html
<!-- Independent dashboard widget refreshes itself whenever refreshMetrics fires on body -->
<div id="revenue-summary"
     hx-get="/dashboard/revenue-summary"
     hx-trigger="refreshMetrics from:body"
     hx-swap="innerMorph">
  Loading metrics...
</div>
```
