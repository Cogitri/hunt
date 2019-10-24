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

module hunt.io.FileInputStream;

import hunt.Exceptions;
import hunt.io.Common;

import std.array;
import std.stdio;


/**
 * A <code>FileInputStream</code> obtains input bytes
 * from a file in a file system. What files
 * are  available depends on the host environment.
 *
 * <p><code>FileInputStream</code> is meant for reading streams of raw bytes
 * such as image data. For reading streams of characters, consider using
 * <code>FileReader</code>.
 *
 * @apiNote
 * To release resources used by this stream {@link #close} should be called
 * directly or by try-with-resources. Subclasses are responsible for the cleanup
 * of resources acquired by the subclass.
 * Subclasses that override {@link #finalize} in order to perform cleanup
 * should be modified to use alternative cleanup mechanisms such as
 * {@link java.lang.ref.Cleaner} and remove the overriding {@code finalize} method.
 *
 * @implSpec
 * If this FileInputStream has been subclassed and the {@link #close}
 * method has been overridden, the {@link #close} method will be
 * called when the FileInputStream is unreachable.
 * Otherwise, it is implementation specific how the resource cleanup described in
 * {@link #close} is performed.

 *
 * @author  Arthur van Hoff
 * @see     java.io.File
 * @see     java.io.FileDescriptor
 * @see     java.io.FileOutputStream
 * @see     java.nio.file.Files#newInputStream
 */
class FileInputStream : InputStream {
    /* File Descriptor - handle to the open file */
    // private final FileDescriptor fd;

    /**
     * The path of the referenced file
     * (null if the stream is created with a file descriptor)
     */
    private string path;
    private File file;
    private Object closeLock;
    private bool closed;

    /**
     * Creates a <code>FileInputStream</code> by
     * opening a connection to an actual file,
     * the file named by the path name <code>name</code>
     * in the file system.  A new <code>FileDescriptor</code>
     * object is created to represent this file
     * connection.
     * <p>
     * First, if there is a security
     * manager, its <code>checkRead</code> method
     * is called with the <code>name</code> argument
     * as its argument.
     * <p>
     * If the named file does not exist, is a directory rather than a regular
     * file, or for some other reason cannot be opened for reading then a
     * <code>FileNotFoundException</code> is thrown.
     *
     * @param      name   the system-dependent file name.
     * @exception  FileNotFoundException  if the file does not exist,
     *                   is a directory rather than a regular file,
     *                   or for some other reason cannot be opened for
     *                   reading.
     * @exception  SecurityException      if a security manager exists and its
     *               <code>checkRead</code> method denies read access
     *               to the file.
     * @see        java.lang.SecurityManager#checkRead(java.lang.string)
     */
    this(string name) {
        if(name.empty)
            throw new NullPointerException();
        this(File(name, "r"));
    }

    /**
     * Creates a <code>FileInputStream</code> by
     * opening a connection to an actual file,
     * the file named by the <code>File</code>
     * object <code>file</code> in the file system.
     * A new <code>FileDescriptor</code> object
     * is created to represent this file connection.
     * <p>
     * First, if there is a security manager,
     * its <code>checkRead</code> method  is called
     * with the path represented by the <code>file</code>
     * argument as its argument.
     * <p>
     * If the named file does not exist, is a directory rather than a regular
     * file, or for some other reason cannot be opened for reading then a
     * <code>FileNotFoundException</code> is thrown.
     *
     * @param      file   the file to be opened for reading.
     * @exception  FileNotFoundException  if the file does not exist,
     *                   is a directory rather than a regular file,
     *                   or for some other reason cannot be opened for
     *                   reading.
     * @exception  SecurityException      if a security manager exists and its
     *               <code>checkRead</code> method denies read access to the file.
     * @see        java.io.File#getPath()
     * @see        java.lang.SecurityManager#checkRead(java.lang.string)
     */
    this(File file) {
        this.file = file;
        closeLock = new Object();
        // string name = (file != null ? file.getPath() : null);
        // SecurityManager security = System.getSecurityManager();
        // if (security != null) {
        //     security.checkRead(name);
        // }
        // if (name == null) {
        //     throw new NullPointerException();
        // }
        // if (file.isInvalid()) {
        //     throw new FileNotFoundException("Invalid file path");
        // }
        // fd = new FileDescriptor();
        // fd.attach(this);
        // path = name;
        // open(name);
        // altFinalizer = getFinalizer(this);
        // if (altFinalizer == null) {
        //     FileCleanable.register(fd);       // open set the fd, register the cleanup
        // }
    }

