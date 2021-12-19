const std = @import("std");

const sqrt = std.math.sqrt;
const abs = std.math.absInt;
const max = std.math.max;
const min = std.math.min;

fn floor(x: f64) i32 {
    return @floatToInt(i32, @floor(x));
}

fn ceil(x: f64) i32 {
    return @floatToInt(i32, @ceil(x));
}

fn float(x: i32) f64 {
    return @intToFloat(f64, x);
}

fn divCeil(x: i32, y: i32) i32 {
    const res = @divFloor(x, y);
    return if (res * y == x) res else res + 1;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;
    var read_buf: [1024]u8 = undefined;

    const line = (try in_stream.readUntilDelimiterOrEof(&read_buf, '\n')).?;
    // e.g. "target area: x=20..30, y=-10..-5"

    var split = std.mem.split(line["target area: ".len..], ", ");
    var x_str = std.mem.split(split.next().?["x=".len..], "..");
    const x1 = try std.fmt.parseInt(i32, x_str.next().?, 10);
    const x2 = try std.fmt.parseInt(i32, x_str.next().?, 10);

    var y_str = std.mem.split(split.next().?["y=".len..], "..");
    const y1 = try std.fmt.parseInt(i32, y_str.next().?, 10);
    const y2 = try std.fmt.parseInt(i32, y_str.next().?, 10);

    // s: step
    // x: initial x velocity
    // y: initial y velocity

    // f(s,x) =
    // if (s < x) -(s-x)(s-x-1)/2 + x(x+1)/2
    // if (s >= x) x(x+1)/2

    // find max y such that there exists an s, there exists an x
    // y1 <= (-s^2 + 2sy + s)/2 <= y2
    // x1 <= f(s,x) <= x2

    // We hit target with y iff there exist a step s:
    // y1 <= -(s-y)(s-y-1)/2 + y*(y+1)/2 <= y2     <==>
    // y1 <= (-s*s + s*y + s + y*s)/2 <= y2          <==>
    // y1 <= (-s^2 + s*(2*y + 1))/2 <= y2          <==>
    // 0 <= -s^2 + s*(2*y + 1) - 2*y1
    //   and    0 >= -s^2 + s*(2*y + 1) - 2*y2

    // solve for s:
    // y1s1 = (2*y + 1 - sqrt(4*y^2 + 4*y + 1 - 8*y1)) / 2
    // y1s2 = (2*y + 1 + sqrt(4*y^2 + 4*y + 1 - 8*y1)) / 2

    // y2s1 = (2*y + 1 - sqrt(4*y^2 + 4*y + 1 - 8*y2)) / 2
    // y2s1 = (2*y + 1 + sqrt(4*y^2 + 4*y + 1 - 8*y2)) / 2

    // y1s1 <= s <= y1s2 and (y2s2 <= s or s <= y2s1)   <==>
    // max(y2s2,y1s1) <= s <= y1s2   or  y1s1 <= s <= min(y1s2,y2s1)

    // Otherwise we cannot hit target with y:
    const highest_y: i32 = max(try abs(y1), try abs(y2));
    const lowest_y: i32 = -highest_y;

    var y: i32 = highest_y;
    var s: i32 = undefined;
    var num: u32 = 0;
    while (y >= lowest_y) : (y -= 1) {
        const y1s1 = (float(2 * y + 1) - sqrt(float(4 * y * y + 4 * y + 1 - 8 * y1))) / 2;
        const y1s2 = (float(2 * y + 1) + sqrt(float(4 * y * y + 4 * y + 1 - 8 * y1))) / 2;

        const y2s1 = (float(2 * y + 1) - sqrt(float(4 * y * y + 4 * y + 1 - 8 * y2))) / 2;
        const y2s2 = (float(2 * y + 1) + sqrt(float(4 * y * y + 4 * y + 1 - 8 * y2))) / 2;

        var xs = std.AutoHashMap(i32, void).init(allocator);
        defer xs.deinit();

        // iterate s
        s = max(max(ceil(y2s2), ceil(y1s1)), 0);
        while (s <= floor(y1s2)) : (s += 1) {
            const intervals = intervalX(y, s, x1, x2);
            for (intervals) |interval| {
                var x: i32 = interval.from;
                while (x <= interval.to) : (x += 1) {
                    try xs.put(x, {});
                }
            }
        }
        s = max(ceil(y1s1), 0);
        while (s <= min(floor(y1s2), floor(y2s1))) : (s += 1) {
            const intervals = intervalX(y, s, x1, x2);
            for (intervals) |interval| {
                var x: i32 = interval.from;
                while (x <= interval.to) : (x += 1) {
                    try xs.put(x, {});
                }
            }
        }
        num += xs.count();
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{num});
}

const Interval = struct {
    from: i32,
    to: i32,
};

fn intervalX(y: i32, s: i32, x1: i32, x2: i32) [3]Interval {
    var intervals: [3]Interval = undefined;
    // Solve for x:
    // if s < x:
    //   x1 <=  sum x-s+1 .. x  <= x2     <==>
    //   x1 <= s*x - (s-1)*s/2 <= x2      <==>
    //   x1/s + (s - 1)/2 <= x <= x2/s + (s - 1)/2

    var num: i32 = 0;
    {
        const min_x = max(divCeil(x1 + @divExact((s - 1) * s, 2), s), s + 1);
        const max_x = @divFloor(x2 + @divExact((s - 1) * s, 2), s);
        intervals[0] = Interval{ .from = min_x, .to = max_x };
    }

    // if s <= x:
    //   x1 <= (x*x + x) / 2 <= x2
    //  Solve:
    //   sx1 = (-1 - sqrt(1 + 8*x1)) / 2
    //   sx2 = (-1 + sqrt(1 + 8*x1)) / 2
    //
    //   sx3 = (-1 - sqrt(1 + 8*x2)) / 2
    //   sx4 = (-1 + sqrt(1 + 8*x2)) / 2
    //
    //  so:
    //   (x <= sx1  or  sx2 <= x)  and
    //    (sx3 <= x <= sx4)               <==>
    //   (max(sx3, s) <= x <= min(sx1, sx4)) or
    //    (max(sx2, sx3, s) <= x <= sx4)
    {
        const sx1 = floor((-1 - sqrt(float(1 + 8 * x1))) / 2);
        const sx2 = ceil((-1 + sqrt(float(1 + 8 * x1))) / 2);
        const sx3 = ceil((-1 - sqrt(float(1 + 8 * x2))) / 2);
        const sx4 = floor((-1 + sqrt(float(1 + 8 * x2))) / 2);
        {
            const min_x = max(sx3, 0);
            const max_x = min(min(sx1, sx4), s);
            intervals[1] = Interval{ .from = min_x, .to = max_x };
        }
        {
            const min_x = max(max(sx2, sx3), 0);
            const max_x = min(sx4, s);
            intervals[2] = Interval{ .from = min_x, .to = max_x };
        }
    }
    return intervals;
}
