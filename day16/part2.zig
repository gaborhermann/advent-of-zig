const std = @import("std");

const List = std.ArrayListUnmanaged;

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;
    var read_buf: [64 * 1024]u8 = undefined;

    const line = (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')).?;
    // TODO handle odd number of characters.
    const bit_len: u32 = if (line.len % 2 == 0) @intCast(u32, line.len) * 4 else unreachable;
    const byte_len: u32 = bit_len / 8;

    var buf: Buffer = blk: {
        var data: []u8 = try allocator.alloc(u8, byte_len);
        var i: u32 = 0;
        while (i < byte_len) : (i += 1) {
            data[i] = try std.fmt.parseInt(u8, line[(2 * i)..(2 * i + 2)], 16);
        }
        break :blk Buffer{ .data = data };
    };
    defer buf.deinit(allocator);

    var p = try buf.readPacket(allocator);
    defer p.deinit(allocator);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{p.value()});
}

const int = u64;

const Packet = struct {
    ver: u3,
    type: u3,
    payload: Payload,

    const Payload = union {
        literal: int,
        operator: List(Packet),
    };

    fn deinit(self: *Packet, allocator: *std.mem.Allocator) void {
        if (self.type != 4) {
            // TODO fix deinit
            // for (self.payload.operator.items) |packet| {
            //     packet.deinit(allocator);
            // }
            self.payload.operator.deinit(allocator);
        }
    }

    fn value(self: Packet) int {
        switch (self.type) {
            4 => {
                return self.payload.literal;
            },

            0 => {
                var agg: int = 0;
                for (self.payload.operator.items) |p| {
                    agg += p.value();
                }
                return agg;
            },
            1 => {
                var agg: int = 1;
                for (self.payload.operator.items) |p| {
                    agg *= p.value();
                }
                return agg;
            },
            2 => {
                var agg: int = std.math.maxInt(int);
                for (self.payload.operator.items) |p| {
                    const val = p.value();
                    if (val < agg) {
                        agg = val;
                    }
                }
                return agg;
            },
            3 => {
                var agg: int = 0;
                for (self.payload.operator.items) |p| {
                    const val = p.value();
                    if (val > agg) {
                        agg = val;
                    }
                }
                return agg;
            },

            5 => {
                const val1 = self.payload.operator.items[0].value();
                const val2 = self.payload.operator.items[1].value();
                return if (val1 > val2) 1 else 0;
            },
            6 => {
                const val1 = self.payload.operator.items[0].value();
                const val2 = self.payload.operator.items[1].value();
                return if (val1 < val2) 1 else 0;
            },
            7 => {
                const val1 = self.payload.operator.items[0].value();
                const val2 = self.payload.operator.items[1].value();
                return if (val1 == val2) 1 else 0;
            },
        }
    }
};

const Buffer = struct {
    data: []u8,
    bytes_read: u32 = 0,

    // We store the data with reversed bits.
    buf: u64 = 0,
    buf_len: u6 = 0,
    bits_read: u32 = 0,

    ver_sum: u32 = 0,

    fn readPacket(self: *Buffer, allocator: *std.mem.Allocator) !Packet {
        const v = self.readInt(u3);
        const t = self.readInt(u3);
        const payload = blk: {
            if (t == 4) {
                const lit = self.readLiteral();
                break :blk Packet.Payload{ .literal = lit };
            } else {
                const op = try self.readOperator(allocator);
                break :blk Packet.Payload{ .operator = op };
            }
        };
        self.ver_sum += v;
        return Packet{ .ver = v, .type = t, .payload = payload };
    }

    fn readLiteral(self: *Buffer) int {
        var lit: int = 0;

        var chunk: u5 = self.readInt(u5);
        lit = (lit << 4) | @truncate(u4, chunk);

        while (chunk >> 4 == 1) {
            chunk = self.readInt(u5);
            lit = (lit << 4) | @truncate(u4, chunk);
        }
        return lit;
    }

    fn readOperator(self: *Buffer, allocator: *std.mem.Allocator) anyerror!List(Packet) {
        var op = List(Packet){};
        const len_type = self.readInt(u1);
        switch (len_type) {
            0 => {
                const len = self.readInt(u15);
                const end_of_op = self.bits_read + len;
                while (self.bits_read < end_of_op) {
                    const p = try self.readPacket(allocator);
                    try op.append(allocator, p);
                }
            },
            1 => {
                const num = self.readInt(u11);
                var i: u11 = 0;
                while (i < num) : (i += 1) {
                    const p = try self.readPacket(allocator);
                    try op.append(allocator, p);
                }
            },
        }
        return op;
    }

    fn readInt(self: *Buffer, comptime T: type) T {
        const info = @typeInfo(T);
        const bit_count = info.Int.bits;

        while (self.buf_len < bit_count) {
            self.loadNextByte();
        }

        const num = @bitReverse(T, @truncate(T, self.buf));
        self.buf >>= bit_count;
        self.buf_len -= bit_count;
        self.bits_read += bit_count;
        return num;
    }

    fn loadNextByte(self: *Buffer) void {
        const byte = self.data[self.bytes_read];
        self.bytes_read += 1;

        const mask: u64 = @as(u64, @bitReverse(u8, byte)) << self.buf_len;
        self.buf_len += 8;
        self.buf |= mask;
    }

    fn deinit(self: *Buffer, allocator: *std.mem.Allocator) void {
        allocator.free(self.data);
    }
};
