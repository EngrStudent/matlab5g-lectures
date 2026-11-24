%% track14_mirror_image_demo
%% Mirror Image (album track 14): phase noise, IQ imbalance, the amplifier, and the EVM budget
% In Signals from Orbit, the distance to the satellite set the delays and 
% the frequency shifts. Now the trouble is inside the radio itself. No real 
% radio is perfect: the oscillator wanders, the I and Q rails never quite 
% match, and the amplifier runs out of room near the top of its range.
% 
% This demonstration adds each flaw on purpose to one slot of OFDM, measures 
% the EVM each one causes, and tests the one rule for combining them.
%% Guiding question
% How much does each flaw in a real radio cost in EVM, and how do several 
% flaws combine into one number you can hold against a limit?
% This demonstration
% 1. B1 — A clean baseline, then oscillator phase noise, before and after 
% removing the common phase error.
% 
% 2. B2 — IQ imbalance: the image at −k, measured against the image-rejection 
% ratio.
% 
% 3. B3 — Independent impairments add in power: phase noise and IQ imbalance, 
% alone and together.
% 
% 4. B4 — The amplifier and the back-off U-curve.
% 
% 5. Build it — An EVM budget: from mixer imbalance to an image-rejection 
% ratio, an EVM, a total, and a margin against the 64QAM limit.
% Key relationships
% EVM in percent, with reference symbols s and received symbols r:
% 
% $$\mathrm{EVM} = 100\sqrt{\frac{\sum |r - s|^2}{\sum |s|^2}}\ \%$$
% 
% Image-rejection ratio (IRR) for amplitude imbalance A (dB) and phase imbalance 
% P (degrees), with g = 10^{A/20}, and the EVM the image alone causes:
% 
% $$\mathrm{IRR} = \frac{g^2 + 2g\cos P + 1}{g^2 - 2g\cos P + 1},\qquad \mathrm{IRR_{dB}} 
% = 10\log_{10}\mathrm{IRR},\qquad \mathrm{EVM_{IQ}} \approx \frac{100}{\sqrt{\mathrm{IRR}}}\ \%$$
% 
% Independent impairments add in power (root-sum-square):
% 
% $$\mathrm{EVM_{total}} = \sqrt{\mathrm{EVM}_1^2 + \mathrm{EVM}_2^2 + \cdots}$$
% 
% Power in dBm (1 ohm reference) to watts:
% 
% $$P_{\mathrm{W}} = 10^{(P_{\mathrm{dBm}} - 30)/10}$$
% Key ideas to remember
% • No real radio is perfect. The oscillator wanders, the I and Q rails are 
% supposed to match in gain and sit exactly 90° apart but never quite do, 
% and the amplifier compresses near the top of its range.
% 
% • comm.PhaseNoise models oscillator wander with a level in dBc/Hz at a list 
% of offsets from the carrier; the default is −80 dBc/Hz at 2 kHz and −100 
% dBc/Hz at 20 kHz. In OFDM the slow part turns every subcarrier in a symbol 
% by the same angle, a common phase error (CPE) that a receiver can track; 
% the fast part leaks each subcarrier into its neighbours and acts like noise.
% 
% • IQ imbalance puts a faint twin at the mirrored frequency: what you send 
% on subcarrier k shows up again on −k. iqimbal applies it, with an amplitude 
% imbalance in dB and a phase imbalance in degrees. Match the gains and fix 
% the angle and the twin fades; comm.IQImbalanceCompensator estimates it and 
% takes it back out.
% 
% • Near the top of its range an amplifier's gain compresses and its phase 
% twists with the input level (AM/AM and AM/PM). comm.MemorylessNonlinearity 
% models it with a cubic polynomial by default, or a Saleh, Ghorbani, or modified 
% Rapp model, or a table you measured.
% 
% • OFDM has big peaks, so you back the amplifier off. Every decibel of back-off 
% lowers the distortion but also lowers the signal while the receiver noise 
% stays where it was: EVM falls, bottoms out, and rises again.
% 
% • EVM: subtract the ideal symbol, square the error, average, divide by the 
% average reference power, take the root, and say it as a percentage. comm.EVM 
% normalizes by the average reference power by default. The 3GPP base-station 
% limits (TS 38.104) run tighter as the order climbs: 17.5 % for QPSK, 12.5 
% % for 16QAM, 8 % for 64QAM, and 3.5 % for 256QAM.
% 
% • Independent impairments add in power, not in percent: three percent from 
% one and four percent from another make five, not seven.
% Prerequisites
% • EVM measured by hand, the noise EVM formula, and the 38.104 limits (album 
% track 02 Copy the Tail, track02/track02_copy_the_tail_demo).
% 
% • OFDM modulation, the cyclic prefix, and the resource grid (track 00 Fundamentals, 
% track00_fundamentals/p00a_ofdm_and_cp_demo).
% 
% • Inter-carrier interference from a frequency error (album track 02 Copy 
% the Tail, B3).
% Words used in this demo
% • Phase noise: random wander of the oscillator phase. dBc/Hz: power per 
% hertz relative to the carrier, at a given offset from it.
% 
% • CPE (common phase error): the part of the phase noise that turns every 
% subcarrier of one OFDM symbol by the same angle. ICI (inter-carrier interference): 
% leakage from each subcarrier into its neighbours.
% 
% • IQ imbalance: a gain mismatch (A, dB) and an angle error (P, degrees) 
% between the I and Q rails of a mixer. Image: the faint copy at the mirrored 
% subcarrier. IRR (image-rejection ratio): wanted power over image power.
% 
% • AM/AM: output amplitude that stops growing with input (compression). AM/PM: 
% output phase that changes with input level. IIP3: input third-order intercept 
% point, in dBm, a measure of how linear an amplifier is. Back-off: running 
% the input below the level where compression starts.
% 
% • EVM budget: a list of the EVM each impairment may use, combined by root-sum-square 
% (rss) and compared with a limit. Margin: the limit minus the total.
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
% • + - * / and ^ — Purpose: arithmetic and powers. Inputs: numbers. Outputs: 
% the result.
% 
% • 10^(x/20), 10^(x/10), and log10(x) — Purpose: from decibels to a ratio 
% (amplitude or power) and back. Inputs: a number. Outputs: a number.
% 
% • sqrt(x) and cosd(e) — Purpose: square root; cosine of an angle in degrees. 
% Inputs: a number; an angle in degrees. Outputs: a number.
% 
% • a <= b — Purpose: test whether a is at most b. Inputs: two numbers. Outputs: 
% true or false.
% 
% Commands you read in the given code
% • carrier = nrCarrierConfig(...), ofdmInfo = nrOFDMInfo(carrier), nrResourceGrid, 
% nrOFDMModulate, nrOFDMDemodulate — Purpose: a carrier, its sample rate, 
% an empty grid, a waveform, and the grid back from a waveform. Inputs: spacing 
% (kHz), RBs; a grid or a waveform. Outputs: objects, a structure, a grid, 
% a waveform.
% 
% • evmPct(ref, rx) and cpeFix(ref, rx) — the two helpers defined in Staging: 
% EVM in percent, and the grid with one common phase per OFDM symbol removed.
% 
% • comm.PhaseNoise, comm.EVM, iqimbal, comm.MemorylessNonlinearity — Used 
% in one beat each; listed there.
% 
% • Figure family: figure(Name = ...), plot, bar, yline, xline, xticklabels, 
% legend, grid on, xlabel, ylabel, title — Purpose: draw curves and bars and label them. 
% Inputs: data and text. Outputs: a figure.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing, ranges, and loops: x(k), x(:), x(end), a:b:c, for k = ... end, 
% if ... end — Purpose: read or write entries, step through values, repeat, 
% choose. Inputs: arrays, ranges, tests. Outputs: the entries or the repeated 
% work.
% 
% • Compare and combine: == < > <= >=, ~, &&, any, all — Purpose: compare 
% values; not; and; any or every entry true. Inputs: numbers or arrays. Outputs: 
% true/false.
% 
% • Built-in helpers: abs, angle, conj, exp, real, imag, pi, max, min, sum, 
% mean, numel, size, zeros, round, randi, randn, hypot, rad2deg, isnan, NaN 
% — Purpose: sizes, sums, complex helpers, random values, and the length of 
% a vector by Pythagoras (hypot). Inputs: numbers or arrays. Outputs: numbers 
% or arrays (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, and f = @(v) ... — Purpose: 
% write and join text, turn numbers into text, and make a one-line helper such 
% as evmPct. Inputs: text or numbers. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), error, fprintf, disp, exist, ver, clear, close all, rng(seed) — 
% Purpose: show columns side by side, stop with a hint when a check fails, 
% stop early with a message, print a banner or note, check for a toolbox, 
% remove variables or figures, repeat random values. Inputs: columns, a test 
% and message, text, names, a seed. Outputs: a shown table or line; an error 
% if a check fails.
% Working status
% Status: unverified until M runs it in R2024b.
% 
% Teaching draft built to the track01 r03 template (track14 r01, 2026-11-20) 
% from the live track14_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox and 
% the Communications Toolbox (comm.PhaseNoise, iqimbal, comm.EVM, comm.MemorylessNonlinearity); 
% Staging stops with a message if the Communications Toolbox is missing. One 
% slot of QPSK on every resource element stands in for the song's 64QAM waveform: 
% phase noise, IQ imbalance, and the amplifier cost the same EVM for any constellation 
% of unit average power. Teaching demo, not production code; not affiliated 
% with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year): the grid, the phase noise, and the added noise repeat

