# Writing a widget package

A package shipping its own widgets subtypes [`AbstractAnywidget`](@ref) and
implements three functions. It then gets the HTML display,
[`html_page`](@ref), [`send_message`](@ref) and the Kaimon Slate integration.

```julia
using Anywidget

const MODULE = AFMModule("mywidgets"; dir = joinpath(@__DIR__, "..", "assets"),
                         esm = "index.js", css = ["index.css"])

struct Gauge <: AbstractAnywidget
    id::String
    traits::Dict{String,Any}
end
Gauge(value; id = Anywidget.new_id()) = Gauge(id, Dict{String,Any}("value" => value))

Anywidget.afm_module(::Gauge) = MODULE
Anywidget.widget_traits(g::Gauge) = g.traits
Anywidget.message_id(g::Gauge) = g.id
```

[AnywidgetInstruments.jl](https://github.com/s-celles/AnywidgetInstruments.jl)
works this way: it ships the front end of anywidget-instruments and one
constructor per widget class, with traits checked against its contract.
