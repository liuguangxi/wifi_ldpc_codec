% Get optimum row permutation of each PCM.

% Copyright (c) 2026 Guangxi Liu
%
% This source code is licensed under the MIT license found in the
% LICENSE file in the root directory of this source tree.


clc;
clear;
tic;

addpath ../src


rng(0);
Kmax = 50000;
vRP = cell(3, 4);
fprintf('--------------------------------------------------------------------------------\n');
for cwlen = 0:2
    for rate = 0:3
        fprintf('cwlen = %d    rate = %d\n\n', cwlen, rate);
        pcm = ldpcPcmBase(cwlen, rate);
        pb = (pcm.base >= 0);
        [rb, nb] = size(pb);
        for ii = 1:rb
            fprintf('%d ', pb(ii, :)); fprintf('\n')
        end
        fprintf('\nrow weight = ['); fprintf(' %d', sum(pb, 2)); fprintf(' ]    ');
        fprintf('nz = %d\n\n', sum(pb(:)));

        kmax = min(Kmax, 2 * factorial(rb));
        rpBest = []; cMainBest = 1e8; cTailBest = 1e8;
        rp = 1:rb;
        for k = 1:kmax
            pbk = pb(rp, :);
            [cMain, cTail] = getPcmDecCost(pbk);
            if ((cMain < cMainBest) || (cMain == cMainBest && cTail < cTailBest))
                rpBest = rp; cMainBest = cMain; cTailBest = cTail;
                fprintf('perm = ['); fprintf(' %d', rpBest); fprintf(' ]    ');
                fprintf('cycle(main) = %d    cycle(tail) = %d\n', cMainBest, cTailBest);
            end
            idxp = randi([2, rb], 1, 2);
            t = rp(idxp(1)); rp(idxp(1)) = rp(idxp(2)); rp(idxp(2)) = t;
        end
        vRP{cwlen+1, rate+1} = rpBest;
        fprintf('--------------------------------------------------------------------------------\n');
    end
end

fprintf('\n');
for cwlen = 0:2
    for rate = 0:3
        fprintf('{cwlen:%d, rate:%d}  =>  [', cwlen, rate);
        fprintf(' %d', vRP{cwlen+1, rate+1});
        fprintf(' ]\n');
    end
end


toc;
