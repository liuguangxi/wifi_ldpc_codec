//==============================================================================
// codeperf.cpp
//
// Performance for LDPC encoder & decoder.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc/ldpc_encoder.h"
#include "ldpc/ldpc_decoder.h"
#include <cstdlib>
#include <cmath>
#include <cstdio>
#include <random>

using namespace std;


// internal functions
void perf();


// Main entry
int main(int argc, char *argv[])
{
    perf();

    return 0;
}


// LDPC encoder & decoder performance test
void perf()
{
    // Simulation parameters
    unsigned Seed = 0;
    int CwLen = 0;    // 0, 1, 2
    int Rate = 0;    // 0, 1, 2, 3
    double VecSnr[] = {1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0};
    int MaxIter = 30;
    bool EarlyExit = true;


    // Derived variables
    int cm = CwLen * 4 + Rate;
    const double VecRate[] = {1/2., 2/3., 3/4., 5/6.};
    int dataLen = (CwLen + 1) * 648;
    int msgLen = static_cast<int>(dataLen * VecRate[Rate] + 0.5);
    int lenVecSnr = sizeof(VecSnr) / sizeof(double);
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

    printf("CwLen = %d\nRate = %d\nMaxIter = %d\nEarlyExit = %d\n\n",
           CwLen, Rate, MaxIter, EarlyExit);

    for (int iSnr = 0; iSnr < lenVecSnr; iSnr++) {
        double snr = VecSnr[iSnr];
        double varNoise = pow(10.0, -snr/10);
        double ampNoise = sqrt(varNoise);
        int numTotalBits = 0;
        int numErrorBits = 0;
        int numTotalBlks = 0;
        double numTotalIters = 0;

        while (numErrorBits <= 10000 && numTotalBits <= 1000000) {
            for (int i = 0; i < msgLen; i++)
                txBits[i] = udist(eng);

            encData = ldpcEncode(txBits, static_cast<CodeMode>(cm));

            for (int i = 0; i < dataLen; i++)
                modSig[i] = (encData[i] == 1) ? 1.0 : -1.0;

            for (int i = 0; i < dataLen; i++)
                rxSig[i] = modSig[i] + ampNoise * ndist(eng);

            for (int i = 0; i < dataLen; i++)
                demodData[i] = -2 * rxSig[i] / varNoise;

            rxBits = ldpcDecodeSP(demodData, static_cast<CodeMode>(cm), MaxIter,
                                  EarlyExit, numIter);
            numTotalIters += numIter;

            numTotalBits += msgLen;
            for (int i = 0; i < msgLen; i++) {
                if (txBits[i] != rxBits[i])
                    numErrorBits++;
            }
            numTotalBlks++;
        }

        double ber = (double)numErrorBits / numTotalBits;
        double avgIters = numTotalIters / numTotalBlks;
        printf("SNR (dB) = %.2f        BER = %.10f  (%d / %d)        AvgIters = %.2f\n",
               snr, ber, numErrorBits, numTotalBits, avgIters);
    }
}
