package mlw_core

Ref_Type :: struct($T: typeid) {
    ref: ^T,
}

Value_Or_Ref :: union($T: typeid) {
    Ref_Type(T),
    T,
}

value_or_ref_ptr :: #force_inline proc(v: ^Value_Or_Ref($T)) -> ^T {
    switch var in &v {
        case Ref_Type(T): return var.ref
        case T: return &var
    }
    return nil
}

ref :: #force_inline proc(v: ^$T) -> (res: Value_Or_Ref(T)) {
    return Ref_Type(T){v}
}