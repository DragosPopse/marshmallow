package mlw_media_image

import "core:builtin"

// Port of https://github.com/nothings/stb/blob/master/stb_image.h . Simplified



stbi__pngchunk :: struct {
    length: stbi__uint32,
    type: stbi__uint32,
}

stbi__get_chunk_header :: proc(s: ^stbi__context) -> stbi__pngchunk {
    c: stbi__pngchunk
    c.length = stbi__get32be(s)
    c.type   = stbi__get32be(s)
    return c
}

stbi__check_png_header :: proc(s: ^stbi__context) -> bool {
    png_sig := [8]stbi_uc { 137,80,78,71,13,10,26,10 }
    for i := 0; i < 8; i += 1 {
        if (stbi__get8(s) != png_sig[i]) {
            return stbi__err("error", "Not a PNG")
        }
    }
       
    return true
}

stbi__png :: struct {
    s: ^stbi__context,
    idata, expanded, out: [^]stbi_uc,
    depth: int,
}

STBI__F_none :: 0
STBI__F_sub :: 1
STBI__F_up :: 2
STBI__F_avg :: 3
STBI__F_paeth :: 4
// synthetic filters used for first scanline to avoid needing a dummy row of 0s
STBI__F_avg_first :: 5
STBI__F_paeth_first :: 6

first_row_filter := [5]stbi_uc {
   STBI__F_none,
   STBI__F_sub,
   STBI__F_none,
   STBI__F_avg_first,
   STBI__F_paeth_first,
}

stbi__paeth :: proc(a, b, c: int) -> int {
   p: int = a + b - c;
   pa: int = abs(p-a);
   pb: int = abs(p-b);
   pc: int = abs(p-c);
   if pa <= pb && pa <= pc do return a;
   if pb <= pc do return b;
   return c;
}

stbi__depth_scale_table := [9]stbi_uc { 0, 0xff, 0x55, 0, 0x11, 0,0,0, 0x01 };

