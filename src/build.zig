const std = @import("std");

// Import Config
const conf = @import("build.conf.zig").conf; // wait for @tryImport

// BuildConf
pub const BuildConf = struct {
    name: []const u8 = "a",
    lib_static: bool = false,
    lib_shared: bool = false,
    exe: bool = false,
    main_file: []const u8 = "",
    unit_test: bool = false,
    targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
    },
    macro_lib_static: []const u8 = "__ZIGC_LIB_STATIC__",
    macro_lib_shared: []const u8 = "__ZIGC_LIB_SHARED__",
    macro_exported: []const u8 = "__ZIGC_EXPORTED__",
    c_flags: []const []const u8 = &.{
        "-Wall",
        "-Wextra",
    },
};

// directories
const DirsIn = struct {
    src: []const u8,
    tests: []const u8,
    example: []const u8,
};
const DirsOut = struct {
    lib: []const u8,
    tests: []const u8,
    static: []const u8,
    shared: []const u8,
    bin: []const u8,
};
const Dirs = struct {
    in: DirsIn,
    out: DirsOut,
};

const dirs: Dirs = .{ .in = .{
    .src = "src",
    .tests = "test",
    .example = "example",
}, .out = .{
    .lib = "lib",
    .tests = "test",
    .static = "static",
    .shared = "shared",
    .bin = "bin",
} };

const file_build_conf_zig = "build.conf.zig";
const file_ext_c = ".c";
const test_suffix = "_test";
const file_ext_unit_test_c = test_suffix ++ file_ext_c;

fn parse(b: *std.Build, io: std.Io, src_dir: []const u8) []const []const u8 {
    var files: std.ArrayList([]const u8) = .empty;

    // open directory
    const dir = std.Io.Dir.cwd().openDir(io, src_dir, .{ .iterate = true }) catch |e| {
        std.debug.print("Failed to read directory '{s}': {}\n", .{ src_dir, e });
        return &.{};
    };

    // create walker
    var walker = dir.walk(b.allocator) catch |e| {
        std.debug.print("Can't walk the directory '{}': {}", .{ dir, e });
        return &.{};
    };
    defer walker.deinit();

    var file_entry = walker.next(io) catch |e| std.debug.panic("Error walking dir {}", .{e});

    while (file_entry) |file| : (file_entry = walker.next(io) catch |e| std.debug.panic("Error walking dir {}", .{e})) {
        const file_path_str = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ src_dir, file.path }) catch |e| std.debug.panic("Out of Memory {}", .{e});

        if (std.mem.endsWith(u8, file.basename, file_ext_c)) {
            // Add regular C files to the library
            files.append(b.allocator, file_path_str) catch |e| std.debug.panic("Error appending path {}", .{e});
        }
    }

    return files.items;
}

