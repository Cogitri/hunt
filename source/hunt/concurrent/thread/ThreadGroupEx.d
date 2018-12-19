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
 
module hunt.concurrent.thread.ThreadGroupEx;

import hunt.lang.exception;

import core.thread;
import std.algorithm;
import std.conv;
import std.stdio;


private __gshared UncaughtExceptionHandler defaultUncaughtExceptionHandler;

void setDefaultUncaughtExceptionHandler(UncaughtExceptionHandler eh) {
// SecurityManager sm = System.getSecurityManager();
// if (sm != null) {
//     sm.checkPermission(
//         new RuntimePermission("setDefaultUncaughtExceptionHandler")
//             );
// }
    defaultUncaughtExceptionHandler = eh;
}

UncaughtExceptionHandler getDefaultUncaughtExceptionHandler(){
    return defaultUncaughtExceptionHandler;
}

/**
 * Interface for handlers invoked when a {@code Thread} abruptly
 * terminates due to an uncaught exception.
 * <p>When a thread is about to terminate due to an uncaught exception
 * the Java Virtual Machine will query the thread for its
 * {@code UncaughtExceptionHandler} using
 * {@link #getUncaughtExceptionHandler} and will invoke the handler's
 * {@code uncaughtException} method, passing the thread and the
 * exception as arguments.
 * If a thread has not had its {@code UncaughtExceptionHandler}
 * explicitly set, then its {@code ThreadGroupEx} object acts as its
 * {@code UncaughtExceptionHandler}. If the {@code ThreadGroupEx} object
 * has no
 * special requirements for dealing with the exception, it can forward
 * the invocation to the {@linkplain #getDefaultUncaughtExceptionHandler
 * default uncaught exception handler}.
 *
 * @see #setDefaultUncaughtExceptionHandler
 * @see #setUncaughtExceptionHandler
 * @see ThreadGroupEx#uncaughtException
 * @since 1.5
 */
interface UncaughtExceptionHandler {
    /**
     * Method invoked when the given thread terminates due to the
     * given uncaught exception.
     * <p>Any exception thrown by this method will be ignored by the
     * Java Virtual Machine.
     * @param t the thread
     * @param e the exception
     */
    void uncaughtException(Thread t, Throwable e);
}

/**
 * A thread group represents a set of threads. In addition, a thread
 * group can also include other thread groups. The thread groups form
 * a tree in which every thread group except the initial thread group
 * has a parent.
 * <p>
 * A thread is allowed to access information about its own thread
 * group, but not to access information about its thread group's
 * parent thread group or any other thread groups.
 *
 * @author  unascribed
 * @since   1.0
 */
/* The locking strategy for this code is to try to lock only one level of the
 * tree wherever possible, but otherwise to lock from the bottom up.
 * That is, from child thread groups to parents.
 * This has the advantage of limiting the number of locks that need to be held
 * and in particular avoids having to grab the lock for the root thread group,
 * (or a global lock) which would be a source of contention on a
 * multi-processor system with many thread groups.
 * This policy often leads to taking a snapshot of the state of a thread group
 * and working off of that snapshot, rather than holding the thread group locked
 * while we work on the children.
 */
// class ThreadGroupEx : UncaughtExceptionHandler {
//     private ThreadGroupEx parent;
//     private string name;
//     private int maxPriority;
//     private bool destroyed;
//     private bool daemon;

//     private int nUnstartedThreads = 0;
//     private int nthreads;
//     private Thread[] threads;

//     private int ngroups;
//     private ThreadGroupEx[] groups;

//     /**
//      * Creates an empty Thread group that is not in any Thread group.
//      * This method is used to create the system Thread group.
//      */
//     private this() {     // called from C code
//         this.name = "system";
//         this.maxPriority = Thread.PRIORITY_MAX;
//         this.parent = null;
//     }

//     /**
//      * Constructs a new thread group. The parent of this new group is
//      * the thread group of the currently running thread.
//      * <p>
//      * The {@code checkAccess} method of the parent thread group is
//      * called with no arguments; this may result in a security exception.
//      *
//      * @param   name   the name of the new thread group.
//      * @throws  SecurityException  if the current thread cannot create a
//      *               thread in the specified thread group.
//      * @see     java.lang.ThreadGroupEx#checkAccess()
//      * @since   1.0
//      */
//     this(string name) {
//         // this(Thread.getThis().getThreadGroup(), name);
//         this(null, name);
//     }

