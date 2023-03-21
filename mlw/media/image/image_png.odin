package mlw_media_image

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

stbi__check_png_header :: proc(s: ^stbi__context) -> int {
    png_sig := [8]stbi_uc { 137,80,78,71,13,10,26,10 }
    for i := 0; i < 8; i += 1 {
        if (stbi__get8(s) != png_sig[i]) {
            return stbi__err("Not a PNG")
        }
    }
       
    return 1
}

stbi__png :: struct {
    s: stbi__context,
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
stbi__create_png_image_raw :: proc(a: ^stbi__png, raw: [^]stbi_uc, raw_len: stbi__uint32, out_n: int, x: stbi__uint32, y: stbi__uint32, depth: int, color: int) -> int {
    bytes: int = (depth == 16 ? 2 : 1)
    s: ^stbi__context = a.s
    i, j: stbi__uint32
    stride: stbi__uint32 = x * out_n * bytes;
    img_len, img_width_bytes: stbi__uint32
    k: int
    img_n: int = s.img_n; // copy it into a local for later

    output_bytes: int = out_n * bytes
    filter_bytes: int = img_n * bytes
    width: int = x

    assert(out_n == s.img_n || out_n == s.img_n + 1)
    a.out = cast([^]stbi_uc)stbi__malloc_mad3(x, y, output_bytes, 0) // extra bytes to write off the end into
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
                    cur[k] = raw[k]
                }
                case STBI__F_sub: { 
                    cur[k] = STBI__BYTECAST(raw[k] + cur[k- output_bytes])
                } 
                case STBI__F_up:         { cur[k] = STBI__BYTECAST(raw[k] + prior[k]); } break;
                case STBI__F_avg:         { cur[k] = STBI__BYTECAST(raw[k] + ((prior[k] + cur[k- output_bytes])>>1)); } break;
                case STBI__F_paeth:       { cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k- output_bytes],prior[k],prior[k- output_bytes])); } break;
                case STBI__F_avg_first:    { cur[k] = STBI__BYTECAST(raw[k] + (cur[k- output_bytes] >> 1)); } break;
                case STBI__F_paeth_first:  { cur[k] = STBI__BYTECAST(raw[k] + stbi__paeth(cur[k- output_bytes],0,0)); } break;
            }

           // the loop above sets the high byte of the pixels' alpha, but for
           // 16 bit png files we also need the low byte set. we'll do that here.
           if (depth == 16) {
              cur = a->out + stride*j; // start at the beginning of the row again
              for (i=0; i < x; ++i,cur+=output_bytes) {
                 cur[filter_bytes+1] = 255;
              }
           }
        }
    }

    // we make a separate pass to expand bits to pixels; for performance,
    // this could run two scanlines behind the above code, so it won't
    // intefere with filtering but will still be in the cache.
    if (depth < 8) {
       for (j=0; j < y; ++j) {
          stbi_uc *cur = a->out + stride*j;
          stbi_uc *in  = a->out + stride*j + x*out_n - img_width_bytes;
          // unpack 1/2/4-bit into a 8-bit buffer. allows us to keep the common 8-bit path optimal at minimal cost for 1/2/4-bit
          // png guarante byte alignment, if width is not multiple of 8/4/2 we'll decode dummy trailing data that will be skipped in the later loop
          stbi_uc scale = (color == 0) ? stbi__depth_scale_table[depth] : 1; // scale grayscale values to 0..255 range

          // note that the final byte might overshoot and write more data than desired.
          // we can allocate enough data that this never writes out of memory, but it
          // could also overwrite the next scanline. can it overwrite non-empty data
          // on the next scanline? yes, consider 1-pixel-wide scanlines with 1-bit-per-pixel.
          // so we need to explicitly clamp the final ones

          if (depth == 4) {
             for (k=x*img_n; k >= 2; k-=2, ++in) {
                *cur++ = scale * ((*in >> 4)       );
                *cur++ = scale * ((*in     ) & 0x0f);
             }
             if (k > 0) *cur++ = scale * ((*in >> 4)       );
          } else if (depth == 2) {
             for (k=x*img_n; k >= 4; k-=4, ++in) {
                *cur++ = scale * ((*in >> 6)       );
                *cur++ = scale * ((*in >> 4) & 0x03);
                *cur++ = scale * ((*in >> 2) & 0x03);
                *cur++ = scale * ((*in     ) & 0x03);
             }
             if (k > 0) *cur++ = scale * ((*in >> 6)       );
             if (k > 1) *cur++ = scale * ((*in >> 4) & 0x03);
             if (k > 2) *cur++ = scale * ((*in >> 2) & 0x03);
          } else if (depth == 1) {
             for (k=x*img_n; k >= 8; k-=8, ++in) {
                *cur++ = scale * ((*in >> 7)       );
                *cur++ = scale * ((*in >> 6) & 0x01);
                *cur++ = scale * ((*in >> 5) & 0x01);
                *cur++ = scale * ((*in >> 4) & 0x01);
                *cur++ = scale * ((*in >> 3) & 0x01);
                *cur++ = scale * ((*in >> 2) & 0x01);
                *cur++ = scale * ((*in >> 1) & 0x01);
                *cur++ = scale * ((*in     ) & 0x01);
             }
             if (k > 0) *cur++ = scale * ((*in >> 7)       );
             if (k > 1) *cur++ = scale * ((*in >> 6) & 0x01);
             if (k > 2) *cur++ = scale * ((*in >> 5) & 0x01);
             if (k > 3) *cur++ = scale * ((*in >> 4) & 0x01);
             if (k > 4) *cur++ = scale * ((*in >> 3) & 0x01);
             if (k > 5) *cur++ = scale * ((*in >> 2) & 0x01);
             if (k > 6) *cur++ = scale * ((*in >> 1) & 0x01);
          }
          if (img_n != out_n) {
             int q;
             // insert alpha = 255
             cur = a->out + stride*j;
             if (img_n == 1) {
                for (q=x-1; q >= 0; --q) {
                   cur[q*2+1] = 255;
                   cur[q*2+0] = cur[q];
                }
             } else {
                STBI_ASSERT(img_n == 3);
                for (q=x-1; q >= 0; --q) {
                   cur[q*4+3] = 255;
                   cur[q*4+2] = cur[q*3+2];
                   cur[q*4+1] = cur[q*3+1];
                   cur[q*4+0] = cur[q*3+0];
                }
             }
          }
       }
    } else if (depth == 16) {
       // force the image data from big-endian to platform-native.
       // this is done in a separate pass due to the decoding relying
       // on the data being untouched, but could probably be done
       // per-line during decode if care is taken.
       stbi_uc *cur = a->out;
       stbi__uint16 *cur16 = (stbi__uint16*)cur;

       for(i=0; i < x*y*out_n; ++i,cur16++,cur+=2) {
          *cur16 = (cur[0] << 8) | cur[1];
       }
    }

    return 1;
}

