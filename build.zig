const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const build_mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const tests = buildTests(b, build_mode, target);

    const lib_step = buildLibrary(b, build_mode, target);
    lib_step.install();

    const test_step = b.step("test", "Run enet tests");
    test_step.dependOn(&tests.step);

    {
        const client_exe = b.addExecutable("client", "examples/client.zig");
        client_exe.setBuildMode(build_mode);
        client_exe.setTarget(target);
        link(b, client_exe);

        const client_install = b.addInstallArtifact(client_exe);

        const client_build_step = b.step("examples:client:install", "Build the client example");
        client_build_step.dependOn(&client_install.step);

        const client_run_step = b.step("examples:client:run", "Run the client example");
        client_run_step.dependOn(&client_exe.run().step);
    }

    {
        const server_exe = b.addExecutable("server", "examples/server.zig");
        server_exe.setBuildMode(build_mode);
        server_exe.setTarget(target);
        link(b, server_exe);

        const server_install = b.addInstallArtifact(server_exe);

        const server_build_step = b.step("examples:server:install", "Build the server example");
        server_build_step.dependOn(&server_install.step);

        const server_run_step = b.step("examples:server:run", "Run the server example");
        server_run_step.dependOn(&server_exe.run().step);
    }
}

pub fn buildTests(
    b: *std.build.Builder,
    build_mode: std.builtin.Mode,
    target: std.zig.CrossTarget,
) *std.build.LibExeObjStep {
    const tests = b.addTest(thisDir() ++ "/enet.zig");
    tests.setBuildMode(build_mode);
    tests.setTarget(target);
    link(b, tests);
    return tests;
}

pub fn buildLibrary(
    b: *std.build.Builder,
    build_mode: std.builtin.Mode,
    target: std.zig.CrossTarget,
) *std.build.LibExeObjStep {
    const lib = b.addStaticLibrary("enet", null);

    lib.setBuildMode(build_mode);
    lib.setTarget(target);
    lib.want_lto = false;
    lib.addIncludeDir(thisDir() ++ "/enet/include");
    lib.linkSystemLibrary("c");

    if (target.isWindows()) {
        lib.linkSystemLibrary("ws2_32");
        lib.linkSystemLibrary("winmm");
    }

    const defines = .{
        "-DHAS_FCNTL=1",
        "-DHAS_POLL=1",
        "-DHAS_GETNAMEINFO=1",
        "-DHAS_GETADDRINFO=1",
        "-DHAS_GETHOSTBYNAME_R=1",
        "-DHAS_GETHOSTBYADDR_R=1",
        "-DHAS_INET_PTON=1",
        "-DHAS_INET_NTOP=1",
        "-DHAS_MSGHDR_FLAGS=1",
        "-DHAS_SOCKLEN_T=1",
        "-fno-sanitize=undefined",
    };
    lib.addCSourceFile(thisDir() ++ "/enet/callbacks.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/compress.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/host.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/list.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/packet.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/peer.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/protocol.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/unix.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/enet/win32.c", &defines);

    return lib;
}

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep) void {
    const lib = buildLibrary(b, step.build_mode, step.target);
    step.linkLibrary(lib);
    step.addPackagePath("enet", thisDir() ++ "/enet.zig");
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