// create the png data from post-deflated data
stbi__create_png_image_raw :: proc(a: ^stbi__png, raw: [^]stbi_uc, raw_len: stbi__uint32, out_n: int, x: stbi__uint32, y: stbi__uint32, depth: int, color: int) -> bool {
    bytes: int = (depth == 16 ? 2 : 1)
    s: ^stbi__context = a.s
    i, j: stbi__uint32
    stride: stbi__uint32 = x * out_n * bytes;
    img_len, img_width_bytes: stbi__uint32
    k: int
    img_n: int = s.img_n; // copy it into a local for later

    output_bytes: int = out_n * bytes
    filter_bytes: int = img_n * bytes
    width: int = cast(int)x

    assert(out_n == s.img_n || out_n == s.img_n + 1)
    a.out = cast([^]stbi_uc)stbi__malloc_mad3(cast(int)x, cast(int)y, cast(int)output_bytes, 0) // extra bytes to write off the end into
    if a.out == nil {
        return stbi__err("outofmem", "Out of memory")
    }

    if !stbi__mad3sizes_valid(img_n, x, depth, 7) do return stbi__err("too large", "Corrupt PNG")
    img_width_bytes = (((img_n * x * depth) + 7) >> 3)
    img_len = (img_width_bytes + 1) * y

    // we used to check for exact match between raw_len and img_len on non-interlaced PNGs,
    // but issue #276 reported a PNG in the wild that had extra data at the end (all zeros),
    // so just check for raw_len < img_len always.
    if raw_len < img_len do return stbi__err("not enough pixels", "Corrupt PNG")

    for j = 0; j < y; j += 1 {
        cur: [^]stbi_uc = a->out[stride*j:]
        prior: [^]stbi_uc
        filter: int = raw[0]
        raw = raw[1:]
        
        if filter > 4 do return stbi__err("invalid filter")
        
        if depth < 8 {
           if img_width_bytes > x do return stbi__err("invalid width")
           cur = cur[x*out_n - img_width_bytes:]// store output to the rightmost img_len bytes, so we can decode in place
           filter_bytes = 1
           width = img_width_bytes
        }
        prior = cur - stride // bugfix: need to compute this after 'cur +=' computation above
       
        // if first row, use special filter that doesn't sample previous row
        if j == 0 do filter = first_row_filter[filter]
       
        // handle first byte explicitly
        for k=0; k < filter_bytes; k += 1 {
           switch filter {
              case STBI__F_none       : cur[k] = raw[k]
              case STBI__F_sub        : cur[k] = raw[k]
              case STBI__F_up         : cur[k] = STBI__BYTECAST(raw[k] + prior[k])
              case STBI__F_avg        : cur[k] = STBI__BYTECAST(raw[k] + (prior[k]>>1))
              case STBI__F_paeth      : cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(0,prior[k],0))
              case STBI__F_avg_first  : cur[k] = raw[k]
              case STBI__F_paeth_first: cur[k] = raw[k]
           }
        }
       
        if depth == 8 {
            if img_n != out_n {
             cur[img_n] = 255 // first pixel
            }  
            raw = raw[img_n:]
            cur = cur[out_n:]
            prior = prior[out_n:]
        } else if depth == 16 {
            if img_n != out_n {
               cur[filter_bytes]   = 255 // first pixel top byte
               cur[filter_bytes+1] = 255 // first pixel bottom byte
            }
            raw = raw[filter_bytes:]
            cur = cur[output_bytes:]
            prior = prior[output_bytes:]
        } else {
            raw = raw[1:]
            cur = cur[1:]
            prior = prior[1:]
        }
       
        // this is a little gross, so that we don't switch per-pixel or per-component
        if depth < 8 || img_n == out_n {
           nk: int = (width - 1)*filter_bytes;
           /*
           #define STBI__CASE(f) \
               case f:     \
                  for (k=0; k < nk; ++k)
           switch (filter) {
              // "none" filter turns into a memcpy here; make that explicit.
              case STBI__F_none:         memcpy(cur, raw, nk); break;
              STBI__CASE(STBI__F_sub)          { cur[k] = STBI__BYTECAST(raw[k] + cur[k-filter_bytes]); } break;
              STBI__CASE(STBI__F_up)           { cur[k] = STBI__BYTECAST(raw[k] + prior[k]); } break;
              STBI__CASE(STBI__F_avg)          { cur[k] = STBI__BYTECAST(raw[k] + ((prior[k] + cur[k-filter_bytes])>>1)); } break;
              STBI__CASE(STBI__F_paeth)        { cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k-filter_bytes],prior[k],prior[k-filter_bytes])); } break;
              STBI__CASE(STBI__F_avg_first)    { cur[k] = STBI__BYTECAST(raw[k] + (cur[k-filter_bytes] >> 1)); } break;
              STBI__CASE(STBI__F_paeth_first)  { cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k-filter_bytes],0,0)); } break;
           }
           #undef STBI__CASE
           */

            switch filter {
                case STBI__F_none: {
                    for k=0; k < nk; k += 1 {
                        memcpy(cur, raw, nk)
                    }
                    
                }
                case STBI__F_sub: {
                    for k=0; k < nk; k += 1 {
                        cur[k] = STBI__BYTECAST(raw[k] + cur[k-filter_bytes])
                    }
                } 
                case STBI__F_up: { 
                    for k=0; k < nk; k += 1 {
                        cur[k] = STBI__BYTECAST(raw[k] + prior[k])
                    }
                } 
                case STBI__F_avg: { 
                    for k=0; k < nk; k += 1 {
                        cur[k] = STBI__BYTECAST(raw[k] + ((prior[k] + cur[k-filter_bytes])>>1)); 
                    }                  
                }
                case STBI__F_paeth: { 
                    for k=0; k < nk; k += 1 {
                        cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k-filter_bytes],prior[k],prior[k-filter_bytes]))
                    }             
                } 
                case STBI__F_avg_first: { 
                    for k=0; k < nk; k += 1 { 
                        cur[k] = STBI__BYTECAST(raw[k] + (cur[k-filter_bytes] >> 1))
                    }  
                } 
                case STBI__F_paeth_first: {
                    for k=0; k < nk; k += 1 {
                        cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k-filter_bytes],0,0))
                    }
                } 
            }
            raw = raw[nk:];
        } else {
           assert(img_n+1 == out_n)
           /*
           #define STBI__CASE(f) \
               case f:     \
                  for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) \
                     for (k=0; k < filter_bytes; ++k)
           switch (filter) {
              STBI__CASE(STBI__F_none)         { cur[k] = raw[k]; } break;
              STBI__CASE(STBI__F_sub)          { cur[k] = STBI__BYTECAST(raw[k] + cur[k- output_bytes]); } break;
              STBI__CASE(STBI__F_up)           { cur[k] = STBI__BYTECAST(raw[k] + prior[k]); } break;
              STBI__CASE(STBI__F_avg)          { cur[k] = STBI__BYTECAST(raw[k] + ((prior[k] + cur[k- output_bytes])>>1)); } break;
              STBI__CASE(STBI__F_paeth)        { cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k- output_bytes],prior[k],prior[k- output_bytes])); } break;
              STBI__CASE(STBI__F_avg_first)    { cur[k] = STBI__BYTECAST(raw[k] + (cur[k- output_bytes] >> 1)); } break;
              STBI__CASE(STBI__F_paeth_first)  { cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k- output_bytes],0,0)); } break;
           }
           #undef STBI__CASE
           */

            switch filter {
                case STBI__F_none: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = raw[k]
                        }
                    }
                }
                case STBI__F_sub: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = STBI__BYTECAST(raw[k] + cur[k- output_bytes])
                        }
                    }
                } 
                case STBI__F_up: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = STBI__BYTECAST(raw[k] + prior[k]) 
                        }
                    }               
                } 
                case STBI__F_avg: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = STBI__BYTECAST(raw[k] + ((prior[k] + cur[k- output_bytes])>>1))
                        }
                    }
                }
                case STBI__F_paeth: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k- output_bytes],prior[k],prior[k- output_bytes]))
                        }
                    }        
                } 
                case STBI__F_avg_first: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = STBI__BYTECAST(raw[k] + (cur[k- output_bytes] >> 1))
                        }
                    }    
                } 
                case STBI__F_paeth_first: { 
                    for i=x-1; i >= 1; {
                        defer {
                            i += 1
                            cur[filter_bytes] = 255
                            raw = raw[filter_bytes:]
                            cur = cur[output_bytes:]
                            prior = prior[output_bytes:]
                        }
                        for k=0; k < filter_bytes; k += 1 {
                            cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k- output_bytes],0,0))
                        }
                    }
                } 
            }

           // the loop above sets the high byte of the pixels' alpha, but for
           // 16 bit png files we also need the low byte set. we'll do that here.
           if depth == 16 {
                cur = a.out[stride*j:] // start at the beginning of the row again
                for i=0; i < x; i += 1 {
                    cur = cur[output_bytes:]
                    cur[filter_bytes+1] = 255
                }
           }
        }
    }

    // we make a separate pass to expand bits to pixels; for performance,
    // this could run two scanlines behind the above code, so it won't
    // intefere with filtering but will still be in the cache.
    if depth < 8 {
        for j=0; j < y; j += 1 {
            cur:  = a.out[stride*j:]
            _in: [^]stbi_uc  = a.out[stride*j + x*out_n - img_width_bytes:]
            // unpack 1/2/4-bit into a 8-bit buffer. allows us to keep the common 8-bit path optimal at minimal cost for 1/2/4-bit
            // png guarante byte alignment, if width is not multiple of 8/4/2 we'll decode dummy trailing data that will be skipped in the later loop
            scale: stbi_uc = (color == 0) ? stbi__depth_scale_table[depth] : 1 // scale grayscale values to 0..255 range

            // note that the final byte might overshoot and write more data than desired.
            // we can allocate enough data that this never writes out of memory, but it
            // could also overwrite the next scanline. can it overwrite non-empty data
            // on the next scanline? yes, consider 1-pixel-wide scanlines with 1-bit-per-pixel.
            // so we need to explicitly clamp the final ones

            if depth == 4 {
                for k=x*img_n; k >= 2; {
                    defer {
                        k -= 2 
                        _in = _in[1:]
                    }
                    cur[0] = scale * ((_in[0] >> 4)       );
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0]     ) & 0x0f); 
                    cur = cur[1:]
                }
                if k > 0 {
                    cur[0] = scale * ((_in[0] >> 4)       )
                    cur = cur[1:]
                }
            } else if depth == 2 {
                for k=x*img_n; k >= 4; {
                    defer {
                        k -= 4 
                        _in = _in[1:]
                    }
                    cur[0] = scale * ((_in[0] >> 6)       )
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 4) & 0x03)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 2) & 0x03)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0]     ) & 0x03)
                    cur = cur[1:]
                }
                if (k > 0) {
                    cur[0] = scale * ((_in[0] >> 6)       )
                    cur = cur[1:]
                }
                if (k > 1) {
                    cur[0] = scale * ((_in[0] >> 4) & 0x03)
                    cur = cur[1:]
                }
                if (k > 2) {
                    cur[0] = scale * ((_in[0] >> 2) & 0x03)
                    cur = cur[1:]
                }
            } else if (depth == 1) {
                for k=x*img_n; k >= 8; {
                    defer {
                        k-=8
                        _in = _in[1:]
                    }
                    cur[0] = scale * ((_in[0] >> 7)       )
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 6) & 0x01)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 5) & 0x01)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 4) & 0x01)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 3) & 0x01)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 2) & 0x01)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0] >> 1) & 0x01)
                    cur = cur[1:]
                    cur[0] = scale * ((_in[0]     ) & 0x01)
                    cur = cur[1:]
                }
                if k > 0 {
                    cur[0] = scale * ((_in[0] >> 7)       )
                    cur = cur[1:]
                }
                if k > 1 {
                    cur[0] = scale * ((_in[0] >> 6) & 0x01)
                    cur = cur[1:]
                }
                if k > 2 {
                    cur[0] = scale * ((_in[0] >> 5) & 0x01)
                    cur = cur[1:] 
                }
                if k > 3 {               
                    cur[0] = scale * ((_in[0] >> 4) & 0x01)
                    cur = cur[1:]
                }
                if k > 4 {               
                    cur[0] = scale * ((_in[0] >> 3) & 0x01)
                    cur = cur[1:]
                }
                if k > 5 {              
                    cur[0] = scale * ((_in[0] >> 2) & 0x01)
                    cur = cur[1:]
                }
                if k > 6 {           
                    cur[0] = scale * ((_in[0] >> 1) & 0x01)
                    cur = cur[1:]
                }
            }
            if img_n != out_n {
                q: int
                // insert alpha = 255
                cur = a.out[stride*j:]
                if img_n == 1 {
                    for q=x-1; q >= 0; q -= 1 { 
                        cur[q*2+1] = 255
                        cur[q*2+0] = cur[q]
                    }
                } else {
                    assert(img_n == 3)
                    for q=x-1; q >= 0; q -= 1 {
                        cur[q*4+3] = 255
                        cur[q*4+2] = cur[q*3+2]
                        cur[q*4+1] = cur[q*3+1]
                        cur[q*4+0] = cur[q*3+0]
                    }
                }
            }
        }
    } else if depth == 16 {
        // force the image data from big-endian to platform-native.
        // this is done in a separate pass due to the decoding relying
        // on the data being untouched, but could probably be done
        // per-line during decode if care is taken.
        cur: [^]stbi_uc = a.out
        cur16: [^]stbi__uint16 = cast([^]stbi__uint16)cur

        for i=0; i < x*y*out_n; {
            defer {
                i += 1
                cur16 = cur16[1:]
                cur = cur[2:]
            }
            cur16[0] = (cur[0] << 8) | cur[1];
        }
    }

    return 1
}

