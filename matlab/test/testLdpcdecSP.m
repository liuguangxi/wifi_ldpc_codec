% Performance test for LDPC decoder (SP algorithm).

% Copyright (c) 2019-2026 Guangxi Liu
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
Snr = 1.0:0.25:3.0;
MaxIter = 30;
EarlyExit = true;


VecLen = [648, 1296, 1944, 3888];
VecRate = [1/2, 2/3, 3/4, 5/6];
msgLen = round(VecLen(CwLen+1) * VecRate(Rate+1));
pcmB = ldpcPcmBase(CwLen, Rate);
pcmG = ldpcPcmGraph(CwLen, Rate);
H = getH(CwLen, Rate);
hDec = comm.LDPCDecoder(sparse(H), 'MaximumIterationCount', MaxIter,...
    'NumIterationsOutputPort', true);
if (EarlyExit)
    hDec.IterationTerminationCondition = 'Parity check satisfied';
end
hError = comm.ErrorRate;


fprintf('CwLen = %d\n', CwLen);
fprintf('Rate = %d\n', Rate);
fprintf('MaxIter = %d\n', MaxIter);
fprintf('EarlyExit = %d\n', EarlyExit);
fprintf('\n');

for snr = Snr
    varNoise = 10^(-snr/10);
    errorStats = zeros(3, 1);
    numTotalBlks = 0;
    numTotalIters = 0;

    while (errorStats(2) <= 1e4 && errorStats(3) <= 1e6)
        txBits = randi([0 1], msgLen, 1);
        encData = ldpcEncode(txBits, pcmB);
        modSig = 2 * encData - 1;
        rxSig = awgn(modSig, snr);
        demodSig = -2 * rxSig / varNoise;

        %[rxBits, numIter] = step(hDec, demodSig);    rxBits = double(rxBits);
        [rxBits, numIter] = ldpcDecodeSP(demodSig, pcmG, MaxIter, EarlyExit);

        numTotalBlks = numTotalBlks + 1;
        numTotalIters = numTotalIters + numIter;
        errorStats  = step(hError, txBits, rxBits);
    end

    avgIters = numTotalIters / numTotalBlks;
    fprintf('SNR (dB) = %.2f      BER = %.10f  (%d / %d)      AvgIters = %.2f\n', ...
        snr, errorStats(1), errorStats(2), errorStats(3), avgIters);
    reset(hError);
end


toc;
