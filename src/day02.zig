const std = @import("std");
const runner = @import("./runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: *std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try multipliedCoordinate(input, false);
    std.debug.print("result: {d}\n", .{result});
    const result_correct = try multipliedCoordinate(input, true);
    std.debug.print("correct result: {d}\n", .{result_correct});
}

fn multipliedCoordinate(input: []const u8, aim_correct: bool) anyerror!i32 {
    var lines = std.mem.split(u8, input, "\n");

    var aim: i32 = 0;
    var hor_pos: i32 = 0;
    var depth: i32 = 0;

    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");
        const direction = parts.next().?;
        const distance = try std.fmt.parseInt(i32, parts.next().?, 10);

        if (std.mem.eql(u8, direction, "down")) {
            aim += distance;
        } else if (std.mem.eql(u8, direction, "up")) {
            aim -= distance;
        } else if (std.mem.eql(u8, direction, "forward")) {
            depth += aim * distance;
            hor_pos += distance;
        } else {
            @panic("unrecognized input");
        }
    }
    if (aim_correct) {
        return depth * hor_pos;
    } else {
        return aim * hor_pos;
    }
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
    try std.testing.expectEqual(expected_result, try multipliedCoordinate(input, false));

    const expected_correct_result: i32 = 900;
    try std.testing.expectEqual(expected_correct_result, try multipliedCoordinate(input, true));
}
