const std = @import("../std.zig");
const builtin = @import("builtin");
const root = @import("root");
const mem = std.mem;

pub const OutStream = interface {
    pub fn write(self: var, bytes: []const u8) !usize;

    const Self = @This();
    const WriteReturnType = @typeInfo(@TypeOf(writeAll)).Fn.return_type;
    const WriteError = @typeInfo(WriteReturnType).ErrorUnion.error_set;

    pub fn writeAll(self: *Self, bytes: []const u8) !void {
        var index: usize = 0;
        while (index != bytes.len) {
            index += try self.write(bytes[index..]);
        }
    }

    pub fn print(self: *Self, comptime format: []const u8, args: var) !void {
        return std.fmt.format(self, WriteError, writeAll, format, args);
    }

    pub fn writeByte(self: *Self, byte: u8) !void {
        const array = [1]u8{byte};
        return self.writeAll(&array);
    }

    pub fn writeByteNTimes(self: *Self, byte: u8, n: usize) !void {
        var bytes: [256]u8 = undefined;
        mem.set(u8, bytes[0..], byte);

        var remaining: usize = n;
        while (remaining > 0) {
            const to_write = std.math.min(remaining, bytes.len);
            try self.writeAll(bytes[0..to_write]);
            remaining -= to_write;
        }
    }

    /// Write a native-endian integer.
    pub fn writeIntNative(self: *Self, comptime T: type, value: T) !void {
        var bytes: [(T.bit_count + 7) / 8]u8 = undefined;
        mem.writeIntNative(T, &bytes, value);
        return self.writeAll(&bytes);
    }

    /// Write a foreign-endian integer.
    pub fn writeIntForeign(self: *Self, comptime T: type, value: T) !void {
        var bytes: [(T.bit_count + 7) / 8]u8 = undefined;
        mem.writeIntForeign(T, &bytes, value);
        return self.writeAll(&bytes);
    }

    pub fn writeIntLittle(self: *Self, comptime T: type, value: T) !void {
        var bytes: [(T.bit_count + 7) / 8]u8 = undefined;
        mem.writeIntLittle(T, &bytes, value);
        return self.writeAll(&bytes);
    }

    pub fn writeIntBig(self: *Self, comptime T: type, value: T) !void {
        var bytes: [(T.bit_count + 7) / 8]u8 = undefined;
        mem.writeIntBig(T, &bytes, value);
        return self.writeAll(&bytes);
    }

    pub fn writeInt(self: *Self, comptime T: type, value: T, endian: builtin.Endian) !void {
        var bytes: [(T.bit_count + 7) / 8]u8 = undefined;
        mem.writeInt(T, &bytes, value, endian);
        return self.writeAll(&bytes);
    }
};
