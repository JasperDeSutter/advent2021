const std = @import("std");
// iterators for everyone!
pub fn IterItem(comptime Itt: type) type {
    const next_decl = @typeInfo(@TypeOf(@field(Itt, "next")));

    if (comptime next_decl != .Fn) {
        @compileError("Iterator 'next' declaration is not a function");
    }
    // std.meta.activeTag(u: anytype)
    return @typeInfo(next_decl.Fn.return_type.?).Optional.child;
}
pub fn EnumerateResult(comptime Item: type) type {
    return struct {
        item: Item,
        i: usize,
    };
}
pub fn Enumerate(comptime Inner: type) type {
    const Item = IterItem(Inner);
    return struct {
        inner: Inner,
        i: usize,
        const Self = @This();
        pub fn new(inner: Inner) Self {
            return .{ .inner = inner, .i = 0 };
        }
        pub fn next(self: *Self) ?EnumerateResult(Item) {
            const item = self.inner.next() orelse return null;
            const i = self.i;
            self.i += 1;
            return EnumerateResult(Item){ .item = item, .i = i };
        }
    };
}

pub fn enumerate(it: anytype) Zip(@TypeOf(it), Range(usize)) { // Enumerate(@TypeOf(it)) {
    // return Enumerate(@TypeOf(it)).new(it);
    return zip(it, range(usize, 0, std.math.maxInt(usize)));
}

pub fn Range(comptime Item: type) type {
    return struct {
        i: Item,
        end: Item,
        negative: bool,
        first: bool,

        pub fn init(start: Item, end: Item) @This() {
            if (end > start) return .{ .i = start, .end = end, .negative = false, .first = true };
            return .{ .i = start, .end = end, .negative = true, .first = true };
        }

        pub fn next(self: *@This()) ?Item {
            if (self.first) {
                self.first = false;
                return self.i;
            }
            if (self.i == self.end) return null;
            if (self.negative) {
                self.i = self.i - 1;
            } else self.i = self.i + 1;
            return self.i;
        }
    };
}

pub fn range(comptime Item: type, start: Item, end: Item) Range(Item) {
    return Range(Item).init(start, end);
}

pub fn SliceIter(comptime Item: type) type {
    return struct {
        slice: []const Item,
        index: usize,
        pub fn init(slice: []const Item) @This() {
            return .{ .slice = slice, .index = 0 };
        }

        pub fn next(self: *@This()) ?*const Item {
            const i = self.index;
            if (i >= self.slice.len) return null;
            self.index += 1;
            return &self.slice[i];
        }
    };
}

pub fn iter(comptime Item: type, slice: []const Item) SliceIter(Item) {
    return SliceIter(Item).init(slice);
}

pub fn ZipResult(comptime Item1: type, comptime Item2: type) type {
    return struct {
        left: Item1,
        right: Item2,
    };
}

pub fn Zip(comptime Inner1: type, comptime Inner2: type) type {
    const Item1 = IterItem(Inner1);
    const Item2 = IterItem(Inner2);
    return struct {
        inner1: Inner1,
        inner2: Inner2,

        pub fn next(self: *@This()) ?ZipResult(Item1, Item2) {
            const left = self.inner1.next() orelse return null;
            const right = self.inner2.next() orelse return null;

            return ZipResult(Item1, Item2){
                .left = left,
                .right = right,
            };
        }
    };
}

pub fn zip(iter1: anytype, iter2: anytype) Zip(@TypeOf(iter1), @TypeOf(iter2)) {
    return .{ .inner1 = iter1, .inner2 = iter2 };
}

pub fn RefIter(comptime Inner: type) type {
    const Item = IterItem(@typeInfo(Inner).Pointer.child);
    return struct {
        inner: Inner,
        pub fn init(inner: Inner) @This() {
            return .{ .inner = inner };
        }

        pub fn next(self: *@This()) ?Item {
            return self.inner.next();
        }
    };
}

pub fn ref(inner: anytype) RefIter(@TypeOf(inner)) {
    return RefIter(@TypeOf(inner)).init(inner);
}

pub fn RepeatIter(comptime Item: type) type {
    return struct {
        item: Item,

        pub fn next(self: *@This()) ?Item {
            return self.item;
        }
    };
}

pub fn repeat(item: anytype) RepeatIter(@TypeOf(item)) {
    return .{ .item = item };
}
