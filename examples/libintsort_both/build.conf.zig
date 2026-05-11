const std = @import("std");
const BuildConf = @import("build.zig").BuildConf;

pub const conf: BuildConf = .{

    .lib_static = true,
    .lib_shared = true,
};
