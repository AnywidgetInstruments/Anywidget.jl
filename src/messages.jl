# Custom messages (AW-MSG-*): `model.on("msg:custom", (content, buffers) => …)`
# on the front end.

"""
    Message(content, buffers = Vector{UInt8}[])

A custom message: its JSON `content` and its binary buffers, sent with it in
order (see [`encode_buffer`](@ref)).
"""
struct Message
    content::Dict{String,Any}
    buffers::Vector{Vector{UInt8}}
end
Message(content::AbstractDict) = Message(Dict{String,Any}(content), Vector{UInt8}[])
function Message(content::AbstractDict, buffers)
    return Message(Dict{String,Any}(content), Vector{UInt8}[Vector{UInt8}(b) for b in buffers])
end

# dtype (numpy notation) -> Julia element type
const DTYPES = Dict{String,DataType}(
    "<f4" => Float32,
    "<f8" => Float64,
    "<i1" => Int8,
    "<i2" => Int16,
    "<i4" => Int32,
    "<i8" => Int64,
    "<u1" => UInt8,
    "<u2" => UInt16,
    "<u4" => UInt32,
    "<u8" => UInt64,
    "u1" => UInt8,
    "|u1" => UInt8,
    "uint8" => UInt8,
    "i1" => Int8,
    "|i1" => Int8,
    "int8" => Int8,
    "float32" => Float32,
    "float64" => Float64,
)

"""
    encode_buffer(dtype, values) -> Vector{UInt8}

Bytes of a binary buffer of a numpy-style `dtype` (`"<f4"`, `"<f8"`, `"u1"`,
`"uint8"`, `"<i4"`, …): each value is converted to the element type and
written little-endian, whatever the byte order of the host (AW-MSG-002).
"""
function encode_buffer(dtype::AbstractString, values)
    T = get(DTYPES, String(dtype), nothing)
    T === nothing &&
        throw(ArgumentError("unsupported buffer dtype \"$dtype\" (little-endian integers and floats only)"))
    data = T[htol(convert(T, v)) for v in values]
    return collect(reinterpret(UInt8, data))
end

const TRANSPORT = Ref{Any}(nothing)

"""
    set_transport!(f)

Install the function sending messages to the front end: `f(id, msg::Message)`,
`id` being the widget's message id. Host integrations install one (the Kaimon
Slate extension sends through SlateAFM); `nothing` removes it.
"""
set_transport!(f) = (TRANSPORT[]=f; nothing)

"""
    transport()

The installed transport, or `nothing`.
"""
transport() = TRANSPORT[]

"""
    send_message(w::AbstractAnywidget, msg::Message)
    send_message(id, msg::Message)

Send a message to the views of widget `w` (or of message id `id`) through the
installed transport (see [`set_transport!`](@ref)).
"""
send_message(w::AbstractAnywidget, msg::Message) = send_message(message_id(w), msg)
function send_message(id::AbstractString, msg::Message)
    f = TRANSPORT[]
    f === nothing && error(
        "no message transport installed: load a host integration (in Kaimon Slate: " *
        "`using SlateAFM`) or call set_transport!((id, msg) -> …)",
    )
    f(String(id), msg)
    return nothing
end
