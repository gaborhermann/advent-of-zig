const std = @import("std");

/// This is a refactor of part1.zig that makes it easier to
/// do part2 linearly.
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

    // Read all positions.
    while (split.next()) |pos_str| {
        const pos = try std.fmt.parseInt(u32, pos_str, 10);
        try positions.append(pos);
    }

    var crabs: []u32 = positions.items;

    // Sort.
    std.sort.sort(u32, crabs, {}, comptime std.sort.asc(u32));

    const len: u32 = @truncate(u32, crabs.len);
    const min_pos: u32 = crabs[0];
    const max_pos: u32 = crabs[len - 1];

    var sum_dist_left: i64 = 0;
    var sum_dist_right: i64 = 0;

    for (crabs) |pos| {
        sum_dist_right += pos - min_pos;
    }

    var min_fuel_pos: u32 = min_pos;
    var min_fuel: i64 = sum_dist_left + sum_dist_right;

    var pos: u32 = min_pos + 1;
    var i: u32 = 0;
    while (pos <= max_pos) : (pos += 1) {
        while (pos > crabs[i]) {
            i += 1;
        }

        const crabs_left: u32 = i;
        const crabs_right: u32 = len - i;

        // We are getting further from i crabs,
        sum_dist_left += crabs_left;
        // closer to (len - i) crabs.
        sum_dist_right -= crabs_right;

        const total_fuel = sum_dist_left + sum_dist_right;
        if (min_fuel > total_fuel) {
            min_fuel = total_fuel;
            min_fuel_pos = pos;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{min_fuel});
}
