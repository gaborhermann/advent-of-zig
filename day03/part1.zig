const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    const digits = 12;

    var buf: [digits]u8 = undefined;

    var zeros = [_]u32{0} ** digits;
    var ones = [_]u32{0} ** digits;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            comptime var i = 0;
            inline while (i < digits) : (i += 1) {
                switch (line[i]) {
                    '0' => zeros[i] += 1,
                    '1' => ones[i] += 1,
                    else => unreachable,
                }
            }
        }
    }

    var gamma = [_]u8{'x'} ** digits;
    var epsilon = [_]u8{'x'} ** digits;
    comptime var i = 0;
    inline while (i < digits) : (i += 1) {
        if (ones[i] > zeros[i]) {
            gamma[i] = '1';
            epsilon[i] = '0';
        } else {
            gamma[i] = '0';
            epsilon[i] = '1';
        }
    }

    var gamma_dec: u32 = try std.fmt.parseInt(u32, &gamma, 2);
    var epsilon_dec: u32 = try std.fmt.parseInt(u32, &epsilon, 2);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{epsilon_dec * gamma_dec});
}