stbi__create_png_image :: proc(a: ^stbi__png, image_data: [^]stbi_uc, image_data_len: stbi__uint32, out_n, depth, color: int, interlaced: bool) -> bool {
    bytes: int = (depth == 16 ? 2 : 1)
    out_bytes: int = out_n * bytes
    final: [^]stbi_uc
    p: int
    if !interlaced do return stbi__create_png_image_raw(a, image_data, image_data_len, out_n, a.s.img_x, a.s.img_y, depth, color)
    

    // de-interlacing
    final = cast([^]stbi_uc)stbi__malloc_mad3(a.s.img_x, a.s.img_y, out_bytes, 0)
    if final == nil do return stbi__err("outofmem", "Out of memory")
    for p=0; p < 7; p += 1 {
        xorig := [?]int { 0,4,0,2,0,1,0 }
        yorig := [?]int { 0,0,4,0,2,0,1 }
        xspc  := [?]int { 8,8,4,4,2,2,1 }
        yspc  := [?]int { 8,8,8,4,4,2,2 }
        i, j, x, y: int
        // pass1_x[4] = 0, pass1_x[5] = 1, pass1_x[12] = 1
        x = (a.s.img_x - xorig[p] + xspc[p]-1) / xspc[p]
        y = (a.s.img_y - yorig[p] + yspc[p]-1) / yspc[p]
        if x != 0 && y != 0 {
            img_len: stbi__uint32 = ((((a.s.img_n * x * depth) + 7) >> 3) + 1) * y;
            if !stbi__create_png_image_raw(a, image_data, image_data_len, out_n, x, y, depth, color) {
               STBI_FREE(final)
               return 0
            }
            for j=0; j < y; j += 1 {
                for i=0; i < x; i += 1 {
                    out_y: int = j*yspc[p]+yorig[p]
                    out_x: int = i*xspc[p]+xorig[p]
                    memcpy(final + out_y*a.s.img_x*out_bytes + out_x*out_bytes,
                           a->out + (j*x+i)*out_bytes, out_bytes)
                }
            }
            STBI_FREE(a.out)
            image_data = image_data[img_len:]
            image_data_len -= img_len
        }
    }
    a.out = final

    return 1;
}

