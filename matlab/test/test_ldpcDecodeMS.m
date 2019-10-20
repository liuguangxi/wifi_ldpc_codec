% Test ldpcEncode, ldpcDecode*MS and comm.LDPCDecoder

% clc;
clear;
tic;

addpath ../src


rng(0);
CwLen = 2;    % 0, 1, 2
Rate = 0;    % 0, 1, 2, 3
Snr = 0.75:0.25:2.25;
MaxIter = 30;
MaxIterLayer = 15;
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
hErrorLNMS = comm.ErrorRate;
hErrorLOMS = comm.ErrorRate;


fprintf('CwLen = %d\n', CwLen);
fprintf('Rate = %d\n', Rate);
fprintf('MaxIter = %d\n', MaxIter);
fprintf('MaxIterLayer = %d\n', MaxIterLayer);
fprintf('ScalingFactor = %g\n', ScalingFactor);
fprintf('Offset = %g\n', Offset);
fprintf('EarlyExit = %d\n', EarlyExit);
fprintf('\n');

for snr = Snr
    varNoise = 10^(-snr/10);
    errorStatsSP = zeros(3, 1);
    numTotalBlks = 0;
    numTotalItersSP = 0;
    numTotalItersMS = 0;
    numTotalItersNMS = 0;
    numTotalItersOMS = 0;
    numTotalItersLNMS = 0;
    numTotalItersLOMS = 0;
    
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
        [rxBitsLNMS, numIterLNMS] = ldpcDecodeLNMS(demodSig, pcmB, MaxIterLayer, ScalingFactor, EarlyExit);
        [rxBitsLOMS, numIterLOMS] = ldpcDecodeLOMS(demodSig, pcmB, MaxIterLayer, Offset, EarlyExit);
        
        numTotalBlks = numTotalBlks + 1;
        numTotalItersSP = numTotalItersSP + numIterSP;
        numTotalItersMS = numTotalItersMS + numIterMS;
        numTotalItersNMS = numTotalItersNMS + numIterNMS;
        numTotalItersOMS = numTotalItersOMS + numIterOMS;
        numTotalItersLNMS = numTotalItersLNMS + numIterLNMS;
        numTotalItersLOMS = numTotalItersLOMS + numIterLOMS;
        errorStatsSP  = step(hErrorSP, txBits, rxBitsSP);
        errorStatsMS  = step(hErrorMS, txBits, rxBitsMS);
        errorStatsNMS  = step(hErrorNMS, txBits, rxBitsNMS);
        errorStatsOMS  = step(hErrorOMS, txBits, rxBitsOMS);
        errorStatsLNMS  = step(hErrorLNMS, txBits, rxBitsLNMS);
        errorStatsLOMS  = step(hErrorLOMS, txBits, rxBitsLOMS);
    end
    
    avgItersSP = numTotalItersSP / numTotalBlks;
    avgItersMS = numTotalItersMS / numTotalBlks;
    avgItersNMS = numTotalItersNMS / numTotalBlks;
    avgItersOMS = numTotalItersOMS / numTotalBlks;
    avgItersLNMS = numTotalItersLNMS / numTotalBlks;
    avgItersLOMS = numTotalItersLOMS / numTotalBlks;
    
    fprintf('SNR (dB) = %.2f\n', snr);
    fprintf('    BER (SP) = %.10f  (%d / %d)      AvgIters (SP) = %.2f\n', ...
        errorStatsSP(1), errorStatsSP(2), errorStatsSP(3), avgItersSP);
    fprintf('    BER (MS) = %.10f  (%d / %d)      AvgIters (MS) = %.2f\n', ...
        errorStatsMS(1), errorStatsMS(2), errorStatsMS(3), avgItersMS);
    fprintf('    BER (NMS) = %.10f  (%d / %d)      AvgIters (NMS) = %.2f\n', ...
        errorStatsNMS(1), errorStatsNMS(2), errorStatsNMS(3), avgItersNMS);
    fprintf('    BER (OMS) = %.10f  (%d / %d)      AvgIters (OMS) = %.2f\n', ...
        errorStatsOMS(1), errorStatsOMS(2), errorStatsOMS(3), avgItersOMS);
    fprintf('    BER (LNMS) = %.10f  (%d / %d)      AvgIters (LNMS) = %.2f\n', ...
        errorStatsLNMS(1), errorStatsLNMS(2), errorStatsLNMS(3), avgItersLNMS);
    fprintf('    BER (LOMS) = %.10f  (%d / %d)      AvgIters (LOMS) = %.2f\n', ...
        errorStatsLOMS(1), errorStatsLOMS(2), errorStatsLOMS(3), avgItersLOMS);
    fprintf('\n');
    
    reset(hErrorSP);
    reset(hErrorMS);
    reset(hErrorNMS);
    reset(hErrorOMS);
    reset(hErrorLNMS);
    reset(hErrorLOMS);
end


toc;
