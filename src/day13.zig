const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, _: []const u8) anyerror!void {

}


test {
    const input =
        \\
    ;

    _ = input;
    // const result1 = try overlappingLineCount(input, false);
    // try std.testing.expectEqual(@intCast(usize, 5), result1);
}
