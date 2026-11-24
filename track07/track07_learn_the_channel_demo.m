%% track07_learn_the_channel_demo
%% Learn the Channel (album track 07): pilots, channel estimation, and equalization
% The grid went out clean, and it came back bent. Every tone got a gain and 
% a twist on the way. To undo that, the receiver first has to measure it.
% 
% This demonstration estimates a channel from a handful of known symbols, 
% the DM-RS pilots, then undoes it without making the noise worse, and hands 
% soft bits to the decoder.
%% Guiding question
% How does a phone that knows only a few pilot symbols learn the gain on every 
% resource element, and how does it undo that gain without boosting the noise?
% This demonstration
% 1. B1 — Pilots and the raw ratio: received over sent, on the DM-RS REs only.
% 
% 2. B2 — Average and interpolate with nrChannelEstimate, and grade it against 
% the perfect channel on the data REs.
% 
% 3. B3 — Zero forcing against MMSE: where the channel fades, ZF boosts the 
% noise and MMSE backs off.
% 
% 4. B4 — Soft bits out: the equalizer's reliability goes into the LLRs the 
% decoder reads.
% 
% 5. Build it — Estimate a channel from six pilots by hand and equalize one 
% faded RE both ways.
% Key relationships
% On a pilot RE the receiver knows what was sent, X_p, so the raw estimate 
% is the received value over the sent one:
% 
% $$\hat{H}_p = \frac{Y_p}{X_p} = H_p + \frac{N_p}{X_p}$$
% 
% For one data RE with estimate h and noise variance σ², the textbook one-tap 
% equalizers are
% 
% $$\hat{x}_{\mathrm{ZF}} = \frac{y}{h},\qquad \hat{x}_{\mathrm{MMSE}} = \frac{h^{*}\,y}{|h|^{2}+\sigma^{2}} 
% = \hat{x}_{\mathrm{ZF}}\cdot \frac{|h|^{2}}{|h|^{2}+\sigma^{2}}$$
% Key ideas to remember
% • The phone knows only the DM-RS symbols. Here they sit on 6 of the 12 subcarriers 
% in each PRB, on two OFDM symbols: 624 of the slot's 8736 REs.
% 
% • On a pilot RE, received over sent is the channel plus noise. One raw ratio 
% is a noisy sample, not yet an estimate.
% 
% • An estimator averages neighbouring pilots to cut the noise, then interpolates 
% so that every data RE has a channel value. Grade it on the data REs, not 
% just on the pilots.
% 
% • nrChannelEstimate returns the estimate for the whole grid and an estimate 
% of the noise variance; nrPerfectChannelEstimate gives the true channel for 
% grading in a simulation.
% 
% • Zero forcing divides by h. Where |h| is small, it divides the noise by 
% a small number too.
% 
% • MMSE multiplies the ZF answer by |h|² / (|h|² + σ²): close to 1 on strong 
% REs, small in deep fades. It is better on average, not on every RE.
% 
% • The decoder wants soft bits whose size is a confidence. Weighting the LLRs 
% by the equalizer's csi tells it which REs sat in a fade.
% Prerequisites
% • The resource grid, PDSCH and DM-RS indices, and NREPerPRB (album track 05 
% Say It Again, track05/track05_say_it_again_demo).
% 
% • TDL channels, delay spread, and path gains (album track 06 Taps in Time, 
% track06/track06_taps_in_time_demo). Here the channel is simply "some multipath".
% 
% • LLRs and what their sign and size mean (track 00 Fundamentals, track00_fundamentals/p00b_softbits_and_dynamics_demo), 
% and the OFDM grid (track00_fundamentals/p00a_ofdm_and_cp_demo).
% 
% • Used here, not taught here: the LDPC decoder that reads these LLRs is 
% album track 04 (Every Check Agrees); the full link with BLER curves is album 
% track 11 (One in Ten).
% Words used in this demo
% • Pilot / reference signal: a symbol the receiver knows in advance. DM-RS 
% (demodulation reference signal): the PDSCH's pilots.
% 
% • Raw estimate (the raw ratio): Y_p / X_p on one pilot RE. Often called 
% the least-squares (LS) estimate.
% 
% • Interpolation: filling the REs between pilots from the pilots around them. 
% Extrapolation: the same past the last pilot, which is less reliable.
% 
% • Equalization: undoing the channel on each data RE. ZF (zero forcing): 
% divide by h. MMSE (minimum mean-squared error): divide by h, then shrink 
% where the noise wins.
% 
% • EVM (error vector magnitude): the RMS error of the equalized symbols as 
% a percentage of the RMS sent symbol.
% 
% • csi (channel state information, here): the equalizer's per-RE reliability, 
% large on strong REs and small in fades.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • x = value — Purpose: store a value under a name. Inputs: a name, then a 
% value or expression. Outputs: the variable x.
% 
% • + - * / and ./ — Purpose: arithmetic, and division entry by entry. Inputs: 
% numbers or arrays of the same size. Outputs: the result.
% 
% • x(idx) — Purpose: pick entries by position. Inputs: an array and a list 
% of positions. Outputs: those entries.
% 
% • hi = interp1(xKnown, yKnown, xWanted, 'linear', 'extrap') — Purpose: fill 
% in values between (and past) known points on straight lines. Inputs: the 
% known positions, their values (complex is fine), the positions wanted, the 
% method, and 'extrap' to allow points past the ends. Outputs: one value per 
% wanted position.
% 
% • conj(z) and abs(z) — Purpose: the complex conjugate; the magnitude. Inputs: 
% complex numbers. Outputs: complex numbers; real, non-negative numbers.
% 
% • z^2 — Purpose: a square. Inputs: a number. Outputs: the number times itself.
% 
% Commands you read in the given code
% • [h, nVar] = nrChannelEstimate(carrier, rxGrid, refInd, refSym) — Purpose: 
% estimate the channel on the whole grid from reference symbols. Inputs: the 
% carrier, the received grid, the pilot indices, and the pilot symbols. Outputs: 
% the estimate (one value per RE) and a noise-variance estimate. Used in B2.
% 
% • h = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset) — 
% Purpose: the true channel on the grid, for grading. Inputs: the carrier, 
% the channel's path gains and filters, and the timing offset. Outputs: one 
% value per RE. Used in B2.
% 
% • [eqSym, csi] = nrEqualizeMMSE(rxSym, hest, nVar) — Purpose: MMSE equalization. 
% Inputs: received data symbols, their channel estimates, and the noise variance. 
% Outputs: equalized symbols and per-RE reliability. Used in B3 and B4.
% 
% • cws = nrPDSCHDecode(carrier, pdsch, sym, nVar) — Purpose: demodulate and 
% descramble PDSCH symbols into soft bits. Inputs: the carrier, the PDSCH, 
% the symbols, and the noise variance. Outputs: a cell array of LLR columns. 
% Used in B4.
% 
% • As in album track 05: nrCarrierConfig, nrPDSCHConfig, nrPDSCHIndices, nrPDSCHDMRSIndices, 
% nrPDSCHDMRS, nrPDSCH, nrResourceGrid. As in album track 06: nrTDLChannel 
% and info. As in album track 02: nrOFDMInfo, nrOFDMModulate, nrOFDMDemodulate. 
% Used in the Setup section.
% 
% • Figure family: figure(Name = ...), plot, semilogy, histogram, stem, axis 
% equal, xlabel, ylabel, title, legend, grid on, hold on — Purpose: draw points, 
% lines, or counts, label them, and name the figure. Inputs: data and text. 
% Outputs: a figure. Used in every beat and Build it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, x(:), x.', x(end), c{n}, s.name, A(:, 
% n) — Purpose: read entries, count a range, reshape, read a cell or a field, 
% pick one column. Inputs: an array and positions. Outputs: the entries.
% 
% • Compare and combine: == ~= < > <= >=, && ||, .* ./ .^ — Purpose: compare 
% values; and, or; work entry by entry. Inputs: numbers or arrays. Outputs: 
% true/false or numbers.
% 
% • Control flow: if ... else ... end — Purpose: run one block or the other. 
% Inputs: a true/false test. Outputs: whatever the blocks store.
% 
% • Built-in helpers: real, imag, sqrt, mean, sum, rms, std, max, min, sort, 
% numel, size, reshape, repmat, randi, randn, complex, isequal, islogical, 
% exist, isnan, NaN, round, double — Purpose: parts and sizes of numbers, 
% averages, sorting, shapes, random values, comparisons, look a name up. Inputs: 
% numbers, arrays, or names. Outputs: numbers, arrays, or true/false (NaN means 
% "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, sprintf, and f = @(v) 
% ... — Purpose: write and join text, turn numbers into text, fill a format, 
% and make a one-line helper such as listText or evmPct. Inputs: text, numbers, 
% a format. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), fprintf, disp, clear, close all, rng — Purpose: show columns side 
% by side, stop with a hint when a check fails, print a banner or note, remove 
% variables or figures, repeat random values. Inputs: columns, a test and message, 
% text, names, a seed. Outputs: a shown table or line; an error if a check fails.
% Working status
% Status: unverified until M runs it in R2024b.
% 
% Teaching draft built to the track01 r03 template (track07 r01, 2026-11-20) 
% from the live track07_demo.m on main d3b954c. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox. The 
% estimator inside nrChannelEstimate is not named on its documentation page 
% (this file calls the raw ratio "LS" as a lecture name only), and the exact 
% formula inside nrEqualizeMMSE is not printed there either: the textbook one-tap 
% forms above are for teaching. Teaching demo, not production code; not affiliated 
% with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year): the same bits and noise each run

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% evmPct gives the error vector magnitude in percent: the RMS of (received
% minus sent) over the RMS of sent. Kept to the end of B3, which uses it.
evmPct = @(ref, rx) 100*sqrt(sum(abs(rx(:) - ref(:)).^2) / sum(abs(ref(:)).^2));
%% Setup — one PDSCH slot through a multipath channel (given)
% Read this section; you do not change it. It builds the slot B1 to B4 work 
% on: a QPSK PDSCH on all 52 PRBs with its DM-RS, sent through a TDL-C channel 
% (album track 06) with noise at a set SNR per RE, then demodulated back to 
% a received grid. The perfect timing offset is used, so timing is not a question 
% here.

