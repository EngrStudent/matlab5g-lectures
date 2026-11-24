%% track11_one_in_ten_demo
%% One in Ten (album track 11): one link loop, BLER waterfalls, throughput, and the CQI target
% Every piece built so far goes into one loop: a transport block is coded, 
% modulated, put on the grid, turned into a waveform, hit by noise, and decoded. 
% Run it many times at many noise levels, count the blocks that fail, and you 
% have the curve 5G links are judged by.
% 
% This demonstration sends one slot first, then sweeps the SNR with HARQ in 
% the loop, looks at why the CQI aims at one block in ten, and compares a 
% receiver that knows the channel with one that must estimate it.
%% Guiding question
% How do you measure how well a link works, and why does the phone aim for 
% about one failed block in ten?
% This demonstration
% 1. B1 — One slot, end to end: it must pass at high SNR before any sweep.
% 
% 2. B2 — The SNR loop: first-transmission BLER, BLER after HARQ, and throughput.
% 
% 3. B3 — Why one in ten: the CQI table and how many blocks honest counting 
% needs.
% 
% 4. B4 — Perfect against practical channel knowledge, on the same noise.
% 
% 5. Build it — From pass and fail counts to a BLER curve, its 0.1 crossing, 
% and a throughput.
% Key relationships
% The block error rate is a count, read on a log axis:
% 
% $$\mathrm{BLER} = \frac{\text{blocks that failed the CRC}}{\text{blocks sent}},\qquad 
% \text{throughput} = \frac{\text{bits in blocks that passed}}{\text{slots used}}$$
% 
% The SNR here is per resource element (RE), as in the toolbox link examples: 
% with an FFT of size N_FFT the time-domain noise is scaled by
% 
% $$N_0 = \frac{1}{\sqrt{N_{\mathrm{FFT}}\cdot\mathrm{SNR}}},\qquad \sigma^2_{\mathrm{RE}} = N_0^2\,N_{\mathrm{FFT}} = \frac{1}{\mathrm{SNR}}$$
% 
% A 0.1 crossing between two SNR points s_1 and s_2 is read by straight-line 
% interpolation on log10(BLER):
% 
% $$s_{0.1} = s_1 + \frac{\log_{10}0.1 - \log_{10}B_1}{\log_{10}B_2 - \log_{10}B_1}\,(s_2 - s_1)$$
% Key ideas to remember
% • Build the loop once, for one slot, and check that one block passes before 
% you sweep anything.
% 
% • Block error rate is the number of blocks that failed their CRC divided 
% by the number sent. Against SNR it is flat near one, then drops like a waterfall, 
% often only a few decibels wide.
% 
% • Throughput counts the bits in blocks that passed, per slot used. It can 
% never be more than the block size times the number of new blocks you sent.
% 
% • The phone picks the highest CQI whose block error probability would not 
% go past one in ten on the first transmission, for three of the four CQI tables; 
% the table for high reliability (the low latency table in the song) aims for 
% one in a hundred thousand.
% 
% • HARQ asks again: a block that fails the first time can still arrive on 
% the next try, so the BLER after HARQ sits below the first-transmission BLER, 
% at the cost of extra slots.
% 
% • Count honestly: a common rule of thumb is about a hundred errors per point, 
% so one in a thousand needs about a hundred thousand blocks. Reuse the same 
% random seeds to compare two receivers.
% 
% • Perfect channel knowledge is a bound, not a result: a real estimator puts 
% noise in the channel estimate too, and the waterfall slides to the right.
% Prerequisites
% • LDPC decoding and the CRC (album track 04 Every Check Agrees, track04/track04_every_check_agrees_demo); 
% the transport block size, redundancy versions, and HARQ (album track 05 
% Say It Again, track05/track05_say_it_again_demo).
% 
% • DM-RS channel estimation and equalization (album track 07 Learn the Channel, 
% track07/track07_learn_the_channel_demo); the CSI-RS the phone measures before 
% it reports a CQI (album track 10 Sound It Out, track10/track10_sound_it_out_demo).
% 
% • OFDM, the resource grid, and SNR in dB (track 00 Fundamentals, track00_fundamentals/p00a_ofdm_and_cp_demo).
% Words used in this demo
% • BLER (block error rate): failed blocks over blocks sent. First-transmission 
% BLER counts only the first try; BLER after HARQ counts blocks that never 
% passed.
% 
% • CQI (channel quality indicator): the number the phone reports, a row of 
% a CQI table with a modulation and a target code rate.
% 
% • Waterfall: the steep part of the BLER curve. 0.1 crossing: the SNR where 
% the curve passes one in ten.
% 
% • Throughput: passed information bits per slot used. Seed: the starting 
% value of the random number generator; the same seed gives the same noise.
% 
% • Perfect receiver: one that is handed the true channel (here H = 1, plain 
% noise) and the true noise level. Practical receiver: one that estimates both 
% from the DM-RS.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • x = value and [a b c] — Purpose: store a value or a row of values under 
% a name. Inputs: a name, then values. Outputs: the variable x.
% 
% • + - * / and ./ — Purpose: arithmetic, and entry-by-entry division. Inputs: 
% numbers or vectors. Outputs: the result.
% 
% • find(x < v, 1) — Purpose: the position of the first entry below v. Inputs: 
% a vector, a threshold. Outputs: an index.
% 
% • log10(x) — Purpose: the base-10 logarithm, for a log axis. Inputs: positive 
% numbers. Outputs: numbers (log10(0.1) = −1).
% 
% • ceil(x) — Purpose: round up to a whole number. Inputs: a number. Outputs: 
% a whole number.
% 
% Commands you read in the given code
% • carrier = nrCarrierConfig(...), pdsch = nrPDSCHConfig, [ind, info] = nrPDSCHIndices(carrier, 
% pdsch) — Purpose: the carrier, the shared channel, and where its REs sit. 
% Inputs: spacing (kHz), RBs, cell ID; PRBSet, Modulation, SymbolAllocation. 
% Outputs: configuration objects; indices and info.G (coded bits) and info.NREPerPRB.
% 
% • tbs = nrTBS(mod, layers, nPRB, NREPerPRB, rate) — Purpose: the transport 
% block size. Outputs: bits.
% 
% • enc = nrDLSCH, setTransportBlock(enc, tr, id), cw = enc(mod, layers, G, 
% rv, id); dec = nrDLSCHDecoder, [bits, blkerr] = dec(soft, mod, layers, rv, 
% id); reset(obj) — Purpose: code a block for one redundancy version; decode 
% it (combining HARQ tries) and check its CRC; empty the HARQ buffers. Outputs: 
% coded bits; decoded bits and true/false for a CRC failure.
% 
% • nrPDSCH, nrPDSCHDMRSIndices, nrPDSCHDMRS, nrResourceGrid, nrOFDMInfo, 
% nrOFDMModulate, nrOFDMDemodulate — Purpose: map the codeword and the DM-RS 
% onto the grid, find N_FFT, and go to a waveform and back. Inputs: the carrier, 
% the channel, symbols. Outputs: symbols, indices, a grid, a waveform, a structure.
% 
% • soft = nrPDSCHDecode(carrier, pdsch, sym, nVar) — Purpose: soft bits 
% from received symbols. Inputs: symbols and the noise variance per RE. Outputs: 
% a cell, soft{1} for one codeword.
% 
% • nrChannelEstimate, nrEqualizeMMSE, nrCQITables — Used in B4 (estimate 
% and equalize) and B3 (the CQI tables); listed at the start of those beats.
% 
% • Figure family: figure(Name = ...), semilogy, plot, yline, xline, legend, 
% grid on, tiledlayout, nexttile, xlabel, ylabel, title — Purpose: draw curves 
% on a log or linear axis and label them. Inputs: data and text. Outputs: a 
% figure.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing, ranges, and loops: x(k), a:b:c, x(end), for k = ... end, if 
% ... else ... end, while ... end, break — Purpose: read or write entries, step through values, 
% repeat, choose, stop a loop early. Inputs: arrays, ranges, tests. Outputs: 
% the entries or the repeated work.
% 
% • Compare and combine: == < > <=, ~, &&, any, all — Purpose: compare values; 
% not; and; any or every entry true. Inputs: numbers or arrays. Outputs: true/false.
% 
% • Built-in helpers: abs, max, min, mean, sum, numel, height, isequal, isnan, 
% randi, randn, zeros, sqrt, double, diff, fliplr, interp1, NaN — Purpose: sizes, sums, random bits 
% and noise, empty arrays. Inputs: numbers or arrays. Outputs: numbers or arrays 
% (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, and f = @(v) ... — Purpose: 
% write and join text, turn numbers into text, and make a one-line helper such 
% as listText. Inputs: text or numbers. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), fprintf, disp, clear, close all, rng(seed) — Purpose: show columns 
% side by side, stop with a hint when a check fails, print a banner or note, 
% remove variables or figures, repeat random values. Inputs: columns, a test 
% and message, text, names, a seed. Outputs: a shown table or line; an error 
% if a check fails.
% Working status
% Status: unverified until M runs it in R2024b.
% 
% Teaching draft built to the track01 r03 template (track11 r01, 2026-11-20) 
% from the live track11_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox (R2024a 
% or later for nrCQITables). B2 and B4 run 50 blocks per SNR point: they draw 
% the shape of the curves, not a measurement (B3 says why). The run takes longer 
% than the earlier tracks; expect a minute or more. Teaching demo, not production 
% code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year), so every block and noise draw repeats

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% One link, shared by every beat: 24 PRBs of QPSK in symbols 2 to 13 of a 52-RB carrier.
carrier = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52, NCellID = 1);   % kHz, RBs, cell ID
pdsch = nrPDSCHConfig;
pdsch.PRBSet = 0:23;               % 24 PRBs
pdsch.Modulation = 'QPSK';         % 2 bits per RE
pdsch.SymbolAllocation = [2 12];   % first symbol (0-based) and number of symbols
pdsch.NumLayers = 1;               % one layer
[pdschInd, indInfo] = nrPDSCHIndices(carrier, pdsch);   % data REs, and G and NREPerPRB in indInfo
dmrsInd = nrPDSCHDMRSIndices(carrier, pdsch);           % DM-RS REs (default: one symbol)
dmrsSym = nrPDSCHDMRS(carrier, pdsch);                  % DM-RS symbols
ofdmInfo = nrOFDMInfo(carrier);                         % ofdmInfo.Nfft, the FFT size for the noise scaling

