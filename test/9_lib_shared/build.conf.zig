const std = @import("std");
const BuildConf = @import("build.zig").BuildConf;

pub const conf: BuildConf = .{

    // make a shared library
    .lib_shared = true,

    // custom export macro
    .macro_exported = "EXPORTED",
};
