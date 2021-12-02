const std = @import("std");

pub fn main() anyerror!void {
    std.debug.print("hello\n", .{});
}

fn numberOfIncrements(input: []const u8) anyerror!u16 {
    var lines = std.mem.split(u8, input, "\n");
    var last = @intCast(u16, std.math.maxInt(u16));
    var increments: u16 = 0;
    while (lines.next()) |line| {
        const next = try std.fmt.parseInt(u16, line, 10);
        if (next > last) {
            increments += 1;
        }
        last = next;
    }
    return increments;
}

test {
    const input =
        \\199
        \\200
        \\208
        \\210
        \\200
        \\207
        \\240
        \\269
        \\260
        \\263
    ;

    const result = try numberOfIncrements(input);
    try std.testing.expectEqual(@intCast(u16, 7), result);
}
