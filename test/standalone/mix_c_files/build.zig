const std = @import("std");
const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;

fn isUnpecifiedTarget(t: CrossTarget) bool {
    return t.cpu_arch == null and t.abi == null and t.os_tag == null;
}
fn isRunnableTarget(t: CrossTarget) bool {
    if (t.isNative()) return true;

    return (t.getOsTag() == std.Target.current.os.tag and
        t.getCpuArch() == std.Target.current.cpu.arch);
}

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const skip_non_native = b.option(bool, "skip-non-native", "skips non-native builds") orelse false;

    const test_step = b.step("test", "Test the program");

    const targets = if (isUnpecifiedTarget(target) and !skip_non_native)
        &[_]CrossTarget{
            .{},    // native target
            .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
            .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
            .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu },
        }
    else
        &[_]CrossTarget{target};
    for (targets) |t| {
        const exe = b.addExecutable("test", "main.zig");
        exe.addCSourceFile("test.c", &[_][]const u8{"-std=c11"});
        exe.linkLibC();
        exe.setBuildMode(mode);
        exe.setTarget(t);
        b.default_step.dependOn(&exe.step);

        if (isRunnableTarget(t)) {
            const run_cmd = exe.run();
            test_step.dependOn(&run_cmd.step);
        } else {
            test_step.dependOn(&exe.step);
        }
    }
}
