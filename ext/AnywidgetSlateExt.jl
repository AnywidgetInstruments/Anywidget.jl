"""
    AnywidgetSlateExt

Kaimon Slate integration (AW-SLATE-*), loaded with SlateExtensionsBase.

- Every `AbstractAnywidget` converts to a `Widget` of the `SlateAFM.AFM`
  kind: `@bind w anywidget(mod; count = 0)` binds `w` to the trait
  dictionary, rendered by the host shim of SlateAFM.
- The local and inline modules of converted widgets are served under
  `/ext-assets/Anywidget.<module name>/`.
- Messages go through `SlateAFM.afm_emit` when SlateAFM is loaded.
"""
module AnywidgetSlateExt

using Anywidget: Anywidget, AbstractAnywidget, FrontendModule, Message, afm_module, message_id, widget_traits
using SlateExtensionsBase: SlateExtensionsBase, Widget, ext_asset_url, provide_assets!

# The widget kind registered by SlateAFM's host shim (AW-SLATE-004).
const KIND = "SlateAFM.AFM"

# Served modules: asset key -> directory. Re-declared from the front-end hook,
# which Slate runs again for each notebook namespace.
const SERVED = Dict{String,String}()

asset_key(m::FrontendModule) = "Anywidget." * m.name

# Directory of an inline module: its source written once to a scratch directory.
const INLINE_DIRS = Dict{String,String}()
function _source_dir(m::FrontendModule)
    dir = get!(() -> mktempdir(; cleanup=true), INLINE_DIRS, m.name)
    write(joinpath(dir, "index.js"), m.source)
    return dir
end

# URL of a file of a module, serving its directory.
function _url(m::FrontendModule, path::AbstractString, dir)
    Anywidget._isurl(path) && return String(path)
    key = asset_key(m)
    SERVED[key] = dir
    provide_assets!(key, dir)
    return ext_asset_url(key, path)
end

function _module_urls(m::FrontendModule)
    kind = Anywidget.esm_kind(m)
    esm = kind === :source ? _url(m, "index.js", _source_dir(m)) : _url(m, m.esm, m.dir)
    css = String[_url(m, c, m.dir) for c in m.css]
    return esm, css
end

function SlateExtensionsBase.to_widget(w::AbstractAnywidget)
    esm, css = _module_urls(afm_module(w))
    return Widget(KIND, widget_traits(w); src=esm, css=css, id=message_id(w))
end

function _slateafm()
    for (id, m) in Base.loaded_modules
        id.name == "SlateAFM" && return m
    end
    return nothing
end

"""
    slate_transport(id, msg::Message)

Send `msg` to the views of message id `id` with `SlateAFM.afm_emit`.
"""
function slate_transport(id::AbstractString, msg::Message)
    afm = _slateafm()
    afm === nothing && error("SlateAFM is not loaded: add `using SlateAFM` to the notebook")
    Base.invokelatest(afm.afm_emit, id, msg.content; buffers=msg.buffers)
    return nothing
end

function __slate_frontend(slate_on)
    for (key, dir) in SERVED
        provide_assets!(key, dir)
    end
    Anywidget.transport() === nothing && Anywidget.set_transport!(slate_transport)
    return nothing
end

function __init__()
    Anywidget.transport() === nothing && Anywidget.set_transport!(slate_transport)
    return nothing
end

end # module
