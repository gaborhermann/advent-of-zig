const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    const window_size = 3;

    // circular buffer
    var window = [_]u32{0} ** window_size;
    var last_idx: u32 = 0;

    var prev_sum: u32 = 0;

    // Fill first full window.
    inline for ([_]u8{0} ** window_size) |i| {
        const line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        var x: u32 = try std.fmt.parseInt(u32, line.?, 10);

        var sum = prev_sum - window[last_idx] + x;

        window[last_idx] = x;
        prev_sum = sum;
        last_idx = (last_idx + 1) % window_size;
    }

    // Iterate over rest.
    var inc: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            var x: u32 = try std.fmt.parseInt(u32, line, 10);

            var sum = prev_sum - window[last_idx] + x;
            if (sum > prev_sum) {
                inc += 1;
            }

            window[last_idx] = x;
            prev_sum = sum;
            last_idx = (last_idx + 1) % window_size;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{inc});
}