tcr = 0.48;                                                             % target code rate
tbs = nrTBS(pdsch.Modulation, 1, numel(pdsch.PRBSet), indInfo.NREPerPRB, tcr);   % transport block, bits
rvSeq = [0 2 3 1];   % redundancy versions for the HARQ tries, the conventional teaching order
%% B1 — One slot, end to end
% New words
% • End to end: from the transport block at the transmitter to the CRC check 
% at the receiver.
% Beat-only commands
% • randn(size(w), "like", w) — complex noise with variance 1, the same size 
% and type as the waveform w.
% Why it matters
% Before drawing a waterfall, one quiet slot must go through the whole chain 
% and come back with blkerr = false and every bit right. If it does not, the 
% plumbing is broken, and a sweep would make a wiring bug look like a poor 
% MCS. The noise follows the toolbox SNR definition (Key relationships): per 
% RE, with variance 1/SNR after OFDM demodulation, and that same 1/SNR is the 
% noise variance handed to nrPDSCHDecode.
% What to look for
% • In the slot table: the TBS, the coded bits G, the code rate, blkerr, and 
% whether every bit came back.
% Common mistakes
% Do not start the SNR loop before a single slot passes.
% 
% Do not scale the noise by the average power of the time waveform: use the 
% per-RE definition in Key relationships (exercise E5 asks what goes wrong).
% Try it (personal exploration)
% Predict blkerr (1 for a failed CRC, 0 for a pass) for the same kind of slot 
% at −6 dB. Type it into myPrediction before you run this section; the one-row 
% table at the end sends a separate block at −6 dB.

% Try it: type your prediction here (1 or 0) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — One slot, end to end
fprintf("B1 — One slot, end to end\n");   % banner title only; every number below goes into a table

% Transmitter: a random transport block, coded for RV 0 and HARQ process 0.
trBlk = randi([0 1], tbs, 1, 'int8');   % the information bits
enc = nrDLSCH(MultipleHARQProcesses = true);
enc.TargetCodeRate = tcr;
setTransportBlock(enc, trBlk, 0);
cw = enc(pdsch.Modulation, 1, indInfo.G, 0, 0);   % modulation, layers, coded bits, RV, HARQ process

% The grid and the waveform: data and DM-RS in place, then OFDM.
txGrid = nrResourceGrid(carrier);
txGrid(pdschInd) = nrPDSCH(carrier, pdsch, cw);
txGrid(dmrsInd) = dmrsSym;
wave = nrOFDMModulate(carrier, txGrid, Windowing = 0);   % no windowing, so every sample is plain OFDM

