% ldpcPcmBase    LDPC parity check matrix base.
%
% Calling syntax:
%     pcm = ldpcPcmBase(cwlen, rate)
%
% Input:
%     cwlen: length of codeword, 0:648, 1:1296, 2:1944
%     rate: code rate, 0:1/2, 1:2/3, 2:3/4, 3:5/6
%
% Output:
%     pcm: struct for parity check matrix base

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function pcm = ldpcPcmBase(cwlen, rate)

% Load LDPC matrices
ldpcMatrix;

switch cwlen
    case 0
        switch rate
            case 0;    pcm = Hn648cr12;
            case 1;    pcm = Hn648cr23;
            case 2;    pcm = Hn648cr34;
            case 3;    pcm = Hn648cr56;
            otherwise; error('Error: invalid value of rate');
        end
    case 1
        switch rate
            case 0;    pcm = Hn1296cr12;
            case 1;    pcm = Hn1296cr23;
            case 2;    pcm = Hn1296cr34;
            case 3;    pcm = Hn1296cr56;
            otherwise; error('Error: invalid value of rate');
        end
    case 2
        switch rate
            case 0;    pcm = Hn1944cr12;
            case 1;    pcm = Hn1944cr23;
            case 2;    pcm = Hn1944cr34;
            case 3;    pcm = Hn1944cr56;
            otherwise; error('Error: invalid value of rate');
        end
    otherwise
        error('Error: invalid value of cwlen');
end

end
