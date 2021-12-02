const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit()) @panic("leak");
    _ = &gpa.allocator;
    var args_iter = std.process.args();
    defer args_iter.deinit();

    _ = args_iter.skip();
    const input = args_iter.nextPosix().?;
    const result = numberOfIncrements(input);
    std.debug.print("result: {}\n", .{result});
}

const int = u16;

fn numberOfIncrements(input: []const u8) anyerror!int {
    var lines = std.mem.split(u8, input, "\n");
    var last = @intCast(int, std.math.maxInt(int));
    var increments: int = 0;
    while (lines.next()) |line| {
        const next = try std.fmt.parseInt(int, line, 10);
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
    try std.testing.expectEqual(@intCast(int, 7), result);
}