% Noise at 20 dB per RE (Key relationships), then back to the grid.
snrdB = 20;                                           % SNR per RE, dB
SNR = 10^(snrdB/10);                                  % linear
N0 = 1/sqrt(double(ofdmInfo.Nfft)*SNR);               % time-domain noise scale
rxGrid = nrOFDMDemodulate(carrier, wave + N0*randn(size(wave), "like", wave), CyclicPrefixFraction = 1);

% Receiver: soft bits with the noise variance per RE, then decode and check the CRC.
dec = nrDLSCHDecoder(MultipleHARQProcesses = true);
dec.TargetCodeRate = tcr;
dec.TransportBlockLength = tbs;
soft = nrPDSCHDecode(carrier, pdsch, rxGrid(pdschInd), 1/SNR);
[rxBits, blkerr] = dec(soft{1}, pdsch.Modulation, 1, 0, 0);   % soft bits, modulation, layers, RV, HARQ process

% Two tests: the CRC passes, and every information bit came back.
okNoErr = ~blkerr;
assert(okNoErr, ...
    'The 20 dB slot should pass its CRC. Look first at the noise: N0 must use ofdmInfo.Nfft, and nrPDSCHDecode needs 1/SNR.');
okBits = isequal(rxBits, trBlk);
assert(okBits, ...
    'Every decoded bit should match the transport block. Look first at dec.TransportBlockLength: it must equal tbs.');

b1Slot = table(tbs, indInfo.G, round((tbs + 16)/indInfo.G, 4), blkerr, okBits, ...
    VariableNames = {'TBS', 'G', 'EffectiveRate', 'blkerr', 'AllBitsBack'});
b1Slot

% Put your Try-it prediction beside a separate block at -6 dB (new encoder and decoder).
encTry = nrDLSCH(MultipleHARQProcesses = true, TargetCodeRate = tcr);
setTransportBlock(encTry, randi([0 1], tbs, 1, 'int8'), 0);
gridTry = nrResourceGrid(carrier);
gridTry(pdschInd) = nrPDSCH(carrier, pdsch, encTry(pdsch.Modulation, 1, indInfo.G, 0, 0));
gridTry(dmrsInd) = dmrsSym;
waveTry = nrOFDMModulate(carrier, gridTry, Windowing = 0);
snrTry = 10^(-6/10);                                   % -6 dB per RE, linear
rxTry = nrOFDMDemodulate(carrier, waveTry + randn(size(waveTry), "like", waveTry)/sqrt(double(ofdmInfo.Nfft)*snrTry), ...
    CyclicPrefixFraction = 1);
decTry = nrDLSCHDecoder(MultipleHARQProcesses = true, TargetCodeRate = tcr, TransportBlockLength = tbs);
softTry = nrPDSCHDecode(carrier, pdsch, rxTry(pdschInd), 1/snrTry);
[~, tryErr] = decTry(softTry{1}, pdsch.Modulation, 1, 0, 0);
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, double(tryErr), predictionNote, ...
    VariableNames = {'MyPrediction', 'blkerr_minus6dB', 'Note'});
b1Prediction
%%
% At 20 dB the block passes and every bit comes back: the chain is wired correctly, 
% so a later failure is the noise, not the plumbing. The code rate in the 
% table counts the CRC too: (TBS + 16)/G is close to the 0.48 asked for. Compare 
% the −6 dB block with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["CRC passes at 20 dB"; ...
     "Every bit back"], ...
    ["blkerr = 0"; "true"], ...
    ["blkerr = " + string(double(blkerr)); string(okBits)], ...
    [okNoErr; okBits], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep enc and dec: B2 reuses them, resetting them for every new block.
clear b1Slot b1Checks b1Prediction predictionNote okNoErr okBits ...
      trBlk cw txGrid wave snrdB SNR N0 rxGrid soft rxBits blkerr ...
      encTry gridTry waveTry snrTry rxTry decTry softTry tryErr myPrediction
%% B2 — The SNR loop: BLER and throughput
% New words
% • Residual BLER: the BLER after HARQ, the fraction of blocks that never 
% passed in any try.
% Beat-only commands
% • semilogy(x, y), yline(v), tiledlayout and nexttile — a log y-axis, a horizontal 
% line, and two plots side by side (Figure family).
% Why it matters
% There are two BLERs. The first-transmission BLER (did RV 0 alone decode?) 
% is what the CQI target of one in ten describes. The BLER after HARQ is the 
% fraction still failing after every try you allow; HARQ pushes it well below 
% the first-transmission curve. Throughput counts passed information bits 
% per slot used, so each retransmission costs throughput. Fifty blocks per 
% point draw the shape of the curves, not a measurement.
% What to look for
% • In the sweep table: both BLERs and the throughput at each SNR, and the 
% slots used.
% 
% • In the figure: two waterfalls on a log axis with a line at 0.1, and a 
% throughput curve that levels off.
% Common mistakes
% Do not read the BLER after HARQ against the 0.1 target: the target is for 
% the first transmission.
% 
% Do not plot BLER on a linear axis: it hides the crossing.
% Try it (personal exploration)
% Predict the SNR, in dB, where the first-transmission BLER crosses 0.1. Type 
% it into myPrediction before you run this section; the one-row table at the 
% end reads the crossing from this sweep.

% Try it: type your prediction here (dB) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — The SNR loop: BLER and throughput
fprintf("B2 — The SNR loop: BLER and throughput\n");   % banner title only; every number below goes into a table

snrGrid = -2:1:6;   % SNR per RE, dB
nBlocks = 50;       % new blocks per SNR point: a shape, not a measurement (B3)

% Counters per SNR point, filled in the loop below.
nErr1 = zeros(size(snrGrid));      % blocks that failed their first transmission
nErrHarq = zeros(size(snrGrid));   % blocks that failed every try
passBits = zeros(size(snrGrid));   % information bits in blocks that passed
slotsUsed = zeros(size(snrGrid));  % slots used, one per try

