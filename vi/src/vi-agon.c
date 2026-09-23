#include "vi-agon.h"
#include <string.h>
#include <ctype.h>

void platform_init(void)
{
	kbuf_init(KEY_EVENT_BUF_LEN);
	// set scroll protection so bottom-right character can be written to without causing scroll
	putch(23); putch(16); putch(1), putch(0xfe);
}

/* Placed on agon 8k SRAM. This should be largely preserved
 * between invocations of vi, and soft resets. So we get
 * a somewhat persistent session. */
#define agon_vi_session ((struct agon_vi_session_t*)0xb7e000)

/* Note that we hash the upper-case transformed string,
 * since we are dealing with fatfs filenames on agon */
static unsigned int djb2_hash(const uint8_t *str)
{
	unsigned int hash = 5381;
	int c;
	while ((c = *str++)) hash = ((hash << 5) + hash) + toupper(c);
	return hash;
}

/** Returns zero if no record. */
int platform_lookup_session_ycursor_pos(const char *filename)
{
	if (!filename) return 0;

	if (agon_vi_session->magic_no != SESSION_MAGIC) return 0;

	unsigned int hash = djb2_hash((const uint8_t*)filename);

	for (uint8_t i=0; i<SESSION_LEN; i++) {
		if (agon_vi_session->filename_hash[i] == hash) {
			return agon_vi_session->line_no[i];
		}
	}
	return 0;
}

void platform_store_session_ycursor_pos(const char *filename, int line_no)
{
	if (!filename) return;

	if (agon_vi_session->magic_no != SESSION_MAGIC) {
		memset(agon_vi_session, 0, sizeof(struct agon_vi_session_t));
		agon_vi_session->magic_no = 0xcafeca;
	}

	unsigned int hash = djb2_hash((const uint8_t*)filename);

	// update if present
	for (uint8_t i=0; i<SESSION_LEN; i++) {
		if (agon_vi_session->filename_hash[i] == hash) {
			agon_vi_session->line_no[i] = line_no;
			return;
		}
	}

	// otherwise set new
	uint8_t idx = (agon_vi_session->current + 1) & (SESSION_LEN-1);
	agon_vi_session->current = idx;
	agon_vi_session->line_no[idx] = line_no;
	agon_vi_session->filename_hash[idx] = hash;
}

int platform_read_key()
{
	struct keyboard_event_t e;
	memset(&e, 0, sizeof(struct keyboard_event_t));

	for (;;) {
		while (!kbuf_poll_event(&e) || !e.isdown) {}

		// allowlist a few non-ascii keys that vi handles
		switch (e.vkey) {
		case VK_UP:
		case VK_RIGHT:
		case VK_DOWN:
		case VK_LEFT:
		case VK_HOME:
		case VK_END:
		case VK_PAGEUP:
		case VK_PAGEDOWN:
		case VK_DELETE:
		case VK_INSERT:
			return ((int)e.vkey) << 8;
		}

		if (e.ascii) return e.ascii;
	}
}
