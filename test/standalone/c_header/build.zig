const std = @import("std");

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Test it");
    b.default_step = test_step;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // testcase 1: single-file c-header library
    {
        const exe = b.addExecutable(.{
            .name = "single-file-library",
            .root_module = b.createModule(.{
                .root_source_file = b.path("main.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addIncludePath(b.path("."));
        exe.root_module.addCSourceFile(.{
            .file = b.path("single_file_library.h"),
            .language = .c,
            .flags = &.{"-DTSTLIB_IMPLEMENTATION"},
        });

        test_step.dependOn(&b.addRunArtifact(exe).step);
    }

    // testcase 2: precompiled c-header
    {
        const pch_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        pch_module.addCSourceFile(.{
            .file = b.path("include_a.h"),
            .language = .c_header,
            .flags = &[_][]const u8{},
        });

        const pch = b.addPrecompiledCHeader(.{
            .name = "pch_c",
            .root_module = pch_module,
        });

        const exe = b.addExecutable(.{
            .name = "pchtest",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        exe.step.dependOn(&pch.step);
        exe.root_module.addCSourceFiles(.{
            .files = &.{"test.c"},
            .flags = &[_][]const u8{},
            .language = .c,
            .precompiled_header = pch.getEmittedBin(),
        });

        test_step.dependOn(&b.addRunArtifact(exe).step);
    }

    // testcase 3: precompiled c++-header
    {
        const pch_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        });
        pch_module.addCSourceFile(.{
            .file = b.path("include_a.h"),
            .language = .cpp_header,
            .flags = &[_][]const u8{},
        });
        const pch = b.addPrecompiledCHeader(.{
            .name = "pch_c++",
            .root_module = pch_module,
        });

        const exe = b.addExecutable(.{
            .name = "pchtest++",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libcpp = true,
            }),
        });
        exe.step.dependOn(&pch.step);
        exe.root_module.addCSourceFile(.{
            .file = b.path("test.cpp"),
            .flags = &[_][]const u8{},
            .precompiled_header = pch.getEmittedBin(),
        });

        test_step.dependOn(&b.addRunArtifact(exe).step);
    }
}
