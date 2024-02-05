const std = @import("std");
const zap = @import("zap");

fn dispatch_routes(r: zap.Request) void {
	if (r.path) |the_path| {
		if (routes.get(the_path)) |render| {
			render(r);
			return;
		}
	}
	r.sendBody("Hello from ZAP!") catch return;
}

fn static_site(r: zap.Request) void {
	r.sendBody("<html><body><h1>Hello from STATIC ZAP!</h1></body></html>") catch return;
}

var dynamic_counter: i32 = 0;
fn dynamic_site(r: zap.Request) void {
	dynamic_counter += 1;
	var buf: [128]u8 = undefined;
	const filled_buf = std.fmt.bufPrintZ(
		&buf,
		"<html><body><h1>Hello # {d} from DYNAMIC ZAP!!!</h1></body></html>",
		.{dynamic_counter},
	) catch "ERROR";
	r.sendBody(filled_buf) catch return;
}

fn setup_routes(a: std.mem.Allocator) !void {
	routes = std.StringHashMap(zap.HttpRequestFn).init(a);
	try routes.put("/static", static_site);
	try routes.put("/dynamic", dynamic_site);
}

var routes: std.StringHashMap(zap.HttpRequestFn) = undefined;

pub fn main() !void {
	try setup_routes(std.heap.page_allocator);
	var listener = zap.HttpListener.init(.{
		.port = 3000,
		.on_request = dispatch_routes,
		.log = true,
		.max_clients = 100000,
	});
	try listener.listen();

	std.debug.print("Listening on 0.0.0.0:3000\n", .{});

	// // start worker threads
	zap.start(.{
		.threads = 2,
		.workers = 2,
	});
}

test "simple test" {
	std.debug.print("Running simple test\n", .{});
	var list = std.ArrayList(i32).init(std.testing.allocator);
	defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
	try list.append(42);
	try std.testing.expectEqual(@as(i32, 42), list.pop());
}
