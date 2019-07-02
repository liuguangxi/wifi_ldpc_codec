% Test ldpc_encode and wifiLdpcEncode

clc;    clear;

addpath ../src

blk_size = 648*3;
code_rate_enum = 3;
cwlen = blk_size / 648 - 1;
rate = code_rate_enum;

if (rate == 0)
    msg_size = round(blk_size * 1/2);
elseif (rate == 1)
    msg_size = round(blk_size * 2/3);
elseif (rate == 2)
    msg_size = round(blk_size * 3/4);
else
    msg_size = round(blk_size * 5/6);
end

msg = randi([0, 1], msg_size, 1);

cwRef = ldpc_encode(msg, blk_size, code_rate_enum);
cwImp = ldpcEncode(msg, cwlen, rate);

err = cwRef ~= cwImp;
if (any(err))
    disp('FAIL');
else
    disp('PASS');
end
