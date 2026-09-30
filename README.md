# Anywidget.jl

[![CI](https://github.com/AnywidgetInstruments/Anywidget.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AnywidgetInstruments/Anywidget.jl/actions/workflows/CI.yml)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://anywidgetinstruments.github.io/Anywidget.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Host [anywidget](https://anywidget.dev) front-end modules (AFM) from Julia.
Bind an ES module to a trait dictionary and show it as standalone HTML
(Documenter, VS Code, Jupyter, Pluto, any page) or in a
[Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl) notebook through
SlateAFM, with custom messages and binary buffers. No Python, no Node.js.

> **Unofficial.** Anywidget.jl is a community-maintained Julia host for
> [anywidget](https://anywidget.dev) front-end modules; it is not affiliated
> with the anywidget project.

> **Status: pre-alpha (0.0.1, phase 0).** See the
> [specification](docs/src/specification.md) and the
> [roadmap](docs/src/roadmap.md).

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/AnywidgetInstruments/Anywidget.jl")
```

## Quick start

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

w = anywidget(counter; count = 0)      # displays as HTML
html_page("counter.html", w)
```

Anywidgets published on PyPI load without Python: the wheel and the class
source are read as data.

```julia
knob = pypi_anywidget("wigglystuff"; class = "Knob", value = 30.0)
```

Widget packages subtype `AbstractAnywidget`, as
[AnywidgetInstruments.jl](https://github.com/AnywidgetInstruments/AnywidgetInstruments.jl)
does, and get every host for free.

## Development

```bash
just test          # unit tests (TestItemRunner)
just test-slate    # Kaimon Slate extension tests (Julia >= 1.12)
just docs          # documentation, llms.txt and llms-full.txt
```

## License

BSD 3-Clause, see [LICENSE.md](LICENSE.md).
