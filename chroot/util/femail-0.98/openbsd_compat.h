/*	$Id: openbsd_compat.h,v 1.1 2005/08/16 16:33:05 brahe Exp $ */

#ifndef	HAS_FGETLN
char		*fgetln(FILE *, size_t *);
#endif

#ifndef HAS_STRLCPY
size_t		 strlcpy(char *, const char *, size_t);
#endif
