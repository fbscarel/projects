/*
 * uxgen.c: Unix implementation of get_heavy_noise() from cmdgen.c.
 */

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#include "putty.h"

char *get_random_data(int len)
{
    char *buf = snewn(len, char);
    int fd;
    int ngot, ret;

    fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) {
	sfree(buf);
	perror("puttygen: unable to open /dev/urandom");
	return NULL;
    }

    ngot = 0;
    while (ngot < len) {
	ret = read(fd, buf+ngot, len-ngot);
	if (ret < 0) {
	    close(fd);
            sfree(buf);
	    perror("puttygen: unable to read /dev/urandom");
	    return NULL;
	}
	ngot += ret;
    }

    close(fd);

    return buf;
}
