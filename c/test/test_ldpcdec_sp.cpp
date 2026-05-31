//==============================================================================
// test_ldpcdec_sp.cpp
//
// Performance test for LDPC decoder (SP algorithm).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_encoder.h"
#include "ldpc_decoder.h"
#include <cstdlib>
#include <cmath>
#include <cstdio>
#include <random>

using namespace std;


// internal functions
static void perfSP();


// Main entry
int main()
{
    perfSP();

    return 0;
}


// LDPC encoder & decoder performance test for SP
void perfSP()
{
    // Simulation parameters
    unsigned Seed = 0;
    int CwLen = 2;    // 0, 1, 2, 3
    int Rate = 0;    // 0, 1, 2, 3
    double VecSnr[] = {1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0};
    int MaxIter = 30;
    bool EarlyExit = true;


    // Derived variables
    const int VecLen[] = {648, 1296, 1944, 3888};
    const double VecRate[] = {1/2., 2/3., 3/4., 5/6.};
    int dataLen = VecLen[CwLen];
    int msgLen = static_cast<int>(dataLen * VecRate[Rate] + 0.5);
    int lenVecSnr = sizeof(VecSnr) / sizeof(double);
    int cm = CwLen * 4 + Rate;
    const PcmBase& pb = Hldpc[cm];
    PcmGraph pg = getPcmGraph(cm);


    // Main simulation loop
    mt19937 eng(Seed);
    uniform_int_distribution<int> udist(0, 1);
    normal_distribution<double> ndist(0.0, 1.0);
    vector<int> txBits(msgLen);
    vector<int> encData;
    vector<double> modSig(dataLen);
    vector<double> rxSig(dataLen);
    vector<double> demodData(dataLen);
    vector<int> rxBits;
    int numIter;

    printf("CwLen = %d\n", CwLen);
    printf("Rate = %d\n", Rate);
    printf("MaxIter = %d\n", MaxIter);
    printf("EarlyExit = %d\n", EarlyExit);
    printf("\n");

    for (int iSnr = 0; iSnr < lenVecSnr; iSnr++) {
        double snr = VecSnr[iSnr];
        double varNoise = max(1e-10, pow(10.0, -snr/10));
        double ampNoise = sqrt(varNoise);
        double numTotalBits = 0;
        double numErrorBits = 0;
        double numTotalBlks = 0;
        double numTotalIters = 0;

        while (numErrorBits <= 1e4 && numTotalBits <= 1e6) {
            for (int i = 0; i < msgLen; i++)
                txBits[i] = udist(eng);

            encData = (cm < 12) ? ldpcEncodeCore(txBits, pb) : ldpc2xEncodeCore(txBits, pb);

            for (int i = 0; i < dataLen; i++)
                modSig[i] = (encData[i] == 1) ? 1.0 : -1.0;

            for (int i = 0; i < dataLen; i++)
                rxSig[i] = modSig[i] + ampNoise * ndist(eng);

            for (int i = 0; i < dataLen; i++)
                demodData[i] = -2 * rxSig[i] / varNoise;

            rxBits = ldpcDecodeSPCore(demodData, pg, MaxIter, EarlyExit, numIter);
            numTotalIters += numIter;

            numTotalBits += msgLen;
            for (int i = 0; i < msgLen; i++) {
                if (txBits[i] != rxBits[i])
                    numErrorBits++;
            }
            numTotalBlks++;
        }

        double ber = numErrorBits / numTotalBits;
        double avgIters = numTotalIters / numTotalBlks;
        printf("SNR (dB) = %.2f      BER = %.10f  (%.0f / %.0f)      AvgIters = %.2f\n",
               snr, ber, numErrorBits, numTotalBits, avgIters);
    }
}
