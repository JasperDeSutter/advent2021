const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    var repr = try Repr.init(alloc, input);
    defer repr.deinit();
    const paths = try repr.countPathsRecursive(false);
    std.debug.print("paths {}\n", .{paths});
    const pathsWithDouble = try repr.countPathsRecursive(true);
    std.debug.print("paths with double {}\n", .{pathsWithDouble});
}

const Path = struct {
    elems: std.ArrayList(Cave),
    used_double: bool,

    fn init(alloc: std.mem.Allocator, used_double: bool) Path {
        return Path{
            .elems = std.ArrayList(Cave).init(alloc),
            .used_double = used_double,
        };
    }

    fn last(self: *const @This()) Cave {
        return self.elems.items[self.elems.items.len - 1];
    }
};

const Cave = u16;

pub const CaveContext = struct {
    pub fn hash(self: @This(), s: Cave) u64 {
        _ = self;
        return s;
    }
    pub fn eql(self: @This(), a: Cave, b: Cave) bool {
        _ = self;
        return a == b;
    }
};

const CaveMap = std.AutoHashMap(Cave, std.ArrayList(Cave));
const start = 's' << 8;
const end = 'e' << 8;

fn strToCave(str: []const u8) Cave {
    if (std.mem.eql(u8, str, "start")) return start;
    if (std.mem.eql(u8, str, "end")) return end;
    return @intCast(u16, str[0]) << 8 | str[1];
}

const Repr = struct {
    const Self = @This();
    connections: CaveMap,
    alloc: std.mem.Allocator,

    fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        var connections = CaveMap.init(alloc);

        var lines = std.mem.split(u8, input, "\n");
        while (lines.next()) |line| {
            var parts = std.mem.split(u8, line, "-");
            const a = strToCave(parts.next().?);
            const b = strToCave(parts.next().?);

            const aEntry = try connections.getOrPut(a);
            if (!aEntry.found_existing) {
                aEntry.value_ptr.* = std.ArrayList(Cave).init(alloc);
            }
            if (!eql(b, start)) try aEntry.value_ptr.*.append(b);

            const bEntry = try connections.getOrPut(b);
            if (!bEntry.found_existing) {
                bEntry.value_ptr.* = std.ArrayList(Cave).init(alloc);
            }
            if (!eql(a, start)) try bEntry.value_ptr.*.append(a);
        }

        return Self{
            .connections = connections,
            .alloc = alloc,
        };
    }

    fn deinit(self: *Self) void {
        var iter = self.connections.valueIterator();
        while (iter.next()) |it| {
            it.deinit();
        }
        self.connections.clearAndFree();
    }

    fn countPaths(self: *const Self, use_double: bool) !u32 {
        var todo = std.ArrayList(Path).init(self.alloc);
        defer {
            for (todo.items) |item| {
                item.elems.deinit();
            }
            todo.deinit();
        }

        var startP = Path.init(self.alloc, !use_double);
        try startP.elems.append(start);
        try todo.append(startP);
        var paths: u32 = 0;

        while (todo.popOrNull()) |path| {
            defer path.elems.deinit();
            const last = path.last();
            if (eql(last, end)) {
                paths += 1;
                continue;
            }

            const edges = self.connections.get(last).?;
            cand: for (edges.items) |candidate| {
                var used_double = path.used_double;
                if (isLower(candidate)) {
                    for (path.elems.items) |visited| {
                        if (eql(visited, candidate)) {
                            if (used_double) continue :cand;
                            used_double = true;
                            break;
                        }
                    }
                }

                var copy = Path.init(self.alloc, used_double);
                try copy.elems.appendSlice(path.elems.items);
                try copy.elems.append(candidate);

                try todo.append(copy);
            }
        }

        return paths;
    }

    const VisitedSet = std.HashMap(Cave, void, CaveContext, 80);

    fn countPathsRecursive(self: *const Self, use_double: bool) !u32 {
        var visited = VisitedSet.init(self.alloc);
        defer visited.deinit();
        var paths: u32 = 0;
        try self.dfs(start, &visited, &paths, !use_double);
        return paths;
    }

    fn dfs(self: *const Self, cave: Cave, visited: *VisitedSet, paths: *u32, used_double: bool) anyerror!void {
        const edges = self.connections.get(cave).?;
        for (edges.items) |candidate| {
            if (eql(candidate, end)) {
                paths.* += 1;
                continue;
            }
            var used_double2 = false;
            if (visited.contains(candidate)) {
                if (!used_double) {
                    used_double2 = true;
                } else {
                    continue;
                }
            } else if (isLower(candidate)) try visited.put(candidate, {});
            try self.dfs(candidate, visited, paths, used_double or used_double2);
            if (!used_double2) {
                _ = visited.remove(candidate);
            }
        }
    }
};

fn eql(a: Cave, b: Cave) bool {
    return a == b;
}

fn isLower(cave: Cave) bool {
    const c = cave & 255;
    // we don't need to check the whole string
    // for (str) |c| {
    if (c > 'z' or c < 'a') {
        return false;
    }
    // }
    return true;
}

test {
    const input1 =
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
    ;

    var repr = try Repr.init(std.testing.allocator, input1);
    defer repr.deinit();
    try std.testing.expectEqual(repr.countPathsRecursive(false), 19);
    try std.testing.expectEqual(repr.countPathsRecursive(true), 103);
}
