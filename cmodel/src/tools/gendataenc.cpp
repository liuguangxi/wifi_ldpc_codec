//==============================================================================
// gendataenc.cpp
//
// Generate test data for LDPC encoder.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc/ldpc_encoder.h"
#define OPTPARSE_IMPLEMENTATION
#define OPTPARSE_API static
#include "optparse.h"
#include <cstdlib>
#include <iostream>
#include <fstream>

using namespace std;


// Global variables
int num = 1;    // number of test cases, positive integer
int mode = 0;    // code mode, 0-11:CodeMode{C648R12-C1944R56}, 12:all modes
int dataType = 2;    // data type, 0:all zeros, 1:all ones, 2:random
const char *outFileName = "test_1.txt";    // output file name
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
    cout << "    -m <mode>        Code mode, \n";
    cout << "                     0-11:CodeMode{C648R12-C1944R56}, 12:all modes\n";
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
            if (mode < 0 || mode > 12) {
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
        972, 1296, 1458, 1620
    };
    static const int TabN[] = {
        648, 648, 648, 648,
        1296, 1296, 1296, 1296,
        1944, 1944, 1944, 1944
    };

    vector<int> msg;
    vector<int> cw;
    int codemode;
    ofstream out(outFileName);
    int lenK, lenN;

    srand(seed);
    for (int n = 0; n < num; n++) {
        codemode = (mode == 12) ? rand() % 12 : mode;
        lenK = TabK[codemode];
        lenN = TabN[codemode];
        out << codemode << " " << lenK << " " << lenN << endl;
        msg.assign(lenK, 0);
        for (int i = 0; i < lenK; i++) {
            if (dataType == 0)
                msg[i] = 0;
            else if (dataType == 1)
                msg[i] = 1;
            else
                msg[i] = rand() % 2;
        }
        cw = ldpcEncode(msg, static_cast<CodeMode>(codemode));
        for (int i = 0; i < lenN; i++)
            out << cw[i] << endl;
    }
    out.close();
}
