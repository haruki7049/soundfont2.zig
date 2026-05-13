const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const riff = b.dependency("riff_zig", .{});

    const mod = b.addModule("soundfont2_zig", .{
        .root_source_file = b.path("src/soundfont2.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "riff_zig", .module = riff.module("riff_zig") },
        },
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "soundfont2.zig",
        .root_module = mod,
    });
    b.installArtifact(lib);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const load_riff_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/load-riff.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "riff_zig", .module = riff.module("riff_zig") },
            },
        }),
    });
    const run_load_riff_tests = b.addRunArtifact(load_riff_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_load_riff_tests.step);
}
