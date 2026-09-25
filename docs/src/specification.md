# Specification

Requirements of Anywidget.jl, written with the
[Easy Approach to Requirements Syntax](https://alistairmavin.com/ears/) (EARS)
and prioritized with MoSCoW: **M**ust, **S**hould, **C**ould, **W**on't (this
time).

Anywidget.jl hosts [anywidget](https://anywidget.dev) front-end modules (AFM)
from Julia: ES modules exporting `{ initialize?, render }` that drive a
host-provided `model` (`get`, `set`, `save_changes`, `on`, `off`, `send`)
([AFM specification](https://anywidget.dev/en/afm/)).

| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-09-25 | First version (phase 0, package 0.0.1) |
| 0.2 | 2026-09-25 | `AFMModule` renamed `FrontendModule` (AW-MOD-006); unofficial status stated (AW-GEN-004) |

## 1. General

| ID | P | Requirement |
|---|---|---|
| AW-GEN-001 | M | The package shall run on the current Julia release (1.13) and on the LTS release (1.10). |
| AW-GEN-002 | M | The core package shall depend only on JSON.jl and on standard libraries; integrations with notebook hosts shall be package extensions. |
| AW-GEN-003 | M | The package shall not require Python, pip, Node.js or network access, except to load a module given by URL. |
| AW-GEN-004 | M | The documentation shall state that the package is an unofficial, community-maintained Julia host, not affiliated with the anywidget project. |

## 2. Modules

| ID | P | Requirement |
|---|---|---|
| AW-MOD-001 | M | The package shall describe a front-end module (`FrontendModule`) by a name, its ES module and its stylesheets. |
| AW-MOD-002 | M | The package shall accept the ES module as a file of a local directory, as an absolute URL (`http://`, `https://`), or as inline source text. |
| AW-MOD-003 | M | When a module file given in a directory does not exist, the package shall throw an `ArgumentError` naming the file. |
| AW-MOD-004 | M | When a module name contains other characters than letters, digits, `.`, `_` and `-`, the package shall throw an `ArgumentError`. |
| AW-MOD-005 | S | The package shall let the base URL a module's files are served from be set (`set_asset_base!(mod, url)`), for pages that should not inline them. |
| AW-MOD-006 | M | The type of a front-end module shall be named `FrontendModule` (not `AFMModule`, which repeats "module"). |

## 3. Widgets

| ID | P | Requirement |
|---|---|---|
| AW-WID-001 | M | The package shall define the interface of a widget (`AbstractAnywidget`): its module (`afm_module`), its trait dictionary (`widget_traits`) and its message id (`message_id`). |
| AW-WID-002 | M | The package shall provide a generic widget (`Anywidget(mod; id, traits...)`) whose traits are read and written like a dictionary. |
| AW-WID-003 | M | The package shall store the traits of the generic widget in JSON form: string keys, symbols as strings, tuples and vectors as arrays, named tuples as dictionaries. |
| AW-WID-004 | S | The package shall give each widget a unique message id unless one is given. |

## 4. Messages

| ID | P | Requirement |
|---|---|---|
| AW-MSG-001 | M | The package shall represent a custom message as its JSON content and its list of binary buffers (`Message`). |
| AW-MSG-002 | M | The package shall encode a numeric array as the bytes of a buffer of a numpy-style `dtype` (`<f4`, `<f8`, `u1`, `uint8`, …), little-endian whatever the host byte order (`encode_buffer`). |
| AW-MSG-003 | M | The package shall send messages to the views of a widget through a replaceable transport (`send_message`, `set_transport!`). |
| AW-MSG-004 | M | When no transport is installed, `send_message` shall throw an error telling how to install one. |

## 5. Standalone HTML

| ID | P | Requirement |
|---|---|---|
| AW-HTML-001 | M | The package shall render every `AbstractAnywidget` as HTML (`MIME"text/html"`) that loads its module and runs `initialize` and `render` with a model held in the page. |
| AW-HTML-002 | M | The HTML shall embed the traits as JSON inside a `<script type="application/json">` element, escaped so that no trait value can close the element. |
| AW-HTML-003 | M | By default, the HTML shall be self-contained: local and inline modules and their styles are inlined, and imported once per page and module. |
| AW-HTML-004 | M | Where a module is given by URL, or its asset base URL is set, the HTML shall load it by URL instead of inlining it. |
| AW-HTML-005 | S | The package shall render several widgets in one standalone page (`html_page`), each module included once. |
| AW-HTML-006 | M | The model held in the page shall implement `get`, `set`, `save_changes`, `on` and `off` for `change:<trait>` events, and `send` as a no-op. |
| AW-HTML-007 | W | The standalone HTML won't send operator actions back to Julia: it has no kernel. |

## 6. Kaimon Slate

| ID | P | Requirement |
|---|---|---|
| AW-SLATE-001 | M | When SlateExtensionsBase is loaded, the package shall convert every `AbstractAnywidget` to a `Widget` of the `SlateAFM.AFM` kind whose bound value is its trait dictionary and whose parameters are the module URL, the stylesheet URLs and the message id. |
| AW-SLATE-002 | M | When SlateExtensionsBase is loaded, the package shall serve the local and inline modules of the widgets it converts, under `/ext-assets/Anywidget.<module name>/`. |
| AW-SLATE-003 | S | When SlateAFM is loaded, the package shall install a transport sending messages with `SlateAFM.afm_emit`, unless another transport is installed. |
| AW-SLATE-004 | W | The package won't register its own Slate widget kind: rendering relies on the host shim of SlateAFM. |

## 7. Quality

| ID | P | Requirement |
|---|---|---|
| AW-QA-001 | M | Every requirement marked M shall be covered by a test item (TestItemRunner.jl). |
| AW-QA-002 | M | The package shall pass Aqua.jl checks. |
| AW-QA-003 | M | The documentation shall build without warnings and publish `llms.txt` and `llms-full.txt`. |

## Out of scope for now

- Bidirectional hosts (Bonito.jl, Pluto.jl, IJulia comms): next phase.
- Loading published anywidgets from PyPI (as SlateAFM's `pypi_afm` does).
