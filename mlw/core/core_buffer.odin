package mlw_core

MAX_SHADERSTAGE_BUFFERS :: 8

Buffer :: distinct u32

Buffer_Type :: enum {
    Vertex,
    Index,
}

Buffer_Usage_Hint :: enum {
    Immutable,
    Dynamic,
    Stream,
}

Buffer_Info :: struct {
    type: Buffer_Type,
    size: int,
    data: []u8, // Optional unless usage_hint == .Immutable
    usage_hint: Buffer_Usage_Hint,
}

Input_Buffers :: struct {
    buffers: [MAX_SHADERSTAGE_BUFFERS]Buffer,
    index: Maybe(Buffer),
}