% The carrier and the PDSCH (album track 05).
carrier = nrCarrierConfig(SubcarrierSpacing = 15, ...   % subcarrier spacing, kHz
                          NSizeGrid = 52, ...           % carrier width, RBs (9.36 MHz)
                          NCellID = 1);                 % cell ID (sets the scrambling)
pdsch = nrPDSCHConfig;
pdsch.PRBSet = 0:51;                          % all 52 PRBs, zero-based
pdsch.Modulation = 'QPSK';                    % 2 bits per symbol
pdsch.SymbolAllocation = [2 12];              % start at symbol 2, 12 symbols long (symbols 2 to 13)
pdsch.DMRS = nrPDSCHDMRSConfig;               % default DM-RS: type 1, type A position 2
pdsch.DMRS.DMRSAdditionalPosition = 1;        % one extra DM-RS symbol (symbol 11)

% Indices, pilots, and the sent grid: DM-RS on its REs, random coded bits
% (standing in for an LDPC codeword) mapped onto the PDSCH REs.
[pdschInd, indInfo] = nrPDSCHIndices(carrier, pdsch);   % PDSCH RE positions; indInfo.G = coded bits
dmrsInd = nrPDSCHDMRSIndices(carrier, pdsch);           % DM-RS RE positions
dmrsSym = nrPDSCHDMRS(carrier, pdsch);                  % the known pilot symbols
txGrid = nrResourceGrid(carrier);                       % empty 624 × 14 slot grid
txGrid(dmrsInd) = dmrsSym;
cw = randi([0 1], indInfo.G, 1);                        % G random bits, one per coded bit
txGrid(pdschInd) = nrPDSCH(carrier, pdsch, cw);

% The channel: TDL-C at 300 ns over 9.36 MHz, so some subcarriers fade deeply
% (that is where ZF and MMSE differ in B3). No motion, one antenna each end.
snrdB = 12;                                   % SNR per resource element, dB
ofdmInfo = nrOFDMInfo(carrier);               % sample rate and FFT size (album track 02)
tdl = nrTDLChannel(DelayProfile = "TDL-C", ...          % 24-tap NLOS profile
                   DelaySpread = 300e-9, ...            % RMS delay spread, s
                   MaximumDopplerShift = 0, ...         % no motion, Hz
                   SampleRate = ofdmInfo.SampleRate);   % 15.36 MHz
tdl.NumTransmitAntennas = 1;                  % one transmit antenna
tdl.NumReceiveAntennas  = 1;                  % one receive antenna

% Send it: OFDM-modulate, pad with zeros so the latest echo comes out, fade.
wave = nrOFDMModulate(carrier, txGrid);
maxChDelay = info(tdl).MaximumChannelDelay;             % longest channel delay, samples
[rxWave, pathGains] = tdl([wave; zeros(maxChDelay, 1)]);
pathFilters = getPathFilters(tdl);                      % the channel's filter taps, for timing and the perfect estimate
offset = nrPerfectTimingEstimate(pathGains, pathFilters);   % timing offset, samples

