const std = @import("std");
const log = std.log;

const c = @cImport({
    @cInclude("netdb.h");
    @cInclude("sys/socket.h");
    @cInclude("sys/types.h");
    @cInclude("arpa/inet.h");
});

pub const CheckIpError = error{ EndpointDoesntFitInBuffer, GetAddressInfoFailed };

pub fn checkIp(endpoint: []const u8, ip: []const u8) !bool {
    var addr_info: [*c]c.addrinfo = undefined;

    var hints: c.addrinfo = c.addrinfo{};

    const buf_len: comptime_int = 128;

    // deal with possible buff overflow, for now err
    if (endpoint.len >= buf_len) {
        log.err("endpoint does not fit in buffer: ", .{endpoint});
        return CheckIpError.EndpointDoesntFitInBuffer;
    }

    var endpoint_buf: [buf_len]u8 = undefined;
    const endpoint_ptr: [*c]const u8 = try std.fmt.bufPrintZ(&endpoint_buf, "{s}", .{endpoint});
    log.info("ENDPOINT = \"{s}\"", .{endpoint_ptr});

    const code: c_int = c.getaddrinfo(endpoint_ptr, null, &hints, &addr_info);
    if (code != 0) {
        const err = c.gai_strerror(code);
        log.err("getaddrinfo responded with {d} - {s}", .{ code, err });
        return CheckIpError.GetAddressInfoFailed;
    }
    defer c.freeaddrinfo(addr_info);

    var curr = addr_info;
    while (true) {
        if (curr.*.ai_family == c.AF_INET) {
            const socket_addr: [*c]c.sockaddr_in = @ptrCast(@alignCast(curr.*.ai_addr));
            const c_addr: [*c]u8 = c.inet_ntoa(socket_addr.*.sin_addr);
            const addr = std.mem.span(c_addr);

            log.info("comparing {s} == {s}", .{ ip, addr });

            if (std.mem.eql(u8, addr, ip)) {
                return true;
            }
        }
        curr = curr.*.ai_next orelse return false;
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
