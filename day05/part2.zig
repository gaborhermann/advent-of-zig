const std = @import("std");

const Line = struct {
    x1: u32,
    y1: u32,
    x2: u32,
    y2: u32,
};

fn sign(x: i64) i64 {
    if (x > 0) return 1;
    if (x < 0) return -1;
    return 0;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;
    var lines = std.ArrayList(Line).init(allocator);
    defer lines.deinit();

    var max_x: u32 = 0;
    var max_y: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split = std.mem.split(line, " -> ");

        var start = split.next().?;
        var x1y1 = std.mem.split(start, ",");
        var x1 = try std.fmt.parseInt(u32, x1y1.next().?, 10);
        var y1 = try std.fmt.parseInt(u32, x1y1.next().?, 10);

        var end = split.next().?;
        var x2y2 = std.mem.split(end, ",");
        var x2 = try std.fmt.parseInt(u32, x2y2.next().?, 10);
        var y2 = try std.fmt.parseInt(u32, x2y2.next().?, 10);

        var li = Line{ .x1 = x1, .y1 = y1, .x2 = x2, .y2 = y2 };
        try lines.append(li);

        if (x1 > max_x) {
            max_x = x1;
        }
        if (x2 > max_x) {
            max_x = x2;
        }
        if (y1 > max_y) {
            max_y = y1;
        }
        if (y2 > max_y) {
            max_y = y2;
        }
    }

    const size = (max_x + 1) * (max_y + 1);

    var covered = try std.DynamicBitSet.initEmpty(size, allocator);
    defer covered.deinit();

    var overlap = try std.DynamicBitSet.initEmpty(size, allocator);
    defer overlap.deinit();

    var num_overlap: u32 = 0;
    for (lines.items) |li| {
        var x1: i64 = li.x1;
        var y1: i64 = li.y1;
        var x2: i64 = li.x2;
        var y2: i64 = li.y2;

        // Only needed to remove this filter compared to part 1 :)
        // if (x1 != x2 and y1 != y2) {
        //     continue;
        // }

        var dir_x: i64 = sign(x2 - x1);
        var dir_y: i64 = sign(y2 - y1);
        while (!(x1 == x2 and y1 == y2)) : ({
            x1 += dir_x;
            y1 += dir_y;
        }) {
            var to_add: u32 = blk: {
                // TODO factor this out to a func. How to modify BitSet?
                var x = @intCast(u16, x1);
                var y = @intCast(u16, y1);
                const idx = x * max_y + y;
                if (overlap.isSet(idx)) {
                    break :blk 0;
                }
                if (covered.isSet(idx)) {
                    overlap.set(idx);
                    break :blk 1;
                }
                covered.set(idx);
                break :blk 0;
            };
            num_overlap += to_add;
        }
        var to_add: u32 = blk: {
            var x = @intCast(u16, x1);
            var y = @intCast(u16, y1);
            const idx = x * max_y + y;
            if (overlap.isSet(idx)) {
                break :blk 0;
            }
            if (covered.isSet(idx)) {
                overlap.set(idx);
                break :blk 1;
            }
            covered.set(idx);
            break :blk 0;
        };
        num_overlap += to_add;
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{num_overlap});
}
