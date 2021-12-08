const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var easy_digits: u64 = 0;

    var read_buf: [1024 * 64]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        var split_line = std.mem.split(line, " | ");
        {
            // TODO parse
            var patterns_str = split_line.next();

            var digits_str = split_line.next();
            // std.debug.print("{s}\n", .{digits_str});

            var digits_split = std.mem.split(digits_str.?, " ");
            while (digits_split.next()) |digit_str| {
                switch (digit_str.len) {
                    2, 3, 4, 7 => {
                        easy_digits += 1;
                    },
                    else => {},
                }
                // std.debug.print("{d}\n", .{digit_str.len});
            }
        }
    }

    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();

    // const allocator = &arena.allocator;

    // var positions = std.ArrayList(u32).init(allocator);
    // defer positions.deinit();

    // var sum: i64 = 0;

    // // Read all positions.
    // while (split.next()) |pos_str| {
    //     const pos = try std.fmt.parseInt(u32, pos_str, 10);
    //     try positions.append(pos);
    //     sum += pos;
    // }

    // // Sort.
    // std.sort.sort(u32, positions.items, {}, comptime std.sort.asc(u32));

    // const len: u32 = @truncate(u32, positions.items.len);
    // const max_pos: u32 = positions.items[len - 1];

    // var min_sort_pos: u32 = 0;
    // var min_sum: i64 = sum;

    // var pos: u32 = 1;
    // var i: u32 = 0;
    // while (pos <= max_pos) : (pos += 1) {
    //     var prev_i: u32 = i;
    //     while (pos > positions.items[i]) {
    //         i += 1;
    //     }
    //     // We are getting further from i crabs,
    //     // closer to (len - i) crabs.
    //     var diff: i64 = (@as(i64, i) - len) + @as(i64, i);
    //     sum += diff;
    //     if (min_sum > sum) {
    //         min_sum = sum;
    //         min_sort_pos = pos;
    //     }
    // }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{easy_digits});
}
