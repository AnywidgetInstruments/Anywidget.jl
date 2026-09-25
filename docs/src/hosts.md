# Hosts

## Standalone HTML

Every [`AbstractAnywidget`](@ref) has a `text/html` representation: the module
runs in the page with a model holding the traits (`get`, `set`,
`save_changes`, `on`, `off`; `send` does nothing). It displays wherever HTML is
shown: Documenter, VS Code, Jupyter with IJulia, Pluto. There is no kernel:
what the user does stays in the page.

- Local and inline modules are **inlined** (base64) and imported once per page
  and module: outputs are self-contained.
- Modules given by URL are imported from that URL.
- [`set_asset_base!`](@ref) serves a local module from a URL instead, for
  example where a documentation build copied its files.

[`html_page`](@ref) writes several widgets into one page, each module included
once:

```julia
html_page("page.html", anywidget(counter; count = 1), anywidget(counter; count = 2))
```

## Kaimon Slate

[Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl) is a reactive
Julia notebook; its SlateAFM extension hosts AFM modules. With
SlateExtensionsBase loaded (Julia 1.12 or later, tested on 1.13), Anywidget.jl plugs into it
through a package extension:

- `@bind w anywidget(mod; count = 0)` binds `w` to the trait dictionary,
  rendered by SlateAFM's host shim (kind `SlateAFM.AFM`);
- local and inline modules are served under `/ext-assets/Anywidget.<name>/`;
- [`send_message`](@ref) goes through `SlateAFM.afm_emit`.

SlateAFM lives in the KaimonSlate.jl repository:

```julia
using Pkg
Pkg.add(url = "https://github.com/kahliburke/KaimonSlate.jl", subdir = "examples/extensions/SlateAFM")
Pkg.add(url = "https://github.com/s-celles/Anywidget.jl")
```

In the notebook:

```julia
using SlateAFM, Anywidget
@bind w anywidget(counter; count = 0, id = "counter")
send_message("counter", Message(Dict("type" => "reset")))
```

Messages sent by the front end (`model.send`) arrive through SlateAFM:
`SlateAFM.afm_on_msg("counter") do content, buffers … end`.

## Other hosts

A host installs its own transport with [`set_transport!`](@ref):

```julia
set_transport!((id, msg) -> my_send(id, msg.content, msg.buffers))
```
