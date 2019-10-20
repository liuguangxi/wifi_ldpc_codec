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


#include "ldpc_decoder.h"
#include <cstdlib>
#include <cmath>
#include <iostream>
#include <utility>
#include <algorithm>

using namespace std;


//----------------------------------------------------------
// Parity check for LQ
//
// Input:
//     vLQ: post LLR data of code
//
// Return:
//     Parity check result, true: pass, false: fail
//----------------------------------------------------------
static bool parityCheck(const vector<double>& vLQ, const PcmGraph& pg)
{
    int nz = pg.rows.size();
    vector<int> vLQHard(pg.n);
    vector<int> vParity(pg.r);

    for (int i = 0; i < pg.n; i++)
        vLQHard[i] = (vLQ[i] < 0) ? 1 : 0;

    fill(vParity.begin(), vParity.end(), 0);
    for (int i = 0; i < nz; i++) {
        if (vLQHard[pg.cols[i]] == 1)
            vParity[pg.rows[i]] = 1 - vParity[pg.rows[i]];
    }

    for (int i = 0; i < pg.r; i++) {
        if (vParity[i] == 1)
            return false;
    }
    return true;
}


//----------------------------------------------------------
// Get parity check matrix graph
//
// Input:
//     idxHldpc: index of Hldpc
//
// Return:
//     Parity check matrix graph for Hldpc with index idxHldpc
//----------------------------------------------------------
PcmGraph getPcmGraph(int idxHldpc)
{
    const PcmBase& h = Hldpc[idxHldpc];
    int r = h.rb * h.z;
    int n = h.nb * h.z;
    PcmGraph pg;
    vector<pair<int, int>> vpos;
    int szvpos;

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
                vpos.push_back(make_pair(colk, rowk));
            }
        }
    }
    szvpos = vpos.size();

    sort(vpos.begin(), vpos.end());
    for (int i = 0; i < szvpos; i++) {
        pg.cols.push_back(vpos[i].first);
        pg.rows.push_back(vpos[i].second);
    }

    return pg;
}


