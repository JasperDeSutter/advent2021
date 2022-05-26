const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: *std.mem.Allocator, input: []const u8) anyerror!void {
    const paths = try countPaths(alloc, input);
    std.debug.print("paths {}\n", .{ paths });
}

fn countPaths(alloc: *std.mem.Allocator, input: []const u8) !u32 {
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
        (try aEntry.value_ptr.*.addOne()).* = b;
        
        const bEntry = try connections.getOrPut(b);
        if (!bEntry.found_existing) {
            bEntry.value_ptr.* = std.ArrayList([]const u8).init(alloc);
        }
        (try bEntry.value_ptr.*.addOne()).* = a;
    }

    var todo = std.ArrayList(std.ArrayList([]const u8)).init(alloc);
    defer {
        for (todo.items) |item| {
            item.deinit();
        }
        todo.deinit();
    }

    var start = std.ArrayList([]const u8).init(alloc);
    try start.append("start");
    try todo.append(start);
    var paths: u32 = 0;

    while (todo.popOrNull()) |path| {
        defer path.deinit();
        const last = path.items[path.items.len - 1];
        if (std.mem.eql(u8, last, "end")) {
            paths += 1;
            continue;
        }

        const edges = connections.get(last).?;
        cand: for (edges.items) |candidate| {
            if (isLower(candidate)) {
                 for (path.items) |visited| {
                    if (std.mem.eql(u8, visited, candidate)) {
                        continue :cand;
                    }
                }
            }
            
            var copy = std.ArrayList([]const u8).init(alloc);
            try copy.appendSlice(path.items);
            try copy.append(candidate);

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

    try std.testing.expectEqual(countPaths(std.testing.allocator, input1), 10);
}
