#ifndef _AGON_DIRENT_H
#define _AGON_DIRENT_H

#include <agon/mos.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Approximate the posix dirent.h API
 */

/* Binary representation identical to MOS fatfs FILINFO struct.
 * Note this isn't posix-compliant, since mandatory d_ino is not present. */
struct dirent {
	uint32_t	ffs_fsize;			/* File size */
	uint16_t	ffs_fdate;			/* Modified date */
	uint16_t	ffs_ftime;			/* Modified time */
	uint8_t	    d_type;//fattrib;		/* File attribute */
	char	    ffs_altname[13];	/* Alternative file name */
	char	    d_name[256]; 	/* Primary file name */
};

/* dirent.d_type flags */
#define DT_DIR AM_DIR
#define DT_REG 0x80 /* Not a real fatfs flag */

extern DIR *opendir(const char *name);
extern struct dirent *readdir(DIR *dirp);
extern int closedir(DIR *d);

#endif /* _AGON_DIRENT_H */