stbi__compute_transparency :: proc(z: ^stbi__png, tc: [3]stbi_uc , out_n: int) -> int {
    s: ^stbi__context = z.s
    i: stbi__uint32
    pixel_count: stbi__uint32 = s.img_x * s.img_y
    p: [^]stbi_uc = z.out;

    // compute color-based transparency, assuming we've
    // already got 255 as the alpha value in the output
    assert(out_n == 2 || out_n == 4)

    if out_n == 2 {
        for i=0; i < pixel_count; i += 1 {
            p[1] = (p[0] == tc[0] ? 0 : 255)
            p = p[2:]
        }
    } else {
        for i=0; i < pixel_count; i += 1 {
            if (p[0] == tc[0] && p[1] == tc[1] && p[2] == tc[2]) {
                p[3] = 0
            }
           
            p = p[4:]
        }
    }
    return 1
}

stbi__compute_transparency16 :: proc(z: ^stbi__png, tc: [3]stbi__uint16, out_n: int) {
    s: ^stbi__context = z.s
    i: stbi__uint32
    pixel_count: stbi__uint32 = s.img_x * s.img_y
    p: [^]stbi__uint16 = cast([^]stbi__uint16) z.out

    // compute color-based transparency, assuming we've
    // already got 65535 as the alpha value in the output
    assert(out_n == 2 || out_n == 4)

    if out_n == 2 {
        for i = 0; i < pixel_count; i += 1 {
            p[1] = (p[0] == tc[0] ? 0 : 65535) 
            p = p[2:]
        }
    } else {
        for i = 0; i < pixel_count; i += 1 {
            if p[0] == tc[0] && p[1] == tc[1] && p[2] == tc[2] {
                p[3] = 0
            }   
            p = p[4:]
        }
    }
    return 1
}