% Stop early with a clear message if the Communications Toolbox is missing.
if isempty(ver('comm'))
    error('This track needs the Communications Toolbox (comm.PhaseNoise, iqimbal, comm.EVM, comm.MemorylessNonlinearity). Install it, then run again.')
end

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
listText = @(v) strjoin(string(v(:).'), " ");

% Two helpers used in every beat: EVM in percent (the formula in Key relationships),
% and the common-phase fix (one angle per OFDM symbol, that is, per grid column).
evmPct = @(ref, rx) 100*sqrt(sum(abs(rx(:) - ref(:)).^2)/sum(abs(ref(:)).^2));
cpeFix = @(ref, rx) rx.*exp(-1j*angle(sum(conj(ref).*rx, 1)));

% One slot of OFDM with QPSK on every resource element.
carrier = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);   % kHz, RBs: 624 subcarriers on a 1024-point FFT
ofdmInfo = nrOFDMInfo(carrier);
fs = ofdmInfo.SampleRate;                % 15.36 MHz for this carrier
txGrid = nrResourceGrid(carrier);        % 624 x 14, one slot
K = size(txGrid, 1);                     % number of subcarriers (624)
bitsI = randi([0 1], size(txGrid));      % random I bits
bitsQ = randi([0 1], size(txGrid));      % random Q bits
txGrid(:) = ((1 - 2*bitsI(:)) + 1j*(1 - 2*bitsQ(:)))/sqrt(2);   % QPSK, unit average power
wave = nrOFDMModulate(carrier, txGrid, Windowing = 0);          % no windowing, so the clean round trip is exact
demod = @(w) nrOFDMDemodulate(carrier, w, CyclicPrefixFraction = 1);   % FFT window right after each cyclic prefix
%% B1 — A clean baseline, then phase noise
% New words
% • Phase-noise mask: the list of levels (dBc/Hz) at the list of offsets 
% (Hz) that describes an oscillator.
% Beat-only commands
% • pnoise = comm.PhaseNoise(Level = L, FrequencyOffset = f, SampleRate = 
% fs) — an oscillator with mask L at offsets f; y = pnoise(x) applies it. 
% 
% • evmMeter = comm.EVM; evmMeter(ref, rx) — the toolbox EVM meter, in percent, 
% normalized by the average reference power.
% Why it matters
% Before blaming any flaw, check the chain itself: a clean slot sent straight 
% from the modulator to the demodulator must come back with essentially zero 
% EVM. Then add an oscillator. Its slow wander turns each whole OFDM symbol 
% by one angle, the common phase error; a receiver can measure that angle 
% and turn it back. Its fast wander leaks each subcarrier into its neighbours, 
% and no single angle per symbol can undo that.
% What to look for
% • In the EVM table: the clean EVM, the EVM with phase noise before and 
% after the CPE fix, and the toolbox meter beside the hand formula.
% 
% • In the phase table: the common phase of each of the 14 symbols, wandering 
% across the slot.
% Common mistakes
% Do not expect the CPE fix to remove the fast part: no single angle per 
% symbol can undo leakage between subcarriers.
% 
% Do not call every rotation IQ imbalance: a rotation that is the same on 
% every subcarrier of a symbol is CPE.
% Try it (personal exploration)
% Raise the whole phase-noise mask by 10 dB (ten times the phase-noise power, 
% the same wander). Predict the factor by which the EVM after the CPE fix grows. 
% Type it into myPrediction before you run this section; the one-row table 
% at the end measures it with the same wander scaled up.

% Try it: type your prediction here (a factor, for example 2) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — A clean baseline, then phase noise
fprintf("B1 — A clean baseline, then phase noise\n");   % banner title only; every number below goes into a table

% The clean round trip: modulate, demodulate, compare.
rx0 = demod(wave);
evmClean = evmPct(txGrid, rx0);          % percent; should be at rounding level

% An oscillator with most of its wander at low offsets and a low floor far out.
pnLevel = [-70 -110];                    % phase-noise mask, dBc/Hz
pnOffset = [1e3 1e5];                    % offsets for those levels, Hz (1 kHz and 100 kHz)
pnoise = comm.PhaseNoise(Level = pnLevel, FrequencyOffset = pnOffset, SampleRate = fs);
wPN = pnoise(wave);                      % one phase-noise realization, kept for B3
rxPN = demod(wPN);
evmPN = evmPct(txGrid, rxPN);                       % before the CPE fix, percent
evmPNfix = evmPct(txGrid, cpeFix(txGrid, rxPN));    % after the CPE fix, percent
cpeDeg = rad2deg(angle(sum(conj(txGrid).*rxPN, 1)));   % the common phase of each symbol, degrees

% The toolbox meter on the same data, as a second opinion on the formula.
evmMeter = comm.EVM;                     % default: percent RMS, normalized by the average reference power
evmTool = evmMeter(txGrid(:), rxPN(:));

% Two tests: the chain is clean, and the common phase really wanders across the slot
% (the slow part the per-symbol fix tracks). The spread ignores the random absolute offset.
cpeSpread = max(cpeDeg) - min(cpeDeg);   % degrees, across the 14 symbols
okClean = evmClean < 1e-6;
assert(okClean, ...
    'The clean round trip should have no EVM. Look first at the carrier: the modulator and the demodulator must use the same carrier object, or every resource element moves.');
okCpe = cpeSpread > 1;
assert(okCpe, ...
    'The common phase should wander by more than 1 degree across the slot. Look first at pnLevel: the first (low-offset) level sets the slow wander; lowered toward the second, the common phase barely moves. Also check cpeDeg uses rxPN, not the clean grid.');

b1Evm = table(["Clean"; "Phase noise, before CPE fix"; "Phase noise, after CPE fix"], ...
    round([evmClean; evmPN; evmPNfix], 3), round([NaN; evmTool; NaN], 3), ...
    VariableNames = {'Case', 'EVM_percent', 'commEVM_percent'});
b1Evm

b1Phase = table((0:13).', round(cpeDeg(:), 2), VariableNames = {'Symbol', 'CommonPhase_deg'});
b1Phase

% Try it: the same wander with the mask 10 dB higher (ten times the phase power), through the same receiver.
pnPhase = angle(wPN./wave);                       % the phase comm.PhaseNoise added, sample by sample
wTry = wave.*exp(1j*sqrt(10)*pnPhase);            % phase power times 10 is phase amplitude times sqrt(10)
evmTry = evmPct(txGrid, cpeFix(txGrid, demod(wTry)));
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, round(evmTry/evmPNfix, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'MeasuredFactor', 'Note'});
b1Prediction
%%
% The clean EVM is at rounding level, so anything above it comes from the 
% flaw you add. With phase noise, the common phase of each symbol drifts by 
% degrees across one slot; that drift is most of the EVM before the fix. After 
% the fix only the fast part is left, a small fraction. The toolbox meter 
% agrees with the hand formula. Compare the measured factor with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["Clean round-trip EVM"; "Common phase wanders across the slot (max - min)"], ...
    ["< 1e-6 percent"; "> 1 degree"], ...
    [string(evmClean) + " percent"; string(round(cpeSpread, 2)) + " degrees"], ...
    [okClean; okCpe], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep wPN and evmPNfix: B3 reuses the same phase-noise wave.
clear b1Evm b1Phase b1Checks b1Prediction predictionNote okClean okCpe cpeSpread ...
      rx0 evmClean pnLevel pnOffset pnoise rxPN evmPN cpeDeg evmMeter evmTool ...
      pnPhase wTry evmTry myPrediction
%% B2 — IQ imbalance: the image at −k
% New words
% • Mirror row: the grid row at the opposite frequency. Grid row r (1-based) 
% sits r − 1 − K/2 subcarriers from the centre, so the mirror of row k is 
% row K − k + 2.
% Beat-only commands
% • y = iqimbal(x, A, P) — applies amplitude imbalance A (dB) and phase imbalance 
% P (degrees) to a complex waveform x. Outputs: the imbalanced waveform.
% Why it matters
% If the I and Q rails differ in gain or are not exactly 90° apart, the mixer 
% output is the wanted signal plus a faint complex-conjugate copy. In frequency, 
% the conjugate flips the spectrum, so what you send on subcarrier k appears 
% again on −k. With every subcarrier occupied, each subcarrier's image lands 
% on top of the data of its mirror and looks like noise. The formula in Key 
% relationships predicts how far down the image sits (the IRR) and the EVM 
% it causes. This beat tests both: the image with one tone, and the EVM with 
% a full grid.
% What to look for
% • In the image table: the wanted and mirror-row magnitudes, their ratio 
% in dB, and the IRR from the formula.
% 
% • In the EVM table: the full-grid EVM beside 100/√IRR.
% 
% • In the figure: two spikes, one at the tone and one at the mirrored subcarrier.
% Common mistakes
% Do not look for the image at +k (that is the tone itself) or at the centre 
% subcarrier: it sits at the opposite frequency.
% 
% Do not confuse the image with CPE from B1: CPE turns every subcarrier by 
% one angle and moves no power between subcarriers; the image moves power 
% from k to −k.
% Try it (personal exploration)
% Double the amplitude imbalance to A = 1 dB, with the same P = 2°. Predict 
% the wanted-to-image ratio, in dB, that the tone measurement will show. Type 
% it into myPrediction before you run this section; the one-row table at the 
% end measures it.

% Try it: type your prediction here (dB) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — IQ imbalance: the image at -k
fprintf("B2 — IQ imbalance: the image at -k\n");   % banner title only; every number below goes into a table

A = 0.5;                 % amplitude imbalance, dB
P = 2;                   % phase imbalance, degrees
g = 10^(A/20);           % amplitude ratio between the rails
irr = (g^2 + 2*g*cosd(P) + 1)/(g^2 - 2*g*cosd(P) + 1);   % image-rejection ratio (power ratio)
irrDb = 10*log10(irr);   % the same, in dB
evmFormula = 100/sqrt(irr);   % EVM from the image alone, percent

% One tone, away from the centre, and the row at the opposite frequency.
probe = nrResourceGrid(carrier);
kWanted = 60;                     % 1-based row: 60 - 1 - 312 = -253 subcarriers from the centre
kMirror = K - kWanted + 2;        % the row at +253 subcarriers
probe(kWanted, 1) = 1;            % the tone, in the first symbol only
wProbe = nrOFDMModulate(carrier, probe, Windowing = 0);
rxIQ = demod(iqimbal(wProbe, A, P));
magWanted = abs(rxIQ(kWanted, 1));
magMirror = abs(rxIQ(kMirror, 1));
irrMeasDb = 20*log10(magWanted/max(magMirror, eps));   % measured wanted over image, dB

% The full grid through the same mixer: every subcarrier's image lands on its mirror's data.
evmIQ = evmPct(txGrid, demod(iqimbal(wave, A, P)));

% Two tests: the tone's image sits at the IRR, and the full-grid EVM matches 100/sqrt(IRR).
okMirror = abs(irrMeasDb - irrDb) < 0.5;
assert(okMirror, ...
    'The image should sit about IRR dB below the tone. Look first at kMirror: the opposite frequency is row K - kWanted + 2; one row off reads an empty subcarrier.');
okEvmIQ = abs(evmIQ - evmFormula) < 0.1;
assert(okEvmIQ, ...
    'The full-grid EVM should match 100/sqrt(IRR). Look first at the input to iqimbal: it must be the full-grid wave, not the one-tone probe.');

b2Image = table(["Wanted (row " + kWanted + ", " + (kWanted - 1 - K/2) + " sc)"; ...
                 "Mirror (row " + kMirror + ", +" + (kMirror - 1 - K/2) + " sc)"], ...
    round([magWanted; magMirror], 5), [NaN; round(irrMeasDb, 2)], [NaN; round(irrDb, 2)], ...
    VariableNames = {'Row', 'Magnitude', 'MeasuredRatio_dB', 'FormulaIRR_dB'});
b2Image

b2Evm = table(A, P, round(evmIQ, 3), round(evmFormula, 3), ...
    VariableNames = {'A_dB', 'P_deg', 'GridEVM_percent', 'Formula_percent'});
b2Evm

figure(Name = "Track 14 — mirror image");
plot((0:K-1) - K/2, 20*log10(abs(rxIQ(:, 1)) + 1e-12));   % add 1e-12 so empty rows plot as a low floor, not minus infinity
grid on;
xline([kWanted kMirror] - 1 - K/2, ':');
xlabel('subcarrier from the centre'); ylabel('|RE| (dB)');
title('B2: one tone and its image at the mirrored subcarrier');

% Try it: A = 1 dB on the same tone.
tryA = 1;                                % amplitude imbalance for the Try, dB
rxTry = demod(iqimbal(wProbe, tryA, P));
tryRatioDb = 20*log10(abs(rxTry(kWanted, 1))/max(abs(rxTry(kMirror, 1)), eps));
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, round(tryRatioDb, 2), predictionNote, ...
    VariableNames = {'MyPrediction_dB', 'Measured_dB', 'Note'});
