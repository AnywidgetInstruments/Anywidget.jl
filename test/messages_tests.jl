@testitem "messages (AW-MSG-001)" begin
    m = Message(Dict("type" => "ping"))
    @test m.content == Dict{String,Any}("type" => "ping")
    @test isempty(m.buffers)
    m2 = Message(Dict("type" => "data"), [UInt8[1, 2]])
    @test m2.buffers == [UInt8[1, 2]]
end

@testitem "buffers (AW-MSG-002)" begin
    b = encode_buffer("<f4", [1.0, 2.5])
    @test b isa Vector{UInt8} && length(b) == 8
    @test reinterpret(Float32, b) == Float32[1.0, 2.5]
    @test length(encode_buffer("<f8", [1, 2, 3])) == 24
    @test encode_buffer("uint8", [1, 255]) == UInt8[1, 255]
    @test encode_buffer("u1", [7]) == UInt8[7]
    @test reinterpret(Int32, encode_buffer("<i4", [-1, 2])) == Int32[-1, 2]
    @test encode_buffer("<f8", [1.0]) == reinterpret(UInt8, [htol(1.0)])
    @test_throws ArgumentError encode_buffer(">f4", [1.0])
    @test_throws ArgumentError encode_buffer("<c16", [1.0])
end

@testitem "transport (AW-MSG-003, AW-MSG-004)" begin
    m = AFMModule("t"; source="export default { render() {} };")
    w = Anywidget.Widget(m; id="w1")
    set_transport!(nothing)
    e = try
        send_message(w, Message(Dict("type" => "x")))
        nothing
    catch err
        err
    end
    @test e isa ErrorException
    @test occursin("transport", sprint(showerror, e))
    sent = []
    set_transport!((id, msg) -> push!(sent, (id, msg)))
    send_message(w, Message(Dict("type" => "x")))
    send_message("other", Message(Dict("type" => "y")))
    @test sent[1][1] == "w1" && sent[1][2].content["type"] == "x"
    @test sent[2][1] == "other"
    set_transport!(nothing)
end
