package mlw_media_image

import core_c "core:c"
import builtin "core:builtin"
import "core:mem"

int :: core_c.int
uint :: core_c.uint 

stbi__uint32 :: u32
stbi__uint16 :: u16
stbi_uc :: u8

stbi_io_callbacks :: struct {
    read: proc(user: rawptr, data: [^]i8, size: int) -> int,  // fill 'data' with 'size' bytes.  return number of bytes actually read
    skip: proc(user: rawptr, n: int),                         // skip the next 'n' bytes, or 'unget' the last -n bytes if negative
    eof:  proc(user: rawptr) -> int,                         // returns nonzero if we are at end of file/data
}

stbi__result_info :: struct {
    bits_per_channel: int,
    num_channels: int,
    channel_order: int,
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
    n: int = s.io.read(s.io_user_data, s.buffer_start[:], s.buflen)
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

stbi__get32be :: proc(s: ^stbi__context) -> stbi__uint32 {
    z: stbi__uint32 = stbi__get16be(s)
    return (z << 16) + stbi__get16be(s)
}

stbi__malloc_mad3 :: proc(a, b, c, add: int) -> rawptr {
   if !stbi__mad3sizes_valid(a, b, c, add) do return nil;
   return stbi__malloc(a*b*c + add);
}

stbi__malloc_mad2 :: proc(a, b, add: int) -> rawptr
{
   if !stbi__mad2sizes_valid(a, b, add) do return nil;
   return stbi__malloc(a*b + add);
}

stbi__mad3sizes_valid :: proc(a, b, c, add: int) -> bool {
   return stbi__mul2sizes_valid(a, b) && stbi__mul2sizes_valid(a*b, c) && stbi__addsizes_valid(a*b*c, add);
}

stbi__mul2sizes_valid :: proc(a, b: int) -> bool {
   if a < 0 || b < 0 do return false;
   if b == 0 do return true; // mul-by-0 is always safe
   // portable way to check for no overflows in a*b
   return a <= max(int) / b;
}

stbi__mad2sizes_valid :: proc(a, b, add: int) -> bool
{
   return stbi__mul2sizes_valid(a, b) && stbi__addsizes_valid(a*b, add);
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

stbi__errpuc :: proc(str1: string, str2: string) -> bool {
    stbi__g_failure_reason = str1
    return false
}

stbi__err :: proc(str1: string, str2: string) -> bool {
    stbi__g_failure_reason = str1
    return false
}

STBI__BYTECAST :: proc(x: builtin.int) -> stbi_uc {
    return stbi_uc(x & 255)
}

STBI_FREE :: proc(ptr: rawptr) {
    unimplemented("STBI_FREE unimplemented")
}

STBI_REALLOC_SIZED :: proc(ptr: rawptr, oldsz, newsz: int) -> rawptr {
    unimplemented("STBI_REALLOC_SIZED")
}

stbi__getn :: proc(s: ^stbi__context, buffer: [^]stbi_uc, n: int) -> int {
    if s.io.read {
        blen: int  = cast(int)(cast(uintptr)raw_data(s.img_buffer_end) - cast(uintptr)raw_data(s.img_buffer))
        if blen < n {
            res, count: int
            mem.copy(buffer, s.img_buffer, blen)
            //memcpy(buffer, s.img_buffer, blen)
            
            count = s.io.read(s.io_user_data, buffer[blen:], n - blen)
            res = (count == (n-blen))
            s.img_buffer = s.img_buffer_end
            return res
        }
    }   

    if cast(uintptr)raw_data(s.img_buffer[n:]) <= cast(uintptr)raw_data(s.img_buffer_end) {
        mem.copy(buffer, s.img_buffer, n)
        //memcpy(buffer, s.img_buffer, n)
        s.img_buffer = s.img_buffer[n:]
        return 1
    } 
    return 0
}

stbi__convert_format :: proc(data: [^]stbi_uc, img_n: int, req_comp: int, x: uint, y: uint) -> [^]stbi_uc {
    i, j: int
    good: [^]stbi_uc

    if req_comp == img_n do return data
    assert(req_comp >= 1 && req_comp <= 4)

    good = cast([^]stbi_uc)stbi__malloc_mad3(req_comp, cast(int)x, cast(int)y, 0)
    if good == nil {
        STBI_FREE(data)
        stbi__errpuc("outofmem", "Out of memory")
        return nil
    }

    for j = 0; j < cast(int)y; j += 1 {
        src: [^]stbi_uc  = data[j * x * img_n:]   
        dest: [^]stbi_uc = good[j * x * req_comp:]

        STBI__COMBO :: proc(a, b: int) -> int { return a * 8 + b }

        switch STBI__COMBO(img_n, req_comp) {
            case STBI__COMBO(1,2): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]; dest[1]=255;
                }
                                                     
            }
            case STBI__COMBO(1,3): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]
                    dest[1]=src[0]
                    dest[2]=src[0]; 
                }
                                                 
            }
            case STBI__COMBO(1,4): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]
                    dest[1]=src[0]
                    dest[2]=src[0]; 
                    dest[3]=255;   
                }
                                  
            }
            case STBI__COMBO(2,1): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0];        
                } 
                                                         
            }
            case STBI__COMBO(2,3): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]
                    dest[1]=src[0]
                    dest[2]=src[0];      
                }
                                            
            }
            case STBI__COMBO(2,4): {
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]
                    dest[1]=src[0]
                    dest[2]=src[0]
                    dest[3]=src[1]
                } 
                                 
            }
            case STBI__COMBO(3,4): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0];
                    dest[1]=src[1];
                    dest[2]=src[2];
                    dest[3]=255;    
                }
                    
            }
            case STBI__COMBO(3,1): { 
                for i=x-1; i >= 0;  {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y(src[0],src[1],src[2]);      
                }
                              
            }
            case STBI__COMBO(3,2): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y(src[0],src[1],src[2]); 
                    dest[1] = 255;  
                }
                  
            }
            case STBI__COMBO(4,1): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y(src[0],src[1],src[2]);         
                }
                          
            }
            case STBI__COMBO(4,2): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y(src[0],src[1],src[2]); 
                    dest[1] = src[3]; 
                }
                
            }
            case STBI__COMBO(4,3): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0];
                    dest[1]=src[1];
                    dest[2]=src[2]; 
                }
                                   
            }
            case: {
                assert(false); STBI_FREE(data); STBI_FREE(good); stbi__errpuc("unsupported", "Unsupported format conversion"); return nil
            }
            
        }

        /*
        #define STBI__COMBO(a,b)  ((a)*8+(b))
        #define STBI__CASE(a,b)   case STBI__COMBO(a,b): for(i=x-1; i >= 0; --i, src += a, dest += b)
        // convert source image with img_n components to one with req_comp components;
        // avoid switch per pixel, so use switch per scanline and massive macros
        switch (STBI__COMBO(img_n, req_comp)) {
            STBI__CASE(1,2) { dest[0]=src[0]; dest[1]=255;                                     } break;
            STBI__CASE(1,3) { dest[0]=dest[1]=dest[2]=src[0];                                  } break;
            STBI__CASE(1,4) { dest[0]=dest[1]=dest[2]=src[0]; dest[3]=255;                     } break;
            STBI__CASE(2,1) { dest[0]=src[0];                                                  } break;
            STBI__CASE(2,3) { dest[0]=dest[1]=dest[2]=src[0];                                  } break;
            STBI__CASE(2,4) { dest[0]=dest[1]=dest[2]=src[0]; dest[3]=src[1];                  } break;
            STBI__CASE(3,4) { dest[0]=src[0];dest[1]=src[1];dest[2]=src[2];dest[3]=255;        } break;
            STBI__CASE(3,1) { dest[0]=stbi__compute_y(src[0],src[1],src[2]);                   } break;
            STBI__CASE(3,2) { dest[0]=stbi__compute_y(src[0],src[1],src[2]); dest[1] = 255;    } break;
            STBI__CASE(4,1) { dest[0]=stbi__compute_y(src[0],src[1],src[2]);                   } break;
            STBI__CASE(4,2) { dest[0]=stbi__compute_y(src[0],src[1],src[2]); dest[1] = src[3]; } break;
            STBI__CASE(4,3) { dest[0]=src[0];dest[1]=src[1];dest[2]=src[2];                    } break;
            default: STBI_ASSERT(0); STBI_FREE(data); STBI_FREE(good); return stbi__errpuc("unsupported", "Unsupported format conversion");
        }
        #undef STBI__CASE
        */

    }

    STBI_FREE(data)
    return good
}

