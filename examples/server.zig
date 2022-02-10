const std = @import("std");
const enet = @import("enet");

pub fn main() !void {
    try enet.initialize();
    var address: enet.Address = std.mem.zeroes(enet.Address);
    address.host = enet.HOST_ANY; //localhost
    address.port = 7777;
    var server: *enet.Host = undefined;

    server = try enet.Host.create(address, 1, 1, 0, 0);

    // game loop
    while (true) {
        var event: enet.Event = std.mem.zeroes(enet.Event);

        // wait 1000 ms (1 second) for an event
        while (try server.service(&event, 1000)) {
            switch (event.type) {
                .connect => {
                    std.log.debug("A new client connected from {d}:{d}.", .{ event.peer.?.address.host, event.peer.?.address.port });
                },
                .receive => {
                    
                    if (event.packet) |packet| {
                        std.log.debug("A packet of length {d} was received from {s} on channel {d}.", .{packet.dataLength, event.peer.?.data, event.channelID});
                        packet.destroy();
                    }
                },
                .disconnect => {
                    std.log.debug("{s} disconnected.", .{event.peer.?.data});
                    event.peer.?.data = null;
                },
                else => {
                    std.log.debug("ugh!", .{});
                },
            }
        }
    }

    server.destroy();
    return;
}
