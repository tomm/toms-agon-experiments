# Vi for the Agon series of eZ80 computers

The pre-compiled binary (./bin/vi.bin) is intended to be put in the /mos directory
of your Agon's sdcard, where it can be invoked directly on the command line with:

`*vi helloworld.txt`

Agon Vi accepts some ex commands from the command prompt, but they must be *after*
the list of files to be edited. For example:

`*vi foo.txt bar.txt +20`

Will open `foo.txt` at line 20.

Note that Agon Vi is not a true 'moslet' (an Agon MOS program designed to be loaded at
0xb0000, and coexist with another program residing at 0x40000), as it uses the whole
Agon RAM. This means that vi can only be run from a MOS prompt, not from within
another program such as BASIC (via star commands).

Agon Vi is based on Busybox Vi.

## New features of Agon Vi

Dos (CRLF) or Unix (LF) line endings can be chosen with these commands:

`:set ff=dos`
`:set ff=unix`
