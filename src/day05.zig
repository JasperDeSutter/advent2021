const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result1 = try overlappingLineCount(input, false);
    std.debug.print("result1: {d}\n", .{result1});
    const result2 = try overlappingLineCount(input, true);
    std.debug.print("result2: {d}\n", .{result2});
}

fn coord(part: []const u8) anyerror![2]u16 {
    var parts = std.mem.split(u8, part, ",");
    return [_]u16{
        try std.fmt.parseInt(u16, parts.next().?, 10),
        try std.fmt.parseInt(u16, parts.next().?, 10),
    };
}
fn overlappingLineCount(input: []const u8, diagonals: bool) anyerror!usize {
    var lines = std.mem.split(u8, input, "\n");
    var board = [_][1000]u8{[_]u8{0} ** 1000} ** 1000;
    while (lines.next()) |line| {
        const arrow_i = std.mem.indexOf(u8, line, "->").?;
        const first_part = try coord(line[0 .. arrow_i - 1]);
        const second_part = try coord(line[arrow_i + 3 ..]);
        var rows = utils.range(u16, first_part[1], second_part[1]);
        var cols = utils.range(u16, first_part[0], second_part[0]);

        if (first_part[0] == second_part[0]) {
            var iter = utils.zip(rows, utils.repeat(first_part[0]));
            while (iter.next()) |it| board[it.left][it.right] += 1;
        } else if (first_part[1] == second_part[1]) {
            var iter = utils.zip(utils.repeat(first_part[1]), cols);
            while (iter.next()) |it| board[it.left][it.right] += 1;
        } else if (diagonals) {
            var iter = utils.zip(rows, cols);
            while (iter.next()) |it| board[it.left][it.right] += 1;
        }
    }
    {
        var sum: usize = 0;
        var rows = utils.iter([1000]u8, board[0..]);
        while (rows.next()) |row| {
            var cols = utils.iter(u8, row);
            while (cols.next()) |item| {
                if (item.* > 1) sum += 1;
            }
        }
        return sum;
    }
}

test {
    const input =
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
    ;

    const result1 = try overlappingLineCount(input, false);
    try std.testing.expectEqual(@intCast(usize, 5), result1);
    const result2 = try overlappingLineCount(input, true);
    try std.testing.expectEqual(@intCast(usize, 12), result2);
}
