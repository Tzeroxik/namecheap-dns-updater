const std = @import("std");
const Allocator = std.mem.Allocator;
const process = std.process;

// -- format: api_key,@,domain.com
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer gpa.deinit();

    const allocator = gpa.allocator();
    var args = try process.argsWithAllocator(allocator); // deinit after copy

    if (!args.skip()) {
        return error.NoArgumentsFound;
    }

    var params = try Params.init(allocator);
    while (args.next()) |arg| {}
    defer params.deinit();
}

const Params = struct {
    allocator: Allocator,
    list: std.ArrayListUnmanaged(Param),

    pub fn init(alloc: Allocator) !Params {
        return Params{ .allocator = alloc, .list = std.ArrayListUnmanaged().initCapacity(alloc, 1) };
    }

    pub fn deinit(self: *Params) void {
        const alloc = self.allocator;
        const list = self.list;
        for (list.items) |value| {
            alloc.free(value.domain);
            alloc.free(value.key);
            alloc.free(value.host);
        }

        list.deinit(alloc);
    }

    fn addParam(self: *Params, key: []u8, domain: []u8, host: []u8) !void {
        const alloc = self.allocator;

        const key_alloc = try alloc.alloc(u8, key.len);
        @memcpy(key_alloc, key);

        const domain_alloc = try alloc.alloc(u8, domain.len);
        @memcpy(domain_alloc, domain);

        const host_alloc = try alloc.alloc(u8, host.len);
        @memcpy(host_alloc, host);

        const param = Param{
            .key = key_alloc,
            .host = host_alloc,
            .domain = domain_alloc,
        };
        self.list.append(self.allocator, param);
    }
};

const Param = struct {
    key: []u8,
    domain: []u8,
    host: []u8,
};
