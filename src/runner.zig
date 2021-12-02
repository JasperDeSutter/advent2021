const std = @import("std");

pub fn run(
    solve: fn (
        alloc: *std.mem.Allocator,
        input: []const u8,
    ) anyerror!void,
) anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit()) @panic("leak");
    var alloc = &gpa.allocator;

    var args_iter = std.process.args();
    defer args_iter.deinit();
    _ = args_iter.skip();
    const input = args_iter.nextPosix().?;

    try solve(alloc, input);
}
