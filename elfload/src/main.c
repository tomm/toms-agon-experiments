#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define MOS_INVALID_EXECUTABLE 21
// st_shndx special values
#define SHN_ABS 0xfff1

struct __attribute__((packed)) Elf32_Sym {
	uint32_t	st_name;
	uint32_t	st_value;
	uint32_t	st_size;
	unsigned char	st_info;
	unsigned char	st_other;
	uint16_t	st_shndx;
};

void fatal(const char *msg)
{
	fputs("Error: ", stderr);
	fputs(msg, stderr);
	fputs("\r\n", stderr);
	exit(-1);
}

// returns pointer into static data
struct Elf32_Sym *lookup_sym(FILE *elf_file, uint32_t symtab_offset, uint32_t sym_number)
{
	static struct Elf32_Sym sym;
	fseek(elf_file, symtab_offset + sym_number*sizeof(struct Elf32_Sym), SEEK_SET);
	if (fread(&sym, 1, sizeof(struct Elf32_Sym), elf_file) != sizeof(struct Elf32_Sym)) {
		fatal("Error in symtable lookup");
	}

	return &sym;
}

uint16_t rd_u16(const uint8_t *data)
{
	return (uint16_t)data[0] | (uint16_t)data[1]<<8;
}

uint32_t rd_u24(const uint8_t *data)
{
	return (uint32_t)data[0] | (uint32_t)data[1]<<8 | (uint32_t)data[2]<<16;
}

void wr_u24(uint8_t *data, uint32_t val)
{
	data[0] = val & 0xff;
	data[1] = (val >> 8) & 0xff;
	data[2] = (val >> 16) & 0xff;
}

uint32_t rd_u32(const uint8_t *data)
{
	return (uint32_t)data[0] | (uint32_t)data[1]<<8 | (uint32_t)data[2]<<16 | (uint32_t)data[3]<<24;
}

void fwrite_u24(FILE *f, uint32_t val)
{
	uint8_t b = val & 0xff;
	fwrite(&b, 1, 1, f);
	b = (val >> 8) & 0xff;
	fwrite(&b, 1, 1, f);
	b = (val >> 16) & 0xff;
	fwrite(&b, 1, 1, f);
}