static int stbi__create_png_image(stbi__png *a, stbi_uc *image_data, stbi__uint32 image_data_len, int out_n, int depth, int color, int interlaced)
{
   int bytes = (depth == 16 ? 2 : 1);
   int out_bytes = out_n * bytes;
   stbi_uc *final;
   int p;
   if (!interlaced)
      return stbi__create_png_image_raw(a, image_data, image_data_len, out_n, a->s->img_x, a->s->img_y, depth, color);

   // de-interlacing
   final = (stbi_uc *) stbi__malloc_mad3(a->s->img_x, a->s->img_y, out_bytes, 0);
   if (!final) return stbi__err("outofmem", "Out of memory");
   for (p=0; p < 7; ++p) {
      int xorig[] = { 0,4,0,2,0,1,0 };
      int yorig[] = { 0,0,4,0,2,0,1 };
      int xspc[]  = { 8,8,4,4,2,2,1 };
      int yspc[]  = { 8,8,8,4,4,2,2 };
      int i,j,x,y;
      // pass1_x[4] = 0, pass1_x[5] = 1, pass1_x[12] = 1
      x = (a->s->img_x - xorig[p] + xspc[p]-1) / xspc[p];
      y = (a->s->img_y - yorig[p] + yspc[p]-1) / yspc[p];
      if (x && y) {
         stbi__uint32 img_len = ((((a->s->img_n * x * depth) + 7) >> 3) + 1) * y;
         if (!stbi__create_png_image_raw(a, image_data, image_data_len, out_n, x, y, depth, color)) {
            STBI_FREE(final);
            return 0;
         }
         for (j=0; j < y; ++j) {
            for (i=0; i < x; ++i) {
               int out_y = j*yspc[p]+yorig[p];
               int out_x = i*xspc[p]+xorig[p];
               memcpy(final + out_y*a->s->img_x*out_bytes + out_x*out_bytes,
                      a->out + (j*x+i)*out_bytes, out_bytes);
            }
         }
         STBI_FREE(a->out);
         image_data += img_len;
         image_data_len -= img_len;
      }
   }
   a->out = final;

   return 1;
}

