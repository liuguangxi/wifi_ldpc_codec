% Verify test data by gendataenc

function verify_gendataenc(filename)

addpath ../../matlab/src

fid = fopen(filename, 'r');
d = fscanf(fid, '%d');
fclose(fid);
lend = length(d);

k = 1; nBlk = 0; nPass = 0;
while k <= lend
    codemode = d(k);    
    msgLen = d(k + 1);
    cwLen = d(k + 2);
    rate = mod(codemode, 4);
    cwlen = floor(codemode/4);
    k = k + 3;
    msg = d(k:k+msgLen-1);
    cw = d(k:k+cwLen-1);
    cwRef = ldpcEncode(msg, cwlen, rate);
    err = cwRef ~= cw;
    nBlk = nBlk + 1;
    fprintf('#%d    ', nBlk);
    if (any(err))
        disp('Fail');
    else
        nPass = nPass + 1;
        disp('Pass');
    end
    k = k + cwLen;
end
if (nPass == nBlk)
    fprintf('PASS (pass %d / total %d)\n', nPass, nBlk);
else
    fprintf('FAIL (pass %d / total %d)\n', nPass, nBlk);
end
