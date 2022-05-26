const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: *std.mem.Allocator, input: []const u8) anyerror!void {
    const paths = try countPaths(alloc, input, false);
    std.debug.print("paths {}\n", .{paths});
    const pathsWithDouble = try countPaths(alloc, input, true);
    std.debug.print("paths with double {}\n", .{pathsWithDouble});
}

const Path = struct {
    elems: std.ArrayList([]const u8),
    used_double: bool,

    fn init(alloc: *std.mem.Allocator, used_double: bool) Path {
        return Path{
            .elems = std.ArrayList([]const u8).init(alloc),
            .used_double = used_double,
        };
    }

    fn last(self: *const @This()) []const u8 {
        return self.elems.items[self.elems.items.len - 1];
    }
};

fn countPaths(alloc: *std.mem.Allocator, input: []const u8, use_double: bool) !u32 {
    var lines = std.mem.split(u8, input, "\n");
    var connections = std.StringHashMap(std.ArrayList([]const u8)).init(alloc);
    defer {
        var iter = connections.valueIterator();
        while (iter.next()) |it| {
            it.deinit();
        }
        connections.clearAndFree();
    }

    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, "-");
        const a = parts.next().?;
        const b = parts.next().?;

        const aEntry = try connections.getOrPut(a);
        if (!aEntry.found_existing) {
            aEntry.value_ptr.* = std.ArrayList([]const u8).init(alloc);
        }
        if (!std.mem.eql(u8, b, "start")) try aEntry.value_ptr.*.append(b);

        const bEntry = try connections.getOrPut(b);
        if (!bEntry.found_existing) {
            bEntry.value_ptr.* = std.ArrayList([]const u8).init(alloc);
        }
        if (!std.mem.eql(u8, a, "start")) try bEntry.value_ptr.*.append(a);
    }

    var todo = std.ArrayList(Path).init(alloc);
    defer {
        for (todo.items) |item| {
            item.elems.deinit();
        }
        todo.deinit();
    }

    var start = Path.init(alloc, !use_double);
    try start.elems.append("start");
    try todo.append(start);
    var paths: u32 = 0;

    while (todo.popOrNull()) |path| {
        defer path.elems.deinit();
        const last = path.last();
        if (std.mem.eql(u8, last, "end")) {
            paths += 1;
            continue;
        }

        const edges = connections.get(last).?;
        cand: for (edges.items) |candidate| {
            var used_double = path.used_double;
            if (isLower(candidate)) {
                for (path.elems.items) |visited| {
                    if (std.mem.eql(u8, visited, candidate)) {
                        if (used_double) continue :cand;
                        used_double = true;
                        break;
                    }
                }
            }

            var copy = Path.init(alloc, used_double);
            try copy.elems.appendSlice(path.elems.items);
            try copy.elems.append(candidate);

            try todo.append(copy);
        }
    }

    return paths;
}

fn isLower(str: []const u8) bool {
    for (str) |c| {
        if (c > 'z' or c < 'a') {
            return false;
        }
    }
    return true;
}

test {
    const input1 =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
    ;

    try std.testing.expectEqual(countPaths(std.testing.allocator, input1, false), 10);
    try std.testing.expectEqual(countPaths(std.testing.allocator, input1, true), 36);
}
