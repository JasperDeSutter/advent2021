const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result1 = numberOfIncrements(1, input);
    std.debug.print("result 1: {}\n", .{result1});

    const result3 = numberOfIncrements(3, input);
    std.debug.print("result 3: {}\n", .{result3});
}

const int = u16;

fn numberOfIncrements(comptime window: usize, input: []const u8) anyerror!int {
    var lines = std.mem.split(u8, input, "\n");
    var last: [window]int = undefined;

    var init: usize = 0;
    while (init < window) : (init += 1) {
        const line = lines.next().?;
        last[init] = try std.fmt.parseInt(int, line, 10);
    }

    var increments: int = 0;
    var index: usize = 0;
    while (lines.next()) |line| {
        const next = try std.fmt.parseInt(int, line, 10);
        if (next > last[index]) {
            increments += 1;
        }
        last[index] = next;
        index = (index + 1) % window;
    }
    return increments;
}

test {
    const input =
        \\199
        \\200
        \\208
        \\210
        \\200
        \\207
        \\240
        \\269
        \\260
        \\263
    ;

    const result1 = try numberOfIncrements(1, input);
    try std.testing.expectEqual(@intCast(int, 7), result1);

    const result3 = try numberOfIncrements(3, input);
    try std.testing.expectEqual(@intCast(int, 5), result3);
}