//     /**
//      * Creates a new thread group. The parent of this new group is the
//      * specified thread group.
//      * <p>
//      * The {@code checkAccess} method of the parent thread group is
//      * called with no arguments; this may result in a security exception.
//      *
//      * @param     parent   the parent thread group.
//      * @param     name     the name of the new thread group.
//      * @throws    NullPointerException  if the thread group argument is
//      *               {@code null}.
//      * @throws    SecurityException  if the current thread cannot create a
//      *               thread in the specified thread group.
//      * @see     java.lang.SecurityException
//      * @see     java.lang.ThreadGroupEx#checkAccess()
//      * @since   1.0
//      */
//     this(ThreadGroupEx parent, string name) {
//         // checkParentAccess(parent);
//         this.name = name;
//         this.maxPriority = parent.maxPriority;
//         this.daemon = parent.daemon;
//         this.parent = parent;
//         parent.add(this);
//     }

//     /*
//      * @throws  NullPointerException  if the parent argument is {@code null}
//      * @throws  SecurityException     if the current thread cannot create a
//      *                                thread in the specified thread group.
//      */
//     // private static void checkParentAccess(ThreadGroupEx parent) {
//     //     parent.checkAccess();
//     //     return null;
//     // }

//     /**
//      * Returns the name of this thread group.
//      *
//      * @return  the name of this thread group.
//      * @since   1.0
//      */
//     final string getName() {
//         return name;
//     }

//     /**
//      * Returns the parent of this thread group.
//      * <p>
//      * First, if the parent is not {@code null}, the
//      * {@code checkAccess} method of the parent thread group is
//      * called with no arguments; this may result in a security exception.
//      *
//      * @return  the parent of this thread group. The top-level thread group
//      *          is the only thread group whose parent is {@code null}.
//      * @throws  SecurityException  if the current thread cannot modify
//      *               this thread group.
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @see        java.lang.SecurityException
//      * @see        java.lang.RuntimePermission
//      * @since   1.0
//      */
//     final ThreadGroupEx getParent() {
//         if (parent !is null)
//             parent.checkAccess();
//         return parent;
//     }

//     /**
//      * Returns the maximum priority of this thread group. Threads that are
//      * part of this group cannot have a higher priority than the maximum
//      * priority.
//      *
//      * @return  the maximum priority that a thread in this thread group
//      *          can have.
//      * @see     #setMaxPriority
//      * @since   1.0
//      */
//     final int getMaxPriority() {
//         return maxPriority;
//     }

//     /**
//      * Tests if this thread group is a daemon thread group. A
//      * daemon thread group is automatically destroyed when its last
//      * thread is stopped or its last thread group is destroyed.
//      *
//      * @return  {@code true} if this thread group is a daemon thread group;
//      *          {@code false} otherwise.
//      * @since   1.0
//      */
//     final bool isDaemon() {
//         return daemon;
//     }

//     /**
//      * Tests if this thread group has been destroyed.
//      *
//      * @return  true if this object is destroyed
//      * @since   1.1
//      */
//     synchronized bool isDestroyed() {
//         return destroyed;
//     }

//     /**
//      * Changes the daemon status of this thread group.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      * <p>
//      * A daemon thread group is automatically destroyed when its last
//      * thread is stopped or its last thread group is destroyed.
//      *
//      * @param      daemon   if {@code true}, marks this thread group as
//      *                      a daemon thread group; otherwise, marks this
//      *                      thread group as normal.
//      * @throws     SecurityException  if the current thread cannot modify
//      *               this thread group.
//      * @see        java.lang.SecurityException
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.0
//      */
//     final void setDaemon(bool daemon) {
//         checkAccess();
//         this.daemon = daemon;
//     }

//     /**
//      * Sets the maximum priority of the group. Threads in the thread
//      * group that already have a higher priority are not affected.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      * <p>
//      * If the {@code pri} argument is less than
//      * {@link Thread#PRIORITY_MIN} or greater than
//      * {@link Thread#PRIORITY_MAX}, the maximum priority of the group
//      * remains unchanged.
//      * <p>
//      * Otherwise, the priority of this ThreadGroupEx object is set to the
//      * smaller of the specified {@code pri} and the maximum permitted
//      * priority of the parent of this thread group. (If this thread group
//      * is the system thread group, which has no parent, then its maximum
//      * priority is simply set to {@code pri}.) Then this method is
//      * called recursively, with {@code pri} as its argument, for
//      * every thread group that belongs to this thread group.
//      *
//      * @param      pri   the new priority of the thread group.
//      * @throws     SecurityException  if the current thread cannot modify
//      *               this thread group.
//      * @see        #getMaxPriority
//      * @see        java.lang.SecurityException
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.0
//      */
//     final void setMaxPriority(int pri) {
//         int ngroupsSnapshot;
//         ThreadGroupEx[] groupsSnapshot;
//         synchronized (this) {
//             checkAccess();
//             if (pri < Thread.PRIORITY_MIN || pri > Thread.PRIORITY_MAX) {
//                 return;
//             }
//             maxPriority = (parent !is null) ? min(pri, parent.maxPriority) : pri;
//             ngroupsSnapshot = ngroups;
//             if (groups !is null) {
//                 groupsSnapshot = groups[0..ngroupsSnapshot]; // Arrays.copyOf(groups, ngroupsSnapshot);
//             } else {
//                 groupsSnapshot = null;
//             }
//         }
//         for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//             groupsSnapshot[i].setMaxPriority(pri);
//         }
//     }

