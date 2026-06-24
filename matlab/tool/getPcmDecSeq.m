% Get decoding schedule sequences of PCM.
%
% Input:
%     tab: parity check base matrix
%     z: expand factor
%
% Output:
%     seq: struct object of decoding schedule sequences

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function seq = getPcmDecSeq(tab, z)

%-------------------------------------------------------------------------------
% Pipeline 1: LQ [read]
% Pipeline 2: LQ [rcs], Lr [read]
% Pipeline 3: Lq [calc]
% Pipeline 4: Lq(min/min2) [minsel], Lq [write], Lq [read]
% Pipeline 5: LQ(new)/Lr(new) [calc]
% Pipeline 6: LQ(new) [write], Lr(new) [write], LQHard(out/pc) [rcs]
% Pipeline 7: LQHard(out) [write], pc [check]
%-------------------------------------------------------------------------------


% Pipeline delay cycles (LQ read -> LQ(new) write)
DLY = 5;


% Get size of tab
[r, n] = size(tab);


% Table of Lr index
TblLrIdx = zeros(r, n);
c = 0;
for ii = 1:r
    for jj = 1:n
        if (tab(ii, jj) >= 0)
            c = c + 1;
            TblLrIdx(ii, jj) = c;
        end
    end
end


% Table of LQ RCS value
TblLQSh0 = -ones(r, n);    % first iteration
TblLQSh1 = -ones(r, n);    % subsequent iterations
for ii = 1:r
    for jj = 1:n
        if (tab(ii, jj) >= 0)
            iiN1 = mod(ii-1 - 1, r) + 1;
            while (tab(iiN1, jj) == -1)
                iiN1 = mod(iiN1-1 - 1, r) + 1;
            end
            sh = mod(tab(ii, jj) - tab(iiN1, jj), z);
            if ((ii == 1) || (ii > 1 && all(tab(1:ii-1, jj) == -1)))
                TblLQSh0(ii, jj) = tab(ii, jj);
            else
                TblLQSh0(ii, jj) = sh;
            end
            TblLQSh1(ii, jj) = sh;
        end
    end
end


% Table of LQ hard output valid indicator
TblLQHd = zeros(r, n);
for jj = 1:n
    for ii = r:-1:1
        if (tab(ii, jj) >= 0)
            TblLQHd(ii, jj) = 1;
            break;
        end
    end
end


% Table of LQ hard output RCS values for parity check
TblPcSh = -ones(r, n);
for jj = 1:n
    sh = tab(find(TblLQHd(:, jj), 1), jj);
    for ii = 1:r
        if (tab(ii, jj) >= 0)
            TblPcSh(ii, jj) = mod(tab(ii, jj) - sh, z);
        end
    end
end


% Get read/write sequences for each layer
rdSeq = cell(1, r);
wrSeq = cell(1, r);

for ii = 1:r
    rdEarly = [];
    rdMid = [];
    rdLate = [];
    wrEarly = [];
    wrMid = [];
    wrLate = [];

    for jj = 1:n
        if (tab(ii, jj) >= 0)
            idxN1 = mod(ii-1 - 1, r) + 1;
            idxN2 = mod(ii-1 - 2, r) + 1;
            idxP1 = mod(ii-1 + 1, r) + 1;
            idxP2 = mod(ii-1 + 2, r) + 1;

            if (tab(idxN1, jj) >= 0)
                rdLate = [rdLate, jj];
            elseif (tab(idxN2, jj) >= 0)
                rdMid = [rdMid, jj];
            else
                rdEarly = [rdEarly, jj];
            end

            if (tab(idxP1, jj) >= 0)
                wrEarly = [wrEarly, jj];
            elseif (tab(idxP2, jj) >= 0)
                wrMid = [wrMid, jj];
            else
                wrLate = [wrLate, jj];
            end
        end
    end

    rdSeq{ii} = [rdEarly, rdMid, rdLate];
    wrSeq{ii} = [wrEarly, wrMid, wrLate];
end


% Calculate schedule timing
L = r * n * 2;
vRdL = zeros(1, L); vRd = zeros(1, L);
vWrL = zeros(1, L); vWr = zeros(1, L);
lenRd = length(rdSeq{1});
lenWr = length(wrSeq{1});
pRd = lenRd;
pWr = lenRd + DLY - 1 + lenWr;
vRdL(1:lenRd) = 1; vRd(1:lenRd) = rdSeq{1};
vWrL(lenRd + DLY-1 + (1:lenWr)) = 1; vWr(lenRd + DLY-1 + (1:lenWr)) = wrSeq{1};

