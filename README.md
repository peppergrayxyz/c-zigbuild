# c-zigbuild

Utilize the Zig Build System for C

The Zig languange is nice, but its build system is even nicer. Instead of relying on dark wizardry of Makefile, CMake, Ninja & Co it bringt its own customizable build system written in Zig itsefl. But it gets even better: Zig is designed as a drop in C replacement, thus making C a first class citizens. We can utalize this propertiy to use the Zig build system to compile C code. This gives us all the benefits of Zig for a C project:
- cross compiling
- dependency management
- testing

## Overview

The heart of the build system is a customized `build.zig` along with configuration in `build.conf.zig` and conventions on how to use it.

`build.conf.zig`:

|option|type|description|
|-|-|-|
|name|[]const u8|name of the output file|
|lib_static|bool|build a static library|
|lib_shared|bool|build a shared library|
|exe|bool|build an executable|
|main_file|[]const u8|c file that contains main()|
|unit_test|bool|treat *_test.c files as tests|
|targets|[]const std.Target.Query|build targets, e.g. .{ .cpu_arch = .x86_64, .os_tag = .linux }|
|macro_lib_static|[]const u8|macro to mark function as static export|
|macro_lib_shared|[]const u8|macro to mark function as shared export|
|macro_exported|[]const u8|macro to mark function as export|
|c_flags|[]const []const u8|additonal c-flags|

## Usage

### Setup

1. Install Zig: https://ziglang.org/learn/getting-started/
2. create a new project 
   ```
   mkdir example
   cd example
   zig init
   ```
3. overwrite `build.zig` with the file from this repository
4. add and configure `build.conf.zig` from this repositry
5. remove zig files from `src/*` and add your c sources


### Build & Run

- `zig build`
- `zig build run`

### Test

Add *_test.c files, each with a main(). Then run them:
- `zig build test`


## Examples

Check out the [examples](/examples/Examples.md) and consider using them as boiler plate.

This is how you run the hello-world example:

```
git clone https://github.com/peppergrayxyz/c-zigbuild.git
cd c-zigbuild/examples/hello_word  
zig build run
```


