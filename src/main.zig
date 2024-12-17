const std = @import("std");
const http = std.http;
const time = std.time;
const log = std.log;

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

    const public_ip: []const u8 = try get_public_ip(&client, params.get_public_ip_url);
    log.info("got public ip: {s} from {s}", .{ public_ip, params.get_public_ip_url });
    while (true) {
        for (params.list.items) |param| {
            log.info("host: {s} - domain: {s}", .{ param.host, param.domain });
        }
        log.info("iteration finished - going to sleep", .{});
        time.sleep(sleep_time);
    }

    // foreach param make a request to check if ip is the same
}

pub fn get_public_ip(client: *Client, url: []const u8) ![]const u8 {
    const uri = try std.Uri.parse(url);

    var header_buf: [1024]u8 = undefined;

    const options = std.http.Client.RequestOptions{ .server_header_buffer = &header_buf };

    var request = try client.open(std.http.Method.GET, uri, options);
    defer request.deinit();

    try request.send();
    try request.wait();

    var buffer: [11]u8 = undefined;
    var response = request.response;

    if (response.content_length) |len| {
        try response.parse(&buffer); // todo
        return buffer[0..len];
    }
    return error.ResponseWithNoContent;
}