stbi__expand_png_palette :: proc(a: ^stbi__png, palette: [^]stbi_uc, len, pal_img_n: int) -> int
{
    i: stbi__uint32 
    pixel_count: stbi__uint32 = a.s.img_x * a.s.img_y;
    orig: [^]stbi_uc = a->out
    p, temp_out: [^]stbi_uc

    p = cast([^]stbi_uc)stbi__malloc_mad2(cast(int)pixel_count, pal_img_n, 0);
    if p == nil do return stbi__err("outofmem", "Out of memory");

    // between here and free(out) below, exitting would leak
    temp_out = p

    if pal_img_n == 3 {
        for i=0; i < pixel_count; i += 1 {
            n: int = orig[i]*4
            p[0] = palette[n  ]
            p[1] = palette[n+1]
            p[2] = palette[n+2]
            p = p[3:]
        }
    } else {
        for i=0; i < pixel_count; i += 1 {
             n = orig[i]*4
             p[0] = palette[n  ]
             p[1] = palette[n+1]
             p[2] = palette[n+2]
             p[3] = palette[n+3]
             p = p[4:]
        }
    }
    STBI_FREE(a.out)
    a.out = temp_out
    
    //STBI_NOTUSED(len)

    return 1
}

stbi__unpremultiply_on_load_global: int = 0
stbi__de_iphone_flag_global: int = 0

STBI_MAX_DIMENSIONS :: int(1) << 24

stbi_set_unpremultiply_on_load :: proc(flag_true_if_should_unpremultiply: int) {
    stbi__unpremultiply_on_load_global = flag_true_if_should_unpremultiply
}

stbi_convert_iphone_png_to_rgb :: proc(flag_true_if_should_convert: int) {
    stbi__de_iphone_flag_global = flag_true_if_should_convert
}

// Note(dragos): wtf
/*
#ifndef STBI_THREAD_LOCAL
#define stbi__unpremultiply_on_load  stbi__unpremultiply_on_load_global
#define stbi__de_iphone_flag  stbi__de_iphone_flag_global
#else
static STBI_THREAD_LOCAL int stbi__unpremultiply_on_load_local, stbi__unpremultiply_on_load_set;
static STBI_THREAD_LOCAL int stbi__de_iphone_flag_local, stbi__de_iphone_flag_set;

STBIDEF void stbi_set_unpremultiply_on_load_thread(int flag_true_if_should_unpremultiply)
{
   stbi__unpremultiply_on_load_local = flag_true_if_should_unpremultiply;
   stbi__unpremultiply_on_load_set = 1;
}

STBIDEF void stbi_convert_iphone_png_to_rgb_thread(int flag_true_if_should_convert)
{
   stbi__de_iphone_flag_local = flag_true_if_should_convert;
   stbi__de_iphone_flag_set = 1;
}

#define stbi__unpremultiply_on_load  (stbi__unpremultiply_on_load_set           \
                                       ? stbi__unpremultiply_on_load_local      \
                                       : stbi__unpremultiply_on_load_global)
#define stbi__de_iphone_flag  (stbi__de_iphone_flag_set                         \
                                ? stbi__de_iphone_flag_local                    \
                                : stbi__de_iphone_flag_global)
#endif // STBI_THREAD_LOCAL
*/

