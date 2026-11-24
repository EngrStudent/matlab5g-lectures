%% track12_how_far_demo
%% How Far (album track 12): positioning reference signals, timing, TDOA hyperbolas, and round trips
% In One in Ten, every piece of the link went into one loop that is judged 
% by its block error rate. Now the same signals are used for something else: 
% finding the phone. Light moves about thirty centimetres every nanosecond, 
% so if you can measure time well enough, you have measured distance.
% 
% This demonstration gives three base stations their own positioning reference 
% signal (PRS), delays each one by the time light takes to reach the phone, 
% measures those delays, turns two time differences into two hyperbolas that 
% cross at the phone, and then shows why a round trip needs no shared clock. 
% It ends with the one thing that fools every method: a blocked direct path.
%% Guiding question
% How can a phone's position be found from the times at which known signals 
% arrive, and what can make every one of those times too long?
% This demonstration
% 1. B1 — One PRS per base station: the same comb of resource elements, a 
% different sequence for each tower.
% 
% 2. B2 — Delay, add, estimate: fractional delays, nrTimingEstimate, and a 
% sub-sample refinement.
% 
% 3. B3 — Two time differences, two hyperbolas, one fix (downlink TDOA).
% 
% 4. B4 — Round trips: the two Rx–Tx readings, what cancels, and the blocked 
% path that does not.
% 
% 5. Build it — From Rx–Tx readings to ranges, a blocked tower, and range 
% differences.
% Key relationships
% A delay is a distance, and one sample at sample rate f_s is a fixed length:
% 
% $$d = c\,\tau,\qquad \Delta x_{\mathrm{sample}} = \frac{c}{f_s}$$
% 
% A PRS comb of size C over N_RB resource blocks fills this many REs in each 
% PRS symbol:
% 
% $$N_{\mathrm{RE/symbol}} = \frac{12\,N_{\mathrm{RB}}}{C}$$
% 
% A time difference of arrival is a range difference (a hyperbola with foci 
% at towers i and 1):
% 
% $$\Delta d_{i1} = d_i - d_1 = c\,(\tau_i - \tau_1)$$
% 
% A round trip, from the two receive-minus-transmit readings, each taken on 
% its own clock:
% 
% $$\left(T_{\mathrm{gNB,Rx}} - T_{\mathrm{gNB,Tx}}\right) + \left(T_{\mathrm{UE,Rx}} 
% - T_{\mathrm{UE,Tx}}\right) = \frac{2d}{c},\qquad d = \frac{c}{2}\,(\text{sum})$$
% 
% A peak at sample k with neighbours a, b, c (b the largest) is refined by 
% a parabola through the three points:
% 
% $$\delta = \frac{1}{2}\,\frac{a - c}{a - 2b + c},\qquad \hat{k} = k + \delta$$
% Key ideas to remember
% • Light moves about 30 cm per nanosecond, so a time is a distance. At the 
% 30.72 MHz sample rate used here one sample is about 9.76 m, so a metre-level 
% answer needs a fraction of a sample.
% 
% • Each base station sends its own PRS with its own sequence identity, any 
% value from 0 to 4095. nrPRSConfig holds the setup, nrPRS makes the symbols, 
% and nrPRSIndices places them on the grid. The comb size (2, 4, 6, or 12) 
% is the RE spacing in each symbol; a PRS uses up to 12 symbols in a row and 
% up to 275 RBs in the toolbox (272 is the nominal maximum in the specification).
% 
% • Wider bandwidth gives sharper timing.
% 
% • There are three methods: differences in arrival time (DL-TDOA), angles 
% of departure (DL-AoD), and round trips (multi-RTT). Two of them ask how long 
% the light took; the third asks which way it left.
% 
% • DL-TDOA needs no round trip, but the base stations must agree on time. 
% Each arrival-time difference puts the phone on a hyperbola, two hyperbolas 
% cross at the fix, and the phone's own clock drops out. A 10 ns disagreement 
% between towers is about 3 m of range difference.
% 
% • In a round trip, the phone reports its receive time minus its send time 
% on its own clock, and the base station does the same on its clock. Add the 
% two and the waiting time and both clock offsets drop out, leaving twice the 
% travel time: no shared clock is needed. The location function in the core 
% network does the maths.
% 
% • If the direct path is blocked, the first arrival is a reflection, so its 
% range is too long. That error does not cancel, and more bandwidth does not 
% fix it.
% Prerequisites
% • Timing estimation with nrTimingEstimate and the synchronization signals 
% (album track 03 Find Me in the Noise, track03/track03_find_me_in_the_noise_demo).
% 
% • The resource grid, OFDM modulation, and the sample rate (track 00 Fundamentals, 
% track00_fundamentals/p00a_ofdm_and_cp_demo; album track 01 Two to the Mu, 
% track01/track01_two_to_the_mu_demo).
% Words used in this demo
% • PRS (positioning reference signal): a known downlink sequence each base 
% station sends so a phone can time it. NPRSID: its sequence identity.
% 
% • Comb: a pattern that uses one RE in every C subcarriers of a symbol, so 
% several cells can share the slot on different offsets.
% 
% • TDOA (time difference of arrival): the difference between two arrival 
% times. Hyperbola: every point whose distances to two towers differ by the 
% same amount.
% 
% • RTT (round-trip time); Rx–Tx time difference: a node's receive time minus 
% its own transmit time, on its own clock. Turnaround: the phone's wait between 
% receiving and sending.
% 
% • LOS / NLOS: line of sight / non-line of sight (direct path blocked). LMF: 
% the location management function in the core network.
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
% • + - * / and .^ — Purpose: arithmetic, and entry-by-entry powers. Inputs: 
% numbers or vectors. Outputs: the result.
% 
% • sqrt(x) — Purpose: square root, here for a distance from x and y differences. 
% Inputs: a number or vector. Outputs: the root.
% 
% • find(x > v, 1) — Purpose: the position of the first entry above v. Inputs: 
% a vector, a threshold. Outputs: an index.
% 
% • x(k) and x(a:b) — Purpose: read one entry, or a run of entries. Inputs: 
% a vector and positions. Outputs: the entries.
% 
% Commands you read in the given code
% • carrier = nrCarrierConfig(...), ofdmInfo = nrOFDMInfo(carrier) — Purpose: 
% the carrier and its sample rate. Inputs: spacing (kHz), RBs, cell ID. Outputs: 
% a configuration object; a structure with SampleRate and Nfft.
% 
% • nrPRSConfig, nrPRS, nrPRSIndices, nrResourceGrid, nrOFDMModulate — Used 
% in B1 and B2; listed at the start of B1.
% 
% • [offset, mag] = nrTimingEstimate(carrier, rx, refInd, refSym) — Used in 
% B2; listed there.
% 
% • fft(x, n), ifft(X), meshgrid, hypot, contour — Used in B2 and B3; listed 
% there.
% 
% • Figure family: figure(Name = ...), imagesc, plot, contour, legend, axis, 
% grid on, hold on, xlabel, ylabel, title — Purpose: draw a map or curves 
% and label them. Inputs: data and text. Outputs: a figure.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing, ranges, and loops: x(k), x(:), a:b:c, x(end), for k = ... end, 
% if ... else ... end, cell arrays c{k} — Purpose: read or write entries, step 
% through values, repeat, choose, hold one item per tower. Inputs: arrays, 
% ranges, tests. Outputs: the entries or the repeated work.
% 
% • Compare and combine: == < > >=, ~, &&, any, all — Purpose: compare values; 
% not; and; any or every entry true. Inputs: numbers or arrays. Outputs: true/false.
% 
% • Built-in helpers: abs, max, min, mean, sum, norm, numel, size, zeros, 
% cell, cellfun, round, ceil, nextpow2, isnan, NaN, exp, pi — Purpose: sizes, 
% sums, lengths, rounding, empty arrays. Inputs: numbers or arrays. Outputs: 
% numbers or arrays (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, and f = @(v) ... — Purpose: 
% write and join text, turn numbers into text, and make a one-line helper such 
% as listText. Inputs: text or numbers. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), fprintf, disp, exist, clear, close all, rng(seed) — Purpose: show 
% columns side by side, stop with a hint when a check fails, print a banner 
% or note, remove variables or figures, repeat random values. Inputs: columns, 
% a test and message, text, names, a seed. Outputs: a shown table or line; 
% an error if a check fails.
% Working status
% Status: unverified until M runs it in R2024b.
% 
% Teaching draft built to the track01 r03 template (track12 r01, 2026-11-20) 
% from the live track12_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox (R2021a 
% or later for the PRS functions; written for R2024b). There is no noise in 
% B2 and B3, so the timing errors come from the sub-sample method and from 
% the three PRS sharing the same REs. AoA and AoD are described in words only. 
% The round-trip identity in B4 is standard physics, not quoted specification 
% text. Teaching demo, not production code; not affiliated with or endorsed 
% by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year); nothing here is random, but later edits may add noise

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
listText = @(v) strjoin(string(v(:).'), " ");

c = 299792458;   % speed of light, m/s: the exact SI value

% One carrier for every tower: 51 RBs at 30 kHz, about 18 MHz wide.
carrier = nrCarrierConfig(SubcarrierSpacing = 30, NSizeGrid = 51, NCellID = 1);   % kHz, RBs, cell ID
ofdmInfo = nrOFDMInfo(carrier);   % ofdmInfo.SampleRate: 30.72 MHz for this carrier
fs = ofdmInfo.SampleRate;         % samples per second; one sample is c/fs metres

% The PRS settings shared by all three towers (B1 explains each one).
combSize = 4;           % comb size: one RE in every 4 subcarriers of a PRS symbol
numPrsSymbols = 12;     % PRS symbols in the slot, 12 in a row (the maximum)
numPrsRB = 51;          % PRS bandwidth in RBs: the whole carrier
prsIDs = [0 1 2];       % one sequence identity per tower (any three different values from 0 to 4095)

% The scene: three towers and one phone, in metres on a flat map.
bs = [0 0; 500 0; 0 500];   % tower positions, m, one row per tower
ue = [200, 150];            % true phone position, m; B3's solver never sees it

% One PRS configuration per tower: same comb and size, a different sequence identity.
prsCfg = cell(1, 3);
for i = 1:3
    p = nrPRSConfig;
    p.NPRSID = prsIDs(i);           % this tower's sequence identity
    p.CombSize = combSize;          % shared comb (above)
    p.NumPRSSymbols = numPrsSymbols;% shared symbol count (above)
    p.NumRB = numPrsRB;             % shared bandwidth (above)
    prsCfg{i} = p;
end
clear p i
%% B1 — One PRS per base station
% New words
% • Sequence identity (NPRSID): the number that seeds a tower's PRS sequence. 
% Same positions with different identities still give different symbols.
% Beat-only commands
% • prs = nrPRSConfig — the PRS settings (NPRSID, CombSize, NumPRSSymbols, 
% NumRB, SymbolStart, REOffset). Output: a configuration object.
% 
% • ind = nrPRSIndices(carrier, prs) and sym = nrPRS(carrier, prs) — where 
% the PRS sits in the slot (linear indices) and its complex symbols. Outputs: 
% column vectors of the same length.
% 
% • g = nrResourceGrid(carrier) — an empty slot grid (subcarriers by symbols). 
% imagesc(m) — draw a matrix as a map.
% Why it matters
% A phone can only time a tower if it can tell that tower's signal from the 
% others. Each base station's PRS is a known sequence placed on a comb, so 
% several cells can share a slot. Here all three towers use the same comb 
% positions; what tells them apart is the sequence identity. The normalised 
% correlation between two sequences is about 1 with itself and small between 
% different identities.
% What to look for
% • In the PRS table: the REs each tower uses, and the correlation of each 
% tower's sequence with tower 1's.
% 
% • In the map: the comb, the same for all three identities.
% Common mistakes
% Do not give every tower the same NPRSID: the phone could no longer tell 
% them apart.
% 
% Do not fill every subcarrier and call it a PRS comb.
% Try it (personal exploration)
% Predict how many subcarriers carry the PRS in one symbol if the comb size 
% is 6 instead of 4 (the bandwidth stays at 51 RBs). Type it into myPrediction 
% before you run this section; the one-row table at the end counts them with 
% nrPRSIndices.

% Try it: type your prediction here (subcarriers in one PRS symbol) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — One PRS per base station
fprintf("B1 — One PRS per base station\n");   % banner title only; every number below goes into a table

% Place each tower's PRS on its own empty grid and count its REs.
grids = cell(1, 3);
nRE = zeros(3, 1);
for i = 1:3
    ind = nrPRSIndices(carrier, prsCfg{i});    % this tower's PRS positions
    g = nrResourceGrid(carrier);               % an empty slot grid
    g(ind) = nrPRS(carrier, prsCfg{i});        % the PRS symbols on those positions
    grids{i} = g;                              % kept: B2 turns each grid into a waveform
    nRE(i) = numel(ind);                       % REs used by this tower
end

% Independent route for the count: 12 subcarriers per RB, one in combSize per symbol.
reExpected = numPrsSymbols*numPrsRB*12/combSize;   % 12 = subcarriers per RB

% Same positions, different sequences: read each grid on tower 1's positions and correlate.
prsMask = abs(grids{1}) > 0;                                        % tower 1's PRS positions
seq = cellfun(@(gr) gr(prsMask), grids, 'UniformOutput', false);    % each tower's symbols there
rho = @(u, v) abs(u'*v)/(norm(u)*norm(v));                          % normalised correlation, 0 to 1
corrWith1 = [rho(seq{1}, seq{1}); rho(seq{1}, seq{2}); rho(seq{1}, seq{3})];

% Two tests: every tower uses the expected number of REs, and the sequences differ.
okCount = all(nRE == reExpected);
assert(okCount, ...
    'Each PRS should fill symbols x RBs x 12 / CombSize REs. Look first at SymbolStart: the PRS symbols must fit in the 14-symbol slot, or nrPRSIndices returns fewer REs.');
okDistinct = max(corrWith1(2:3)) < 0.2;
assert(okDistinct, ...
    'Different towers should have nearly uncorrelated sequences. Common mistake: the same NPRSID for every tower.');

b1Prs = table(prsIDs(:), nRE, round(corrWith1, 3), ...
    VariableNames = {'NPRSID', 'REs', 'AbsCorrWithTower1'});
b1Prs

% Mechanism figure: the comb in one slot (the same for all three identities).
figure(Name = 'Track 12 - PRS comb', Color = 'w');
imagesc(prsMask);           % 1 where tower 1's PRS sits
axis xy;
xlabel('OFDM symbol (1 to 14)');
ylabel('subcarrier');
title('B1: PRS positions, comb size 4 (the same for NPRSID 0, 1, 2)');

% Put your Try-it prediction beside a count for comb size 6.
prsTry = prsCfg{1};
prsTry.CombSize = 6;                                  % the Try-it comb size
indTry = nrPRSIndices(carrier, prsTry);
[~, symTry] = ind2sub(size(grids{1}), indTry);       % symbol of each PRS RE
countTry = nnz(symTry == min(symTry));                % REs in the first PRS symbol
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, countTry, predictionNote, ...
    VariableNames = {'MyPrediction', 'SubcarriersPerSymbol_Comb6', 'Note'});
b1Prediction
%%
% Every tower fills the same positions, so the map shows one comb, and the 
% RE count matches the comb rule in Key relationships. The correlation column 
% shows the difference: 1 for tower 1 against itself, and small for the other 
% two, so a receiver correlating against tower 2's sequence hears tower 2. 
% Compare the comb-6 count with your prediction.
%% B1 — Assertion checks

% One row per assert in B1, plus the self-correlation row (true by construction). Pass is computed from the stored flags.
b1Checks = table( ...
    ["REs per tower match the comb rule"; ...
     "Different NPRSIDs are nearly uncorrelated"; ...
     "Tower 1 with itself (by construction, not asserted)"], ...
    [string(reExpected) + " each"; "< 0.2"; "1"], ...
    [listText(nRE); string(round(max(corrWith1(2:3)), 3)); string(round(corrWith1(1), 3))], ...
    [okCount; okDistinct; abs(corrWith1(1) - 1) < 1e-12], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep grids and prsCfg: B2 sends each tower's grid and times it against its own PRS.
clear b1Prs b1Checks b1Prediction predictionNote okCount okDistinct ...
      i ind g nRE reExpected prsMask seq rho corrWith1 ...
      prsTry indTry symTry countTry myPrediction
%% B2 — Delay, add, estimate: fractional delays
% New words
% • Fractional delay: a delay that is not a whole number of samples. Sub-sample 
% refinement: estimating the part of the delay between two samples.
% Beat-only commands
% • W = fft(w, n) and w = ifft(W) — to the frequency domain (zero-padded to 
% n samples) and back. A delay of tau seconds is the phase ramp exp(−j2πf·tau) 
% in frequency.
% 
% • [offset, mag] = nrTimingEstimate(carrier, rx, refInd, refSym) — correlates 
% the received waveform with the slot built from the reference indices and 
% symbols. Outputs: the whole-sample offset of the strongest peak (counted 
% from 0), and mag, the correlation magnitude at every sample (mag(offset + 1) 
% is the peak, because MATLAB counts from 1).
% Why it matters
% A delay estimated from a known PRS is a range. The phone sits at (200, 150) 
% m and the towers at (0, 0), (500, 0) and (0, 500) m. At 30.72 MHz one sample 
% is about 9.76 m, so the true delays fall between samples, and nrTimingEstimate 
% alone returns whole samples. A parabola through the peak of mag and its two 
% neighbours estimates the fraction. All three towers arrive on top of each 
% other in one received waveform, as they would at a real phone; each timing 
% estimate correlates against one tower's own PRS.
% What to look for
% • In the timing table: the true range and delay of each tower, the whole-sample 
% offset, the refined delay, and the error in metres.
% Common mistakes
% Do not round the delay to a whole sample and expect a metre-level fix: one 
% sample is already about 10 m.
% 
% Do not call nrTimingEstimate with the (waveform, nrb, scs, ...) form from 
% album track 03 and the carrier-object inputs mixed together: this beat uses 
% the (carrier, waveform, refInd, refSym) form.
% Try it (personal exploration)
% Predict the delay from tower 1, in samples at 30.72 MHz, if the phone stood 
% at (250, 150) m instead. Type it into myPrediction before you run this section; 
% the one-row table at the end computes it.

% Try it: type your prediction here (samples) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Delay, add, estimate
fprintf("B2 — Delay, add, estimate\n");   % banner title only; every number below goes into a table

% True geometry: range, delay in seconds, and delay in samples for each tower.
d = sqrt(sum((bs - ue).^2, 2));   % ranges, m
tau = d/c;                        % delays, s
nSamp = tau*fs;                   % delays, samples (fractional)

% Delay each tower's PRS waveform by its own fractional delay, as a phase ramp in frequency.
wave = cell(1, 3);
nMax = 0;
for i = 1:3
    w = nrOFDMModulate(carrier, grids{i});                 % this tower's slot, PRS only
    nPad = 2^nextpow2(numel(w) + ceil(nSamp(i)) + 8);      % room for the delay plus a margin of 8 samples
    W = fft(w, nPad);                                      % zero-padded spectrum
    f = (0:nPad-1).'*(fs/nPad);                            % frequency of each FFT bin, Hz
    f(f >= fs/2) = f(f >= fs/2) - fs;                      % upper half is negative frequency, so the ramp is a true delay
    wave{i} = ifft(W.*exp(-1j*2*pi*f*tau(i)));             % delayed by tau(i) seconds
    nMax = max(nMax, numel(wave{i}));                      % longest delayed waveform so far
end

% The phone hears all three at once: add them on a common length (no noise in this geometry check).
rx = zeros(nMax, 1);
for i = 1:3
    rx(1:numel(wave{i})) = rx(1:numel(wave{i})) + wave{i};   % add tower i's delayed signal
end

% Time each tower against its own PRS, then refine the peak with a parabola.
offInt = zeros(3, 1);    % whole-sample offsets from nrTimingEstimate
offFine = zeros(3, 1);   % refined delays, samples
for i = 1:3
    refInd = nrPRSIndices(carrier, prsCfg{i});               % tower i's reference positions
    refSym = nrPRS(carrier, prsCfg{i});                      % tower i's reference symbols
    [off, mag] = nrTimingEstimate(carrier, rx, refInd, refSym);
    offInt(i) = off;
    k0 = off + 1;                                            % the peak's position in mag (MATLAB counts from 1)
    a = abs(mag(k0 - 1)); b = abs(mag(k0)); cc = abs(mag(k0 + 1));   % the peak and its two neighbours
    den = a - 2*b + cc;                                      % negative at a true peak
    if den < 0
        delta = 0.5*(a - cc)/den;                            % parabola vertex, between -0.5 and +0.5 samples
    else
        delta = 0;                                           % not a peak shape: keep the whole sample
    end
    offFine(i) = off + delta;
end

% Two tests: the whole-sample offsets are within one sample, and the refined delays within a quarter sample.
okInteger = all(abs(offInt - nSamp) < 1);
assert(okInteger, ...
    'Each whole-sample offset should be within 1 sample of the true delay. Look first at the reference: each call must use that tower''s own prsCfg{i}.');
okRefined = all(abs(offFine - nSamp) < 0.25);
assert(okRefined, ...
    'Each refined delay should be within 0.25 samples of the truth. Look first at b2Timing: if every error has the same sign, the peak shape is skewed (all three PRS share REs); report the table.');

b2Timing = table((1:3).', round(d, 2), round(nSamp, 3), offInt, round(offFine, 3), ...
    round((offFine - nSamp)*c/fs, 2), ...
    VariableNames = {'Tower', 'TrueRange_m', 'TrueDelay_samples', 'WholeSampleOffset', 'RefinedDelay_samples', 'RangeError_m'});
b2Timing

% Put your Try-it prediction beside the delay for the moved phone.
dTry = norm([250 150] - bs(1, :));   % range from tower 1 to the Try-it position, m
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, round(dTry/c*fs, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'Delay_samples_Tower1', 'Note'});
b2Prediction
%%
% The whole-sample offsets land on the nearest sample, so on their own they 
% would be up to half a sample, about 5 m, wrong. The parabola moves each 
% estimate to within a small fraction of a sample, a metre or two of range 
% at most. Compare the moved-phone delay with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Whole-sample offsets within 1 sample"; ...
     "Refined delays within 0.25 samples"], ...
    ["< 1 sample"; "< 0.25 samples"], ...
    [string(round(max(abs(offInt - nSamp)), 3)) + " max"; string(round(max(abs(offFine - nSamp)), 3)) + " max"], ...
    [okInteger; okRefined], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep d and offFine: B3 turns the refined delays into range differences, and B4 uses d(1).
clear b2Timing b2Checks b2Prediction predictionNote okInteger okRefined ...
      i w nPad W f wave nMax rx refInd refSym off mag k0 a b cc den delta ...
      tau nSamp offInt dTry myPrediction
%% B3 — Hyperbolas cross at the fix (DL-TDOA)
% New words
% • Fix: the estimated position. Grid search: try every point of a fine grid 
% and keep the one that fits the measurements best.
% Beat-only commands
% • [X, Y] = meshgrid(xs, ys) — every (x, y) pair of two ranges, as two matrices. 
% hypot(a, b) — sqrt(a.^2 + b.^2) entry by entry.
% 
% • contour(X, Y, Z, [v v]) — draw the curve where Z equals v (here, a hyperbola).
% Why it matters
% DL-TDOA assumes the towers are synchronized. A time difference is not a 
% range; it is a range difference, and every point with the same range difference 
% to two towers lies on one hyperbola with those towers as its foci. Two differences 
% give two hyperbolas, and they cross at the phone. The phone's own clock 
% does not matter: it shifts every arrival by the same amount, and that drops 
% out of each difference. The grid search below knows only the towers and 
% the two measured differences, never the true position.
% What to look for
% • In the fix table: the true and measured range differences, the fix, and 
% its error in metres.
% 
% • In the figure: two hyperbolas crossing at the phone, and the fix on top 
% of it.
% Common mistakes
% Do not draw circles around the towers: those would need ranges, and TDOA 
% gives only differences.
% 
% Do not mix the order: every difference here is tower i minus tower 1.
% Try it (personal exploration)
% Predict how far, in metres, the fix moves if tower 2's clock alone runs 
% 10 ns late. Type it into myPrediction before you run this section; the one-row 
% table at the end solves again with that bias.

% Try it: type your prediction here (metres the fix moves) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Hyperbolas cross at the fix
fprintf("B3 — Hyperbolas cross at the fix\n");   % banner title only; every number below goes into a table

% Measured range differences, tower i minus tower 1, from the refined delays.
dHat = offFine*(c/fs);           % measured ranges, m (every one shifted alike if the phone clock were off)
deltaHat = dHat - dHat(1);       % measured range differences, m
deltaTrue = d - d(1);            % true range differences, m

% Grid search around the tower centroid (a teaching solver, not a toolbox function).
cen = mean(bs, 1);               % centre of the search box: the towers' centroid, m
halfBox = 350;                   % half-width of the search box, m (covers the triangle of towers)
step = 0.5;                      % grid spacing, m (fine enough for a metre-level answer)
[Xg, Yg] = meshgrid(cen(1)-halfBox:step:cen(1)+halfBox, cen(2)-halfBox:step:cen(2)+halfBox);
Rg = cell(1, 3);
for i = 1:3
    Rg{i} = hypot(Xg - bs(i, 1), Yg - bs(i, 2));   % distance from every grid point to tower i, computed once
end
mismatch = @(dd) hypot((Rg{2} - Rg{1}) - dd(2), (Rg{3} - Rg{1}) - dd(3));   % how badly each point fits two differences

% The fix is the grid point that fits both measured differences best.
fitMap = mismatch(deltaHat);
[~, iMin] = min(fitMap(:));
xyHat = [Xg(iMin), Yg(iMin)];                       % the fix, m
onEdge = any(abs(xyHat - cen) >= halfBox - step);   % true would mean "widen the box"
errM = norm(xyHat - ue);                            % fix error, m

% One test: the fix lands within 3 m of the phone.
okFix = errM < 3;
assert(okFix, ...
    'The fix should be within 3 m of the phone. Look first at deltaHat: every difference must be tower i minus tower 1, the same order as the hyperbolas.');

b3Fix = table(["Tower 2 minus tower 1"; "Tower 3 minus tower 1"], round(deltaTrue(2:3), 2), round(deltaHat(2:3), 2), ...
    VariableNames = {'Difference', 'True_m', 'Measured_m'});
b3Fix
b3Position = table(round(xyHat, 2), round(errM, 2), errM < 1, onEdge, ...
    VariableNames = {'Fix_m', 'Error_m', 'Under1mDemoLine', 'OnSearchBoxEdge'});
b3Position

% Mechanism figure: the two true hyperbolas, the towers, the phone, and the fix.
figure(Name = 'Track 12 - TDOA hyperbolas', Color = 'w');
[X, Y] = meshgrid(linspace(-50, 550, 400), linspace(-50, 550, 400));   % drawing grid, m
R1 = hypot(X - bs(1, 1), Y - bs(1, 2));
contour(X, Y, hypot(X - bs(2, 1), Y - bs(2, 2)) - R1, [deltaTrue(2) deltaTrue(2)], 'b');   % hyperbola, towers 2 and 1
hold on;
contour(X, Y, hypot(X - bs(3, 1), Y - bs(3, 2)) - R1, [deltaTrue(3) deltaTrue(3)], 'r');   % hyperbola, towers 3 and 1
plot(bs(:, 1), bs(:, 2), 'ks', ue(1), ue(2), 'go', xyHat(1), xyHat(2), 'mx');
axis equal;
grid on;
legend('towers 2 and 1', 'towers 3 and 1', 'towers', 'phone', 'fix');
xlabel('x (m)');
ylabel('y (m)');
title('B3: two TDOA hyperbolas cross at the phone');

% Put your Try-it prediction beside the fix with tower 2's clock 10 ns late.
biasTryNs = [0 10 0];                                   % tower clock errors, ns (Try it)
dTry = dHat + c*biasTryNs(:)*1e-9;                      % ranges as the late clock reports them, m
fitTry = mismatch(dTry - dTry(1));
[~, iTry] = min(fitTry(:));
moveTry = norm([Xg(iTry), Yg(iTry)] - xyHat);           % how far the fix moved, m
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, round(moveTry, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'FixMoved_m', 'Note'});
b3Prediction
%%
% The measured differences match the true ones to a fraction of a metre, so 
% the two hyperbolas cross where the phone is and the fix lands close to it. 
% The 1 m line in the position table is a demonstration choice, not a 3GPP 
% figure, and it is shown, not asserted. Compare the moved fix with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flag.
b3Checks = table("Fix within 3 m of the phone", "< 3 m", string(round(errM, 2)) + " m", okFix, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep d: B4 uses the line-of-sight range to tower 1. The figures stay open.
clear b3Fix b3Position b3Checks b3Prediction predictionNote okFix ...
      dHat deltaHat deltaTrue cen halfBox step Xg Yg Rg i mismatch fitMap iMin xyHat onEdge errM ...
      X Y R1 biasTryNs dTry fitTry iTry moveTry offFine grids prsCfg myPrediction
%% B4 — Round trips, angles, and the blocked path
% New words
% • Clock offset: how far a node's clock is from true time. Turnaround: how 
% long the phone waits between receiving and sending.
% Beat-only commands
% None beyond Staging: this beat is arithmetic on timestamps.
% Why it matters
% A two-way time is a range, not a difference: the same path is travelled 
% twice. The base station reports its receive time minus its transmit time 
% on its own clock; the phone reports its receive time minus its transmit 
% time on its clock. Each node only subtracts two of its own readings, so 
% its clock offset never meets the other node's; the phone's turnaround appears 
% once with each sign. The sum is twice the travel time. Angles (AoA and AoD) 
% are the third family: in DL-AoD the base station sweeps beams, the phone 
% reports how strongly each arrived, and one angle gives a line. They are 
% described here in words only. A blocked direct path is different from all 
% of these: the extra length is real and does not cancel.
% What to look for
% • In the round-trip table: the two Rx–Tx readings, their sum, 2d/c, and 
% the range c·(sum)/2 against the line-of-sight range.
% 
% • The sign-slip row: what you get by subtracting the readings instead of 
% adding them.
% Common mistakes
% Do not subtract the two readings: that leaves the turnaround in.
% 
% Do not treat a blocked-path range as if it were still the straight line 
% to the tower.
% Try it (personal exploration)
% Predict how many metres longer the round-trip range becomes if the direct 
% path to tower 1 is blocked and the first arrival travels 30 m further on 
% each leg. Type it into myPrediction before you run this section; the one-row 
% table at the end builds those timestamps.

% Try it: type your prediction here (metres added to the range) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Round trips
fprintf("B4 — Round trips, angles, and the blocked path\n");   % banner title only; every number below goes into a table

dLOS = d(1);          % line-of-sight range to tower 1, m (from B2)
aClk = 100e-9;        % base-station clock offset, s (any value: it cancels)
bClk = -40e-9;        % phone clock offset, s (any value: it cancels)
wTA = 12e-6;          % phone turnaround, s (any value: it cancels)

% Toy timestamps, in seconds, each read on its own node's clock (true time + that node's offset).
tTxGNB = 0 + aClk;                            % base station sends the PRS at true time 0
tRxUE = (dLOS/c) + bClk;                      % phone hears it after the travel time
tTxUE = tRxUE + wTA;                          % phone answers after its turnaround
tRxGNB = (dLOS/c + wTA + dLOS/c) + aClk;      % base station hears the answer