stbi__convert_format16 :: proc(data: [^]stbi__uint16, img_n, req_comp: int, x, y: uint) -> [^]stbi__uint16 {
    i, j: int
    good: [^]stbi__uint16

    if req_comp == img_n do return data
    assert(req_comp >= 1 && req_comp <= 4)

    good = cast([^]stbi__uint16)stbi__malloc(req_comp * x * y * 2)
    if good == nil {
       STBI_FREE(data)
       stbi__errpuc("outofmem", "Out of memory")
       return nil
    }

    for j=0; j < cast(int)y; j += 1 {
        src: [^]stbi__uint16 = data[j * x * img_n:]   
        dest: [^]stbi__uint16 = good[j * x * req_comp:]

        //#define STBI__COMBO(a,b)  ((a)*8+(b))
        //#define STBI__CASE(a,b)   case STBI__COMBO(a,b): for(i=x-1; i >= 0; --i, src += a, dest += b)
        STBI__COMBO :: proc(a, b: int) -> int { 
            return a * 8 + b 
        }
        // convert source image with img_n components to one with req_comp components;
        // avoid switch per pixel, so use switch per scanline and massive macros
        switch STBI__COMBO(img_n, req_comp) {
            case STBI__COMBO(1,2): {
                for i=x-1; i >= 0;  {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]; dest[1]=0xffff;  
                }                               
            } 

            case STBI__COMBO(1,3): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0]
                    dest[1]=src[0]
                    dest[2]=src[0] 
                }

            } 

            case STBI__COMBO(1,4): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:] 
                    }
                    dest[0]=src[0]
                    dest[1]=src[0]
                    dest[2]=src[0]
                    dest[3]=0xffff   
                }

            } 

            case STBI__COMBO(2,1): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0];       
                }
            } 

            case STBI__COMBO(2,3): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0], dest[1], dest[2] = src[0];    
                } 
            } 

            case STBI__COMBO(2,4): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0], dest[1], dest[2] = src[0]; 
                    dest[3]=src[1]; 
                }
            } 

            case STBI__COMBO(3,4): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0];dest[1]=src[1];dest[2]=src[2];dest[3]=0xffff;     
                }
            } 

            case STBI__COMBO(3,1): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y_16(src[0],src[1],src[2]);     
                }

            } 

            case STBI__COMBO(3,2): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y_16(src[0],src[1],src[2]); dest[1] = 0xffff; 
                }
            } 

            case STBI__COMBO(4,1): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y_16(src[0],src[1],src[2]);  
                }
            } 

            case STBI__COMBO(4,2): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=stbi__compute_y_16(src[0],src[1],src[2]); dest[1] = src[3]; 
                }
            } 

            case STBI__COMBO(4,3): { 
                for i=x-1; i >= 0; {
                    defer {
                        i -= 1 
                        src = src[a:] 
                        dest = dest[b:]
                    }
                    dest[0]=src[0];dest[1]=src[1];dest[2]=src[2];    
                }
            } 

            case: {
                assert(false); STBI_FREE(data); STBI_FREE(good); 
                stbi__errpuc("unsupported", "Unsupported format conversion")
                return nil
            }
        }
    }

    STBI_FREE(data)
    return good
}