% Noise scaled so that each RE of the demodulated grid has SNR = snrdB
% (the scaling the 5G Toolbox examples use: 1/sqrt(2 Nfft SNR) per part).
snrLin = 10^(snrdB/10);                                 % SNR per RE, linear
N0 = 1/sqrt(2*double(ofdmInfo.Nfft)*snrLin);            % noise amplitude per real and imaginary part
rxWave = rxWave + N0*complex(randn(size(rxWave)), randn(size(rxWave)));
nVarTrue = 1/snrLin;                                    % the noise variance per RE this sets (unit-power symbols)

% Receive: drop the timing offset and OFDM-demodulate back to a grid.
rxGrid = nrOFDMDemodulate(carrier, rxWave(1+offset:end, :));   % 624 × 14 received grid
%% B1 — Pilots and the raw ratio
% New words
% • DM-RS RE: a resource element that carries a pilot. Here DM-RS type 1 puts 
% pilots on every other subcarrier (6 per PRB) on each DM-RS symbol.
% 
% • Raw ratio: received over sent on one pilot RE, Y_p / X_p.
% Why it matters
% The phone does not start with a full grid of known symbols. It knows only 
% the DM-RS. The raw ratio on those REs is its first picture of H; everything 
% after it is averaging and interpolation. Without H the received constellation 
% is rotated and scaled on each tone, so a fixed decision grid fails: coherent 
% detection needs H.
% What to look for
% • In the pilots table: how many DM-RS REs there are, and what fraction of 
% the slot's REs that is.
% 
% • In the figure: the raw ratios are not one point. They spread out because 
% the channel changes across frequency, and noise adds to each one.
% Common mistakes
% Do not divide every RE by its data symbol and call that the estimate: the 
% phone does not know the data yet. Only the pilots are known.
% 
% Do not expect halving the PRBs to change the pilot density: the DM-RS type 
% fixes the pilots per PRB; extra DM-RS symbols add pilots in time.
% Try it (personal exploration)
% Predict how many DM-RS REs the same PDSCH has with DMRSAdditionalPosition 
% = 2 (one more DM-RS symbol). Type it into myPrediction before you run this 
% section; the one-row table at the end counts them on a copy of the PDSCH, 
% so the slot B2 to B4 use does not change.

% Try it: type your prediction here (a number of REs) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Pilots and the raw ratio
fprintf("B1 — Pilots and the raw ratio\n");   % banner title only; every number below goes into a table

% The raw ratio: received over sent, on the pilot REs only.
rawH = rxGrid(dmrsInd) ./ dmrsSym;            % one raw channel sample per DM-RS RE

% Two tests: the pilot count is 6 REs per PRB on each of the two DM-RS
% symbols, and the sent grid holds the known pilots on those REs.
nDmrsExpected = 6*numel(pdsch.PRBSet)*2;      % REs: 6 per PRB per DM-RS symbol × 52 PRBs × 2 symbols
okCount = numel(dmrsInd) == nDmrsExpected;
assert(okCount, ...
    'The DM-RS RE count is off. Look first at DMRSAdditionalPosition in Setup: 1 means two DM-RS symbols.');
okPlaced = isequal(txGrid(dmrsInd), dmrsSym);
assert(okPlaced, ...
    'The sent grid does not hold the pilots. Common mistake: writing the PDSCH symbols over the DM-RS REs.');

% The pilots in numbers: how many, how sparse, and how spread the raw ratios are.
b1Pilots = table(numel(dmrsInd), numel(txGrid), numel(dmrsInd)/numel(txGrid), ...
    mean(abs(rawH)), std(abs(rawH)), ...
    VariableNames = {'DMRS_REs', 'Grid_REs', 'Fraction', 'MeanRawMag', 'StdRawMag'});
b1Pilots

% Put your Try-it prediction beside the count on a copy with one more DM-RS symbol.
pdschTry = nrPDSCHConfig;                     % a fresh PDSCH, so the one B2 to B4 use stays as it is
pdschTry.PRBSet = pdsch.PRBSet;               % same 52 PRBs
pdschTry.Modulation = pdsch.Modulation;       % same modulation
pdschTry.SymbolAllocation = pdsch.SymbolAllocation;   % same symbols 2 to 13
pdschTry.DMRS.DMRSAdditionalPosition = 2;     % two extra DM-RS symbols
tryCount = numel(nrPDSCHDMRSIndices(carrier, pdschTry));   % DM-RS REs on the fresh PDSCH
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, tryCount, predictionNote, ...
    VariableNames = {'MyPrediction', 'DMRS_REs_AddPos2', 'Note'});
b1Prediction

% The raw ratios in the complex plane: each dot is one pilot RE's channel sample.
figure(Name = 'Track 07 B1 - raw pilot ratios', Color = 'w');
plot(real(rawH), imag(rawH), '.');            % one dot per DM-RS RE
axis equal;
grid on;
xlabel('I');
ylabel('Q');
title('B1: raw Y_p / X_p on the DM-RS REs');
%%
% The pilots are a small fraction of the slot, so most REs have no direct 
% measurement. The raw ratios are spread out: across 52 PRBs this channel turns 
% and scales each tone differently, and every ratio carries its own noise. 
% Compare the count on the copy with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["DM-RS REs = 6 × PRBs × DM-RS symbols"; ...
     "Sent grid holds the pilots"], ...
    [string(nDmrsExpected); "true"], ...
    [string(numel(dmrsInd)); string(okPlaced)], ...
    [okCount; okPlaced], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep the Setup slot (carrier, pdsch, indices, grids, channel outputs) and
% rawH: B2 compares the estimate with it. Everything else was only for B1.
clear b1Pilots b1Checks b1Prediction predictionNote okCount okPlaced nDmrsExpected ...
      pdschTry tryCount myPrediction
%% B2 — Average, interpolate, grade
% New words
% • Averaging window: how many neighbouring pilots are averaged before interpolation.
% 
% • Perfect channel estimate: the true channel on every RE, available only 
% in a simulation, for grading.
% Beat-only commands
% • rms(x) — Purpose: the root mean square. Inputs: an array. Outputs: a number.
% Why it matters
% One noisy ratio per pilot is not an estimate. Averaging neighbours cuts the 
% noise; interpolating fills the REs in between, so every data RE has an H. 
% nrChannelEstimate does both from the pilot indices and symbols, and returns 
% a noise-variance estimate too. Its pre-interpolation step is often called 
% least squares; the documentation page does not name it, so here LS is only 
% the lecture name for the raw ratio.
% What to look for
% • In the errors table: the raw ratio's error on the pilots against the estimate's 
% error on the same pilots, then the estimate's error on the data REs.
% 
% • The noise-variance estimate next to the value Setup used.
% 
% • In the figure: the estimate following the perfect channel across the band, 
% including the dips.
% Common mistakes
% Do not treat the noise-variance estimate as exact: it is estimated from the 
% same pilots.
% Try it (personal exploration)
% The estimate covers the whole slot grid, 624 subcarriers × 14 symbols. Suppose 
% the slot used the B1 Try's DM-RS setting instead (DMRSAdditionalPosition 
% = 2). Predict how many REs of the estimate there would be for each DM-RS 
% RE. Type it into myPrediction before you run this section; the one-row table 
% at the end works it out on a fresh PDSCH with that setting.

