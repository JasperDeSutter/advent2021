const std = @import("std");
const runner = @import("runner.zig");
const utils = @import("utils.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const sum = versionsSum(input);
    std.debug.print("sum {}\n", .{sum});

    const result = try evaluate(input);
    std.debug.print("result {}\n", .{result});
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

    fn nextV(self: *@This(), bitsCount: u4) ?u16 {
        var bits = bitsCount;
        var result: u16 = 0;
        if (self.lastHexDigits > 0) {
            const take = std.math.min(self.lastHexDigits, bits);

            bits -= take;
            result = result | @shlExact(@intCast(u16, self.lastHex >> @intCast(u2, 4 - take)), bits);

            self.lastHexDigits -= take;
            if (self.lastHexDigits > 0) self.lastHex = self.lastHex << @intCast(u2, take);
        }
        if (bits == 0) return result;

        while (bits > 3) : (bits -= 4) {
            const val = self.hexIter.next() orelse return null;
            result = result | @shlExact(@intCast(u16, val), (bits - 4));
        }
        if (bits == 0) return result;

        self.lastHex = self.hexIter.next() orelse return null;
        result = result | (self.lastHex >> @intCast(u2, 4 - bits));
        self.lastHexDigits = 4 - bits;
        if (self.lastHexDigits > 0) self.lastHex = self.lastHex << @intCast(u2, bits);

        return result;
    }

    fn next(self: *@This(), comptime Int: type) ?Int {
        const bits = @intCast(u4, @typeInfo(Int).Int.bits);
        const result = self.nextV(bits) orelse return null;
        return @intCast(Int, result);
    }
};

const Literal = struct {
    len: u8,
    value: u64,
};

const PacketContent = union {
    literal: Literal,
    followingCount: u11,
    followingLen: u15,
};

const Packet = struct {
    version: u3,
    typ: u3,
    isLen: bool,
    content: PacketContent,

    fn isDone(self: *const @This(), contentLen: u16, contentCount: u16) bool {
        if (self.typ == 4) return true;
        if (self.isLen) return self.content.followingLen == contentLen;
        return self.content.followingCount == contentCount;
    }

    fn len(self: *const @This()) u8 {
        if (self.typ == 4) return self.content.literal.len;
        if (self.isLen) return 6 + 1 + 15;
        return 6 + 1 + 11;
    }
};

const PacketIter = struct {
    bitsIter: BitsIter,

    fn next(self: *@This()) ?Packet {
        const tag = self.bitsIter.next(u6) orelse return null;
        const version = @intCast(u3, tag >> 3);
        const typ = @intCast(u3, tag & 7);

        var content: PacketContent = undefined;
        var isLen = true;
        if (typ == 4) {
            var len: u8 = 6;
            var value: u64 = 0;
            while (self.bitsIter.next(u5)) |limb| {
                len += 5;
                value = @shlExact(value, 4) | (limb & 15);
                if ((limb & 16) == 0) break;
            }
            content = PacketContent{ .literal = .{ .len = len, .value = value } };
        } else {
            const mode = self.bitsIter.next(u1) orelse return null;
            if (mode == 0) {
                const size = self.bitsIter.next(u15) orelse return null;
                content = PacketContent{ .followingLen = size };
            } else {
                const count = self.bitsIter.next(u11) orelse return null;
                content = PacketContent{ .followingCount = count };
                isLen = false;
            }
        }

        return Packet{
            .version = version,
            .typ = typ,
            .isLen = isLen,
            .content = content,
        };
    }
};

fn versionsSum(hex: []const u8) u32 {
    var iter = PacketIter{ .bitsIter = .{ .hexIter = .{ .bytesIter = utils.iter(u8, hex) } } };
    var sum: u32 = 0;
    while (iter.next()) |packet| {
        sum += packet.version;
    }
    return sum;
}

fn evaluateRecursive(iter: *PacketIter, len: *u16) u64 {
    const packet = iter.next().?;
    if (packet.typ == 4) {
        const lit = packet.content.literal;
        len.* += lit.len;
        return @intCast(u64, lit.value);
    }

    if (packet.typ > 4) {
        var subLen: u16 = 0;
        const left = evaluateRecursive(iter, &subLen);
        const right = evaluateRecursive(iter, &subLen);
        len.* += subLen + packet.len();

        const tru: u64 = 1;
        const fals: u64 = 0;
        return switch (packet.typ) {
            5 => if (left > right) tru else fals,
            6 => if (left < right) tru else fals,
            else => if (left == right) tru else fals,
        };
    } else {
        var contentLen: u16 = 0;
        var contentCount: u16 = 1;
        var acc: u64 = evaluateRecursive(iter, &contentLen);

        while (!packet.isDone(contentLen, contentCount)) {
            const operand = evaluateRecursive(iter, &contentLen);
            acc = switch (packet.typ) {
                0 => acc + operand,
                1 => acc * operand,
                2 => std.math.min(acc, operand),
                else => std.math.max(acc, operand),
            };
            contentCount += 1;
        }

        len.* += contentLen + packet.len();
        return acc;
    }
}

fn evaluate(hex: []const u8) !u64 {
    var iter = PacketIter{ .bitsIter = .{ .hexIter = .{ .bytesIter = utils.iter(u8, hex) } } };

    var totalLen: u16 = 0;
    const res = evaluateRecursive(&iter, &totalLen);
    return res;
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

test {
    const sum = evaluate("C200B40A82");
    try std.testing.expectEqual(sum, 3);

    const product = evaluate("04005AC33890");
    try std.testing.expectEqual(product, 54);

    const minOfThree = evaluate("880086C3E88112");
    try std.testing.expectEqual(minOfThree, 7);

    const equals = evaluate("9C005AC2F8F0");
    try std.testing.expectEqual(equals, 0);

    const complex = evaluate("9C0141080250320F1802104A08");
    try std.testing.expectEqual(complex, 1);
}
