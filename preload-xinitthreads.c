/*
 * Workaround for "Assertion `!xcb_xlib_threads_sequence_lost' failed"
 * Source: https://github.com/smcv/workaround-shadow-tactics
 *
 * Compile with:
 *   gcc -shared -fPIC -o preload-xinitthreads.so preload-xinitthreads.c -lX11
 */

#include <X11/Xlib.h>

__attribute__((constructor))
static void call_xinitthreads(void)
{
    XInitThreads();
}

