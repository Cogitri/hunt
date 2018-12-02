/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.io.TcpStream;

import hunt.event;
import hunt.io.core;
import hunt.logging;
import hunt.lang.common;

import std.format;
import std.socket;
import std.exception;
import std.socket;
import core.thread;
import core.time;


import core.sys.linux.netinet.tcp : TCP_KEEPCNT;

class TcpStreamOption {
    string ip = "127.0.0.1";
    ushort port = 8080;

    // http://www.tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html
    /// the interval between the last data packet sent (simple ACKs are not considered data) and the first keepalive probe; 
    /// after the connection is marked to need keepalive, this counter is not used any further 
    int keepaliveTime = 7200; // in seconds

    /// the interval between subsequential keepalive probes, regardless of what the connection has exchanged in the meantime 
    int keepaliveInterval = 75; // in seconds

    /// the number of unacknowledged probes to send before considering the connection dead and notifying the application layer 
    int keepaliveProbes = 9; // times

    bool isKeepalive = false;

    size_t bufferSize = 1024*8;

    this() {

    }
}

/**
*/
class TcpStream : AbstractStream {
    SimpleEventHandler closeHandler;

    private TcpStreamOption _tcpOption;

    // for client
    this(Selector loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4096 * 2) {
        super(loop, family, bufferSize);
        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);

        _isClient = false;
        _isConnected = false;
        initialize();
    }

    // for server
    this(Selector loop, Socket socket, TcpStreamOption option = null) {
        if(option is null)
            initialize();
        else
            _tcpOption = option;
        super(loop, socket.addressFamily, _tcpOption.bufferSize);
        this.socket = socket;
        _remoteAddress = socket.remoteAddress();
        _localAddress = socket.localAddress();

        _isClient = false;
        _isConnected = true;
        setKeepalive();
    }

    private void initialize() {
        _tcpOption = new TcpStreamOption();
        _tcpOption.isKeepalive = true;
        _tcpOption.keepaliveTime = 15; 
        _tcpOption.keepaliveInterval = 3; 
        _tcpOption.keepaliveProbes = 5;
    }

    void options(TcpStreamOption option) @property {
        assert(option !is null);
        this._tcpOption = option;
    }

    TcpStreamOption options() @property {
        return this._tcpOption;
    }

    
    override bool isBusy() {
        return _isWritting;
    }

    void connect(string ip, ushort port) {
        connect(parseAddress(ip, port));
    }

    void connect(Address addr) {
        if (_isConnected)
            return;

        try {
            Address binded = createAddress(this.socket, 0);
            this.socket.bind(binded);
            this.doConnect(addr);
            start();
            _isConnected = true;
            _remoteAddress = addr;
            setKeepalive();

            _localAddress = this.socket.localAddress();
        } catch (Exception ex) {
            error(ex.message);
        }

        if (_connectionHandler !is null)
            _connectionHandler(_isConnected);
    }


    // www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/
    // http://www.importnew.com/27624.html
    private void setKeepalive() {
        if(_tcpOption.isKeepalive) {
            this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
            this.setOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, _tcpOption.keepaliveProbes);
            checkKeepAlive();
        }
    }

    private void checkKeepAlive() {
        int time ;
        int interval;
        int isKeep;
        int ret1 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPIDLE, time);
        warningf("ret=%d, time=%d", ret1, time);
        int ret2 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPINTVL, interval);
        warningf("ret=%d, interval=%d", ret2, interval);
        int ret3 = getOption(SocketOptionLevel.SOCKET, SocketOption.KEEPALIVE, isKeep);
        warningf("ret=%d, keepalive=%s", ret3, isKeep==1);
        int probe;
        int ret4 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, probe);
        warningf("ret=%d, interval=%d", ret4, probe);
    }

    void reconnect(Address addr) {
        if (_isConnected)
            this.close();
        _isConnected = false;
        AddressFamily family = AddressFamily.INET;
        if (this.socket !is null)
            family = this.socket.addressFamily;

        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);
        connect(addr);
    }

    TcpStream onConnected(ConnectionHandler cback) {
        _connectionHandler = cback;
        return this;
    }

    TcpStream onDataReceived(DataReceivedHandler handler) {
        dataReceivedHandler = handler;
        return this;
    }

    // TcpStream onDataWritten(DataWrittenHandler handler)
    // {
    //     sentHandler = handler;
    //     return this;
    // }

    TcpStream onClosed(SimpleEventHandler handler) {
        closeHandler = handler;
        return this;
    }

    TcpStream onDisconnected(SimpleEventHandler handler) {
        disconnectionHandler = handler;
        return this;
    }

    TcpStream onError(ErrorEventHandler handler) {
        errorHandler = handler;
        return this;
    }

    bool isConnected() nothrow {
        return _isConnected;
    }

    override void start() {
        if (_isRegistered)
            return;
        _inLoop.register(this);
        _isRegistered = true;
        version (Windows)
            this.beginRead();
    }

    void write(StreamWriteBuffer buffer) {
        assert(buffer !is null);

        if (!_isConnected) {
            warning("The connection has been closed!");
            return;
        }

        _writeQueue.enQueue(buffer);

        version (Windows) {
            if (_isWritting) {
                version (HUNT_DEBUG)
                    infof("Busy in writting, data buffered (%d bytes)", buffer.capacity);
            } else
                tryWrite();
        } else {
            onWrite();
        }
    }

    /// safe for big data sending
    void write(in ubyte[] data, DataWrittenHandler handler = null) {
        if (data.length == 0)
            return;

        write(new SocketStreamBuffer(data, handler));
    }

    void shutdownInput() {
        this.socket.shutdown(SocketShutdown.RECEIVE);
    }

    void shutdownOutput() {
        this.socket.shutdown(SocketShutdown.SEND);
    }

