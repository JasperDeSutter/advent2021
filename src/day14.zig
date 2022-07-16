const std = @import("std");
const runner = @import("./runner.zig");
const utils = @import("./utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: *std.mem.Allocator, input: []const u8) anyerror!void {
    const freq = try countFrequencies(alloc, input, 10);
    std.debug.print("freq {}\n", .{freq});
}

fn countFrequencies(alloc: *std.mem.Allocator, input: []const u8, iterations: u8) anyerror!u32 {
    var iter = std.mem.split(u8, input, "\n");
    const template = iter.next().?;
    _ = iter.next();

    var rules = std.AutoHashMap([2]u8, u8).init(alloc);
    defer rules.deinit();

    while (iter.next()) |item| {
        var iter2 = std.mem.split(u8, item, " ");
        const first = iter2.next().?;
        _ = iter2.next();
        const insert = iter2.next().?;

        try rules.put(.{ first[0], first[1] }, insert[0]);
    }

    const Node = std.SinglyLinkedList(u8).Node;
    var start = Node{ .next = null, .data = 0 };
    defer {
        var next = start.next;
        while (next) |n| {
            next = n.next;
            alloc.destroy(n);
        }
    }

    var counts = [1]u32{0} ** 26;

    var lastNode: *Node = &start;
    for (template) |char| {
        const node = try alloc.create(Node);
        node.*.data = char;
        counts[char - 'A'] += 1;
        Node.insertAfter(lastNode, node);
        lastNode = node;
    }

    var rem: u8 = iterations;
    while (rem > 0) : (rem -= 1) {
        var node = &start;
        while (node.next) |next| {
            if (rules.get(.{ node.data, next.data })) |val| {
                const new = try alloc.create(Node);
                new.*.data = val;
                Node.insertAfter(node, new);

                counts[val - 'A'] += 1;
            }
            node = next;
        }
    }

    var min: u32 = std.math.maxInt(u32);
    var max: u32 = 0;
    for (counts) |count| {
        if (count == 0) continue;
        if (count < min) min = count;
        if (count > max) max = count;
    }
    return max - min;
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
}
