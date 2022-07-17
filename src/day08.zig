const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try retrieveDigits(input);
    std.debug.print("simple digits: {d}\n", .{result.simple_digit_count});
    std.debug.print("value sum: {d}\n", .{result.values_sum});
}

const Digit = ?[]const u8;

const Solution = struct {
    seven: u8,
    four: u8,

    fn init() @This() {
        return .{ .seven = 0, .four = 0 };
    }

    fn transformDigit(part: []const u8) u8 {
        var bitset = std.bit_set.StaticBitSet(7).initEmpty();
        for (part) |char| {
            bitset.set(char - 'a');
        }
        return bitset.mask;
    }

    fn add_digit(self: *@This(), part: []const u8) void {
        switch (part.len) {
            3 => {
                self.seven = transformDigit(part);
            },
            4 => {
                self.four = transformDigit(part);
            },
            else => {},
        }
    }

    fn getDigit(self: *const @This(), part: []const u8) u8 {
        return switch (part.len) {
            2 => 1,
            3 => 7,
            4 => 4,
            5 => {
                const value = transformDigit(part);
                if ((value & self.seven) == self.seven) return 3;
                return if (@popCount(u8, (value & self.four)) == 2) 2 else 5;
            },
            6 => {
                const value = transformDigit(part);
                if ((value & self.seven) != self.seven) return 6;
                return if ((value & self.four) == self.four) 9 else 0;
            },
            7 => 8,
            else => @panic(part),
        };
    }
};

const Result = struct {
    simple_digit_count: u16,
    values_sum: u32,
};

fn retrieveDigits(input: []const u8) anyerror!Result {
    var result = Result{ .values_sum = 0, .simple_digit_count = 0 };
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const bar = std.mem.indexOf(u8, line, "|").?;
        const solution = b: {
            var solution = Solution.init();
            var parts = std.mem.split(u8, line[0..(bar - 1)], " ");
            while (parts.next()) |part| {
                solution.add_digit(part);
            }
            break :b solution;
        };

        {
            var parts = std.mem.split(u8, line[(bar + 2)..], " ");
            var number: u16 = 0;
            while (parts.next()) |part| {
                const digit = solution.getDigit(part);
                number = number * 10 + digit;

                const simple_digit = switch (digit) {
                    1, 4, 7, 8 => true,
                    else => false,
                };
                if (simple_digit) {
                    result.simple_digit_count += 1;
                }
            }
            result.values_sum += number;
        }
    }
    return result;
}

test {
    const input =
        \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
        \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
        \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
        \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
        \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
        \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
        \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
        \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
        \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
        \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    ;

    const result = try retrieveDigits(input);
    try std.testing.expectEqual(@intCast(u16, 26), result.simple_digit_count);
    try std.testing.expectEqual(@intCast(u32, 61229), result.values_sum);
}
