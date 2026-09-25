# A fake PyPI index (file:// URLs) serving two wheels built by the tests:
# - staticwidget: the front end is a static file, found through a variable
#   (`_DIR = pathlib.Path(__file__).parent / "static"`);
# - inlinewidget: two classes, the front end and the styles inline, trait
#   defaults of several types.

@testmodule FakePyPI begin
    using Anywidget, JSON, SHA, p7zip_jll

    const STATIC_INIT = raw"""
    import pathlib
    import anywidget
    import traitlets

    _DIR = pathlib.Path(__file__).parent / "static"

    class Counter(anywidget.AnyWidget):
        _esm = _DIR / "widget.js"
        _css = pathlib.Path(__file__).parent / "static" / "widget.css"
        count = traitlets.Int(3).tag(sync=True)
        label = traitlets.Unicode("Clicks").tag(sync=True)
        hidden = traitlets.Int(9)          # not synced: ignored
    """

    const INLINE_INIT = replace(
        raw"""
import anywidget
from traitlets import Bool, Float, Int, List, Unicode, Dict, Any

class Hello(anywidget.AnyWidget):
    _esm = TQ
    export default { render({ model, el }) { el.textContent = `hello ${model.get("name")}\n`; } };
    TQ
    _css = ".hello { color: red; }"
    name = Unicode('world').tag(sync=True)
    ratio = Float(0.5).tag(sync=True)
    on = Bool(True).tag(sync=True)
    items = List([1, 2, "three"]).tag(sync=True)
    opts = Dict({"a": None, "b": False}).tag(sync=True)
    computed = Int(compute()).tag(sync=True)   # not a literal: left to the user

class Other(AnyWidget):
    _esm = r"export default { render() {} };"
""",
        "TQ" => "\"\"\"",
    )

    "Write a wheel (zip) of `files` (path => content) and return its path."
    function wheel(dir, name, version, files)
        src = mktempdir()
        for (path, content) in files
            mkpath(dirname(joinpath(src, path)))
            write(joinpath(src, path), content)
        end
        whl = joinpath(dir, "$(name)-$(version)-py3-none-any.whl")
        run(pipeline(`$(p7zip()) a -tzip $whl $(joinpath(src, "*"))`; stdout=devnull))
        return whl
    end

    "Publish a project in the fake index `root`: JSON API pages for the version and the latest."
    function publish(root, name, version, files; digest=nothing)
        dir = mkpath(joinpath(root, "files"))
        whl = wheel(dir, name, version, files)
        sha = digest === nothing ? bytes2hex(open(sha256, whl)) : digest
        page = Dict(
            "info" => Dict("name" => name, "version" => version),
            "urls" => [
                Dict(
                    "packagetype" => "sdist",
                    "filename" => "$name-$version.tar.gz",
                    "url" => "file:///nope",
                    "digests" => Dict("sha256" => "0"),
                ),
                Dict(
                    "packagetype" => "bdist_wheel",
                    "filename" => basename(whl),
                    "url" => "file://" * whl,
                    "digests" => Dict("sha256" => sha),
                ),
            ],
        )
        for p in (joinpath(root, name, "json"), joinpath(root, name, version, "json"))
            mkpath(dirname(p))
            write(p, JSON.json(page))
        end
        return whl
    end

    const ROOT = mktempdir()
    const INDEX = "file://" * ROOT
    const CACHE = mktempdir()

    publish(
        ROOT,
        "staticwidget",
        "1.2.0",
        [
            "staticwidget/__init__.py" => STATIC_INIT,
            "staticwidget/static/widget.js" => "export default { render({ el }) { el.textContent = 'static'; } };",
            "staticwidget/static/widget.css" => ".static { color: blue; }",
            "staticwidget-1.2.0.dist-info/METADATA" => "Name: staticwidget\nVersion: 1.2.0\n",
        ],
    )
    publish(
        ROOT,
        "inlinewidget",
        "0.1.0",
        [
            "inlinewidget/__init__.py" => INLINE_INIT,
            "inlinewidget-0.1.0.dist-info/METADATA" => "Name: inlinewidget\nVersion: 0.1.0\n",
        ],
    )
    publish(
        ROOT,
        "layered",
        "2.0.0",
        [
            "layered/_base.py" => "from anywidget import AnyWidget\nimport traitlets\n\nclass Base(AnyWidget):\n    _css = \".base {}\"\n    size = traitlets.Int(10).tag(sync=True)\n",
            "layered/_map.py" => "from pathlib import Path\nfrom layered._base import Base\nimport traitlets\nout = Path(__file__).parent / 'static'\n\nclass Map(Base):\n    _esm = out / 'index.js'\n    zoom = traitlets.Float(1.5).tag(sync=True)\n\nclass Layer(Base):\n    color = traitlets.Unicode('red').tag(sync=True)\n",
            "layered/static/index.js" => "export default { render() {} };",
        ],
    )
    publish(ROOT, "badwidget", "1.0.0", ["badwidget/__init__.py" => "x = 1\n"]; digest="00" ^ 32)
    publish(
        ROOT,
        "pathwidget",
        "1.0.0",
        [
            "pathwidget/__init__.py" => "import anywidget\nclass P(anywidget.AnyWidget):\n    _esm = some_function()\n",
            "pathwidget/front/main.js" => "export default { render() {} };",
        ],
    )
