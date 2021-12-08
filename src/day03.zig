const std = @import("std");
const runner = @import("./runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: *std.mem.Allocator, input: []const u8) anyerror!void {
    const diagnostics = try Diagnostics(12).new(alloc, input);
    defer diagnostics.deinit();
    std.debug.print("powerConsumption: {d}\n", .{diagnostics.powerConsumption()});

    std.debug.print("lifeSupportRating: {d}\n", .{diagnostics.lifeSupportRating()});
}

fn Diagnostics(comptime len: comptime_int) type {
    const int = std.meta.Int(.unsigned, len);
    const intMul = std.meta.Int(.unsigned, len * 2);
    const Arr = std.ArrayList(int);

    return struct {
        gamma: int,
        arr: Arr,

        fn deinit(self: @This()) void {
            self.arr.deinit();
        }

        fn new(alloc: *std.mem.Allocator, input: []const u8) anyerror!@This() {
            var lines = std.mem.split(u8, input, "\n");
            var arr = try Arr.initCapacity(alloc, (input.len + 1) / (len / 1));
            var slots = [_]i16{0} ** len;

            while (lines.next()) |line| {
                const num = try std.fmt.parseInt(int, line, 2);
                try arr.append(num);

                var i: usize = 0;
                while (i < len) : (i += 1) {
                    var slot = &slots[i];
                    switch (line[i]) {
                        '0' => slot.* -= 1,
                        '1' => slot.* += 1,
                        else => @panic("unrecognized bit"),
                    }
                }
            }

            var gamma: int = 0;
            {
                var i: std.math.Log2Int(int) = 0;
                while (i < len) : (i += 1) {
                    const one: int = 1;
                    const i_inv = len - 1 - i;
                    if (slots[i] >= 0) {
                        gamma = gamma | (one << i_inv);
                    }
                }
            }

            return @This(){
                .gamma = gamma,
                .arr = arr,
            };
        }

        fn powerConsumption(self: *const @This()) intMul {
            const epsilon = ~self.gamma;
            return @intCast(intMul, self.gamma) * epsilon;
        }

        fn findFirstOne(items: []int, mask: int) usize {
            var left: usize = 0;
            var right: usize = items.len;

            if (items.len < 4) {
                var i: usize = 0;
                while (i < items.len) : (i += 1) {
                    if ((items[i] & mask) != 0) {
                        return i;
                    }
                }
                return 0;
            }

            // binary search
            while (left < right) {
                const mid = left + (right - left) / 2;

                if ((items[mid - 1] & mask) == 0) {
                    // we need the 0->1 edge
                    if ((items[mid] & mask) != 0) {
                        return mid;
                    } else {
                        left = mid + 1;
                    }
                } else {
                    right = mid;
                }
            }

            return 0;
        }

        fn findRating(self: *const @This(), most: bool) int {
            var items = self.arr.items;

            var i: std.math.Log2Int(int) = 0;
            while (i < len) : (i += 1) {
                const one: int = 1;
                const i_inv = len - 1 - i;
                const mask = (one << i_inv);

                const mid = items.len / 2;

                const first_one = findFirstOne(items, mask);
                if ((first_one > mid) == most) {
                    items = items[0..first_one];
                } else {
                    items = items[first_one..];
                }

                if (items.len < 2) return items[0];
            }

            return 0;
        }

        fn lifeSupportRating(self: *const @This()) anyerror!intMul {
            std.sort.sort(int, self.arr.items, {}, comptime std.sort.asc(int));

            const oxygen = self.findRating(true);
            const co2 = self.findRating(false);

            return @intCast(intMul, oxygen) * co2;
        }
    };
}

test {
    const input =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;

    const diagnostics = try Diagnostics(5).new(std.testing.allocator, input);
    defer diagnostics.deinit();
    const expectedPowerConsumption: u10 = 198;
    try std.testing.expectEqual(expectedPowerConsumption, diagnostics.powerConsumption());

    const expectedLifeSupportRating: u10 = 230;
    try std.testing.expectEqual(expectedLifeSupportRating, try diagnostics.lifeSupportRating());
}
