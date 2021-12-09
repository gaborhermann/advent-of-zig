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

    var total: u64 = 0;
    var y: u32 = 0;
    while (y < y_len) : (y += 1) {
        var x: u32 = 0;
        while (x < x_len) : (x += 1) {
            if (map.higher_neighbors(x, y).len == map.neighbors(x, y).len) {
                total += map.get(x, y) + 1;
            }
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{total});
}

const Map = struct {
    x_len: u64,
    y_len: u64,
    map: []u8,

    fn get(self: Map, x: u32, y: u32) u8 {
        return self.map[y * self.x_len + x];
    }

    fn higher_neighbors(self: Map, x: u32, y: u32) []Point {
        var len: u8 = 0;
        var hns: [4]Point = undefined;

        const ns = self.neighbors(x, y);
        const height = self.get(x, y);
        for (ns) |n| if (height < self.get(n.x, n.y)) {
            hns[len] = n;
            len += 1;
        };

        return hns[0..len];
    }

    fn neighbors(self: Map, x: u32, y: u32) []Point {
        var len: u8 = 0;
        var ns: [4]Point = undefined;

        // x - 1, y
        if (x > 0) {
            ns[len] = Point{ .x = x - 1, .y = y };
            len += 1;
        }
        // x + 1, y
        if (x + 1 < self.x_len) {
            ns[len] = Point{ .x = x + 1, .y = y };
            len += 1;
        }
        // x, y - 1
        if (y > 0) {
            ns[len] = Point{ .x = x, .y = y - 1 };
            len += 1;
        }
        // x, y + 1
        if (y + 1 < self.y_len) {
            ns[len] = Point{ .x = x, .y = y + 1 };
            len += 1;
        }

        return ns[0..len];
    }
};

const Point = struct {
    x: u32,
    y: u32,
};
