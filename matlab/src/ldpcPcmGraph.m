% ldpcPcmGraph    LDPC parity check matrix graph (variable node <-> check node).
%
% Calling syntax:
%     pcm = ldpcPcmGraph(cwlen, rate)
%
% Input:
%     cwlen: length of codeword, 0:648, 1:1296, 2:1944
%     rate: code rate, 0:1/2, 1:2/3, 2:3/4, 3:5/6
%
% Output:
%     pcm: struct for parity check matrix graph

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function pcm = ldpcPcmGraph(cwlen, rate)

% Load LDPC matrices
ldpcMatrix;

switch cwlen
    case 0
        switch rate
            case 0;    pcmBase = Hn648cr12;
            case 1;    pcmBase = Hn648cr23;
            case 2;    pcmBase = Hn648cr34;
            case 3;    pcmBase = Hn648cr56;
            otherwise; error('ERROR: invalid value of rate');
        end
    case 1
        switch rate
            case 0;    pcmBase = Hn1296cr12;
            case 1;    pcmBase = Hn1296cr23;
            case 2;    pcmBase = Hn1296cr34;
            case 3;    pcmBase = Hn1296cr56;
            otherwise; error('ERROR: invalid value of rate');
        end
    case 2
        switch rate
            case 0;    pcmBase = Hn1944cr12;
            case 1;    pcmBase = Hn1944cr23;
            case 2;    pcmBase = Hn1944cr34;
            case 3;    pcmBase = Hn1944cr56;
            otherwise; error('ERROR: invalid value of rate');
        end
    otherwise
        error('ERROR: invalid value of cwlen');
end


% Calculate graph
z = pcmBase.z;
tab = pcmBase.base;
[rb, nb] = size(tab);
r = rb*z;
n = nb*z;

H = zeros(r, n);
for ii = 1:rb
    for jj = 1:nb
        H((ii-1)*z+1:ii*z, (jj-1)*z+1:jj*z) = cycPerm(z, tab(ii,jj));
    end
end

[rows, cols] = find(H);
szH = length(rows);
rcSort = sortrows([rows cols]);
rows2 = rcSort(:, 1);
cols2 = rcSort(:, 2);

posChk = rows;
posChkIdx = zeros(n+1, 1);
posChkIdx(1) = 1;
posChkIdx(n+1) = szH + 1;
idx = 2;
for k = 1:szH
    if (cols(k) == idx)
        posChkIdx(idx) = k;
        idx = idx + 1;
    end
end

posVar = cols2;
posVarIdx = zeros(r+1, 1);
posVarIdx(1) = 1;
posVarIdx(r+1) = szH + 1;
idx = 2;
for k = 1:szH
    if (rows2(k) == idx)
        posVarIdx(idx) = k;
        idx = idx + 1;
    end
end

pcm = struct('r', r, 'n', n, ...
    'posChk', posChk, 'posChkIdx', posChkIdx, ...
    'posVar', posVar, 'posVarIdx', posVarIdx);

end



% cycPerm    generate cyclic permutation matrix
%
% Calling syntax:
%     pmat = cycPerm(n, s)
%
% Input:
%     n: matrix of size n x n
%     s: right rotate shift number, negative number for zeros vector output
%
% Output:
%     pmat: cyclic permutation matrix


function pmat = cycPerm(n, s)

a = zeros(1, n*n);
if (s >= 0)
    a((0:n-1)*n+(0:n-1)+1) = 1;
    b = reshape(a, n, n);
    pmat = b(:, 1+mod((0:n-1)-s,n));
else
    pmat = reshape(a, n, n);
end

end