    /**
     * Creates a <code>FileInputStream</code> by using the file descriptor
     * <code>fdObj</code>, which represents an existing connection to an
     * actual file in the file system.
     * <p>
     * If there is a security manager, its <code>checkRead</code> method is
     * called with the file descriptor <code>fdObj</code> as its argument to
     * see if it's ok to read the file descriptor. If read access is denied
     * to the file descriptor a <code>SecurityException</code> is thrown.
     * <p>
     * If <code>fdObj</code> is null then a <code>NullPointerException</code>
     * is thrown.
     * <p>
     * This constructor does not throw an exception if <code>fdObj</code>
     * is {@link java.io.FileDescriptor#valid() invalid}.
     * However, if the methods are invoked on the resulting stream to attempt
     * I/O on the stream, an <code>IOException</code> is thrown.
     *
     * @param      fdObj   the file descriptor to be opened for reading.
     * @throws     SecurityException      if a security manager exists and its
     *                 <code>checkRead</code> method denies read access to the
     *                 file descriptor.
     * @see        SecurityManager#checkRead(java.io.FileDescriptor)
     */
    // this(FileDescriptor fdObj) {
    //     SecurityManager security = System.getSecurityManager();
    //     if (fdObj == null) {
    //         throw new NullPointerException();
    //     }
    //     if (security != null) {
    //         security.checkRead(fdObj);
    //     }
    //     fd = fdObj;
    //     path = null;
    //     altFinalizer = null;

    //     /*
    //      * FileDescriptor is being shared by streams.
    //      * Register this stream with FileDescriptor tracker.
    //      */
    //     fd.attach(this);
    // }

    /**
     * Opens the specified file for reading.
     * @param name the name of the file
     */
    // private native void open0(string name);

    // wrap native call to allow instrumentation
    /**
     * Opens the specified file for reading.
     * @param name the name of the file
     */
    // private void open(string name) {
    //     open0(name);
    // }

    /**
     * Reads a byte of data from this input stream. This method blocks
     * if no input is yet available.
     *
     * @return     the next byte of data, or <code>-1</code> if the end of the
     *             file is reached.
     * @exception  IOException  if an I/O error occurs.
     */
    override int read() {
        byte[] buf = file.rawRead(new byte[1]);
        if(buf.length == 0)
            return -1;
        else
            return buf[0];
    }


    /**
     * Reads a subarray as a sequence of bytes.
     * @param b the data to be written
     * @param off the start offset in the data
     * @param len the number of bytes that are written
     * @exception IOException If an I/O error has occurred.
     */
    private int readBytes(byte[] b, int off, int len) {
        byte[] buf = file.rawRead(b[off .. off+len]);
        if(buf.length == 0)
            return -1;
        else
            return cast(int)buf.length;
    }

    /**
     * Reads up to <code>b.length</code> bytes of data from this input
     * stream into an array of bytes. This method blocks until some input
     * is available.
     *
     * @param      b   the buffer into which the data is read.
     * @return     the total number of bytes read into the buffer, or
     *             <code>-1</code> if there is no more data because the end of
     *             the file has been reached.
     * @exception  IOException  if an I/O error occurs.
     */
    override int read(byte[] b) {
        return readBytes(b, 0, cast(int)b.length);
    }

