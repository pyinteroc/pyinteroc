const std = @import("std");
const builtin = @import("builtin");

const glue = @import("crates/glue.zig");

const str = glue.str;
const RocStr = glue.str.RocStr;
const list = glue.list;
const RocList = glue.list.RocList;

const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;
const maxInt = std.math.maxInt;

const mem = std.mem;
const Allocator = mem.Allocator;

const PyArg = extern struct {
    function: [*]const u8,
    args: i32
};

extern fn roc__mainForHost_1_exposed_generic([*]u8, [*]u8) void;
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
    
    @export(roc_fx_args, .{ .name="roc_fx_args", .linkage = .Strong,  });
}

const Unit = extern struct {};

pub export fn main() u8 {
    const allocator = std.heap.page_allocator;

    // NOTE the return size can be zero, which will segfault. Always allocate at least 8 bytes
    const size = @max(8, @as(usize, @intCast(roc__mainForHost_1_exposed_size())));
    const raw_output = allocator.alignedAlloc(u8, @alignOf(u64), @as(usize, @intCast(size))) catch unreachable;
    var output = @as([*]u8, @ptrCast(raw_output));

    const rstr = RocStr.fromSlice("TEST_PYARG_STR");
    const rstr2 = RocStr.fromSlice("\nNew one \n");
    defer {
        rstr.decref();
        rstr2.decref();
    }

    defer {
        allocator.free(raw_output);
    }

    // Args just don't work in this setup. Postponing them ...
    // std.debug.print("There are {d} args:\n", .{std.os.argv.len});

    const rocslice = [_]RocStr{rstr, rstr2};
    const roclist = RocList.fromSlice(RocStr, &rocslice);
    defer roclist.decref(@alignOf(RocStr));

    roc__mainForHost_1_exposed_generic(output, list.listAllocationPtr(roclist).?);

    call_the_closure(output);

    return 0;
}

var pyResult: i32 = 0;
// const PyArgC = extern struct {
//     fn_name: [*c]const u8,
//     num:i32
// };

// pub export fn call_roc( arg: *PyArgC ) i32 {
//     const allocator = std.heap.page_allocator;

//     // NOTE the return size can be zero, which will segfault. Always allocate at least 8 bytes
//     const size = @max(8, @as(usize, @intCast(roc__mainForHost_1_exposed_size())));
//     const raw_output = allocator.alignedAlloc(u8, @alignOf(u64), @as(usize, @intCast(size))) catch unreachable;
//     var output = @as([*]u8, @ptrCast(raw_output));

//     defer {
//         allocator.free(raw_output);
//     }


//     const stdout = std.io.getStdOut().writer();
//     stdout.print("Calling FN: {s}\n", .{arg.fn_name}) catch unreachable;

//     roc__mainForHost_1_exposed_generic(output, arg.num);

//     call_the_closure(output);

//     return pyResult;
// }

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


///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// EFFECTS START HERE ///////////////////////////
///////////////////////////////////////////////////////////////////////////////


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

pub export fn roc_fx_stdoutLine(rocPath: *RocStr) RocRes_Void_Str {
    const errMsgIfAny = "ERROR_WRITING_LINE";
    return roc_fx_stdoutLine_help(rocPath) catch return .{
        .payload = .{ .err = RocStr.init(errMsgIfAny, errMsgIfAny.len) },
        .tag = 0
    };
}

fn roc_fx_stdoutLine_help(rocPath: *RocStr) !RocRes_Void_Str {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}\n", .{rocPath.asSlice()}) catch unreachable;
    
    return .{
        .payload = .{ .err = RocStr.init("", 0) },
        .tag = 1
    };
}

pub export fn roc_fx_stdoutWrite(rocPath: *RocStr) RocRes_Void_Str {
    const errMsgIfAny = "ERROR_WRITING";
    const stdout = std.io.getStdOut().writer();
    _ = stdout.write(rocPath.asSlice()) catch return .{
        .payload = .{ .err = RocStr.init(errMsgIfAny, errMsgIfAny.len)}
        , .tag = 0
    };
    
    return .{
        .payload = .{.err = RocStr.init("",0)}
        , .tag = 1
    };
}

pub export fn roc_fx_stderrWrite(rocPath: *RocStr) RocRes_Void_Str {
    const errMsgIfAny = "ERROR_WRITING_TO_STDERR";
    const stdout = std.io.getStdErr().writer();
    _ = stdout.write(rocPath.asSlice()) catch return .{
        .payload = .{ .err = RocStr.init(errMsgIfAny, errMsgIfAny.len) }
        , .tag = 0
    };
    
    return .{ 
        .payload = .{ .err = RocStr.init("",0) }
        , .tag = 1
    };
}

pub export fn roc_fx_stderrLine(rocPath: *RocStr) RocRes_Void_Str {
    const errMsgIfAny = "ERROR_WRITING_TO_STDERR";
    const stdout = std.io.getStdErr().writer();
    stdout.print("{s}\n", .{rocPath.asSlice()}) catch return .{
        .payload = .{ .err = RocStr.init(errMsgIfAny, errMsgIfAny.len) }
        , .tag = 0
    };
    
    return .{
        .payload = .{ .err = RocStr.init("",0) }
        , .tag = 1
    };
}


const RocRes_Str_Str = RocResultUnion(RocStr, RocStr);
pub export fn roc_fx_stdinLine() RocRes_Str_Str {
    const errMsgIfAny = "ERROR_READING_LINE";
    return roc_fx_stdinLine_help() catch return .{
        .payload = .{ .err = RocStr.init(errMsgIfAny, errMsgIfAny.len) },
        .tag = 0
    };
}

fn roc_fx_stdinLine_help() !RocRes_Str_Str {
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined; // Adjust buffer size as needed

    const line: []u8 = (try stdin.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.EndOfFile;

    // Optionally trim the newline character
    const trimmedLine = std.mem.trimRight(u8, line, "\n");

    return .{
        .payload = .{ .ok = RocStr.init(@as([*]const u8, trimmedLine.ptr), trimmedLine.len) },
        .tag = 1
    };
}

pub export fn roc_fx_stdinBytes() RocList {
    const errMsgIfAny = "ERROR_READING_INPUT";
    return roc_fx_stdinBytes_helper() catch return RocList.fromSlice(u8, errMsgIfAny);
}

fn roc_fx_stdinBytes_helper() !RocList {
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined; // Adjust buffer size as needed
    const line: []u8 = (try stdin.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.EndOfFile;
    
    return RocList.fromSlice(u8, line);
}

fn roc_fx_args() callconv(.C) RocList {
    const errMsgIfAny = [2]RocStr{RocStr.fromSlice("2"),
            RocStr.fromSlice("4")};
    // return roc_fx_args_help() catch return RocList.fromSlice(
    //     RocStr, &errMsgIfAny);
    return RocList.fromSlice(RocStr, &errMsgIfAny);
}


fn roc_fx_args_help() !RocList {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    // const args = std.os.argv; /// Doesn't work on windows.

    // Parse args into string array (error union needs 'try')
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Get and print them!
    std.debug.print("There are {d} args:\n", .{args.len});
    var roc_strs = std.ArrayList(RocStr).init(allocator);

    defer roc_strs.deinit();

    for (args) |arg| {
        try roc_strs.append(RocStr.fromSlice(arg));
        std.debug.print("  {s}\n", .{arg});
    }

    return RocList.fromSlice(RocStr, roc_strs.items);
}

pub export fn roc_fx_setResult(n: i32) void {
    pyResult = n;
}