//     /**
//      * Tests if this thread group is either the thread group
//      * argument or one of its ancestor thread groups.
//      *
//      * @param   g   a thread group.
//      * @return  {@code true} if this thread group is the thread group
//      *          argument or one of its ancestor thread groups;
//      *          {@code false} otherwise.
//      * @since   1.0
//      */
//     final bool parentOf(ThreadGroupEx g) {
//         for (; g !is null ; g = g.parent) {
//             if (g == this) {
//                 return true;
//             }
//         }
//         return false;
//     }

//     /**
//      * Determines if the currently running thread has permission to
//      * modify this thread group.
//      * <p>
//      * If there is a security manager, its {@code checkAccess} method
//      * is called with this thread group as its argument. This may result
//      * in throwing a {@code SecurityException}.
//      *
//      * @throws     SecurityException  if the current thread is not allowed to
//      *               access this thread group.
//      * @see        java.lang.SecurityManager#checkAccess(java.lang.ThreadGroupEx)
//      * @since      1.0
//      */
//     final void checkAccess() {
//         // TODO: Tasks pending completion -@zxp at 10/13/2018, 4:13:51 PM
//         // 
//         // SecurityManager security = System.getSecurityManager();
//         // if (security !is null) {
//         //     security.checkAccess(this);
//         // }
//     }

//     /**
//      * Returns an estimate of the number of active threads in this thread
//      * group and its subgroups. Recursively iterates over all subgroups in
//      * this thread group.
//      *
//      * <p> The value returned is only an estimate because the number of
//      * threads may change dynamically while this method traverses internal
//      * data structures, and might be affected by the presence of certain
//      * system threads. This method is intended primarily for debugging
//      * and monitoring purposes.
//      *
//      * @return  an estimate of the number of active threads in this thread
//      *          group and in any other thread group that has this thread
//      *          group as an ancestor
//      *
//      * @since   1.0
//      */
//     int activeCount() {
//         int result;
//         // Snapshot sub-group data so we don't hold this lock
//         // while our children are computing.
//         int ngroupsSnapshot;
//         ThreadGroupEx[] groupsSnapshot;
//         synchronized (this) {
//             if (destroyed) {
//                 return 0;
//             }
//             result = nthreads;
//             ngroupsSnapshot = ngroups;
//             if (groups !is null) {
//                 groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//                 groupsSnapshot[0..groups.length] = groups[0..$];
//                 // Arrays.copyOf(groups, ngroupsSnapshot);
//             } else {
//                 groupsSnapshot = null;
//             }
//         }
//         for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//             result += groupsSnapshot[i].activeCount();
//         }
//         return result;
//     }

//     /**
//      * Copies into the specified array every active thread in this
//      * thread group and its subgroups.
//      *
//      * <p> An invocation of this method behaves in exactly the same
//      * way as the invocation
//      *
//      * <blockquote>
//      * {@linkplain #enumerate(Thread[], bool) enumerate}{@code (list, true)}
//      * </blockquote>
//      *
//      * @param  list
//      *         an array into which to put the list of threads
//      *
//      * @return  the number of threads put into the array
//      *
//      * @throws  SecurityException
//      *          if {@linkplain #checkAccess checkAccess} determines that
//      *          the current thread cannot access this thread group
//      *
//      * @since   1.0
//      */
//     int enumerate(Thread[] list) {
//         checkAccess();
//         return enumerate(list, 0, true);
//     }

