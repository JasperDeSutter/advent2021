const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const freq = try countFrequencies(alloc, input, 10);
    std.debug.print("freq 10: {}\n", .{freq});

    const freq40 = try countFrequencies(alloc, input, 40);
    std.debug.print("freq 40: {}\n", .{freq40});
}

fn hashFn(_: HashMapContext, key: [2]u8) u64 {
    return @intCast(u64, key[0]) << 8 | key[1];
}

fn eqlFn(_: HashMapContext, a: [2]u8, b: [2]u8) bool {
    return a[0] == b[0] and a[1] == b[1];
}

const HashMapContext = struct {
    pub const hash = hashFn;
    pub const eql = eqlFn;
};

fn HashMap(comptime V: type) type {
    return std.HashMap([2]u8, V, HashMapContext, std.hash_map.default_max_load_percentage);
}

fn mapAdd(hm: *HashMap(u64), key: [2]u8, val: u64) !void {
    var res = try hm.getOrPut(key);
    if (res.found_existing) {
        res.value_ptr.* += val;
    } else {
        res.value_ptr.* = val;
    }
}

fn countFrequencies(alloc: std.mem.Allocator, input: []const u8, iterations: u8) anyerror!u64 {
    var iter = std.mem.split(u8, input, "\n");
    const template = iter.next().?;
    _ = iter.next();

    var rules = HashMap([2][2]u8).init(alloc);
    defer rules.deinit();

    while (iter.next()) |item| {
        var iter2 = std.mem.split(u8, item, " ");
        const first = iter2.next().?;
        _ = iter2.next();
        const insert = iter2.next().?;

        try rules.put(.{ first[0], first[1] }, .{ .{ first[0], insert[0] }, .{ insert[0], first[1] } });
    }

    var counts = HashMap(u64).init(alloc);
    defer counts.deinit();

    var templateIter = utils.iter(u8, template);
    var first = templateIter.next().?;
    while (templateIter.next()) |char| {
        try mapAdd(&counts, .{ first.*, char.* }, 1);
        first = char;
    }

    var newCounts = HashMap(u64).init(alloc);
    defer newCounts.deinit();

    var i = iterations;
    while (i > 0) : (i -= 1) {
        var items = counts.iterator();
        while (items.next()) |item| {
            const key = item.key_ptr.*;
            const count = item.value_ptr.*;
            if (rules.get(key)) |rule| {
                try mapAdd(&newCounts, rule[0], count);
                try mapAdd(&newCounts, rule[1], count);
            } else {
                try mapAdd(&newCounts, key, count);
            }
            item.value_ptr.* = 0; // reset for next iteration
        }

        const tmp = newCounts;
        newCounts = counts;
        counts = tmp;
    }

    var letterCounts = [1]u64{0} ** 26;
    // every letter is double except for first and lastof template
    letterCounts[template[0] - 'A'] = 1;
    letterCounts[template[template.len - 1] - 'A'] += 1;

    var valueIter = counts.iterator();
    while (valueIter.next()) |value| {
        const key = value.key_ptr.*;
        const count = value.value_ptr.*;
        letterCounts[key[0] - 'A'] += count;
        letterCounts[key[1] - 'A'] += count;
    }

    var min: u64 = std.math.maxInt(u64);
    var max: u64 = 0;
    for (letterCounts) |count| {
        if (count == 0) continue;
        if (count < min) min = count;
        if (count > max) max = count;
    }
    return max / 2 - min / 2;
}

test {
    const input =
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
    ;

    const result = try countFrequencies(std.testing.allocator, input, 10);
    try std.testing.expectEqual(result, 1588);

    const result40 = try countFrequencies(std.testing.allocator, input, 40);
    try std.testing.expectEqual(result40, 2188189693529);
}
