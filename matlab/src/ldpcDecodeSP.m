% ldpcDecode    LDPC decode LLR data with sum-product algorithm.
%
% Calling syntax:
%     y = ldpcDecode(x, pcm, maxIter)
%
% Input:
%     x: demapped LLR data, column vector
%     pcm: struct for parity check matrix graph
%     maxIter: maximum number of decoding iterations
%
% Output:
%     y: decoded data, column vector

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function y = ldpcDecodeSP(x, pcm, maxIter)

% Check input arguments
if (~isnumeric(x))
    error('ERROR: msg must be a numeric vector');
end
if (~isnumeric(maxIter) || numel(maxIter) ~= 1 || maxIter <= 0)
    error('ERROR: maxIter must be a positive integer');
end


% Derive parameters
r = pcm.r;
n = pcm.n;
posChk = pcm.posChk;
posChkIdx = pcm.posChkIdx;
posVar = pcm.posVar;
posVarIdx = pcm.posVarIdx;
xDim = size(x);
if (length(xDim) ~= 2 || xDim(1) ~= n || xDim(2) ~= 1)
    error('ERROR: invalid size of x');
end


% Decode LLR data
vLq = zeros(r, n);
vLr = zeros(r, n);

for ii = 1:n
    for jj = posChkIdx(ii):posChkIdx(ii+1)-1
        vLq(posChk(jj), ii) = x(ii);
    end
end

for iter = 1:maxIter
    for jj = 1:r
        setVj = posVar(posVarIdx(jj):posVarIdx(jj+1)-1);
        lenVj = length(setVj);
        for ii = 1:lenVj
            vLrji = 1;
            for k = 1:lenVj
                if (k == ii)
                    continue;
                end
                vLrji = vLrji * tanh(vLq(jj, setVj(k)) / 2);
            end
            vLrji = max(min(vLrji, 0.999999999999), -0.999999999999);
            vLr(jj, setVj(ii)) = 2 * atanh(vLrji);
        end
    end
    
    for ii = 1:n
        setCi = posChk(posChkIdx(ii):posChkIdx(ii+1)-1);
        lenCi = length(setCi);
        for jj = 1:lenCi
            vLqij = x(ii);
            for k = 1:lenCi
                if (k == jj)
                    continue;
                end
                vLqij = vLqij + vLr(setCi(k), ii);
            end
            vLq(setCi(jj), ii) = vLqij;
        end
    end
end

y = x;
for ii = 1:n
    for jj = posChkIdx(ii):posChkIdx(ii+1)-1
        y(ii) = y(ii) + vLr(posChk(jj), ii);
    end
end
y = double(y(1:n-r) < 0);


end
