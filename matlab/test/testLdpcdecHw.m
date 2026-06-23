% Performance test for LDPC decoder (SP/HW algorithm).

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


% clc;
clear;
tic;

addpath ../src


rng(0);
CwLen = 2;    % 0, 1, 2
Rate = 0;    % 0, 1, 2, 3
MaxIter = 16;
MaxIterLayer = 8;
scSel = double(Rate == 0);
EarlyExit = true;
SnrStart = 1.0;
SnrStep = 0.25;
SnrLen = 9;

CfgHw.F_IN = 2;
CfgHw.W_IN = 6;
CfgHw.W_CHK = 6;
CfgHw.W_VAR = 8;
CfgHw.MS_ALG = 0;
CfgHw.HAS_PC = true;
CfgHwLMS = CfgHw; CfgHwLMS.MS_ALG = 0;
CfgHwLNMS = CfgHw; CfgHwLNMS.MS_ALG = 1;
CfgHwLOMS = CfgHw; CfgHwLOMS.MS_ALG = 2;


VecLen = [648, 1296, 1944];
VecRate = [1/2, 2/3, 3/4, 5/6];
msgLen = round(VecLen(CwLen+1) * VecRate(Rate+1));
pcmB = ldpcPcmBase(CwLen, Rate);
rp = ldpcPcmRowPerm(CwLen, Rate);
pcmBHw.z = pcmB.z;
pcmBHw.base = pcmB.base(rp, :);
H = getH(CwLen, Rate);
hDec = comm.LDPCDecoder(sparse(H), 'MaximumIterationCount', MaxIter,...
    'NumIterationsOutputPort', true);
if (EarlyExit)
    hDec.IterationTerminationCondition = 'Parity check satisfied';
end
hErrorSP = comm.ErrorRate;
hErrorHwLMS = comm.ErrorRate;
hErrorHwLNMS = comm.ErrorRate;
hErrorHwLOMS = comm.ErrorRate;
VecSnr = SnrStart + (0:SnrLen-1) * SnrStep;


fprintf('CwLen = %d\n', CwLen);
fprintf('Rate = %d\n', Rate);
fprintf('MaxIter = %d\n', MaxIter);
fprintf('MaxIterLayer = %d\n', MaxIterLayer);
fprintf('ScalingFactor = %g\n', (12 + scSel) / 16);
fprintf('Offset = %g\n', 0.5);
fprintf('EarlyExit = %d\n', EarlyExit);
fprintf('VecSnr = %.2f:%.2f:%.2f\n', SnrStart, SnrStep, VecSnr(end));
fprintf("CfgHw = {F_IN:%d, W_IN:%d, W_CHK:%d, W_VAR:%d}\n",...
    CfgHw.F_IN, CfgHw.W_IN, CfgHw.W_CHK, CfgHw.W_VAR);
fprintf('\n');

for snr = VecSnr
    varNoise = 10^(-snr/10);
    errorStatsSP = zeros(3, 1);
    numTotalBlks = 0;
    numTotalItersSP = 0;
    numTotalItersHwLMS = 0;
    numTotalItersHwLNMS = 0;
    numTotalItersHwLOMS = 0;

    while (errorStatsSP(2) <= 1e3 && errorStatsSP(3) <= 1e7)
        txBits = randi([0, 1], msgLen, 1);
        encData = ldpcEncode(txBits, pcmB);
        modSig = 2 * encData - 1;
        rxSig = awgn(modSig, snr);
        demodSig = -2 * rxSig / varNoise;

        [rxBitsSP, numIterSP] = step(hDec, demodSig);    rxBitsSP = double(rxBitsSP);
        [rxBitsHwLMS, numIterHwLMS, ~] = ldpcDecodeHw(demodSig, pcmBHw, MaxIterLayer, scSel, EarlyExit, CfgHwLMS);
        [rxBitsHwLNMS, numIterHwLNMS, ~] = ldpcDecodeHw(demodSig, pcmBHw, MaxIterLayer, scSel, EarlyExit, CfgHwLNMS);
        [rxBitsHwLOMS, numIterHwLOMS, ~] = ldpcDecodeHw(demodSig, pcmBHw, MaxIterLayer, scSel, EarlyExit, CfgHwLOMS);

        numTotalBlks = numTotalBlks + 1;
        numTotalItersSP = numTotalItersSP + numIterSP;
        numTotalItersHwLMS = numTotalItersHwLMS + numIterHwLMS;
        numTotalItersHwLNMS = numTotalItersHwLNMS + numIterHwLNMS;
        numTotalItersHwLOMS = numTotalItersHwLOMS + numIterHwLOMS;
        errorStatsSP = step(hErrorSP, txBits, rxBitsSP);
        errorStatsHwLMS = step(hErrorHwLMS, txBits, rxBitsHwLMS);
        errorStatsHwLNMS = step(hErrorHwLNMS, txBits, rxBitsHwLNMS);
        errorStatsHwLOMS = step(hErrorHwLOMS, txBits, rxBitsHwLOMS);
    end

    avgItersSP = numTotalItersSP / numTotalBlks;
    avgItersHwLMS = numTotalItersHwLMS / numTotalBlks;
    avgItersHwLNMS = numTotalItersHwLNMS / numTotalBlks;
    avgItersHwLOMS = numTotalItersHwLOMS / numTotalBlks;

    fprintf('SNR (dB) = %.2f\n', snr);
    fprintf('    BER (SP) = %.10f  (%d / %d)      AvgIters (SP) = %.2f\n', ...
        errorStatsSP(1), errorStatsSP(2), errorStatsSP(3), avgItersSP);
    fprintf('    BER (HW LMS) = %.10f  (%d / %d)      AvgIters (HW LMS) = %.2f\n', ...
        errorStatsHwLMS(1), errorStatsHwLMS(2), errorStatsHwLMS(3), avgItersHwLMS);
    fprintf('    BER (HW LNMS) = %.10f  (%d / %d)      AvgIters (HW LNMS) = %.2f\n', ...
        errorStatsHwLNMS(1), errorStatsHwLNMS(2), errorStatsHwLNMS(3), avgItersHwLNMS);
    fprintf('    BER (HW LOMS) = %.10f  (%d / %d)      AvgIters (HW LOMS) = %.2f\n', ...
        errorStatsHwLOMS(1), errorStatsHwLOMS(2), errorStatsHwLOMS(3), avgItersHwLOMS);
    fprintf('\n');

    reset(hErrorSP);
    reset(hErrorHwLMS);
    reset(hErrorHwLNMS);
    reset(hErrorHwLOMS);
end


toc;
