const std = @import("std");
const BuildConf = @import("build.zig").BuildConf;

pub const conf: BuildConf = .{

    // Name of the app/lib
    .name = "hello_world",
};
