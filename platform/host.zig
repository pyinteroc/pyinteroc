const std = @import("std");
const builtin = @import("builtin");
const str = @import("glue").str;
const RocStr = str.RocStr;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;
const maxInt = std.math.maxInt;

const mem = std.mem;
const Allocator = mem.Allocator;

extern fn roc__mainForHost_1_exposed_generic([*]u8) void;
extern fn roc__mainForHost_1_exposed_size() i64;
extern fn roc__mainForHost_0_caller(*const u8, [*]u8, [*]u8) void;
extern fn roc__mainForHost_0_size() i64;
extern fn roc__mainForHost_0_result_size() i64;

const Align = 2 * @alignOf(usize);
extern fn malloc(size: usize) callconv(.C) ?*align(Align) anyopaque;
extern fn realloc(c_ptr: [*]align(Align) u8, size: usize) callconv(.C) ?*anyopaque;
extern fn free(c_ptr: [*]align(Align) u8) callconv(.C) void;
extern fn memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.C) void;
extern fn memset(dst: [*]u8, value: i32, size: usize) void;
extern fn kill(pid: c_int, sig: c_int) c_int;
extern fn shm_open(name: *const i8, oflag: c_int, mode: c_uint) c_int;
extern fn mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) *anyopaque;
extern fn getppid() c_int;

const DEBUG: bool = false;

export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        var ptr = malloc(size);
        const stdout = std.io.getStdOut().writer();
        stdout.print("alloc:   {d} (alignment {d}, size {d})\n", .{ ptr, alignment, size }) catch unreachable;
        return ptr;
    } else {
        return malloc(size);
    }
}

export fn roc_realloc(c_ptr: *anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("realloc: {d} (alignment {d}, old_size {d})\n", .{ c_ptr, alignment, old_size }) catch unreachable;
    }

    return realloc(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))), new_size);
}

export fn roc_dealloc(c_ptr: *anyopaque, alignment: u32) callconv(.C) void {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("dealloc: {d} (alignment {d})\n", .{ c_ptr, alignment }) catch unreachable;
    }

    free(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))));
}

export fn roc_panic(msg: *RocStr, tag_id: u32) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    switch (tag_id) {
        0 => {
            stderr.print("Roc standard library crashed with message\n\n    {s}\n\nShutting down\n", .{msg.asSlice()}) catch unreachable;
        },
        1 => {
            stderr.print("Application crashed with message\n\n    {s}\n\nShutting down\n", .{msg.asSlice()}) catch unreachable;
        },
        else => unreachable,
    }
    std.process.exit(1);
}

export fn roc_dbg(loc: *RocStr, msg: *RocStr, src: *RocStr) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    stderr.print("[{s}] {s} = {s}\n", .{ loc.asSlice(), src.asSlice(), msg.asSlice() }) catch unreachable;
}

export fn roc_memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void {
    return memset(dst, value, size);
}

fn roc_getppid() callconv(.C) c_int {
    return getppid();
}

fn roc_getppid_windows_stub() callconv(.C) c_int {
    return 0;
}

fn roc_shm_open(name: *const i8, oflag: c_int, mode: c_uint) callconv(.C) c_int {
    return shm_open(name, oflag, mode);
}
fn roc_mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) callconv(.C) *anyopaque {
    return mmap(addr, length, prot, flags, fd, offset);
}

comptime {
    if (builtin.os.tag == .macos or builtin.os.tag == .linux) {
        @export(roc_getppid, .{ .name = "roc_getppid", .linkage = .Strong });
        @export(roc_mmap, .{ .name = "roc_mmap", .linkage = .Strong });
        @export(roc_shm_open, .{ .name = "roc_shm_open", .linkage = .Strong });
    }

    if (builtin.os.tag == .windows) {
        @export(roc_getppid_windows_stub, .{ .name = "roc_getppid", .linkage = .Strong });
    }
}

const Unit = extern struct {};

pub export fn main() u8 {
    const allocator = std.heap.page_allocator;

    // NOTE the return size can be zero, which will segfault. Always allocate at least 8 bytes
    const size = @max(8, @as(usize, @intCast(roc__mainForHost_1_exposed_size())));
    const raw_output = allocator.alignedAlloc(u8, @alignOf(u64), @as(usize, @intCast(size))) catch unreachable;
    var output = @as([*]u8, @ptrCast(raw_output));

    defer {
        allocator.free(raw_output);
    }

    var timer = std.time.Timer.start() catch unreachable;

    roc__mainForHost_1_exposed_generic(output);

    call_the_closure(output);

    const nanos = timer.read();
    const seconds = (@as(f64, @floatFromInt(nanos)) / 1_000_000_000.0);

    if (DEBUG) {
        const stderr = std.io.getStdErr().writer();
        stderr.print("runtime: {d:.3}ms\n", .{seconds * 1000}) catch unreachable;
    }
    return 0;
}

