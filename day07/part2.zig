const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var read_buf: [1024 * 64]u8 = undefined;
    const line = try in_stream.readUntilDelimiterOrEof(&read_buf, '\n');
    var split = std.mem.split(line.?, ",");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var positions = std.ArrayList(u32).init(allocator);
    defer positions.deinit();

    var max_pos: u32 = 0;
    // Read all positions.
    while (split.next()) |pos_str| {
        const pos = try std.fmt.parseInt(u32, pos_str, 10);
        try positions.append(pos);
        if (pos > max_pos) {
            max_pos = pos;
        }
    }

    const len: u32 = @truncate(u32, positions.items.len);

    var min_sort_pos: u32 = 0;
    var min_sum: i64 = std.math.maxInt(i64);

    var pos: u32 = 0;
    while (pos <= max_pos) : (pos += 1) {
        var sum: i64 = 0;
        // Brute force!
        for (positions.items) |p| {
            const dist: i64 = try std.math.absInt(@as(i64, pos) - @as(i64, p));
            sum += fuel_for_dist(dist);
        }
        if (min_sum > sum) {
            min_sum = sum;
            min_sort_pos = pos;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{min_sum});
}

fn fuel_for_dist(n: i64) i64 {
    return @divExact(n * (n + 1), 2);
}
