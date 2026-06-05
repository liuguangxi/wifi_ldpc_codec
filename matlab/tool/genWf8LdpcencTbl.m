% Generate RTL code snippet for wf8ldpcenc_tbl.v

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


clc;    clear;


% Load LDPC matrices
addpath ../src
ldpcMatrix;


% Generate RTL code
kmax = [12, 16, 18, 20, 12, 16, 18, 20, 12, 16, 18, 20, 24, 32, 36, 40];
hname = {'Hn648cr12.base', 'Hn648cr23.base', 'Hn648cr34.base', 'Hn648cr56.base',...
    'Hn1296cr12.base', 'Hn1296cr23.base', 'Hn1296cr34.base', 'Hn1296cr56.base',...
    'Hn1944cr12.base', 'Hn1944cr23.base', 'Hn1944cr34.base', 'Hn1944cr56.base',...
    'Hn3888cr12.base', 'Hn3888cr23.base', 'Hn3888cr34.base', 'Hn3888cr56.base'};
binpre = {'00_00', '00_01', '00_10', '00_11',...
    '01_00', '01_01', '01_10', '01_11',...
    '10_00', '10_01', '10_10', '10_11',...
    '11_00', '11_01', '11_10', '11_11'};

for n = 1:12
    varname = ['sh', num2str(n), '_w'];
    fprintf('always @(*) begin\n');
    fprintf('    case (addr)\n');
    for ii = 1:12
        h = eval(hname{ii});
        for k = 1:kmax(ii)
            if (n <= size(h, 1) && h(n, k) ~= -1)
                if (ii >= 5 && ii <= 8 && h(n, k) >= 27)
                    mux = 1;
                else
                    mux = 0;
                end
                fprintf('        10''b%s_%s: %s = 10''h%s;\n',...
                    binpre{ii}, dec2bin(k-1, 6), varname, dec2hex(h(n, k) + mux*128 + 256, 3));
            end
        end
    end
    for ii = 13:16
        h = eval(hname{ii});
        for k = 1:kmax(ii)
            if (n <= size(h, 1)/2)
                if (h(2*n-1, k) ~= -1)
                    fprintf('        10''b%s_%s: %s = 10''h%s;\n',...
                        binpre{ii}, dec2bin(k-1, 6), varname, dec2hex(h(2*n-1, k) + 256, 3));
                elseif (h(2*n, k) ~= -1)
                    fprintf('        10''b%s_%s: %s = 10''h%s;\n',...
                        binpre{ii}, dec2bin(k-1, 6), varname, dec2hex(h(2*n, k) + 256 + 512, 3));
                end
            end
        end
    end
    fprintf('        default: %s = 10''h0;\n', varname);
    fprintf('    endcase\n');
    fprintf('end\n\n');
end
