// This is free and unencumbered software released into the public domain.
// For more information, please refer to <https://unlicense.org>
// bbbbbr 2020

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#include "files.h"
#include "files_c_source.h"

#define MAX_STR_LEN     4096

char filename_in[MAX_STR_LEN] = {'\0'};
char filename_out[MAX_STR_LEN] = {'\0'};

uint8_t * p_buf_in  = NULL;
uint8_t * p_buf_out = NULL;

bool opt_verbose          = false;
bool opt_c_source_input   = false;
bool opt_c_source_output  = false;
char opt_c_source_output_varname[MAX_STR_LEN] = "var_name";

static void display_help(void);
static int handle_args(int argc, char * argv[]);
static int convert(void);
void cleanup(void);


static void bin2delta(uint8_t * p_buf_in, uint32_t buf_size_in) {
    uint8_t prev_byte;
    uint8_t delta_value;
    uint32_t c = 0;

    // Very first delta is always zero
    prev_byte = *p_buf_in;
    *p_buf_in++ = 0;
    c++; // Move to second byte in buffer

    // Convert buffer to delta-encoded
    while (c < buf_size_in) {

        // Calculate absolute value of difference between current and previous
        if (*p_buf_in > prev_byte)
            delta_value = *p_buf_in - prev_byte;
        else
            delta_value = prev_byte - *p_buf_in;

        // Save current byte in unaltered state
        prev_byte = *p_buf_in;
        // Update buffer
        *p_buf_in = delta_value;

        // Move to next byte
        c++;
        p_buf_in++;
    }

}



static void display_help(void) {
    fprintf(stdout,
       "gbcompress [options] infile outfile\n"
       "Use: compress a binary file and write it out.\n"
       "\n"
       "Options\n"
       "-h    : Show this help screen\n"
       "-v    : Verbose output\n"
       "--cin  : Read input as .c source format (8 bit char ONLY, uses first array found)\n"
       "--cout : Write output in .c / .h source format (8 bit char ONLY) \n"
       "--varname=<NAME> : specify variable name for c source output\n"
       "\n"
       "Example: \"gbcompress --cin binaryfile.c compressed.bin\"\n"
       "Example: \"gbcompress --cout compressedfile.bin decompressed.c\"\n"
       "\n"
       );
}


int handle_args(int argc, char * argv[]) {

    int i = 1; // start at first arg

    if( argc < 3 ) {
        display_help();
        return false;
    }

    // Start at first optional argument
    // Last two arguments *must* be input/output files
    for (i = 1; i < (argc - 2); i++ ) {

        if (argv[i][0] == '-') {
            if (strstr(argv[i], "-h") == argv[i]) {
                display_help();
                return false;  // Don't parse input when -h is used
            } else if (strstr(argv[i], "-v") == argv[i]) {
                opt_verbose = true;
            } else if (strstr(argv[i], "--cin") == argv[i]) {
                opt_c_source_input = true;
            } else if (strstr(argv[i], "--cout") == argv[i]) {
                opt_c_source_output = true;
            } else if (strstr(argv[i], "--varname=") == argv[i]) {
                snprintf(opt_c_source_output_varname, sizeof(opt_c_source_output_varname), "%s", argv[i] + 10);
            } else
                printf("c2bin: Warning: Ignoring unknown option %s\n", argv[i]);
        }
    }

    // Copy input and output filenames from last two arguments
    // if not preceded with option dash
    if (argv[i][0] != '-') {
        snprintf(filename_in, sizeof(filename_in), "%s", argv[i++]);

        if (argv[i][0] != '-') {
            snprintf(filename_out, sizeof(filename_out), "%s", argv[i++]);
            return true;
        }
    }


    return false;
}


void cleanup(void) {
    if (p_buf_in != NULL) {
        free(p_buf_in);
        p_buf_in = NULL;
    }
    if (p_buf_out != NULL) {
        free(p_buf_out);
        p_buf_out = NULL;
    }
}


static int convert() {

    uint32_t  buf_size_in = 0;
    uint32_t  buf_size_out = 0;
    uint32_t  out_len = 0;
    bool      result = false;

    if (opt_c_source_input)
        p_buf_in =  file_read_c_input_into_buffer(filename_in, &buf_size_in);
    else
        p_buf_in =  file_read_into_buffer(filename_in, &buf_size_in);

    if ((p_buf_in) && (buf_size_in > 0)) {

        bin2delta(p_buf_in, buf_size_in);

        if (opt_c_source_output) {
            c_source_set_sizes(buf_size_in, buf_size_in); // compressed, decompressed
            result = file_write_c_output_from_buffer(filename_out, p_buf_in, buf_size_in, opt_c_source_output_varname, true);
        }
        else
            result = file_write_from_buffer(filename_out, p_buf_in, buf_size_in);

        if (result) {
            if (opt_verbose)
                printf("Wrote: %d bytes\n", buf_size_in);
            return EXIT_SUCCESS;
        }
    }

    return EXIT_FAILURE;
}


int main( int argc, char *argv[] )  {

    // Exit with failure by default
    int ret = EXIT_FAILURE;

    // Register cleanup with exit handler
    atexit(cleanup);

    if (handle_args(argc, argv)) {

        ret = convert();
    }
    cleanup();

    return ret; // Exit with failure by default
}

