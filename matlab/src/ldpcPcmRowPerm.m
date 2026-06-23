% ldpcPcmRowPerm    LDPC parity check matrix base row permutation.
%
% Calling syntax:
%     rp = ldpcPcmRowPerm(cwlen, rate)
%
% Input:
%     cwlen: length of codeword, 0:648, 1:1296, 2:1944
%     rate: code rate, 0:1/2, 1:2/3, 2:3/4, 3:5/6
%
% Output:
%     rp: row permutation for parity check matrix base

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function rp = ldpcPcmRowPerm(cwlen, rate)

switch cwlen
    case 0
        switch rate
            case 0;    rp = [1 9 2 6 11 10 7 5 12 3 8 4];    % n648cr12
            case 1;    rp = [1 2 3 4 5 6 7 8];    % n648cr23
            case 2;    rp = [1 6 2 3 5 4];    % n648cr34
            case 3;    rp = [1 3 2 4];    % n648cr56
            otherwise; error('Error: invalid value of rate');
        end
    case 1
        switch rate
            case 0;    rp = [1 7 3 12 11 6 2 8 4 10 5 9];    % n1296cr12
            case 1;    rp = [1 6 3 4 5 8 7 2];    % n1296cr23
            case 2;    rp = [1 2 3 4 5 6];    % n1296cr34
            case 3;    rp = [1 3 2 4];    % n1296cr56
            otherwise; error('Error: invalid value of rate');
        end
    case 2
        switch rate
            case 0;    rp = [1 12 7 9 5 8 4 6 2 11 3 10];    % n1944cr12
            case 1;    rp = [1 7 3 4 5 6 2 8];    % n1944cr23
            case 2;    rp = [1 4 2 3 5 6];    % n1944cr34
            case 3;    rp = [1 3 2 4];    % n1944cr56
            otherwise; error('Error: invalid value of rate');
        end
    otherwise
        error('Error: invalid value of cwlen');
end

end
