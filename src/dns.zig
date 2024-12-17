const std = @import("std");
// todo: actual dns
pub const Header = packed struct {
    id: u16,
    qr: u1,
    op_code: u4,
    aa: u1,
    tc: u1,
    rd: u1,
    ra: u1,
    z: u3,
    rcode: u4,
};
