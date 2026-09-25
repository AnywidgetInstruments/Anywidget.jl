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
| 0.3 | 2026-09-25 | "Out of scope" becomes "Planned", with the phases |
| 0.4 | 2026-09-25 | Published anywidgets from PyPI without Python (section 7, AW-PYPI-*) |

## 1. General

| ID | P | Requirement |
|---|---|---|
| AW-GEN-001 | M | The package shall run on the current Julia release (1.13) and on the LTS release (1.10). |
| AW-GEN-002 | M | The core package shall depend only on JSON.jl and on standard libraries (including p7zip_jll); integrations with notebook hosts shall be package extensions. |
| AW-GEN-003 | M | The package shall not require Python, pip, Node.js or network access, except to load a module given by URL or a PyPI project. |
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

## 7. Published anywidgets (PyPI, without Python)

An anywidget published on PyPI is a Python class whose front end is a static
file of its wheel (a zip archive) or a string in its source. The package reads
the wheel and the source as data: Python is never run.

| ID | P | Requirement |
|---|---|---|
| AW-PYPI-001 | M | The package shall find the wheel of a PyPI project (latest version or a given one) through the PyPI JSON API, preferring a pure-Python wheel (`py3-none-any`). |
| AW-PYPI-002 | M | The package shall download the wheel, check its SHA-256 against the digest published by the index, and throw an error when they differ. |
| AW-PYPI-003 | M | The package shall extract the wheel into a cache directory keyed by project, version and digest, and reuse it on later calls. |
| AW-PYPI-004 | M | The package shall find the anywidget classes of the project by reading its Python source: classes deriving from `anywidget.AnyWidget` (or `AnyWidget`). |
| AW-PYPI-005 | M | The package shall read the `_esm` and `_css` of a class given as a string literal (plain, raw or triple-quoted), or as a path built from `pathlib.Path(__file__).parent` and string segments, directly or through a module-level variable. |
| AW-PYPI-006 | M | The package shall read the defaults of the synced traits of a class declared with a literal first argument (`traitlets.Int(0).tag(sync=True)`, `Unicode("x")`, `Bool(True)`, `List([1, 2])`, …); traits whose default cannot be read statically are left to the user. |
| AW-PYPI-007 | M | When the project has several anywidget classes and none is chosen, or the chosen class is not found, the package shall throw an `ArgumentError` listing the classes. |
| AW-PYPI-008 | M | When the front end of a class cannot be resolved statically, the package shall throw an error telling to give the module file with `esm`. |
| AW-PYPI-009 | M | The package shall build a `FrontendModule` of the class (`pypi_module`) and a widget whose traits are the read defaults overridden by the given traits (`pypi_anywidget`). |
| AW-PYPI-010 | S | The package shall let the index URL and the cache directory be set (`index`, `cache` keywords; `ANYWIDGET_PYPI_INDEX`, `ANYWIDGET_CACHE`). |
| AW-PYPI-011 | W | The package won't run Python or install the project's Python dependencies. |
| AW-PYPI-012 | M | The package shall follow inheritance between the classes of the project: a class deriving from an anywidget class is one, and inherits the `_esm`, `_css` and trait defaults it does not redefine; without `class`, the only class having a front end is chosen. |

## 8. Quality

| ID | P | Requirement |
|---|---|---|
| AW-QA-001 | M | Every requirement marked M shall be covered by a test item (TestItemRunner.jl). |
| AW-QA-002 | M | The package shall pass Aqua.jl checks. |
| AW-QA-003 | M | The documentation shall build without warnings and publish `llms.txt` and `llms-full.txt`. |

## Planned

Not yet specified as requirements; see the [roadmap](roadmap.md) for the phases.

- Bidirectional hosts (Pluto.jl, Bonito.jl, IJulia comms): phase 1.
- Published anywidgets from npm by name (esm.sh / jsDelivr URLs already work).
