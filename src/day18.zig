const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const mag = try addSnailfishNumbers(alloc, input);
    std.debug.print("magnitude {}\n", .{mag});

    const max = try highestMagnitude(alloc, input);
    std.debug.print("max 2-line magnitude {}\n", .{max});
}

fn addSnailfishNumbers(alloc: std.mem.Allocator, input: []const u8) !u64 {
    var lines = std.mem.split(u8, input, "\n");
    var string = std.ArrayList(u8).init(alloc);
    defer string.deinit();

    try string.appendSlice(lines.next().?);

    while (lines.next()) |line| {
        try string.insert(0, '[');
        try string.append(',');
        try string.appendSlice(line);
        try string.append(']');

        while (true) {
            if (findExplodingPair(string.items)) |i| {
                var pairN: [2]u32 = undefined;
                {
                    const pair = string.items[(i[0] + 1)..i[1]];
                    var numbers = std.mem.split(u8, pair, ",");
                    pairN[0] = try std.fmt.parseInt(u32, numbers.next().?, 10);
                    pairN[1] = try std.fmt.parseInt(u32, numbers.next().?, 10);
                    try string.replaceRange(i[0], i[1] - i[0] + 1, "0");
                }

                var zero = i[0];
                var buf: [10]u8 = undefined;

                if (findFirstNumber(string.items[(zero + 1)..])) |f| {
                    const off = zero + 1;
                    const old = (string.items[off..])[f[0]..f[1]];
                    const parsed = try std.fmt.parseInt(u32, old, 10);
                    const slice = try std.fmt.bufPrint(&buf, "{}", .{parsed + pairN[1]});
                    try string.replaceRange(off + f[0], f[1] - f[0], slice);
                }
                if (findLastNumber(string.items[0..(zero - 1)])) |f| {
                    const off = 1; // from iterating backwards?
                    const old = (string.items[off..])[f[0]..f[1]];
                    const parsed = try std.fmt.parseInt(u32, old, 10);
                    const slice = try std.fmt.bufPrint(&buf, "{}", .{parsed + pairN[0]});
                    try string.replaceRange(off + f[0], f[1] - f[0], slice);
                }
            } else if (findSplitNumber(string.items)) |i| {
                const n = try std.fmt.parseInt(u32, string.items[i[0]..i[1]], 10);
                const half = n / 2;
                const odd = n & 1;
                const printed = try std.fmt.allocPrint(alloc, "[{},{}]", .{ half, half + odd });
                defer alloc.free(printed);

                try string.replaceRange(i[0], i[1] - i[0], printed);
            } else break;
        }
    }

    return (try magnitude(string.items))[0];
}

fn magnitude(s: []const u8) std.fmt.ParseIntError![2]usize { // number, len
    var c = s[0];
    if (c == '[') {
        const left = try magnitude(s[1..]);
        const right = try magnitude(s[2 + left[1] ..]);

        const value = (left[0] * 3 + right[0] * 2);
        return [_]usize{ value, 3 + left[1] + right[1] };
    }
    const range = findFirstNumber(s).?;
    const n = try std.fmt.parseInt(usize, s[0..range[1]], 10);
    return [_]usize{ n, range[1] };
}

fn findExplodingPair(s: []const u8) ?[2]usize {
    var nesting: u8 = 0;
    var lastOpen: usize = 0;
    for (s) |c, i| {
        if (c == '[') {
            nesting += 1;
            lastOpen = i;
        } else if (c == ']') {
            if (nesting >= 5) return [2]usize{ lastOpen, i };
            nesting -= 1;
        }
    }
    return null;
}

fn findSplitNumber(s: []const u8) ?[2]usize {
    var firstDigit: ?usize = null;
    for (s) |c, i| {
        if (c >= '0' and c <= '9') {
            if (firstDigit == null) {
                firstDigit = i;
            }
        } else if (firstDigit) |f| {
            if (i - f == 1) {
                firstDigit = null;
            } else {
                return [2]usize{ f, i };
            }
        }
    }
    return null;
}

fn findLastNumber(s: []const u8) ?[2]usize {
    var i = s.len - 1;
    var lastDigit: ?usize = null;
    while (i > 0) : (i -= 1) {
        const c = s[i];
        if (c >= '0' and c <= '9') {
            if (lastDigit == null) {
                lastDigit = i;
            }
        } else if (lastDigit) |l| {
            return [2]usize{ i, l };
        }
    }
    return null;
}

fn findFirstNumber(s: []const u8) ?[2]usize {
    var firstDigit: ?usize = null;
    for (s) |c, i| {
        if (c >= '0' and c <= '9') {
            if (firstDigit == null) {
                firstDigit = i;
            }
        } else if (firstDigit) |f| {
            return [2]usize{ f, i };
        }
    }
    return null;
}

fn highestMagnitude(alloc: std.mem.Allocator, input: []const u8) !usize {
    var buf = std.ArrayList([]const u8).init(alloc);
    defer buf.deinit();

    {
        var lines = std.mem.split(u8, input, "\n");
        while (lines.next()) |line| try buf.append(line);
    }

    var max: usize = 0;
    while (buf.items.len > 1) {
        const last = buf.items[buf.items.len - 1];
        for (buf.items[0..(buf.items.len - 2)]) |other| {
            var combined = try std.fmt.allocPrint(alloc, "{s}\n{s}", .{ last, other });
            defer alloc.free(combined);

            const mag1 = try addSnailfishNumbers(alloc, combined);
            if (mag1 > max) max = mag1;

            const combined2 = try std.fmt.bufPrint(combined, "{s}\n{s}", .{ other, last });

            const mag2 = try addSnailfishNumbers(alloc, combined2);
            if (mag2 > max) max = mag2;
        }
        _ = buf.pop();
    }
    return max;
}

test {
    const input =
        \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
        \\[[[5,[2,8]],4],[5,[[9,9],0]]]
        \\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
        \\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
        \\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
        \\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
        \\[[[[5,4],[7,7]],8],[[8,3],8]]
        \\[[9,3],[[9,9],[6,[4,9]]]]
        \\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
        \\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
    ;

    const result = try addSnailfishNumbers(std.testing.allocator, input);
    try std.testing.expectEqual(result, 4140);

    const result2 = try highestMagnitude(std.testing.allocator, input);
    try std.testing.expectEqual(result2, 3993);
}