% Sweep the SNR points; at each one, send nBlocks new transport blocks.
for k = 1:numel(snrGrid)
    SNR = 10^(snrGrid(k)/10);                       % linear
    N0 = 1/sqrt(double(ofdmInfo.Nfft)*SNR);         % time-domain noise scale (Key relationships)
    % Each new block: fresh bits, empty HARQ buffers, then up to four tries.
    for b = 1:nBlocks
        tr = randi([0 1], tbs, 1, 'int8');
        reset(enc);
        reset(dec);
        setTransportBlock(enc, tr, 0);
        passed = false;
        % HARQ: try each redundancy version in turn until the CRC passes; the decoder combines the tries.
        for r = 1:numel(rvSeq)
            txGrid = nrResourceGrid(carrier);
            txGrid(pdschInd) = nrPDSCH(carrier, pdsch, enc(pdsch.Modulation, 1, indInfo.G, rvSeq(r), 0));
            txGrid(dmrsInd) = dmrsSym;
            wave = nrOFDMModulate(carrier, txGrid, Windowing = 0);
            rxGrid = nrOFDMDemodulate(carrier, wave + N0*randn(size(wave), "like", wave), CyclicPrefixFraction = 1);
            soft = nrPDSCHDecode(carrier, pdsch, rxGrid(pdschInd), 1/SNR);
            [~, err] = dec(soft{1}, pdsch.Modulation, 1, rvSeq(r), 0);
            slotsUsed(k) = slotsUsed(k) + 1;        % every try uses a slot
            if r == 1
                nErr1(k) = nErr1(k) + err;           % the first transmission alone
            end
            if ~err
                passed = true;
                break                                % passed: no more tries for this block
            end
        end
        nErrHarq(k) = nErrHarq(k) + ~passed;
        passBits(k) = passBits(k) + passed*tbs;
    end
end
bler1 = nErr1/nBlocks;              % first-transmission BLER
blerHarq = nErrHarq/nBlocks;        % BLER after HARQ
tput = passBits./slotsUsed;         % bits per slot used

% The 0.1 crossing of the first-transmission curve (Key relationships), if it crosses.
k2 = find(bler1 < 0.1, 1);
if ~isempty(k2) && k2 > 1 && bler1(k2 - 1) >= 0.1
    yLog = log10(max(bler1, 1/(nBlocks + 1)));          % a 0 count plotted as below one in nBlocks
    cross1 = snrGrid(k2 - 1) + (-1 - yLog(k2 - 1))/(yLog(k2) - yLog(k2 - 1))*(snrGrid(k2) - snrGrid(k2 - 1));
else
    cross1 = NaN;                                        % no crossing inside this grid
end

% Four tests: the high end passes, the curve falls, HARQ combining helps where the first try fails,
% and the top SNR runs close to the full block size. The throughput invariant is shown as a table row.
okHighPass = tput(end) > 0;
assert(okHighPass, ...
    'Some blocks should pass at the top of the grid. Look first at B1: if one slot fails at 20 dB, fix that first.');
okFalls = bler1(1) > bler1(end);
assert(okFalls, ...
    'The first-transmission BLER should fall from the low end to the high end. Look first at N0: it must shrink as the SNR grows.');
okHarqHelps = nErrHarq(1) <= 0.5*nErr1(1);
assert(okHarqHelps, ...
    'At the lowest SNR, HARQ should rescue at least half of the blocks that failed their first try. Look first at where the decoder is reset.');
okFullRate = tput(end) > 0.9*tbs;
assert(okFullRate, ...
    'At the top SNR almost every first transmission should pass, so the throughput should exceed 90 percent of the TBS. Look first at the noise scaling and at snrGrid.');
okInvariant = all(passBits <= tbs*nBlocks);   % true by construction (a passing block adds tbs once); shown as a table row, not asserted

b2Sweep = table(snrGrid(:), bler1(:), blerHarq(:), round(tput(:)), slotsUsed(:), ...
    VariableNames = {'SNR_dB', 'BLER_FirstTx', 'BLER_AfterHARQ', 'Throughput_bitsPerSlot', 'SlotsUsed'});
b2Sweep

% Put your Try-it prediction beside the crossing read from this sweep.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, round(cross1, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'Crossing_FirstTx_dB', 'Note'});
b2Prediction

% Two panels: the two waterfalls against 0.1, and the throughput against the block size.
figure(Name = 'Track 11 B2 - BLER and throughput', Color = 'w');
tiledlayout(1, 2);
nexttile;
semilogy(snrGrid, max(bler1, 1/(nBlocks + 1)), '-o', snrGrid, max(blerHarq, 1/(nBlocks + 1)), '-s');   % 0 counts drawn at 1/(nBlocks+1)
yline(0.1, ':r', 'CQI target (first transmission)');
grid on;
legend('first transmission', 'after HARQ', Location = 'southwest');
xlabel('SNR per RE (dB)');
ylabel('BLER');
title('B2: BLER, 50 blocks per point');
nexttile;
plot(snrGrid, tput, '-o');
yline(tbs, ':k', 'TBS');
grid on;
xlabel('SNR per RE (dB)');
ylabel('bits per slot used');
title('B2: throughput');
%%
% The first-transmission BLER sits near one at the low end and drops within 
% a few dB: the waterfall. The curve after HARQ sits to its left, because 
% the decoder combines the tries, but the throughput shows the price: at low 
% SNR many slots carry retransmissions, and the throughput only reaches the 
% TBS once most first transmissions pass. Compare the crossing with your prediction.
%% B2 — Assertion checks

