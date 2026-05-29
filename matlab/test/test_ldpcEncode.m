% Test ldpcEncode and comm.LDPCEncoder

clc;    clear;

addpath ../src

rng(0);

VecLen = [648, 1296, 1944, 3888];
VecRate = [1/2, 2/3, 3/4, 5/6];
MaxCnt = 10;

for cwlen = 0:3
    for rate = 0:3
        msgLen = round(VecLen(cwlen+1) * VecRate(rate+1));
        pcmB = ldpcPcmBase(cwlen, rate);
        H = getH(cwlen, rate);
        hEnc = comm.LDPCEncoder(sparse(H));

        for iter = 1:10
            txBits = randi([0 1], msgLen, 1);
            encData = ldpcEncode(txBits, pcmB);
            encDataRef = step(hEnc, txBits);

            ok = isequal(encData, encDataRef);
            fprintf('cwlen = %d, rate = %d: ', cwlen, rate);
            if (ok)
                fprintf('PASS\n');
            else
                fprintf('FAIL\n');
            end
        end
    end
end
