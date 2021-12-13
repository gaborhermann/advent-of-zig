const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var ps = std.AutoArrayHashMap([2]u32, void).init(allocator);

    var read_buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        if (line.len == 0) {
            break;
        }
        var split = std.mem.split(line, ",");
        var p: [2]u32 = undefined;
        p[0] = try std.fmt.parseInt(u32, split.next().?, 10);
        p[1] = try std.fmt.parseInt(u32, split.next().?, 10);
        try ps.put(p, {});
    }

    while (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')) |line| {
        const axis_char = line[11];
        const fold_axis: u1 = switch (axis_char) {
            'x' => 0,
            'y' => 1,
            else => unreachable,
        };
        const move_axis: u1 = fold_axis +% 1;
        const fold = try std.fmt.parseInt(u32, line[13..], 10);

        var new = std.AutoArrayHashMap([2]u32, void).init(allocator);
        var it = ps.iterator();
        while (it.next()) |e| {
            const p: [2]u32 = e.key_ptr.*;
            var folded: [2]u32 = undefined;
            if (p[fold_axis] > fold) {
                folded[fold_axis] = fold - (p[fold_axis] - fold);
            } else {
                folded[fold_axis] = p[fold_axis];
            }
            folded[move_axis] = p[move_axis];
            try new.put(folded, {});
        }
        ps.deinit();
        ps = new;

        break;
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{ps.count()});

    ps.deinit();
}