b2Prediction
%%
% The tone's image sits at the mirrored subcarrier, about 29.5 dB down, which 
% is the IRR from the formula. With every subcarrier occupied the images land 
% on data and act like noise of 100/√IRR percent, about 3.4 %. Compare the 
% Try measurement with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Tone image ratio matches the IRR"; "Full-grid EVM matches 100/sqrt(IRR)"], ...
    [string(round(irrDb, 2)) + " dB (within 0.5)"; string(round(evmFormula, 3)) + " percent (within 0.1)"], ...
    [string(round(irrMeasDb, 2)) + " dB"; string(round(evmIQ, 3)) + " percent"], ...
    [okMirror; okEvmIQ], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep A and P: B3 uses the same mixer.
clear b2Image b2Evm b2Checks b2Prediction predictionNote okMirror okEvmIQ ...
      g irr irrDb evmFormula probe kWanted kMirror wProbe rxIQ magWanted magMirror irrMeasDb ...
      evmIQ tryA rxTry tryRatioDb myPrediction
%% B3 — Independent impairments add in power
% New words
% • Root-sum-square (rss): the square root of the sum of the squares. hypot(a, 
% b) is the rss of two numbers.
% Beat-only commands
% None beyond Staging and the commands above.
% Why it matters
% A real transmitter has several flaws at once. If they are independent and 
% small, their error vectors point in unrelated directions, so their powers 
% add, not their lengths. That rule turns a list of EVMs into one total you 
% can hold against a limit. This beat tests it on phase noise (after the CPE 
% fix, so only its fast part is left) and IQ imbalance: each alone, then both, 
% with the same phase-noise wander every time.
% What to look for
% • In the budget table: phase noise alone, IQ imbalance alone, both together, 
% the rss prediction, and the plain sum of the percentages.
% Common mistakes
% Do not add the percentages themselves: that overstates the total whenever 
% more than one term is large.
% 
% Do not draw a new phase-noise wander for the "both" run: the comparison 
% only holds with the same wander in every case.
% Try it (personal exploration)
% Now pair the IQ imbalance with receiver noise instead of phase noise. Noise 
% alone costs about 4.5 % here, and the IQ imbalance alone about 3.4 %. Predict 
% the EVM with both, in percent. Type it into myPrediction before you run 
% this section; the one-row table at the end measures it.