% Try it: type your prediction here (a ratio) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Average, interpolate, grade
fprintf("B2 — Average, interpolate, grade\n");   % banner title only; every number below goes into a table

% The practical estimate from the pilots, and the true channel for grading
% (the documented pattern: the path gains, the path filters, the same offset).
[Hest, nVar] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym);   % estimate on every RE; noise-variance estimate
Hperf = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset);   % true channel on every RE

% RMS errors: the raw ratio on the pilots, the estimate on the pilots, and
% the estimate on the data REs.
errRawPilot = rms(rawH - Hperf(dmrsInd));               % raw ratio error on the pilots
errEstPilot = rms(Hest(dmrsInd) - Hperf(dmrsInd));      % estimate error on the pilots
errEstData  = rms(Hest(pdschInd) - Hperf(pdschInd));    % estimate error on the data REs

% Two tests: the estimate covers every RE of the grid, and averaging beats
% the raw ratio on the pilots themselves.
okFull = isequal(size(Hest), size(rxGrid));
assert(okFull, ...
    'The estimate is not the size of the grid. Look first at the inputs: the received grid, then the DM-RS indices and symbols.');
okAverages = errEstPilot < errRawPilot;
assert(okAverages, ...
    'The estimate is no better than the raw ratio on the pilots. Common mistake: passing the PDSCH indices instead of the DM-RS indices.');

b2Errors = table(errRawPilot, errEstPilot, errEstData, nVar, nVarTrue, ...
    VariableNames = {'RawRatio_onPilots', 'Estimate_onPilots', 'Estimate_onData', 'nVar_estimated', 'nVar_Setup'});
b2Errors

% Put your Try-it prediction beside the REs per pilot.
pdschTry = nrPDSCHConfig;                     % a fresh PDSCH with the B1 Try's DM-RS setting
pdschTry.PRBSet = pdsch.PRBSet;               % same 52 PRBs
pdschTry.SymbolAllocation = pdsch.SymbolAllocation;   % same symbols 2 to 13
pdschTry.DMRS.DMRSAdditionalPosition = 2;     % three DM-RS symbols
tryRatio = numel(Hest)/numel(nrPDSCHDMRSIndices(carrier, pdschTry));   % estimate REs per DM-RS RE
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, tryRatio, predictionNote, ...
    VariableNames = {'MyPrediction', 'REsPerPilot', 'Note'});
b2Prediction

% The estimate against the true channel across frequency, on symbol 3 (a data symbol).
figure(Name = 'Track 07 B2 - estimate vs perfect', Color = 'w');
plot(abs(Hperf(:, 4)), 'k-');                 % true |H|, column 4 = OFDM symbol 3
hold on;
plot(abs(Hest(:, 4)), 'r--');                 % estimated |H| on the same symbol
grid on;
xlabel('subcarrier');
ylabel('|H|');
legend('perfect', 'nrChannelEstimate');
title('B2: interpolated |H| across frequency, symbol 3');
%%
% Averaging pulls the estimate closer to the true channel than the raw ratios 
% on the same pilots. The error on the data REs includes the interpolation 
% error as well: compare it with the pilot error before you trust a pilot-only 
% grade. Read the noise-variance estimate against the Setup value: close, not 
% equal. Compare the REs per pilot with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Estimate is the size of the grid"; ...
     "Estimate beats the raw ratio on the pilots"], ...
    [listText(size(rxGrid)); "estimate error < " + string(round(errRawPilot, 4))], ...
    [listText(size(Hest)); string(round(errEstPilot, 4))], ...
    [okFull; okAverages], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep Hest and nVar (B3 and B4 equalize with them) and the Setup slot.
% Hperf, rawH, and the errors were only for grading B2.
clear b2Errors b2Checks b2Prediction predictionNote okFull okAverages ...
      errRawPilot errEstPilot errEstData Hperf rawH pdschTry tryRatio myPrediction
%% B3 — Zero forcing against MMSE
% New words
% • Zero forcing (ZF): divide each data RE by its channel estimate.
% 
% • MMSE equalizer: divide by the estimate, then shrink by |h|² / (|h|² + σ²).
% 
% • Weakest REs: here, the tenth of the PDSCH REs with the smallest estimated 
% |H|.
% Beat-only commands
% • sort(x) with [~, idx] = sort(...) — Purpose: put values in order and get 
% their positions. Inputs: an array. Outputs: the sorted values and the positions.
% Why it matters
% Zero forcing divides out H, and divides the noise by H too: wherever |H| 
% is small, the noise is boosted. MMSE shrinks those REs on purpose. On a strong 
% RE the two give almost the same answer; in a fade MMSE gives up a little 
% bias to avoid a large noise boost, so its error is smaller on average.
% What to look for
% • In the EVM table: the EVM after ZF and after MMSE over all PDSCH REs, then 
% the RMS error on the weakest REs only.
% 
% • In the figure: the per-RE error against |H|. Where |H| is small, the ZF 
% errors climb and the MMSE errors level off.
% Common mistakes
% Do not call MMSE "better on every RE": it is better on average; on a strong 
% RE the two are almost the same, and one RE can go either way.
% 
% Do not compare equalizers with different noise-variance inputs: both use 
% the same estimate and the same nVar here.
% Try it (personal exploration)
% Use the textbook forms in Key relationships for one RE with |h| = 0.2 and 
% σ² = 0.05. ZF multiplies y by 1/|h| = 5 in size. Predict the size of the 
% MMSE multiplier, |h| / (|h|² + σ²). Type it into myPrediction before you 
% run this section; the one-row table at the end works it out, and also reads 
% what nrEqualizeMMSE gives for the same RE (read, not checked).

% Try it: type your prediction here (a multiplier) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Zero forcing against MMSE
fprintf("B3 — Zero forcing against MMSE\n");   % banner title only; every number below goes into a table

% The data REs and their estimates, then both equalizers on the same inputs.
rxPdsch = rxGrid(pdschInd);                   % received data symbols
Hpdsch  = Hest(pdschInd);                     % their channel estimates
txPdsch = txGrid(pdschInd);                   % what was sent, for grading only
zf = rxPdsch ./ Hpdsch;                       % one-tap ZF
[mmse, csi] = nrEqualizeMMSE(rxPdsch, Hpdsch, nVar);   % MMSE, and its per-RE reliability

