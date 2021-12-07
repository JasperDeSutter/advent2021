const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");
pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: *std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try bingo(alloc, input);
    std.debug.print("first bingo score: {d}\n", .{result[0]});
    std.debug.print("last bingo score: {d}\n", .{result[1]});
}

fn Board(comptime El: type) type {
    return struct {
        rows: [5][5]El,

        fn init(comptime value: El) @This() {
            return .{ .rows = [1][5]El{[_]El{value} ** 5} ** 5 };
        }

        fn find(this: *const @This(), needle: El) ?[2]usize {
            var rows = utils.enumerate(utils.iter([5]El, this.rows[0..]));
            while (rows.next()) |row| {
                var cols = utils.enumerate(utils.iter(El, row.left));
                while (cols.next()) |col| {
                    if (col.left.* == needle) return [_]usize{ col.right, row.right };
                }
            }
            return null;
        }

        fn checkRow(this: *const @This(), row: usize, value: El) bool {
            var cols = utils.range(0, 5 - 1);
            while (cols.next()) |col| {
                if (this.rows[row][col] != value) {
                    return false;
                }
            }
            return true;
        }

        fn checkCol(this: *const @This(), col: usize, value: El) bool {
            var rows = utils.iter([5]El, this.rows[0..]);
            while (rows.next()) |row| {
                if (row[col] != value) {
                    return false;
                }
            }
            return true;
        }

        fn sumUnmarked(this: *const @This(), markers: *const Board(bool)) usize {
            var rows = utils.zip(
                utils.iter([5]El, this.rows[0..]),
                utils.iter([5]bool, markers.rows[0..]),
            );
            var sum: usize = 0;
            while (rows.next()) |row| {
                var cols = utils.zip(utils.iter(El, row.left), utils.iter(bool, row.right));
                while (cols.next()) |col| {
                    if (!col.right.*) {
                        sum += col.left.*;
                    }
                }
            }
            return sum;
        }
    };
}

fn bingo(alloc: *std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var lines = std.mem.split(u8, input, "\n");

    var numbers_arr = std.ArrayList(u8).init(alloc);
    defer numbers_arr.deinit();
    {
        const numbers_line = lines.next().?;
        var numbers = std.mem.split(u8, numbers_line, ",");
        while (numbers.next()) |number| {
            const parsed = try std.fmt.parseInt(u8, number, 10);
            try numbers_arr.append(parsed);
        }
    }

    var first_idx: usize = std.math.maxInt(usize);
    var first_value: usize = 0;
    var last_idx: usize = 0;
    var last_value: usize = 0;
    while (lines.next()) |_| {
        var board = Board(u8).init(0);
        var range = utils.zip(utils.range(0, 5 - 1), utils.ref(&lines));
        while (range.next()) |line| {
            var numbers = utils.enumerate(std.mem.tokenize(u8, line.right, " "));

            while (numbers.next()) |n| {
                const number = try std.fmt.parseInt(u8, n.left, 10);
                board.rows[line.left][n.right] = number;
            }
        }

        var markers = Board(bool).init(false);

        var picks = utils.enumerate(utils.iter(u8, numbers_arr.items));
        while (picks.next()) |pick| {
            const position = board.find(pick.left.*) orelse continue;
            markers.rows[position[1]][position[0]] = true;
            if (markers.checkRow(position[1], true) or markers.checkCol(position[0], true)) {
                if (pick.right < first_idx) {
                    first_idx = pick.right;
                    first_value = @intCast(usize, pick.left.*) * board.sumUnmarked(&markers);
                }
                if (pick.right > last_idx) {
                    last_idx = pick.right;
                    last_value = @intCast(usize, pick.left.*) * board.sumUnmarked(&markers);
                }
                // std.debug.print("{d} {d} {d} {d}\n", .{ pick.left.*, first_value, pick.right, position });
                break;
            }
        }
    }
    return [_]usize{ first_value, last_value };
}

test {
    const input =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
    ;
    const result = try bingo(std.testing.allocator, input);
    try std.testing.expectEqual(result[0], 4512);
    try std.testing.expectEqual(result[1], 1924);
}
