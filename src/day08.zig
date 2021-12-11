const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: *std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try countSimpleDigits(input);
    std.debug.print("simple digits: {d}\n", .{result});
}

const Digits = [10](?[]const u8);

const Solution = struct {
    digits: Digits,

    const simple_digits = [_]u8{1, 4, 7, 8};
    fn countSimpleDigits(self: *const @This()) u8 {
        var iter = utils.iter(u8, simple_digits[0..]);
        var sum:u8 = 0;
        while (iter.next()) |it| {
            const digit = self.digits[it.*];
            if (digit != null) {
                std.debug.print("{s}\n", .{digit});
                sum += 1;
            }
        }
        return sum;
    }
};

fn countSimpleDigits(input: []const u8) anyerror!u16 {
    var total: u16 = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const bar = std.mem.indexOf(u8, line, "|").?;
        var parts = std.mem.split(u8, line[(bar + 1)..], " ");
        // var digits: Digits = .{null} ** 10;
        while (parts.next()) |part| {
            const digit: ?u8 = switch(part.len) {
                2 => 1,
                3 => 7,
                4 => 4,
                7 => 8,
                else => null,
            };
            if (digit != null) {
                // digits[digit.?] = part;
                total += 1;
            }
        }
        // const solution = Solution { .digits = digits };
        // total += solution.countSimpleDigits();
    }
    return total;
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

    const result1 = try countSimpleDigits(input);
    try std.testing.expectEqual(@intCast(u16, 26), result1);
}
