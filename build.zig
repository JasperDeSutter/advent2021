const std = @import("std");
const builtin = std.builtin;

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const test_step = b.step("test", "Run all tests");

    var day: u32 = 1;
    var end: u32 = 9;
    while (day <= end) : (day += 1) {
        var dayStringBuf: [5]u8 = undefined;
        const dayString = try std.fmt.bufPrint(dayStringBuf[0..], "day{:0>2}", .{day});

        const srcFile = b.fmt("src/{s}.zig", .{dayString});

        const exe = b.addExecutable(dayString, srcFile);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(dayString, b.fmt("Run {s}", .{dayString}));
        run_step.dependOn(&run_cmd.step);

        const input_path = b.pathFromRoot(b.fmt("inputdata/{s}.txt", .{dayString}));
        run_cmd.addArg(input_path);

        const test_cmd = b.addTest(srcFile);
        test_cmd.setTarget(target);
        test_cmd.setBuildMode(mode);
        test_step.dependOn(&test_cmd.step);
    }
}
