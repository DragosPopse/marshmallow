package mlw_media_image

import core_c "core:c"
import builtin "core:builtin"

int :: core_c.int

stbi__uint32 :: u32
stbi_uc :: u8

stbi_io_callbacks :: struct {
    read: proc(user: rawptr, data: [^]i8, size: int) -> int,  // fill 'data' with 'size' bytes.  return number of bytes actually read
    skip: proc(user: rawptr, n: int),                         // skip the next 'n' bytes, or 'unget' the last -n bytes if negative
    eof:  proc(user: rawptr) -> int,                         // returns nonzero if we are at end of file/data
}

stbi__context :: struct {
    img_x, img_y: stbi__uint32,
    img_n, img_out_n: int,

    io: stbi_io_callbacks,
    io_user_data: rawptr,

    read_from_callbacks: int,
    buflen: int,
    buffer_start: [128]stbi_uc,
    callback_already_read: int,

    img_buffer, img_buffer_end: [^]stbi_uc,
    img_buffer_original, img_buffer_original_end: [^]stbi_uc,
}

stbi__refill_buffer :: proc(s: ^stbi__context) {
    n: int = s.io.read(s.io_user_data, s.buffer_start, s.buflen)
    s.callback_already_read += int(cast(uintptr)raw_data(s.img_buffer) - cast(uintptr)raw_data(s.img_buffer_original))
    if (n == 0) {
        // at end of file, treat same as if from memory, but need to handle case
        // where s->img_buffer isn't pointing to safe memory, e.g. 0-byte file
        s.read_from_callbacks = 0
        s.img_buffer = s.buffer_start
        s.img_buffer_end = s.buffer_start[1:]
        s.img_buffer = nil
    } else {
        s.img_buffer = s.buffer_start
        s.img_buffer_end = s.buffer_start[n:]
    }
}

stbi__get8 :: proc(s: ^stbi__context) -> (result: stbi_uc) {
    if (cast(uintptr)raw_data(s.img_buffer) < cast(uintptr)raw_data(s.img_buffer_end)) {
        result = s.img_buffer[0]
        s.img_buffer = s.img_buffer[1:]
        return result
    }
    
    if (s.read_from_callbacks != 0) {
       stbi__refill_buffer(s)
       result = s.img_buffer[0]
        s.img_buffer = s.img_buffer[1:]
       return result
    }
    return 0
}

stbi__get16be :: proc(s: ^stbi__context) -> int
{
    z: int = stbi__get8(s)
    return (z << 8) + stbi__get8(s)
}

stbi__get32be(s: ^stbi__context) -> stbi__uint32 {
    z: stbi__uint32 = stbi__get16be(s)
    return (z << 16) + stbi__get16be(s)
}

stbi__malloc_mad3 :: proc(a, b, c, add: int) -> rawptr {
   if !stbi__mad3sizes_valid(a, b, c, add) do return nil;
   return stbi__malloc(a*b*c + add);
}

stbi__mad3sizes_valid :: proc(a, b, c, add: int) -> bool {
   return stbi__mul2sizes_valid(a, b) && stbi__mul2sizes_valid(a*b, c) && stbi__addsizes_valid(a*b*c, add);
}

stbi__mul2sizes_valid :: proc(a, b: int) -> bool {
   if a < 0 || b < 0 do return false;
   if b == 0 do return true; // mul-by-0 is always safe
   // portable way to check for no overflows in a*b
   return a <= INT_MAX / b;
}

stbi__addsizes_valid :: proc(a, b: int) -> bool {
   if b < 0 do return false;
   // now 0 <= b <= INT_MAX, hence also
   // 0 <= INT_MAX - b <= INTMAX.
   // And "a + b <= INT_MAX" (which might overflow) is the
   // same as a <= INT_MAX - b (no overflow)
   return a <= INT_MAX - b;
}

stbi__malloc :: proc(size: int) -> rawptr {
    unimplemented("allocations not implemented oof")
}

stbi__g_failure_reason: string

stbi__err :: proc(str1: string, str2: string) {
   stbi__g_failure_reason = str1
   return 0;
}

STBI__BYTECAST :: proc(x: #any_int builtin.int) -> stbi_uc {
    return stbi_uc(x & 255)
}