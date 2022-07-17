const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try bestCrabAlignment(alloc, input);
    std.debug.print("least crab fuel: {d}\n", .{result.med_result});
    std.debug.print("least crab fuel2: {d}\n", .{result.avg_result});
}

const Result = struct {
    avg_result: u64,
    med_result: u64,
};

fn bestCrabAlignment(alloc: std.mem.Allocator, input: []const u8) anyerror!Result {
    var arr = std.ArrayList(u16).init(alloc);
    defer arr.deinit();
    var numbers = std.mem.split(u8, input, ",");
    var sum: u64 = 0;
    while (numbers.next()) |it| {
        const num = try std.fmt.parseInt(u16, it, 10);
        try arr.append(num);
        sum += num;
    }
    const avg1 = sum / arr.items.len;
    const avg2 = avg1 + 1;

    std.sort.sort(u16, arr.items, {}, comptime std.sort.asc(u16));
    var median = arr.items[arr.items.len / 2];
    if (arr.items.len % 2 == 0) {
        median = (median + arr.items[(arr.items.len - 1) / 2]) / 2;
    }

    var iter = utils.iter(u16, arr.items);
    var med_result: u64 = 0;
    var avg_result1: u64 = 0;
    var avg_result2: u64 = 0;
    while (iter.next()) |num| {
        med_result += std.math.max(num.*, median) - std.math.min(num.*, median);
        const diff1 = std.math.max(num.*, avg1) - std.math.min(num.*, avg1);
        avg_result1 += ((diff1 + 1) * diff1) / 2;
        const diff2 = std.math.max(num.*, avg2) - std.math.min(num.*, avg2);
        avg_result2 += ((diff2 + 1) * diff2) / 2;
    }

    return Result{
        .avg_result = std.math.min(avg_result1, avg_result2),
        .med_result = med_result,
    };
}

test {
    const input =
        \\16,1,2,0,4,2,7,1,2,14
    ;

    const result1 = try bestCrabAlignment(std.testing.allocator, input);
    try std.testing.expectEqual(@intCast(u64, 37), result1.med_result);
    try std.testing.expectEqual(@intCast(u64, 168), result1.avg_result);
}
