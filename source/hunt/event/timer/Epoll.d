/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.event.timer.Epoll;

// dfmt off
version (HAVE_EPOLL) : 
// dfmt on

import hunt.event.selector.Selector;
import hunt.event.timer.Common;
import hunt.Functions;
import hunt.io.channel.Common;

import core.sys.posix.unistd;
import core.sys.posix.time : itimerspec, CLOCK_MONOTONIC;

import core.time;
import std.socket;

/**
*/
abstract class AbstractTimer : TimerChannelBase {
    this(Selector loop) {
        super(loop);
        init();
    }

    private void init() {
        setFlag(ChannelFlag.Read, true);
        _readBuffer = new UintObject();
        this.handle = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
        // setTimer();
    }

    ~this() @nogc {
        // close();
    }

    private bool setTimer() {
        itimerspec its;
        ulong sec, nsec;
        sec = time() / 1000;
        nsec = (time() % 1000) * 1_000_000;

        its.it_value.tv_sec = cast(typeof(its.it_value.tv_sec)) sec;
        its.it_value.tv_nsec = cast(typeof(its.it_value.tv_nsec)) nsec;
        its.it_interval.tv_sec = its.it_value.tv_sec;
        its.it_interval.tv_nsec = its.it_value.tv_nsec;
        const int err = timerfd_settime(this.handle, 0, &its, null);
        if (err == -1) {
            return false;
        }
        return true;
    }

    bool readTimer(scope SimpleActionHandler read) {
        this.clearError();
        uint value;
        core.sys.posix.unistd.read(this.handle, &value, 8);
        this._readBuffer.data = value;
        if (read)
            read(this._readBuffer);
        return false;
    }

    override void start(bool immediately = false, bool once = false) {
        setTimer();
        super.start();
    }

    UintObject _readBuffer;
}

/**
C APIs for timerfd
*/
enum TFD_TIMER_ABSTIME = 1 << 0;
enum TFD_CLOEXEC = 0x80000;
enum TFD_NONBLOCK = 0x800;

extern (C) {
    socket_t timerfd_create(int clockid, int flags) nothrow;
    int timerfd_settime(int fd, int flags, const itimerspec* new_value, itimerspec* old_value) nothrow;
    int timerfd_gettime(int fd, itimerspec* curr_value) nothrow;
}
