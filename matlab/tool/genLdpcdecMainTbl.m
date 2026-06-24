% Generate RTL code snippet for ldpcdec_main_tbl.v

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


% Generate LUT of q_raddr / q_byp / q_sh / q_vld
varname = '{q_raddr_w, q_byp_w, q_sh_w, q_vld_w}';
fprintf('always @(*) begin\n');
fprintf('    case (addr)\n');
for ii = 1:12
    seqn = seq{ii};
    for k = 1:2*seqn.Lm
        QRaddr = seqn.QRaddr(k);
        QByp = seqn.QByp(k);
        QSh = seqn.QSh(k);
        if (QSh >= 0)
            if (seqn.Z == 54)
                mux = 2 + (QSh >= 27);
            else
                mux = 0;
            end
        end
        QVld = seqn.QVld(k);

        if (QRaddr > 0)
            fprintf('        12''b%s_%d_%s: %s = {5''h%s, 1''b%d, 9''h%s, 2''h%s};\n',...
                binpre{ii}, k > seqn.Lm, dec2bin(mod(k-1, seqn.Lm), 7), varname,...
                dec2hex(QRaddr-1, 2), QByp, dec2hex(QSh + mux*128, 3), dec2hex(QVld));
        end
    end
end
fprintf('        default: %s = {5''h0, 1''b0, 9''h0, 2''h0};\n', varname);
fprintf('    endcase\n');
fprintf('end\n\n');


% Generate LUT of r_raddr / r_vld
varname = '{r_raddr_w, r_vld_w}';
fprintf('always @(*) begin\n');
fprintf('    case (addr)\n');
for ii = 1:12
    seqn = seq{ii};
    for k = 1:2*seqn.Lm
        RRaddr = seqn.RRaddr(k);

        if (RRaddr > 0)
            fprintf('        12''b%s_%d_%s: %s = {7''h%s, 1''b%d};\n',...
                binpre{ii}, k > seqn.Lm, dec2bin(mod(k-1, seqn.Lm), 7), varname,...
                dec2hex(RRaddr-1, 2), 1);
        end
    end
end
fprintf('        default: %s = {7''h0, 1''b0};\n', varname);
fprintf('    endcase\n');
fprintf('end\n\n');


% Generate LUT of t_raddr / t_byp / t_vld
varname = '{t_raddr_w, t_byp_w, t_vld_w}';
fprintf('always @(*) begin\n');
fprintf('    case (addr)\n');
for ii = 1:12
    seqn = seq{ii};
    for k = 1:2*seqn.Lm
        TRaddr = seqn.TRaddr(k);
        TByp = seqn.TByp(k);

        if (TRaddr > 0)
            fprintf('        12''b%s_%d_%s: %s = {5''h%s, 1''b%d, 1''b%d};\n',...
                binpre{ii}, k > seqn.Lm, dec2bin(mod(k-1, seqn.Lm), 7), varname,...
                dec2hex(TRaddr-1, 2), TByp, 1);
        end
    end
end
fprintf('        default: %s = {5''h0, 1''b0, 1''b0};\n', varname);
fprintf('    endcase\n');
fprintf('end\n\n');


% Generate LUT of r_waddr
varname = 'r_waddr_w';
fprintf('always @(*) begin\n');
fprintf('    case (addr)\n');
for ii = 1:12
    seqn = seq{ii};
    for k = 1:2*seqn.Lm
        RWaddr = seqn.RWaddr(k);

        if (RWaddr > 0)
            fprintf('        12''b%s_%d_%s: %s = 7''h%s;\n',...
                binpre{ii}, k > seqn.Lm, dec2bin(mod(k-1, seqn.Lm), 7), varname,...
                dec2hex(RWaddr-1, 2));
        end
    end
end
fprintf('        default: %s = 7''h0;\n', varname);
fprintf('    endcase\n');
fprintf('end\n\n');


% Generate LUT of q_hd_sh / q_hd_waddr / q_hd_vld
varname = '{q_hd_sh_w, q_hd_waddr_w, q_hd_vld_w}';
fprintf('always @(*) begin\n');
fprintf('    case (addr)\n');
for ii = 1:12
    seqn = seq{ii};
    for k = 1:2*seqn.Lm
        QHdSh = seqn.QHdSh(k);
        if (QHdSh >= 0)
            if (seqn.Z == 54)
                mux = 2 + (QHdSh >= 27);
            else
                mux = 0;
            end
        end
        QHdWaddr = seqn.QHdWaddr(k);

        if (QHdSh >= 0)
            fprintf('        12''b%s_%d_%s: %s = {9''h%s, 5''h%s, 1''b%d};\n',...
                binpre{ii}, k > seqn.Lm, dec2bin(mod(k-1, seqn.Lm), 7), varname,...
                dec2hex(QHdSh + mux*128, 3), dec2hex(QHdWaddr-1, 2), 1);
        end
    end
end
fprintf('        default: %s = {9''h0, 5''h0, 1''b0};\n', varname);
fprintf('    endcase\n');
fprintf('end\n\n');
