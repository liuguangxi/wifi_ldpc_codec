% ldpcEncode    LDPC encode binary data.
%
% Calling syntax:
%     cw = wifiLdpcEncode(msg, cwlen, rate)
%
% Input:
%     z: message data bits, column vector
%     cwlen: length of codeword, 0:648, 1:1296, 2:1944
%     rate: code rate, 0:1/2, 1:2/3, 2:3/4, 3:5/6
%
% Output:
%     cw: codeword data bits, column vector

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.

function cw = ldpcEncode(msg, cwlen, rate)

% Load LDPC matrices
if (~isnumeric(msg))
    error('ERROR: msg must be a numeric vector');
end

ldpcMatrix;

switch cwlen
    case 0
        switch rate
            case 0;    h = Hc648r12;
            case 1;    h = Hc648r23;
            case 2;    h = Hc648r34;
            case 3;    h = Hc648r56;
            otherwise; error('ERROR: invalid value of rate');
        end
    case 1
        switch rate
            case 0;    h = Hc1296r12;
            case 1;    h = Hc1296r23;
            case 2;    h = Hc1296r34;
            case 3;    h = Hc1296r56;
            otherwise; error('ERROR: invalid value of rate');
        end
    case 2
        switch rate
            case 0;    h = Hc1944r12;
            case 1;    h = Hc1944r23;
            case 2;    h = Hc1944r34;
            case 3;    h = Hc1944r56;
            otherwise; error('ERROR: invalid value of rate');
        end
    case 3
        switch rate
            case 0;    h = Hc648r12;
            case 1;    h = Hc648r23;
            case 2;    h = Hc648r34;
            case 3;    h = Hc648r56;
            otherwise; error('ERROR: invalid value of rate');
        end
    otherwise
        error('ERROR: invalid value of cwlen');
end


% Derive parameters
z = h.z;
tab = h.base;
[nkz, nz] = size(tab);
kz = nz - nkz;
msgDim = size(msg);
if (length(msgDim) ~= 2 || msgDim(1) ~= kz * z || msgDim(2) ~= 1)
    error('ERROR: invalid size of msg');
end


% Encode message bits
x = zeros(nkz * z, 1);
p = zeros(nkz * z, 1);

for ii = 1:nkz
    for jj = 1:kz
        x((ii-1)*z+1 : ii*z) = mod(x((ii-1)*z+1 : ii*z) +...
            rotateVector(msg((jj-1)*z+1 : jj*z), tab(ii, jj)), 2);
    end
end

for ii = 1:nkz
    p(1:z) = mod(p(1:z) + x((ii-1)*z+1 : ii*z), 2);
end
for ii = 1:nkz-1
    if (ii == 1)
        p(ii*z+1 : (ii+1)*z) = mod(x((ii-1)*z+1 : ii*z) + rotateVector(p(1:z), 1), 2);
    elseif (ii == nkz/2+1)
        p(ii*z+1 : (ii+1)*z) = mod(x((ii-1)*z+1 : ii*z) + p(1:z) + p((ii-1)*z+1 : ii*z), 2);
    else
        p(ii*z+1 : (ii+1)*z) = mod(x((ii-1)*z+1 : ii*z) + p((ii-1)*z+1 : ii*z), 2);
    end
end

cw = [msg; p];

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