% The weakest tenth of the REs by estimated |H|: where the two should differ.
[~, order] = sort(abs(Hpdsch));               % positions from weakest to strongest
weak = order(1:round(numel(order)/10));       % the weakest 10 %
errZFweak   = rms(zf(weak) - txPdsch(weak));  % ZF RMS error on the weakest REs
errMMSEweak = rms(mmse(weak) - txPdsch(weak));   % MMSE RMS error on the weakest REs

% Two tests: MMSE returns one symbol and one non-negative reliability per
% RE, and on the weakest REs its error is smaller than ZF's.
okShapes = numel(mmse) == numel(rxPdsch) && numel(csi) == numel(rxPdsch) && all(csi >= 0);
assert(okShapes, ...
    'MMSE output sizes are off. Look first at the inputs: the PDSCH symbols and their estimates, both from pdschInd.');
okFades = errMMSEweak < errZFweak;
assert(okFades, ...
    'MMSE did not beat ZF on the weakest REs. Common mistake: passing a noise variance of 0, which turns MMSE into ZF.');

b3EVM = table(evmPct(txPdsch, zf), evmPct(txPdsch, mmse), errZFweak, errMMSEweak, numel(weak), ...
    VariableNames = {'EVM_ZF_pct', 'EVM_MMSE_pct', 'RMSerr_ZF_weakest', 'RMSerr_MMSE_weakest', 'WeakestREs'});
b3EVM

% Put your Try-it prediction beside the textbook multiplier, and read the toolbox's.
tryH = 0.2;                                   % channel magnitude on one RE
tryNVar = 0.05;                               % noise variance
tryMMSE = tryH/(tryH^2 + tryNVar);            % textbook MMSE multiplier size
tryTool = abs(nrEqualizeMMSE(1, tryH, tryNVar));   % nrEqualizeMMSE on y = 1 with h = 0.2 (read, not checked)
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the numbers";
end
b3Prediction = table(myPrediction, round(tryMMSE, 3), round(tryTool, 3), 1/tryH, predictionNote, ...
    VariableNames = {'MyPrediction', 'Textbook_MMSE', 'nrEqualizeMMSE_read', 'ZF', 'Note'});
b3Prediction

% Per-RE error against the estimated |H|: ZF blows up in fades, MMSE levels off.
figure(Name = 'Track 07 B3 - ZF vs MMSE in fades', Color = 'w');
semilogy(abs(Hpdsch), abs(zf - txPdsch), '.', abs(Hpdsch), abs(mmse - txPdsch), '.');   % one dot per RE per equalizer
grid on;
xlabel('|H_{est}| on the RE');
ylabel('|error|');
legend('ZF', 'MMSE');
title('B3: per-RE error against channel magnitude');
%%
% On the weakest REs, MMSE's error is smaller than ZF's: ZF divides the noise 
% by a small |H|, and MMSE shrinks those REs instead. Over all REs the EVMs 
% are closer, because most REs are strong and there the two nearly agree. 
% Read the figure from left to right to see where they part. Compare the multiplier 
% with your prediction, and the toolbox value with the textbook one.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["One symbol and one csi >= 0 per RE"; ...
     "MMSE error < ZF error on the weakest REs"], ...
    [string(numel(rxPdsch)) + " each"; "MMSE < " + string(round(errZFweak, 4))], ...
    [string(numel(mmse)) + " and " + string(numel(csi)); string(round(errMMSEweak, 4))], ...
    [okShapes; okFades], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep rxPdsch, mmse, csi, and Hpdsch: B4 decodes them and ranks by Hpdsch. evmPct is no longer needed.
clear b3EVM b3Checks b3Prediction predictionNote okShapes okFades ...
      txPdsch zf order weak errZFweak errMMSEweak ...
      tryH tryNVar tryMMSE tryTool evmPct myPrediction
%% B4 — Soft bits out
% New words
% • csi weighting: multiplying each RE's LLRs by its csi, so faded REs speak 
% more quietly to the decoder.
% Beat-only commands
% • repmat(A, m, n) — Purpose: repeat an array. Inputs: the array and the repeat 
% counts. Outputs: the bigger array.
% 
% • histogram(x, n) — Purpose: count values in n bins. Inputs: data and a bin 
% count. Outputs: a figure.
% Why it matters
% The decoder does not want equalized symbols; it wants soft bits whose size 
% is a confidence. nrPDSCHDecode turns the MMSE symbols and the noise variance 
% into LLRs; weighting them by csi tells the decoder which REs sat in a fade. 
% These LLRs are what the LDPC decoder of album track 04 reads (the song's 
% "decoder from last time" is that album track 04 decoder; here cw is 
% random bits standing in for a codeword, so raw bit errors are counted instead).
% What to look for
% • In the bits table: the bit errors from the equalized soft bits against 
% decoding the raw, unequalized symbols (the mistake).
% 
% • The mean |LLR| on the weakest REs against the strongest.
% 
% • In the histogram: two humps for bit 0 and bit 1, and the small LLRs near 
% zero from faded REs.
% Common mistakes
% Do not throw away the noise variance or the channel estimate and decode as 
% if every symbol were equally reliable.
% 
% Do not read a large |LLR| as a correct bit: a wrong noise variance rescales 
% every LLR.
% Try it (personal exploration)
% Decode the same MMSE symbols with a noise variance ten times too small. Predict 
% how many times larger the mean |LLR| gets. Type it into myPrediction before 
% you run this section; the one-row table at the end works it out, with the 
% number of bits whose sign changes.

% Try it: type your prediction here (a ratio) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Soft bits out
fprintf("B4 — Soft bits out\n");   % banner title only; every number below goes into a table

