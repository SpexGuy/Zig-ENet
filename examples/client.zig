const std = @import("std");
const enet = @import("enet");

pub fn main() !void {
 
    try enet.initialize();

    var address: enet.Address = std.mem.zeroes(enet.Address);
    var client: *enet.Host = undefined;
    var peer: *enet.Peer = undefined;
    var event: enet.Event = std.mem.zeroes(enet.Event);

    client = try enet.Host.create(null, 1, 1, 0, 0);

    try address.set_host("127.0.0.1");
    address.port = 7777;

    peer = try client.connect(address, 1, 0);

    if (try client.service(&event, 5000)) {
        if (event.type == enet.EventType.connect) {
            std.log.debug("Connection to 127.0.0.1:7777 succeeded!", .{});
        }
    }

    while (try client.service(&event, 1000)) {
        switch (event.type) {
            .receive => {
                if (event.packet) |packet| {
                    std.log.debug("A packet of length {d} was received from {d}:{d} on channel {d}.", .{
                        packet.dataLength,
                        event.peer.?.address.host,
                        event.peer.?.address.port,
                        event.channelID,
                    });
                }
            },
            else => {},
        }
    }

    peer.disconnect(0);

    while (try client.service(&event, 3000)) {
        switch (event.type) {
            .receive => {
                if (event.packet) |packet| {
                    packet.destroy();
                }
            },
            .disconnect => {
                std.log.debug("Disconnect succeeded!", .{});
            },
            else => {},
        }
    }

    client.destroy();

    return;
}
