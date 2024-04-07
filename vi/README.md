# Vi for the Agon series of eZ80 computers

Requires MOS 2.2+

The pre-compiled binary (./bin/vi.bin) is intended to be put in the /bin directory
of your Agon's sdcard, where it can be invoked directly on the command line with:

`*vi helloworld.txt`

Agon Vi accepts some ex commands from the command prompt, but they must be *after*
the list of files to be edited. For example:

`*vi foo.txt bar.txt +20`

Will open `foo.txt` at line 20.

Agon Vi is based on Busybox Vi.

## New features of Agon Vi

Dos (CRLF) or Unix (LF) line endings can be chosen with these commands:

`:set ff=dos`
`:set ff=unix`

## Vi for MOS older than v2.2

An old moslet binary of vi is available [here](./bin/vi-obsolete-moslet.bin). It should
be placed in your sdcard's /mos/ directory. This binary is not for MOS 2.2+
