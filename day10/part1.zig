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

    var total: u64 = 0;
    var read_buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                else => {
                    const last = stack.pop();
                    if ((try matching(last)) != c) {
                        total += try score(c);
                        break;
                    }
                },
            }
        }
        stack.shrinkRetainingCapacity(0);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{total});
}

fn matching(open: u8) !u8 {
    switch (open) {
        '(' => return ')',
        '[' => return ']',
        '{' => return '}',
        '<' => return '>',
        else => unreachable,
    }
}

fn score(close: u8) !u32 {
    return switch (close) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => unreachable,
    };
}
