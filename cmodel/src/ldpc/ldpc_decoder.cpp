//==============================================================================
// ldpc_decoder.cpp
//
// LDPC decoder implementation.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc/ldpc_decoder.h"
#include <cstdlib>
#include <cmath>
#include <iostream>
#include <utility>
#include <algorithm>

using namespace std;


//----------------------------------------------------------
// Get parity check matrix graph
//
// Input:
//     idxHldpc: index of Hldpc
//
// Return:
//     Parity check matrix graph for Hldpc with index idx
//----------------------------------------------------------
static PcmGraph getPcmGraph(int idxHldpc)
{
    const PcmBase& h = Hldpc[idxHldpc];
    int r = h.rb * h.z;
    int n = h.nb * h.z;
    PcmGraph pg;
    vector<pair<int, int>> vpos;
    int szvpos;
    int idx;

    pg.r = r;
    pg.n = n;

    for (int i = 0; i < h.rb; i++) {
        for (int j = 0; j < h.nb; j++) {
            int sh = h.base[i * h.nb + j];
            if (sh == -1)
                continue;
            for (int k = 0; k < h.z; k++) {
                int rowk = i * h.z + k;
                int colk = j * h.z + (k + sh) % h.z;
                vpos.push_back(make_pair(rowk, colk));
            }
        }
    }
    szvpos = vpos.size();

    sort(vpos.begin(), vpos.end());
    pg.posVarIdx.push_back(0);
    idx = 1;
    for (int i = 0; i < szvpos; i++) {
        pg.posVar.push_back(vpos[i].second);
        if (vpos[i].first == idx) {
            pg.posVarIdx.push_back(i);
            idx++;
        }
        swap(vpos[i].first, vpos[i].second);
    }
    pg.posVarIdx.push_back(szvpos);

    sort(vpos.begin(), vpos.end());
    pg.posChkIdx.push_back(0);
    idx = 1;
    for (int i = 0; i < szvpos; i++) {
        pg.posChk.push_back(vpos[i].second);
        if (vpos[i].first == idx) {
            pg.posChkIdx.push_back(i);
            idx++;
        }
    }
    pg.posChkIdx.push_back(szvpos);

    return pg;
}


//----------------------------------------------------------
// LDPC decoder core with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pg: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
static vector<int> ldpcDecodeSPCore(const vector<double>& dataIn,
                                    const PcmGraph& pg, int maxIter)
{
    if (dataIn.size() != static_cast<vector<int>::size_type>(pg.n)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << pg.n << endl;
        exit(EXIT_FAILURE);
    }

    if (maxIter <= 0) {
        cerr << "Error: Invalid input maxIter" << maxIter
             << ", should be positive integer" << endl;
        exit(EXIT_FAILURE);
    }

    vector<double> vLq(pg.r * pg.n);
    vector<double> vLr(pg.r * pg.n);

    for (int i = 0; i < pg.n; i++) {
        for (int j = pg.posChkIdx[i]; j < pg.posChkIdx[i+1]; j++)
            vLq[pg.posChk[j] * pg.n + i] = dataIn[i];
    }

    for (int iter = 1; iter <= maxIter; iter++) {
        for (int j = 0; j < pg.r; j++) {
            int lenVj = pg.posVarIdx[j+1] - pg.posVarIdx[j];
            double vLrji = 1.0;
            vector<double> vlq(lenVj);
            for (int i = 0; i < lenVj; i++) {
                double lq = tanh(vLq[j * pg.n + pg.posVar[pg.posVarIdx[j]+i]] / 2.0);
                lq = (lq >= 0) ? max(1e-9, lq) : min(-1e-9, lq);
                vlq[i] = lq;
                vLrji *= lq;
            }
            for (int i = 0; i < lenVj; i++) {
                int idx = j * pg.n + pg.posVar[pg.posVarIdx[j]+i];
                double lr = vLrji / vlq[i];
                lr = max(min(lr, 0.999999999999), -0.999999999999);
                vLr[idx] = 2 * atanh(lr);
            }
        }

        for (int i = 0; i < pg.n; i++) {
            int lenCi = pg.posChkIdx[i+1] - pg.posChkIdx[i];
            double vLqij = dataIn[i];
            for (int j = 0; j < lenCi; j++)
                vLqij += vLr[pg.posChk[pg.posChkIdx[i]+j] * pg.n + i];
            for (int j = 0; j < lenCi; j++) {
                int idx = pg.posChk[pg.posChkIdx[i]+j] * pg.n + i;
                vLq[idx] = vLqij - vLr[idx];
            }
        }
    }

    vector<double> vLQ(dataIn);
    for (int i = 0; i < pg.n; i++) {
        for (int j = pg.posChkIdx[i]; j < pg.posChkIdx[i+1]; j++)
            vLQ[i] += vLr[pg.posChk[j] * pg.n + i];
    }

    int szMsg = pg.n - pg.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeSP(const vector<double>& dataIn,
                         CodeMode mode, int maxIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pg = getPcmGraph(idxHldpc);
    return ldpcDecodeSPCore(dataIn, pg, maxIter);
}
