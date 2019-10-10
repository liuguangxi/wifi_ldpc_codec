% ldpcEncode    LDPC encode binary data.
%
% Calling syntax:
%     cw = ldpcEncode(msg, pcm)
%
% Input:
%     msg: message data bits, column vector
%     pcm: struct for parity check matrix base
%
% Output:
%     cw: codeword data bits, column vector

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function cw = ldpcEncode(msg, pcm)

% Check input arguments
if (~isnumeric(msg))
    error('Error: msg must be a numeric vector');
end


% Derive parameters
z = pcm.z;
tab = pcm.base;
[rb, nb] = size(tab);
kb = nb - rb;
msgDim = size(msg);
if (length(msgDim) ~= 2 || msgDim(1) ~= kb * z || msgDim(2) ~= 1)
    error('Error: invalid size of msg');
end


% Encode message bits
x = zeros(rb * z, 1);
p = zeros(rb * z, 1);

for ii = 1:rb
    for jj = 1:kb
        x((ii-1)*z+1 : ii*z) = mod(x((ii-1)*z+1 : ii*z) +...
            rotateVector(msg((jj-1)*z+1 : jj*z), tab(ii, jj)), 2);
    end
end

for ii = 1:rb
    p(1:z) = mod(p(1:z) + x((ii-1)*z+1 : ii*z), 2);
end
for ii = 1:rb-1
    if (ii == 1)
        p(ii*z+1 : (ii+1)*z) = mod(x((ii-1)*z+1 : ii*z) + rotateVector(p(1:z), 1), 2);
    elseif (ii == rb/2+1)
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