% Soft bits from the MMSE symbols, weighted by each RE's csi: Qm LLRs per RE,
% so each csi value is repeated Qm times in the bit order.
soft = nrPDSCHDecode(carrier, pdsch, mmse, nVar);   % cell array: one LLR column per codeword
Qm = numel(soft{1}) / numel(mmse);            % bits per symbol (2 for QPSK)
csiBits = repmat(csi(:).', Qm, 1);            % Qm rows: one copy of each RE's csi per bit
llr = soft{1} .* csiBits(:);                  % csi-weighted LLRs, in bit order
nErrEq = sum((llr < 0) ~= cw);                % bit errors: a negative LLR means bit 1

% The mistake: decode the received symbols with no equalization.
softRaw = nrPDSCHDecode(carrier, pdsch, rxPdsch, nVar);
nErrRaw = sum((softRaw{1} < 0) ~= cw);        % bit errors without equalization

% Mean unweighted |LLR| per RE, then on the weakest and the strongest tenth
% by the channel estimate |Hpdsch| (B3's ranking), so the csi weighting
% cannot make the test true by itself.
llrPerRE = mean(reshape(abs(soft{1}), Qm, []), 1);   % one mean confidence per RE, before csi weighting
[~, order] = sort(abs(Hpdsch(:)));            % REs from weakest to strongest channel
nTenth = round(numel(order)/10);              % a tenth of the REs
llrWeak   = mean(llrPerRE(order(1:nTenth)));            % mean |LLR|, least reliable tenth
llrStrong = mean(llrPerRE(order(end-nTenth+1:end)));    % mean |LLR|, most reliable tenth

% Three tests: one soft bit per coded bit, equalizing beats the raw symbols,
% and the faded REs carry smaller LLRs.
okBitCount = numel(llr) == indInfo.G;
assert(okBitCount, ...
    'The soft-bit count is not G. Look first at Qm: one LLR per bit, Qm bits per QPSK symbol.');
okEqBeatsRaw = nErrEq < nErrRaw;
assert(okEqBeatsRaw, ...
    'Equalized soft bits did not beat the raw symbols. Common mistake: decoding rxPdsch instead of mmse.');
okWeakLow = llrWeak < llrStrong;
assert(okWeakLow, ...
    'Faded REs do not have smaller LLRs. Look first at the ranking: sort by |Hpdsch| and use the unweighted soft{1}, Qm LLRs per RE.');

b4Bits = table(numel(llr), indInfo.G, nErrEq, nErrRaw, mean(abs(llr)), llrWeak, llrStrong, ...
    VariableNames = {'SoftBits', 'G', 'BitErrors_Equalized', 'BitErrors_Raw', 'MeanAbsLLR', 'MeanAbsLLR_weakest', 'MeanAbsLLR_strongest'});
b4Bits

% Put your Try-it prediction beside the effect of a ten-times-too-small nVar.
softTry = nrPDSCHDecode(carrier, pdsch, mmse, nVar/10);   % the same symbols, nVar ten times too small
llrTry = softTry{1} .* csiBits(:);
tryRatio = mean(abs(llrTry)) / mean(abs(llr));          % how much larger the LLRs got
tryFlips = sum((llrTry < 0) ~= (llr < 0));              % bits whose sign changed
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, round(tryRatio, 3), tryFlips, predictionNote, ...
    VariableNames = {'MyPrediction', 'MeanAbsLLR_ratio', 'SignChanges', 'Note'});
b4Prediction

% The soft bits: two humps, and the faded REs near zero.
figure(Name = 'Track 07 B4 - soft bits', Color = 'w');
histogram(llr, 100);                          % 100 bins of csi-weighted LLRs
grid on;
xlabel('LLR (csi-weighted)');
ylabel('count');
title('B4: soft bits cluster at + (bit 0) and - (bit 1); small |LLR| = faded REs');
%%
% Equalized soft bits give far fewer bit errors than the raw symbols, which 
% sit at the channel's rotation on every tone. The least reliable REs carry 
% the smallest LLRs, so the decoder trusts them least. Compare the LLR ratio 
% and the sign changes with your prediction: what does that say about how 
% large an LLR should be?
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["One soft bit per coded bit"; ...
     "Equalized bit errors < raw bit errors"; ...
     "Weakest REs have smaller mean |LLR|"], ...
    [string(indInfo.G); "fewer than " + string(nErrRaw); "less than " + string(round(llrStrong, 3))], ...
    [string(numel(llr)); string(nErrEq); string(round(llrWeak, 3))], ...
    [okBitCount; okEqBeatsRaw; okWeakLow], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The beats are done: clear the slot, the channel, and everything B1 to B4
% made. Keep listText for the Build it check tables.
clear b4Bits b4Checks b4Prediction predictionNote okBitCount okEqBeatsRaw okWeakLow ...
      soft Qm csiBits llr nErrEq softRaw nErrRaw llrPerRE order nTenth llrWeak llrStrong Hpdsch ...
      softTry llrTry tryRatio tryFlips myPrediction ...
      carrier pdsch pdschInd indInfo dmrsInd dmrsSym txGrid cw snrdB ofdmInfo tdl wave ...
      maxChDelay rxWave pathGains pathFilters offset snrLin N0 nVarTrue rxGrid ...
      Hest nVar rxPdsch mmse csi
%% Build it — Estimate a channel from six pilots, then equalize a fade
% Competency: given the received values on a few known pilots, work out the 
% raw ratios, interpolate them to every subcarrier, and equalize one faded 
% data RE with ZF and with MMSE.
% Problem
% One OFDM symbol has 12 subcarriers. Pilots sit on the odd subcarriers (1, 
% 3, ..., 11), data on the even ones. Stage 1 gives what was sent, the channel, 
% the noise, and what was received. Using only the pilots, estimate the channel 
% on all 12 subcarriers, then equalize the data RE on subcarrier 6, where the 
% channel fades, both ways, and compare each with what was sent.
% Allowed commands
% Indexing x(idx); ./ and ordinary arithmetic + - * / ^; interp1 with 'linear' 
% and 'extrap'; conj; abs. The tables and the figure in the check sections 
% and Stage 5 are given. All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section. The channel 
% has a magnitude dip around subcarrier 6 and a phase that turns steadily 
% across the band (a delay). The noise values are fixed, so every run gives 
% the same numbers.
% Pass: the check below prints Stage 1 OK.

% myTx = [1+1j, -1+1j, 1-1j, 1+1j, -1-1j, -1+1j, 1+1j, 1-1j, -1+1j, -1-1j, 1-1j, 1+1j] / sqrt(2);   % sent QPSK symbols, unit power: odd = pilots, even = data
% myMag = [1.0 0.95 0.85 0.7 0.45 0.3 0.25 0.4 0.6 0.8 0.9 1.0];       % true channel magnitude on each subcarrier
% myH = myMag .* exp(-1j*2*pi*0.04*(0:11));                             % true channel: magnitude, with a phase that turns 0.04 cycles per subcarrier
% myN = 0.14*[0.6-0.2j, -0.4+0.9j, 0.3+0.5j, -0.8-0.1j, 0.2-0.7j, 0.9+0.4j, -0.5+0.3j, 0.1-0.6j, -0.3-0.4j, 0.7+0.2j, -0.2+0.8j, 0.4-0.5j];   % fixed noise, one value per subcarrier
% myY = myH .* myTx + myN;                                              % what the receiver measures
% myPilotSc = 1:2:11;                                                   % pilot subcarriers (MATLAB positions)
% myNVar = 0.01;                                                        % noise variance the receiver assumes
%% Stage 1 check (given)
if ~exist('myTx','var') || ~exist('myMag','var') || ~exist('myH','var') || ~exist('myN','var') ...
        || ~exist('myY','var') || ~exist('myPilotSc','var') || ~exist('myNVar','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = numel(myTx) == 12 && numel(myY) == 12 && isequal(myPilotSc, 1:2:11) && myNVar == 0.01 ...
        && max(abs(myY - myH.*myTx - myN)) < 1e-12;           % the values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the lines you uncommented: 12 symbols, pilots 1:2:11, and myNVar = 0.01.')
    stage1Checks = table("Given values", "12 subcarriers, pilots 1 3 5 7 9 11, nVar 0.01", ...
        string(numel(myY)) + " subcarriers, pilots " + listText(myPilotSc) + ", nVar " + string(myNVar), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the raw ratios on the pilots
% Fill the blanks: the received values on the pilot subcarriers over the sent 
% pilot symbols, entry by entry.
% Pass: Stage 2 OK.

% myRaw = myY(___) ./ myTx(___);
%% Stage 2 check (given; the check builds each ratio as channel plus noise over pilot, a different route from yours)
if ~exist('myRaw','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: Key relationships, H_p + N_p / X_p.
    oracleRaw = myH(myPilotSc) + myN(myPilotSc)./myTx(myPilotSc);

    % Two tests: one ratio per pilot, and each matches the other route.
    okStage2 = [numel(myRaw) == numel(myPilotSc); ...
                numel(myRaw) == numel(oracleRaw) && max(abs(myRaw - oracleRaw)) < 1e-12];
    assert(okStage2(1), ...
        'myRaw should have one value per pilot. Look first at the positions you used: the pilot subcarriers, both times.')
    assert(okStage2(2), ...
        'myRaw is off. Common mistake: dividing the sent symbols by the received ones, or using the data positions.')
    stage2Checks = table( ...
        ["One ratio per pilot"; "Ratio = H + N/X on each pilot"], ...
        [string(numel(myPilotSc)); "largest difference < 1e-12"], ...
        [string(numel(myRaw)); "matches = " + string(okStage2(2))], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then interpolate to every subcarrier
% First type your prediction: the estimated |H| on subcarrier 6, halfway between 
% pilots 5 and 7. Then fill the blanks: interpolate the raw ratios from the 
% pilot positions to all 12 subcarriers, on straight lines, allowing points 
% past the last pilot.
% Pass: your prediction and your value appear side by side in a one-row table, 
% and Stage 3 OK.

% myPrediction = ___;
% myHest = interp1(___, ___, 1:12, 'linear', 'extrap');
%% Stage 3 check (given; the check builds the halfway and edge values by hand, a different route from yours)
if ~exist('myHest','var') || ~exist('myPrediction','var')
    disp('Stage 3 not done: type your prediction, fill the blanks, uncomment, and run.')
else
    % Your prediction beside your value, in one row.
    stage3Prediction = table(myPrediction, round(abs(myHest(min(6, end))), 4), ...
        VariableNames = {'MyPrediction', 'MyAbsHest6'});
    stage3Prediction

    % Different route: halfway between two pilots is their average; one step
    % past the last pilot continues the last line by half a pilot gap.
    oracleHalf = (oracleRaw(3) + oracleRaw(4))/2;                  % subcarrier 6, between pilots 5 and 7
    oracleEdge = oracleRaw(6) + (oracleRaw(6) - oracleRaw(5))/2;   % subcarrier 12, past pilot 11

    % Three tests: 12 values, the pilots unchanged, and the halfway and edge
    % values match the hand route.
    okStage3 = [numel(myHest) == 12; ...
                numel(myHest) == 12 && max(abs(myHest(myPilotSc) - oracleRaw)) < 1e-12; ...
                numel(myHest) == 12 && abs(myHest(6) - oracleHalf) < 1e-12 && abs(myHest(12) - oracleEdge) < 1e-12];
    assert(okStage3(1), ...
        'myHest should have 12 values. Look first at the third input: every subcarrier, 1:12.')
    assert(okStage3(2), ...
        'myHest does not pass through the raw ratios. Look first at the first two inputs: the pilot positions, then the ratios.')
    assert(okStage3(3), ...
        'The halfway or edge value is off. Common mistake: leaving out ''extrap'', which leaves subcarrier 12 as NaN.')
    stage3Checks = table( ...
        ["Values"; "Through the raw ratios"; "Halfway and edge values"], ...
        ["12"; "largest difference < 1e-12"; "|H6| " + string(round(abs(oracleHalf), 4)) + ", |H12| " + string(round(abs(oracleEdge), 4))], ...
        [string(numel(myHest)); string(okStage3(2)); "|H6| " + string(round(abs(myHest(min(6, end))), 4)) + ", |H12| " + string(round(abs(myHest(end)), 4))], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — equalize the faded RE both ways
% Fill the blanks: ZF on subcarrier 6 (received over estimate); MMSE with the 
% textbook form in Key relationships, using myNVar; then each one's error size 
% against what was sent there.
% Pass: Stage 4 OK.

% myZF = myY(6) / ___;
% myMMSE = conj(___) * myY(6) / (abs(___)^2 + ___);
% myErrZF = abs(myZF - ___);
% myErrMMSE = abs(myMMSE - ___);
%% Stage 4 check (given; the check builds ZF with the conjugate and MMSE as ZF times the shrink factor, a different route from yours)
if ~exist('myZF','var') || ~exist('myMMSE','var') || ~exist('myErrZF','var') || ~exist('myErrMMSE','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: y h* / |h|², then MMSE = ZF × |h|² / (|h|² + σ²).
    h6 = myHest(6);                                         % your estimate on subcarrier 6 (Stage 3 checked it)
    oracleZF = myY(6)*conj(h6)/abs(h6)^2;
    oracleShrink = abs(h6)^2/(abs(h6)^2 + myNVar);          % MMSE shrink factor (no unit)
    oracleMMSE = oracleZF*oracleShrink;

    % Three tests: ZF, MMSE, and both error sizes.
    okStage4 = [abs(myZF - oracleZF) < 1e-12; ...
                abs(myMMSE - oracleMMSE) < 1e-12; ...
                abs(myErrZF - abs(oracleZF - myTx(6))) < 1e-12 && abs(myErrMMSE - abs(oracleMMSE - myTx(6))) < 1e-12];
    assert(okStage4(1), ...
        'myZF is off. Look first at what you divided by: the estimate on subcarrier 6, not the true channel.')
    assert(okStage4(2), ...
        'myMMSE is off. Common mistake: forgetting conj, or using the true channel myH instead of the estimate.')
    assert(okStage4(3), ...
        'An error size is off. Look first at what you compared with: the symbol sent on subcarrier 6.')
    stage4Checks = table( ...
        ["ZF on subcarrier 6"; "MMSE on subcarrier 6"; "Error sizes (ZF, MMSE)"], ...
        [string(round(oracleZF, 4)); string(round(oracleMMSE, 4)); ...
         string(round(abs(oracleZF - myTx(6)), 4)) + ", " + string(round(abs(oracleMMSE - myTx(6)), 4))], ...
        [string(round(myZF, 4)); string(round(myMMSE, 4)); string(round(myErrZF, 4)) + ", " + string(round(myErrMMSE, 4))], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myErrMMSE','var') || ~exist('myHest','var') || ~exist('myRaw','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [max(abs(myRaw - (myH(myPilotSc) + myN(myPilotSc)./myTx(myPilotSc)))) < 1e-12; ...
        abs(myHest(6) - (myRaw(3) + myRaw(4))/2) < 1e-12; ...
        abs(myMMSE - (myY(6)/myHest(6))*abs(myHest(6))^2/(abs(myHest(6))^2 + myNVar)) < 1e-12; ...
        myErrZF > abs(myN(6)); ...
        myErrMMSE < myErrZF];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["Raw ratio = H + N/X on every pilot"; "Estimate on 6 = average of pilots 5 and 7"; ...
         "MMSE = ZF × |h|²/(|h|² + σ²)"; "ZF boosts the noise: ZF error > |noise| on 6"; "Error on subcarrier 6: MMSE < ZF"], ...
        ["difference < 1e-12"; string(round((myRaw(3) + myRaw(4))/2, 4)); ...
         string(round((myY(6)/myHest(6))*abs(myHest(6))^2/(abs(myHest(6))^2 + myNVar), 4)); ...
         "more than " + string(round(abs(myN(6)), 4)); "less than " + string(round(myErrZF, 4))], ...
        [string(max(abs(myRaw - (myH(myPilotSc) + myN(myPilotSc)./myTx(myPilotSc))))); string(round(myHest(6), 4)); ...
         string(round(myMMSE, 4)); string(round(myErrZF, 4)); string(round(myErrMMSE, 4))], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: the true |H|, the raw ratios at the pilots, and your estimate.
    figure(Name = 'Track 07 Build it - my estimate', Color = 'w');
    plot(1:12, abs(myH), 'k-');                         % true channel magnitude
    hold on;
    stem(myPilotSc, abs(myRaw), 'filled');              % raw ratios at the pilots
    plot(1:12, abs(myHest), 'r--o');                    % your interpolated estimate
    grid on;
    xlabel('subcarrier');
    ylabel('|H|');
    legend('true', 'raw ratio at pilots', 'my estimate');
    title(sprintf('Subcarrier 6: |error| ZF %.3f, MMSE %.3f', myErrZF, myErrMMSE));
end
%%
% Your interpretation (write one or two sentences here): how close is the 
% estimate on subcarrier 6 to the true channel there, and on subcarrier 12? 
% Which equalizer landed nearer the sent symbol on the faded RE, and why would 
% you not conclude that it wins on every RE?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks oracleRaw okStage2 stage2Checks ...
      stage3Prediction oracleHalf oracleEdge okStage3 stage3Checks ...
      h6 oracleZF oracleShrink oracleMMSE okStage4 stage4Checks buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B1)
% A PDSCH uses 24 PRBs, symbols 2 to 13, DM-RS type 1. Work out the number 
% of DM-RS REs with DMRSAdditionalPosition = 0 and with 3 (four DM-RS symbols), 
% and each as a fraction of the 24 PRBs' REs in the slot. Using album track 
% 06, say when the extra pilots are worth their cost.
% 
% Your answer:
% E2 — New values (B3)
% At 12 dB SNR per RE, σ² = 1/10^1.2. For |h| = 1, 0.5, and 0.1, work out the 
% size of the ZF multiplier and of the textbook MMSE multiplier. Why does the 
% MMSE multiplier get smaller again at |h| = 0.1, and what does that do to 
% the noise on that RE?
% 
% Your answer:
% E3 — Diagnosis (B2 and Build it)
% In your Build it, compare the estimate with the true channel on subcarrier 
% 12, past the last pilot, and on subcarrier 6, between two pilots. How large 
% is each error, what went wrong on subcarrier 12, and why?
% 
% Your answer:
% E4 — Explanation (B3)
% MMSE pulls every equalized symbol towards zero a little, so its output is 
% biased, yet its error is smaller in fades. Explain the trade it makes, and 
% why the EVMs over all PDSCH REs in B3 are much closer than the errors on 
% the weakest REs.
% 
% Your answer:
% E5 — Diagnosis (B4)
% A classmate decodes with a noise variance ten times too large and says "the 
% bit errors did not change, so the noise variance does not matter". Using 
% album track 05, name one place where LLRs of the wrong size do harm even 
% when every sign is right, and say what goes wrong there.
% 
% Your answer:
% E6 — Explanation (Build it)
% In your Build it the channel's phase turns 0.04 cycles per subcarrier. How 
% many subcarriers make one full turn? If it turned 0.25 cycles per subcarrier 
% instead (a much longer delay), how far apart in phase would two neighbouring 
% pilots be, and what would averaging them give? What does that say about 
% averaging and interpolating across a channel with a long delay spread?
% 
% Your answer:
%% Recap — Learn the Channel (album track 07)
% The phone knows only the pilots. Received over sent on each pilot is a noisy 
% sample of the channel; averaging cuts the noise and interpolation fills in 
% the data REs. Then it equalizes: ZF divides by the estimate, MMSE divides 
% and backs off where the noise wins, and the soft bits carry that reliability 
% to the decoder.
% Key relationships
% $$\hat{H}_p = \frac{Y_p}{X_p},\qquad \hat{x}_{\mathrm{ZF}} = \frac{y}{h},\qquad \hat{x}_{\mathrm{MMSE}} 
% = \frac{h^{*}\,y}{|h|^{2}+\sigma^{2}}$$
% What this means in practice
% • Only the DM-RS REs are known; every other RE's channel is averaged and 
% interpolated from them.
% 
% • Grade an estimate on the data REs, where it is used, not only on the pilots.
% 
% • Interpolation is safer between pilots than past the last one.
% 
% • ZF boosts the noise in fades; MMSE shrinks those REs and wins on average.
% 
% • The LLRs' size is a confidence: the noise variance and the csi set it, 
% even when the signs do not change.
% 
% • You estimated a channel from six pilots by hand, interpolated it, and equalized 
% a faded RE with ZF and MMSE.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 06 (track06/track06_taps_in_time_demo), why does a phone at 120 km/h 
% need more DM-RS symbols per slot than one at walking speed?
% 
% • Next in the album: track08 (Clusters and Angles).
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
% • x = value:
% 
% • + - * / and ./:
% 
% • x(idx):
% 
% • interp1:
% 
% • conj and abs:
% 
% • z^2:
% What I missed, and where to reread it
% 