//     /**
//      * Copies into the specified array every active thread in this
//      * thread group. If {@code recurse} is {@code true},
//      * this method recursively enumerates all subgroups of this
//      * thread group and references to every active thread in these
//      * subgroups are also included. If the array is too short to
//      * hold all the threads, the extra threads are silently ignored.
//      *
//      * <p> An application might use the {@linkplain #activeCount activeCount}
//      * method to get an estimate of how big the array should be, however
//      * <i>if the array is too short to hold all the threads, the extra threads
//      * are silently ignored.</i>  If it is critical to obtain every active
//      * thread in this thread group, the caller should verify that the returned
//      * int value is strictly less than the length of {@code list}.
//      *
//      * <p> Due to the inherent race condition in this method, it is recommended
//      * that the method only be used for debugging and monitoring purposes.
//      *
//      * @param  list
//      *         an array into which to put the list of threads
//      *
//      * @param  recurse
//      *         if {@code true}, recursively enumerate all subgroups of this
//      *         thread group
//      *
//      * @return  the number of threads put into the array
//      *
//      * @throws  SecurityException
//      *          if {@linkplain #checkAccess checkAccess} determines that
//      *          the current thread cannot access this thread group
//      *
//      * @since   1.0
//      */
//     int enumerate(Thread[] list, bool recurse) {
//         checkAccess();
//         return enumerate(list, 0, recurse);
//     }

//     private int enumerate(Thread[] list, int n, bool recurse) {
//         int ngroupsSnapshot = 0;
//         ThreadGroupEx[] groupsSnapshot = null;
//         synchronized (this) {
//             if (destroyed) {
//                 return 0;
//             }
//             size_t nt = nthreads;
//             if (nt > list.length - n) {
//                 nt = list.length - n;
//             }
//             for (size_t i = 0; i < nt; i++) {
//                 // TODO: Tasks pending completion -@zxp at 10/14/2018, 9:11:46 AM
//                 // 
//                 implementationMissing(false);
//                 // if (threads[i].isAlive()) {
//                 //     list[n++] = threads[i];
//                 // }
//             }
//             if (recurse) {
//                 ngroupsSnapshot = ngroups;
//                 if (groups !is null) {
//                     groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//                     groupsSnapshot[0..groups.length] = groups[0..$];
//                     // Arrays.copyOf(groups, ngroupsSnapshot);
//                 } else {
//                     groupsSnapshot = null;
//                 }
//             }
//         }
//         if (recurse) {
//             for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//                 n = groupsSnapshot[i].enumerate(list, n, true);
//             }
//         }
//         return n;
//     }

//     /**
//      * Returns an estimate of the number of active groups in this
//      * thread group and its subgroups. Recursively iterates over
//      * all subgroups in this thread group.
//      *
//      * <p> The value returned is only an estimate because the number of
//      * thread groups may change dynamically while this method traverses
//      * internal data structures. This method is intended primarily for
//      * debugging and monitoring purposes.
//      *
//      * @return  the number of active thread groups with this thread group as
//      *          an ancestor
//      *
//      * @since   1.0
//      */
//     int activeGroupCount() {
//         int ngroupsSnapshot;
//         ThreadGroupEx[] groupsSnapshot;
//         synchronized (this) {
//             if (destroyed) {
//                 return 0;
//             }
//             ngroupsSnapshot = ngroups;
//             if (groups !is null) {
//                 groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//                 groupsSnapshot[0..groups.length] = groups[0..$];
//                 // Arrays.copyOf(groups, ngroupsSnapshot);
//             } else {
//                 groupsSnapshot = null;
//             }
//         }
//         int n = ngroupsSnapshot;
//         for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//             n += groupsSnapshot[i].activeGroupCount();
//         }
//         return n;
//     }

//     /**
//      * Copies into the specified array references to every active
//      * subgroup in this thread group and its subgroups.
//      *
//      * <p> An invocation of this method behaves in exactly the same
//      * way as the invocation
//      *
//      * <blockquote>
//      * {@linkplain #enumerate(ThreadGroupEx[], bool) enumerate}{@code (list, true)}
//      * </blockquote>
//      *
//      * @param  list
//      *         an array into which to put the list of thread groups
//      *
//      * @return  the number of thread groups put into the array
//      *
//      * @throws  SecurityException
//      *          if {@linkplain #checkAccess checkAccess} determines that
//      *          the current thread cannot access this thread group
//      *
//      * @since   1.0
//      */
//     int enumerate(ThreadGroupEx[] list) {
//         checkAccess();
//         return enumerate(list, 0, true);
//     }

