const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const sum = versionsSum(input);
    std.debug.print("sum {}\n", .{ sum });
}

const HexIter = struct {
    bytesIter: utils.SliceIter(u8),

    fn next(self: *@This()) ?u4 {
        const bytePtr = self.bytesIter.next() orelse return null;
        const byte = bytePtr.*;
        const value = switch (byte) {
            '0'...'9' => byte - '0',
            'A'...'F' => byte - 'A' + 10,
            else => @panic("unexpected hex digit"),
        };
        return @intCast(u4, value);
    }
};

const BitsIter = struct {
    hexIter: HexIter,
    lastHex: u4 = 0,
    lastHexDigits: u4 = 0,

    fn next(self: *@This(), bitsCount: u4) ?u16 {
        var bits = bitsCount;
        var result: u16 = 0;
        if (self.lastHexDigits > 0) {
            const take = std.math.min(self.lastHexDigits, bits);

            bits -= take;
            result = result | (@intCast(u16, self.lastHex >> @intCast(u2, 4 - take)) << bits);

            self.lastHexDigits -= take;
            if (self.lastHexDigits > 0) self.lastHex = self.lastHex << @intCast(u2, take);
        }
        if (bits == 0) return result;

        while (bits > 4) : (bits -= 4) {
            const val = self.hexIter.next() orelse return null;
            result = result | (@intCast(u16, val) << (bits - 4));
        }
        if (bits == 0) return result;

        self.lastHex = self.hexIter.next() orelse return null;
        result = result | (self.lastHex >> @intCast(u2, 4 - bits));
        self.lastHexDigits = 4 - bits;
        if (self.lastHexDigits > 0) self.lastHex = self.lastHex << @intCast(u2, bits);

        return result;
    }
};

const Packet = struct {
    version: u3,
};

const PacketIter = struct {
    bitsIter: BitsIter,

    fn next(self: *@This()) ?Packet {
        const tag = self.bitsIter.next(6) orelse return null;
        const version = @intCast(u3, tag >> 3);
        const typ = @intCast(u3, tag & 7);

        if (typ == 4) {
            while (self.bitsIter.next(5)) |limb| {
                if ((limb & 16) == 0) {
                    break;
                }
            }
        } else {
            const mode = self.bitsIter.next(1) orelse return null;
            if (mode == 0) {
                _ = self.bitsIter.next(15) orelse return null;
            } else {
                _ = self.bitsIter.next(11) orelse return null;
            }
        }

        return Packet{
            .version = version,
        };
    }
};

fn versionsSum(hex: []const u8) u64 {
    var iter = PacketIter{ .bitsIter = .{ .hexIter = .{ .bytesIter = utils.iter(u8, hex) } } };
    var sum: u64 = 0;
    while (iter.next()) |packet| {
        sum += packet.version;
    }
    return sum;
}

test {
    const result2 = versionsSum("8A004A801A8002F478");
    try std.testing.expectEqual(result2, 16);

    const result3 = versionsSum("620080001611562C8802118E34");
    try std.testing.expectEqual(result3, 12);

    const result4 = versionsSum("C0015000016115A2E0802F182340");
    try std.testing.expectEqual(result4, 23);

    const result5 = versionsSum("A0016C880162017C3686B18A3D4780");
    try std.testing.expectEqual(result5, 31);
}
