const std = @import("std");
const builtin = std.builtin;

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("day01", "src/day01.zig");
    
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("day01", "Run day01");
    run_step.dependOn(&run_cmd.step);
}