/*
static void stbi__de_iphone(stbi__png *z)
{
   stbi__context *s = z->s;
   stbi__uint32 i, pixel_count = s->img_x * s->img_y;
   stbi_uc *p = z->out;

   if (s->img_out_n == 3) {  // convert bgr to rgb
      for (i=0; i < pixel_count; ++i) {
         stbi_uc t = p[0];
         p[0] = p[2];
         p[2] = t;
         p += 3;
      }
   } else {
      STBI_ASSERT(s->img_out_n == 4);
      if (stbi__unpremultiply_on_load) {
         // convert bgr to rgb and unpremultiply
         for (i=0; i < pixel_count; ++i) {
            stbi_uc a = p[3];
            stbi_uc t = p[0];
            if (a) {
               stbi_uc half = a / 2;
               p[0] = (p[2] * 255 + half) / a;
               p[1] = (p[1] * 255 + half) / a;
               p[2] = ( t   * 255 + half) / a;
            } else {
               p[0] = p[2];
               p[2] = t;
            }
            p += 4;
         }
      } else {
         // convert bgr to rgb
         for (i=0; i < pixel_count; ++i) {
            stbi_uc t = p[0];
            p[0] = p[2];
            p[2] = t;
            p += 4;
         }
      }
   }
}
*/

STBI__SCAN_load :: 0
STBI__SCAN_type :: 1
STBI__SCAN_header :: 2

//#define STBI__PNG_TYPE(a,b,c,d)  (((unsigned) (a) << 24) + ((unsigned) (b) << 16) + ((unsigned) (c) << 8) + (unsigned) (d))

STBI__PNG_TYPE :: proc(a, b, c, d: rune) -> stbi__uint32 {
    return ((stbi__uint32(a) << 24) + (stbi__uint32(b) << 16) + (stbi__uint32(c) << 8) + stbi__uint32(d))
}
 