//     /**
//      * Copies into the specified array references to every active
//      * subgroup in this thread group. If {@code recurse} is
//      * {@code true}, this method recursively enumerates all subgroups of this
//      * thread group and references to every active thread group in these
//      * subgroups are also included.
//      *
//      * <p> An application might use the
//      * {@linkplain #activeGroupCount activeGroupCount} method to
//      * get an estimate of how big the array should be, however <i>if the
//      * array is too short to hold all the thread groups, the extra thread
//      * groups are silently ignored.</i>  If it is critical to obtain every
//      * active subgroup in this thread group, the caller should verify that
//      * the returned int value is strictly less than the length of
//      * {@code list}.
//      *
//      * <p> Due to the inherent race condition in this method, it is recommended
//      * that the method only be used for debugging and monitoring purposes.
//      *
//      * @param  list
//      *         an array into which to put the list of thread groups
//      *
//      * @param  recurse
//      *         if {@code true}, recursively enumerate all subgroups
//      *
//      * @return  the number of thread groups put into the array
//      *
//      * @throws  SecurityException
//      *          if {@linkplain #checkAccess checkAccess} determines that
//      *          the current thread cannot access this thread group
//      *
//      * @since   1.0
//      */
//     int enumerate(ThreadGroupEx[] list, bool recurse) {
//         checkAccess();
//         return enumerate(list, 0, recurse);
//     }

//     private int enumerate(ThreadGroupEx[] list, int n, bool recurse) {
//         int ngroupsSnapshot = 0;
//         ThreadGroupEx[] groupsSnapshot = null;
//         synchronized (this) {
//             if (destroyed) {
//                 return 0;
//             }
//             size_t ng = ngroups;
//             if (ng > list.length - n) {
//                 ng = list.length - n;
//             }
//             if (ng > 0) {
//                 // System.arraycopy(groups, 0, list, n, ng);
//                 list[n .. n+ng] = groups[0..ng];
//                 n += ng;
//             }
//             if (recurse) {
//                 ngroupsSnapshot = ngroups;
//                 if (groups !is null) {
//                     groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//                     groupsSnapshot[0..groups.length] = groups[0..$]; 
//                     // Arrays.copyOf(groups, ngroupsSnapshot);
//                 } else {
//                     groupsSnapshot = null;
//                 }
//             }
//         }
//         if (recurse) {
//             for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//                 n = groupsSnapshot[i].enumerate(list, n, true);
//             }
//         }
//         return n;
//     }

//     /**
//      * Stops all threads in this thread group.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      * <p>
//      * This method then calls the {@code stop} method on all the
//      * threads in this thread group and in all of its subgroups.
//      *
//      * @throws     SecurityException  if the current thread is not allowed
//      *               to access this thread group or any of the threads in
//      *               the thread group.
//      * @see        java.lang.SecurityException
//      * @see        java.lang.Thread#stop()
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.0
//      * @deprecated    This method is inherently unsafe.  See
//      *     {@link Thread#stop} for details.
//      */
//     //@Deprecated(since="1.2")
//     // final void stop() {
//     //     if (stopOrSuspend(false))
//     //         Thread.getThis().stop();
//     // }

//     /**
//      * Interrupts all threads in this thread group.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      * <p>
//      * This method then calls the {@code interrupt} method on all the
//      * threads in this thread group and in all of its subgroups.
//      *
//      * @throws     SecurityException  if the current thread is not allowed
//      *               to access this thread group or any of the threads in
//      *               the thread group.
//      * @see        java.lang.Thread#interrupt()
//      * @see        java.lang.SecurityException
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.2
//      */
//     final void interrupt() {
//         int ngroupsSnapshot;
//         ThreadGroupEx[] groupsSnapshot;
//         synchronized (this) {
//             checkAccess();
//             // for (int i = 0 ; i < nthreads ; i++) {
//             //     threads[i].interrupt();
//             // }
//             // TODO: Tasks pending completion -@zxp at 10/14/2018, 9:13:18 AM
//             // 
//             implementationMissing(false);
//             ngroupsSnapshot = ngroups;
//             if (groups !is null) {
//                 groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//                 groupsSnapshot[0..groups.length] = groups[0..$];
//                 // Arrays.copyOf(groups, ngroupsSnapshot);
//             } else {
//                 groupsSnapshot = null;
//             }
//         }
//         for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//             groupsSnapshot[i].interrupt();
//         }
//     }

//     /**
//      * Suspends all threads in this thread group.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      * <p>
//      * This method then calls the {@code suspend} method on all the
//      * threads in this thread group and in all of its subgroups.
//      *
//      * @throws     SecurityException  if the current thread is not allowed
//      *               to access this thread group or any of the threads in
//      *               the thread group.
//      * @see        java.lang.Thread#suspend()
//      * @see        java.lang.SecurityException
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.0
//      * @deprecated    This method is inherently deadlock-prone.  See
//      *     {@link Thread#suspend} for details.
//      */
//     //@Deprecated(since="1.2")
//     // @SuppressWarnings("deprecation")
//     // final void suspend() {
//     //     if (stopOrSuspend(true))
//     //         Thread.getThis().suspend();
//     // }

