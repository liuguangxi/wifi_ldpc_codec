//==============================================================================
// gen_tc_ldpcdec.cpp
//
// Generate test case for LDPC decoder simulation.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_encoder.h"
#include "ldpc_decoder_hw.h"
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
int mode = 0;    // code mode, 0-11:fixed mode, 16:random modes of 0-11
int dataType = 2;    // data type, 0:all zeros, 1:all ones, 2:random
int msAlg = 1;    // min-sum algorithm type, 0:MS, 1:NMS, 2:OMS
bool hasPc = true;    // whether including parity check or not
double snr = 30.0;    // SNR (dB) for AWGN channel, range [-30.0, 60.0]
const char *outFileName = "tc_1.txt";    // output file name
unsigned seed = 0;    // seed for random number generator


// internal functions
void printUsage(const char *exec);
void parseCmd(char **argv);
vector<int> quantizeLLR(const vector<double>& vIn, int fIn, int wIn);
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
    cout << "    -m <mode>        Code mode, 0-15:fixed mode, 16:random modes of 0-11\n";
    cout << "    -t <datatype>    Data type, 0:all zeros, 1:all ones, 2:random\n";
    cout << "    -a <algo>        Min-sum algorithm type, 0:MS, 1:NMS, 2:OMS\n";
    cout << "    -p <pc>          Whether including parity check or not\n";
    cout << "    -r <snr>         SNR (dB) for AWGN channel, range [-30.0, 60.0]\n";
    cout << "    -o <filename>    Output file name\n";
    cout << "    -s <seed>        Seed for random number generator" << endl;
}


// Parse command line option
void parseCmd(char **argv)
{
    int option;
    struct optparse options;

    optparse_init(&options, argv);
    while ((option = optparse(&options, "hn:m:t:a:p:r:o:s:")) != -1) {
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
            if (mode < 0 || mode > 16 || (mode >= 12 && mode <= 15)) {
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
        case 'a':
            msAlg = atoi(options.optarg);
            if (msAlg < 0 || msAlg > 2) {
                cerr << "Error: Invalid algorithm type of -a " << msAlg << endl;
                exit(EXIT_FAILURE);
            }
            break;
        case 'p':
            hasPc = atoi(options.optarg);
            break;
        case 'r':
            snr = atof(options.optarg);
            if (snr < -30 || msAlg > 60) {
                cerr << "Error: Invalid value of -r " << snr << endl;
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
    cout << "MS_ALG = " << msAlg << endl;
    cout << "HAS_PC = " << hasPc << endl;
    cout << "snr = " << snr << endl;
    cout << "outFileName = " << outFileName << endl;
    cout << "seed = " << seed << endl;
}


// Quantize input LLR data
vector<int> quantizeLLR(const vector<double>& vIn, int fIn, int wIn)
{
    const int inSc = (1 << fIn);
    const int inMax = (1 << (wIn - 1)) - 1;
    const int inMin = -inMax;

    int n = vIn.size();
    vector<int> vOut(n);
    for (int i = 0; i < n; i++) {
        vOut[i] = max(min(static_cast<int>(vIn[i] * inSc + 0.5), inMax), inMin);
    }
    return vOut;
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

    const int MaxIter = 8;
    const bool EarlyTerm = true;
    const HwConfig CfgHw = {2, 6, 6, 8, msAlg, hasPc};

    mt19937 eng(seed);
    uniform_int_distribution<int> udistuint(0, 11);
    uniform_int_distribution<int> udist01(0, 1);
    normal_distribution<double> ndist(0.0, 1.0);
    int codemode;
    PcmBase pb;
    int scSel;
    vector<int> txBits;
    vector<int> encData;
    vector<double> modSig;
    vector<double> rxSig;
    vector<double> demodData;
    vector<int> demodDataQ;
    vector<int> rxBits;
    int numIter;
    bool pc;
    ofstream out(outFileName);
    int lenK, lenN;


    for (int n = 1; n <= num; n++) {
        codemode = (mode == 16) ? udistuint(eng) : mode;
        lenK = TabK[codemode];
        lenN = TabN[codemode];
        scSel = (msAlg == 1 && codemode % 4 == 0) ? 1 : 0;
        out << dec << "Case " << n << "\n" << codemode << "\n";
        out << MaxIter << "\n" << scSel << "\n" << EarlyTerm << "\n";

        txBits.assign(lenK, 0);
        for (int i = 0; i < lenK; i++) {
            txBits[i] = (dataType == 0) ? 0 : (dataType == 1) ? 1 : udist01(eng);
        }

        encData = ldpcEncode(txBits, static_cast<CodeMode>(codemode));

        modSig.assign(lenN, 0);
        for (int i = 0; i < lenN; i++)
            modSig[i] = (encData[i] == 1) ? 1.0 : -1.0;

        double varNoise = max(1e-10, pow(10.0, -snr/10));
        double ampNoise = sqrt(varNoise);
        rxSig.assign(lenN, 0);
        for (int i = 0; i < lenN; i++)
            rxSig[i] = modSig[i] + ampNoise * ndist(eng);

        demodData.assign(lenN, 0);
        for (int i = 0; i < lenN; i++)
            demodData[i] = -2 * rxSig[i] / varNoise;

        demodDataQ = quantizeLLR(demodData, CfgHw.F_IN, CfgHw.W_IN);

        int lenSegN = lenN / 27;
        for (int i = 0; i < lenSegN; i++) {
            for (int k = 0; k < 27; k++) {
                int llr = demodDataQ[27 * i + k];
                if (llr < 0)    llr += (1 << CfgHw.W_IN);
                out << hex << setw(2) << setfill('0') << llr;
                if (k < 26)    out << " ";
            }
            out << "\n";
        }

        pb = rowPermutePcmBase(Hldpc[codemode], RPldpc[codemode]);
        rxBits = ldpcDecodeHwCore(demodDataQ, pb, MaxIter, scSel, EarlyTerm, CfgHw, numIter, pc);

        out << dec << numIter << "\n" << pc << "\n";

        int lenSegK = lenK / 27;
        for (int i = 0; i < lenSegK; i++) {
            unsigned x = 0;
            for (int k = 0; k < 27; k++) {
                x |= (rxBits[27 * i + k] << k);
            }
            out << hex << setw(7) << setfill('0') << x << "\n";
        }

        out << endl;
    }
    out.close();

    cout << "Generate file '" << outFileName << "' done." << endl;
}