% One row per assert in B2, plus the invariant row (true by construction). Pass is computed from the stored flags.
b2Checks = table( ...
    ["Some blocks pass at the top SNR"; ...
     "First-transmission BLER falls"; ...
     "HARQ rescues half at the lowest SNR"; ...
     "Top-SNR throughput > 90 percent of TBS"; ...
     "Passed bits ≤ TBS × new blocks (by construction)"], ...
    ["> 0"; "first > last"; "≤ " + string(0.5*nErr1(1)) + " failures after HARQ"; "> " + string(0.9*tbs); "≤ " + string(tbs*nBlocks) + " per point"], ...
    [string(round(tput(end))); string(bler1(1)) + " > " + string(bler1(end)); ...
     string(nErrHarq(1)) + " of " + string(nErr1(1)); string(round(tput(end))); "max " + string(max(passBits))], ...
    [okHighPass; okFalls; okHarqHelps; okFullRate; okInvariant], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep snrGrid and nBlocks: B4 sweeps the same points.
clear b2Sweep b2Checks b2Prediction predictionNote okHighPass okFalls okHarqHelps okFullRate okInvariant ...
      nErr1 nErrHarq passBits slotsUsed bler1 blerHarq tput k2 yLog cross1 ...
      k b r SNR N0 tr passed txGrid wave rxGrid soft err enc dec myPrediction
%% B3 — Why one in ten
% New words
% • Target code rate: the code rate a CQI row asks for, already divided by 
% 1024 in the toolbox table.
% Beat-only commands
% • ct = nrCQITables — the four CQI tables of TS 38.214 as table properties 
% (ct.CQITable1 to ct.CQITable4), each with a TargetCodeRate column. height(t) 
% — the number of rows of a table.
% Why it matters
% One in ten is not a lyric convenience. TS 38.214 §5.2.2.1 says the phone 
% reports the highest CQI whose block error probability on a single transmission 
% would not exceed 0.1, for three of the four CQI tables; the high-reliability 
% table aims at 0.00001. Each CQI row is a modulation and a target code rate, 
% and the rate of the B1 link sits between two QPSK rows of table 1. Counting 
% honestly needs about a hundred errors per point, which is why the fifty 
% blocks per point in B2 draw a shape, not a measurement.
% What to look for
% • In the CQI table: the QPSK rows of table 1 and their target code rates.
% 
% • In the counting table: the blocks needed for a hundred errors at each 
% target.
% Common mistakes
% Do not read a single crossing from fifty blocks as if it had a hundred errors 
% behind it.
% 
% Do not multiply the TargetCodeRate column by 1024 a second time: the toolbox 
% table already divides by 1024.
% Try it (personal exploration)
% Predict how many blocks you would need for about a hundred errors at the 
% high-reliability target of one in a hundred thousand. Type it into myPrediction 
% before you run this section; the one-row table at the end computes it.

% Try it: type your prediction here (blocks) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Why one in ten
fprintf("B3 — Why one in ten\n");   % banner title only; every number below goes into a table

% The four CQI tables; table 1 (up to 64QAM) is one of the three with the 0.1 target.
ct = nrCQITables;
cqi1 = ct.CQITable1;   % CQI 0 to 15: rows 1 to 16

% The QPSK rows of table 1 are CQI 1 to 6 (rows 2 to 7); find the highest one at or below the link's rate.
qpskRates = cqi1.TargetCodeRate(2:7);              % already divided by 1024
cqiBelow = find(qpskRates <= tcr, 1, 'last');      % CQI index, because row 2 is CQI 1

% Blocks for about a hundred errors at the two targets the beat names.
targets = [0.1; 1e-3];        % BLER targets
blocksNeeded = 100./targets;  % blocks for about 100 errors

% Two tests: table 1 has 16 rows, and the link's rate sits between CQI 5 and CQI 6.
okRows = height(cqi1) == 16;
assert(okRows, ...
    'CQI table 1 should have 16 rows, CQI 0 to 15. Look first at the property name: ct.CQITable1.');
okBracket = isequal(cqiBelow, 5) && qpskRates(6) > tcr;
assert(okBracket, ...
    'The link rate 0.48 should sit between CQI 5 and CQI 6. Common mistake: multiplying TargetCodeRate by 1024 again.');

b3Cqi = cqi1(1:7, :);   % CQI 0 to 6: the out-of-range row and the QPSK rows
b3Cqi
b3Counting = table(targets, blocksNeeded, ...
    VariableNames = {'BLER_Target', 'BlocksFor100Errors'});
b3Counting

% Put your Try-it prediction beside the count for one in a hundred thousand.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, 100/1e-5, predictionNote, ...
    VariableNames = {'MyPrediction', 'BlocksFor100Errors_1e5', 'Note'});
b3Prediction
%%
% The link's rate of 0.48 lies between the QPSK rows for CQI 5 and CQI 6, 
% so this link is a CQI-5-and-a-bit link: a phone would report the row whose 
% first-transmission BLER stays at or below 0.1 at the SNR it measures. The 
% counting table shows why B2 is only a shape: honest points at 0.1 need about 
% a thousand blocks, and every factor of ten lower needs ten times more. Compare 
% the count with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["CQI table 1 has 16 rows"; ...
     "Link rate between CQI 5 and CQI 6"], ...
    ["16"; "CQI 5"], ...
    [string(height(cqi1)); "CQI " + string(cqiBelow)], ...
    [okRows; okBracket], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the CQI tables.
clear b3Cqi b3Counting b3Checks b3Prediction predictionNote okRows okBracket ...
      ct cqi1 qpskRates cqiBelow targets blocksNeeded myPrediction
%% B4 — Perfect against practical, on the same noise
% New words
% • Bound: a result no real receiver can beat, used to judge how far a practical 
% one falls short.
% Beat-only commands
% • [H, nVar] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym) — the 
% channel at every RE and the noise variance, estimated from the DM-RS.
% 
% • eq = nrEqualizeMMSE(sym, h, nVar) — undo the channel on the data REs, 
% weighting by the noise.
% Why it matters
% Handing the receiver the true channel makes the curve look great, but no 
% real phone knows the channel for free. Here the channel is plain noise (H 
% = 1), so the perfect receiver uses H = 1 and the true noise variance 1/SNR. 
% The practical receiver estimates both from the noisy DM-RS, so noise lives 
% in its channel estimate too. Both receivers see the very same block and 
% noise at every point, because each block starts from the same seed: the 
% only difference is the estimator. Only first transmissions are counted, 
% the BLER the CQI target is about.
% What to look for
% • In the comparison table: both first-transmission BLERs at each SNR, and 
% the practical receiver's noise estimate beside the true 1/SNR.
% 
% • In the crossing table: the 0.1 crossing of each curve, where both exist.
% Common mistakes
% Do not compare two receivers on different noise draws: the difference is 
% then partly luck.
% 
% Do not assert point by point that the practical receiver is worse: with 
% fifty blocks a single point can come out the other way.
% Try it (personal exploration)
% Predict the noise variance per RE that the practical receiver should estimate 
% at the top of the grid, 6 dB. Type it into myPrediction before you run this 
% section; the one-row table at the end shows the average estimate there.

% Try it: type your prediction here (noise variance per RE) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Perfect against practical, on the same noise
fprintf("B4 — Perfect against practical, on the same noise\n");   % banner title only; every number below goes into a table

% One encoder and two decoders, one per receiver.
encB4 = nrDLSCH(MultipleHARQProcesses = true, TargetCodeRate = tcr);
decPerf = nrDLSCHDecoder(MultipleHARQProcesses = true, TargetCodeRate = tcr, TransportBlockLength = tbs);
decPrac = nrDLSCHDecoder(MultipleHARQProcesses = true, TargetCodeRate = tcr, TransportBlockLength = tbs);