fn to_seconds(tms: std.os.timespec) f64 {
    return @as(f64, @floatFromInt(tms.tv_sec)) + (@as(f64, @floatFromInt(tms.tv_nsec)) / 1_000_000_000.0);
}

fn call_the_closure(closure_data_pointer: [*]u8) void {
    const allocator = std.heap.page_allocator;

    const size = roc__mainForHost_0_result_size();

    if (size == 0) {
        // the function call returns an empty record
        // allocating 0 bytes causes issues because the allocator will return a NULL pointer
        // So it's special-cased
        const flags: u8 = 0;
        var result: [1]u8 = .{0};
        roc__mainForHost_0_caller(&flags, closure_data_pointer, &result);

        return;
    }

    const raw_output = allocator.alignedAlloc(u8, @alignOf(u64), @as(usize, @intCast(size))) catch unreachable;
    var output = @as([*]u8, @ptrCast(raw_output));

    defer {
        allocator.free(raw_output);
    }

    const flags: u8 = 0;
    roc__mainForHost_0_caller(&flags, closure_data_pointer, output);

    return;
}


// ///// Effects start here

fn RocResultUnion(comptime T:type, comptime E:type) type {
    return extern struct {
        payload: extern union {ok: T, err: E},
        tag: u8,
        pub const len = @sizeOf(@This());
    };
}

fn RocResult_EmptyErr(comptime T:type) type {
    return RocResultUnion(T, void);
}

fn RocResult_EmptyPayload(comptime E:type) type {
    return RocResultUnion(void, E);
}

const RocRes_Void_Str = RocResult_EmptyPayload(RocStr);


pub export fn roc_fx_getLine() str.RocStr {
    return roc_fx_getLine_help() catch return str.RocStr.empty();
}

fn roc_fx_getLine_help() !RocStr {
    const stdin = std.io.getStdIn().reader();
    var buf: [400]u8 = undefined;

    const line: []u8 = (try stdin.readUntilDelimiterOrEof(&buf, '\n')) orelse "";

    return str.RocStr.init(@as([*]const u8, @ptrCast(line)), line.len);
}

pub export fn roc_fx_putLine(rocPath: *str.RocStr) i64 {
    const stdout = std.io.getStdOut().writer();

    for (rocPath.asSlice()) |char| {
        stdout.print("{c}", .{char}) catch unreachable;
    }

    stdout.print("\n", .{}) catch unreachable;

    return 0;
}

const GetInt = extern struct {
    value: i64,
    error_code: u8,
    is_error: bool,
};

pub export fn roc_fx_getInt() GetInt {
    if (roc_fx_getInt_help()) |value| {
        const get_int = GetInt{ .is_error = false, .value = value, .error_code = 0 };
        return get_int;
    } else |err| switch (err) {
        error.InvalidCharacter => {
            return GetInt{ .is_error = true, .value = 0, .error_code = 0 };
        },
        else => {
            return GetInt{ .is_error = true, .value = 0, .error_code = 1 };
        },
    }

    return 0;
}

fn roc_fx_getInt_help() !i64 {
    const stdin = std.io.getStdIn().reader();
    var buf: [40]u8 = undefined;

    // make sure to strip `\r` on windows
    const raw_line: []u8 = (try stdin.readUntilDelimiterOrEof(&buf, '\n')) orelse "";
    const line = std.mem.trimRight(u8, raw_line, &std.ascii.whitespace);

    return std.fmt.parseInt(i64, line, 10);
}

pub export fn roc_fx_stdoutLine(rocPath: *RocStr) RocRes_Void_Str {
    const errMsgIfAny = "ERROR";
    return roc_fx_stdoutLine_help(rocPath) catch return .{
        .payload = .{ .err = RocStr.init(errMsgIfAny, errMsgIfAny.len) },
        .tag = 0
    };
}

fn roc_fx_stdoutLine_help(rocPath: *RocStr) !RocRes_Void_Str {
    const stdout = std.io.getStdOut().writer();
    _ = stdout.write("testing\n") catch unreachable;
    const slice = rocPath.asSlice();
    stdout.print("{s}", .{slice}) catch unreachable;
    
    return .{
        .payload = .{ .err = RocStr.init("", 0) },
        .tag = 1
    };
}