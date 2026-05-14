#include "stdio.h"

void emit_hex_data(char* label, char* in_filename, FILE* out_file) {
	FILE* in_file = fopen(in_filename, "r");
	fprintf(out_file, "%s db ", label);
	int len = 0;
	char c;
	while((c = fgetc(in_file)) != EOF) {
		fprintf(out_file, "0x%x,", c);
		len++;
	}
	fclose(in_file);

	fprintf(out_file, "0\n");
	fprintf(out_file, "%s_len dd %i\n", label, len);
}

int main(void) {
	FILE* out = fopen("code/generation/generated_data.asm", "w");
	emit_hex_data("vert_src", "code/shaders/screen.vert", out);
	emit_hex_data("frag_src", "code/shaders/screen.frag", out);
	fclose(out);
}
