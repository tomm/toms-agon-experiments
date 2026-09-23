#include <agon/mos.h>
#include <stdint.h>
#include <stdlib.h>
#include "agon-dirent.h"

DIR *opendir(const char *name)
{
	DIR *d = calloc(sizeof(DIR),1);
	uint8_t res = ffs_dopen(d, name);

	if (res) {
		free(d);
		return 0;
	}
	return d;
}

struct dirent *readdir(DIR *dirp)
{
	static struct dirent *de = 0;
	if (!de) de = calloc(sizeof(struct dirent), 1);

	uint8_t res = ffs_dread(dirp, (FILINFO*)de);
	if (res || !de->d_name[0]) {
		free(de);
		de = 0;
		return 0;
	}
	if (!(de->d_type & DT_DIR)) {
		// set synthetic 'regular file' flag
		de->d_type |= DT_REG;
	}
	return de;
}

int closedir(DIR *d)
{
	if (!d) return 0;
	uint8_t res = ffs_dclose(d);
	free(d);
	return res;
}
