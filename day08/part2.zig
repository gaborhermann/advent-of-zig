const std = @import("std");

/// Returns output value
fn process_line(line: anytype) !u32 {
    var encoded_digits = [_]u8{0} ** 10;
    var encoded_display = [_]u8{0} ** 4;

    var split_line = std.mem.split(line, " | ");
    {
        var str = split_line.next();
        var digits_split = std.mem.split(str.?, " ");
        var i: u8 = 0;
        while (digits_split.next()) |digit_str| {
            for (digit_str) |char| {
                encoded_digits[i] += @as(u8, 1) << @intCast(u3, char - 'a');
            }
            i += 1;
        }
    }

    {
        var str = split_line.next();
        var digits_split = std.mem.split(str.?, " ");
        var i: u8 = 0;
        while (digits_split.next()) |digit_str| {
            for (digit_str) |char| {
                encoded_display[i] += @as(u8, 1) << @intCast(u3, char - 'a');
            }
            i += 1;
        }
    }

    const e1: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 2) {
            break :blk e;
        };
        unreachable;
    };
    const e7: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 3) {
            break :blk e;
        };
        unreachable;
    };
    const e4: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 4) {
            break :blk e;
        };
        unreachable;
    };
    const e8: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 7) {
            break :blk e;
        };
        unreachable;
    };

    const eA: u8 = e7 - (e7 & e1);
    const e9: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 6 and @popCount(u8, e - (e & (e4 + eA))) == 1) {
            break :blk e;
        };
        unreachable;
    };
    const eG: u8 = e9 - (e9 & (e4 + eA));

    const eE: u8 = e8 - e9;
    const e3: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 5 and @popCount(u8, e - (e & (e1 + eA + eG))) == 1) {
            break :blk e;
        };
        unreachable;
    };
    const eD: u8 = e3 - (e3 & (e1 + eA + eG));

    const eB: u8 = e8 - (e1 + eA + eD + eE + eG);
    const e0: u8 = eA + eB + eE + eG + e1;
    const e6: u8 = blk: {
        for (encoded_digits) |e| if (@popCount(u8, e) == 6 and e != e0 and e != e9) {
            break :blk e;
        };
        unreachable;
    };
    const eF = e6 & e1;
    const eC = e1 - eF;
    const e2 = eA + eC + eD + eE + eG;
    const e5 = eA + eB + eD + eF + eG;

    var decode = [_]u8{0} ** 128;
    decode[e0] = 0;
    decode[e1] = 1;
    decode[e2] = 2;
    decode[e3] = 3;
    decode[e4] = 4;
    decode[e5] = 5;
    decode[e6] = 6;
    decode[e7] = 7;
    decode[e8] = 8;
    decode[e9] = 9;

    var output: u32 = 0;
    for (encoded_display) |digit| {
        output = output * 10 + decode[digit];
    }
    return output;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var easy_digits: u64 = 0;

    var read_buf: [1024 * 64]u8 = undefined;
    var total: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        var value = try process_line(line);
        total += value;
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{total});
}