% Try it: type your prediction here (percent) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Independent impairments add in power
fprintf("B3 — Independent impairments add in power\n");   % banner title only; every number below goes into a table

% Each impairment alone, then both, with the CPE fix on every case.
evmPnOnly = evmPNfix;                                                % from B1: the same wander, after the CPE fix
evmIqOnly = evmPct(txGrid, cpeFix(txGrid, demod(iqimbal(wave, A, P))));
evmBoth = evmPct(txGrid, cpeFix(txGrid, demod(iqimbal(wPN, A, P))));   % the B1 wander, then the mixer
evmRss = hypot(evmPnOnly, evmIqOnly);    % rss prediction, percent
evmLinear = evmPnOnly + evmIqOnly;       % the plain sum, percent

% One test: the measured total matches the rss within 10 percent of it.
okRss = abs(evmBoth - evmRss) < 0.1*evmRss;
assert(okRss, ...
    'Both-on EVM should match the rss of the two. Look first at the both-on wave: it must reuse wPN from B1 (a new pnoise call draws a new wander), with cpeFix on every case.');

b3Budget = table(["Phase noise alone (after CPE fix)"; "IQ imbalance alone"; "Both, measured"; ...
                  "rss prediction"; "Plain sum"], ...
    round([evmPnOnly; evmIqOnly; evmBoth; evmRss; evmLinear], 3), ...
    VariableNames = {'Case', 'EVM_percent'});
