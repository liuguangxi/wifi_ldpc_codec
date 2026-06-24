% Get decoding cost of PCM.
%
% Input:
%     pcm: binary form of parity check base matrix
%
% Output:
%     cMain: main decoding cycles
%     cTail: tail decoding cycles

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


function [cMain, cTail] = getPcmDecCost(pcm)

% Pipeline delay cycles (LQ read -> LQ(new) write)
DLY = 5;


% Get read/write sequences for each layer
[r, n] = size(pcm);
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
        if (pcm(ii, jj))
            idxN1 = mod(ii-1 - 1, r) + 1;
            idxN2 = mod(ii-1 - 2, r) + 1;
            idxP1 = mod(ii-1 + 1, r) + 1;
            idxP2 = mod(ii-1 + 2, r) + 1;

            if (pcm(idxN1, jj))
                rdLate = [rdLate, jj];
            elseif (pcm(idxN2, jj))
                rdMid = [rdMid, jj];
            else
                rdEarly = [rdEarly, jj];
            end

            if (pcm(idxP1, jj))
                wrEarly = [wrEarly, jj];
            elseif (pcm(idxP2, jj))
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
lenRd = length(rdSeq{1});
lenWr = length(wrSeq{1});
pRd = lenRd;
pWr = lenRd + DLY - 1 + lenWr;

for ii = 2:r
    idx = find(rdSeq{ii} == wrSeq{ii-1}(1), 1);
    if (~isempty(idx))
        pRd = pRd + max(0, DLY - idx);
    end
    lenRd = length(rdSeq{ii});
    pRd = max(pRd, pWr + 1 - lenRd - DLY);
    pRd = pRd + lenRd;
    lenWr = length(wrSeq{ii});
    pWr = pRd + DLY - 1 + lenWr;
end
cTail = pRd + DLY - 1 + lenWr;

idx = find(rdSeq{1} == wrSeq{r}(1), 1);
if (~isempty(idx))
    pRd = pRd + max(0, DLY - idx);
end
lenRd = length(rdSeq{1});
pRd = max(pRd, pWr + 1 - lenRd - DLY);

cMain = pRd;
cTail = cTail - cMain;


end
