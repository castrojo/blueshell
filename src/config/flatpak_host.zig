//! Locating the host's configuration directory from inside a Flatpak sandbox.
//!
//! Flatpak points `XDG_CONFIG_HOME` at `~/.var/app/<app-id>/config`, so the
//! normal XDG lookup never sees `~/.config/ghostty`, the path users are
//! told to edit. The sandbox keeps the real `$HOME` and (with the
//! `--filesystem=home:ro` finish-arg) can read it, so we can find the
//! host's config directory and load it as a base layer underneath the
//! sandbox-local one. The sandbox-local config stays the writable
//! per-app override.

const std = @import("std");
const Allocator = std.mem.Allocator;
const internal_os = @import("../os/main.zig");
const global = @import("../global.zig");

/// The env var Flatpak sets to the host's `XDG_CONFIG_HOME`, when the host
/// has one set.
const host_env = "HOST_XDG_CONFIG_HOME";

/// Returns `<host config dir>/<subdir>`, or null if we're not sandboxed in
/// Flatpak or the host config dir is the one the XDG lookup already
/// covers. The returned value is allocated.
pub fn path(alloc: Allocator, subdir: []const u8) !?[]u8 {
    if (!internal_os.isFlatpak()) return null;

    var environ_map = try global.environMap();
    defer environ_map.deinit();

    const host_xdg_raw = environ_map.get(host_env) orelse "";
    const host_xdg: ?[]const u8 = if (host_xdg_raw.len > 0) host_xdg_raw else null;

    var home_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const home = try internal_os.home(global.io(), &environ_map, &home_buf);

    const sandbox = try internal_os.xdg.config(
        global.io(),
        alloc,
        &environ_map,
        .{ .subdir = subdir },
    );
    defer alloc.free(sandbox);

    return try resolve(
        alloc,
        host_xdg,
        home,
        subdir,
        sandbox,
    );
}

/// Pure resolution logic behind `path`. `host_xdg` is the value of
/// `HOST_XDG_CONFIG_HOME` (null if unset or empty), `home` the user's
/// home directory, and `sandbox` the sandbox-local path for `subdir`.
fn resolve(
    alloc: Allocator,
    host_xdg: ?[]const u8,
    home: ?[]const u8,
    subdir: []const u8,
    sandbox: []const u8,
) !?[]u8 {
    const result = if (host_xdg) |base|
        try std.fs.path.join(alloc, &.{ base, subdir })
    else if (home) |h|
        try std.fs.path.join(alloc, &.{ h, ".config", subdir })
    else
        return null;

    // Don't load the same file twice (e.g. a user who exported
    // XDG_CONFIG_HOME into the sandbox via `flatpak override --env`).
    if (std.mem.eql(u8, result, sandbox)) {
        alloc.free(result);
        return null;
    }

    return result;
}

test "resolve: HOST_XDG_CONFIG_HOME wins over home" {
    const alloc = std.testing.allocator;
    const result = (try resolve(
        alloc,
        "/home/u/cfg",
        "/home/u",
        "ghostty/config",
        "/home/u/.var/app/x/config/ghostty/config",
    )).?;
    defer alloc.free(result);
    try std.testing.expectEqualStrings("/home/u/cfg/ghostty/config", result);
}

test "resolve: falls back to home/.config" {
    const alloc = std.testing.allocator;
    const result = (try resolve(
        alloc,
        null,
        "/home/u",
        "ghostty/themes",
        "/home/u/.var/app/x/config/ghostty/themes",
    )).?;
    defer alloc.free(result);
    try std.testing.expectEqualStrings("/home/u/.config/ghostty/themes", result);
}

test "resolve: no host dir and no home" {
    const alloc = std.testing.allocator;
    try std.testing.expect(try resolve(alloc, null, null, "ghostty/config", "/s") == null);
}

test "resolve: same as sandbox path is skipped" {
    const alloc = std.testing.allocator;
    try std.testing.expect(try resolve(
        alloc,
        null,
        "/home/u",
        "ghostty/config",
        "/home/u/.config/ghostty/config",
    ) == null);
}