protected:
    bool _isClient;
    ConnectionHandler _connectionHandler;

    override void onRead() {
        version (HUNT_DEBUG)
            trace("start to read");

        version (Posix) {
            while (!_isClosed && !tryRead()) {
                version (HUNT_DEBUG)
                    trace("continue reading...");
            }
        } else {
            doRead();
        }

        if (this.isError) {
            string msg = format("Socket error on read: fd=%d, message: %s",
                    this.handle, this.erroString);
            // version (HUNT_DEBUG)
            debug errorf(msg);
            errorOccurred(msg);
        }
    }

    override void onClose() {
        version (HUNT_DEBUG) {
            if (!_writeQueue.empty) {
                warning("Some data has not been sent yet.");
            }

            infof("connection closed with: %s", this.remoteAddress);
        }

        _writeQueue.clear();
        super.onClose();
        _isConnected = false;
        this.socket.shutdown(SocketShutdown.BOTH);
        this.socket.close();

        if (closeHandler)
            closeHandler();
    }

    override void onWrite() {
        if (!_isConnected) {
            _isConnected = true;
            _remoteAddress = socket.remoteAddress();

            if (_connectionHandler)
                _connectionHandler(true);
            return;
        }

        // bool canWrite = true;
        version (HUNT_DEBUG)
            tracef("start to write [fd=%d]", this.handle);

        while (_isRegistered && !isWriteCancelling && !_writeQueue.empty) {
            version (HUNT_DEBUG)
                tracef("writting [fd=%d]...", this.handle);

            StreamWriteBuffer writeBuffer = _writeQueue.front();
            const(ubyte[]) data = writeBuffer.remaining();
            if (data.length == 0) {
                auto q = _writeQueue.deQueue();
                if (q is null)
                    warning("StreamWriteBuffer is null");
                else
                    q.finish();
                // _writeQueue.deQueue().finish();
                continue;
            }

            this.clearError();
            size_t nBytes = tryWrite(data);
            if (nBytes > 0 && writeBuffer.pop(nBytes)) {
                version (HUNT_DEBUG)
                    tracef("writing done: %d bytes, fd: %d", nBytes, this.handle);
                auto q = _writeQueue.deQueue();
                if (q is null)
                    warning("StreamWriteBuffer is null");
                else
                    q.finish();
            }

            if (this.isError) {
                string msg = format("Socket error on write: fd=%d, message=%s",
                        this.handle, this.erroString);
                debug errorf(msg);
                errorOccurred(msg);
                break;
            }
        }
    }
}