nErrPerf = zeros(size(snrGrid));   % first-transmission failures, perfect receiver
nErrPrac = zeros(size(snrGrid));   % first-transmission failures, practical receiver
nVarMean = zeros(size(snrGrid));   % average noise estimate of the practical receiver

% Sweep the SNR points; every block is seeded, so both receivers see the same bits and noise.
for k = 1:numel(snrGrid)
    SNR = 10^(snrGrid(k)/10);                       % linear
    N0 = 1/sqrt(double(ofdmInfo.Nfft)*SNR);         % time-domain noise scale
    % One first transmission per block, decoded twice.
    for b = 1:nBlocks
        rng(1000*k + b);                             % this block's seed: the same draw for both receivers
        reset(encB4);
        reset(decPerf);
        reset(decPrac);
        setTransportBlock(encB4, randi([0 1], tbs, 1, 'int8'), 0);
        txGrid = nrResourceGrid(carrier);
        txGrid(pdschInd) = nrPDSCH(carrier, pdsch, encB4(pdsch.Modulation, 1, indInfo.G, 0, 0));
        txGrid(dmrsInd) = dmrsSym;
        wave = nrOFDMModulate(carrier, txGrid, Windowing = 0);
        rxGrid = nrOFDMDemodulate(carrier, wave + N0*randn(size(wave), "like", wave), CyclicPrefixFraction = 1);

        % Perfect: H = 1 and the true noise variance per RE.
        softPerf = nrPDSCHDecode(carrier, pdsch, rxGrid(pdschInd), 1/SNR);
        [~, errPerf] = decPerf(softPerf{1}, pdsch.Modulation, 1, 0, 0);

        % Practical: estimate H and the noise from the DM-RS, equalize, then decode.
        [Hest, nVarHat] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym);
        eqSym = nrEqualizeMMSE(rxGrid(pdschInd), Hest(pdschInd), nVarHat);
        softPrac = nrPDSCHDecode(carrier, pdsch, eqSym, nVarHat);
        [~, errPrac] = decPrac(softPrac{1}, pdsch.Modulation, 1, 0, 0);

        nErrPerf(k) = nErrPerf(k) + errPerf;
        nErrPrac(k) = nErrPrac(k) + errPrac;
        nVarMean(k) = nVarMean(k) + nVarHat/nBlocks;
    end
end
blerPerf = nErrPerf/nBlocks;
blerPrac = nErrPrac/nBlocks;

% The 0.1 crossing of each curve, as in B2, or NaN if it does not cross inside the grid.
crossPair = NaN(1, 2);
curves = [blerPerf; blerPrac];
% One crossing per receiver: perfect, then practical.
for c = 1:2
    k2 = find(curves(c, :) < 0.1, 1);
    if ~isempty(k2) && k2 > 1 && curves(c, k2 - 1) >= 0.1
        yLog = log10(max(curves(c, :), 1/(nBlocks + 1)));
        crossPair(c) = snrGrid(k2 - 1) + (-1 - yLog(k2 - 1))/(yLog(k2) - yLog(k2 - 1))*(snrGrid(k2) - snrGrid(k2 - 1));
    end
end

% One test, on the totals over the whole grid: the practical receiver fails at least as often.
okBound = sum(nErrPrac) >= sum(nErrPerf);
assert(okBound, ...
    'Over the whole grid the practical receiver should fail at least as often as the perfect one. If practical < perfect, look first at nVarHat in the table: an underestimated noise makes the soft bits overconfident.');

b4Compare = table(snrGrid(:), blerPerf(:), blerPrac(:), round(nVarMean(:), 4), round(10.^(-snrGrid(:)/10), 4), ...
    VariableNames = {'SNR_dB', 'BLER_Perfect', 'BLER_Practical', 'NoiseEstimate', 'TrueNoise_1overSNR'});
b4Compare
b4Crossings = table(round(crossPair(1), 2), round(crossPair(2), 2), round(crossPair(2) - crossPair(1), 2), ...
    VariableNames = {'Crossing_Perfect_dB', 'Crossing_Practical_dB', 'Shift_dB'});
b4Crossings

% Put your Try-it prediction beside the average noise estimate at the top of the grid.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, round(nVarMean(end), 4), predictionNote, ...
    VariableNames = {'MyPrediction', 'NoiseEstimate_TopSNR', 'Note'});
b4Prediction

