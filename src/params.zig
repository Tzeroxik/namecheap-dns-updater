const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const process = std.process;
const mem = std.mem;

pub const ParamError = error{ NoParamsFound, MissingApiKey, MissingHost, MissingDomain, MissingGetPublicIpUrl };

pub const Params = struct {
    allocator: Allocator,
    list: ArrayListUnmanaged(Param),
    get_public_ip_url: []const u8,

    pub fn initFromArgs(allocator: Allocator) !Params {
        var args_iter = try process.argsWithAllocator(allocator);
        defer args_iter.deinit();

        _ = args_iter.skip();

        const get_pub_ip_url_arg = args_iter.next() orelse return ParamError.MissingGetPublicIpUrl;

        var params = try Params.init(allocator, get_pub_ip_url_arg);
        errdefer params.deinit();

        while (args_iter.next()) |arg| {
            var values = mem.tokenizeAny(u8, arg, ",");
            const api_key = values.next() orelse return ParamError.MissingApiKey;
            const host = values.next() orelse return ParamError.MissingHost;
            const domain = values.next() orelse return ParamError.MissingDomain;
            try params.addParam(api_key, domain, host);
        }
        return params;
    }

    pub fn init(alloc: Allocator, get_pub_ip_url: []const u8) !Params {
        return Params{
            .allocator = alloc,
            .list = try std.ArrayListUnmanaged(Param).initCapacity(alloc, 1),
            .get_public_ip_url = try alloc.dupe(u8, get_pub_ip_url),
        };
    }

    pub fn deinit(self: *Params) void {
        const a = self.allocator;

        a.free(self.get_public_ip_url);

        for (self.list.items) |param| {
            a.free(param.key);
            a.free(param.domain);
            a.free(param.host);
        }

        self.list.deinit(a);
    }

    fn addParam(self: *Params, key: []const u8, domain: []const u8, host: []const u8) !void {
        const param = Param{
            .key = try self.allocator.dupe(u8, key),
            .host = try self.allocator.dupe(u8, host),
            .domain = try self.allocator.dupe(u8, domain),
        };

        try self.list.append(self.allocator, param);
    }
};

pub const Param = struct {
    key: []const u8,
    domain: []const u8,
    host: []const u8,
};
