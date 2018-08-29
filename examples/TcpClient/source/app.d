import std.stdio;

import hunt.event;
import hunt.io.TcpStream;
// import hunt.logging;

void main()
{
	EventLoop loop = new EventLoop();
	TcpStream client = new TcpStream(loop);
	client.onConnected((bool isSucceeded) {
		if (isSucceeded)
		{
			writeln("connected with: ", client.remoteAddress.toString()); 
			client.write(cast(const(ubyte[])) "Hello world!", (in ubyte[] wdata, size_t size) {
				debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			});

			// client.write(new SocketStreamBuffer(cast(const(ubyte[])) "hello world!",
			// 	(in ubyte[] wdata, size_t size) {
			// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// 	}));
		}
		else
		{
			writeln("The connection failed!");
			loop.stop();
		}
	}).onDataReceived((in ubyte[] data) {
		writeln("received data: ", cast(string) data);
		client.write(data, (in ubyte[] wdata, size_t size) {
			debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
		});
		// client.write(new SocketStreamBuffer(data.dup, (in ubyte[] wdata, size_t size) {
		// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
		// 	}));
	}).onClosed(() {
		writeln("The connection is closed!");
		// loop.stop(); // It's will raise a exception: Invalid memory operation
	// }).connect("127.0.0.1", 8090);
	}).connect("10.1.222.120", 8090);

	loop.run();
}
