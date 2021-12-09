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
    defer map_list.deinit();

    var x_len: u64 = undefined;
    var read_buf: [1024]u8 = undefined;
    {
        const line = (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')).?;
        x_len = line.len;
        try map_list.ensureTotalCapacity(x_len);
        for (line) |point| {
            try map_list.append(point - '0');
        }
    }

    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        try map_list.ensureTotalCapacity(map_list.items.len + x_len);
        for (line) |point| {
            try map_list.append(point - '0');
        }
    }

    const y_len: u64 = map_list.items.len / x_len;
    const map = Map{ .x_len = x_len, .y_len = y_len, .map = map_list.items };

    var low_points = std.ArrayList(Point).init(allocator);
    defer low_points.deinit();

    var y: u32 = 0;
    while (y < y_len) : (y += 1) {
        var x: u32 = 0;
        while (x < x_len) : (x += 1) {
            if (map.higher_neighbors(x, y).len == map.neighbors(x, y).len) {
                try low_points.append(Point{ .x = x, .y = y });
            }
        }
    }

    var discovered = try std.DynamicBitSet.initEmpty(map.map.len, allocator);
    defer discovered.deinit();

    var stack = std.ArrayList(Point).init(allocator);
    defer stack.deinit();

    var top3 = [_]u32{0} ** 3;
    for (low_points.items) |p| {
        var basin_size: u32 = 0;

        try stack.append(p);
        while (stack.items.len != 0) {
            const v = stack.pop();

            const idx = v.y * x_len + v.x;
            if (!discovered.isSet(idx)) {
                basin_size += 1;
                discovered.set(idx);
                const hns = map.higher_neighbors(v.x, v.y);
                for (hns.get()) |w| {
                    if (map.get(w.x, w.y) != 9) {
                        try stack.append(w);
                    }
                }
            }
        }

        if (basin_size > top3[2]) {
            top3[0] = top3[1];
            top3[1] = top3[2];
            top3[2] = basin_size;
        } else if (basin_size > top3[1]) {
            top3[0] = top3[1];
            top3[1] = basin_size;
        } else if (basin_size > top3[0]) {
            top3[0] = basin_size;
        }

        stack.shrinkRetainingCapacity(0);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{top3[0] * top3[1] * top3[2]});
}

const Neighbors = struct {
    len: u8 = 0,
    ns: [4]Point = undefined,

    fn add(self: *Neighbors, x: u32, y: u32) void {
        const n = Point{ .x = x, .y = y };
        self.ns[self.len] = n;
        self.len += 1;
    }

    fn get(self: Neighbors) []const Point {
        return self.ns[0..self.len];
    }
};

const Map = struct {
    x_len: u64,
    y_len: u64,
    map: []u8,

    fn get(self: Map, x: u32, y: u32) u8 {
        return self.map[y * self.x_len + x];
    }

    fn higher_neighbors(self: Map, x: u32, y: u32) Neighbors {
        var hns = Neighbors{};

        const ns = self.neighbors(x, y);
        const height = self.get(x, y);
        for (ns.get()) |n| if (height < self.get(n.x, n.y)) {
            hns.add(n.x, n.y);
        };

        return hns;
    }

    fn neighbors(self: Map, x: u32, y: u32) Neighbors {
        var ns = Neighbors{};

        if (x > 0) {
            ns.add(x - 1, y);
        }
        if (x + 1 < self.x_len) {
            ns.add(x + 1, y);
        }
        if (y > 0) {
            ns.add(x, y - 1);
        }
        if (y + 1 < self.y_len) {
            ns.add(x, y + 1);
        }

        return ns;
    }
};

const Point = struct {
    x: u32,
    y: u32,
};
