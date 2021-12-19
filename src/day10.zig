const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: *std.mem.Allocator, input: []const u8) anyerror!void {
    const sytaxError = totalSyntaxError(input);
    std.debug.print("total syntax error: {d}\n", .{sytaxError});
}

fn isClose(char: u8) bool {
    return switch (char) {
        ')', '}', ']', '>' => true,
        else => false,
    };
}

fn firstInvalidChar(copy: *[]const u8) ?u8 {
    var line = copy.*;
    if (line.len < 1) return null;

    const oposite: u8 = switch (line[0]) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',
        else => @panic("unexpected input"),
    };
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

fn totalSyntaxError(input: []const u8) u32 {
    var lines = std.mem.split(u8, input, "\n");

    var total: u32 = 0;
    while (lines.next()) |line| {
        var copy = line;
        const invalid = firstInvalidChar(&copy) orelse continue;
        const points: u32 = switch (invalid) {
            ')' => 3,
            ']' => 57,
            '}' => 1197,
            '>' => 25137,
            else => @panic("unexpected input"),
        };
        total += points;
    }
    return total;
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

    const result1 = totalSyntaxError(input);
    try std.testing.expectEqual(result1, 26397);
}
