const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var map_list = std.ArrayList(u8).init(allocator);
    map_list.deinit();

    const map = blk: {
        var i: u32 = 0;
        var read_buf: [1024]u8 = undefined;

        const first_line = (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')).?;
        for (first_line) |point| {
            try map_list.append(point - '0');
            i += 1;
        }
        const x_len = i;

        while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
            for (first_line) |point| {
                try map_list.append(point - '0');
                i += 1;
            }
        }
        const y_len = i / x_len;
        break :blk Map{ .map = map_list.items, .x_len = x_len, .y_len = y_len };
    };

    // map.print();
    const len = map.map.len;

    const inf = std.math.maxInt(u32);

    var dist: []u32 = try allocator.alloc(u32, len);
    defer allocator.free(dist);

    var q = std.PriorityQueue(u64).init(allocator, compare);
    defer q.deinit();

    {
        dist[0] = 0;
        try q.add((Vertex{ .v = 0, .dist = 0 }).toLong());

        var v: u32 = 1;
        while (v < map.map.len) : (v += 1) {
            dist[v] = inf;
            try q.add((Vertex{ .v = v, .dist = std.math.maxInt(u32) }).toLong());
        }
    }

    while (q.len > 0) {
        const u_vert = Vertex.fromLong(q.remove());
        const u = u_vert.v;
        if (u == len - 1) {
            break;
        }

        const ns = map.neighbors(u);
        for (ns.get()) |v| {
            const alt = dist[u] + map.map[v];
            if (alt < dist[v]) {
                try q.update((Vertex{ .v = v, .dist = dist[v] }).toLong(), (Vertex{ .v = v, .dist = alt }).toLong());
                dist[v] = alt;
            }
        }
    }
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{dist[len - 1]});
}

const Neighbors = struct {
    len: u8 = 0,
    ns: [4]u32 = undefined,

    fn add(self: *Neighbors, x: u32, y: u32, x_len: u32) void {
        self.ns[self.len] = y * x_len + x;
        self.len += 1;
    }

    fn get(self: Neighbors) []const u32 {
        return self.ns[0..self.len];
    }
};

const Vertex = struct {
    v: u32,
    dist: u32,

    fn toLong(self: Vertex) u64 {
        var x: u64 = @as(u64, self.dist) << 32;
        x += self.v;
        return x;
    }

    fn fromLong(x: u64) Vertex {
        const dist_mask: u64 = 0xFFFFFFFF00000000;
        const v = @intCast(u32, x & ~dist_mask);
        const dist = @intCast(u32, (x & dist_mask) >> 32);
        return Vertex{ .v = v, .dist = dist };
    }
};

fn compare(a: u64, b: u64) std.math.Order {
    return std.math.order(a, b);
}

const Map = struct {
    map: []u8,
    x_len: u32,
    y_len: u32,

    fn setXLen(self: *Map, x_len: u32) void {
        self.x_len = x_len;
    }

    fn setYLen(self: *Map, y_len: u32) void {
        self.y_len = y_len;
    }

    fn set(self: *Map, x: u8, y: u8, val: u8) void {
        self.map[y * self.x_len + x] = val;
    }

    fn get(self: Map, x: u8, y: u8) u8 {
        return self.map[y * self.x_len + x];
    }

    fn neighbors(self: Map, i: u32) Neighbors {
        const x_len = self.x_len;
        const y_len = self.y_len;
        const x = i % x_len;
        const y = i / x_len;
        var ns = Neighbors{};

        if (x > 0) {
            ns.add(x - 1, y, x_len);
        }
        if (x + 1 < x_len) {
            ns.add(x + 1, y, x_len);
        }
        if (y > 0) {
            ns.add(x, y - 1, x_len);
        }
        if (y + 1 < y_len) {
            ns.add(x, y + 1, x_len);
        }

        return ns;
    }

    fn print(self: Map) void {
        var i: u32 = 0;
        while (i < self.x_len) : (i += 1) {
            var j: u32 = 0;
            while (j < self.y_len) : (j += 1) {
                const val = self.get(i, j);
                const c: u8 = if (val == 0) '-' else val + '0';
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};