static int stbi__compute_transparency(stbi__png *z, stbi_uc tc[3], int out_n)
{
   stbi__context *s = z->s;
   stbi__uint32 i, pixel_count = s->img_x * s->img_y;
   stbi_uc *p = z->out;

   // compute color-based transparency, assuming we've
   // already got 255 as the alpha value in the output
   STBI_ASSERT(out_n == 2 || out_n == 4);

   if (out_n == 2) {
      for (i=0; i < pixel_count; ++i) {
         p[1] = (p[0] == tc[0] ? 0 : 255);
         p += 2;
      }
   } else {
      for (i=0; i < pixel_count; ++i) {
         if (p[0] == tc[0] && p[1] == tc[1] && p[2] == tc[2])
            p[3] = 0;
         p += 4;
      }
   }
   return 1;
}

static int stbi__compute_transparency16(stbi__png *z, stbi__uint16 tc[3], int out_n)
{
   stbi__context *s = z->s;
   stbi__uint32 i, pixel_count = s->img_x * s->img_y;
   stbi__uint16 *p = (stbi__uint16*) z->out;

   // compute color-based transparency, assuming we've
   // already got 65535 as the alpha value in the output
   STBI_ASSERT(out_n == 2 || out_n == 4);

   if (out_n == 2) {
      for (i = 0; i < pixel_count; ++i) {
         p[1] = (p[0] == tc[0] ? 0 : 65535);
         p += 2;
      }
   } else {
      for (i = 0; i < pixel_count; ++i) {
         if (p[0] == tc[0] && p[1] == tc[1] && p[2] == tc[2])
            p[3] = 0;
         p += 4;
      }
   }
   return 1;
}

static int stbi__expand_png_palette(stbi__png *a, stbi_uc *palette, int len, int pal_img_n)
{
   stbi__uint32 i, pixel_count = a->s->img_x * a->s->img_y;
   stbi_uc *p, *temp_out, *orig = a->out;

   p = (stbi_uc *) stbi__malloc_mad2(pixel_count, pal_img_n, 0);
   if (p == NULL) return stbi__err("outofmem", "Out of memory");

   // between here and free(out) below, exitting would leak
   temp_out = p;

   if (pal_img_n == 3) {
      for (i=0; i < pixel_count; ++i) {
         int n = orig[i]*4;
         p[0] = palette[n  ];
         p[1] = palette[n+1];
         p[2] = palette[n+2];
         p += 3;
      }
   } else {
      for (i=0; i < pixel_count; ++i) {
         int n = orig[i]*4;
         p[0] = palette[n  ];
         p[1] = palette[n+1];
         p[2] = palette[n+2];
         p[3] = palette[n+3];
         p += 4;
      }
   }
   STBI_FREE(a->out);
   a->out = temp_out;

   STBI_NOTUSED(len);

   return 1;
}

static int stbi__unpremultiply_on_load_global = 0;
static int stbi__de_iphone_flag_global = 0;

STBIDEF void stbi_set_unpremultiply_on_load(int flag_true_if_should_unpremultiply)
{
   stbi__unpremultiply_on_load_global = flag_true_if_should_unpremultiply;
}

STBIDEF void stbi_convert_iphone_png_to_rgb(int flag_true_if_should_convert)
{
   stbi__de_iphone_flag_global = flag_true_if_should_convert;
}

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

#define STBI__PNG_TYPE(a,b,c,d)  (((unsigned) (a) << 24) + ((unsigned) (b) << 16) + ((unsigned) (c) << 8) + (unsigned) (d))

