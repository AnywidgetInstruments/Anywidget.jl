# Getting started

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/s-celles/Anywidget.jl")
```

Julia 1.10 (LTS) and later; the Kaimon Slate integration needs Julia 1.12.

## Modules

An [`FrontendModule`](@ref) names an ES module and its stylesheets. The module is a
file of a local directory, an absolute URL, or inline source text:

```julia
using Anywidget
local_mod = FrontendModule("counter"; dir = "path/to/widget", esm = "counter.js", css = ["counter.css"])
cdn_mod = FrontendModule("confetti"; esm = "https://esm.sh/some-anywidget@1")
inline_mod = FrontendModule("hello"; source = "export default { render({ el }) { el.textContent = 'hello'; } };")
```

## Widgets

[`anywidget`](@ref) binds a module to traits, stored in JSON form (string
keys, symbols as strings, tuples as arrays). A widget reads and writes like a
dictionary:

```@example start
using Anywidget
counter = FrontendModule("counter"; dir = joinpath(@__DIR__, "assets"), esm = "counter.js", css = ["counter.css"])
w = anywidget(counter; count = 3, label = :Clicks)
w[:count] = 4
widget_traits(w)
```

Its HTML display runs the module in the page. Click the button: the model
lives in the page.

```@example start
w
```

## Messages

A [`Message`](@ref) is a JSON content and binary buffers, received by the
front end with `model.on("msg:custom", (content, buffers) => …)`.
[`encode_buffer`](@ref) writes little-endian buffers of a numpy-style dtype:

```@example start
msg = Message(Dict("type" => "samples", "n" => 3), [encode_buffer("<f4", [0.1, 0.2, 0.3])])
length.(msg.buffers)
```

[`send_message`](@ref) hands it to the transport of the host (see
[Hosts](hosts.md)).
