@testmodule Fixtures begin
    using Anywidget
    const DIR = joinpath(@__DIR__, "fixtures")
    counter() = FrontendModule("counter"; dir=DIR, esm="counter.js", css=["counter.css"])
end

@testitem "modules (AW-MOD-001..004)" setup = [Fixtures] begin
    m = Fixtures.counter()
    @test m.name == "counter"
    @test Anywidget.esm_kind(m) === :file
    u = FrontendModule("remote"; esm="https://esm.sh/some-widget@1", css=["https://example.org/w.css"])
    @test Anywidget.esm_kind(u) === :url
    s = FrontendModule("inline"; source="export default { render() {} };")
    @test Anywidget.esm_kind(s) === :source
    @test_throws ArgumentError FrontendModule("missing"; dir=Fixtures.DIR, esm="nope.js")
    @test_throws ArgumentError FrontendModule("css"; dir=Fixtures.DIR, esm="counter.js", css=["nope.css"])
    @test_throws ArgumentError FrontendModule("bad name!"; source="")
    @test_throws ArgumentError FrontendModule("relative"; esm="counter.js")      # no dir
    @test_throws ArgumentError FrontendModule("nothing")                          # no module
end

@testitem "type name (AW-MOD-006)" begin
    @test isdefined(Anywidget, :FrontendModule)
    @test Base.isexported(Anywidget, :FrontendModule)
    @test !isdefined(Anywidget, :AFMModule)          # renamed before any release
end

@testitem "asset base URL (AW-MOD-005)" setup = [Fixtures] begin
    m = Fixtures.counter()
    set_asset_base!(m, "https://example.org/counter")
    @test m.base[] == "https://example.org/counter/"
    set_asset_base!(m, nothing)
    @test m.base[] === nothing
end

@testitem "generic widget (AW-WID-001..004)" setup = [Fixtures] begin
    m = Fixtures.counter()
    w = Anywidget.Widget(m; count=0, label=:Clicks, size=(100, 40), opts=(a=1,))
    @test w isa AbstractAnywidget
    @test afm_module(w) === m
    @test w[:count] == 0
    @test w["label"] == "Clicks"                      # Symbol -> String
    @test w[:size] == [100, 40]                        # tuple -> array
    @test w[:opts] == Dict{String,Any}("a" => 1)       # named tuple -> dict
    w[:count] = 3
    @test widget_traits(w)["count"] == 3
    @test haskey(w, :count) && !haskey(w, :nope)
    @test !isempty(message_id(w))
    @test message_id(Anywidget.Widget(m; id="c1")) == "c1"
    @test message_id(Anywidget.Widget(m)) != message_id(Anywidget.Widget(m))
    @test anywidget(m; count=2) isa Anywidget.Widget         # exported shorthand
    @test !Base.isexported(Anywidget, :Widget)                 # no clash with other Widget types
end