for ii = 2:r
    idx = find(rdSeq{ii} == wrSeq{ii-1}(1), 1);
    if (~isempty(idx))
        pRd = pRd + max(0, DLY - idx);
    end
    lenRd = length(rdSeq{ii});
    pRd = max(pRd, pWr + 1 - lenRd - DLY);
    vRdL(pRd + (1:lenRd)) = ii; vRd(pRd + (1:lenRd)) = rdSeq{ii};
    pRd = pRd + lenRd;
    lenWr = length(wrSeq{ii});
    vWrL(pRd + DLY-1 + (1:lenWr)) = ii; vWr(pRd + DLY-1 + (1:lenWr)) = wrSeq{ii};
    pWr = pRd + DLY - 1 + lenWr;
end
cTail = pRd + DLY - 1 + lenWr;

idx = find(rdSeq{1} == wrSeq{r}(1), 1);
if (~isempty(idx))
    pRd = pRd + max(0, DLY - idx);
end
lenRd = length(rdSeq{1});
pRd = max(pRd, pWr + 1 - lenRd - DLY);

cEnd = cTail - pRd;
L = pRd;


% Generate decoding schedule sequences
QRaddrL = [vRdL(1:L), vRdL(1:L)];
QRaddr = [vRd(1:L), vRd(1:L)];

QWaddrL = zeros(1, 2*L);
QWaddrL(1:cTail) = vWrL(1:cTail);
QWaddrL(L+1:end) = QWaddrL(L+1:end) + vWrL(1:L);
QWaddr = zeros(1, 2*L);
QWaddr(1:cTail) = vWr(1:cTail);
QWaddr(L+1:end) = QWaddr(L+1:end) + vWr(1:L);

QByp = zeros(1, 2*L);
for k = 1:2*L
    if (QRaddr(k) > 0 && QWaddr(k) > 0 && QRaddr(k) == QWaddr(k))
        QByp(k) = 1;
    end
end

QSh = -ones(1, 2*L);
for k = 1:2*L
    i1 = QRaddrL(k); i2 = QRaddr(k);
    if (i1 > 0 && i2 > 0)
        if (k <= L)
            QSh(k) = TblLQSh0(i1, i2);
        else
            QSh(k) = TblLQSh1(i1, i2);
        end
    end
end

QVld = zeros(1, 2*L);
for k = 1:2*L
    if (QRaddrL(k) > 0)
        QVld(k) = 1;    % vld = 1
        if ((k == 2*L) || (k < 2*L && QRaddrL(k+1) ~= QRaddrL(k)))
            QVld(k) = QVld(k) + 2;    % eop = 1
        end
    end
end

RRaddr = zeros(1, 2*L);
for k = L+1:2*L
    i1 = QRaddrL(k); i2 = QRaddr(k);
    if (i1 > 0 && i2 > 0)
        RRaddr(k) = TblLrIdx(i1, i2);
    end
end

TWaddr = [zeros(1, 3), QRaddr(1:end-3)];
TRaddr = [QWaddr(3:end), QWaddr(L+1:L+2)];

TByp = zeros(1, 2*L);
for k = 1:2*L
    if (TWaddr(k) > 0 && TRaddr(k) > 0 && TWaddr(k) == TRaddr(k))
        TByp(k) = 1;
    end
end

RWaddr = zeros(1, 2*L);
for k = 1:2*L
    i1 = QWaddrL(k); i2 = QWaddr(k);
    if (i1 > 0 && i2 > 0)
        RWaddr(k) = TblLrIdx(i1, i2);
    end
end

QHdSh = -ones(1, 2*L);
QHdWaddr = zeros(1, 2*L);
for k = 1:2*L
    i1 = QWaddrL(k); i2 = QWaddr(k);
    if (i1 > 0 && i2 > 0 && TblLQHd(i1, i2))
        QHdSh(k) = mod(-tab(i1, i2), z);
        QHdWaddr(k) = QWaddr(k);
    end
end

PcSh = cell(1, 2*L);
for k = 1:2*L
    i1 = QWaddrL(k); i2 = QWaddr(k);
    if (i1 > 0 && i2 > 0 && TblLQHd(i1, i2))
        PcSh{k} = TblPcSh(:, i2)';
    end
end


% Output
seq.Lm = L;
seq.Le = cEnd;
seq.Z = z;

seq.QRaddr = QRaddr;
seq.QByp = QByp;
seq.QSh = QSh;
seq.QVld = QVld;
seq.RRaddr = RRaddr;
seq.TRaddr = TRaddr;
seq.TByp = TByp;
seq.RWaddr = RWaddr;
seq.QHdSh = QHdSh;
seq.QHdWaddr = QHdWaddr;
seq.PcSh = PcSh;


end
