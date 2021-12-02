const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var depth: i32 = 0;
    var horizontal: i32 = 0;
    var aim: i32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            switch (line[0]) {
                'u' => {
                    // up
                    var val: i32 = try std.fmt.parseInt(i32, line[3..], 10);
                    aim -= val;
                },
                'd' => {
                    // down
                    var val: i32 = try std.fmt.parseInt(i32, line[5..], 10);
                    aim += val;
                },
                'f' => {
                    // forward
                    var val: i32 = try std.fmt.parseInt(i32, line[8..], 10);
                    horizontal += val;
                    depth += aim * val;
                },
                else => {
                    unreachable;
                },
            }
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{depth * horizontal});
}
