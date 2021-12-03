const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    const digits = 12;
    const max_numbers = 1200;

    var buf: [digits]u8 = undefined;

    // indexed as [col * max_numbers + row]
    var data = [_]u8{0} ** (digits * max_numbers);

    var j: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            comptime var i = 0;
            inline while (i < digits) : (i += 1) {
                data[i * max_numbers + j] = line[i];
            }
            j += 1;
        }
    }
    const numbers = j;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var zeros = std.ArrayList(u32).init(allocator);
    try zeros.ensureTotalCapacity(numbers);

    j = 0;
    while (j < numbers) : (j += 1) {
        try zeros.append(j);
    }

    var ones = std.ArrayList(u32).init(allocator);
    try ones.ensureTotalCapacity(numbers);
    j = 0;
    while (j < numbers) : (j += 1) {
        try ones.append(j);
    }

    var filtered = zeros;

    var oxygen = [_]u8{0} ** digits;

    var ii: u32 = 0;
    while (ii < digits) : (ii += 1) {
        var zs: u32 = 0;
        var os: u32 = 0;
        for (filtered.items) |jj| {
            switch (data[ii * max_numbers + jj]) {
                '0' => {
                    zeros.items[zs] = jj;
                    zs += 1;
                },
                '1' => {
                    ones.items[os] = jj;
                    os += 1;
                },
                else => unreachable,
            }
        }
        zeros.items = zeros.items[0..zs];
        ones.items = ones.items[0..os];
        if (zs > os) {
            filtered = zeros;
            oxygen[ii] = '0';
        } else {
            filtered = ones;
            oxygen[ii] = '1';
        }
    }

    j = 0;
    while (j < numbers) : (j += 1) {
        try zeros.append(j);
    }

    ones = std.ArrayList(u32).init(allocator);
    try ones.ensureTotalCapacity(numbers);
    j = 0;
    while (j < numbers) : (j += 1) {
        try ones.append(j);
    }

    filtered = zeros;

    var co2 = [_]u8{0} ** digits;

    ii = 0;
    while (ii < digits and filtered.items.len > 1) : (ii += 1) {
        var zs: u32 = 0;
        var os: u32 = 0;
        for (filtered.items) |jj| {
            switch (data[ii * max_numbers + jj]) {
                '0' => {
                    zeros.items[zs] = jj;
                    zs += 1;
                },
                '1' => {
                    ones.items[os] = jj;
                    os += 1;
                },
                else => unreachable,
            }
        }
        zeros.items = zeros.items[0..zs];
        ones.items = ones.items[0..os];
        if (zs <= os) {
            filtered = zeros;
            co2[ii] = '0';
        } else {
            filtered = ones;
            co2[ii] = '1';
        }
    }
    var jj = filtered.items[0];
    while (ii < digits) : (ii += 1) {
        co2[ii] = data[ii * max_numbers + jj];
    }

    var oxygen_dec: u32 = try std.fmt.parseInt(u32, &oxygen, 2);
    var co2_dec: u32 = try std.fmt.parseInt(u32, &co2, 2);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{oxygen_dec * co2_dec});
}
