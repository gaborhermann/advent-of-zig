const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var depth: u32 = 0;
    var horizontal: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            switch (line[0]) {
                'u' => {
                    // up
                    var val: u32 = try std.fmt.parseInt(u32, line[3..], 10);
                    depth -= val;
                },
                'd' => {
                    // down
                    var val: u32 = try std.fmt.parseInt(u32, line[5..], 10);
                    depth += val;
                },
                'f' => {
                    // forward
                    var val: u32 = try std.fmt.parseInt(u32, line[8..], 10);
                    horizontal += val;
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
