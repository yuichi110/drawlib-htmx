# Core Request Attributes

The core request attributes declare that an HTML element issues an asynchronous HTTP request when triggered. In htmx v4.0.1, you can declare requests using either the six verb-specific attributes (`hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, `hx-query`) or the unified `hx-action` + `hx-method` pair.

| Symbol | HTTP Verb | Parameter Encoding | Enclosing `<form>` Auto-Inclusion | Inheritance |
| :--- | :--- | :--- | :--- | :--- |
| [`hx-get`](#hx-get) | `GET` | URL Query String (`?k=v`) | Only if element is `<form>` (or via `hx-include`) | Non-inherited |
| [`hx-post`](#hx-post) | `POST` | Request Body (`URLSearchParams` / `FormData`) | Yes (`elt.form \|\| elt.closest('form')`) | Non-inherited |
| [`hx-put`](#hx-put) | `PUT` | Request Body (`URLSearchParams` / `FormData`) | Yes (`elt.form \|\| elt.closest('form')`) | Non-inherited |
| [`hx-patch`](#hx-patch) | `PATCH` | Request Body (`URLSearchParams` / `FormData`) | Yes (`elt.form \|\| elt.closest('form')`) | Non-inherited |
| [`hx-delete`](#hx-delete) | `DELETE` | URL Query String (`?k=v`) | Only if element is `<form>` (or via `hx-include`) | Non-inherited |
| [`hx-query`](#hx-query) | `QUERY` | Request Body (`URLSearchParams` / `FormData`) | Yes (`elt.form \|\| elt.closest('form')`) | Non-inherited |
| [`hx-action`](#hx-action) | Determined by `hx-method` | Matches resolved verb (`GET`/`DELETE` vs body) | Matches resolved verb | Non-inherited |
| [`hx-method`](#hx-method) | Any HTTP method string | Pairs with `hx-action` | Matches resolved verb | Inherited by default |

```drawlib align=center code=fold file=cat_01_core_request_verbs.png caption="Figure 1: HTTP Method Resolution and Payload Encoding Pipeline in htmx v4.0.1"
from drawlib.canvas import save, setup
from drawlib.lines import line
from drawlib.shapes import rectangle
from drawlib.smartarts import Panel
from drawlib.styles import Styles
from drawlib.text import text

setup(width=180, height=84, dpi=150)

text((90, 78.5), "HTTP Method Resolution & Payload Encoding Pipeline", style=Styles.DarkBold.patch(text_size=13.0))

# Column 1: Attribute Resolution
p1 = Panel(
    "1. Attribute Resolution",
    style=Styles.PrimaryNeutral,
    header_style=Styles.PrimaryFlat,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
p1.draw((5, 6), width=52, height=66, align="bottom_left")

rectangle((31, 54), width=46, height=16, style=Styles.PrimaryFlat.patch(shape_r=1.8), text="Verb Shorthand Attributes\nhx-get | hx-post | hx-put\nhx-patch | hx-delete | hx-query", text_style=Styles.WhiteBold.patch(text_size=10.0))
rectangle((31, 34), width=46, height=16, style=Styles.SecondaryNeutral.patch(shape_r=1.8), text="Unified Action Pair\nhx-action=\"/url\" (local)\n+ hx-method=\"POST\" (inherited)", text_style=Styles.DarkBold.patch(text_size=10.0))
rectangle((31, 15), width=46, height=15, style=Styles.White.patch(shape_r=1.8), text="Boosted HTML Fallbacks\n<a href> -> GET\n<form action method>", text_style=Styles.Dark.patch(text_size=10.0))

# Column 2: Parameter Collection
p2 = Panel(
    "2. Parameter Collection",
    style=Styles.SecondaryNeutral,
    header_style=Styles.SecondaryBold,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
p2.draw((64, 6), width=52, height=66, align="bottom_left")

rectangle((90, 50), width=46, height=22, style=Styles.White.patch(shape_r=1.8), text="Query-Param Verbs\nGET & DELETE\n• Element value + hx-vals\n• Parent <form> NOT included", text_style=Styles.Dark.patch(text_size=10.0))
rectangle((90, 21), width=46, height=24, style=Styles.AccentFlat.patch(shape_r=1.8), text="Body-Payload Verbs\nPOST, PUT, PATCH, QUERY\n• Auto-includes parent <form>\n• Merged with hx-vals/include", text_style=Styles.WhiteBold.patch(text_size=10.0))

# Column 3: Fetch / Inline Dispatch
p3 = Panel(
    "3. Fetch / Inline Dispatch",
    style=Styles.Neutral,
    header_style=Styles.DarkBold,
    text_style=Styles.WhiteBold.patch(text_size=10.5),
    header_height=7.5,
)
p3.draw((123, 6), width=52, height=66, align="bottom_left")

rectangle((149, 54), width=46, height=16, style=Styles.White.patch(shape_r=1.8), text="URL Query Dispatch\nAppends ?key=val to URL\nfetch(url, { body: null })", text_style=Styles.Dark.patch(text_size=10.0))
rectangle((149, 34), width=46, height=16, style=Styles.PrimaryNeutral.patch(shape_r=1.8), text="Body Payload Dispatch\nURLSearchParams (default)\nor FormData (multipart)", text_style=Styles.DarkBold.patch(text_size=10.0))
rectangle((149, 15), width=46, height=15, style=Styles.SecondaryNeutral.patch(shape_r=1.8), text="js: / javascript: Action\nEvaluates inline JS with params\n(No network request)", text_style=Styles.Dark.patch(text_size=10.0))

# Connectors
line((57, 45), (64, 45), arrow_head="->", style=Styles.DarkBold)
line((57, 25), (64, 25), arrow_head="->", style=Styles.DarkBold)
line((116, 50), (123, 50), arrow_head="->", style=Styles.DarkBold)
line((116, 28), (123, 28), arrow_head="->", style=Styles.DarkBold)

save()
```

---

## Read & Safe Query Verbs

Attributes in this section issue idempotent read or query operations. Note how `hx-get` encodes parameters into the URL query string while `hx-query` sends a structured request body.

### `hx-get`

Issues an HTTP `GET` request to the specified URL and swaps the returned HTML into the target DOM node.

**Syntax**

```html
<element hx-get="<url> | js:<expression>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **HTTP Method** | `GET` |
| **Parameter Encoding** | Appended to the request URL query string (`URLSearchParams`). `ctx.request.body` is set to `null`. |
| **Form Inclusion** | Does **not** automatically serialize an enclosing `<form>` unless `hx-get` is placed directly on the `<form>` element itself or `hx-include="closest form"` is specified. |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |
| **Special Prefixes** | `js:<expr>` or `javascript:<expr>` evaluates inline JavaScript instead of calling `fetch()` and swaps the returned string into the target. |

**Usage Examples**

```html
<!-- Basic GET request swapping into a target container -->
<button hx-get="/api/users/42" hx-target="#user-profile">
  Load Profile
</button>
<div id="user-profile"></div>

<!-- Live search input (explicitly includes enclosing form filters if needed) -->
<form id="filter-form">
  <select name="role">
    <option value="all">All Roles</option>
    <option value="admin">Admin</option>
  </select>
  <input type="search"
         name="q"
         hx-get="/api/users/search"
         hx-include="closest form"
         hx-trigger="input changed delay:300ms"
         hx-target="#search-results">
</form>
<div id="search-results"></div>
```

---

### `hx-query`

Issues an HTTP `QUERY` request (IETF HTTP QUERY method) to the specified URL. Unlike `hx-get`, `hx-query` transmits parameters in the HTTP request body rather than the URL query string, making it ideal for complex filter payloads or sensitive search criteria that should not appear in server access logs or browser URL bars.

**Syntax**

```html
<element hx-query="<url>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **HTTP Method** | `QUERY` |
| **Parameter Encoding** | Sent in the HTTP request body (`application/x-www-form-urlencoded` via `URLSearchParams` by default, or `FormData` when `hx-encoding="multipart/form-data"`). |
| **Form Inclusion** | Automatically includes all inputs from an enclosing `<form>` (`elt.form \|\| elt.closest('form')`). |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |

**Usage Examples**

```html
<!-- Complex structured query sent in request body rather than URL -->
<form hx-query="/api/reports/aggregate" hx-target="#report-table">
  <input type="date" name="start_date" value="2026-01-01">
  <input type="date" name="end_date" value="2026-12-31">
  <textarea name="filter_dsl">status == "active" AND region IN ("us", "jp")</textarea>
  <button type="submit">Run Query</button>
</form>
<div id="report-table"></div>
```

---

## State-Mutating Verbs

State-mutating verb attributes modify server resources. In htmx v4.0.1, `POST`, `PUT`, and `PATCH` automatically collect inputs from their enclosing `<form>` and encode them in the request body, whereas `DELETE` encodes parameters into the URL query string.

### `hx-post`

Issues an HTTP `POST` request to the specified URL to create a resource or trigger a server-side action.

**Syntax**

```html
<element hx-post="<url> | js:<expression>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **HTTP Method** | `POST` |
| **Parameter Encoding** | Sent in `ctx.request.body` (`URLSearchParams` by default; `FormData` if `hx-encoding="multipart/form-data"` or enclosing `<form enctype="multipart/form-data">`). |
| **Form Inclusion** | Automatically serializes the enclosing `<form>` (`elt.form \|\| elt.closest('form')`) plus the triggering submitter button's `name=value`. |
| **Validation** | Runs `form.reportValidity()` prior to request dispatch when triggered on a `<form>` (unless `novalidate` is present) or when `hx-validate="true"`. |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |

**Usage Examples**

```html
<!-- Standard form creation with append swap -->
<form hx-post="/api/todos" hx-target="#todo-list" hx-swap="append">
  <input type="text" name="title" placeholder="New task..." required>
  <button type="submit">Add Task</button>
</form>
<ul id="todo-list"></ul>
```

---

### `hx-put`

Issues an HTTP `PUT` request to the specified URL to replace an existing server resource.

**Syntax**

```html
<element hx-put="<url>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **HTTP Method** | `PUT` |
| **Parameter Encoding** | Sent in `ctx.request.body` (`URLSearchParams` or `FormData`). |
| **Form Inclusion** | Automatically serializes the enclosing `<form>` (`elt.form \|\| elt.closest('form')`). |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |

**Usage Examples**

```html
<!-- Full resource replacement with outerMorph to preserve focus -->
<form hx-put="/api/settings/notifications" hx-target="this" hx-swap="outerMorph">
  <label>
    <input type="checkbox" name="email_alerts" value="true" checked>
    Email Alerts
  </label>
  <label>
    <input type="checkbox" name="sms_alerts" value="true">
    SMS Alerts
  </label>
  <button type="submit">Save Preferences</button>
</form>
```

---

### `hx-patch`

Issues an HTTP `PATCH` request to the specified URL to apply a partial update to an existing server resource.

**Syntax**

```html
<element hx-patch="<url>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **HTTP Method** | `PATCH` |
| **Parameter Encoding** | Sent in `ctx.request.body` (`URLSearchParams` or `FormData`). |
| **Form Inclusion** | Automatically serializes the enclosing `<form>` (`elt.form \|\| elt.closest('form')`). |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |

**Usage Examples**

```html
<!-- Inline field update triggered on change -->
<input type="text"
       name="display_name"
       value="Ada Lovelace"
       hx-patch="/api/users/42/name"
       hx-trigger="change"
       hx-target="#save-status">
<span id="save-status"></span>
```

---

### `hx-delete`

Issues an HTTP `DELETE` request to the specified URL to remove a server resource.

**Syntax**

```html
<element hx-delete="<url>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **HTTP Method** | `DELETE` |
| **Parameter Encoding** | Appended to the request URL query string (`usesQueryParams = /GET\|DELETE/.test(method)`). `ctx.request.body` is set to `null`. |
| **Form Inclusion** | Does **not** automatically serialize an enclosing `<form>` unless `hx-delete` is placed directly on the `<form>` or `hx-include` is used. Use `hx-vals` to pass additional query parameters if needed. |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |

**Usage Examples**

```html
<!-- Delete a row and remove the closest <tr> on 200 OK -->
<tr id="row-108">
  <td>Invoice #108</td>
  <td>
    <button hx-delete="/api/invoices/108"
            hx-confirm="Permanently delete Invoice #108?"
            hx-target="closest tr"
            hx-swap="delete">
      Delete
    </button>
  </td>
</tr>
```

---

## Unified Action & Method Attributes

In addition to the verb-specific shorthand attributes (`hx-get`, `hx-post`, etc.), htmx v4.0.1 introduces `hx-action` and `hx-method` so you can separate the target endpoint URL from the HTTP verb—or inherit a shared HTTP method across a group of action buttons.

### `hx-action`

Specifies the request endpoint URL independently of the HTTP method. When `hx-action` is present on an element, htmx resolves the HTTP method from `hx-method` (which can be inherited from an ancestor), falling back to `submitter.formmethod`, `elt.getAttribute('method')`, or `'GET'`.

**Syntax**

```html
<element hx-action="<url> | js:<expression>" [hx-method="<VERB>"]></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **Resolution Precedence** | Evaluated **before** `hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, and `hx-query` in `__determineMethodAndAction()`. |
| **Default Method** | Uses `hx-method` if present (on the element or inherited), else `evt.submitter?.formmethod`, else `elt.getAttribute('method')`, else `'GET'`. |
| **Inheritance** | Non-inherited (`allowInheritance = false`). |
| **Inline JS Execution** | If `hx-action` starts with `js:` or `javascript:`, htmx evaluates the JavaScript expression with `Object.fromEntries(ctx.request.body)` in scope and swaps the returned string without making a network request. |

**Usage Examples**

```html
<!-- Toolbar sharing an inherited POST method across multiple hx-action buttons -->
<div hx-method="POST" hx-target="#Selection-status">
  <button hx-action="/api/items/archive">Archive Selected</button>
  <button hx-action="/api/items/publish">Publish Selected</button>
  <button hx-action="/api/items/purge" hx-method="DELETE">Purge Selected</button>
</div>
<div id="Selection-status"></div>

<!-- Client-side computed fragment swap using js: prefix -->
<button hx-action="js:`<strong>Timestamp: ${new Date().toISOString()}</strong>`"
        hx-target="#clock-out">
  Stamp Local Time
</button>
<div id="clock-out"></div>
```

---

### `hx-method`

Specifies the HTTP method (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `QUERY`, or any custom HTTP verb) to use when paired with `hx-action`. Unlike `hx-action` and the shorthand verb attributes, `hx-method` **is inherited by default**, allowing a parent container or `<form>` to define the default HTTP verb for descendant `[hx-action]` elements.

**Syntax**

```html
<element hx-method="GET | POST | PUT | PATCH | DELETE | QUERY | <CUSTOM>"></element>
```

| Aspect | Specification in htmx v4.0.1 |
| :--- | :--- |
| **Case Normalization** | Automatically converted to uppercase (`method.toUpperCase()`). |
| **Dialog Bypass** | If the resolved method is `'DIALOG'` (e.g., `<form method="dialog">`), htmx aborts network processing so native HTML `<dialog>` closing works seamlessly. |
| **Inheritance** | **Inherited by default** (`__getAttributeValue(elt, 'hx-method')` searches up the DOM tree). Can be blocked on a subtree using `:inherited` rules or overridden locally. |

**Usage Examples**

```html
<!-- Form using hx-action + hx-method instead of hx-post -->
<form hx-action="/api/projects" hx-method="POST" hx-target="#project-list" hx-swap="prepend">
  <input type="text" name="name" required>
  <button type="submit">Create Project</button>
</form>
<div id="project-list"></div>
```
