# Front-end modules (AW-MOD-*).

"""
    FrontendModule(name; dir = nothing, esm = "", css = String[], source = nothing)

A front-end module: an ES module exporting `{ initialize?, render }` and its
stylesheets. The module is either

- a file of the local directory `dir` (`esm = "index.js"`),
- an absolute URL (`esm = "https://esm.sh/…"`),
- or inline source text (`source = "export default { … }"`).

Each item of `css` is a file of `dir` or an absolute URL. `name` identifies
the module in pages and in served URLs: letters, digits, `.`, `_` and `-`.
"""
struct FrontendModule
    name::String
    esm::String
    css::Vector{String}
    dir::Union{Nothing,String}
    source::Union{Nothing,String}
    base::Base.RefValue{Union{Nothing,String}}
end

_isurl(s::AbstractString) = startswith(s, "http://") || startswith(s, "https://")

function FrontendModule(
    name::AbstractString;
    dir::Union{Nothing,AbstractString}=nothing,
    esm::AbstractString="",
    css=String[],
    source::Union{Nothing,AbstractString}=nothing,
)
    occursin(r"^[A-Za-z0-9._-]+$", name) ||
        throw(ArgumentError("invalid module name \"$name\": use letters, digits, '.', '_' and '-'"))
    cssv = css isa AbstractString ? [String(css)] : String[String(c) for c in css]
    d = dir === nothing ? nothing : abspath(dir)
    if source === nothing
        isempty(esm) && throw(ArgumentError("module \"$name\": give `esm` (a file of `dir` or a URL) or `source`"))
        _check_file(name, d, esm)
    end
    for c in cssv
        _check_file(name, d, c)
    end
    src = source === nothing ? nothing : String(source)
    return FrontendModule(String(name), String(esm), cssv, d, src, Ref{Union{Nothing,String}}(nothing))
end

function _check_file(name, dir, path)
    _isurl(path) && return nothing
    dir === nothing && throw(ArgumentError("module \"$name\": \"$path\" is not a URL and no `dir` is given"))
    isfile(joinpath(dir, path)) || throw(ArgumentError("module \"$name\": file \"$path\" not found in $dir"))
    return nothing
end

"""
    esm_kind(mod::FrontendModule) -> Symbol

Where the ES module comes from: `:source` (inline text), `:url` or `:file`.
"""
esm_kind(m::FrontendModule) =
    if m.source !== nothing
        :source
    elseif _isurl(m.esm)
        :url
    else
        :file
    end

"""
    set_asset_base!(mod::FrontendModule, url::Union{AbstractString,Nothing})

Base URL the local files of `mod` are served from (for example where a
documentation build copied them). The HTML display then loads them by URL
instead of inlining them; `nothing` restores inlining (AW-MOD-005).
"""
function set_asset_base!(m::FrontendModule, url::Union{AbstractString,Nothing})
    m.base[] = url === nothing ? nothing : (endswith(url, "/") ? String(url) : url * "/")
    return m
end

Base.show(io::IO, m::FrontendModule) = print(io, "FrontendModule(", repr(m.name), ", ", esm_kind(m), ")")
