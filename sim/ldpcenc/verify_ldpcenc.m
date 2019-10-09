% Verify ldpcenc

clc;    clear;

addpath ../../matlab/src

msg = load('ldpcenc_in.txt');
cw = load('ldpcenc_out.txt');

cwlen = length(cw) / 648 - 1;
if (length(cw) / 2 == length(msg))
    rate = 0;
elseif (length(cw) * 2 / 3 == length(msg))
    rate = 1;
elseif (length(cw) * 3 / 4 == length(msg))
    rate = 2;    
elseif (length(cw) * 5 / 6 == length(msg))
    rate = 3;
else
    error('Invalid length of cw or msg');
end

pb = ldpcPcmBase(cwlen, rate);
cwRef = ldpcEncode(msg, pb);

err = cwRef ~= cw;
if (any(err))
    disp('FAIL');
else
    disp('PASS');
end
