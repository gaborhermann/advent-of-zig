const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var read_buf: [1024]u8 = undefined;
    const line = try in_stream.readUntilDelimiterOrEof(&read_buf, '\n');
    var split = std.mem.split(line.?, ",");

    // Circular buffer. buf[(zero + x) % 9] stores
    // current number of fish with internal timer of x.
    var buf: [9]u64 = [_]u64{0} ** 9;
    // Index of current zero.
    var zero: u8 = 0;

    // Read all timers.
    while (split.next()) |timer_str| {
        const timer = try std.fmt.parseInt(u8, timer_str, 10);
        buf[(zero + timer) % 9] += 1;
    }

    {
        const days: u64 = 80;
        comptime var i: u64 = 0;
        inline while (i < days) : (i += 1) {
            // Ticks a day, spawns new fish.
            zero = (zero + 1) % 9;
            // Restart timer of 0 day fish of previous day.
            buf[(zero + 6) % 9] += buf[(zero + 8) % 9];
        }
    }

    var sum: u64 = 0;
    {
        var i: u8 = 0;
        while (i < 9) : (i += 1) {
            sum += buf[i];
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{sum});
}
