const std = @import("std");
const BuildConf = @import("build.zig").BuildConf;

pub const conf: BuildConf = .{

    // Name of the app/lib
    .name = "zigc",

    // Create static or shared library
    .lib_static = true,
    .lib_shared = true,
    .exe = true,

    // treat *_test.c files as tests
    .unit_test = true,

    // File containing main function for exe build
    .main_file = "main.c",

    // Build for multiple targets to make a release
    // Details on what architectures, OSes, CPUs, and ABIs (details on ABIs in the next chapter) are available can be found by running `zig targets`
    // https://zig.guide/build-system/cross-compilation/
    .targets = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
    },

    // additonal c-flags
    .c_flags = &.{
        "-Wall",
        "-Wextra",
    },
};
