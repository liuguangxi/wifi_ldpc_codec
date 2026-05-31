//==============================================================================
// gen_tc_ldpcenc.cpp
//
// Generate test case for LDPC encoder simulation.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_encoder.h"
#define OPTPARSE_IMPLEMENTATION
#define OPTPARSE_API static
#include "optparse.h"
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <random>

using namespace std;


// Global variables
int num = 1;    // number of test cases, positive integer
int mode = 0;    // code mode, 0-11:CodeMode{C648R12-C1944R56}, 12:all modes
int dataType = 2;    // data type, 0:all zeros, 1:all ones, 2:random
const char *outFileName = "tc_1.txt";    // output file name
unsigned seed = 0;    // seed for random number generator


// internal functions
void printUsage(const char *exec);
void parseCmd(char **argv);
void genTestCase();


// Main entry
int main(int argc, char *argv[])
{
    parseCmd(argv);
    genTestCase();

    return 0;
}


// Print usage information
void printUsage(const char *exec)
{
    cout << "Usage: " << exec << " [options]\n";
    cout << "Options:\n";
    cout << "    -h               Print this message\n";
    cout << "    -n <num>         Number of test cases\n";
    cout << "    -m <mode>        Code mode, 0-15:fixed mode, 16:random modes of 0-11, 17: random modes of 0-15\n";
    cout << "    -t <datatype>    Data type, 0:all zeros, 1:all ones, 2:random\n";
    cout << "    -o <filename>    Output file name\n";
    cout << "    -s <seed>        Seed for random number generator" << endl;
}


// Parse command line option
void parseCmd(char **argv)
{
    int option;
    struct optparse options;

    optparse_init(&options, argv);
    while ((option = optparse(&options, "hn:m:t:o:s:")) != -1) {
        switch (option) {
        case 'h':
            printUsage(argv[0]);
            exit(EXIT_SUCCESS);
            break;
        case 'n':
            num = atoi(options.optarg);
            if (num < 1) {
                cerr << "Error: Invalid number of -n " << num << endl;
                exit(EXIT_FAILURE);
            }
            break;
        case 'm':
            mode = atoi(options.optarg);
            if (mode < 0 || mode > 17) {
                cerr << "Error: Invalid code mode of -m " << mode << endl;
                exit(EXIT_FAILURE);
            }
            break;
        case 't':
            dataType = atoi(options.optarg);
            if (dataType < 0 || dataType > 2) {
                cerr << "Error: Invalid data type of -t " << dataType << endl;
                exit(EXIT_FAILURE);
            }
            break;
        case 'o':
            outFileName = options.optarg;
            break;
        case 's':
            seed = atoi(options.optarg);
            break;
        case '?':
            cerr << argv[0] << ": " << options.errmsg << endl;
            exit(EXIT_FAILURE);
        }
    }

    cout << "num = " << num << endl;
    cout << "mode = " << mode << endl;
    cout << "dataType = " << dataType << endl;
    cout << "outFileName = " << outFileName << endl;
    cout << "seed = " << seed << endl;
}


// Generate test cases
void genTestCase()
{
    static const int TabK[] = {
        324, 432, 486, 540,
        648, 864, 972, 1080,
        972, 1296, 1458, 1620,
        1944, 2592, 2916, 3240
    };
    static const int TabN[] = {
        648, 648, 648, 648,
        1296, 1296, 1296, 1296,
        1944, 1944, 1944, 1944,
        3888, 3888, 3888, 3888
    };

    vector<int> msg;
    vector<int> cw;
    int codemode;
    ofstream out(outFileName);
    int lenK, lenSegN;
    mt19937 eng(seed);
    uniform_int_distribution<int> udist01(0, 1);
    uniform_int_distribution<int> udistuint(0, 47);

    for (int n = 1; n <= num; n++) {
        codemode = (mode == 16) ? udistuint(eng) % 12 : (mode == 17) ? udistuint(eng) % 16 : mode;
        lenK = TabK[codemode];
        lenSegN = TabN[codemode] / 27;
        out << "Case " << n << "\n" << codemode / 4 << "\n" << codemode % 4 << "\n";

        msg.assign(lenK, 0);
        for (int i = 0; i < lenK; i++) {
            msg[i] = (dataType == 0) ? 0 : (dataType == 1) ? 1 : udist01(eng);
        }

        cw = ldpcEncode(msg, static_cast<CodeMode>(codemode));
        for (int i = 0; i < lenSegN; i++) {
            unsigned x = 0;
            for (int k = 0; k < 27; k++) {
                x |= (cw[27 * i + k] << k);
            }
            stringstream ss;
            ss << hex << setw(7) << setfill('0') << x;
            out << ss.str() << "\n";
        }
        out << endl;
    }
    out.close();

    cout << "Generate file '" << outFileName << "' done." << endl;
}