//----------------------------------------------------------
// LDPC decoder core with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pg: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeSPCore(const vector<double>& dataIn,
                             const PcmGraph& pg, int maxIter, bool earlyExit,
                             int &numIter)
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

    int nz = pg.rows.size();
    vector<double> vLq(nz);
    vector<double> prodLq(pg.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pg.n);
    vector<int> vLQHard(pg.n);
    vector<int> vParity(pg.r);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pg.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            double lq = tanh(vLq[i] / 2.0);
            lq = (lq >= 0) ? max(1e-9, lq) : min(-1e-9, lq);
            vLq[i] = lq;
        }
        fill(prodLq.begin(), prodLq.end(), 1.0);
        for (int i = 0; i < nz; i++)
            prodLq[pg.rows[i]] *= vLq[i];
        for (int i = 0; i < nz; i++) {
            double lr = prodLq[pg.rows[i]] / vLq[i];
            lr = 2 * atanh(max(min(lr, 0.999999999999), -0.999999999999));
            vLr[i] = lr;
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pg.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pg.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pg.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pg))
                break;
        }
    }

    // Output hard decision of information bits
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
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeSP(const vector<double>& dataIn,
                         CodeMode mode, int maxIter, bool earlyExit,
                         int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pg = getPcmGraph(idxHldpc);
    return ldpcDecodeSPCore(dataIn, pg, maxIter, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pg: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeMSCore(const vector<double>& dataIn,
                             const PcmGraph& pg, int maxIter, bool earlyExit,
                             int &numIter)
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

    int nz = pg.rows.size();
    vector<double> vLq(nz);
    vector<int> vLqSgn(nz);
    vector<double> vLqAbs(nz);
    vector<int> prodLqSgn(pg.r);
    vector<double> vLqAbsMin(pg.r);
    vector<int> vLqAbsMinIdx(pg.r);
    vector<double> vLqAbsMin2(pg.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pg.n);
    vector<int> vLQHard(pg.n);
    vector<int> vParity(pg.r);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pg.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            vLqSgn[i] = (vLq[i] >= 0) ? 1 : -1;
            vLqAbs[i] = abs(vLq[i]);
        }
        fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
        fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
        fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);
        for (int i = 0; i < nz; i++) {
            int rowsi = pg.rows[i];
            prodLqSgn[rowsi] *= vLqSgn[i];
            if (vLqAbs[i] < vLqAbsMin[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbsMin[rowsi];
                vLqAbsMin[rowsi] = vLqAbs[i];
                vLqAbsMinIdx[rowsi] = i;
            } else if (vLqAbs[i] < vLqAbsMin2[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbs[i];
            }
        }
        for (int i = 0; i < nz; i++) {
            int rowsi = pg.rows[i];
            double lqAbsMin = (vLqAbsMinIdx[rowsi] == i) ?
                              vLqAbsMin2[rowsi] : vLqAbsMin[rowsi];
            vLr[i] = prodLqSgn[rowsi] * vLqSgn[i] * lqAbsMin;
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pg.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pg.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pg.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pg))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pg.n - pg.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeMS(const vector<double>& dataIn,
                         CodeMode mode, int maxIter, bool earlyExit,
                         int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pg = getPcmGraph(idxHldpc);
    return ldpcDecodeMSCore(dataIn, pg, maxIter, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with normalized minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pg: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeNMSCore(const vector<double>& dataIn,
                              const PcmGraph& pg, int maxIter,
                              double sc, bool earlyExit,
                              int &numIter)
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

    if (sc <= 0 || sc > 1) {
        cerr << "Error: Invalid input sc" << sc
             << ", should in range (0, 1]" << endl;
        exit(EXIT_FAILURE);
    }

    int nz = pg.rows.size();
    vector<double> vLq(nz);
    vector<int> vLqSgn(nz);
    vector<double> vLqAbs(nz);
    vector<int> prodLqSgn(pg.r);
    vector<double> vLqAbsMin(pg.r);
    vector<int> vLqAbsMinIdx(pg.r);
    vector<double> vLqAbsMin2(pg.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pg.n);
    vector<int> vLQHard(pg.n);
    vector<int> vParity(pg.r);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pg.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            vLqSgn[i] = (vLq[i] >= 0) ? 1 : -1;
            vLqAbs[i] = abs(vLq[i]);
        }
        fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
        fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
        fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);
        for (int i = 0; i < nz; i++) {
            int rowsi = pg.rows[i];
            prodLqSgn[rowsi] *= vLqSgn[i];
            if (vLqAbs[i] < vLqAbsMin[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbsMin[rowsi];
                vLqAbsMin[rowsi] = vLqAbs[i];
                vLqAbsMinIdx[rowsi] = i;
            } else if (vLqAbs[i] < vLqAbsMin2[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbs[i];
            }
        }
        for (int i = 0; i < nz; i++) {
            int rowsi = pg.rows[i];
            double lqAbsMin = (vLqAbsMinIdx[rowsi] == i) ?
                              vLqAbsMin2[rowsi] : vLqAbsMin[rowsi];
            vLr[i] = prodLqSgn[rowsi] * vLqSgn[i] * lqAbsMin * sc;
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pg.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pg.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pg.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pg))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pg.n - pg.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with normalized minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeNMS(const vector<double>& dataIn,
                          CodeMode mode, int maxIter,
                          double sc, bool earlyExit,
                          int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pg = getPcmGraph(idxHldpc);
    return ldpcDecodeNMSCore(dataIn, pg, maxIter, sc, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with offset minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pg: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     os: offset
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeOMSCore(const vector<double>& dataIn,
                              const PcmGraph& pg, int maxIter,
                              double os, bool earlyExit,
                              int &numIter)
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

    if (os < 0) {
        cerr << "Error: Invalid input os" << os
             << ", should be nonnegative" << endl;
        exit(EXIT_FAILURE);
    }

    int nz = pg.rows.size();
    vector<double> vLq(nz);
    vector<int> vLqSgn(nz);
    vector<double> vLqAbs(nz);
    vector<int> prodLqSgn(pg.r);
    vector<double> vLqAbsMin(pg.r);
    vector<int> vLqAbsMinIdx(pg.r);
    vector<double> vLqAbsMin2(pg.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pg.n);
    vector<int> vLQHard(pg.n);
    vector<int> vParity(pg.r);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pg.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            vLqSgn[i] = (vLq[i] >= 0) ? 1 : -1;
            vLqAbs[i] = abs(vLq[i]);
        }
        fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
        fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
        fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);
        for (int i = 0; i < nz; i++) {
            int rowsi = pg.rows[i];
            prodLqSgn[rowsi] *= vLqSgn[i];
            if (vLqAbs[i] < vLqAbsMin[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbsMin[rowsi];
                vLqAbsMin[rowsi] = vLqAbs[i];
                vLqAbsMinIdx[rowsi] = i;
            } else if (vLqAbs[i] < vLqAbsMin2[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbs[i];
            }
        }
        for (int i = 0; i < nz; i++) {
            int rowsi = pg.rows[i];
            double lqAbsMin = (vLqAbsMinIdx[rowsi] == i) ?
                              vLqAbsMin2[rowsi] : vLqAbsMin[rowsi];
            vLr[i] = prodLqSgn[rowsi] * vLqSgn[i] * max(lqAbsMin - os, 0.0);
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pg.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pg.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pg.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pg))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pg.n - pg.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with offset minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     os: offset
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeOMS(const vector<double>& dataIn,
                          CodeMode mode, int maxIter,
                          double os, bool earlyExit,
                          int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pg = getPcmGraph(idxHldpc);
    return ldpcDecodeOMSCore(dataIn, pg, maxIter, os, earlyExit, numIter);
}
