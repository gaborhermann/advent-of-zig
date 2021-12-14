const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var ids = std.AutoArrayHashMap([2]u8, u16).init(allocator);
    defer ids.deinit();

    var rules = std.ArrayList(NextPairIds).init(allocator);
    defer rules.deinit();

    var read_buf: [1024]u8 = undefined;
    const template = (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')).?;
    var polymer = try allocator.dupe(u8, template);
    defer allocator.free(polymer);

    _ = try in_stream.readUntilDelimiterOrEof(&read_buf, '\n');
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        const from = [2]u8{ line[0], line[1] };
        const to: u8 = line[6];

        const to_left = [2]u8{ from[0], to };
        const to_right = [2]u8{ to, from[1] };

        const from_id = try getOrSetId(&ids, &rules, from);
        const to_left_id = try getOrSetId(&ids, &rules, to_left);
        const to_right_id = try getOrSetId(&ids, &rules, to_right);

        rules.items[from_id] = NextPairIds{ .left = to_left_id, .right = to_right_id };
    }

    const len = ids.count();

    var element_count = [_]u64{0} ** ('Z' - 'A' + 1);

    var pair_counts = try makeZeros(len, allocator);
    defer allocator.free(pair_counts);

    {
        var i: u16 = 0;
        while (i < polymer.len - 1) : (i += 1) {
            const from = [2]u8{ polymer[i], polymer[i + 1] };
            const from_id = ids.get(from).?;
            pair_counts[from_id] += 1;
            element_count[polymer[i] - 'A'] += 1;
        }
        element_count[polymer[i] - 'A'] += 1;
    }

    // We assume that every possible pair has a rule.

    var step: u16 = 0;
    while (step < 40) : (step += 1) {
        var next_pair_counts = try makeZeros(len, allocator);
        for (rules.items) |to, from| {
            next_pair_counts[to.left] += pair_counts[from];
            next_pair_counts[to.right] += pair_counts[from];

            element_count[ids.keys()[to.left][1] - 'A'] += pair_counts[from];
        }
        allocator.free(pair_counts);
        pair_counts = next_pair_counts;
    }

    var max: u64 = 0;
    var min: u64 = std.math.maxInt(u64);
    for (element_count) |cnt, i| {
        if (cnt == 0) {
            continue;
        }
        if (max < cnt) {
            max = cnt;
        }
        if (min > cnt) {
            min = cnt;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{max - min});
}

fn getOrSetId(ids: *std.AutoArrayHashMap([2]u8, u16), rules: *std.ArrayList(NextPairIds), pair: [2]u8) !u16 {
    if (ids.get(pair)) |id| {
        return id;
    } else {
        var id = @intCast(u16, ids.count());
        try ids.put(pair, id);
        try rules.append(undefined);
        return id;
    }
}

/// Caller owns returned memory.
fn makeZeros(len: usize, allocator: *std.mem.Allocator) ![]u64 {
    var slice = try allocator.alloc(u64, len);
    {
        var i: u16 = 0;
        while (i < slice.len) : (i += 1) {
            slice[i] = 0;
        }
    }
    return slice;
}

const NextPairIds = struct {
    left: u16,
    right: u16,
};
