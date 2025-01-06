# ----------------------------
# Makefile Options
# ----------------------------

NAME = vi
DESCRIPTION = "VI"
COMPRESSED = NO

CFLAGS = -Wall -Wextra -Oz -ferror-limit=1
CXXFLAGS = -Wall -Wextra -Oz

INIT_LOC=040000
BSSHEAP_LOW=050000
BSSHEAP_HIGH=0a8000
STACK_HIGH=0affff

LDHAS_EXIT_HANDLER=0
# ----------------------------

include $(shell cedev-config --makefile)