stbi__parse_png_file :: proc(z: ^stbi__png, scan: int, req_comp: int) -> bool {
    pal_img_n: stbi_uc = 0
    palette: [1024]stbi_uc
    has_trans: stbi_uc = 0
    tc: [3]stbi_uc
    tc16: [3]stbi__uint16
    ioff, idata_limit, i, pal_len: stbi__uint32
    k, interlace, color, is_iphone: int
    first: int = 1
    s: ^stbi__context = z.s

    z.expanded = nil
    z.idata = nil
    z.out = nil

    if !stbi__check_png_header(s) do return false

    if scan == STBI__SCAN_type do return true

    for {
        c: stbi__pngchunk = stbi__get_chunk_header(s);
        switch c.type {
            case STBI__PNG_TYPE('C','g','B','I'):
                is_iphone = 1 
                stbi__skip(s, c.length)
                
            case STBI__PNG_TYPE('I','H','D','R'): {
                comp, filter: int
                if first == 0 do return stbi__err("multiple IHDR","Corrupt PNG")
                first = 0
                if c.length != 13 do return stbi__err("bad IHDR len","Corrupt PNG")
                s.img_x = stbi__get32be(s)
                s.img_y = stbi__get32be(s)
                if s.img_y > STBI_MAX_DIMENSIONS do return stbi__err("too large","Very large image (corrupt?)");
                if s.img_x > STBI_MAX_DIMENSIONS do return stbi__err("too large","Very large image (corrupt?)");
                z.depth = stbi__get8(s); if z.depth != 1 && z.depth != 2 && z.depth != 4 && z.depth != 8 && z.depth != 16 do return stbi__err("1/2/4/8/16-bit only","PNG not supported: 1/2/4/8/16-bit only");
                color = stbi__get8(s); if color > 6 do return stbi__err("bad ctype","Corrupt PNG");
                if color == 3 && z->depth == 16       do     return stbi__err("bad ctype","Corrupt PNG");
                if color == 3 do pal_img_n = 3; else if color & 1 do return stbi__err("bad ctype","Corrupt PNG");
                comp  = stbi__get8(s);  if comp != 0 do return stbi__err("bad comp method","Corrupt PNG");
                filter= stbi__get8(s);  if filter != 0 do return stbi__err("bad filter method","Corrupt PNG");
                interlace = stbi__get8(s); if interlace>1 do return stbi__err("bad interlace method","Corrupt PNG");
                if s.img_x == 0 || s.img_y == 0 do return stbi__err("0-pixel image","Corrupt PNG");
                if (!pal_img_n) {
                    s.img_n = (color & 2 ? 3 : 1) + (color & 4 ? 1 : 0);
                    if (1 << 30) / s.img_x / s.img_n < s.img_y do return stbi__err("too large", "Image too large to decode");
                } else {
                    // if paletted, then pal_n is our final components, and
                    // img_n is # components to decompress/filter.
                    s.img_n = 1;
                    if (1 << 30) / s.img_x / 4 < s.img_y do return stbi__err("too large","Corrupt PNG");
                }
                // even with SCAN_header, have to scan to see if we have a tRNS
            }
          
            case STBI__PNG_TYPE('P','L','T','E'):  {
                if first != 0 do return stbi__err("first not IHDR", "Corrupt PNG")
                if c.length > 256*3 do return stbi__err("invalid PLTE","Corrupt PNG")
                pal_len = c.length / 3
                if pal_len * 3 != c.length do return stbi__err("invalid PLTE","Corrupt PNG");
                for i=0; i < pal_len; i += 1 {
                   palette[i*4+0] = stbi__get8(s)
                   palette[i*4+1] = stbi__get8(s) 
                   palette[i*4+2] = stbi__get8(s) 
                   palette[i*4+3] = 255
                }
            }
          
            case STBI__PNG_TYPE('t','R','N','S'): {
                if first != 0 do return stbi__err("first not IHDR", "Corrupt PNG")
                if z.idata != nil do return stbi__err("tRNS after IDAT","Corrupt PNG")
                if pal_img_n != 0 {
                    if scan == STBI__SCAN_header { 
                        s->img_n = 4
                        return 1
                    }
                    if pal_len == 0 do return stbi__err("tRNS before PLTE","Corrupt PNG")
                    if c.length > pal_len do return stbi__err("bad tRNS len","Corrupt PNG")
                    pal_img_n = 4
                    for i=0; i < c.length; i += 1 {
                        palette[i*4+3] = stbi__get8(s)
                    }
                       
                } else {
                    if !(s.img_n & 1) do return stbi__err("tRNS with alpha","Corrupt PNG")
                    if c.length != cast(stbi__uint32)s->img_n*2 do return stbi__err("bad tRNS len","Corrupt PNG")
                    has_trans = 1
                    // non-paletted with tRNS = constant alpha. if header-scanning, we can stop now.
                    if scan == STBI__SCAN_header { 
                        s.img_n += 1
                        return 1
                    }
                    if (z.depth == 16) {
                        for k = 0; k < s.img_n; k += 1 do tc16[k] = cast(stbi__uint16)stbi__get16be(s); // copy the values as-is
                    } else {
                        for k = 0; k < s.img_n; k += 1 do tc[k] = cast(stbi_uc)(stbi__get16be(s) & 255) * stbi__depth_scale_table[z->depth]; // non 8-bit images will be larger
                    }
                }
            }
          
            case STBI__PNG_TYPE('I','D','A','T'): {
                if first != 0 do return stbi__err("first not IHDR", "Corrupt PNG");
                if pal_img_n && pal_len == 0 do return stbi__err("no PLTE","Corrupt PNG");
                if scan == STBI__SCAN_header {
                   // header scan definitely stops at first IDAT
                   if (pal_img_n) do s.img_n = pal_img_n 
                   return 1 
                }
                if c.length > (u32(1) << 30) do return stbi__err("IDAT size limit", "IDAT section larger than 2^30 bytes");
                if cast(int)(ioff + c.length) < cast(int)ioff do return 0
                if (ioff + c.length > idata_limit) {
                    idata_limit_old: stbi__uint32 = idata_limit;
                    p: [^]stbi_uc
                    if idata_limit == 0 do idata_limit = c.length > 4096 ? c.length : 4096;
                    for ioff + c.length > idata_limit {
                         idata_limit *= 2;
                    }

                    p = cast([^]stbi_uc)STBI_REALLOC_SIZED(z->idata, idata_limit_old, idata_limit); 
                    if p == nil do return stbi__err("outofmem", "Out of memory");
                    z.idata = p
                }
                if stbi__getn(s, z->idata+ioff,c.length) == 0 do return stbi__err("outofdata","Corrupt PNG");
                ioff += c.length
                break
            }
          
            case STBI__PNG_TYPE('I','E','N','D'): {
                raw_len, bpl: stbi__uint32
                if first != 0 do return stbi__err("first not IHDR", "Corrupt PNG");
                if scan != STBI__SCAN_load do return 1
                if z.idata == nil do return stbi__err("no IDAT","Corrupt PNG");
                // initial guess for decoded data size to avoid unnecessary reallocs
                bpl = (s.img_x * z.depth + 7) / 8; // bytes per line, per component
                raw_len = bpl * s.img_y * s.img_n /* pixels */ + s.img_y /* filter mode per row */;
                // Note(dragos): import core:compress/zlib???
                z.expanded = cast([^]stbi_uc)stbi_zlib_decode_malloc_guesssize_headerflag(cast([^]stbi_uc) z.idata, ioff, raw_len, cast(^int) &raw_len, !is_iphone);
                if z.expanded == nil do return 0; // zlib should set error
                STBI_FREE(z.idata)
                z.idata = nil
                if (req_comp == s.img_n+1 && req_comp != 3 && !pal_img_n) || has_trans {
                    s.img_out_n = s.img_n+1
                } else {
                    s->img_out_n = s->img_n
                }
                   
                if stbi__create_png_image(z, z.expanded, raw_len, s.img_out_n, z.depth, color, interlace) == 0 do return 0
                if has_trans {
                   if (z->depth == 16) {
                      if !stbi__compute_transparency16(z, tc16, s.img_out_n) do return 0;
                   } else {  
                      if !stbi__compute_transparency(z, tc, s.img_out_n) do return 0;
                   }
                }
                if is_iphone && stbi__de_iphone_flag && s->img_out_n > 2 {
                    stbi__de_iphone(z)
                }
                if pal_img_n != 0 {
                    // pal_img_n == 3 or 4
                    s.img_n = pal_img_n // record the actual colors we had
                    s.img_out_n = pal_img_n
                    if req_comp >= 3 do s.img_out_n = req_comp
                    if !stbi__expand_png_palette(z, palette, pal_len, s->img_out_n) {
                        return 0
                    }
                      
                } else if has_trans {
                    // non-paletted image with tRNS -> source image has (constant) alpha
                    s.img_n += 1
                }
                STBI_FREE(z.expanded) 
                z.expanded = nil
                // end of PNG chunk, read and skip CRC
                stbi__get32be(s)
                return 1
            }
          
            case:
                // if critical, fail
                if first do return stbi__err("first not IHDR", "Corrupt PNG");
                if (c.type & (1 << 29)) == 0 {
                    //#ifndef STBI_NO_FAILURE_STRINGS
                    // not threadsafe
                    //static char invalid_chunk[] = "XXXX PNG chunk not known";
                    //invalid_chunk[0] = STBI__BYTECAST(c.type >> 24);
                    //invalid_chunk[1] = STBI__BYTECAST(c.type >> 16);
                    //invalid_chunk[2] = STBI__BYTECAST(c.type >>  8);
                    //invalid_chunk[3] = STBI__BYTECAST(c.type >>  0);
                    //#endif
                    return stbi__err(invalid_chunk, "PNG not supported: unknown PNG chunk type");
                }
                stbi__skip(s, c.length)
                break
        }
        // end of PNG chunk, read and skip CRC
        stbi__get32be(s)
    }
}

