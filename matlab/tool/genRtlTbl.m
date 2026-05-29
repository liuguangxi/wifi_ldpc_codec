% genRtlTbl    Generate RTL code snippet for ldpcenc_tbl.v

% Copyright (c) 2019 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.

clc;    clear;

% Load LDPC matrices
addpath ../matlab/src/
ldpcMatrix;


% Generate RTL code
kmax = [12, 16, 18, 20, 12, 16, 18, 20, 12, 16, 18, 20];
hname = {'Hn648cr12.base', 'Hn648cr23.base', 'Hn648cr34.base', 'Hn648cr56.base',...
    'Hn1296cr12.base', 'Hn1296cr23.base', 'Hn1296cr34.base', 'Hn1296cr56.base',...
    'Hn1944cr12.base', 'Hn1944cr23.base', 'Hn1944cr34.base', 'Hn1944cr56.base'};
binpre = {'00_00', '00_01', '00_10', '00_11',...
    '01_00', '01_01', '01_10', '01_11',...
    '10_00', '10_01', '10_10', '10_11'};

for n = 1:12
    varname = ['sh', num2str(n), '_w'];
    fprintf('always @ (*) begin\n');
    fprintf('    case (addr)\n');
    for ii = 1:12
        h = eval(hname{ii});
        for k = 1:kmax(ii)
            if (n <= size(h, 1) && h(n, k) ~= -1)
                fprintf('        9''b%s_%s: %s = 8''d%d;\n',...
                    binpre{ii}, dec2bin(k-1, 5), varname, h(n, k)+128);
            end
        end
    end
    fprintf('        default: %s = 8''d0;\n', varname);
    fprintf('    endcase\n');
    fprintf('end\n\n');
end
