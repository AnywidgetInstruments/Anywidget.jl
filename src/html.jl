# Standalone HTML host (AW-HTML-*): the module runs in the page with a model
# holding the traits. No kernel: operator actions stay in the page.

# JSON safe inside <script>: no "</", no "<!--", no line separators.
function script_json(x)
    return replace(JSON.json(x), "<" => "\\u003c", ">" => "\\u003e", "&" => "\\u0026", " " => "\\u2028", " " => "\\u2029")
end

_html_escape(s) = replace(String(s), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;")

# URL of a local file of a module when its base URL is set, else nothing (inline).
_url(m::FrontendModule, path) =
    if _isurl(path)
        path
    elseif m.base[] === nothing
        nothing
    else
        m.base[] * path
    end

_esm_text(m::FrontendModule) = m.source !== nothing ? m.source : read(joinpath(m.dir, m.esm), String)

# Inline copies of a module (base64, so no text can close the element), once per
# output or page. Returns the loader spec of the module.
function _write_module(io::IO, m::FrontendModule)
    esm = esm_kind(m) === :source ? nothing : _url(m, m.esm)
    if esm === nothing
        print(io, "<script type=\"text/plain\" data-afm-esm=\"", m.name, "\">")
        print(io, base64encode(_esm_text(m)), "</script>\n")
    end
    css = Any[]
    for c in m.css
        u = _url(m, c)
        if u === nothing
            print(io, "<script type=\"text/plain\" data-afm-css=\"", m.name, "\">")
            print(io, base64encode(read(joinpath(m.dir, c))), "</script>\n")
            push!(css, nothing)
        else
            push!(css, u)
        end
    end
    return Dict("name" => m.name, "esm" => esm, "css" => css)
end

# Loader: imports each module once per page, adds its styles once, then runs
# initialize and render with a model holding the traits (AW-HTML-006).
const LOADER = raw"""
const afmLoad = (spec) => {
  const cache = (window.__afmModules ||= {});
  if (cache[spec.name]) return cache[spec.name];
  const text = (sel, i) => {
    const el = document.querySelectorAll(sel)[i || 0];
    const bin = atob(el.textContent);
    return new TextDecoder().decode(Uint8Array.from(bin, (c) => c.charCodeAt(0)));
  };
  let inline = 0;
  spec.css.forEach((url) => {
    const key = spec.name + ":" + (url || inline);
    if (!document.querySelector(`[data-afm-style="${CSS.escape(key)}"]`)) {
      const style = document.createElement(url ? "link" : "style");
      style.setAttribute("data-afm-style", key);
      if (url) { style.rel = "stylesheet"; style.href = url; }
      else style.textContent = text(`script[data-afm-css="${CSS.escape(spec.name)}"]`, inline);
      document.head.appendChild(style);
    }
    if (!url) inline += 1;
  });
  const url = spec.esm || URL.createObjectURL(new Blob(
    [text(`script[data-afm-esm="${CSS.escape(spec.name)}"]`)], { type: "text/javascript" }));
  cache[spec.name] = import(url).then((m) => m.default);
  return cache[spec.name];
};
const afmModel = (traits) => {
  const handlers = {};
  const fire = (ev, ...a) => (handlers[ev] || []).slice().forEach((h) => h(...a));
  return {
    get: (k) => traits[k],
    set(k, v) {
      if (JSON.stringify(traits[k]) === JSON.stringify(v)) return;
      traits[k] = v;
      fire(`change:${k}`);
    },
    save_changes: () => {},
    on: (ev, cb) => (handlers[ev] ||= []).push(cb),
    off: (ev, cb) => (handlers[ev] = (handlers[ev] || []).filter((h) => h !== cb)),
    send: () => {},
  };
};
"""

function _write_widget(io::IO, w::AbstractAnywidget, spec)
    uid = "afm-" * string(uuid4())
    print(io, "<div id=\"", uid, "\" class=\"afm-host\"></div>\n")
    print(io, "<script type=\"application/json\" id=\"", uid, "-traits\">")
    print(io, script_json(widget_traits(w)), "</script>\n")
    print(io, "<script type=\"module\">\n", LOADER)
    print(io, "const el = document.getElementById(\"", uid, "\");\n")
    print(io, "const traits = JSON.parse(document.getElementById(\"", uid, "-traits\").textContent);\n")
    print(io, "const afm = await afmLoad(", script_json(spec), ");\n")
    print(io, "const model = afmModel(traits);\n")
    print(io, "await afm.initialize?.({ model });\n")
    print(io, "await afm.render({ model, el });\n")
    print(io, "</script>\n")
    return nothing
end

function Base.show(io::IO, ::MIME"text/html", w::AbstractAnywidget)
    spec = _write_module(io, afm_module(w))
    _write_widget(io, w, spec)
    return nothing
end

"""
    html_page(widgets...; title = "Anywidget") -> String
    html_page(path, widgets...; title = "Anywidget") -> path

A standalone HTML page showing `widgets` side by side, each module included
once (AW-HTML-005). With a `path`, the page is written to that file.
"""
function html_page(widgets::AbstractAnywidget...; title::AbstractString="Anywidget")
    io = IOBuffer()
    print(io, "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n")
    print(io, "<title>", _html_escape(title), "</title>\n")
    print(
        io,
        "<style>body { font-family: sans-serif; display: flex; flex-wrap: wrap; gap: 24px; padding: 16px; }</style>\n",
    )
    print(io, "</head>\n<body>\n")
    specs = Dict{String,Any}()
    for w in widgets
        m = afm_module(w)
        spec = get!(() -> _write_module(io, m), specs, m.name)
        _write_widget(io, w, spec)
    end
    print(io, "</body>\n</html>\n")
    return String(take!(io))
end

function html_page(path::AbstractString, widgets::AbstractAnywidget...; kw...)
    write(path, html_page(widgets...; kw...))
    return path
end
