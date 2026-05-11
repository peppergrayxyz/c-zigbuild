const std = @import("std");
const BuildConf = @import("build.zig").BuildConf;

pub const conf: BuildConf = .{
    .name = "intsort",

    // make a shared library
    .lib_shared = true,

    // make exe
    .exe = true,
    .main_file = "main.c",
};
