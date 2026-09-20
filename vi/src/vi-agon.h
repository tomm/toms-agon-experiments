#ifndef VI_AGON_H
#define VI_AGON_H

#include <agon/mos.h>
#include <agon/keyboard.h>

#define VI_VER "Agon VI v1.07 is based on Busybox VI"

// this is just nonsense I made to get it to compile
#define KEYCODE_UP 0x995
#define KEYCODE_RIGHT 0x996
#define KEYCODE_DOWN 0x997
#define KEYCODE_LEFT 0x998
// getch() returns zero for all these..
#define KEYCODE_HOME 0x999
#define KEYCODE_END 0x99a
#define KEYCODE_PAGEUP 0x99b
#define KEYCODE_PAGEDOWN 0x99c
#define KEYCODE_DELETE 0x99d
#define KEYCODE_INSERT 0x99e

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
#define IF_FEATURE_VI_ASK_TERMINAL(x) 0
#define isbackspace(c) ((c) == 0x7f)
//#define isbackspace(c) ((c) == term_orig.c_cc[VERASE] || (c) == 8 || (c) == 127)

// Note the buffer includes key-up events, so will want twice as long as needed
#define KEY_EVENT_BUF_LEN 64

static inline void platform_init()
{
	kbuf_init(KEY_EVENT_BUF_LEN);
	// set scroll protection so bottom-right character can be written to without causing scroll
	putch(23); putch(16); putch(1), putch(0xfe);
}

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

static inline int read_key()
{
	struct keyboard_event_t e;
	memset(&e, 0, sizeof(struct keyboard_event_t));

	while(!e.ascii || !e.isdown) {
		while (!kbuf_poll_event(&e)) {}
		//printf("%x %x %x %x\r\n", e.ascii, e.kmod, e.vkey, e.isdown);
	}

	return e.ascii;
}

static inline int get_scr_cols() { return getsysvar_scrCols(); }
static inline int get_scr_rows() { return getsysvar_scrRows(); }
static inline void goto_xy(int x, int y) {
	putch(31);
	putch(x);
	putch(y);
}
static inline int system(const char *command)
{
	return mos_oscli(command, &command, 1);	
}

#endif /* VI_AGON_H */
