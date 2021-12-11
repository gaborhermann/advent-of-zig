const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var map = Map{};
    {
        var i: u8 = 0;
        var read_buf: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
            for (line) |point, j| {
                map.set(i, @intCast(u8, j), point - '0');
            }
            i += 1;
        }
    }

    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();
    try stack.ensureCapacity(100);

    var flashes: u64 = 0;
    var step: u32 = 0;
    while (step < 100) : (step += 1) {
        {
            comptime var i: u8 = 0;
            inline while (i < 100) : (i += 1) {
                if (map.inc(i % 10, i / 10) == 0) {
                    flashes += 1;
                    try stack.append(i);
                }
            }
        }

        while (stack.items.len > 0) {
            const i = stack.pop();
            const x = i % 10;
            const y = i / 10;
            const ns = neighbors(i);
            for (ns.get()) |n| {
                if (map.get(n % 10, n / 10) == 0) {
                    continue;
                }
                if (map.inc(n % 10, n / 10) == 0) {
                    flashes += 1;
                    try stack.append(n);
                }
            }
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{flashes});
}

const Neighbors = struct {
    len: u8 = 0,
    ns: [9]u8 = undefined,

    fn add(self: *Neighbors, x: u8, y: u8) void {
        self.ns[self.len] = y * 10 + x;
        self.len += 1;
    }

    fn get(self: Neighbors) []const u8 {
        return self.ns[0..self.len];
    }
};

fn neighbors(i: u8) Neighbors {
    const x = i % 10;
    const y = i / 10;
    var ns = Neighbors{};

    if (x > 0) {
        ns.add(x - 1, y);
        if (y > 0) {
            ns.add(x - 1, y - 1);
        }
        if (y + 1 < 10) {
            ns.add(x - 1, y + 1);
        }
    }
    if (x + 1 < 10) {
        ns.add(x + 1, y);
        if (y > 0) {
            ns.add(x + 1, y - 1);
        }
        if (y + 1 < 10) {
            ns.add(x + 1, y + 1);
        }
    }
    if (y > 0) {
        ns.add(x, y - 1);
    }
    if (y + 1 < 10) {
        ns.add(x, y + 1);
    }

    return ns;
}

const Map = struct {
    map: [100]u8 = undefined,

    fn set(self: *Map, x: u8, y: u8, val: u8) void {
        self.map[y * 10 + x] = val;
    }

    fn get(self: Map, x: u8, y: u8) u8 {
        return self.map[y * 10 + x];
    }

    fn inc(self: *Map, x: u8, y: u8) u8 {
        self.map[y * 10 + x] += 1;
        if (self.map[y * 10 + x] == 10) {
            self.map[y * 10 + x] = 0;
        }
        return self.map[y * 10 + x];
    }

    fn print(self: Map) void {
        comptime var i: u8 = 0;
        inline while (i < 10) : (i += 1) {
            comptime var j: u8 = 0;
            inline while (j < 10) : (j += 1) {
                const val = self.get(i, j);
                const c: u8 = if (val == 0) '-' else val + '0';
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};
