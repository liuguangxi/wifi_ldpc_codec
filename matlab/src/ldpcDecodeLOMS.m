% ldpcDecodeLOMS    LDPC decode LLR data with layered offset minimum-sum algorithm.
%
% Calling syntax:
%     [y, numIter] = ldpcDecodeLOMS(x, pcm, maxIter, os, earlyExit)
%
% Input:
%     x: demapped LLR data, column vector
%     pcm: struct for parity check matrix graph
%     maxIter: maximum number of decoding iterations
%     os: offset
%     earlyExit: whether decoding terminates after all parity checks are satisfied
%
% Output:
%     y: decoded data, column vector
%     numIter: actual number of iterations performed

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function [y, numIter] = ldpcDecodeLOMS(x, pcm, maxIter, os, earlyExit)

% Check input arguments
if (~isnumeric(x))
    error('Error: msg must be a numeric vector');
end
if (~isnumeric(maxIter) || numel(maxIter) ~= 1 || maxIter <= 0)
    error('Error: maxIter must be a positive integer');
end
if (os < 0)
    error('Error: os must be nonnegative');
end


% Derive parameters
z = pcm.z;
tab = pcm.base;
[rb, nb] = size(tab);
r = rb * z;
n = nb * z;
xDim = size(x);
if (length(xDim) ~= 2 || xDim(1) ~= n || xDim(2) ~= 1)
    error('Error: invalid size of x');
end


% Decode LLR data
% Initialize variable nodes
vLQ = x;
vLr = zeros(rb, n);
prodLqSgn = zeros(z, 1);
vLqAbsMin = zeros(z, 1);
vLqAbsMinIdx = zeros(z, 1);
vLqAbsMin2 = zeros(z, 1);

% Decode iteratively
numIter = 0;
for iter = 1:maxIter
    numIter = numIter + 1;

    for ii = 1:rb
        % Update check nodes and variable nodes values for each layer
        prodLqSgn(:) = 1;
        vLqAbsMin(:) = 1e12;
        vLqAbsMin2(:) = 1e12;

        for jj = 1:nb
            sh = tab(ii, jj);
            if (sh >= 0)
                for kk = 1:z
                    idx = (jj-1)*z + mod(kk-1+sh, z) + 1;
                    lq = vLQ(idx) - vLr(ii, idx);
                    lqAbs = abs(lq);
                    if (lq < 0)
                        prodLqSgn(kk) = -prodLqSgn(kk);
                    end
                    if (lqAbs < vLqAbsMin(kk))
                        vLqAbsMin2(kk) = vLqAbsMin(kk);
                        vLqAbsMin(kk) = lqAbs;
                        vLqAbsMinIdx(kk) = idx;
                    elseif (lqAbs < vLqAbsMin2(kk))
                        vLqAbsMin2(kk) = lqAbs;
                    end
                end
            end
        end

        for jj = 1:nb
            sh = tab(ii, jj);
            if (sh >= 0)
                for kk = 1:z
                    idx = (jj-1)*z + mod(kk-1+sh, z) + 1;
                    lq = vLQ(idx) - vLr(ii, idx);
                    if (lq < 0)
                        lr = -prodLqSgn(kk);
                    else
                        lr = prodLqSgn(kk);
                    end
                    if (vLqAbsMinIdx(kk) == idx)
                        lr = lr * max(vLqAbsMin2(kk) - os, 0);
                    else
                        lr = lr * max(vLqAbsMin(kk) - os, 0);
                    end
                    vLr(ii, idx) = lr;
                    vLQ(idx) = lq + lr;
                end
            end
        end
    end

    % Parity checks
    if (earlyExit)
        vLQHard = double(vLQ < 0);
        allZero = true;
        for ii = 1:rb
            vParity0 = zeros(z, 1);
            for jj = 1:nb
                vParity0 = mod(vParity0 + rotateVector(vLQHard((jj-1)*z+1 : jj*z), tab(ii, jj)), 2);
            end
            if (any(vParity0))
                allZero = false;
                break;
            end
        end
        if (allZero)
            break;
        end
    end
end

% Output hard decision of information bits
y = double(vLQ(1:n-r) < 0);


end



% rotateVector    right rotate vector
%
% Calling syntax:
%     vo = rotateVector(vi, s)
%
% Input:
%     vi: input column vector
%     s: right rotate shift number, negative number for zeros vector output
%
% Output:
%     vo: rotated vector


function vo = rotateVector(vi, s)

if (s < 0)
    vo = zeros(size(vi));
else
    vo = [vi(s+1:end); vi(1:s)];
end

end