static int stbi__parse_png_file(stbi__png *z, int scan, int req_comp)
{
   stbi_uc palette[1024], pal_img_n=0;
   stbi_uc has_trans=0, tc[3]={0};
   stbi__uint16 tc16[3];
   stbi__uint32 ioff=0, idata_limit=0, i, pal_len=0;
   int first=1,k,interlace=0, color=0, is_iphone=0;
   stbi__context *s = z->s;

   z->expanded = NULL;
   z->idata = NULL;
   z->out = NULL;

   if (!stbi__check_png_header(s)) return 0;

   if (scan == STBI__SCAN_type) return 1;

   for (;;) {
      stbi__pngchunk c = stbi__get_chunk_header(s);
      switch (c.type) {
         case STBI__PNG_TYPE('C','g','B','I'):
            is_iphone = 1;
            stbi__skip(s, c.length);
            break;
         case STBI__PNG_TYPE('I','H','D','R'): {
            int comp,filter;
            if (!first) return stbi__err("multiple IHDR","Corrupt PNG");
            first = 0;
            if (c.length != 13) return stbi__err("bad IHDR len","Corrupt PNG");
            s->img_x = stbi__get32be(s);
            s->img_y = stbi__get32be(s);
            if (s->img_y > STBI_MAX_DIMENSIONS) return stbi__err("too large","Very large image (corrupt?)");
            if (s->img_x > STBI_MAX_DIMENSIONS) return stbi__err("too large","Very large image (corrupt?)");
            z->depth = stbi__get8(s);  if (z->depth != 1 && z->depth != 2 && z->depth != 4 && z->depth != 8 && z->depth != 16)  return stbi__err("1/2/4/8/16-bit only","PNG not supported: 1/2/4/8/16-bit only");
            color = stbi__get8(s);  if (color > 6)         return stbi__err("bad ctype","Corrupt PNG");
            if (color == 3 && z->depth == 16)                  return stbi__err("bad ctype","Corrupt PNG");
            if (color == 3) pal_img_n = 3; else if (color & 1) return stbi__err("bad ctype","Corrupt PNG");
            comp  = stbi__get8(s);  if (comp) return stbi__err("bad comp method","Corrupt PNG");
            filter= stbi__get8(s);  if (filter) return stbi__err("bad filter method","Corrupt PNG");
            interlace = stbi__get8(s); if (interlace>1) return stbi__err("bad interlace method","Corrupt PNG");
            if (!s->img_x || !s->img_y) return stbi__err("0-pixel image","Corrupt PNG");
            if (!pal_img_n) {
               s->img_n = (color & 2 ? 3 : 1) + (color & 4 ? 1 : 0);
               if ((1 << 30) / s->img_x / s->img_n < s->img_y) return stbi__err("too large", "Image too large to decode");
            } else {
               // if paletted, then pal_n is our final components, and
               // img_n is # components to decompress/filter.
               s->img_n = 1;
               if ((1 << 30) / s->img_x / 4 < s->img_y) return stbi__err("too large","Corrupt PNG");
            }
            // even with SCAN_header, have to scan to see if we have a tRNS
            break;
         }

         case STBI__PNG_TYPE('P','L','T','E'):  {
            if (first) return stbi__err("first not IHDR", "Corrupt PNG");
            if (c.length > 256*3) return stbi__err("invalid PLTE","Corrupt PNG");
            pal_len = c.length / 3;
            if (pal_len * 3 != c.length) return stbi__err("invalid PLTE","Corrupt PNG");
            for (i=0; i < pal_len; ++i) {
               palette[i*4+0] = stbi__get8(s);
               palette[i*4+1] = stbi__get8(s);
               palette[i*4+2] = stbi__get8(s);
               palette[i*4+3] = 255;
            }
            break;
         }

         case STBI__PNG_TYPE('t','R','N','S'): {
            if (first) return stbi__err("first not IHDR", "Corrupt PNG");
            if (z->idata) return stbi__err("tRNS after IDAT","Corrupt PNG");
            if (pal_img_n) {
               if (scan == STBI__SCAN_header) { s->img_n = 4; return 1; }
               if (pal_len == 0) return stbi__err("tRNS before PLTE","Corrupt PNG");
               if (c.length > pal_len) return stbi__err("bad tRNS len","Corrupt PNG");
               pal_img_n = 4;
               for (i=0; i < c.length; ++i)
                  palette[i*4+3] = stbi__get8(s);
            } else {
               if (!(s->img_n & 1)) return stbi__err("tRNS with alpha","Corrupt PNG");
               if (c.length != (stbi__uint32) s->img_n*2) return stbi__err("bad tRNS len","Corrupt PNG");
               has_trans = 1;
               // non-paletted with tRNS = constant alpha. if header-scanning, we can stop now.
               if (scan == STBI__SCAN_header) { ++s->img_n; return 1; }
               if (z->depth == 16) {
                  for (k = 0; k < s->img_n; ++k) tc16[k] = (stbi__uint16)stbi__get16be(s); // copy the values as-is
               } else {
                  for (k = 0; k < s->img_n; ++k) tc[k] = (stbi_uc)(stbi__get16be(s) & 255) * stbi__depth_scale_table[z->depth]; // non 8-bit images will be larger
               }
            }
            break;
         }

         case STBI__PNG_TYPE('I','D','A','T'): {
            if (first) return stbi__err("first not IHDR", "Corrupt PNG");
            if (pal_img_n && !pal_len) return stbi__err("no PLTE","Corrupt PNG");
            if (scan == STBI__SCAN_header) {
               // header scan definitely stops at first IDAT
               if (pal_img_n)
                  s->img_n = pal_img_n;
               return 1;
            }
            if (c.length > (1u << 30)) return stbi__err("IDAT size limit", "IDAT section larger than 2^30 bytes");
            if ((int)(ioff + c.length) < (int)ioff) return 0;
            if (ioff + c.length > idata_limit) {
               stbi__uint32 idata_limit_old = idata_limit;
               stbi_uc *p;
               if (idata_limit == 0) idata_limit = c.length > 4096 ? c.length : 4096;
               while (ioff + c.length > idata_limit)
                  idata_limit *= 2;
               STBI_NOTUSED(idata_limit_old);
               p = (stbi_uc *) STBI_REALLOC_SIZED(z->idata, idata_limit_old, idata_limit); if (p == NULL) return stbi__err("outofmem", "Out of memory");
               z->idata = p;
            }
            if (!stbi__getn(s, z->idata+ioff,c.length)) return stbi__err("outofdata","Corrupt PNG");
            ioff += c.length;
            break;
         }

         case STBI__PNG_TYPE('I','E','N','D'): {
            stbi__uint32 raw_len, bpl;
            if (first) return stbi__err("first not IHDR", "Corrupt PNG");
            if (scan != STBI__SCAN_load) return 1;
            if (z->idata == NULL) return stbi__err("no IDAT","Corrupt PNG");
            // initial guess for decoded data size to avoid unnecessary reallocs
            bpl = (s->img_x * z->depth + 7) / 8; // bytes per line, per component
            raw_len = bpl * s->img_y * s->img_n /* pixels */ + s->img_y /* filter mode per row */;
            z->expanded = (stbi_uc *) stbi_zlib_decode_malloc_guesssize_headerflag((char *) z->idata, ioff, raw_len, (int *) &raw_len, !is_iphone);
            if (z->expanded == NULL) return 0; // zlib should set error
            STBI_FREE(z->idata); z->idata = NULL;
            if ((req_comp == s->img_n+1 && req_comp != 3 && !pal_img_n) || has_trans)
               s->img_out_n = s->img_n+1;
            else
               s->img_out_n = s->img_n;
            if (!stbi__create_png_image(z, z->expanded, raw_len, s->img_out_n, z->depth, color, interlace)) return 0;
            if (has_trans) {
               if (z->depth == 16) {
                  if (!stbi__compute_transparency16(z, tc16, s->img_out_n)) return 0;
               } else {
                  if (!stbi__compute_transparency(z, tc, s->img_out_n)) return 0;
               }
            }
            if (is_iphone && stbi__de_iphone_flag && s->img_out_n > 2)
               stbi__de_iphone(z);
            if (pal_img_n) {
               // pal_img_n == 3 or 4
               s->img_n = pal_img_n; // record the actual colors we had
               s->img_out_n = pal_img_n;
               if (req_comp >= 3) s->img_out_n = req_comp;
               if (!stbi__expand_png_palette(z, palette, pal_len, s->img_out_n))
                  return 0;
            } else if (has_trans) {
               // non-paletted image with tRNS -> source image has (constant) alpha
               ++s->img_n;
            }
            STBI_FREE(z->expanded); z->expanded = NULL;
            // end of PNG chunk, read and skip CRC
            stbi__get32be(s);
            return 1;
         }

         default:
            // if critical, fail
            if (first) return stbi__err("first not IHDR", "Corrupt PNG");
            if ((c.type & (1 << 29)) == 0) {
               #ifndef STBI_NO_FAILURE_STRINGS
               // not threadsafe
               static char invalid_chunk[] = "XXXX PNG chunk not known";
               invalid_chunk[0] = STBI__BYTECAST(c.type >> 24);
               invalid_chunk[1] = STBI__BYTECAST(c.type >> 16);
               invalid_chunk[2] = STBI__BYTECAST(c.type >>  8);
               invalid_chunk[3] = STBI__BYTECAST(c.type >>  0);
               #endif
               return stbi__err(invalid_chunk, "PNG not supported: unknown PNG chunk type");
            }
            stbi__skip(s, c.length);
            break;
      }
      // end of PNG chunk, read and skip CRC
      stbi__get32be(s);
   }
}

