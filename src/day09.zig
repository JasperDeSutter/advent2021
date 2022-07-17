const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn HeightMap() type {
    return struct {
        rows: std.ArrayList([]const u8),

        fn init(alloc: std.mem.Allocator) @This() {
            return .{ .rows = std.ArrayList([]const u8).init(alloc) };
        }

        fn deinit(self: @This()) void {
            self.rows.deinit();
        }

        fn get(self: *const @This(), x: i32, y: i32) u8 {
            const max = std.math.maxInt(u8);
            if (x < 0 or y < 0) return max;
            if (y >= self.rows.items.len) return max;
            const row = self.rows.items[@intCast(u32, y)];
            if (x >= row.len) return max;
            return row[@intCast(u32, x)];
        }

        fn sumRiskLevel(self: *const @This()) u32 {
            var iter = LowPointsIter{
                .x = -1,
                .y = 0,
                .map = self,
            };
            var sum: u32 = 0;
            while (iter.next()) |it| {
                const val = it - '0' + 1;
                sum += val;
            }
            return sum;
        }

        const LowPointsIter = struct {
            x: i32,
            y: i32,
            map: *const HeightMap(),

            fn next(self: *@This()) ?u8 {
                const map = self.map;
                const row_len = map.rows.items[0].len;
                while (self.y < map.rows.items.len) {
                    self.x += 1;
                    const y = self.y;
                    const x = self.x;
                    if (x >= row_len) {
                        self.x = -1;
                        self.y += 1;
                        continue;
                    }
                    const it = map.get(x, y);
                    if (it < map.get(x - 1, y) and
                        it < map.get(x + 1, y) and
                        it < map.get(x, y - 1) and
                        it < map.get(x, y + 1))
                    {
                        return it;
                    }
                }
                return null;
            }
        };
    };
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result1 = try parseHeightMap(alloc, input);
    defer result1.deinit();
    std.debug.print("risk level: {d}\n", .{result1.sumRiskLevel()});
}

fn parseHeightMap(alloc: std.mem.Allocator, input: []const u8) anyerror!HeightMap() {
    var lines = std.mem.split(u8, input, "\n");
    var height_map = HeightMap().init(alloc);
    while (lines.next()) |line| {
        try height_map.rows.append(line);
    }
    return height_map;
}

test {
    const input =
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
    ;

    const result1 = try parseHeightMap(std.testing.allocator, input);
    defer result1.deinit();
    try std.testing.expectEqual(@intCast(u32, 15), result1.sumRiskLevel());
}