    /**
     * Reads up to <code>len</code> bytes of data from this input stream
     * into an array of bytes. If <code>len</code> is not zero, the method
     * blocks until some input is available; otherwise, no
     * bytes are read and <code>0</code> is returned.
     *
     * @param      b     the buffer into which the data is read.
     * @param      off   the start offset in the destination array <code>b</code>
     * @param      len   the maximum number of bytes read.
     * @return     the total number of bytes read into the buffer, or
     *             <code>-1</code> if there is no more data because the end of
     *             the file has been reached.
     * @exception  NullPointerException If <code>b</code> is <code>null</code>.
     * @exception  IndexOutOfBoundsException If <code>off</code> is negative,
     * <code>len</code> is negative, or <code>len</code> is greater than
     * <code>b.length - off</code>
     * @exception  IOException  if an I/O error occurs.
     */
    override int read(byte[] b, int off, int len) {
        return readBytes(b, off, len);
    }

    /**
     * Skips over and discards <code>n</code> bytes of data from the
     * input stream.
     *
     * <p>The <code>skip</code> method may, for a variety of
     * reasons, end up skipping over some smaller number of bytes,
     * possibly <code>0</code>. If <code>n</code> is negative, the method
     * will try to skip backwards. In case the backing file does not support
     * backward skip at its current position, an <code>IOException</code> is
     * thrown. The actual number of bytes skipped is returned. If it skips
     * forwards, it returns a positive value. If it skips backwards, it
     * returns a negative value.
     *
     * <p>This method may skip more bytes than what are remaining in the
     * backing file. This produces no exception and the number of bytes skipped
     * may include some number of bytes that were beyond the EOF of the
     * backing file. Attempting to read from the stream after skipping past
     * the end will result in -1 indicating the end of the file.
     *
     * @param      n   the number of bytes to be skipped.
     * @return     the actual number of bytes skipped.
     * @exception  IOException  if n is negative, if the stream does not
     *             support seek, or if an I/O error occurs.
     */
    override long skip(long n) {
        // auto last = file.tell();
        // file.seek(n);
        // auto diff = file.tell() - last;
        // return cast(long)diff;
        throw new NotSupportedException();
    }


    /**
     * Returns an estimate of the number of remaining bytes that can be read (or
     * skipped over) from this input stream without blocking by the next
     * invocation of a method for this input stream. Returns 0 when the file
     * position is beyond EOF. The next invocation might be the same thread
     * or another thread. A single read or skip of this many bytes will not
     * block, but may read or skip fewer bytes.
     *
     * <p> In some cases, a non-blocking read (or skip) may appear to be
     * blocked when it is merely slow, for example when reading large
     * files over slow networks.
     *
     * @return     an estimate of the number of remaining bytes that can be read
     *             (or skipped over) from this input stream without blocking.
     * @exception  IOException  if this file input stream has been closed by calling
     *             {@code close} or an I/O error occurs.
     */
    override int available() {
        // return available0();
        return cast(int)(file.size());
    }

    // private native int available0();

    /**
     * Closes this file input stream and releases any system resources
     * associated with the stream.
     *
     * <p> If this stream has an associated channel then the channel is closed
     * as well.
     *
     * @apiNote
     * Overriding {@link #close} to perform cleanup actions is reliable
     * only when called directly or when called by try-with-resources.
     * Do not depend on finalization to invoke {@code close};
     * finalization is not reliable and is deprecated.
     * If cleanup of native resources is needed, other mechanisms such as
     * {@linkplain java.lang.ref.Cleaner} should be used.
     *
     * @exception  IOException  if an I/O error occurs.
     *
     * @revised 1.4
     * @spec JSR-51
     */
    override void close() {
        if (closed)
            return;

        synchronized (closeLock) {
            if (closed) return;
            closed = true;
        }

        file.close();

        // FileChannel fc = channel;
        // if (fc != null) {
        //     // possible race with getChannel(), benign since
        //     // FileChannel.close is final and idempotent
        //     fc.close();
        // }

        // fd.closeAll(new Closeable() {
        //     void close() {
        //        fd.close();
        //    }
        // });
    }

    /**
     * Returns the <code>FileDescriptor</code>
     * object  that represents the connection to
     * the actual file in the file system being
     * used by this <code>FileInputStream</code>.
     *
     * @return     the file descriptor object associated with this stream.
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.FileDescriptor
     */
    // final FileDescriptor getFD() {
    //     if (fd != null) {
    //         return fd;
    //     }
    //     throw new IOException();
    // }