static void *stbi__do_png(stbi__png *p, int *x, int *y, int *n, int req_comp, stbi__result_info *ri)
{
   void *result=NULL;
   if (req_comp < 0 || req_comp > 4) return stbi__errpuc("bad req_comp", "Internal error");
   if (stbi__parse_png_file(p, STBI__SCAN_load, req_comp)) {
      if (p->depth <= 8)
         ri->bits_per_channel = 8;
      else if (p->depth == 16)
         ri->bits_per_channel = 16;
      else
         return stbi__errpuc("bad bits_per_channel", "PNG not supported: unsupported color depth");
      result = p->out;
      p->out = NULL;
      if (req_comp && req_comp != p->s->img_out_n) {
         if (ri->bits_per_channel == 8)
            result = stbi__convert_format((unsigned char *) result, p->s->img_out_n, req_comp, p->s->img_x, p->s->img_y);
         else
            result = stbi__convert_format16((stbi__uint16 *) result, p->s->img_out_n, req_comp, p->s->img_x, p->s->img_y);
         p->s->img_out_n = req_comp;
         if (result == NULL) return result;
      }
      *x = p->s->img_x;
      *y = p->s->img_y;
      if (n) *n = p->s->img_n;
   }
   STBI_FREE(p->out);      p->out      = NULL;
   STBI_FREE(p->expanded); p->expanded = NULL;
   STBI_FREE(p->idata);    p->idata    = NULL;

   return result;
}