stbi__do_png :: proc(p: ^stbi__png, x: ^int, y: ^int, n: ^int, req_comp: int, ri: ^stbi__result_info) -> rawptr {
    result: rawptr
    if req_comp < 0 || req_comp > 4 do return stbi__errpuc("bad req_comp", "Internal error");
    if stbi__parse_png_file(p, STBI__SCAN_load, req_comp) {
        if (p.depth <= 8) {
            ri.bits_per_channel = 8
        } else if (p.depth == 16) {
            ri.bits_per_channel = 16
        } else {
            stbi__errpuc("bad bits_per_channel", "PNG not supported: unsupported color depth")
            return nil
        }   
        result = p.out
        p.out = nil
        if (req_comp && req_comp != p.s.img_out_n) {
            if (ri.bits_per_channel == 8) {
                result = stbi__convert_format(cast([^]stbi_uc)result, p.s.img_out_n, req_comp, p.s.img_x, p.s.img_y);
            } else {
                result = stbi__convert_format16(cast([^]stbi__uint16)result, p.s.img_out_n, req_comp, p.s.img_x, p.s.img_y);
            }
              
            p.s.img_out_n = req_comp;
            if result == nil do return result
        }
        x^ = p.s.img_x;
        y^ = p.s.img_y;
        if n != nil do n^ = p.s.img_n
    }
    STBI_FREE(p.out)    
    p.out      = nil
    STBI_FREE(p.expanded)
    p.expanded = nil
    STBI_FREE(p.idata)   
    p.idata    = nil

    return result
}

stbi__png_load :: proc(s: ^stbi__context, x, y, comp: ^int, req_comp: int, ri: ^stbi__result_info) -> rawptr {
    p: stbi__png 
    p.s = s
    return stbi__do_png(&p, x, y, comp,req_comp, ri)
}
stbi__png_test :: proc(s: ^stbi__context) -> int {
    r: bool
    r = stbi__check_png_header(s)
    stbi__rewind(s)
    return r
}

stbi__png_info_raw :: proc(p: ^stbi__png, x, y, comp: ^int) -> int
{
    if !stbi__parse_png_file(p, STBI__SCAN_header, 0) {
        stbi__rewind( p->s )
        return 0
    }
    if x do x^ = p.s.img_x
    if y do y^ = p.s.img_y
    if comp do comp^ = p.s.img_n
    return 1;
}

stbi__png_info :: proc(s: ^stbi__context, x, y, comp: ^int) -> int
{
    p: stbi__png
    p.s = s
    return stbi__png_info_raw(&p, x, y, comp)
}

stbi__png_is16 :: proc(s: ^stbi__context) -> int
{
    p: stbi__png
    p.s = s;
    if !stbi__png_info_raw(&p, NULL, NULL, NULL) do return 0
    if p.depth != 16 {
       stbi__rewind(p.s)
       return 0
    }
    return 1;
}