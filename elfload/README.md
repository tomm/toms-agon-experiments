# Elfload

This is an elf loader for the Agon Light, which can load relocatable
elf32-z80 binaries.

You need [agondev](https://github.com/AgonPlatform/agondev) to build elfload.
The elf32-z80 binaries it loads can also be built using agondev. There
is an example of how to do this in the [example-elf-binary](./example-elf-binary)
directory.

Example usage (from the Agon MOS CLI):
```
elfload hello_elf.bin 0x56789
jmp &56789
```