stbi__compute_y_16 :: proc(r, g, b: int) -> stbi__uint16 {
    return cast(stbi__uint16) (((r*77) + (g*150) +  (29*b)) >> 8);
}

stbi__compute_y :: proc(r, g, b: int) -> stbi_uc {
    return cast(stbi_uc) (((r*77) + (g*150) +  (29*b)) >> 8);
}
 
stbi__rewind :: proc(s: ^stbi__context) {
    // conceptually rewind SHOULD rewind to the beginning of the stream,
    // but we just rewind to the beginning of the initial buffer, because
    // we only use it after doing 'test', which only ever looks at at most 92 bytes
    s.img_buffer = s.img_buffer_original
    s.img_buffer_end = s.img_buffer_original_end  
}

stbi__skip :: proc(s: ^stbi__context, n: int) {
    if n == 0 do return  // already there!
    if n < 0 {
        s.img_buffer = s.img_buffer_end;
        return
    }
    if (s->io.read) {
        blen: int = cast(int) (cast(uintptr)raw_data(s.img_buffer_end) - cast(uintptr)raw_data(s.img_buffer));
        if (blen < n) {
            s.img_buffer = s.img_buffer_end;
            s.io.skip(s.io_user_data, n - blen);
            return;
        }
    }
    s.img_buffer = s.img_buffer[n:];
}