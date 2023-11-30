#ifndef LIBBB_H
#define LIBBB_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <mos_api.h>

#define ALWAYS_INLINE inline
#define KEYCODE_BUFFER_SIZE 16
#define CONFIG_FEATURE_VI_MAX_LEN 4096
#define FALSE 0
#define TRUE 1
#define STRERROR_FMT    "%s"
#define STRERROR_ERRNO
typedef int smallint;

#define xstrdup(p) strdup(p)
#define xzalloc(s) calloc(s,1)
#define ARRAY_SIZE(x) ((unsigned)(sizeof(x) / sizeof((x)[0])))

#define KEYCODE_DOWN 0x81
#define KEYCODE_LEFT 0x82
#define KEYCODE_RIGHT 0x83
#define KEYCODE_HOME 0x84
#define KEYCODE_END 0x85
#define KEYCODE_PAGEUP 0x86
#define KEYCODE_PAGEDOWN 0x87
#define KEYCODE_DELETE 0x88
#define KEYCODE_INSERT 0x89
#define KEYCODE_UP 0x8a

#define ENABLE_FEATURE_VI_READONLY 0
#define ENABLE_FEATURE_VI_ASK_TERMINAL 0
#define IF_FEATURE_VI_ASK_TERMINAL(x) 0
#define isbackspace(c) ((c) == 0x7f)
//#define isbackspace(c) ((c) == term_orig.c_cc[VERASE] || (c) == 8 || (c) == 127)

// unistd.h, getopt.h stuff
char *optarg;
int optind = 1, opterr, optopt;

static inline void* memrchr(const void *s, int c, size_t n)
{
	const char *start = s, *end = s;

	end += n - 1;

	while (end >= start) {
		if (*end == (char)c)
			return (void *) end;
		end--;
	}

	return NULL;
}

static inline int get_scr_cols() { return getsysvar_scrCols() - 1; }
static inline int get_scr_rows() { return getsysvar_scrRows() - 1; }
static inline void goto_xy(int x, int y) {
	putch(31);
	putch(x);
	putch(y);
}

#endif
