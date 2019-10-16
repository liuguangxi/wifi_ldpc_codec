% Test ldpcEncode, ldpcDecodeMS and comm.LDPCDecoder

% clc;
clear;
tic;

addpath ../src


rng(0);
CwLen = 0;    % 0, 1, 2
Rate = 0;    % 0, 1, 2, 3
Snr = 1.0:0.25:3.0;
MaxIter = 30;
ScalingFactor = 0.75;    % (0, 1]
Offset = 0.5;    % >= 0
EarlyExit = true;


vecRate = [1/2, 2/3, 3/4, 5/6];
msgLen = round((CwLen+1)*648 * vecRate(Rate+1));
pcmB = ldpcPcmBase(CwLen, Rate);
pcmG = ldpcPcmGraph(CwLen, Rate);
H = getH(CwLen, Rate);
hDec = comm.LDPCDecoder(sparse(H), 'MaximumIterationCount', MaxIter,...
    'NumIterationsOutputPort', true);
if (EarlyExit)
    hDec.IterationTerminationCondition = 'Parity check satisfied';
end
hErrorSP = comm.ErrorRate;
hErrorMS = comm.ErrorRate;
hErrorNMS = comm.ErrorRate;
hErrorOMS = comm.ErrorRate;


fprintf('CwLen = %d\n', CwLen);
fprintf('Rate = %d\n', Rate);
fprintf('MaxIter = %d\n', MaxIter);
fprintf('ScalingFactor = %g\n', ScalingFactor);
fprintf('Offset = %g\n', Offset);
fprintf('EarlyExit = %d\n', EarlyExit);
fprintf('\n');

for snr = Snr
    varNoise = 10^(-snr/10);
    errorStatsSP = zeros(3, 1);
    errorStatsMS = zeros(3, 1);
    errorStatsNMS = zeros(3, 1);
    errorStatsOMS = zeros(3, 1);
    numTotalBlks = 0;
    numTotalItersSP = 0;
    numTotalItersMS = 0;
    numTotalItersNMS = 0;
    numTotalItersOMS = 0;
    
    while (errorStatsSP(2) <= 1e4 && errorStatsSP(3) <= 1e6)
        txBits = randi([0 1], msgLen, 1);
        encData = ldpcEncode(txBits, pcmB);
        modSig = 2 * encData - 1;
        rxSig = awgn(modSig, snr);
        demodSig = -2 * rxSig / varNoise;
        
        [rxBitsSP, numIterSP] = step(hDec, demodSig);    rxBitsSP = double(rxBitsSP);
        [rxBitsMS, numIterMS] = ldpcDecodeMS(demodSig, pcmG, MaxIter, EarlyExit);
        [rxBitsNMS, numIterNMS] = ldpcDecodeNMS(demodSig, pcmG, MaxIter, ScalingFactor, EarlyExit);
        [rxBitsOMS, numIterOMS] = ldpcDecodeOMS(demodSig, pcmG, MaxIter, Offset, EarlyExit);
        
        numTotalBlks = numTotalBlks + 1;
        numTotalItersSP = numTotalItersSP + numIterSP;
        numTotalItersMS = numTotalItersMS + numIterMS;
        numTotalItersNMS = numTotalItersNMS + numIterNMS;
        numTotalItersOMS = numTotalItersOMS + numIterOMS;
        errorStatsSP  = step(hErrorSP, txBits, rxBitsSP);
        errorStatsMS  = step(hErrorMS, txBits, rxBitsMS);
        errorStatsNMS  = step(hErrorNMS, txBits, rxBitsNMS);
        errorStatsOMS  = step(hErrorOMS, txBits, rxBitsOMS);
    end
    
    avgItersSP = numTotalItersSP / numTotalBlks;
    avgItersMS = numTotalItersMS / numTotalBlks;
    avgItersNMS = numTotalItersNMS / numTotalBlks;
    avgItersOMS = numTotalItersOMS / numTotalBlks;
    
    fprintf('SNR (dB) = %.2f\n', snr);
    fprintf('    BER (SP) = %.10f  (%d / %d)      AvgIters (SP) = %.2f\n', ...
        errorStatsSP(1), errorStatsSP(2), errorStatsSP(3), avgItersSP);
    fprintf('    BER (MS) = %.10f  (%d / %d)      AvgIters (MS) = %.2f\n', ...
        errorStatsMS(1), errorStatsMS(2), errorStatsMS(3), avgItersMS);
    fprintf('    BER (NMS) = %.10f  (%d / %d)      AvgIters (NMS) = %.2f\n', ...
        errorStatsNMS(1), errorStatsNMS(2), errorStatsNMS(3), avgItersNMS);
    fprintf('    BER (OMS) = %.10f  (%d / %d)      AvgIters (OMS) = %.2f\n', ...
        errorStatsOMS(1), errorStatsOMS(2), errorStatsOMS(3), avgItersOMS);
    fprintf('\n');
    
    reset(hErrorSP);
    reset(hErrorMS);
    reset(hErrorNMS);
    reset(hErrorOMS);
end


toc;
