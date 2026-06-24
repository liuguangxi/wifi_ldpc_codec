% Generate RTL code snippet for ldpcdec_pc_tbl.v

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


clc;    clear;


% Load LDPC matrices
addpath ../src
ldpcMatrix;


% Generate RTL code
hname = {'Hn648cr12', 'Hn648cr23', 'Hn648cr34', 'Hn648cr56',...
    'Hn1296cr12', 'Hn1296cr23', 'Hn1296cr34', 'Hn1296cr56',...
    'Hn1944cr12', 'Hn1944cr23', 'Hn1944cr34', 'Hn1944cr56'};
binpre = {'0000', '0001', '0010', '0011',...
    '0100', '0101', '0110', '0111',...
    '1000', '1001', '1010', '1011'};

seq = cell(1, 12);
for k = 1:12
    h = eval(hname{k});
    rp = ldpcPcmRowPerm(floor((k-1)/4), mod(k-1, 4));
    seq{k} = getPcmDecSeq(h.base(rp, :), h.z);
end

for n = 1:12
    varname = ['pc_sh', num2str(n), '_w'];
    fprintf('always @(*) begin\n');
    fprintf('    case (addr)\n');
    for ii = 1:12
        seqn = seq{ii};
        for k = 1:2*seqn.Lm
            vSh = seqn.PcSh{k};
            if (length(vSh) >= n && vSh(n) >= 0)
                if (seqn.Z == 54)
                    mux = 2 + (vSh(n) >= 27);
                else
                    mux = 0;
                end
                fprintf('        12''b%s_%d_%s: %s = 10''h%s;\n',...
                    binpre{ii}, k > seqn.Lm, dec2bin(mod(k-1, seqn.Lm), 7), varname, dec2hex(vSh(n) + mux*128 + 512, 3));
            end
        end
    end
    fprintf('        default: %s = 10''h0;\n', varname);
    fprintf('    endcase\n');
    fprintf('end\n\n');
end