//     /**
//      * Helper method: recursively stops or suspends (as directed by the
//      * bool argument) all of the threads in this thread group and its
//      * subgroups, except the current thread.  This method returns true
//      * if (and only if) the current thread is found to be in this thread
//      * group or one of its subgroups.
//      */
//     // @SuppressWarnings("deprecation")
//     // private bool stopOrSuspend(bool suspend) {
//     //     bool suicide = false;
//     //     Thread us = Thread.getThis();
//     //     int ngroupsSnapshot;
//     //     ThreadGroupEx[] groupsSnapshot = null;
//     //     synchronized (this) {
//     //         checkAccess();
//     //         for (int i = 0 ; i < nthreads ; i++) {
//     //             if (threads[i]==us)
//     //                 suicide = true;
//     //             else if (suspend)
//     //                 threads[i].suspend();
//     //             else
//     //                 threads[i].stop();
//     //         }

//     //         ngroupsSnapshot = ngroups;
//     //         if (groups !is null) {                
//     //             groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//     //             groupsSnapshot[0..groups.length] = groups[0..$];
//     //             // Arrays.copyOf(groups, ngroupsSnapshot);
//     //         }
//     //     }
//     //     for (int i = 0 ; i < ngroupsSnapshot ; i++)
//     //         suicide = groupsSnapshot[i].stopOrSuspend(suspend) || suicide;

//     //     return suicide;
//     // }

//     /**
//      * Resumes all threads in this thread group.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      * <p>
//      * This method then calls the {@code resume} method on all the
//      * threads in this thread group and in all of its sub groups.
//      *
//      * @throws     SecurityException  if the current thread is not allowed to
//      *               access this thread group or any of the threads in the
//      *               thread group.
//      * @see        java.lang.SecurityException
//      * @see        java.lang.Thread#resume()
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.0
//      * @deprecated    This method is used solely in conjunction with
//      *       {@code Thread.suspend} and {@code ThreadGroupEx.suspend},
//      *       both of which have been deprecated, as they are inherently
//      *       deadlock-prone.  See {@link Thread#suspend} for details.
//      */
//     //@Deprecated(since="1.2")
//     // @SuppressWarnings("deprecation")
//     // final void resume() {
//     //     int ngroupsSnapshot;
//     //     ThreadGroupEx[] groupsSnapshot;
//     //     synchronized (this) {
//     //         checkAccess();
//     //         for (int i = 0 ; i < nthreads ; i++) {
//     //             threads[i].resume();
//     //         }
//     //         ngroupsSnapshot = ngroups;
//     //         if (groups !is null) {
//     //             groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//     //             groupsSnapshot[0..groups.length] = groups[0..$];
//     //             // Arrays.copyOf(groups, ngroupsSnapshot);
//     //         } else {
//     //             groupsSnapshot = null;
//     //         }
//     //     }
//     //     for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//     //         groupsSnapshot[i].resume();
//     //     }
//     // }

//     /**
//      * Destroys this thread group and all of its subgroups. This thread
//      * group must be empty, indicating that all threads that had been in
//      * this thread group have since stopped.
//      * <p>
//      * First, the {@code checkAccess} method of this thread group is
//      * called with no arguments; this may result in a security exception.
//      *
//      * @throws     IllegalThreadStateException  if the thread group is not
//      *               empty or if the thread group has already been destroyed.
//      * @throws     SecurityException  if the current thread cannot modify this
//      *               thread group.
//      * @see        java.lang.ThreadGroupEx#checkAccess()
//      * @since      1.0
//      */
//     final void destroy() {
//         int ngroupsSnapshot;
//         ThreadGroupEx[] groupsSnapshot;
//         synchronized (this) {
//             checkAccess();
//             if (destroyed || (nthreads > 0)) {
//                 throw new IllegalThreadStateException();
//             }
//             ngroupsSnapshot = ngroups;
//             if (groups !is null) {
//                 groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//                 groupsSnapshot[0..groups.length] = groups[0..$];
//                 // Arrays.copyOf(groups, ngroupsSnapshot);
//             } else {
//                 groupsSnapshot = null;
//             }
//             if (parent !is null) {
//                 destroyed = true;
//                 ngroups = 0;
//                 groups = null;
//                 nthreads = 0;
//                 threads = null;
//             }
//         }
//         for (int i = 0 ; i < ngroupsSnapshot ; i += 1) {
//             groupsSnapshot[i].destroy();
//         }
//         if (parent !is null) {
//             parent.remove(this);
//         }
//     }

