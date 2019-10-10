% Test ldpcEncode, ldpcDecode and comm.LDPCDecoder

% clc;
clear;
tic;

addpath ../src


rng(0);
CwLen = 0;    % 0, 1, 2
Rate = 0;    % 0, 1, 2, 3
Snr = 1.0:0.25:3.0;
MaxIter = 30;
EarlyExit = true;


vecRate = [1/2, 2/3, 3/4, 5/6];
msgLen = round((CwLen+1)*648 * vecRate(Rate+1));
pcmB = ldpcPcmBase(CwLen, Rate);
pcmG = ldpcPcmGraph(CwLen, Rate);
H = getH(CwLen, Rate);
if (EarlyExit)
    hDec = comm.LDPCDecoder(sparse(H), 'MaximumIterationCount', MaxIter,...
        'IterationTerminationCondition', 'Parity check satisfied');
else
    hDec = comm.LDPCDecoder(sparse(H), 'MaximumIterationCount', MaxIter);
end
hError = comm.ErrorRate;


fprintf('CwLen = %d\nRate = %d\nMaxIter = %d\nEarlyExit = %d\n\n', ...
    CwLen, Rate, MaxIter, EarlyExit);

for snr = Snr
    varNoise = 10^(-snr/10);
    errorStats = zeros(3, 1);
    while (errorStats(2) <= 10000 && errorStats(3) <= 1000000)
        txBits = randi([0 1], msgLen, 1);
        encData = ldpcEncode(txBits, pcmB);
        modSig = 2 * encData - 1;
        rxSig = awgn(modSig, snr);
        demodSig = -2 * rxSig / varNoise;
        rxBits = ldpcDecodeSP(demodSig, pcmG, MaxIter, EarlyExit);
        %rxBits = double(step(hDec, demodSig));
        errorStats  = step(hError, txBits, rxBits);
    end
    
    fprintf('SNR (dB) = %.2f        BER = %.10f  (%d / %d)\n', ...
        snr, errorStats(1), errorStats(2), errorStats(3));
    reset(hError);
end


toc;
