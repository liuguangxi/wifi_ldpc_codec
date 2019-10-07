% Test ldpcEncode and comm.LDPCEncoder

clc;    clear;

addpath ../src

rng(0);

vecRate = [1/2, 2/3, 3/4, 5/6];

for CwLen = 0:2
    for Rate = 0:3
        msgLen = round((CwLen+1)*648 * vecRate(Rate+1));
        pcmB = ldpcPcmBase(CwLen, Rate);
        H = getH(CwLen, Rate);
        hEnc = comm.LDPCEncoder(sparse(H));
        
        txBits = randi([0 1], msgLen, 1);
        encData = ldpcEncode(txBits, pcmB);
        encDataRef = step(hEnc, txBits);
        
        err = (encData ~= encDataRef);
        fprintf('CwLen = %d, Rate = %d: ', CwLen, Rate);
        if (any(err))
            fprintf('FAIL\n');
        else
            fprintf('PASS\n');
        end
    end
end