//     /**
//      * Adds the specified Thread group to this group.
//      * @param g the specified Thread group to be added
//      * @throws  IllegalThreadStateException If the Thread group has been destroyed.
//      */
//     private final void add(ThreadGroupEx g){
//         synchronized (this) {
//             if (destroyed) {
//                 throw new IllegalThreadStateException();
//             }
//             if (groups is null) {
//                 groups = new ThreadGroupEx[4];
//             } else if (ngroups == groups.length) {
//                 // groups = Arrays.copyOf(groups, ngroups * 2);
//                 ThreadGroupEx[] th = new ThreadGroupEx[ngroups * 2];
//                 th[0..groups.length] = groups[0..$];
//                 groups = th;
//             }
//             groups[ngroups] = g;

//             // This is done last so it doesn't matter in case the
//             // thread is killed
//             ngroups++;
//         }
//     }

//     /**
//      * Removes the specified Thread group from this group.
//      * @param g the Thread group to be removed
//      * @return if this Thread has already been destroyed.
//      */
//     private void remove(ThreadGroupEx g) {
//         synchronized (this) {
//             if (destroyed) {
//                 return;
//             }
//             for (int i = 0 ; i < ngroups ; i++) {
//                 if (groups[i] == g) {
//                     ngroups -= 1;
//                     // System.arraycopy(groups, i + 1, groups, i, ngroups - i);
//                     for(int j=i; j<ngroups; j++)
//                         groups[j] = groups[j+1];
//                     // Zap dangling reference to the dead group so that
//                     // the garbage collector will collect it.
//                     groups[ngroups] = null;
//                     break;
//                 }
//             }
//             if (nthreads == 0) {
//                 // notifyAll();
//             }
//             if (daemon && (nthreads == 0) &&
//                 (nUnstartedThreads == 0) && (ngroups == 0))
//             {
//                 destroy();
//             }
//         }
//     }


//     /**
//      * Increments the count of unstarted threads in the thread group.
//      * Unstarted threads are not added to the thread group so that they
//      * can be collected if they are never started, but they must be
//      * counted so that daemon thread groups with unstarted threads in
//      * them are not destroyed.
//      */
//     void addUnstarted() {
//         synchronized(this) {
//             if (destroyed) {
//                 throw new IllegalThreadStateException();
//             }
//             nUnstartedThreads++;
//         }
//     }

//     /**
//      * Adds the specified thread to this thread group.
//      *
//      * <p> Note: This method is called from both library code
//      * and the Virtual Machine. It is called from VM to add
//      * certain system threads to the system thread group.
//      *
//      * @param  t
//      *         the Thread to be added
//      *
//      * @throws IllegalThreadStateException
//      *          if the Thread group has been destroyed
//      */
//     void add(Thread t) {
//         synchronized (this) {
//             if (destroyed) {
//                 throw new IllegalThreadStateException();
//             }
//             if (threads is null) {
//                 threads = new Thread[4];
//             } else if (nthreads == threads.length) {
//                 Thread[] th = new Thread[nthreads * 2];
//                 th[0..threads.length] = threads[0..$];
//                 threads = th;
//                 // threads = Arrays.copyOf(threads, nthreads * 2);
//             }
//             threads[nthreads] = t;

//             // This is done last so it doesn't matter in case the
//             // thread is killed
//             nthreads++;

//             // The thread is now a fully fledged member of the group, even
//             // though it may, or may not, have been started yet. It will prevent
//             // the group from being destroyed so the unstarted Threads count is
//             // decremented.
//             nUnstartedThreads--;
//         }
//     }

//     /**
//      * Notifies the group that the thread {@code t} has failed
//      * an attempt to start.
//      *
//      * <p> The state of this thread group is rolled back as if the
//      * attempt to start the thread has never occurred. The thread is again
//      * considered an unstarted member of the thread group, and a subsequent
//      * attempt to start the thread is permitted.
//      *
//      * @param  t
//      *         the Thread whose start method was invoked
//      */
//     void threadStartFailed(Thread t) {
//         synchronized(this) {
//             remove(t);
//             nUnstartedThreads++;
//         }
//     }

//     /**
//      * Notifies the group that the thread {@code t} has terminated.
//      *
//      * <p> Destroy the group if all of the following conditions are
//      * true: this is a daemon thread group; there are no more alive
//      * or unstarted threads in the group; there are no subgroups in
//      * this thread group.
//      *
//      * @param  t
//      *         the Thread that has terminated
//      */
//     void threadTerminated(Thread t) {
//         synchronized (this) {
//             remove(t);

//             if (nthreads == 0) {
//                 // TODO: Tasks pending completion -@zxp at 10/14/2018, 9:04:08 AM
//                 // 
//                 implementationMissing(false);
//                 // notifyAll();
//             }
//             if (daemon && (nthreads == 0) &&
//                 (nUnstartedThreads == 0) && (ngroups == 0))
//             {
//                 destroy();
//             }
//         }
//     }

