const std = @import("std");
const runner = @import("./runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: *std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try multipliedCoordinate(input);
    std.debug.print("result: {d}\n", .{result});
}

fn multipliedCoordinate(input: []const u8) anyerror!i32 {
    var lines = std.mem.split(u8, input, "\n");

    var depth: i32 = 0;
    var hor_pos: i32 = 0;

    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");
        const direction = parts.next().?;
        const distance = try std.fmt.parseInt(i32, parts.next().?, 10);

        if (std.mem.eql(u8, direction, "down")) {
            depth += distance;
        } else if (std.mem.eql(u8, direction, "up")) {
            depth -= distance;
        } else if (std.mem.eql(u8, direction, "forward")) {
            hor_pos += distance;
        } else {
            @panic("unrecognized input");
        }
    }

    return depth * hor_pos;
}

test {
    const input =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
    ;
    const expected_result: i32 = 150;
    try std.testing.expectEqual(expected_result, try multipliedCoordinate(input));
}
