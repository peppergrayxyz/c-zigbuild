const std = @import("std");
const BuildConf = @import("build.zig").BuildConf;

pub const conf: BuildConf = .{

    // make a static library
    .lib_static = true,
};
