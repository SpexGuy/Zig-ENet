const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *std.build.Builder) anyerror!void {
    const target = b.standardTargetOptions(.{});

    const examples = [_][2][]const u8{
        [_][]const u8{ "client", "examples/client.zig" },
        [_][]const u8{ "server", "examples/server.zig" },
    };

    for (examples) |example, i| {
        const name = example[0];
        const source = example[1];

        var exe = b.addExecutable(name, source);
        exe.setBuildMode(b.standardReleaseOptions());

        // for some reason exe_compiled + debug build results in "illegal instruction 4". Investigate at some point.
        linkArtifact(b, exe, target,"");

        const run_cmd = exe.run();
        const exe_step = b.step(name, b.fmt("run {s}.zig", .{name}));
        exe_step.dependOn(&run_cmd.step);

        exe.install();

        // first element in the list is added as "run" so "zig build run" works
        if (i == 0) {
            const run_exe_step = b.step("run", b.fmt("run {s}.zig", .{name}));
            run_exe_step.dependOn(&run_cmd.step);
        }
    }
}

/// prefix_path is used to add package paths. It should be the the same path used to include this build file
pub fn linkArtifact(b: *Builder, artifact: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    if (prefix_path.len > 0 and !std.mem.endsWith(u8, prefix_path, "/")) @panic("prefix-path must end with '/' if it is not empty");

    compileEnet(b, artifact, target, prefix_path);

    artifact.addPackagePath("enet", prefix_path ++ "enet.zig");
}

fn compileEnet(b: *Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    _ = b;
    _ = target;
    exe.linkLibC();
    exe.addIncludeDir(prefix_path ++ "enet/include/enet");
    exe.addIncludeDir(prefix_path ++ "enet/include");

    const cflags = &[_][]const u8{ "" };
    exe.addCSourceFile(prefix_path ++ "enet/callbacks.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/compress.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/host.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/list.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/packet.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/peer.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/protocol.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/unix.c", cflags);
    exe.addCSourceFile(prefix_path ++ "enet/win32.c", cflags);
}
