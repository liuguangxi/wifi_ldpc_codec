% Performance test for LDPC decoder (SP/LNMS/LOMS/LNMSFx/LOMSFx algorithm).

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


% clc;
clear;
tic;

addpath ../src


rng(0);
CwLen = 2;    % 0, 1, 2, 3
Rate = 0;    % 0, 1, 2, 3
MaxIter = 30;
MaxIterLayer = 15;
if (Rate == 0)
    ScalingFactor = 13/16;    % (0, 1]
else
    ScalingFactor = 3/4;    % (0, 1]
end
Offset = 0.5;    % >= 0
EarlyExit = true;
SnrStart = 1.0;
SnrStep = 0.25;
SnrLen = 9;

CfgFx.F_IN = 2;
CfgFx.W_IN = 6;
CfgFx.W_CHK = 6;
CfgFx.W_VAR = 8;


VecLen = [648, 1296, 1944, 3888];
VecRate = [1/2, 2/3, 3/4, 5/6];
msgLen = round(VecLen(CwLen+1) * VecRate(Rate+1));
pcmB = ldpcPcmBase(CwLen, Rate);
H = getH(CwLen, Rate);
hDec = comm.LDPCDecoder(sparse(H), 'MaximumIterationCount', MaxIter,...
    'NumIterationsOutputPort', true);
if (EarlyExit)
    hDec.IterationTerminationCondition = 'Parity check satisfied';
end
hErrorSP = comm.ErrorRate;
hErrorLNMS = comm.ErrorRate;
hErrorLOMS = comm.ErrorRate;
hErrorLNMSFx = comm.ErrorRate;
hErrorLOMSFx = comm.ErrorRate;
VecSnr = SnrStart + (0:SnrLen-1) * SnrStep;


fprintf('CwLen = %d\n', CwLen);
fprintf('Rate = %d\n', Rate);
fprintf('MaxIter = %d\n', MaxIter);
fprintf('MaxIterLayer = %d\n', MaxIterLayer);
fprintf('ScalingFactor = %g\n', ScalingFactor);
fprintf('Offset = %g\n', Offset);
fprintf('EarlyExit = %d\n', EarlyExit);
fprintf('VecSnr = %.2f:%.2f:%.2f\n', SnrStart, SnrStep, VecSnr(end));
fprintf("CfgFx = {F_IN:%d, W_IN:%d, W_CHK:%d, W_VAR:%d}\n",...
    CfgFx.F_IN, CfgFx.W_IN, CfgFx.W_CHK, CfgFx.W_VAR);
fprintf('\n');

for snr = VecSnr
    varNoise = 10^(-snr/10);
    errorStatsSP = zeros(3, 1);
    numTotalBlks = 0;
    numTotalItersSP = 0;
    numTotalItersLNMS = 0;
    numTotalItersLOMS = 0;
    numTotalItersLNMSFx = 0;
    numTotalItersLOMSFx = 0;

    while (errorStatsSP(2) <= 1e3 && errorStatsSP(3) <= 1e7)
        txBits = randi([0, 1], msgLen, 1);
        encData = ldpcEncode(txBits, pcmB);
        modSig = 2 * encData - 1;
        rxSig = awgn(modSig, snr);
        demodSig = -2 * rxSig / varNoise;

        [rxBitsSP, numIterSP] = step(hDec, demodSig);    rxBitsSP = double(rxBitsSP);
        [rxBitsLNMS, numIterLNMS] = ldpcDecodeLNMS(demodSig, pcmB, MaxIterLayer, ScalingFactor, EarlyExit);
        [rxBitsLOMS, numIterLOMS] = ldpcDecodeLOMS(demodSig, pcmB, MaxIterLayer, Offset, EarlyExit);
        [rxBitsLNMSFx, numIterLNMSFx] = ldpcDecodeLNMSFx(demodSig, pcmB, MaxIterLayer, ScalingFactor, EarlyExit, CfgFx);
        [rxBitsLOMSFx, numIterLOMSFx] = ldpcDecodeLOMSFx(demodSig, pcmB, MaxIterLayer, Offset, EarlyExit, CfgFx);

        numTotalBlks = numTotalBlks + 1;
        numTotalItersSP = numTotalItersSP + numIterSP;
        numTotalItersLNMS = numTotalItersLNMS + numIterLNMS;
        numTotalItersLOMS = numTotalItersLOMS + numIterLOMS;
        numTotalItersLNMSFx = numTotalItersLNMSFx + numIterLNMSFx;
        numTotalItersLOMSFx = numTotalItersLOMSFx + numIterLOMSFx;
        errorStatsSP = step(hErrorSP, txBits, rxBitsSP);
        errorStatsLNMS = step(hErrorLNMS, txBits, rxBitsLNMS);
        errorStatsLOMS = step(hErrorLOMS, txBits, rxBitsLOMS);
        errorStatsLNMSFx = step(hErrorLNMSFx, txBits, rxBitsLNMSFx);
        errorStatsLOMSFx = step(hErrorLOMSFx, txBits, rxBitsLOMSFx);
    end

    avgItersSP = numTotalItersSP / numTotalBlks;
    avgItersLNMS = numTotalItersLNMS / numTotalBlks;
    avgItersLOMS = numTotalItersLOMS / numTotalBlks;
    avgItersLNMSFx = numTotalItersLNMSFx / numTotalBlks;
    avgItersLOMSFx = numTotalItersLOMSFx / numTotalBlks;

    fprintf('SNR (dB) = %.2f\n', snr);
    fprintf('    BER (SP) = %.10f  (%d / %d)      AvgIters (SP) = %.2f\n', ...
        errorStatsSP(1), errorStatsSP(2), errorStatsSP(3), avgItersSP);
    fprintf('    BER (LNMS) = %.10f  (%d / %d)      AvgIters (LNMS) = %.2f\n', ...
        errorStatsLNMS(1), errorStatsLNMS(2), errorStatsLNMS(3), avgItersLNMS);
    fprintf('    BER (LOMS) = %.10f  (%d / %d)      AvgIters (LOMS) = %.2f\n', ...
        errorStatsLOMS(1), errorStatsLOMS(2), errorStatsLOMS(3), avgItersLOMS);
    fprintf('    BER (LNMSFx) = %.10f  (%d / %d)      AvgIters (LNMSFx) = %.2f\n', ...
        errorStatsLNMSFx(1), errorStatsLNMSFx(2), errorStatsLNMSFx(3), avgItersLNMSFx);
    fprintf('    BER (LOMSFx) = %.10f  (%d / %d)      AvgIters (LOMSFx) = %.2f\n', ...
        errorStatsLOMSFx(1), errorStatsLOMSFx(2), errorStatsLOMSFx(3), avgItersLOMSFx);
    fprintf('\n');

    reset(hErrorSP);
    reset(hErrorLNMS);
    reset(hErrorLOMS);
    reset(hErrorLNMSFx);
    reset(hErrorLOMSFx);
end


toc;