rxtxGNB = tRxGNB - tTxGNB;                    % base station's reading, its own clock
rxtxUE = tRxUE - tTxUE;                       % phone's reading, its own clock
sumRxTx = rxtxGNB + rxtxUE;                   % twice the travel time
slipRxTx = rxtxGNB - rxtxUE;                  % the sign slip: the turnaround stays in
dRtt = c*sumRxTx/2;                           % range from the round trip, m

b4Rtt = table(["gNB Rx-Tx"; "UE Rx-Tx"; "Sum"; "2d/c"; "Sign slip (gNB minus UE)"], ...
    round([rxtxGNB; rxtxUE; sumRxTx; 2*dLOS/c; slipRxTx]*1e9, 3), ...
    VariableNames = {'Quantity', 'Value_ns'});
b4Rtt
b4Range = table(round(dRtt, 4), round(dLOS, 4), VariableNames = {'RangeFromRTT_m', 'LineOfSight_m'});
b4Range

% Put your Try-it prediction beside the range when each leg is 30 m longer.
nlosTry = 30;                                          % extra length on each leg, m (Try it)
tRxUEn = (dLOS + nlosTry)/c + bClk;                    % phone hears the reflection
tRxGNBn = (2*(dLOS + nlosTry)/c + wTA) + aClk;         % base station hears the reflected answer
sumN = (tRxGNBn - tTxGNB) + (tRxUEn - (tRxUEn + wTA)); % the same two readings, added
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, round(c*sumN/2 - dLOS, 4), predictionNote, ...
    VariableNames = {'MyPrediction', 'ExtraRange_m', 'Note'});