b3Budget

% Try it: receiver noise added to the time samples, then the same mixer.
snrDb = 24.8;                            % signal-to-noise ratio for the Try, dB (relative to the average sample power)
noiseStd = sqrt(mean(abs(wave).^2)/10^(snrDb/10));   % noise standard deviation per complex sample
noise = noiseStd*(randn(size(wave)) + 1j*randn(size(wave)))/sqrt(2);
evmNoiseOnly = evmPct(txGrid, demod(wave + noise));
evmIqNoise = evmPct(txGrid, cpeFix(txGrid, demod(iqimbal(wave, A, P) + noise)));
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the last two numbers";
end
b3Prediction = table(round(evmNoiseOnly, 2), round(evmIqOnly, 2), myPrediction, round(evmIqNoise, 2), predictionNote, ...
    VariableNames = {'NoiseAlone_percent', 'IQAlone_percent', 'MyPrediction', 'Both_percent', 'Note'});
b3Prediction
%%
% The measured total lands on the rss of the two parts, not on their sum: 
% the two error vectors are unrelated, so their powers add. That is the rule 
% the Build it uses for a whole budget. Compare the Try measurement with your 
% prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flag.
b3Checks = table("Both-on EVM matches the rss", ...
    string(round(evmRss, 3)) + " percent (within 10 percent of it)", string(round(evmBoth, 3)) + " percent", okRss, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the phase noise or the mixer.
clear b3Budget b3Checks b3Prediction predictionNote okRss ...
      evmPnOnly evmIqOnly evmBoth evmRss evmLinear wPN evmPNfix A P ...
      snrDb noiseStd noise evmNoiseOnly evmIqNoise myPrediction
%% B4 — The amplifier and the back-off U-curve
% New words
% • Drive: the average input power into the amplifier, in dBm. dBm: decibels 
% relative to 1 mW (here with a 1 ohm reference).
% Beat-only commands
% • pa = comm.MemorylessNonlinearity(Method = "Cubic polynomial", LinearGain 
% = 0, IIP3 = x, AMPMConversion = 0) — a memoryless amplifier: no gain, an 
% IIP3 of x dBm, and no AM/PM. y = pa(x) applies it.
% Why it matters
% An OFDM waveform has peaks several dB above its average. Drive the amplifier 
% hard and the peaks compress, which bends the constellation. Back the drive 
% off and the compression fades, but the signal also sinks toward the noise 
% of the receive chain, which does not move. So EVM against drive is a U: 
% noise on the left arm, compression on the right, and a best drive in between. 
% Here the noise is a fixed floor added after the amplifier, standing in for 
% the whole receive chain. AMPMConversion is set to 0 here, so this curve 
% shows the amplitude compression on its own; E6 asks what the default would 
% change.
% What to look for
% • In the figure: EVM against drive, falling on the left, rising on the right.
% 
% • In the U-curve table: the drive with the lowest EVM, its EVM, and how 
% far below the IIP3 it sits.
% Common mistakes
% Do not assume more back-off is always cleaner: that forgets the noise floor.
% 
% Do not score only the one drive you already tuned by hand: sweep, and check 
% the minimum is not at the edge of the sweep.
% Try it (personal exploration)
% Replace the amplifier with a more linear one, IIP3 = 20 dBm instead of 10, 
% with the same noise floor. Predict how many dB the best drive moves, and 
% in which direction. Type the number of dB into myPrediction (positive for 
% higher drive) before you run this section; the one-row table at the end 
% sweeps the new amplifier.

% Try it: type your prediction here (dB, positive = higher drive) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — The amplifier and the back-off U-curve
fprintf("B4 — The amplifier and the back-off U-curve\n");   % banner title only; every number below goes into a table

iip3 = 10;                    % amplifier input third-order intercept, dBm
pa = comm.MemorylessNonlinearity(Method = "Cubic polynomial", LinearGain = 0, ...
    IIP3 = iip3, AMPMConversion = 0);   % LinearGain in dB; AM/PM off so only compression shows
noiseFloor = -50;             % noise power added after the amplifier, dBm (stands in for the receive chain)
pinSweep = -30:2:6;           % drive into the amplifier, dBm (back-off = moving left)
rmsWave = sqrt(mean(abs(wave).^2));   % RMS of the unscaled waveform
noiseDraw = (randn(size(wave)) + 1j*randn(size(wave)))/sqrt(2);   % one unit-power noise draw, reused at every drive so the curve is smooth
nAmp = sqrt(10^((noiseFloor - 30)/10));   % noise amplitude, sqrt(W)

evmU = zeros(size(pinSweep));
% For each drive: scale the wave to that power, amplify, add the floor, scale back, measure.
for k = 1:numel(pinSweep)
    gIn = sqrt(10^((pinSweep(k) - 30)/10))/rmsWave;   % amplitude scale that sets the drive
    y = pa(wave*gIn) + nAmp*noiseDraw;
    evmU(k) = evmPct(txGrid, demod(y/gIn));
end
[evmMin, kMin] = min(evmU);

% One test: the lowest EVM sits inside the sweep, so both arms are present.
okInterior = kMin > 1 && kMin < numel(pinSweep);
assert(okInterior, ...
    'The U-curve minimum should be inside the sweep. Look first at the noise: noiseFloor must be finite and the noise added after pa, or the left arm vanishes.');

b4U = table(pinSweep(:), round(evmU(:), 2), VariableNames = {'Drive_dBm', 'EVM_percent'});
b4U

b4Min = table(pinSweep(kMin), round(evmMin, 2), iip3 - pinSweep(kMin), ...
    VariableNames = {'BestDrive_dBm', 'EVM_percent', 'BelowIIP3_dB'});
b4Min

figure(Name = "Track 14 — amplifier U-curve");
plot(pinSweep, evmU, '-o'); grid on;
xline(pinSweep(kMin), ':');
xlabel('drive into the amplifier (dBm); back-off = moving left'); ylabel('EVM (%)');
title('B4: back-off U-curve (noise arm left, compression arm right)');

% Try it: the same floor with a more linear amplifier, on a wider sweep.
paTry = comm.MemorylessNonlinearity(Method = "Cubic polynomial", LinearGain = 0, ...
    IIP3 = 20, AMPMConversion = 0);    % IIP3 in dBm for the Try
pinTry = -30:2:16;                     % wider sweep for the Try, dBm
evmTryU = zeros(size(pinTry));
% Same steps as the sweep above, with the Try amplifier.
for k = 1:numel(pinTry)
    gIn = sqrt(10^((pinTry(k) - 30)/10))/rmsWave;
    evmTryU(k) = evmPct(txGrid, demod((paTry(wave*gIn) + nAmp*noiseDraw)/gIn));
end
[~, kTry] = min(evmTryU);
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers (2 dB sweep steps)";
end
b4Prediction = table(myPrediction, pinTry(kTry) - pinSweep(kMin), predictionNote, ...
    VariableNames = {'MyPrediction_dB', 'MeasuredMove_dB', 'Note'});
b4Prediction
%%
% On the left the signal sinks into the fixed floor; on the right the peaks 
% compress. The best drive sits well below the IIP3, by about the 
% peak-to-average ratio and then some. Compare the Try move with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flag.
b4Checks = table("U-curve minimum inside the sweep", ...
    "between " + pinSweep(1) + " and " + pinSweep(end) + " dBm, not at either end", ...
    string(pinSweep(kMin)) + " dBm", okInterior, ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the beats' values; keep listText and evmPct for the Build it checks,
% and the carrier, grid, wave, and demod for the Build it oracles.
clear b4U b4Min b4Checks b4Prediction predictionNote okInterior ...
      iip3 pa noiseFloor pinSweep rmsWave noiseDraw nAmp evmU k gIn y evmMin kMin ...
      paTry pinTry evmTryU kTry myPrediction
%% Build it — An EVM budget against the 64QAM limit
% Competency: from a mixer's amplitude and phase imbalance, compute its image-rejection 
% ratio and the EVM it causes, combine it with the other impairments by root-sum-square, 
% and say whether the total meets a limit and with how much margin.
% Problem
% A transmitter's mixer has 0.3 dB amplitude imbalance and 1.5° phase imbalance. 
% Its oscillator leaves 2.5 % EVM after the CPE fix, and the amplifier at 
% its chosen drive costs 3.0 %. The waveform is 64QAM, with the 38.104 limit 
% of 8 %. Work out the IRR (as a ratio and in dB), the EVM the image causes, 
% the total EVM, the margin, and whether the budget is met.
% Allowed commands
% x = value and [a b c]; + - * / and ^; 10^(x/20), 10^(x/10), and log10(x); 
% sqrt(x) and cosd(e); a <= b. The tables in the check sections and Stage 
% 5 are given. All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myA = 0.3;           % amplitude imbalance, dB
% myP = 1.5;           % phase imbalance, degrees
% myEvmPn = 2.5;       % phase noise after the CPE fix, percent
% myEvmPa = 3.0;       % amplifier at its drive, percent
% myLimit = 8;         % 38.104 limit for 64QAM, percent
%% Stage 1 check (given)
if ~exist('myA','var') || ~exist('myP','var') || ~exist('myEvmPn','var') || ~exist('myEvmPa','var') || ~exist('myLimit','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = myA == 0.3 && myP == 1.5 && myEvmPn == 2.5 && myEvmPa == 3.0 && myLimit == 8;
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the five lines you uncommented: 0.3 dB, 1.5 degrees, 2.5 %, 3.0 %, 8 %.')
    stage1Checks = table("Given values", "0.3, 1.5, 2.5, 3, 8", ...
        listText([myA myP myEvmPn myEvmPa myLimit]), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the image-rejection ratio
% Fill the blanks: the amplitude ratio from the imbalance in dB, then the 
% IRR formula from Key relationships, then the IRR in dB.
% Pass: Stage 2 OK.

% myG = 10^(myA/___);
% myIrr = (myG^2 + 2*myG*cosd(myP) + 1)/(myG^2 - 2*myG*cosd(___) + 1);
% myIrrDb = 10*log10(___);
%% Stage 2 check (given; the check sends one tone through iqimbal and measures the image, a different route from yours)
if ~exist('myIrr','var') || ~exist('myIrrDb','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: a tone on row 60 through iqimbal, then the wanted over the mirror row.
    oracleProbe = nrResourceGrid(carrier);
    oracleProbe(60, 1) = 1;                                      % the tone, row 60
    oracleRx = demod(iqimbal(nrOFDMModulate(carrier, oracleProbe, Windowing = 0), myA, myP));
    irrOracleDb = 20*log10(abs(oracleRx(60, 1))/abs(oracleRx(K - 60 + 2, 1)));   % dB
    okStage2 = abs(myIrrDb - irrOracleDb) < 0.05 && abs(10*log10(myIrr) - myIrrDb) < 1e-9;
    assert(okStage2, ...
        'myIrr or myIrrDb is off. Look first at the amplitude ratio: an imbalance in dB between two rails is a voltage (amplitude) ratio, not a power ratio.')
    stage2Checks = table("Image-rejection ratio", string(round(irrOracleDb, 2)) + " dB", ...
        string(round(myIrrDb, 2)) + " dB", okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then the image EVM
% Predict first: the total EVM of the whole budget, in percent. Type it into 
% myPrediction. Then fill the blank: the EVM the image alone causes, from 
% the IRR.
% Pass: Stage 3 OK.

% myPrediction = ___;
% myEvmIq = 100/sqrt(___);
%% Stage 3 check (given; the check sends a full random grid through iqimbal and measures its EVM, a different route from yours)
if ~exist('myEvmIq','var')
    disp('Stage 3 not done: fill the blank, uncomment, and run.')
else
    % Different route: the full-grid wave through iqimbal, then the EVM by the Staging helper.
    evmIqOracle = evmPct(txGrid, demod(iqimbal(wave, myA, myP)));   % percent
    okStage3 = abs(myEvmIq - evmIqOracle) < 0.05;
    assert(okStage3, ...
        'myEvmIq is off. Look first at what goes under the root: it must be a plain ratio, not a value in dB.')
    stage3Checks = table("Image EVM", string(round(evmIqOracle, 3)) + " percent", ...
        string(round(myEvmIq, 3)) + " percent", okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — the total, the margin, and the verdict
% Fill the blanks: the root-sum-square of the three EVMs, the margin to the 
% limit, and whether the budget is met.
% Pass: Stage 4 OK.

% myTotal = sqrt(myEvmIq^2 + ___^2 + myEvmPa^2);
% myMargin = myLimit - ___;
% myPass = myTotal <= ___;
%% Stage 4 check (given; the check adds the squares one term at a time in a loop, a different route from yours)
if ~exist('myTotal','var') || ~exist('myMargin','var') || ~exist('myPass','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: the measured image EVM and the two given terms, squared and added in a loop.
    terms = [evmIqOracle myEvmPn myEvmPa];   % percent
    sumSq = 0;
    % Add the square of each term in turn.
    for t = 1:numel(terms)
        sumSq = sumSq + terms(t)^2;
    end
    totalOracle = sqrt(sumSq);                                   % percent
    okStage4 = [abs(myTotal - totalOracle) < 0.05; ...
                abs(myMargin - (8 - totalOracle)) < 0.05; ...
                isequal(logical(myPass), totalOracle <= 8)];
    assert(okStage4(1), ...
        'myTotal is off. Look first at the three terms: each one must appear once in the total.')
    assert(okStage4(2), ...
        'myMargin is off. Look first at the sign: a met budget has a positive margin.')
    assert(okStage4(3), ...
        'myPass is off. Look first at the direction of the test: a budget is met when the total does not exceed the limit, equal included.')
    stage4Checks = table(["Total EVM (rss)"; "Margin to the limit"; "Budget met"], ...
        [string(round(totalOracle, 3)) + " percent"; string(round(8 - totalOracle, 3)) + " points"; string(totalOracle <= 8)], ...
        [string(round(myTotal, 3)) + " percent"; string(round(myMargin, 3)) + " points"; string(logical(myPass))], ...
        okStage4, VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    if ~exist('myPrediction','var')
        myPrediction = NaN;   % no prediction line was uncommented
    end
    if isnan(myPrediction)
        predictionNote = "No prediction typed";
    else
        predictionNote = "Compare the two numbers";
    end
    stage4Prediction = table(myPrediction, round(totalOracle, 3), predictionNote, ...
        VariableNames = {'MyPrediction_percent', 'Total_percent', 'Note'});
    stage4Prediction
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myIrrDb','var') || ~exist('myEvmIq','var') || ~exist('myTotal','var') || ~exist('myPass','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    myTerms = [myEvmIq myEvmPn myEvmPa];   % percent
    buildFlags = [myTotal <= myLimit; ...
        myTotal > max(myTerms); ...
        sum(myTerms) > myTotal; ...
        myIrrDb >= 30];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["Total at or below the 64QAM limit"; "Total above every single term"; ...
         "Plain sum overstates the total"; "Image at least 30 dB down"], ...
        ["<= " + string(myLimit) + " percent"; "> " + string(round(max(myTerms), 3)) + " percent"; ...
         "> " + string(round(myTotal, 3)) + " percent"; ">= 30 dB"], ...
        [string(round(myTotal, 3)) + " percent"; string(round(myTotal, 3)) + " percent"; ...
         string(round(sum(myTerms), 3)) + " percent"; string(round(myIrrDb, 2)) + " dB"], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    figure(Name = "Track 14 — EVM budget");
    bar([myTerms myTotal]); grid on;
    yline(myLimit, '--', '64QAM limit');
    xticklabels(["IQ image", "Phase noise", "Amplifier", "Total (rss)"]);
    ylabel('EVM (%)');
    title('Build it: the budget, term by term, and the total');
end
%%
% Your interpretation (write one or two sentences here): which term uses 
% the most of the budget, and if you had to free up room for a tighter limit, 
% which one would you attack first and why?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks oracleProbe oracleRx irrOracleDb okStage2 stage2Checks ...
      evmIqOracle okStage3 stage3Checks terms sumSq t totalOracle okStage4 stage4Checks ...
      stage4Prediction predictionNote myTerms buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — Explanation (B1)
% Keep the far-out level at −110 dBc/Hz but raise only the 1 kHz level from 
% −70 to −60 dBc/Hz. Which EVM grows a lot, the one before the CPE fix or 
% the one after it? Roughly by what factor does each change, and why are the 
% two so different?
% 
% Your answer:
% E2 — New values (B2)
% A better mixer has A = 0.2 dB and P = 1°. Work out its IRR in dB and the 
% EVM its image causes. A tone sits on grid row 100 of the 624-row grid: on 
% which row, and at how many subcarriers from the centre, does its image appear?
% 
% Your answer:
% E3 — Diagnosis (B1 and B3)
% A classmate's 64QAM budget lists 3.37 % for the mixer image and 3.0 % for 
% the amplifier. For the oscillator they take B1's oscillator, read the EVM 
% straight off the demodulated grid (about 6.5 %), and combine the three by 
% root-sum-square: 7.9 %, just under the 8 % limit, so they report no room 
% left. What is wrong with their oscillator term? Which number from your B1 
% tables should replace it, and what is the corrected total and margin?
% 
% Your answer:
% E4 — New values (B4)
% The receive chain gets 10 dB noisier (the floor in B4 rises from −50 to 
% −40 dBm) with the same amplifier. Does the best drive move up or down, and 
% by about how many dB? Explain from the two arms of the U.
% 
% Your answer:
% E5 — New values (Build it)
% A 64QAM transmitter already has 3.37 % from its mixer image and 4.0 % from 
% phase noise. How much EVM is left for the amplifier under the 8 % limit? 
% How much would be left under the 256QAM limit of 3.5 %, and what does that 
% say about the mixer and the oscillator?
% 
% Your answer:
% E6 — Explanation (terms)
% B4 set AMPMConversion to 0. The default for the cubic model is 10°/dB. Say 
% what that property adds to the amplifier, which arm of the U-curve it changes, 
% and which way the best drive would move.
% 
% Your answer:
%% Recap — Mirror Image (album track 14)
% No real radio is perfect, and each flaw has its own signature. Phase noise 
% turns whole symbols by a common angle that a receiver can track, plus a 
% fast part that leaks like noise. IQ imbalance puts a faint twin of each 
% subcarrier at the mirrored frequency, about IRR dB down. The amplifier compresses 
% at high drive while the noise wins at low drive, so the EVM has a best point 
% in the middle. Independent flaws add in power, which turns a list of EVMs 
% into one number to hold against the limit.
% Key relationships
% $$\mathrm{IRR} = \frac{g^2 + 2g\cos P + 1}{g^2 - 2g\cos P + 1},\qquad \mathrm{EVM_{IQ}} 
% \approx \frac{100}{\sqrt{\mathrm{IRR}}}\ \%,\qquad \mathrm{EVM_{total}} = \sqrt{\textstyle\sum 
% \mathrm{EVM}_i^2}$$
% What this means in practice
% • Plot the common phase per symbol to tell the slow wander from the fast leakage.
% 
% • Look for an IQ image at the opposite frequency, row K − k + 2 on the 
% grid.
% 
% • Sweep the amplifier drive and pick the bottom of the U; check it is not 
% at the edge of the sweep.
% 
% • Budget EVM by root-sum-square, never by adding percentages.
% 
% • You built an EVM budget: an IRR, an image EVM, a total, and a margin 
% against the 64QAM limit.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 13 (track13/track13_signals_from_orbit_demo), why do 32 stop-and-wait 
% HARQ processes keep a GEO transparent link only about 6 % busy?
% 
% • Next in the album: track15 (End to End).
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
% • + - * / and ^:
% 
% • 10^(x/20), 10^(x/10), and log10(x):
% 
% • sqrt(x) and cosd(e):
% 
% • a <= b:
% What I missed, and where to reread it
% 
