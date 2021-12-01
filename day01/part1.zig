const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    const first = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var prev: u32 = try std.fmt.parseInt(u32, first.?, 10);

    var inc: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            var x: u32 = try std.fmt.parseInt(u32, line, 10);
            if (x > prev) {
                inc += 1;
            }
            prev = x;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{inc});
}
