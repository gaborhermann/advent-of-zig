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

    // indexed: map[y * x_len + x]
    const map = map_list.items;
    const y_len: u64 = map.len / x_len;

    var total: u64 = 0;
    var y: u32 = 0;
    while (y < y_len) : (y += 1) {
        var x: u32 = 0;
        while (x < x_len) : (x += 1) {
            const height = map[y * x_len + x];
            const risk_level: u64 = blk: {
                // x - 1, y
                if (x > 0) if (height >= map[y * x_len + (x - 1)]) {
                    break :blk 0;
                };
                // x + 1, y
                if (x + 1 < x_len) if (height >= map[y * x_len + (x + 1)]) {
                    break :blk 0;
                };
                // x, y - 1
                if (y > 0) if (height >= map[(y - 1) * x_len + x]) {
                    break :blk 0;
                };
                // x, y + 1
                if (y + 1 < y_len) if (height >= map[(y + 1) * x_len + x]) {
                    break :blk 0;
                };
                break :blk height + 1;
            };
            total += risk_level;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{total});
}
