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


#include "ldpc_encoder.h"
#include "ldpc_decoder.h"
#include <cstdlib>
#include <cmath>
#include <cstdio>
#include <random>

using namespace std;


// internal functions
static void perfSP();
static void perfAlgo();


// Main entry
int main(int argc, char *argv[])
{
    //perfSP();
    perfAlgo();

    return 0;
}


// LDPC encoder & decoder performance test for SP
void perfSP()
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

            encData = ldpcEncodeCore(txBits, pb);

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


// LDPC encoder & decoder performance test for SP/MS/NMS/OMS
void perfAlgo()
{
    // Simulation parameters
    unsigned Seed = 0;
    int CwLen = 0;    // 0, 1, 2
    int Rate = 0;    // 0, 1, 2, 3
    double VecSnr[] = {1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0};
    double ScalingFactor = 0.75;    // (0, 1]
    double Offset = 0.5;    // >= 0
    int MaxIter = 30;    // >= 1
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
    vector<int> rxBitsSP;
    vector<int> rxBitsMS;
    vector<int> rxBitsNMS;
    vector<int> rxBitsOMS;
    int numIterSP;
    int numIterMS;
    int numIterNMS;
    int numIterOMS;

    printf("CwLen = %d\n", CwLen);
    printf("Rate = %d\n", Rate);
    printf("MaxIter = %d\n", MaxIter);
    printf("ScalingFactor = %g\n", ScalingFactor);
    printf("Offset = %g\n", Offset);
    printf("EarlyExit = %d\n", EarlyExit);
    printf("\n");

    for (int iSnr = 0; iSnr < lenVecSnr; iSnr++) {
        double snr = VecSnr[iSnr];
        double varNoise = max(1e-10, pow(10.0, -snr/10));
        double ampNoise = sqrt(varNoise);
        double numTotalBits = 0;
        double numErrorBitsSP = 0;
        double numErrorBitsMS = 0;
        double numErrorBitsNMS = 0;
        double numErrorBitsOMS = 0;
        double numTotalBlks = 0;
        double numTotalItersSP = 0;
        double numTotalItersMS = 0;
        double numTotalItersNMS = 0;
        double numTotalItersOMS = 0;

        while (numErrorBitsSP <= 1e4 && numTotalBits <= 1e6) {
            for (int i = 0; i < msgLen; i++)
                txBits[i] = udist(eng);

            encData = ldpcEncodeCore(txBits, pb);

            for (int i = 0; i < dataLen; i++)
                modSig[i] = (encData[i] == 1) ? 1.0 : -1.0;

            for (int i = 0; i < dataLen; i++)
                rxSig[i] = modSig[i] + ampNoise * ndist(eng);

            for (int i = 0; i < dataLen; i++)
                demodData[i] = -2 * rxSig[i] / varNoise;

            rxBitsSP = ldpcDecodeSPCore(demodData, pg, MaxIter, EarlyExit, numIterSP);
            numTotalItersSP += numIterSP;
            rxBitsMS = ldpcDecodeMSCore(demodData, pg, MaxIter, EarlyExit, numIterMS);
            numTotalItersMS += numIterMS;
            rxBitsNMS = ldpcDecodeNMSCore(demodData, pg, MaxIter, ScalingFactor, EarlyExit, numIterNMS);
            numTotalItersNMS += numIterNMS;
            rxBitsOMS = ldpcDecodeOMSCore(demodData, pg, MaxIter, Offset, EarlyExit, numIterOMS);
            numTotalItersOMS += numIterOMS;

            numTotalBits += msgLen;
            for (int i = 0; i < msgLen; i++) {
                if (txBits[i] != rxBitsSP[i])
                    numErrorBitsSP++;
                if (txBits[i] != rxBitsMS[i])
                    numErrorBitsMS++;
                if (txBits[i] != rxBitsNMS[i])
                    numErrorBitsNMS++;
                if (txBits[i] != rxBitsOMS[i])
                    numErrorBitsOMS++;
            }
            numTotalBlks++;
        }

        double berSP = numErrorBitsSP / numTotalBits;
        double avgItersSP = numTotalItersSP / numTotalBlks;
        double berMS = numErrorBitsMS / numTotalBits;
        double avgItersMS = numTotalItersMS / numTotalBlks;
        double berNMS = numErrorBitsNMS / numTotalBits;
        double avgItersNMS = numTotalItersNMS / numTotalBlks;
        double berOMS = numErrorBitsOMS / numTotalBits;
        double avgItersOMS = numTotalItersOMS / numTotalBlks;

        printf("SNR (dB) = %.2f\n", snr);
        printf("    BER (SP) = %.10f  (%.0f / %.0f)      AvgIters (SP) = %.2f\n",
               berSP, numErrorBitsSP, numTotalBits, avgItersSP);
        printf("    BER (MS) = %.10f  (%.0f / %.0f)      AvgIters (MS) = %.2f\n",
               berMS, numErrorBitsMS, numTotalBits, avgItersMS);
        printf("    BER (NMS) = %.10f  (%.0f / %.0f)      AvgIters (NMS) = %.2f\n",
               berNMS, numErrorBitsNMS, numTotalBits, avgItersNMS);
        printf("    BER (OMS) = %.10f  (%.0f / %.0f)      AvgIters (OMS) = %.2f\n",
               berOMS, numErrorBitsOMS, numTotalBits, avgItersOMS);
        printf("\n");
    }
}
