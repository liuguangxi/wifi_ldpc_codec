% Verify ldpcenc

clc;    clear;

addpath ../../../../matlab/src

cwlen = 2;
rate = 3;

msg = load('ldpcenc_in.txt');
cwRtl = load('ldpcenc_out.txt');

cwRef = ldpcEncode(msg, cwlen, rate);

err = cwRef ~= cwRtl;
if (any(err))
    disp('FAIL');
else
    disp('PASS');
end