% Both waterfalls on one axis, against the 0.1 line.
figure(Name = 'Track 11 B4 - perfect against practical', Color = 'w');
semilogy(snrGrid, max(blerPerf, 1/(nBlocks + 1)), '-o', snrGrid, max(blerPrac, 1/(nBlocks + 1)), '-s');   % 0 counts drawn at 1/(nBlocks+1)
yline(0.1, ':r');
grid on;
legend('perfect (H = 1, true noise)', 'practical (DM-RS estimate)', Location = 'southwest');
xlabel('SNR per RE (dB)');
ylabel('first-transmission BLER');
title('B4: same blocks, same noise, two receivers');
%%
% Over the grid the practical receiver fails at least as often (equal totals 
% also pass: at high SNR both may make no errors at all), and its waterfall 
% sits to the right when both crossings exist: the noise in its estimate costs 
% SNR. Its noise estimate tracks the true 1/SNR, which is how it weighs its 
% soft bits. A shift read from fifty blocks is a sketch; with a thousand blocks 
% per point it would be a measurement. Compare the noise estimate with your 
% prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flag.
b4Checks = table( ...
    "Practical fails at least as often (totals)", ...
    "≥ " + string(sum(nErrPerf)), ...
    string(sum(nErrPrac)), ...
    okBound, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The Build it starts fresh with its own my... values; keep listText.
clear b4Compare b4Crossings b4Checks b4Prediction predictionNote okBound ...
      encB4 decPerf decPrac nErrPerf nErrPrac nVarMean blerPerf blerPrac crossPair curves ...
      k b c k2 yLog SNR N0 txGrid wave rxGrid softPerf errPerf Hest nVarHat eqSym softPrac errPrac ...
      carrier pdsch pdschInd indInfo dmrsInd dmrsSym ofdmInfo tcr tbs rvSeq snrGrid nBlocks myPrediction
%% Build it — From counts to a BLER curve, its 0.1 crossing, and a throughput
% Competency: turn pass and fail counts into a BLER curve, find where it crosses 
% one in ten by interpolating on a log axis, work out how many blocks an honest 
% point needs, and compute the throughput when HARQ costs extra slots.
% Problem
% A classmate sent 200 first transmissions of a 3000-bit transport block at 
% each of five SNR points, 0 to 4 dB, and counted the failures. Turn the counts 
% into BLERs, find the first point below 0.1, and read the 0.1 crossing. Then, 
% at that point, work out the blocks needed for about a hundred errors, and 
% the throughput if every failed block needs exactly one retransmission, which 
% always passes.
% Allowed commands
% x = value and [a b c]; + - * / and ./; find(x < v, 1); log10(x); ceil(x); 
% indexing such as x(k) and x(k - 1). The tables and the figure in the check 
% sections and Stage 5 are given. All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% mySnr = [0 1 2 3 4];             % SNR per RE, dB
% myBlocks = 200;                  % first transmissions per point
% myFail = [190 150 60 12 1];      % failed CRCs per point
% myTbs = 3000;                    % transport block, bits
%% Stage 1 check (given)
if ~exist('mySnr','var') || ~exist('myBlocks','var') || ~exist('myFail','var') || ~exist('myTbs','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal(mySnr, [0 1 2 3 4]) && myBlocks == 200 && isequal(myFail, [190 150 60 12 1]) && myTbs == 3000;
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the four lines you uncommented: the SNRs, 200, the five counts, and 3000.')
    stage1Checks = table("Given values", "0:4 dB, 200, 190 150 60 12 1, 3000", ...
        listText(mySnr) + ", " + myBlocks + ", " + listText(myFail) + ", " + myTbs, okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the BLER curve
% Fill the blanks: the BLER at every point (failures over blocks, entry by 
% entry), and the position of the first point whose BLER is below 0.1.
% Pass: Stage 2 OK.

% myBler = ___ ./ ___;
% myIdx = find(myBler < ___, 1);
%% Stage 2 check (given; the check counts the blocks that passed and works back, a different route from yours)
if ~exist('myBler','var') || ~exist('myIdx','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: one minus the pass fraction, and a loop that stops at the first point below 0.1.
    blerOracle = 1 - (myBlocks - myFail)/myBlocks;
    idxOracle = NaN;
    % Walk the points from the low SNR end; stop at the first BLER below 0.1.
    for n = 1:numel(blerOracle)
        if blerOracle(n) < 0.1
            idxOracle = n;
            break
        end
    end
    okStage2 = [isequal(size(myBler), size(myFail)) && max(abs(myBler - blerOracle)) < 1e-12; ...
                isequal(myIdx, idxOracle)];
    assert(okStage2(1), ...
        'myBler is off. Look first at the division: failures over blocks, with ./ so every point gets its own BLER.')
    assert(okStage2(2), ...
        'myIdx is off. Look first at the threshold: one in ten is 0.1, and find returns a position, not a BLER.')
    stage2Checks = table( ...
        ["BLER at every point"; "First point below 0.1"], ...
        [listText(round(blerOracle, 4)); string(idxOracle)], ...
        [listText(round(myBler, 4)); string(myIdx)], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then the 0.1 crossing
% First type your prediction: the crossing in dB. Then fill the blanks: the 
% crossing between the point before myIdx and myIdx, by the interpolation 
% on log10(BLER) in the Key relationships.
% Pass: your prediction and your value appear side by side in a one-row table, 
% and Stage 3 OK.

% myPrediction = ___;
% myCross = mySnr(myIdx - 1) + (log10(0.1) - log10(myBler(___)))/(log10(myBler(___)) - log10(myBler(myIdx - 1)))*(mySnr(myIdx) - mySnr(myIdx - 1));
%% Stage 3 check (given; the check uses interp1 on the log curve, a different route from yours)
if ~exist('myPrediction','var') || ~exist('myCross','var')
    disp('Stage 3 not done: type your prediction, fill the blanks, uncomment, and run.')
else
    % Your prediction beside your value, in one row.
    stage3Prediction = table(myPrediction, round(myCross, 3), ...
        VariableNames = {'MyPrediction', 'MyCross_dB'});
    stage3Prediction

    % Different route: interp1 on log10(BLER) against SNR (the BLER falls, so the points are flipped to rise).
    crossOracle = interp1(fliplr(log10(blerOracle)), fliplr(mySnr), -1);
    okStage3 = abs(myCross - crossOracle) < 1e-9;
    assert(okStage3, ...
        'myCross is off. Common mistake: interpolating the BLER itself instead of log10(BLER); look first at the two blanks, myIdx - 1 then myIdx.')
    stage3Checks = table("0.1 crossing", string(round(crossOracle, 3)) + " dB", string(round(myCross, 3)) + " dB", okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — honest counting and throughput
% Fill the blanks: the blocks for about a hundred errors at the BLER of point 
% myIdx (rounded up), and the throughput there: every block passes in the 
% end, and every failed first transmission costs one more slot.
% Pass: Stage 4 OK.

% myNeed = ceil(100/___);
% myTput = myBlocks*myTbs/(myBlocks + ___);
%% Stage 4 check (given; the check adds up the bits and the slots one block at a time, a different route from yours)
if ~exist('myNeed','var') || ~exist('myTput','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route 1: add blocks until about 100 errors are expected.
    needOracle = 0;
    % Each block adds BLER expected errors; stop when the expected count reaches 100.
    while needOracle*blerOracle(idxOracle) < 100 - 1e-9
        needOracle = needOracle + 1;
    end
    % Different route 2: passing blocks use one slot, failing ones two; every block brings myTbs bits.
    slotsOracle = (myBlocks - myFail(idxOracle))*1 + myFail(idxOracle)*2;
    tputOracle = myBlocks*myTbs/slotsOracle;
    okStage4 = [myNeed == needOracle; abs(myTput - tputOracle) < 1e-9];
    assert(okStage4(1), ...
        'myNeed is off. Look first at the BLER you divided by: it must be the BLER at myIdx, and ceil rounds up.')
    assert(okStage4(2), ...
        'myTput is off. Common mistake: dividing by myBlocks alone; the failed first transmissions use extra slots.')
    stage4Checks = table( ...
        ["Blocks for about 100 errors"; "Throughput, bits per slot"], ...
        [string(needOracle); string(round(tputOracle, 1))], ...
        [string(myNeed); string(round(myTput, 1))], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myBler','var') || ~exist('myCross','var') || ~exist('myTput','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [all(diff(myBler) < 0); ...
        myBler(myIdx - 1) >= 0.1 && myBler(myIdx) < 0.1; ...
        myCross > mySnr(myIdx - 1) && myCross < mySnr(myIdx); ...
        myTput < myTbs && myTput > (1 - myBler(myIdx))*myTbs; ...
        myNeed*myBler(myIdx) >= 100];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["BLER falls with SNR"; "0.1 lies between points myIdx - 1 and myIdx"; "Crossing inside that interval"; ...
         "Throughput between first-try-only and TBS"; "Enough blocks for 100 errors"], ...
        ["every step down"; "≥ 0.1, then < 0.1"; string(mySnr(myIdx - 1)) + " to " + string(mySnr(myIdx)) + " dB"; ...
         string(round((1 - myBler(myIdx))*myTbs, 1)) + " to " + string(myTbs); "≥ 100 expected errors"], ...
        [listText(round(myBler, 3)); string(myBler(myIdx - 1)) + ", " + string(myBler(myIdx)); string(round(myCross, 3)) + " dB"; ...
         string(round(myTput, 1)); string(round(myNeed*myBler(myIdx), 2))], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: your curve, the 0.1 line, and your crossing.
    figure(Name = 'Track 11 Build it - my waterfall', Color = 'w');
    semilogy(mySnr, myBler, '-o');      % your BLER on a log axis
    yline(0.1, ':r', 'one in ten');
    xline(myCross, '--', 'myCross');
    grid on;
    xlabel('SNR per RE (dB)');
    ylabel('first-transmission BLER');
    title(sprintf('My waterfall: 0.1 crossing at %.2f dB', myCross));
end
%%
% Your interpretation (write one or two sentences here): where does your curve 
% cross one in ten, and why read it on a log axis? Is 200 blocks per point 
% enough at that crossing, and what did HARQ cost in throughput there?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks blerOracle idxOracle n okStage2 stage2Checks ...
      stage3Prediction crossOracle okStage3 stage3Checks ...
      needOracle slotsOracle tputOracle okStage4 stage4Checks ...
      buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B3)
% How many blocks give about a hundred errors at a BLER of one in a hundred, 
% and at one in ten thousand? At one block per 1 ms slot, how long is each 
% in real time (give the second in hours)? What changes, and what does not, 
% if 8 HARQ processes run in parallel?
% 
% Your answer:
% E2 — New values (Build it)
% At 2 dB in the Build it, work out the throughput if every failed block needs 
% exactly one retransmission that always passes, and the throughput with no 
% HARQ at all (failed blocks are lost). Which is higher, and why can HARQ not 
% make a link with a high first-transmission BLER efficient?
% 
% Your answer:
% E3 — Diagnosis (B2)
% A classmate moves reset(dec) inside the loop over redundancy versions. About 
% how many slots would the SlotsUsed column show at −2 dB with this bug, and 
% why?
% 
% Your answer:
% E4 — Explanation (B2 and B3)
% Explain why the CQI target is set on the first-transmission BLER rather 
% than the BLER after HARQ, and why aiming at one in ten, rather than one in 
% a thousand, usually gives more throughput.
% 
% Your answer:
% E5 — Diagnosis (B1)
% An earlier version of this demo added noise as 10^(−snrdB/20)*sqrt(mean(abs(wave).^2)/2)*(randn + 1j*randn) 
% and passed 10^(−snrdB/10)*mean(abs(wave).^2) to nrPDSCHDecode as the noise 
% variance. Name the two problems for a 24-PRB allocation on a 52-RB carrier, 
% and say in which direction each one moves the waterfall or the decoder's 
% confidence.
% 
% Your answer:
% E6 — Explanation (B4)
% The practical receiver estimates the channel from one DM-RS symbol. Adding 
% a second DM-RS symbol (AdditionalPosition = 1) improves the estimate but 
% costs data REs. Work out the NREPerPRB and the TBS at rate 0.48 on the same 
% 24 PRBs with the second DM-RS symbol, and say when the trade is worth it.
% 
% Your answer:
%% Recap — One in Ten (album track 11)
% One loop ties the album together: transport block, coding, modulation, 
% OFDM, noise, and the receiver back to the CRC. Count passes and failures 
% at every SNR and the BLER falls in a waterfall. The phone reports the highest 
% CQI whose first transmission would fail about one block in ten; HARQ pushes 
% the residual BLER lower at the cost of extra slots. Count enough errors, 
% reuse seeds, and treat perfect channel knowledge as a bound.
% Key relationships
% $$\mathrm{BLER} = \frac{\text{failed}}{\text{sent}},\qquad N_0 = \frac{1}{\sqrt{N_{\mathrm{FFT}}\,\mathrm{SNR}}},\qquad 
% s_{0.1} = s_1 + \frac{-1 - \log_{10}B_1}{\log_{10}B_2 - \log_{10}B_1}(s_2 - s_1)$$
% What this means in practice
% • Pass one slot at high SNR before any sweep.
% 
% • Scale the noise per RE with ofdmInfo.Nfft and pass 1/SNR to nrPDSCHDecode, 
% as the toolbox link examples do.
% 
% • Read the first-transmission BLER against 0.1 on a log axis; keep HARQ 
% in the loop for throughput.
% 
% • nrCQITables gives TargetCodeRate already divided by 1024.
% 
% • Compare receivers on the same seeds, and on totals or crossings, not single 
% points.
% 
% • You turned counts into a BLER curve, read its 0.1 crossing on a log axis, 
% and worked out the blocks and the throughput at that point.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 10 (track10/track10_sound_it_out_demo), what does the phone measure 
% to work out the CQI it reports, and why can it not just reuse the SRS?
% 
% • Next in the album: track12 (How Far).
%% Review — self-check
% Do this without looking at the header. Scroll down so the top of the file 
% is out of sight, then write from memory, in your own words.
% 
% First, each of the seven key ideas, one line each. Then, for each command 
% you write yourself (listed below by name only), its purpose, its inputs, and 
% its outputs.
% 
% When you have written all you can, scroll up to Key ideas to remember and 
% Key code terms to remember and compare. Mark anything you missed or got wrong, 
% and reread the beat where it was used. The commands you read, the families 
% of helpers, and the short lists at the start of each beat are not part of 
% this review: tick them against their lists, or look one up when you meet it 
% again. Nothing in this section is checked by the script.
% My key ideas
% 1.
% 
% 2.
% 
% 3.
% 
% 4.
% 
% 5.
% 
% 6.
% 
% 7.
% Commands I write (purpose; inputs; outputs)
% • x = value and [a b c]:
% 
% • + - * / and ./:
% 
% • find(x < v, 1):
% 
% • log10(x):
% 
% • ceil(x):
% What I missed, and where to reread it
% 
