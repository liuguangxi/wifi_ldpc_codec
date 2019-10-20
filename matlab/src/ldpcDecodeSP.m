% ldpcDecodeSP    LDPC decode LLR data with sum-product algorithm.
%
% Calling syntax:
%     [y, numIter] = ldpcDecodeSP(x, pcm, maxIter, earlyExit)
%
% Input:
%     x: demapped LLR data, column vector
%     pcm: struct for parity check matrix graph
%     maxIter: maximum number of decoding iterations
%     earlyExit: whether decoding terminates after all parity checks are satisfied
%
% Output:
%     y: decoded data, column vector
%     numIter: actual number of iterations performed

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function [y, numIter] = ldpcDecodeSP(x, pcm, maxIter, earlyExit)

% Check input arguments
if (~isnumeric(x))
    error('Error: msg must be a numeric vector');
end
if (~isnumeric(maxIter) || numel(maxIter) ~= 1 || maxIter <= 0)
    error('Error: maxIter must be a positive integer');
end


% Derive parameters
r = pcm.r;
n = pcm.n;
rows = pcm.rows;
cols = pcm.cols;
nz = length(rows);
xDim = size(x);
if (length(xDim) ~= 2 || xDim(1) ~= n || xDim(2) ~= 1)
    error('Error: invalid size of x');
end


% Decode LLR data
% Initialize variable nodes
vLq = x(cols);

% Decode iteratively
numIter = 0;
for iter = 1:maxIter
    numIter = numIter + 1;
    
    % Calculate check nodes values from variable node values
    vLq = tanh(vLq/2);
    vLq = (2*(vLq >= 0)-1) .* max(abs(vLq), 1e-9);
    prodLq = ones(r, 1);
    for nn = 1:nz
        prodLq(rows(nn)) = prodLq(rows(nn)) * vLq(nn);
    end
    vLr = 2 * atanh(max(min(prodLq(rows)./vLq, 0.999999999999), -0.999999999999));
    
    % Calculate variable nodes values from check node values
    vLQ = x;
    for nn = 1:nz
        vLQ(cols(nn)) = vLQ(cols(nn)) + vLr(nn);
    end
    vLq = vLQ(cols) - vLr;
    
    % Parity checks
    if (earlyExit)
        vLQHard = double(vLQ < 0);
        vParity = zeros(r, 1);
        for nn = 1:nz
            if (vLQHard(cols(nn)))
                vParity(rows(nn)) = 1 - vParity(rows(nn));
            end
        end
        
        if (~any(vParity))
            break;
        end
    end
end

% Output hard decision of information bits
y = double(vLQ(1:n-r) < 0);


end
