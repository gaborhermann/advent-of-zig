const std = @import("std");

const Board = struct {
    row_marked: [5]u8 = [_]u8{0} ** 5,
    col_marked: [5]u8 = [_]u8{0} ** 5,

    // indexed [row * 5 + col]
    data: [25]u8 = [_]u8{0} ** 25,
    marks: [25]bool = [_]bool{false} ** 25,
};

const Pos = struct {
    board: u32,
    row: u8,
    col: u8,
};

fn parse_board(in_stream: anytype) !?Board {
    var buf: [1024]u8 = undefined;

    // read empty line
    var empty = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    if (empty == null) {
        return null;
    }

    var board = Board{};

    var i: u8 = 0;
    while (i < 5) : (i += 1) {
        var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        if (line == null) {
            return null;
        }
        var split = std.mem.split(line.?, " ");
        var j: u8 = 0;
        while (split.next()) |num_str| {
            if (num_str.len == 0) {
                continue;
            }
            const num: u8 = try std.fmt.parseInt(u8, num_str, 10);
            board.data[i * 5 + j] = num;
            j += 1;
        }
    }
    return board;
}

pub fn find_winner(boards: anytype, index: anytype, numbers: anytype) !u32 {
    for (numbers.items) |num| {
        if (index.get(num)) |positions| {
            for (positions.items) |pos| {
                var b: *Board = &(boards.items[pos.board]);
                b.row_marked[pos.row] += 1;
                b.col_marked[pos.col] += 1;
                b.marks[pos.row * 5 + pos.col] = true;

                if (b.row_marked[pos.row] == 5 or b.col_marked[pos.col] == 5) {
                    // we've got a winner
                    var last_value: u32 = b.data[pos.row * 5 + pos.col];

                    var sum: u32 = 0;
                    var i: u8 = 0;
                    while (i < 25) : (i += 1) {
                        if (!b.marks[i]) {
                            sum += b.data[i];
                        }
                    }
                    return sum * last_value;
                }
            }
        }
    }
    unreachable;
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

    var numbers = std.ArrayList(u8).init(allocator);
    defer numbers.deinit();

    var index = std.AutoHashMap(u8, std.ArrayList(Pos)).init(allocator);
    defer {
        var it = index.valueIterator();
        while (it.next()) |val| {
            val.deinit();
        }

        index.deinit();
    }

    var boards = std.ArrayList(Board).init(allocator);
    defer boards.deinit();

    // Parse numbers.
    {
        const line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        var split = std.mem.split(line.?, ",");
        while (split.next()) |num_str| {
            var num: u8 = try std.fmt.parseInt(u8, num_str, 10);
            try numbers.append(num);
        }
    }

    // Parse and index boards.
    {
        var bs: u32 = 0;
        while (try parse_board(in_stream)) |board| {
            try boards.append(board);
            for (board.data) |num, idx| {
                const x: u8 = @truncate(u8, idx);
                const i: u8 = x / 5;
                const j: u8 = x % 5;
                const pos = Pos{ .board = bs, .row = i, .col = j };

                // get or create array list
                var positions: std.ArrayList(Pos) = undefined;
                if (index.get(num)) |ps| {
                    positions = ps;
                } else {
                    positions = std.ArrayList(Pos).init(allocator);
                }

                try positions.append(pos);
                try index.put(num, positions);
            }
            bs += 1;
        }
    }

    var score = find_winner(boards, index, numbers);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{score});
}
