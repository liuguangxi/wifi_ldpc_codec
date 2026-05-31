% Get original parity check matrices of LDPC.

% Copyright (c) 2019-2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function H = getH(cwlen, rate)

% Load LDPC matrices
ldpcMatrix;

switch cwlen
    case 0
        switch rate
            case 0;    pcmBase = Hn648cr12;
            case 1;    pcmBase = Hn648cr23;
            case 2;    pcmBase = Hn648cr34;
            case 3;    pcmBase = Hn648cr56;
            otherwise; error('Error: invalid value of rate');
        end
    case 1
        switch rate
            case 0;    pcmBase = Hn1296cr12;
            case 1;    pcmBase = Hn1296cr23;
            case 2;    pcmBase = Hn1296cr34;
            case 3;    pcmBase = Hn1296cr56;
            otherwise; error('Error: invalid value of rate');
        end
    case 2
        switch rate
            case 0;    pcmBase = Hn1944cr12;
            case 1;    pcmBase = Hn1944cr23;
            case 2;    pcmBase = Hn1944cr34;
            case 3;    pcmBase = Hn1944cr56;
            otherwise; error('Error: invalid value of rate');
        end
    case 3
        switch rate
            case 0;    pcmBase = Hn3888cr12;
            case 1;    pcmBase = Hn3888cr23;
            case 2;    pcmBase = Hn3888cr34;
            case 3;    pcmBase = Hn3888cr56;
            otherwise; error('Error: invalid value of rate');
        end
    otherwise
        error('Error: invalid value of cwlen');
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

end



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