//     /**
//      * Removes the specified Thread from this group. Invoking this method
//      * on a thread group that has been destroyed has no effect.
//      *
//      * @param  t
//      *         the Thread to be removed
//      */
//     private void remove(Thread t) {
//         synchronized (this) {
//             if (destroyed) {
//                 return;
//             }
//             for (int i = 0 ; i < nthreads ; i++) {
//                 if (threads[i] == t) {
//                     //System.arraycopy(threads, i + 1, threads, i, --nthreads - i);
//                     --nthreads;
//                     for(int j=i; j<nthreads; j++)
//                         threads[j] = threads[j+1];

//                     // Zap dangling reference to the dead thread so that
//                     // the garbage collector will collect it.
//                     threads[nthreads] = null;
//                     break;
//                 }
//             }
//         }
//     }

//     /**
//      * Prints information about this thread group to the standard
//      * output. This method is useful only for debugging.
//      *
//      * @since   1.0
//      */
//     // void list() {
//     //     list(System.out, 0);
//     // }
//     // void list(PrintStream out, int indent) {
//     //     int ngroupsSnapshot;
//     //     ThreadGroupEx[] groupsSnapshot;
//     //     synchronized (this) {
//     //         for (int j = 0 ; j < indent ; j++) {
//     //             out.print(" ");
//     //         }
//     //         out.println(this);
//     //         indent += 4;
//     //         for (int i = 0 ; i < nthreads ; i++) {
//     //             for (int j = 0 ; j < indent ; j++) {
//     //                 out.print(" ");
//     //             }
//     //             out.println(threads[i]);
//     //         }
//     //         ngroupsSnapshot = ngroups;
//     //         if (groups !is null) {
//     //             groupsSnapshot = new ThreadGroupEx[ngroupsSnapshot]; 
//     //             groupsSnapshot[0..groups.length] = groups[0..$];
//     //             // Arrays.copyOf(groups, ngroupsSnapshot);
//     //         } else {
//     //             groupsSnapshot = null;
//     //         }
//     //     }
//     //     for (int i = 0 ; i < ngroupsSnapshot ; i++) {
//     //         groupsSnapshot[i].list(out, indent);
//     //     }
//     // }

//     /**
//      * Called by the Java Virtual Machine when a thread in this
//      * thread group stops because of an uncaught exception, and the thread
//      * does not have a specific {@link UncaughtExceptionHandler}
//      * installed.
//      * <p>
//      * The {@code uncaughtException} method of
//      * {@code ThreadGroupEx} does the following:
//      * <ul>
//      * <li>If this thread group has a parent thread group, the
//      *     {@code uncaughtException} method of that parent is called
//      *     with the same two arguments.
//      * <li>Otherwise, this method checks to see if there is a
//      *     {@linkplain Thread#getDefaultUncaughtExceptionHandler default
//      *     uncaught exception handler} installed, and if so, its
//      *     {@code uncaughtException} method is called with the same
//      *     two arguments.
//      * <li>Otherwise, this method determines if the {@code Throwable}
//      *     argument is an instance of {@link ThreadDeath}. If so, nothing
//      *     special is done. Otherwise, a message containing the
//      *     thread's name, as returned from the thread's {@link
//      *     Thread#getName getName} method, and a stack backtrace,
//      *     using the {@code Throwable}'s {@link
//      *     Throwable#printStackTrace printStackTrace} method, is
//      *     printed to the {@linkplain System#err standard error stream}.
//      * </ul>
//      * <p>
//      * Applications can override this method in subclasses of
//      * {@code ThreadGroupEx} to provide alternative handling of
//      * uncaught exceptions.
//      *
//      * @param   t   the thread that is about to exit.
//      * @param   e   the uncaught exception.
//      * @since   1.0
//      */
//     void uncaughtException(Thread t, Throwable e) {
//         if (parent !is null) {
//             parent.uncaughtException(t, e);
//         } else {
//             UncaughtExceptionHandler ueh = getDefaultUncaughtExceptionHandler();
//             if (ueh !is null) {
//                 ueh.uncaughtException(t, e);
//             } else {
//                 stderr.writeln("Exception in thread \"" ~ t.name() ~ "\" ");
//                 stderr.writeln(e.toString());
//             }
//         }
//     }

//     /**
//      * Returns a string representation of this Thread group.
//      *
//      * @return  a string representation of this thread group.
//      * @since   1.0
//      */
//     override string toString() {
//         return typeid(this).name ~ "[name=" ~ getName() ~ 
//             ",maxpri=" ~ maxPriority.to!string() ~ "]";
//     }
// }