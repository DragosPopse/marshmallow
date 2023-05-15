package mlw_random

import "../../math"

// Adapted "core:math/rand" to support the generic generator

global_generator_impl := Xorshift64{1}
global_generator := xorshift64_generator(&global_generator_impl)

uint32 :: proc(r: ^Generator) -> u32 { 
    return u32(generate(r) % cast(u64)max(u32))
}

uint64 :: proc(r: ^Generator) -> u64 {
	return generate(r)
}

int31  :: proc(r: ^Generator) -> i32  { 
    return i32(uint32(r) << 1 >> 1) 
}

int63  :: proc(r: ^Generator) -> i64  { 
    return i64(uint64(r) << 1 >> 1) 
}

int31_max :: proc(n: i32, r: ^Generator) -> i32 {
	if n <= 0 {
		panic("Invalid argument to int31_max")
	}
	if n & (n - 1) == 0 {
		return int31(r) & (n-1)
	}
	max := i32((1 << 31) - 1 - (1 << 31) % u32(n))
	v := int31(r)
	for v > max {
		v = int31(r)
	}
	return v % n
}

int63_max :: proc(n: i64, r: ^Generator) -> i64 {
	if n <= 0 {
		panic("Invalid argument to int63_max")
	}
	if n&(n-1) == 0 {
		return int63(r) & (n-1)
	}
	max := i64((1<<63) - 1 - (1<<63)%u64(n))
	v := int63(r)
	for v > max {
		v = int63(r)
	}
	return v % n
}

int_max :: proc(n: int, r: ^Generator) -> int {
	if n <= 0 {
		panic("Invalid argument to int_max")
	}
	when size_of(int) == 4 {
		return int(int31_max(i32(n), r))
	} else {
		return int(int63_max(i64(n), r))
	}
}

// Uniform random distribution [0, 1)
double :: proc(r: ^Generator) -> f64 { 
    return f64(int63_max(1<<53, r)) / (1 << 53) 
}

// Uniform random distribution [0, 1)
float :: proc(r: ^Generator) -> f32 { 
    return cast(f32)double(r)
}

double_range :: proc(lo, hi: f64, r: ^Generator) -> f64 { 
    return (hi - lo) * double(r) + lo 
}

float_range :: proc(lo, hi: f32, r: ^Generator) -> f32 { 
    return (hi - lo) * float(r) + lo 
}

int_range :: proc(lo, hi: int, r: ^Generator) -> int {
    lo := cast(f64)lo
    hi := cast(f64)hi
    return int((hi - lo) * double(r) + lo)
}
