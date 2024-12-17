const std = @import("std");
const log = std.log;

const c = @cImport({
    @cInclude("netdb.h");
    @cInclude("sys/socket.h");
    @cInclude("arpa/inet.h");
});

pub fn checkIp(endpoint: []const u8, ip: []const u8) !bool {
    var addr_info: [*c]c.addrinfo = undefined;
    const size: isize = c.getaddrinfo(endpoint.ptr, null, null, &addr_info);
    if (size != 0) {
        log.err("getaddrinfo responded with {d}", .{size});
        return error.CouldNotCheckIp;
    }
    defer c.freeaddrinfo(addr_info);

    var curr = addr_info;
    while (true) {
        if (addr_info.*.ai_family == c.AF_INET) {
            const socket_addr: [*c]c.sockaddr_in = @ptrCast(@alignCast(addr_info.*.ai_addr));
            const c_addr: [*c]u8 = c.inet_ntoa(socket_addr.*.sin_addr);
            const addr = std.mem.span(c_addr);

            log.info("comparing {s} == {s}", .{ ip, addr });

            if (std.mem.eql(u8, addr, ip)) {
                return true;
            }
        }
        curr = addr_info.*.ai_next orelse return false;
    }
}

// todo: actual dns implementation
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
