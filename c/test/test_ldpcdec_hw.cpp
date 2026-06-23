//==============================================================================
// test_ldpcdec_hw.cpp
//
// Performance test for LDPC decoder (SP/HW algorithm).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_encoder.h"
#include "ldpc_decoder.h"
#include "ldpc_decoder_hw.h"
#include <cstdlib>
#include <cmath>
#include <cstdio>
#include <random>

using namespace std;


// Internal functions
static vector<double> genVecSnr(double start, double step, int len);
static vector<int> quantizeLLR(const vector<double>& vIn, int fIn, int wIn);
static void perfAlgo();


// Main entry
int main()
{
    perfAlgo();

    return 0;
}


// Generate SNR vector
static vector<double> genVecSnr(double start, double step, int len)
{
    vector<double> v(len);
    for (int i = 0; i < len; i++)
        v[i] = start + i * step;
    return v;
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


// LDPC encoder & decoder performance test for SP/LNMS/LOMS/LNMSFx/LOMSFx
void perfAlgo()
{
    // Simulation parameters
    unsigned Seed = 0;
    int CwLen = 2;    // 0, 1, 2
    int Rate = 0;    // 0, 1, 2, 3
    double scSel = (Rate == 0) ? 1 : 0;
    int MaxIter = 16;    // >= 1
    int MaxIterLayer = 8;    // >= 1
    bool EarlyExit = true;
    double SnrStart = 1.0;
    double SnrStep = 0.25;
    int SnrLen = 9;
    HwConfig CfgHwLMS = {2, 6, 6, 8, 0, true};
    HwConfig CfgHwLNMS = {2, 6, 6, 8, 1, true};
    HwConfig CfgHwLOMS = {2, 6, 6, 8, 2, true};


    // Derived variables
    const int VecLen[] = {648, 1296, 1944};
    const double VecRate[] = {1/2., 2/3., 3/4., 5/6.};
    int dataLen = VecLen[CwLen];
    int msgLen = static_cast<int>(dataLen * VecRate[Rate] + 0.5);
    int cm = CwLen * 4 + Rate;
    const PcmBase& pb = Hldpc[cm];
    PcmBase pbHw = rowPermutePcmBase(pb, RPldpc[cm]);
    PcmGraph pg = getPcmGraph(cm);
    vector<double> VecSnr = genVecSnr(SnrStart, SnrStep, SnrLen);


    // Main simulation loop
    mt19937 eng(Seed);
    uniform_int_distribution<int> udist(0, 1);
    normal_distribution<double> ndist(0.0, 1.0);
    vector<int> txBits(msgLen);
    vector<int> encData;
    vector<double> modSig(dataLen);
    vector<double> rxSig(dataLen);
    vector<double> demodData(dataLen);
    vector<int> demodDataQ;
    vector<int> rxBitsSP;
    vector<int> rxBitsHwLMS;
    vector<int> rxBitsHwLNMS;
    vector<int> rxBitsHwLOMS;
    int numIterSP;
    int numIterHwLMS;
    int numIterHwLNMS;
    int numIterHwLOMS;
    bool pcHwLMS;
    bool pcHwLNMS;
    bool pcHwLOMS;

    printf("CwLen = %d\n", CwLen);
    printf("Rate = %d\n", Rate);
    printf("MaxIter = %d\n", MaxIter);
    printf("MaxIterLayer = %d\n", MaxIterLayer);
    printf("ScalingFactor = %g\n", (12 + scSel) / 16.);
    printf("Offset = %g\n", 0.5);
    printf("EarlyExit = %d\n", EarlyExit);
    printf("VecSnr = %.2f:%.2f:%.2f\n", SnrStart, SnrStep, VecSnr[SnrLen - 1]);
    printf("CfgHw = {F_IN:%d, W_IN:%d, W_CHK:%d, W_VAR:%d}\n",
        CfgHwLMS.F_IN, CfgHwLMS.W_IN, CfgHwLMS.W_CHK, CfgHwLMS.W_VAR);
    printf("\n");

    for (int iSnr = 0; iSnr < SnrLen; iSnr++) {
        double snr = VecSnr[iSnr];
        double varNoise = max(1e-10, pow(10.0, -snr/10));
        double ampNoise = sqrt(varNoise);
        double numTotalBits = 0;
        double numErrorBitsSP = 0;
        double numErrorBitsHwLMS = 0;
        double numErrorBitsHwLNMS = 0;
        double numErrorBitsHwLOMS = 0;
        double numTotalBlks = 0;
        double numTotalItersSP = 0;
        double numTotalItersHwLMS = 0;
        double numTotalItersHwLNMS = 0;
        double numTotalItersHwLOMS = 0;

        while (numErrorBitsSP <= 1e3 && numTotalBits <= 1e7) {
            for (int i = 0; i < msgLen; i++)
                txBits[i] = udist(eng);

            encData = ldpcEncodeCore(txBits, pb);

            for (int i = 0; i < dataLen; i++)
                modSig[i] = (encData[i] == 1) ? 1.0 : -1.0;

            for (int i = 0; i < dataLen; i++)
                rxSig[i] = modSig[i] + ampNoise * ndist(eng);

            for (int i = 0; i < dataLen; i++)
                demodData[i] = -2 * rxSig[i] / varNoise;

            demodDataQ = quantizeLLR(demodData, CfgHwLMS.F_IN, CfgHwLMS.W_IN);

            rxBitsSP = ldpcDecodeSPCore(demodData, pg, MaxIter, EarlyExit, numIterSP);
            numTotalItersSP += numIterSP;
            rxBitsHwLMS = ldpcDecodeHwCore(demodDataQ, pbHw, MaxIterLayer, scSel, EarlyExit, CfgHwLMS, numIterHwLMS, pcHwLMS);
            numTotalItersHwLMS += numIterHwLMS;
            rxBitsHwLNMS = ldpcDecodeHwCore(demodDataQ, pbHw, MaxIterLayer, scSel, EarlyExit, CfgHwLNMS, numIterHwLNMS, pcHwLNMS);
            numTotalItersHwLNMS += numIterHwLNMS;
            rxBitsHwLOMS = ldpcDecodeHwCore(demodDataQ, pbHw, MaxIterLayer, scSel, EarlyExit, CfgHwLOMS, numIterHwLOMS, pcHwLOMS);
            numTotalItersHwLOMS += numIterHwLOMS;

            numTotalBits += msgLen;
            for (int i = 0; i < msgLen; i++) {
                if (txBits[i] != rxBitsSP[i])
                    numErrorBitsSP++;
                if (txBits[i] != rxBitsHwLMS[i])
                    numErrorBitsHwLMS++;
                if (txBits[i] != rxBitsHwLNMS[i])
                    numErrorBitsHwLNMS++;
                if (txBits[i] != rxBitsHwLOMS[i])
                    numErrorBitsHwLOMS++;
            }
            numTotalBlks++;
        }

        double berSP = numErrorBitsSP / numTotalBits;
        double avgItersSP = numTotalItersSP / numTotalBlks;
        double berHwLMS = numErrorBitsHwLMS / numTotalBits;
        double avgItersHwLMS = numTotalItersHwLMS / numTotalBlks;
        double berHwLNMS = numErrorBitsHwLNMS / numTotalBits;
        double avgItersHwLNMS = numTotalItersHwLNMS / numTotalBlks;
        double berHwLOMS = numErrorBitsHwLOMS / numTotalBits;
        double avgItersHwLOMS = numTotalItersHwLOMS / numTotalBlks;

        printf("SNR (dB) = %.2f\n", snr);
        printf("    BER (SP) = %.10f  (%.0f / %.0f)      AvgIters (SP) = %.2f\n",
               berSP, numErrorBitsSP, numTotalBits, avgItersSP);
        printf("    BER (HW LMS) = %.10f  (%.0f / %.0f)      AvgIters (HW LMS) = %.2f\n",
               berHwLMS, numErrorBitsHwLMS, numTotalBits, avgItersHwLMS);
        printf("    BER (HW LNMS) = %.10f  (%.0f / %.0f)      AvgIters (HW LNMS) = %.2f\n",
               berHwLNMS, numErrorBitsHwLNMS, numTotalBits, avgItersHwLNMS);
        printf("    BER (HW LOMS) = %.10f  (%.0f / %.0f)      AvgIters (HW LOMS) = %.2f\n",
               berHwLOMS, numErrorBitsHwLOMS, numTotalBits, avgItersHwLOMS);
        printf("\n");
    }
}