fn file_exists(file_path: []const u8) bool {
    const file_system = std.Io.Dir.cwd();
    const file = file_system.openFile(file_path, .{ .mode = .read_only }) catch return false;
    file.close();
    return true;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // io handle
    const io = b.graph.io;

    // Add all C files in the `c_src` directory.
    const c_src_path = b.path(dirs.in.src);

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Check Option -Dtargets
    // if set, built targets, else build native
    const makeTargets = b.option(
        bool,
        "targets",
        "Build targets defined in build.conf.zig (else native target)",
    ) orelse false;

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const targets: []const std.Target.Query = if (makeTargets) conf.targets else &.{b.standardTargetOptions(.{}).query};

    // Parse source directory
    const filesInDir_src = parse(b, io, dirs.in.src);

    // Assign files to outputs
    var source_files_bin: std.ArrayList([]const u8) = .empty;
    var source_files_lib: std.ArrayList([]const u8) = .empty;
    var source_files_tst: std.ArrayList([]const u8) = .empty;
    var source_files_src: std.ArrayList([]const u8) = .empty;

    const conf_lib_and_exe = (conf.exe and (conf.lib_shared or conf.lib_static));
    const conf_lib = (conf.lib_shared or conf.lib_static);
    const conf_none = !(conf.exe or conf.lib_shared or conf.lib_static);
    const conf_main = conf.main_file.len > 0;

    for (filesInDir_src) |file_path| {
        const is_main_file = if (!conf_main) false else std.mem.endsWith(u8, file_path, conf.main_file);
        const has_unit_test_suffix = std.mem.endsWith(u8, file_path, file_ext_unit_test_c);

        if (conf.unit_test and has_unit_test_suffix) {
            source_files_tst.append(b.allocator, file_path) catch |e| std.debug.panic("Error appending path {}", .{e});
        } else {
            source_files_src.append(b.allocator, file_path) catch |e| std.debug.panic("Error appending path {}", .{e});

            if (conf_lib_and_exe and is_main_file) {
                source_files_bin.append(b.allocator, file_path) catch |e| std.debug.panic("Error appending path {}", .{e});
            } else if (conf_lib) {
                source_files_lib.append(b.allocator, file_path) catch |e| std.debug.panic("Error appending path {}", .{e});
            } else {
                source_files_bin.append(b.allocator, file_path) catch |e| std.debug.panic("Error appending path {}", .{e});
            }
        }
    }

    // Check which outputs are enabled and if we have files to build them. If nothing is selected, build an exe
    const buildLibStatic = (source_files_lib.items.len > 0) and (conf.lib_static);
    const buildLibShared = (source_files_lib.items.len > 0) and (conf.lib_shared);
    const buildLib = buildLibStatic or buildLibShared;
    const buildTst = (source_files_tst.items.len > 0) and (conf.unit_test);
    const buildBin = (source_files_bin.items.len > 0) and (conf.exe or conf_none);

    if (!(buildLib or buildTst or buildBin)) {
        std.debug.print("No source files found (build aborted)!\n", .{});
        return;
    }

    // Check consitency of config
    if (conf_lib_and_exe) {
        if (source_files_bin.items.len <= 0) {
            std.debug.print("Exe and library build configured, but main file ", .{});
            if (conf_main) {
                std.debug.print("`{s}` not found!\n", .{conf.main_file});
            } else {
                std.debug.print("not configured!\n", .{});
            }
            return;
        }
        if (!buildLib) {
            std.debug.print("Exe and library build configured, but only single file `{s}` found (skipping lib build)! \n", .{conf.main_file});
        }
    }

    for (targets) |t| {
        // Standard target options allows the person running `zig build` to choose
        // what target to build for. Here we do not override the defaults, which
        // means any target is allowed, and the default is native. Other options
        // for restricting supported target set are available.
        const target = b.resolveTargetQuery(t);

        const zigTriple = t.zigTriple(b.allocator) catch |e| std.debug.panic("Out of Memory {}", .{e});
        const build_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ zigTriple, @tagName(optimize) }) catch |e| std.debug.panic("Out of Memory {}", .{e});
        //const lib_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ zigTriple, dirs.out.lib }) catch |e| std.debug.panic("Out of Memory {}", .{e});
        //const lib_path_static = std.fmt.allocPrint(b.allocator, "{s}/static", .{lib_path}) catch |e| std.debug.panic("Out of Memory {}", .{e});
        //const lib_path_shared = std.fmt.allocPrint(b.allocator, "{s}/shared", .{lib_path}) catch |e| std.debug.panic("Out of Memory {}", .{e});
        // const test_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ zigTriple, dirs.out.tests }) catch |e| std.debug.panic("Out of Memory {}", .{e});
        //const bin_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ zigTriple, dirs.out.bin }) catch |e| std.debug.panic("Out of Memory {}", .{e});

        const dir = std.Io.Dir.cwd().openDir(io, dirs.in.src, .{ .iterate = true }) catch |e| {
            std.debug.print("Failed to read directory {s}: {}\n", .{ dirs.in.src, e });
            return;
        };
        var walker = dir.walk(b.allocator) catch |e| {
            std.debug.print("Can't walk the directory {}: {}", .{ dir, e });
            return;
        };
        defer walker.deinit();

        var libStatic: *std.Build.Step.Compile = undefined;
        var libShared: *std.Build.Step.Compile = undefined;

        if (buildLib) {
            if (buildLibStatic) {
                libStatic = b.addLibrary(.{
                    .name = conf.name,
                    .linkage = .static,
                    .root_module = b.createModule(.{
                        .target = target,
                        .optimize = optimize,
                        .link_libc = true,
                    }),
                });

                libStatic.root_module.addCMacro(conf.macro_exported, "");
                libStatic.root_module.addCMacro(conf.macro_lib_static, "");

                libStatic.root_module.addIncludePath(c_src_path);
                libStatic.root_module.addCSourceFiles(.{
                    .files = source_files_lib.items,
                    .flags = conf.c_flags,
                });

                b.getInstallStep().dependOn(&b.addInstallArtifact(libStatic, .{
                    .dest_dir = .{
                        .override = .{
                            .custom = build_path,
                        },
                    },
                }).step);
            }

            if (buildLibShared) {
                libShared = b.addLibrary(.{
                    .name = conf.name,
                    .linkage = .dynamic,
                    .root_module = b.createModule(.{
                        .target = target,
                        .optimize = optimize,
                        .link_libc = true,
                    }),
                });

                libShared.root_module.addCMacro(conf.macro_lib_shared, " ");
                libShared.root_module.addCMacro(
                    conf.macro_exported,
                    if (t.os_tag == .windows) "__declspec(dllexport)" else "",
                );

                libShared.root_module.addIncludePath(c_src_path);
                libShared.root_module.addCSourceFiles(.{
                    .files = source_files_lib.items,
                    .flags = conf.c_flags,
                });

                b.getInstallStep().dependOn(&b.addInstallArtifact(libShared, .{
                    .dest_dir = .{
                        .override = .{
                            .custom = build_path,
                        },
                    },
                }).step);
            }
        }

        if (buildBin) {
            const exe = b.addExecutable(.{
                .name = conf.name,
                .root_module = b.createModule(.{
                    .target = target,
                    .optimize = optimize,
                    .link_libc = true,
                }),
            });

            exe.root_module.addIncludePath(c_src_path);
            exe.root_module.addCSourceFiles(.{
                .files = source_files_bin.items,
                .flags = conf.c_flags,
            });

            if (buildLibShared) {
                exe.root_module.linkLibrary(libShared);
                exe.root_module.addRPathSpecial("$ORIGIN");

                exe.root_module.addCMacro(conf.macro_lib_shared, " ");
                exe.root_module.addCMacro(
                    conf.macro_exported,
                    if (t.os_tag == .windows) "__declspec(dllexport)" else "",
                );
            } else if (buildLibStatic) {
                exe.root_module.addCMacro(conf.macro_exported, "");
                exe.root_module.addCMacro(conf.macro_lib_static, "");
                exe.root_module.addObjectFile(libStatic.getEmittedBin());
            }

            // This declares intent for the executable to be installed into the
            // standard location when the user invokes the "install" step (the default
            // step when running `zig build`).

            b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{
                .dest_dir = .{
                    .override = .{
                        .custom = build_path,
                    },
                },
            }).step);

            if (!makeTargets) {
                // This *creates* a Run step in the build graph, to be executed when another
                // step is evaluated that depends on it. The next line below will establish
                // such a dependency.
                const run_cmd = b.addRunArtifact(exe);

                // By making the run step depend on the install step, it will be run from the
                // installation directory rather than directly from within the cache directory.
                // This is not necessary, however, if the application depends on other installed
                // files, this ensures they will be present and in the expected location.
                run_cmd.step.dependOn(b.getInstallStep());

                // This allows the user to pass arguments to the application in the build
                // command itself, like this: `zig build run -- arg1 arg2 etc`
                if (b.args) |args| {
                    run_cmd.addArgs(args);
                }

                // This creates a build step. It will be visible in the `zig build --help` menu,
                // and can be selected like this: `zig build run`
                // This will evaluate the `run` step rather than the default, which is "install".
                const run_step = b.step("run", "Run the app");
                run_step.dependOn(&run_cmd.step);
            }
        }

        if (buildTst) {
            var previous_run_step: ?*std.Build.Step = null;

            for (source_files_tst.items, 1..) |test_file, test_number| {
                const test_src_name = std.fs.path.stem(std.fs.path.basename(test_file));
                const test_name = test_src_name[0 .. test_src_name.len - test_suffix.len];
                const test_file_name = b.fmt("test-{d}-{s}", .{
                    test_number,
                    test_name,
                });

                const test_exe = b.addExecutable(.{
                    .name = test_file_name,
                    .root_module = b.createModule(.{
                        .target = target,
                        .optimize = optimize,
                        .link_libc = true,
                    }),
                });

                test_exe.root_module.addIncludePath(c_src_path);
                test_exe.root_module.addCSourceFiles(.{ .files = source_files_src.items, .flags = &.{} });

                // Add this test's C file. Each test file should define main().
                test_exe.root_module.addCSourceFile(.{
                    .file = b.path(test_file),
                    .flags = conf.c_flags,
                });

                const run_test = b.addRunArtifact(test_exe);
                run_test.addArg(b.fmt("{d}", .{test_number}));
                run_test.addArg(b.fmt("{d}", .{source_files_tst.items.len}));
                run_test.addArg(test_name);

                // Force sequential execution:
                if (previous_run_step) |prev| {
                    run_test.step.dependOn(prev);
                }

                previous_run_step = &run_test.step;
            }

            // The public `zig build test` step depends on the final run step.
            // Because each run step depends on the previous one, this runs all tests.
            const test_step = b.step("test", "Run C tests");
            if (previous_run_step) |last| {
                test_step.dependOn(last);
            }
        }
    }
}