b4Prediction
%%
% The sum of the two readings equals 2d/c to a fraction of a picosecond, so 
% c·(sum)/2 gives the line-of-sight range with both clock offsets and the 
% turnaround gone. The sign slip is off by twice the turnaround, 24 µs, which 
% would be about 3.6 km. Change aClk, bClk, or wTA and the sum does not move. 
% Compare the blocked-path range with your prediction.
%% B4 — Assertion checks

% B4 has no assert: the identity holds for any offsets by the algebra of the timestamps,
% so the row below is a demonstration, labelled by construction. Pass is computed.
okIdentity = abs(sumRxTx - 2*dLOS/c) < 1e-15;
b4Checks = table("Sum of Rx-Tx equals 2d/c (by construction, not asserted)", ...
    string(round(2*dLOS/c*1e9, 3)) + " ns", string(round(sumRxTx*1e9, 3)) + " ns", okIdentity, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the beats' values; keep c, bs, ue, and listText for the Build it checks.
clear b4Rtt b4Range b4Prediction b4Checks predictionNote okIdentity ...
      dLOS aClk bClk wTA tTxGNB tRxUE tTxUE tRxGNB rxtxGNB rxtxUE sumRxTx slipRxTx dRtt ...
      nlosTry tRxUEn tRxGNBn sumN d myPrediction
%% Build it — From Rx–Tx readings to ranges, a blocked tower, and range differences
% Competency: turn a phone's and three base stations' Rx–Tx readings into 
% ranges, use a known test point to find the tower whose range is too long, 
% and turn the ranges into the range differences a TDOA solver would use.
% Problem
% In a test run, a phone stood at a surveyed point (240, 320) m. Three towers 
% at (0, 0), (600, 0), and (0, 800) m each measured a round trip with it. 
% The table of readings below gives each base station's Rx–Tx and the phone's 
% Rx–Tx, in nanoseconds. Turn the readings into ranges, compare them with 
% the straight-line distances to the surveyed point, find the tower whose 
% range is too long, and work out the two range differences (tower 2 minus 
% tower 1, tower 3 minus tower 1) and how many nanoseconds of timing the bad 
% tower's extra length is worth.
% Allowed commands
% x = value and [a b c]; + - * / and .^; sqrt(x); find(x > v, 1); indexing 
% such as x(k) and x(a:b). The tables and the figure in the check sections 
% and Stage 5 are given. All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myTowerX = [0 600 0];                    % tower x positions, m
% myTowerY = [0 0 800];                    % tower y positions, m
% myPoint = [240 320];                     % surveyed phone position, m
% myGnb = [3668.51 5713.31 7880.39];       % base-station Rx-Tx readings, ns
% myUe = [-1000 -2500 -4000];              % phone Rx-Tx readings, ns (negative: it receives before it sends)
%% Stage 1 check (given)
if ~exist('myTowerX','var') || ~exist('myTowerY','var') || ~exist('myPoint','var') || ~exist('myGnb','var') || ~exist('myUe','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal(myTowerX, [0 600 0]) && isequal(myTowerY, [0 0 800]) && isequal(myPoint, [240 320]) ...
        && isequal(myGnb, [3668.51 5713.31 7880.39]) && isequal(myUe, [-1000 -2500 -4000]);
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the five lines you uncommented: the towers, the point, and the two rows of readings.')
    stage1Checks = table("Given values", "towers, (240, 320), 3 + 3 readings", ...
        listText(myTowerX) + " / " + listText(myTowerY) + " / " + listText(myPoint) + " / " + listText(myGnb) + " / " + listText(myUe), ...
        okStage1, VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the round-trip ranges
% Fill the blanks: add each tower's two readings (entry by entry), then turn 
% the sums into ranges in metres. The readings are in nanoseconds, and c is 
% the speed of light from Staging.
% Pass: Stage 2 OK.

% mySum = ___ + ___;
% myRange = c*mySum*1e-9/___;
%% Stage 2 check (given; the check rebuilds each range from the two one-way times, a different route from yours)
if ~exist('mySum','var') || ~exist('myRange','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: one-way time = half of the gNB reading once the phone's turnaround (from its reading) is taken out.
    oneWayOracle = (myGnb - (-myUe))/2*1e-9;   % s
    rangeOracle = c*oneWayOracle;              % m
    okStage2 = [isequal(size(mySum), size(myGnb)) && max(abs(mySum - (myGnb + myUe))) < 1e-9; ...
                isequal(size(myRange), size(myGnb)) && max(abs(myRange - rangeOracle)) < 1e-6];
    assert(okStage2(1), ...
        'mySum is off. Common mistake: subtracting the phone reading; the two readings are added.')
    assert(okStage2(2), ...
        'myRange is off. Check the units: ns to s.')
    stage2Checks = table( ...
        ["Sum of the readings"; "Range per tower"], ...
        [listText(round(myGnb + myUe, 2)) + " ns"; listText(round(rangeOracle, 2)) + " m"], ...
        [listText(round(mySum, 2)) + " ns"; listText(round(myRange, 2)) + " m"], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then find the blocked tower
% Predict first: which tower (1, 2, or 3) has a range that is too long? Type 
% it into myPrediction. Then fill the blanks: the straight-line distance from 
% the surveyed point to each tower, the residual (measured range minus that 
% distance), and the first tower whose residual is more than 10 m.
% Pass: Stage 3 OK.

% myPrediction = ___;
% myGeo = sqrt((myPoint(1) - myTowerX).^2 + (___ - myTowerY).^2);
% myResid = myRange - ___;
% myBad = find(myResid > ___, 1);
%% Stage 3 check (given; the check uses hypot and a loop over towers, a different route from yours)
if ~exist('myGeo','var') || ~exist('myResid','var') || ~exist('myBad','var')
    disp('Stage 3 not done: fill the blanks, uncomment, and run.')
else
    % Different route: hypot for each distance, and a loop that stops at the first residual above 10 m.
    geoOracle = hypot(myPoint(1) - myTowerX, myPoint(2) - myTowerY);
    residOracle = rangeOracle - geoOracle;
    badOracle = NaN;
    % Walk the towers in order; stop at the first one more than 10 m too long.
    for n = 1:numel(residOracle)
        if residOracle(n) > 10
            badOracle = n;
            break
        end
    end
    okStage3 = [max(abs(myGeo - geoOracle)) < 1e-6; max(abs(myResid - residOracle)) < 1e-6; isequal(myBad, badOracle)];
    assert(okStage3(1), ...
        'myGeo is off. Look first at the y term: the x and y coordinates of the surveyed point must not be mixed up.')
    assert(okStage3(2), ...
        'myResid is off. Look first at the order: measured range minus the straight-line distance.')
    assert(okStage3(3), ...
        'myBad is off. Look first at the threshold: it is in metres, and find returns a tower number, not a residual.')
    if ~exist('myPrediction','var') || isnan(myPrediction)
        predictionNote = "No prediction typed";
    else
        predictionNote = "Compare your prediction with myBad";
    end
    stage3Prediction = table(string(predictionNote), VariableNames = {'Prediction'});
    stage3Prediction
    stage3Checks = table( ...
        ["Distances to the point"; "Residuals"; "First tower over 10 m"], ...
        [listText(round(geoOracle, 2)); listText(round(residOracle, 2)); string(badOracle)], ...
        [listText(round(myGeo, 2)); listText(round(myResid, 2)); string(myBad)], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — range differences, and the bad tower in nanoseconds
% Fill the blanks: the two range differences a TDOA solver would use (towers 
% 2 and 3, each minus tower 1), and the bad tower's extra length expressed 
% as a time in nanoseconds.
% Pass: Stage 4 OK.

% myDiff = myRange(___) - myRange(1);
% myErrNs = myResid(myBad)/___*1e9;
%% Stage 4 check (given; the check subtracts one tower at a time in a loop, a different route from yours)
if ~exist('myDiff','var') || ~exist('myErrNs','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: build each difference in a loop, and convert the extra length with the one-way time.
    diffOracle = zeros(1, 2);
    % Towers 2 and 3, each against tower 1 (the TDOA reference).
    for n = 2:3
        diffOracle(n - 1) = rangeOracle(n) - rangeOracle(1);
    end
    errNsOracle = residOracle(badOracle)/(c*1e-9);   % metres over metres per ns
    okStage4 = [isequal(size(myDiff), [1 2]) && max(abs(myDiff - diffOracle)) < 1e-6; abs(myErrNs - errNsOracle) < 1e-6];
    assert(okStage4(1), ...
        'myDiff is off. Look first at the indices: they must pick the other towers, not tower 1 again.')
    assert(okStage4(2), ...
        'myErrNs is off. Look first at the conversion: from metres to seconds first, then to nanoseconds.')
    stage4Checks = table( ...
        ["Range differences"; "Bad tower extra length as time"], ...
        [listText(round(diffOracle, 2)) + " m"; string(round(errNsOracle, 1)) + " ns"], ...
        [listText(round(myDiff, 2)) + " m"; string(round(myErrNs, 1)) + " ns"], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myRange','var') || ~exist('myResid','var') || ~exist('myDiff','var') || ~exist('myErrNs','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    good = setdiff(1:3, myBad);                                  % the towers that are not blocked
    buildFlags = [all(myRange > 0); ...
        all(abs(myResid(good)) < 1); ...
        myResid(myBad) > 0; ...
        myErrNs > 10];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["Every range is positive"; "Unblocked towers fit the point within 1 m"; ...
         "The blocked tower's range is too long, not too short"; "Its error is worth more than 10 ns of sync"], ...
        ["> 0 m"; "|residual| < 1 m"; "residual > 0"; "> 10 ns"], ...
        [listText(round(myRange, 1)); listText(round(myResid(good), 3)); string(round(myResid(myBad), 2)) + " m"; ...
         string(round(myErrNs, 1)) + " ns"], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: a circle of your range around each tower, and the surveyed point.
    figure(Name = 'Track 12 Build it - my ranges', Color = 'w');
    ang = linspace(0, 2*pi, 361);          % angles for drawing each circle, rad
    hold on;
    % One circle per tower, radius = your round-trip range.
    for n = 1:3
        plot(myTowerX(n) + myRange(n)*cos(ang), myTowerY(n) + myRange(n)*sin(ang));
    end
    plot(myTowerX, myTowerY, 'ks', myPoint(1), myPoint(2), 'go');
    axis equal;
    grid on;
    xlabel('x (m)');
    ylabel('y (m)');
    title(sprintf('My ranges: tower %d misses the point by %.1f m', myBad, myResid(myBad)));
end
%%
% Your interpretation (write one or two sentences here): which circle misses 
% the surveyed point, and on which side? Why is the error not removed by adding 
% the two readings, when the clock offsets and the turnaround are?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks oneWayOracle rangeOracle okStage2 stage2Checks ...
      geoOracle residOracle badOracle n okStage3 stage3Checks stage3Prediction predictionNote ...
      diffOracle errNsOracle okStage4 stage4Checks good buildFlags buildChecks ang
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B1)
% A PRS spans 272 RBs. How many REs does it use in one symbol with comb size 
% 2, and with comb size 12? How many in a slot of 12 PRS symbols for each? 
% Then say how a comb lets several cells share the same slot without colliding.
% 
% Your answer:
% E2 — New values (B2)
% At a sample rate of 122.88 MHz, how many metres is one sample? A carrier 
% of about 99 MHz has a resolution scale of about c/B. Work it out, and explain 
% why the bandwidth, not the sample rate alone, sets how sharp the timing is.
% 
% Your answer:
% E3 — Diagnosis (B3)
% Two things go wrong in a TDOA test. First, all three towers' clocks run 
% 10 ns late together. Second, separately, only tower 3's clock runs 25 ns 
% late. For each, say what happens to the two range differences and to the 
% fix, and give the size of any range-difference error in metres.
% 
% Your answer:
% E4 — New values (B4)
% A phone sits at a surveyed point exactly 300.0 m from a base station. The 
% base station reads gNB Rx–Tx = 18 001.4 ns. The phone reports its own reading 
% as +31 457 in units of Tc = 1/(480 000 × 4096) s, and its sign convention 
% is not documented: it may be Rx − Tx, as in B4, or Tx − Rx. Use the gNB 
% reading and the known range to find the phone's turnaround in µs and which 
% convention the phone uses. What range would you have computed if you had 
% assumed B4's convention without checking?
% 
% Your answer:
% E5 — Explanation (B4)
% Explain why a wider bandwidth sharpens the timing but does not fix a blocked 
% direct path. Then name one way a location function could notice that one 
% tower's range is too long, using only the measurements.
% 
% Your answer:
% E6 — Explanation (angles)
% In DL-AoD, one angle from one tower puts the phone on a line. How many towers' 
% angles are needed for a 2-D fix? What if one tower gives both an angle and 
% a round-trip range? Say what shape each measurement gives and where they 
% meet.
% 
% Your answer:
%% Recap — How Far (album track 12)
% Time is distance at about 30 cm per nanosecond. Each tower sends its own 
% PRS on a comb; a phone times each one against its own sequence and refines 
% the peak below one sample. Downlink TDOA turns arrival-time differences 
% into hyperbolas that cross at the fix, as long as the towers share time. 
% A round trip needs no shared clock, because each node subtracts only its 
% own readings. A blocked direct path adds length that nothing cancels.
% Key relationships
% $$d = c\,\tau,\qquad \Delta d_{i1} = c(\tau_i - \tau_1),\qquad d = \frac{c}{2}\left[(T_{\mathrm{gNB,Rx}} 
% - T_{\mathrm{gNB,Tx}}) + (T_{\mathrm{UE,Rx}} - T_{\mathrm{UE,Tx}})\right]$$
% What this means in practice
% • Read the sample rate from nrOFDMInfo and work out c/fs before trusting 
% a whole-sample delay.
% 
% • Time each tower against its own PRS (its own NPRSID), then refine the 
% peak with a parabola through mag.
% 
% • Form every difference against the same reference tower, and search for 
% the point that fits both differences.
% 
% • Add the two Rx–Tx readings, never subtract them.
% 
% • Treat a range that is too long as a possible blocked path, not as noise.
% 
% • You turned Rx–Tx readings into ranges, found the blocked tower from its 
% residual, and turned the ranges into range differences.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 11 (track11/track11_one_in_ten_demo), what block error rate does the 
% phone aim for on the first transmission when it reports a CQI from table 
% 1, and why is it the first transmission that counts?
% 
% • Next in the album: track13 (Signals from Orbit).
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
% • + - * / and .^:
% 
% • sqrt(x):
% 
% • find(x > v, 1):
% 
% • x(k) and x(a:b):
% What I missed, and where to reread it
% 
