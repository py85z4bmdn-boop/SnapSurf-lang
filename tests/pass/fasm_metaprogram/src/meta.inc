macro emit_byte value {
    db value
}

struc pair first, second {
    .lo db first
    .hi db second
}