static void *stbi__png_load(stbi__context *s, int *x, int *y, int *comp, int req_comp, stbi__result_info *ri)
{
   stbi__png p;
   p.s = s;
   return stbi__do_png(&p, x,y,comp,req_comp, ri);
}

static int stbi__png_test(stbi__context *s)
{
   int r;
   r = stbi__check_png_header(s);
   stbi__rewind(s);
   return r;
}

static int stbi__png_info_raw(stbi__png *p, int *x, int *y, int *comp)
{
   if (!stbi__parse_png_file(p, STBI__SCAN_header, 0)) {
      stbi__rewind( p->s );
      return 0;
   }
   if (x) *x = p->s->img_x;
   if (y) *y = p->s->img_y;
   if (comp) *comp = p->s->img_n;
   return 1;
}

static int stbi__png_info(stbi__context *s, int *x, int *y, int *comp)
{
   stbi__png p;
   p.s = s;
   return stbi__png_info_raw(&p, x, y, comp);
}

static int stbi__png_is16(stbi__context *s)
{
   stbi__png p;
   p.s = s;
   if (!stbi__png_info_raw(&p, NULL, NULL, NULL))
	   return 0;
   if (p.depth != 16) {
      stbi__rewind(p.s);
      return 0;
   }
   return 1;
}