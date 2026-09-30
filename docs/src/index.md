```@raw html
---
layout: home

hero:
  name: Anywidget.jl
  text: anywidget front-end modules, hosted from Julia
  tagline: Bind an anywidget ES module to a trait dictionary and show it as standalone HTML or in a Kaimon Slate notebook. No Python, no Node.js.
  actions:
    - theme: brand
      text: Getting started
      link: /getting-started/
    - theme: alt
      text: Hosts
      link: /hosts/
    - theme: alt
      text: View on GitHub
      link: https://github.com/AnywidgetInstruments/Anywidget.jl

features:
  - icon: 🧩
    title: Any AFM module
    details: A local file, a URL (esm.sh, jsDelivr) or inline source text, with its stylesheets.
    link: /getting-started/
  - icon: 🌐
    title: Standalone HTML
    details: Widgets display in Documenter, VS Code, Jupyter, Pluto or a page written with html_page.
    link: /hosts/#Standalone-HTML
  - icon: 📓
    title: Kaimon Slate
    details: "@bind w anywidget(mod; ...) through SlateAFM, with messages and binary buffers from Julia."
    link: /hosts/#Kaimon-Slate
  - icon: 🐍
    title: PyPI anywidgets, no Python
    details: pypi_anywidget("drawdata"; class = "ScatterWidget") reads the wheel and the class source as data.
    link: /pypi/
  - icon: 📦
    title: A base for widget packages
    details: Subtype AbstractAnywidget and get every host for free, as AnywidgetInstruments.jl does.
    link: /packages/
---
```

!!! note "Unofficial"
    Anywidget.jl is a community-maintained Julia host for
    [anywidget](https://anywidget.dev) front-end modules; it is not affiliated
    with the anywidget project.

Anywidget.jl hosts [anywidget](https://anywidget.dev) front-end modules (AFM)
from Julia. An AFM is an ES module exporting `{ initialize?, render }` that
drives a model provided by the host (`get`, `set`, `save_changes`, `on`, `off`,
`send`). This package binds such a module to a trait dictionary and hosts it.

```julia
using Anywidget

counter = FrontendModule("counter"; source = """
export default {
  render({ model, el }) {
    const b = document.createElement("button");
    const show = () => (b.textContent = `count: ${model.get("count")}`);
    b.onclick = () => { model.set("count", model.get("count") + 1); model.save_changes(); };
    model.on("change:count", show);
    show();
    el.appendChild(b);
  },
};
""")

anywidget(counter; count = 0)
```
