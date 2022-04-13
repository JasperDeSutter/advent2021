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

fn isClose(char: u8) bool {
    return switch (char) {
        ')', '}', ']', '>' => true,
        else => false,
    };
}

fn opositeChar(char: u8) u8 {
    return switch (char) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',
        ')' => '(',
        ']' => '[',
        '}' => '{',
        '>' => '<',
        else => @panic("unexpected input"),
    };
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
            const points: u64 = switch (char) {
                '(' => 1,
                '[' => 2,
                '{' => 3,
                '<' => 4,
                else => @panic("unexpected input"),
            };
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
            const points: u64 = switch (invalid) {
                ')' => 3,
                ']' => 57,
                '}' => 1197,
                '>' => 25137,
                else => @panic("unexpected input"),
            };
            totalError += points;
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
