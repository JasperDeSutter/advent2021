const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const lanternfishes = try reproduceLanternfish(input, 80);
    std.debug.print("lanternfishes: {d}\n", .{lanternfishes});
    const lanternfishes256 = try reproduceLanternfish(input, 256);
    std.debug.print("lanternfishes forever: {d}\n", .{lanternfishes256});
}

const int = u64;

fn reproduceLanternfish(input: []const u8, days: u16) anyerror!int{
    var arr = [_]int{0} ** 9;
    var numbers = std.mem.split(u8, input, ",");
    while (numbers.next()) |number| {
        const i = try std.fmt.parseInt(u8, number, 10);
        arr[i] += 1;
    }
    var birth_queue = [_]int{0} ** 2;
    var iter = utils.range(u16, 0, days - 1);
    while (iter.next()) |it| {
        const i = it % 9;
        arr[(i + 7) % 9] += arr[i];
    }
    var total: int= birth_queue[0] + birth_queue[1];
    var final = utils.iter(int, arr[0..]);
    while (final.next()) |it| {
        total += it.*;
    }
    return total;
}

test {
    const input =
        \\3,4,3,1,2
    ;

    const result1 = try reproduceLanternfish(input, 18);
    try std.testing.expectEqual(@intCast(int, 26), result1);

    const result2 = try reproduceLanternfish(input, 80);
    try std.testing.expectEqual(@intCast(int, 5934), result2);

    const result3 = try reproduceLanternfish(input, 256);
    try std.testing.expectEqual(@intCast(int, 26984457539), result3);
}
