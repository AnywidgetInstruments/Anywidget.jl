using Test
using Anywidget
using SlateExtensionsBase
using SlateAFM

const Ext = Base.get_extension(Anywidget, :AnywidgetSlateExt)
const FIXTURES = joinpath(@__DIR__, "..", "fixtures")

@testset "Kaimon Slate extension" begin
    @test Ext !== nothing
    counter = AFMModule("counter"; dir=FIXTURES, esm="counter.js", css=["counter.css"])

    @testset "to_widget (AW-SLATE-001)" begin
        w = to_widget(anywidget(counter; count=1, id="c1"))
        @test w isa SlateExtensionsBase.Widget
        @test w.kind == "SlateAFM.AFM"
        @test w.default == Dict{String,Any}("count" => 1)
        @test w.params["src"] == "/ext-assets/Anywidget.counter/counter.js"
        @test w.params["css"] == ["/ext-assets/Anywidget.counter/counter.css"]
        @test w.params["id"] == "c1"
        remote = AFMModule("remote"; esm="https://esm.sh/w@1")
        @test to_widget(anywidget(remote)).params["src"] == "https://esm.sh/w@1"
    end

    @testset "served modules (AW-SLATE-002)" begin
        @test SlateExtensionsBase._ASSETS["Anywidget.counter"] == abspath(FIXTURES)
        inline = AFMModule("inline"; source="export default { render() {} };")
        w = to_widget(anywidget(inline))
        @test w.params["src"] == "/ext-assets/Anywidget.inline/index.js"
        dir = SlateExtensionsBase._ASSETS["Anywidget.inline"]
        @test read(joinpath(dir, "index.js"), String) == inline.source
        empty!(SlateExtensionsBase._ASSETS)
        handlers = Dict{String,Any}()
        Ext.__slate_frontend((ch, f) -> (handlers[ch] = f))
        @test haskey(SlateExtensionsBase._ASSETS, "Anywidget.counter")   # re-declared
        @test isempty(handlers)                                          # incoming messages stay with SlateAFM
    end

    @testset "transport through SlateAFM (AW-SLATE-003)" begin
        @test Anywidget.transport() === Ext.slate_transport
        sent = []
        task_local_storage(:slate_ctx, (; emit=(channel, value) -> push!(sent, (channel, value)))) do
            send_message(anywidget(counter; id="c1"), Message(Dict("type" => "data"), [encode_buffer("<f4", [3.0])]))
        end
        @test length(sent) == 2                                # content frame + one buffer frame
        @test sent[1][1] == "SlateAFM.msg:c1"
        @test sent[1][2].content["type"] == "data"
        @test sent[2][2] isa SlateBinary
        @test reinterpret(Float32, sent[2][2].data) == Float32[3.0]
    end
end
