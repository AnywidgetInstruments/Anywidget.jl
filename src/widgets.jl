# Widgets: a module bound to a trait dictionary (AW-WID-*).

"""
    AbstractAnywidget

A widget hosted by Anywidget.jl. A subtype implements

- [`afm_module`](@ref)`(w)`: its [`FrontendModule`](@ref);
- [`widget_traits`](@ref)`(w)`: its trait dictionary, in JSON form;
- [`message_id`](@ref)`(w)`: the id of its message channel.

It then gets the HTML display, [`html_page`](@ref), [`send_message`](@ref) and
the Kaimon Slate integration.
"""
abstract type AbstractAnywidget end

"""
    afm_module(w::AbstractAnywidget) -> FrontendModule

The front-end module of a widget.
"""
function afm_module end

"""
    widget_traits(w::AbstractAnywidget) -> Dict{String,Any}

The trait dictionary the front end is bound to, in JSON form.
"""
function widget_traits end

"""
    message_id(w::AbstractAnywidget) -> String

The id of the widget's message channel, used by hosts to route messages.
"""
function message_id end

"""
    Anywidget.Widget(mod::FrontendModule; id = <unique>, traits...)

The generic widget: a module and a trait dictionary, read and written like a
dictionary (`w[:count]`, `w[:count] = 2`). Traits are stored in JSON form:
string keys, symbols as strings, tuples as arrays, named tuples as
dictionaries. Not exported; [`anywidget`](@ref) builds one.
"""
struct Widget <: AbstractAnywidget
    mod::FrontendModule
    id::String
    traits::Dict{String,Any}
end

function Widget(mod::FrontendModule; id::AbstractString=new_id(), traits...)
    return Widget(mod, String(id), Dict{String,Any}(String(k) => jsonify(v) for (k, v) in traits))
end

"""
    anywidget(mod::FrontendModule; id = <unique>, traits...) -> Anywidget.Widget

A generic widget of module `mod` with the given traits.
"""
anywidget(mod::FrontendModule; kw...) = Widget(mod; kw...)

"""
    new_id() -> String

A unique message id.
"""
new_id() = "afm-" * string(uuid4())

afm_module(w::Widget) = w.mod
widget_traits(w::Widget) = w.traits
message_id(w::Widget) = w.id

Base.getindex(w::Widget, k::Union{AbstractString,Symbol}) = w.traits[String(k)]
Base.setindex!(w::Widget, v, k::Union{AbstractString,Symbol}) = (w.traits[String(k)]=jsonify(v); v)
Base.haskey(w::Widget, k::Union{AbstractString,Symbol}) = haskey(w.traits, String(k))
Base.get(w::Widget, k::Union{AbstractString,Symbol}, default) = get(w.traits, String(k), default)
Base.keys(w::Widget) = keys(w.traits)

"""
    jsonify(x)

Plain JSON form of a value: dictionaries with string keys, arrays for tuples
and vectors, strings for symbols; other values are returned unchanged.
"""
jsonify(x::AbstractDict) = Dict{String,Any}(string(k) => jsonify(v) for (k, v) in x)
jsonify(x::NamedTuple) = Dict{String,Any}(string(k) => jsonify(v) for (k, v) in pairs(x))
jsonify(x::Union{AbstractVector,Tuple}) = Any[jsonify(v) for v in x]
jsonify(x::Symbol) = String(x)
jsonify(x) = x

function Base.show(io::IO, ::MIME"text/plain", w::Widget)
    print(io, "Anywidget.Widget(", w.mod.name, ") id=", repr(w.id))
    for (k, v) in sort!(collect(w.traits); by=first)
        print(io, "\n  ", k, " = ", repr(v))
    end
end
