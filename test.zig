const std = @import("std");
const enet = @import("enet.zig");

fn refDeclsList(comptime T: type, comptime decls: []const std.builtin.TypeInfo.Declaration) void {
    for (decls) |decl| {
        if (decl.is_pub) {
            _ = @field(T, decl.name);
            switch (decl.data) {
                .Type => |SubType| refAllDeclsRecursive(SubType),
                .Var => |Type| {},
                .Fn => |fn_decl| {},
            }
        }
    }
}

fn refAllDeclsRecursive(comptime T: type) void {
    comptime {
        switch (@typeInfo(T)) {
            .Struct => |info| refDeclsList(T, info.decls),
            .Union => |info| refDeclsList(T, info.decls),
            .Enum => |info| refDeclsList(T, info.decls),
            .Opaque => |info| refDeclsList(T, info.decls),
            else => {},
        }
    }
}

comptime {
    @setEvalBranchQuota(10000);
    // workaround circular dependency compiler bug
    _ = enet.PacketFreeCallback;
    _ = enet.InterceptCallback;
    refAllDeclsRecursive(enet);
    refAllDeclsRecursive(enet.List(enet.Acknowledgement));
}

test "" {}
