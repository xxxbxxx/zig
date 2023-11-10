const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *Builder) void {
    const test_step = b.step("test", "Test it");
    b.default_step = test_step;

    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // c-header
    {
        const exe = b.addExecutable(.{
            .name = "pchtest",
            .target = target,
            .optimize = mode,
            .link_libc = true,
        });

        const pch = b.addPrecompiledCHeader(.{
            .name = "pch_c",
            .target = target,
            .optimize = mode,
            .cpp_header = false,
        }, .{
            .file = .{ .path = "include_a.h" },
            .flags = &[_][]const u8{},
        });

        exe.addPrecompiledCHeader(pch);

        exe.addCSourceFile(.{
            .file = .{ .path = "test.c" },
            .flags = &[_][]const u8{},
        });

        test_step.dependOn(&b.addRunArtifact(exe).step);
    }

    // c++-header
    {
        const exe = b.addExecutable(.{
            .name = "pchtest++",
            .target = target,
            .optimize = mode,
            .link_libc = true,
        });
        exe.linkLibCpp();

        const pch = b.addPrecompiledCHeader(.{
            .name = "pch_c++",
            .target = target,
            .optimize = mode,
            .cpp_header = true,
        }, .{
            .file = .{ .path = "include_a.h" },
            .flags = &[_][]const u8{},
        });

        exe.addPrecompiledCHeader(pch);

        exe.addCSourceFile(.{
            .file = .{ .path = "test.cpp" },
            .flags = &[_][]const u8{},
        });

        test_step.dependOn(&b.addRunArtifact(exe).step);
    }
}