void load_elf(FILE *elf_file, uint24_t load_address)
{
	uint8_t header[0x34];

	if (fread(header, 1, 0x34, elf_file) != 0x34) {
		fatal("Failed to load ELF header");
	}

	if (header[0] != 0x7f || header[1] != 'E' || header[2] != 'L' || header[3] != 'F') fatal("not elf");
	if (header[4] != 1) fatal("not elf32");
	if (header[5] != 1) fatal("not little endian");
	if (header[6] != 1) fatal("unsupported elf version");
	if (header[0x10] != 2) fatal("not elf e_type ET_EXEC (executable");
	if (header[0x12] != 0xdc) fatal("not arch z80");
	if (rd_u32(header + 0x14) != 1) fatal("unsupported elf version");

	uint32_t e_entry = rd_u32(header + 0x18);
	uint32_t e_phoff = rd_u32(header + 0x1c);
	uint32_t e_shoff = rd_u32(header + 0x20);
	uint16_t e_phentsize = rd_u16(header + 0x2a);
	uint16_t e_phnum = rd_u16(header + 0x2c);
	uint16_t e_shentsize = rd_u16(header + 0x2e);
	uint16_t e_shnum = rd_u16(header + 0x30);
	printf("e_entry: 0x%x\n", e_entry);
	printf("e_phoff: 0x%lx, e_phnum %d, e_phentsize 0x%x\n", e_phoff, e_phnum, e_phentsize);
	printf("e_shoff: 0x%lx, e_shnum %d, e_shentsize 0x%x\n", e_shoff, e_shnum, e_shentsize);

	if (e_phentsize != 0x20) {
		fatal("Unexpected e_phentsize. Expected 0x20");
	}
	if (e_shentsize != 0x28) {
		fatal("Unexpected e_shentsize. Expected 0x28");
	}

	// Now load the program header into header[]
	fseek(elf_file, e_phoff, SEEK_SET);
	if (fread(header, 1, e_phentsize, elf_file) != e_phentsize) {
		fatal("Failed to load ELF program header");
	}
	
	if (rd_u32(header) != 1) fatal("program header not PT_LOAD");
	if (e_phnum != 1) fatal("expected only 1 program header");

	// offset of program segment in the file
	uint32_t p_offset = rd_u32(header + 0x4);
	uint32_t p_vaddr = rd_u32(header + 0x8);
	uint32_t p_paddr = rd_u32(header + 0xc);
	uint32_t p_filesz = rd_u32(header + 0x10);

	printf("p_offset 0x%lx, p_vaddr 0x%lx, p_paddr 0x%lx, p_filesz 0x%lx\n", p_offset, p_vaddr, p_paddr, p_filesz);

	// write raw program binary to memory
	fseek(elf_file, p_offset, SEEK_SET);
	fread((void*)load_address, 1, p_filesz, elf_file);

	int output_reloc_table_size = 0;
	uint32_t symtab_offset = 0;
	uint32_t symtab_size = 0;
	for (int section=0; section<e_shnum; section++) {
		size_t header_offset = e_shoff + e_shentsize*section;
		fseek(elf_file, header_offset, SEEK_SET);
		if (fread(header, 1, e_shentsize, elf_file) != e_shentsize) {
			fatal("failed to load a section header");
		}
		uint32_t sh_type = rd_u32(header + 4);
		uint32_t sh_offset = rd_u32(header + 0x10);
		uint32_t sh_size = rd_u32(header + 0x14);
		if (sh_type == 0x2) {
			// SHT_SYMTAB
			symtab_offset = sh_offset;
			symtab_size = sh_size;
		}
	}

	printf("Found symbol table at 0x%x, size 0x%x\n", symtab_offset, symtab_size);

	for (int section=0; section<e_shnum; section++) {
		//size_t header_offset = e_shoff + e_shentsize*section;
		fseek(elf_file, e_shoff + e_shentsize*section, SEEK_SET);
		if (fread(header, 1, e_shentsize, elf_file) != e_shentsize) {
			fatal("Error reading ELF section header");
		}
		uint32_t sh_type = rd_u32(header + 4);
		uint32_t sh_offset = rd_u32(header + 0x10);
		uint32_t sh_size = rd_u32(header + 0x14);
		//printf("Section %d: sh_type 0x%lx\n", section, sh_type);
		// Ignore all sections except relocations (rela)
		if (sh_type != 0x4) continue;

		// SHT_RELA: relocation entries with addends
		for (int i=0; i<sh_size; i+=12) {
			uint8_t reloc_raw[12];
			fseek(elf_file, sh_offset + i, SEEK_SET);
			if (fread(reloc_raw, 1, 12, elf_file) != 12) {
				fatal("error reading relocations");
			}
			uint32_t relocation_offset = rd_u32(reloc_raw);
			uint32_t relocation_type = reloc_raw[4];
			uint32_t relocation_sym = rd_u24(reloc_raw + 5);
			uint32_t relocation_addend = rd_u32(reloc_raw + 8);

			// SKIP WEIRD ONES
			if (relocation_type != 5) continue;

			//printf("\t\trel offset 0x%x, type 0x%x, sym 0x%x, addend 0x%x\n", relocation_offset, relocation_type, relocation_sym, relocation_addend);
			const struct Elf32_Sym *sym = lookup_sym(elf_file, symtab_offset, relocation_sym);
			//printf("\t\tsym info 0x%x (type %d), value 0x%x, st_shndx %d\n", sym->st_info, sym->st_info & 0xf, sym->st_value, sym->st_shndx);

			if (sym->st_shndx != SHN_ABS) {
				uint32_t relocated_value = load_address + sym->st_value + relocation_addend;
				*(uint24_t*)(load_address + relocation_offset) = relocated_value;
			}
		}
	}
}

int main(int argc, char *argv[])
{
	if (argc < 3) {
		printf("Usage: elfload <some_elf32_ez80_executable> <0xload address>\r\n");
		exit(0);
	}
	int load_addr;
	if (sscanf(argv[2], "0x%x", &load_addr) != 1) {
		printf("Error parsing load address. %s is not a hex memory address\r\n", argv[2]);
		exit(0);
	}
	printf("Loading %s to 0x%x...\r\n", argv[1], load_addr);
	FILE *f = fopen(argv[1], "rb");
	if (!f) {
		printf("ELF executable '%s' not found\r\n", argv[1]);
		exit(MOS_INVALID_EXECUTABLE);
	}
	load_elf(f, load_addr);
	printf("Success. Try 'JMP &%x'\r\n", load_addr);

	fclose(f);
	return 0;
}

