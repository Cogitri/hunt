module kiss.event.base;

import std.bitmanip;


alias ReadDataCallBack = void delegate(in ubyte[] data) nothrow;
alias ReadObjectCallBack = void delegate(Object obj) nothrow;

enum WatcherType : ubyte
{
    ACCEPT = 0,
    TCP,
    UDP,
    Timer ,
    Event,
    File,
    None
}

enum WatchFlag : ubyte
{
    None = 0x00,
    Read,
    Write,

    TimerOnce = 0x0F,
    ETMode = 0XFF
}

// 所有检测的不同都有Watcher区分， 保证上层socket的代码都是公共代码
@trusted abstract class Watcher {
    this(WatcherType type_){
        _type = type_;
    }

    /// Whether the watcher is active.
    bool active(){
        return false;
    }

    abstract bool isError();

    abstract string erroString();

    final bool flag(WatchFlag index){return _flags[index];} 
    final @property type(){return _type;}

protected:
    final void setFlag(WatchFlag bit, bool enable){
        _flags[index] = enable;
    }
private:
    bool[16] _flags;
    WatcherType _type;
package (kiss):
    Watcher _priv;
    Watcher _next;
}


@trusted interface  ReadTransport {
    void onRead(Watcher watcher) nothrow;

    void onClose(Watcher watcher) nothrow;
}


//@Transport 

@trusted interface WriteTransport {
    void onWrite(Watcher watcher) nothrow;

    void onClose(Watcher watcher) nothrow;
}


@trusted interface Transport  : ReadTransport, WriteTransport {
}

// 实际处理
interface BaseLoop {
    Watcher createWatcher(WatcherType type);

    void read(Watcher watcher,scope ReadDataCallBack read);

    void read(Watcher watcher,scope ReadObjectCallBack read);

    bool write(Watcher watcher,in ubyte[] data, out size_t writed);

    // 关闭会自动unRegister的
    bool close(Watcher watcher);

    bool register(Watcher watcher);

    bool unRegister(Watcher watcher);

    bool weakUp();

    // while(true)
    void join(scope void delegate()nothrow weak); 

    void stop();
}
