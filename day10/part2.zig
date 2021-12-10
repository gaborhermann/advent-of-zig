const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    var scores = std.ArrayList(u64).init(allocator);
    defer scores.deinit();

    var read_buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        var illegal = false;

        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                else => {
                    const last = stack.pop();
                    if ((try matching(last)) != c) {
                        illegal = true;
                        break;
                    }
                },
            }
        }

        if (illegal) {
            stack.shrinkRetainingCapacity(0);
        } else {
            var total: u64 = 0;
            while (stack.items.len != 0) {
                const last = stack.pop();
                total *= 5;
                total += try score(try matching(last));
            }
            try scores.append(total);
        }
    }

    std.sort.sort(u64, scores.items, {}, comptime std.sort.asc(u64));

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{scores.items[scores.items.len / 2]});
}

fn matching(open: u8) !u8 {
    return switch (open) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',
        else => unreachable,
    };
}

fn score(close: u8) !u32 {
    return switch (close) {
        ')' => 1,
        ']' => 2,
        '}' => 3,
        '>' => 4,
        else => unreachable,
    };
}
