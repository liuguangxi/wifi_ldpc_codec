//==============================================================================
// test_ldpcdec_lms_fx.cpp
//
// Performance test for LDPC decoder (SP/LNMS/LOMS/LNMSFx/LOMSFx algorithm).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_encoder.h"
#include "ldpc_decoder.h"
#include "ldpc_decoder_fx.h"
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
    int CwLen = 2;    // 0, 1, 2, 3
    int Rate = 0;    // 0, 1, 2, 3
    double ScalingFactor = (Rate == 0) ? 0.8125 : 0.75;    // (0, 1]
    double Offset = 0.5;    // >= 0
    int MaxIter = 30;    // >= 1
    int MaxIterLayer = 15;    // >= 1
    bool EarlyExit = true;
    double SnrStart = 1.0;
    double SnrStep = 0.25;
    int SnrLen = 9;
    FxConfig CfgFx = {2, 6, 6, 8};
    int ScalingFactorInt = static_cast<int>(ScalingFactor * 16 + 0.5);
    int OffsetInt = static_cast<int>(Offset * (1 << CfgFx.F_IN) + 0.5);


    // Derived variables
    const int VecLen[] = {648, 1296, 1944, 3888};
    const double VecRate[] = {1/2., 2/3., 3/4., 5/6.};
    int dataLen = VecLen[CwLen];
    int msgLen = static_cast<int>(dataLen * VecRate[Rate] + 0.5);
    int cm = CwLen * 4 + Rate;
    const PcmBase& pb = Hldpc[cm];
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
    vector<int> rxBitsLNMS;
    vector<int> rxBitsLOMS;
    vector<int> rxBitsLNMSFx;
    vector<int> rxBitsLOMSFx;
    int numIterSP;
    int numIterLNMS;
    int numIterLOMS;
    int numIterLNMSFx;
    int numIterLOMSFx;

    printf("CwLen = %d\n", CwLen);
    printf("Rate = %d\n", Rate);
    printf("MaxIter = %d\n", MaxIter);
    printf("MaxIterLayer = %d\n", MaxIterLayer);
    printf("ScalingFactor = %g\n", ScalingFactor);
    printf("Offset = %g\n", Offset);
    printf("EarlyExit = %d\n", EarlyExit);
    printf("VecSnr = %.2f:%.2f:%.2f\n", SnrStart, SnrStep, VecSnr[SnrLen - 1]);
    printf("CfgFx = {F_IN:%d, W_IN:%d, W_CHK:%d, W_VAR:%d}\n",
        CfgFx.F_IN, CfgFx.W_IN, CfgFx.W_CHK, CfgFx.W_VAR);
    printf("\n");

    for (int iSnr = 0; iSnr < SnrLen; iSnr++) {
        double snr = VecSnr[iSnr];
        double varNoise = max(1e-10, pow(10.0, -snr/10));
        double ampNoise = sqrt(varNoise);
        double numTotalBits = 0;
        double numErrorBitsSP = 0;
        double numErrorBitsLNMS = 0;
        double numErrorBitsLOMS = 0;
        double numErrorBitsLNMSFx = 0;
        double numErrorBitsLOMSFx = 0;
        double numTotalBlks = 0;
        double numTotalItersSP = 0;
        double numTotalItersLNMS = 0;
        double numTotalItersLOMS = 0;
        double numTotalItersLNMSFx = 0;
        double numTotalItersLOMSFx = 0;

        while (numErrorBitsSP <= 1e3 && numTotalBits <= 1e7) {
            for (int i = 0; i < msgLen; i++)
                txBits[i] = udist(eng);

            encData = (cm < 12) ? ldpcEncodeCore(txBits, pb) : ldpc2xEncodeCore(txBits, pb);

            for (int i = 0; i < dataLen; i++)
                modSig[i] = (encData[i] == 1) ? 1.0 : -1.0;

            for (int i = 0; i < dataLen; i++)
                rxSig[i] = modSig[i] + ampNoise * ndist(eng);

            for (int i = 0; i < dataLen; i++)
                demodData[i] = -2 * rxSig[i] / varNoise;

            demodDataQ = quantizeLLR(demodData, CfgFx.F_IN, CfgFx.W_IN);

            rxBitsSP = ldpcDecodeSPCore(demodData, pg, MaxIter, EarlyExit, numIterSP);
            numTotalItersSP += numIterSP;
            rxBitsLNMS = ldpcDecodeLNMSCore(demodData, pb, MaxIterLayer, ScalingFactor, EarlyExit, numIterLNMS);
            numTotalItersLNMS += numIterLNMS;
            rxBitsLOMS = ldpcDecodeLOMSCore(demodData, pb, MaxIterLayer, Offset, EarlyExit, numIterLOMS);
            numTotalItersLOMS += numIterLOMS;
            rxBitsLNMSFx = ldpcDecodeLNMSFxCore(demodDataQ, pb, MaxIterLayer, ScalingFactorInt, EarlyExit, CfgFx, numIterLNMSFx);
            numTotalItersLNMSFx += numIterLNMSFx;
            rxBitsLOMSFx = ldpcDecodeLOMSFxCore(demodDataQ, pb, MaxIterLayer, OffsetInt, EarlyExit, CfgFx, numIterLOMSFx);
            numTotalItersLOMSFx += numIterLOMSFx;

            numTotalBits += msgLen;
            for (int i = 0; i < msgLen; i++) {
                if (txBits[i] != rxBitsSP[i])
                    numErrorBitsSP++;
                if (txBits[i] != rxBitsLNMS[i])
                    numErrorBitsLNMS++;
                if (txBits[i] != rxBitsLOMS[i])
                    numErrorBitsLOMS++;
                if (txBits[i] != rxBitsLNMSFx[i])
                    numErrorBitsLNMSFx++;
                if (txBits[i] != rxBitsLOMSFx[i])
                    numErrorBitsLOMSFx++;
            }
            numTotalBlks++;
        }

        double berSP = numErrorBitsSP / numTotalBits;
        double avgItersSP = numTotalItersSP / numTotalBlks;
        double berLNMS = numErrorBitsLNMS / numTotalBits;
        double avgItersLNMS = numTotalItersLNMS / numTotalBlks;
        double berLOMS = numErrorBitsLOMS / numTotalBits;
        double avgItersLOMS = numTotalItersLOMS / numTotalBlks;
        double berLNMSFx = numErrorBitsLNMSFx / numTotalBits;
        double avgItersLNMSFx = numTotalItersLNMSFx / numTotalBlks;
        double berLOMSFx = numErrorBitsLOMSFx / numTotalBits;
        double avgItersLOMSFx = numTotalItersLOMSFx / numTotalBlks;

        printf("SNR (dB) = %.2f\n", snr);
        printf("    BER (SP) = %.10f  (%.0f / %.0f)      AvgIters (SP) = %.2f\n",
               berSP, numErrorBitsSP, numTotalBits, avgItersSP);
        printf("    BER (LNMS) = %.10f  (%.0f / %.0f)      AvgIters (LNMS) = %.2f\n",
               berLNMS, numErrorBitsLNMS, numTotalBits, avgItersLNMS);
        printf("    BER (LOMS) = %.10f  (%.0f / %.0f)      AvgIters (LOMS) = %.2f\n",
               berLOMS, numErrorBitsLOMS, numTotalBits, avgItersLOMS);
        printf("    BER (LNMSFx) = %.10f  (%.0f / %.0f)      AvgIters (LNMSFx) = %.2f\n",
               berLNMSFx, numErrorBitsLNMSFx, numTotalBits, avgItersLNMSFx);
        printf("    BER (LOMSFx) = %.10f  (%.0f / %.0f)      AvgIters (LOMSFx) = %.2f\n",
               berLOMSFx, numErrorBitsLOMSFx, numTotalBits, avgItersLOMSFx);
        printf("\n");
    }
}
