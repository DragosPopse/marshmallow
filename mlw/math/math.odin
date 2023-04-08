package mmlow_math


minmax :: proc(val, min, max: $T) -> (min_result, max_result: T) {
    min_result, max_result = min, max
    if val > max do max_result = val
    if val < min do min_result = val
    return min_result, max_result
}