end

@testitem "wheel lookup and download (AW-PYPI-001..003)" setup = [FakePyPI] begin
    w = Anywidget.pypi_wheel("staticwidget"; index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
    @test w.version == "1.2.0"
    @test endswith(w.filename, "py3-none-any.whl")
    @test isfile(joinpath(w.dir, "staticwidget", "static", "widget.js"))
    @test occursin("staticwidget-1.2.0", w.dir)
    # cached: a second call reuses the directory
    t = mtime(joinpath(w.dir, "staticwidget", "__init__.py"))
    w2 = Anywidget.pypi_wheel("staticwidget"; version="1.2.0", index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
    @test w2.dir == w.dir
    @test mtime(joinpath(w2.dir, "staticwidget", "__init__.py")) == t
    # a wrong digest is refused
    e = try
        Anywidget.pypi_wheel("badwidget"; index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
        nothing
    catch err
        err
    end
    @test e isa ErrorException
    @test occursin("SHA-256", sprint(showerror, e))
end

@testitem "classes and front end from a path (AW-PYPI-004, AW-PYPI-005, AW-PYPI-009)" setup = [FakePyPI] begin
    m = pypi_module("staticwidget"; index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
    @test m isa FrontendModule
    @test m.name == "staticwidget.Counter"
    @test Anywidget.esm_kind(m) === :file
    @test endswith(m.esm, "widget.js") && endswith(m.css[1], "widget.css")
    @test read(joinpath(m.dir, m.esm), String) == "export default { render({ el }) { el.textContent = 'static'; } };"
end

@testitem "inline front end and trait defaults (AW-PYPI-005, AW-PYPI-006, AW-PYPI-009)" setup = [FakePyPI] begin
    w = pypi_anywidget("inlinewidget"; class="Hello", index=FakePyPI.INDEX, cache=FakePyPI.CACHE, ratio=0.8)
    m = afm_module(w)
    @test Anywidget.esm_kind(m) === :source
    @test occursin("hello \${model.get(\"name\")}\n`", m.source)      # \n unescaped, as Python does
    @test occursin(".hello { color: red; }", read(joinpath(m.dir, m.css[1]), String))
    t = widget_traits(w)
    @test t["name"] == "world"
    @test t["ratio"] == 0.8                                            # given trait wins
    @test t["on"] === true
    @test t["items"] == Any[1, 2, "three"]
    @test t["opts"] == Dict{String,Any}("a" => nothing, "b" => false)
    @test !haskey(t, "computed")                                       # not a literal
    o = pypi_module("inlinewidget"; class="Other", index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
    @test o.source == "export default { render() {} };"
end

@testitem "class choice and unresolved front end (AW-PYPI-007, AW-PYPI-008)" setup = [FakePyPI] begin
    msg(f) =
        try
            f()
            ""
        catch e
            e isa ArgumentError || e isa ErrorException ? sprint(showerror, e) : rethrow()
        end
    kw = (index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
    s = msg(() -> pypi_module("inlinewidget"; kw...))
    @test occursin("Hello", s) && occursin("Other", s)
    @test occursin("Hello", msg(() -> pypi_module("inlinewidget"; class="Nope", kw...)))
    s2 = msg(() -> pypi_module("pathwidget"; kw...))
    @test occursin("esm", s2)
    # giving the module file resolves it
    m = pypi_module("pathwidget"; esm="pathwidget/front/main.js", kw...)
    @test Anywidget.esm_kind(m) === :file
end

@testitem "inherited classes (AW-PYPI-004, AW-PYPI-012)" setup = [FakePyPI] begin
    kw = (index=FakePyPI.INDEX, cache=FakePyPI.CACHE)
    w = Anywidget.pypi_wheel("layered"; kw...)
    @test sort!(collect(keys(Anywidget.anywidget_classes(w.dir)))) == ["Base", "Layer", "Map"]
    # only Map has a front end: chosen without `class`
    x = pypi_anywidget("layered"; kw...)
    @test afm_module(x).name == "layered.Map"
    @test widget_traits(x) == Dict{String,Any}("size" => 10, "zoom" => 1.5)   # inherited default
    @test occursin(".base {}", read(joinpath(afm_module(x).dir, afm_module(x).css[1]), String))  # inherited _css
end

@testitem "index and cache settings (AW-PYPI-010)" setup = [FakePyPI] begin
    withenv("ANYWIDGET_PYPI_INDEX" => FakePyPI.INDEX, "ANYWIDGET_CACHE" => mktempdir()) do
        w = Anywidget.pypi_wheel("staticwidget")
        @test startswith(w.dir, ENV["ANYWIDGET_CACHE"])
    end
end

@testitem "Python literals" begin
    lit = Anywidget.python_literal
    @test lit("0") === 0 && lit("-2.5") === -2.5 && lit("1e3") === 1000.0
    @test lit("True") === true && lit("None") === nothing
    @test lit("'a\\'b'") == "a'b" && lit("\"x\"") == "x"
    @test lit("[1, (2, 3), {'k': [None]}]") == Any[1, Any[2, 3], Dict{String,Any}("k" => Any[nothing])]
    @test lit("[]") == Any[] && lit("{}") == Dict{String,Any}()
    @test lit("compute()") === Anywidget.NOT_LITERAL
    @test lit("x + 1") === Anywidget.NOT_LITERAL
end