    /**
     * Returns the unique {@link java.nio.channels.FileChannel FileChannel}
     * object associated with this file input stream.
     *
     * <p> The initial {@link java.nio.channels.FileChannel#position()
     * position} of the returned channel will be equal to the
     * number of bytes read from the file so far.  Reading bytes from this
     * stream will increment the channel's position.  Changing the channel's
     * position, either explicitly or by reading, will change this stream's
     * file position.
     *
     * @return  the file channel associated with this file input stream
     *
     * @spec JSR-51
     */
    // FileChannel getChannel() {
    //     FileChannel fc = this.channel;
    //     if (fc == null) {
    //         synchronized (this) {
    //             fc = this.channel;
    //             if (fc == null) {
    //                 this.channel = fc = FileChannelImpl.open(fd, path, true,
    //                     false, false, this);
    //                 if (closed) {
    //                     try {
    //                         // possible race with close(), benign since
    //                         // FileChannel.close is final and idempotent
    //                         fc.close();
    //                     } catch (IOException ioe) {
    //                         throw new InternalError(ioe); // should not happen
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     return fc;
    // }

    // private static native void initIDs();

    // static {
    //     initIDs();
    // }

    /**
     * Ensures that the {@link #close} method of this file input stream is
     * called when there are no more references to it.
     * The {@link #finalize} method does not call {@link #close} directly.
     *
     * @apiNote
     * To release resources used by this stream {@link #close} should be called
     * directly or by try-with-resources.
     *
     * @implSpec
     * If this FileInputStream has been subclassed and the {@link #close}
     * method has been overridden, the {@link #close} method will be
     * called when the FileInputStream is unreachable.
     * Otherwise, it is implementation specific how the resource cleanup described in
     * {@link #close} is performed.
     *
     * @deprecated The {@code finalize} method has been deprecated and will be removed.
     *     Subclasses that override {@code finalize} in order to perform cleanup
     *     should be modified to use alternative cleanup mechanisms and
     *     to remove the overriding {@code finalize} method.
     *     When overriding the {@code finalize} method, its implementation must explicitly
     *     ensure that {@code super.finalize()} is invoked as described in {@link Object#finalize}.
     *     See the specification for {@link Object#finalize()} for further
     *     information about migration options.
     *
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.FileInputStream#close()
     */
    // @Deprecated(since="9", forRemoval = true)
    // protected void finalize() {
    // }

    /*
     * Returns a finalizer object if the FIS needs a finalizer; otherwise null.
     * If the FIS has a close method; it needs an AltFinalizer.
     */
    // private static Object getFinalizer(FileInputStream fis) {
    //     Class<?> clazz = fis.getClass();
    //     while (clazz != FileInputStream.class) {
    //         try {
    //             clazz.getDeclaredMethod("close");
    //             return new AltFinalizer(fis);
    //         } catch (NoSuchMethodException nsme) {
    //             // ignore
    //         }
    //         clazz = clazz.getSuperclass();
    //     }
    //     return null;
    // }
    /**
     * Class to call {@code FileInputStream.close} when finalized.
     * If finalization of the stream is needed, an instance is created
     * in its constructor(s).  When the set of instances
     * related to the stream is unreachable, the AltFinalizer performs
     * the needed call to the stream's {@code close} method.
     */
    // static class AltFinalizer {
    //     private final FileInputStream fis;

    //     AltFinalizer(FileInputStream fis) {
    //         this.fis = fis;
    //     }

    //     override
    //     @SuppressWarnings("deprecation")
    //     protected final void finalize() {
    //         try {
    //             if ((fis.fd != null) && (fis.fd != FileDescriptor.in)) {
    //                 /* if fd is shared, the references in FileDescriptor
    //                  * will ensure that finalizer is only called when
    //                  * safe to do so. All references using the fd have
    //                  * become unreachable. We can call close()
    //                  */
    //                 fis.close();
    //             }
    //         } catch (IOException ioe) {
    //             // ignore
    //         }
    //     }
    // }
}