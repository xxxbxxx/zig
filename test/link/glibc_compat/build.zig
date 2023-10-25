const std = @import("std");
const builtin = @import("builtin");

// To run executables linked against a specific glibc version, the
// run-time glibc version needs to be new enough.  Check the host's glibc
// version.  Note that this does not allow for translation/vm/emulation
// services to run these tests.
const running_glibc_minor = switch (builtin.os.tag) {
    .linux => builtin.os.version_range.linux.glibc.minor,
    else => -1,
};

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Test");
    b.default_step = test_step;

    for ([_][]const u8{ "aarch64-linux-gnu.2.27", "aarch64-linux-gnu.2.34" }) |t| {
        const exe = b.addExecutable(.{
            .name = t,
            .root_source_file = .{ .path = "main.c" },
            .target = std.zig.CrossTarget.parse(
                .{ .arch_os_abi = t },
            ) catch unreachable,
        });
        exe.linkLibC();
        // TODO: actually test the output
        _ = exe.getEmittedBin();
        test_step.dependOn(&exe.step);
    }

    // Build & run against a sampling of supported glibc versions
    for ([_][]const u8{
        "native-linux-gnu.2.17", // Currently oldest supported, see #17769
        "native-linux-gnu.2.23",
        "native-linux-gnu.2.28",
        "native-linux-gnu.2.33",
        "native-linux-gnu.2.38",
        "native-linux-gnu",
    }) |t| {
        const target = std.zig.CrossTarget.parse(
            .{ .arch_os_abi = t },
        ) catch unreachable;

        const major_ver = target.toTarget().os.version_range.linux.glibc.major;
        const minor_ver = target.toTarget().os.version_range.linux.glibc.minor;

        std.debug.assert(major_ver == 2); // assuming no v1 or v3 to test

        const exe = b.addExecutable(.{
            .name = t,
            .root_source_file = .{ .path = "glibc_runtime_check.zig" },
            .target = target,
        });
        exe.linkLibC();

        // Only try running the test if the host glibc is known to be good enough
        if (minor_ver <= running_glibc_minor) {
            const run_cmd = b.addRunArtifact(exe);
            run_cmd.skip_foreign_checks = true;
            run_cmd.expectExitCode(0);

            test_step.dependOn(&run_cmd.step);
        }

        const check = exe.checkObject();

        // __errno_location is always a dynamically linked symbol
        check.checkStart();
        check.checkInDynamicSymtab();
        check.checkExact("0 0 UND FUNC GLOBAL DEFAULT __errno_location");

        // before v2.32 fstatat redirects through __fxstatat, afterwards its a
        // normal dynamic symbol
        check.checkStart();
        if (minor_ver < 32) {
            check.checkInDynamicSymtab();
            check.checkExact("0 0 UND FUNC GLOBAL DEFAULT __fxstatat");

            check.checkInSymtab();
            check.checkContains("FUNC LOCAL HIDDEN fstatat");
        } else {
            check.checkInDynamicSymtab();
            check.checkExact("0 0 UND FUNC GLOBAL DEFAULT fstatat");

            check.checkInSymtab();
            check.checkNotPresent("FUNC LOCAL HIDDEN fstatat");
        }

        // before v2.26 reallocarray is not supported
        check.checkStart();
        if (minor_ver >= 26) {
            check.checkInDynamicSymtab();
            check.checkExact("0 0 UND FUNC GLOBAL DEFAULT reallocarray");
        } else {
            check.checkInDynamicSymtab();
            check.checkNotPresent("reallocarray");
        }

        // v2.16 introduced getauxval(), so always present
        check.checkStart();
        check.checkInDynamicSymtab();
        check.checkExact("0 0 UND FUNC GLOBAL DEFAULT getauxval");

        // Always have a dynamic "exit" reference
        check.checkStart();
        check.checkInDynamicSymtab();
        check.checkExact("0 0 UND FUNC GLOBAL DEFAULT exit");

        // An atexit local symbol is defined, and depends on undefined dynamic
        // __cxa_atexit.
        check.checkStart();
        check.checkInSymtab();
        check.checkContains("FUNC LOCAL HIDDEN atexit");
        check.checkInDynamicSymtab();
        check.checkExact("0 0 UND FUNC GLOBAL DEFAULT __cxa_atexit");

        test_step.dependOn(&check.step);
    }
}
