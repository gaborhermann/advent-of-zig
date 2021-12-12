const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var cave_id = std.StringHashMap(u32).init(allocator);
    defer {
        // TODO how to free string keys of map?
        // while (it.next()) |k| {
        //     allocator.free(slice);
        // }

        cave_id.deinit();
    }

    var neighbors = std.ArrayList(std.ArrayList(u32)).init(allocator);
    defer {
        for (neighbors.items) |ns| {
            ns.deinit();
        }
        neighbors.deinit();
    }

    var ids: u32 = 0;

    _ = try getOrSetId(&cave_id, &neighbors, &ids, allocator, "start");
    _ = try getOrSetId(&cave_id, &neighbors, &ids, allocator, "end");

    var read_buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        var split = std.mem.split(line, "-");
        const from = split.next().?;
        const to = split.next().?;
        const from_id = try getOrSetId(&cave_id, &neighbors, &ids, allocator, from);
        const to_id = try getOrSetId(&cave_id, &neighbors, &ids, allocator, to);

        try neighbors.items[from_id].append(to_id);
        try neighbors.items[to_id].append(from_id);
    }

    var is_small_cave = try std.DynamicBitSet.initEmpty(ids, allocator);
    defer is_small_cave.deinit();
    {
        var it = cave_id.iterator();
        while (it.next()) |e| {
            if (std.ascii.isLower(e.key_ptr.*[0])) {
                is_small_cave.set(e.value_ptr.*);
            }
        }
    }

    var paths: u64 = 0;
    var been_to = try std.DynamicBitSet.initEmpty(ids, allocator);
    defer been_to.deinit();

    var stack = std.ArrayList(NextCave).init(allocator);
    defer stack.deinit();

    try stack.append(NextCave{ .id = 0, .n_idx = 0 });
    been_to.set(0);

    var double_visited: ?u32 = null;

    while (stack.items.len != 0) {
        const v = stack.pop();
        const ns = neighbors.items[v.id];
        if (v.n_idx >= ns.items.len) {
            if (double_visited == v.id) {
                double_visited = null;
            } else {
                been_to.unset(v.id);
            }
            continue;
        }

        try stack.append(NextCave{ .id = v.id, .n_idx = v.n_idx + 1 });
        const n = ns.items[v.n_idx];
        if (n == 1) {
            // found "end" node, new path
            paths += 1;
            continue;
        }
        if (!been_to.isSet(n)) {
            try stack.append(NextCave{ .id = n, .n_idx = 0 });
            if (is_small_cave.isSet(n)) {
                been_to.set(n);
            }
        } else if (double_visited == null and n != 0 and n != 1) {
            try stack.append(NextCave{ .id = n, .n_idx = 0 });
            double_visited = n;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{paths});
}

const NextCave = struct {
    id: u32,
    n_idx: u32,
};

fn getOrSetId(cave_id: *std.StringHashMap(u32), neighbors: *std.ArrayList(std.ArrayList(u32)), ids: *u32, allocator: *std.mem.Allocator, name_str: []const u8) !u32 {
    const name: []const u8 = try allocator.dupe(u8, name_str);
    if (cave_id.get(name)) |id| {
        return id;
    }

    const id: u32 = ids.*;
    const new_ids: u32 = id + 1;
    ids.* = new_ids;

    try cave_id.put(name, id);

    try neighbors.append(std.ArrayList(u32).init(allocator));
    return id;
}
