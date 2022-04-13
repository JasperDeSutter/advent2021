const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: *std.mem.Allocator, input: []const u8) anyerror!void {
    const result = totalSyntaxErrorAndMiddleScore(alloc, input);
    std.debug.print("total syntax error: {d}\n", .{result[0]});
    std.debug.print("autocomplete score: {d}\n", .{result[1]});
}

const CharConfig = struct {
    open: u8,
    close: u8,
    illegalPoints: u64,
    autocompletePoints: u64,
};

const config = [_]CharConfig{
    CharConfig{ .open = '(', .close = ')', .illegalPoints = 3, .autocompletePoints = 1 },
    CharConfig{ .open = '[', .close = ']', .illegalPoints = 57, .autocompletePoints = 2 },
    CharConfig{ .open = '{', .close = '}', .illegalPoints = 1197, .autocompletePoints = 3 },
    CharConfig{ .open = '<', .close = '>', .illegalPoints = 25137, .autocompletePoints = 4 },
};

fn isClose(char: u8) bool {
    inline for (config) |c| {
        if (char == c.close) return true;
    }
    return false;
}

fn opositeChar(char: u8) u8 {
    inline for (config) |c| {
        if (char == c.close) return c.open;
        if (char == c.open) return c.close;
    }
    @panic("unexpected input");
}

fn firstInvalidChar(copy: *[]const u8) ?u8 {
    var line = copy.*;
    if (line.len < 1) return null;

    const oposite = opositeChar(line[0]);
    line = line[1..];

    while (line.len > 0) {
        const first = line[0];
        if (isClose(first)) {
            if (first != oposite) return first;
            line = line[1..];
            break;
        }
        if (firstInvalidChar(&line)) |invalid| return invalid;
    }
    copy.* = line;
    return null;
}

fn autocompleteLine(line: []const u8) u64 {
    var score: u64 = 0;
    var i = line.len - 1;
    while (i < std.math.maxInt(u64)) : (i -%= 1) {
        const char = line[i];
        if (isClose(char)) {
            var matches: u8 = 1;
            const oposite = opositeChar(char);
            i -= 1;
            while (i < std.math.maxInt(u64)) : (i -%= 1) {
                const char2 = line[i];
                if (char2 == char) {
                    matches += 1;
                }
                if (char2 == oposite) {
                    matches -= 1;
                    if (matches == 0) {
                        break;
                    }
                }
            }
        } else {
            var points: u64 = 0;
            inline for (config) |c| {
                if (c.open == char) points = c.autocompletePoints;
            }
            score = score * 5 + points;
        }
    }
    return score;
}

fn totalSyntaxErrorAndMiddleScore(alloc: *std.mem.Allocator, input: []const u8) [2]u64 {
    var lines = std.mem.split(u8, input, "\n");
    var scores = std.ArrayList(u64).init(alloc);
    defer scores.deinit();

    var totalError: u64 = 0;
    while (lines.next()) |line| {
        var copy = line;
        if (firstInvalidChar(&copy)) |invalid| {
            inline for (config) |c| {
                if (c.close == invalid) totalError += c.illegalPoints;
            }
        } else {
            const score = autocompleteLine(line);
            scores.append(score) catch @panic("oom");
        }
    }

    std.sort.sort(u64, scores.items, {}, comptime std.sort.asc(u64));
    const middle = scores.items[scores.items.len / 2];

    return .{ totalError, middle };
}

test {
    const input =
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
    ;

    const result = totalSyntaxErrorAndMiddleScore(std.testing.allocator, input);
    try std.testing.expectEqual(result[0], 26397);
    try std.testing.expectEqual(result[1], 288957);
}
