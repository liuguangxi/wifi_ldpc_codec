% ldpcDecodeLOMSFx    LDPC decode LLR data with layered offset minimum-sum algorithm (fixed-point).
%
% Calling syntax:
%     [y, numIter] = ldpcDecodeLOMSFx(x, pcm, maxIter, os, earlyExit, cfgFx)
%
% Input:
%     x: demapped LLR data, column vector
%     pcm: struct for parity check matrix graph
%     maxIter: maximum number of decoding iterations
%     os: offset
%     earlyExit: whether decoding terminates after all parity checks are satisfied
%     cfgFx: configuration object for fixed-point
%
% Output:
%     y: decoded data, column vector
%     numIter: actual number of iterations performed

% Copyright (c) 2019-2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function [y, numIter] = ldpcDecodeLOMSFx(x, pcm, maxIter, os, earlyExit, cfgFx)

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


% Fixed-point parameters
FIN = cfgFx.F_IN;
WIN = cfgFx.W_IN;
WR = cfgFx.W_CHK;
WQ = cfgFx.W_VAR;


% Derive parameters
osInt = round(os * 2^FIN);
inMax = 2^(WIN-1)-1;
inMin = -inMax;
rMax = 2^(WR-1)-1;
rMin = -rMax;
qMax = 2^(WQ-1)-1;
qMin = -qMax;

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
xIn = max(min(round(x * 2^FIN), inMax), inMin);
vLQ = xIn;
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
        vLqAbsMin(:) = qMax;
        vLqAbsMin2(:) = qMax;

        for jj = 1:nb
            sh = tab(ii, jj);
            if (sh >= 0)
                for kk = 1:z
                    idx = (jj-1)*z + mod(kk-1+sh, z) + 1;
                    lq = vLQ(idx) - vLr(ii, idx);
                    lq = max(min(lq, qMax), qMin);
                    lqAbs = abs(lq);
                    if (lq < 0)
                        prodLqSgn(kk) = -prodLqSgn(kk);
                    end
                    if (lqAbs <= vLqAbsMin(kk))
                        vLqAbsMin2(kk) = vLqAbsMin(kk);
                        vLqAbsMin(kk) = lqAbs;
                        vLqAbsMinIdx(kk) = jj;
                    elseif (lqAbs <= vLqAbsMin2(kk))
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
                    lq = max(min(lq, qMax), qMin);
                    if (lq < 0)
                        lr = -prodLqSgn(kk);
                    else
                        lr = prodLqSgn(kk);
                    end
                    if (vLqAbsMinIdx(kk) == jj)
                        lr = lr * max(vLqAbsMin2(kk) - osInt, 0);
                    else
                        lr = lr * max(vLqAbsMin(kk) - osInt, 0);
                    end
                    vLr(ii, idx) = max(min(lr, rMax), rMin);
                    vLQ(idx) = max(min(lq + lr, qMax), qMin);
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
                sh = tab(ii, jj);
                if (sh >= 0)
                    vParity0 = mod(vParity0 + rotateVector(vLQHard((jj-1)*z+1 : jj*z), sh), 2);
                end
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



% rotateVector    Right rotate vector
%
% Calling syntax:
%     vo = rotateVector(vi, s)
%
% Input:
%     vi: input column vector
%     s: right rotate shift number, must be non-negative
%
% Output:
%     vo: rotated vector


function vo = rotateVector(vi, s)

vo = [vi(s+1:end); vi(1:s)];

end
