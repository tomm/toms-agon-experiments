#ifndef VI_AGON_H
#define VI_AGON_H

#include <agon/mos.h>
#include <agon/keyboard.h>
#include "agon-vkey.h"
#include "agon-dirent.h"

#define VI_VER "Agon vi v1.08 is based on Busybox vi"

#define KEYCODE_UP (VK_UP << 8)
#define KEYCODE_RIGHT (VK_RIGHT << 8)
#define KEYCODE_DOWN (VK_DOWN << 8)
#define KEYCODE_LEFT (VK_LEFT << 8)
#define KEYCODE_HOME (VK_HOME << 8)
#define KEYCODE_END (VK_END << 8)
#define KEYCODE_PAGEUP (VK_PAGEUP << 8)
#define KEYCODE_PAGEDOWN (VK_PAGEDOWN << 8)
#define KEYCODE_DELETE (VK_DELETE << 8)
#define KEYCODE_INSERT (VK_INSERT << 8)

#define ENABLE_FEATURE_VI_FUZZYFINDER 1
#define ENABLE_FEATURE_ALLOW_EXEC 1
#define ENABLE_FEATURE_VI_SEARCH 1
#define ENABLE_FEATURE_VI_YANKMARK 1
#define ENABLE_FEATURE_VI_DOT_CMD 1
#define ENABLE_FEATURE_VI_UNDO 1
#define ENABLE_FEATURE_VI_COLON 1
//#define ENABLE_FEATURE_VI_UNDO_QUEUE 1
//#define CONFIG_FEATURE_VI_UNDO_QUEUE_MAX 10
#define ENABLE_FEATURE_VI_READONLY 0
#define ENABLE_FEATURE_VI_ASK_TERMINAL 0
#define ENABLE_FEATURE_VI_SETOPTS 1
#define ENABLE_FEATURE_VI_SET 1
#define IF_FEATURE_VI_ASK_TERMINAL(x) 0
#define isbackspace(c) ((c) == 0x7f)
//#define isbackspace(c) ((c) == term_orig.c_cc[VERASE] || (c) == 8 || (c) == 127)

// Note the buffer includes key-up events, so will want twice as long as needed
#define KEY_EVENT_BUF_LEN 64

extern void platform_init(void);

static inline void platform_deinit()
{
	kbuf_deinit();
}

static inline void platform_putch(char c)
{
	putch(c);
}

static inline void platform_cursor_right(void)
{
	putch(9);
}

static inline void platform_text_highlight(void)
{
	if (getsysvar_scrColours() > 2) {
		putch(17); putch(129);
	}
}

static inline void platform_text_normal(void)
{
	if (getsysvar_scrColours() > 2) {
		putch(17); putch(128);
	}
}

static inline void platform_write_stdout(const char *out, int len)
{
	while (len--) {
		putch(*out);
		out++;
	}
}

/**
 * For ascii keys, return the ascii. For non ascii keys
 * return the fabgl vkey<<8
 */
extern int platform_read_key();

static inline int platform_get_columns() { return getsysvar_scrCols(); }
static inline int platform_get_rows() { return getsysvar_scrRows(); }
static inline void goto_xy(int x, int y) {
	putch(31);
	putch(x);
	putch(y);
}
static inline int system(char *command)
{
	return mos_oscli(command, &command, 1);	
}

/* Simple session store that records cursor position in different files. */
#define SESSION_LEN 32
#define SESSION_MAGIC 0xcafeca
struct agon_vi_session_t {
	int magic_no;
	uint8_t current;
	unsigned int filename_hash[SESSION_LEN];
	unsigned int line_no[SESSION_LEN];
};

/** Returns zero if no record. */
extern int platform_lookup_session_ycursor_pos(const char *filename);
extern void platform_store_session_ycursor_pos(const char *filename, int line_no);

#endif /* VI_AGON_H */
