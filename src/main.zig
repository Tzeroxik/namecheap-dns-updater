const std = @import("std");
const http = std.http;
const time = std.time;
const log = std.log;
const dns = @import("dns.zig");

const Allocator = std.mem.Allocator;
const Client = std.http.Client;
const Params = @import("params.zig").Params;

const sleep_time = 5 * time.ns_per_min;

// -- format: api_key,@,domain.com
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == std.heap.Check.leak) {
        std.log.err("deinited allocator with leaks", .{});
    };

    const allocator = gpa.allocator();

    var params = try Params.initFromArgs(allocator);
    defer params.deinit();

    var client = Client{ .allocator = allocator };
    defer client.deinit();

    var pub_ip_buf: [12]u8 = undefined;
    const size = try get_public_ip(&client, params.get_public_ip_url, &pub_ip_buf);
    const public_ip: []const u8 = pub_ip_buf[0..size];

    log.info("got public ip: \"{s}\" from {s}", .{ public_ip, params.get_public_ip_url });
    while (true) {
        for (params.list.items) |param| {
            log.info("host: {s} - domain: {s}", .{ param.host, param.domain });

            const parts = switch (param.host[0]) {
                '@', '.' => ([_][]const u8{param.domain})[0..],
                else => ([_][]const u8{ param.host, ".", param.domain })[0..],
            };

            const endpoint = try std.mem.join(allocator, "", parts);
            {
                defer allocator.free(endpoint);
                const is_same_ip = try dns.checkIp(endpoint, public_ip);

                if (!is_same_ip) {
                    log.info("updating IP to {s}", .{public_ip});
                    try update_ip(allocator, public_ip);
                } else {
                    log.info("IP already up to date", .{});
                }
            }
        }
        log.info("iteration finished - going to sleep", .{});
        time.sleep(sleep_time);
    }

    // foreach param make a request to check if ip is the same
}

pub fn update_ip(_: Allocator, _: []const u8) !void {}

pub fn get_public_ip(client: *Client, url: []const u8, buffer: []u8) !u64 {
    const uri = try std.Uri.parse(url);

    var header_buf: [1024]u8 = undefined;

    const options = std.http.Client.RequestOptions{ .server_header_buffer = &header_buf };

    var request = try client.open(std.http.Method.GET, uri, options);
    defer request.deinit();

    try request.send();

    try request.wait();

    return try request.readAll(buffer);
}
