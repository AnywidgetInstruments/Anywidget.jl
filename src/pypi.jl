# Published anywidgets from PyPI, without Python (AW-PYPI-*): the wheel is a zip
# archive read as data, the widget class is read from its source.

const DEFAULT_INDEX = "https://pypi.org/pypi"

_index(index) = rstrip(something(index, get(ENV, "ANYWIDGET_PYPI_INDEX", DEFAULT_INDEX)), '/')
_cache(cache) = something(cache, get(ENV, "ANYWIDGET_CACHE", joinpath(first(DEPOT_PATH), "anywidget", "pypi")))

function _fetch(url::AbstractString)
    io = IOBuffer()
    Downloads.download(url, io)
    return String(take!(io))
end

"""
    pypi_wheel(project; version = nothing, index = nothing, cache = nothing)
        -> (; name, version, filename, dir)

Find the wheel of a PyPI project through the JSON API of `index` (default
`https://pypi.org/pypi`, or `ENV["ANYWIDGET_PYPI_INDEX"]`), preferring a
pure-Python wheel; download it, check its SHA-256 and extract it into `cache`
(default `<depot>/anywidget/pypi`, or `ENV["ANYWIDGET_CACHE"]`). An extracted
wheel is reused (AW-PYPI-001..003, AW-PYPI-010).
"""
function pypi_wheel(
    project::AbstractString;
    version::Union{Nothing,AbstractString}=nothing,
    index::Union{Nothing,AbstractString}=nothing,
    cache::Union{Nothing,AbstractString}=nothing,
)
    base = _index(index)
    url = version === nothing ? "$base/$project/json" : "$base/$project/$version/json"
    page = JSON.parse(_fetch(url); dicttype=Dict{String,Any})
    ver = String(page["info"]["version"])
    wheels = [u for u in page["urls"] if u["packagetype"] == "bdist_wheel"]
    isempty(wheels) && error("PyPI project \"$project\" $ver has no wheel")
    pure = findfirst(u -> endswith(u["filename"], "-none-any.whl"), wheels)
    whl = wheels[something(pure, 1)]
    sha = lowercase(String(whl["digests"]["sha256"]))
    dir = joinpath(_cache(cache), "$(project)-$(ver)-$(first(sha, 12))")
    if !isfile(joinpath(dir, ".complete"))
        tmp = mktempdir()
        file = joinpath(tmp, whl["filename"])
        Downloads.download(whl["url"], file)
        got = bytes2hex(open(SHA.sha256, file))
        got == sha || error("SHA-256 of $(whl["filename"]) is $got, the index publishes $sha: download refused")
        out = joinpath(tmp, "wheel")
        run(pipeline(`$(p7zip_jll.p7zip()) x -y -o$out $file`; stdout=devnull))
        mkpath(dirname(dir))
        rm(dir; force=true, recursive=true)
        mv(out, dir)
        touch(joinpath(dir, ".complete"))
        rm(tmp; force=true, recursive=true)
    end
    return (name=String(project), version=ver, filename=String(whl["filename"]), dir=dir)
end

function _class(project, dir, class)
    classes = anywidget_classes(dir)
    isempty(classes) && throw(ArgumentError("no anywidget class (deriving from anywidget.AnyWidget) in \"$project\""))
    names = join(sort!(collect(keys(classes))), ", ")
    if class === nothing
        length(classes) == 1 && return only(values(classes))
        # the only class having a front end (base classes often have none)
        withesm = [c for c in values(classes) if first(python_asset(c, "_esm")) !== :missing]
        length(withesm) == 1 && return only(withesm)
        throw(ArgumentError("\"$project\" has several anywidget classes, choose one with `class`: $names"))
    end
    haskey(classes, class) || throw(ArgumentError("no anywidget class \"$class\" in \"$project\"; classes: $names"))
    return classes[class]
end

# File of an inline stylesheet, written next to the extracted wheel.
function _inline_file(dir, name, text)
    path = joinpath(dir, ".anywidget", name)
    mkpath(dirname(path))
    write(path, text)
    return relpath(path, dir)
end

"""
    pypi_module(project; class = nothing, version = nothing, esm = nothing, css = nothing,
                index = nothing, cache = nothing) -> FrontendModule

The front-end module of an anywidget published on PyPI, read without Python:
the `_esm` and `_css` of its class (`class` is needed when the project has
several). When `_esm` cannot be read statically, give the module file of the
wheel with `esm` (a path relative to the wheel root); `css` likewise
(AW-PYPI-005, AW-PYPI-007..009).
"""
function pypi_module(project::AbstractString; kw...)
    return first(_pypi_module(project; kw...))
end

# (module, class) of a PyPI project, reading its wheel once.
function _pypi_module(
    project::AbstractString; class=nothing, version=nothing, esm=nothing, css=nothing, index=nothing, cache=nothing
)
    w = pypi_wheel(project; version=version, index=index, cache=cache)
    cls = _class(project, w.dir, class)
    name = "$(replace(project, r"[^A-Za-z0-9._-]" => "_")).$(cls.name)"
    cssfiles = if css !== nothing
        css isa AbstractString ? [String(css)] : String[String(c) for c in css]
    else
        kind, v = python_asset(cls, "_css")
        if kind === :file
            [relpath(v, w.dir)]
        elseif kind === :source
            [_inline_file(w.dir, "$(cls.name).css", v)]
        else
            String[]
        end
    end
    esm !== nothing && return FrontendModule(name; dir=w.dir, esm=esm, css=cssfiles), cls
    kind, v = python_asset(cls, "_esm")
    kind === :source && return FrontendModule(name; dir=w.dir, source=v, css=cssfiles), cls
    kind === :file && return FrontendModule(name; dir=w.dir, esm=relpath(v, w.dir), css=cssfiles), cls
    return error(
        "the front end of $(cls.name) (`_esm = $(something(v, "…"))` in $(relpath(cls.file, w.dir))) cannot be read " *
        "without running Python: give the module file of the wheel with `esm = \"path/in/wheel.js\"`",
    )
end

"""
    pypi_anywidget(project; class = nothing, version = nothing, esm = nothing, css = nothing,
                   index = nothing, cache = nothing, id = <unique>, traits...) -> Anywidget.Widget

A widget of an anywidget published on PyPI: its module ([`pypi_module`](@ref))
and the defaults of its synced traits read from the class, overridden by
`traits` (AW-PYPI-006, AW-PYPI-009).
"""
function pypi_anywidget(
    project::AbstractString;
    class=nothing,
    version=nothing,
    esm=nothing,
    css=nothing,
    index=nothing,
    cache=nothing,
    id::AbstractString=new_id(),
    traits...,
)
    m, cls = _pypi_module(project; class=class, version=version, esm=esm, css=css, index=index, cache=cache)
    defaults = python_trait_defaults(cls)
    for (k, v) in traits
        defaults[String(k)] = jsonify(v)
    end
    return Widget(m, String(id), defaults)
end
