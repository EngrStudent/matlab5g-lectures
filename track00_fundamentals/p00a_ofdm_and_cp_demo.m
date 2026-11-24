%% P00a — Grid and Waveform: OFDM and the Cyclic Prefix
%% One IFFT per symbol, orthogonal tones, and the prefix as a copied tail
% Each column of the resource grid becomes one OFDM symbol through one inverse 
% FFT. The tones are orthogonal: over the useful symbol each one completes a 
% whole number of cycles relative to its neighbours, so the receiver's FFT separates 
% them exactly.
% 
% Before transmission, the last part of each symbol is copied to its front. 
% That copy is the cyclic prefix (CP). Its length is a fixed time, so its length 
% in samples follows the sample rate.
%% Guiding question
% How does one column of the grid become samples in the air, and what exactly 
% is the cyclic prefix?
% This demonstration
% 1. B3 — Build one OFDM symbol with a 2048-point IFFT at 30 kHz, recover its 
% tones exactly, then add a frequency offset of one tenth of the subcarrier spacing 
% and measure the leakage (ICI).
% 
% 2. B4 — Count CP samples at the 15 kHz, Nfft = 2048 reference clock, scale 
% to Nfft = 1024, and draw the CP as the copied tail of the symbol.
% Key relationships
% The sample rate is the FFT size times the subcarrier spacing:
% 
% $$f_s = N_{\mathrm{FFT}} \cdot \Delta f$$
% 
% A tone shifted by a fraction ε of the spacing keeps only part of its power 
% in its own FFT bin:
% 
% $$P_{\mathrm{own}} \approx \left(\frac{\sin \pi\varepsilon}{\pi\varepsilon}\right)^2$$
% 
% The CP is a fixed time, so its sample count scales with the sample rate:
% 
% $$N_{\mathrm{CP}} = T_{\mathrm{CP}} \cdot f_s$$
%% Prerequisites
% • Resource elements and the 14-symbol slot (P00a bits-and-grid demo, B2)
% 
% • The idea of an FFT/IFFT pair turning frequency bins into time samples and 
% back
% 
% Words used in this demo
% • FFT/IFFT, FFT size (Nfft), subcarrier spacing, sample rate, guard bins,
% orthogonality, frequency offset ε, and ICI (leakage into other bins).
%
% • Cyclic prefix (CP): a copy of the last samples of a symbol, placed in front.
% Its duration is fixed by the numerology; its sample count follows the sample
% rate. A half-subframe is 0.5 ms.
%
% B3's 2048-point example is at 30 kHz (61.44 Msps). B4's 2048-point reference
% clock is at 15 kHz (30.72 Msps). They share an FFT size, not a clock.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write
% yourself get their own entry; small helpers are grouped into families.
%
% Commands you write
% • ifft(x) and fft(x) — Purpose: turn frequency bins into time samples, and
% back. Inputs: a column of bins or samples. Outputs: the transform, same length.
%
% • x(k:end) — Purpose: take entries from index k through the last one. Inputs:
% a list and a start index k. Outputs: the tail of the list. end means the last
% position (not a formula for a prefix length).
%
% • [a; b] — Purpose: stack columns. Inputs: two columns. Outputs: one column.
%
% • numel(x) — Purpose: count entries. Inputs: an array. Outputs: a whole number.
%
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start a
% comment; start a section.
%
% • exp, sin, abs, circshift, table, isnan — Purpose: the usual math and display
% helpers in the given cells.
%
% Read each table and figure against the sentence that follows it.
%% Staging for script

% Clear the workspace and close figures so every run starts from the same state.
clear; close all;
% Fix the random seed so the random QPSK-like symbols are reproducible.
rng(2026);
%% B3 — One IFFT per OFDM symbol
% New words
% • IFFT: the calculation that turns a column of subcarrier values into time 
% samples (the FFT goes back).
% 
% • Orthogonal: placed so the FFT separates every tone with no trace of the others.
% 
% • ICI: power from one tone leaking into other bins when that separation fails.
% Why it matters
% One OFDM symbol is one inverse FFT of one grid column, so the time samples 
% come out at a rate set by the FFT size and the spacing:
% 
% $$f_s = N_{\mathrm{FFT}} \cdot \Delta f$$
% 
% NFFT is a power of two larger than the number of used subcarriers; the unused 
% bins at both edges are guard bins that keep energy off the neighbours' channels.
% 
% Orthogonality is why the tones can sit so close: at the receiver's FFT, each 
% tone's spectrum has a null exactly on every other tone. If the transmitter and 
% receiver clocks disagree, every tone is shifted by a fraction ε of the spacing, 
% the nulls slide off their marks, and energy leaks into the neighbours. That 
% is inter-carrier interference (ICI). A single tone keeps only
% 
% $$P_{\mathrm{own}} \approx \left(\frac{\sin \pi\varepsilon}{\pi\varepsilon}\right)^2$$
% 
% of its power in its own bin.
% What to look for
% • In the results table, check the sample rate against FFT size × spacing.
% 
% • In the figure, compare the two panels: the left shows every active tone 
% recovered at full magnitude; the right shows the same symbol with an offset, 
% where the bins outside the 72 active tones are no longer empty.
% 
% • In the leakage table, compare the measured single-tone loss with the sinc² 
% formula, and compare both with the inactive-bin ICI figure in the results table.
% Common mistakes
% Do not read the inactive-bin percentage as the whole ICI. It counts only energy 
% that lands in the empty guard bins; most of a tone's lost power lands on the 
% other active tones, where this measure cannot see it.
% 
% Do not confuse the sample rate with the subcarrier spacing. The spacing sets 
% the symbol length; the FFT size then sets how many samples describe it.
% Try it (personal exploration)
% Use the sinc² rule in Why it matters to predict the percentage of a single 
% tone's power that leaves its own bin at the default offset, epsCFO. Type that 
% percentage into myPrediction in the first code line below before you run this 
% section. After the leakage table, a given line prints your prediction beside 
% the measured result.
% 
% Then change epsCFO to 0.2, predict again with the same rule, and run. Finally 
% set epsCFO to 0 and predict what the inactive-bin row will show. Every check 
% in this section holds for any offset, so the run does not stop; put epsCFO 
% back to 0.1 when you are done.

% Try it: type your prediction here (a percentage) before running this section.
myPrediction = NaN;
% This reference example uses a 2048-point IFFT at 30 kHz subcarrier
% spacing. The resulting sample rate is 61.44 million samples per second.
Nfft = 2048;
scs_Hz = 30e3;
sampleRate_Hz = Nfft * scs_Hz;

% Place 72 active tones around DC. The other FFT bins are unused guard bins.
% This is a compact teaching example, not a complete NR carrier allocation.
activeToneCount = 72;
toneOffsets = [-activeToneCount/2:-1, 1:activeToneCount/2].';

% In fftshift ordering, DC is at bin Nfft/2 + 1.
activeBins = Nfft/2 + 1 + toneOffsets;

% Place unit-magnitude QPSK-like symbols onto the active frequency bins.
txSpectrum = zeros(Nfft,1);
txSymbols = exp(1j*pi/2*randi([0 3], activeToneCount, 1));
txSpectrum(activeBins) = txSymbols;

% Convert from centered frequency-bin order to MATLAB IFFT-bin order, then
% produce one useful time-domain OFDM symbol.
txTime = ifft(ifftshift(txSpectrum));

% In the ideal case, FFT followed by IFFT recovers every active tone.
rxSpectrumClean = fftshift(fft(txTime));
cleanError = max(abs(rxSpectrumClean(activeBins) - txSymbols));

% Apply a carrier-frequency offset equal to one tenth of subcarrier spacing.
% epsCFO is normalized to subcarrier spacing.
epsCFO = 0.1;
sampleIndex = (0:Nfft-1).';

rxTimeCFO = txTime .* exp(1j*2*pi*epsCFO*sampleIndex/Nfft);
rxSpectrumCFO = fftshift(fft(rxTimeCFO));

% Any energy that appears in inactive bins is inter-carrier interference.
inactiveBins = setdiff((1:Nfft).', activeBins);

iciPowerFraction = sum(abs(rxSpectrumCFO(inactiveBins)).^2) / ...
    sum(abs(rxSpectrumCFO).^2);

% Check the central numerical relationships.
% isDefaultExample is true only for the narrated numbers. A check that is
% written for those numbers runs only then; otherwise it is skipped with a
% printed note, so changing a value for Try it never stops the run.
isDefaultExample = Nfft == 2048 && scs_Hz == 30e3;
checkCleanOrthogonality = cleanError < 1e-12;

% With no offset nothing leaks (only rounding noise remains); with any offset
% some power must reach the empty bins. This holds for every epsCFO you try.
if epsCFO == 0
    checkICI = iciPowerFraction < 1e-20;
else
    checkICI = iciPowerFraction > 1e-12;
end

if isDefaultExample
    checkSampleRate = abs(sampleRate_Hz - 61.44e6) < 1;
    assert(checkSampleRate, ...
        '2048 points at 30 kHz should give 61.44 Msps. Look first at the line sampleRate_Hz = Nfft * scs_Hz. Common mistake: confusing sample rate with spacing.');
else
    checkSampleRate = NaN;   % NaN marks "skipped" in the verification table
    disp('Default-only check skipped: the sample-rate number check is written for Nfft = 2048 at 30 kHz.')
end

assert(checkCleanOrthogonality, ...
    'An unshifted OFDM symbol should recover its active tones exactly. Look first at the fftshift/ifftshift pair around ifft and fft.');

assert(checkICI, ...
    'Leakage into the empty bins does not match the offset: some should appear for any nonzero epsCFO and none for epsCFO = 0. Look first at the exp term in rxTimeCFO and at inactiveBins.');

% Measure the same leakage on one isolated tone, so the result can be
% compared with the sinc-squared formula. Put a single unit tone in one bin,
% shift it by epsCFO, and see how much power stays in that bin.
toneBin = Nfft/2 + 1 + 5;
singleTone = zeros(Nfft,1);
singleTone(toneBin) = 1;
singleToneRx = fftshift(fft(ifft(ifftshift(singleTone)) .* ...
    exp(1j*2*pi*epsCFO*sampleIndex/Nfft)));
ownBinLossMeasured = 1 - abs(singleToneRx(toneBin))^2 / sum(abs(singleToneRx).^2);

% The formula has a removable 0/0 at epsCFO = 0, where nothing is lost.
sincValue = 1;
if epsCFO ~= 0
    sincValue = sin(pi*epsCFO) / (pi*epsCFO);
end
ownBinLossFormula = 1 - sincValue^2;

% For any offset the measured loss should match the formula closely.
checkOwnBinLoss = abs(ownBinLossMeasured - ownBinLossFormula) < 1e-4;

assert(checkOwnBinLoss, ...
    'The measured single-tone power loss does not match 1 - (sin(pi*eps)/(pi*eps))^2. Look first at the sign of epsCFO in the exp term and at toneBin.');

% Summarize the FFT size, rate, tone allocation, offset, and inactive-bin ICI.
% Create explicit, equally sized text columns for the display table.
ofdmQuantity = [ ...
    "FFT size"; ...
    "Subcarrier spacing"; ...
    "Sample rate"; ...
    "Active tones"; ...
    "Guard bins"; ...
    "Frequency offset"; ...
    "ICI power in inactive bins"];

ofdmValue = [ ...
    string(Nfft); ...
    string(sprintf('%.0f kHz', scs_Hz/1e3)); ...
    string(sprintf('%.2f Msps', sampleRate_Hz/1e6)); ...
    string(activeToneCount); ...
    string(Nfft-activeToneCount); ...
    string(sprintf('%.1f of one subcarrier spacing', epsCFO)); ...
    string(sprintf('%.3f %%', 100*iciPowerFraction))];

assert(numel(ofdmQuantity) == numel(ofdmValue), ...
    'The OFDM results table columns must have the same number of rows. Look first at ofdmQuantity and ofdmValue: add or remove rows in both.');

ofdmResults = table( ...
    ofdmQuantity, ...
    ofdmValue, ...
    VariableNames = {'Quantity','Value'});

ofdmResults

% Compare the single-tone loss measured by the FFT with the formula.
leakageResults = table( ...
    ["Single-tone power lost from its own bin (measured)"; ...
     "Single-tone power lost from its own bin (formula)"], ...
    [string(sprintf('%.2f %%', 100*ownBinLossMeasured)); ...
     string(sprintf('%.2f %%', 100*ownBinLossFormula))], ...
    VariableNames = {'Quantity','Value'});

leakageResults

% Compare your Try-it prediction with the measurement, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run this section again.')
else
    predCompare = table(myPrediction, 100*ownBinLossMeasured, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
%% B3 — After the run
% Compare the measured single-tone loss with the sinc-squared formula. The
% inactive-bin ICI is smaller than that loss, because most leaked power falls
% on neighbouring active tones rather than in the guard bins.
%% B3 — Verification results


% Assertions stop execution if an essential relationship fails. This table
% makes successful checks visible in the Live Editor.

checkPassed = [ ...
    checkSampleRate; ...
    checkCleanOrthogonality; ...
    checkICI];

% Pass, Fail, or Skipped, all computed from the flags (NaN means skipped).
resultText = repmat("Pass", numel(checkPassed), 1);
resultText(checkPassed == 0) = "Fail";
resultText(isnan(checkPassed)) = "Skipped (default-only)";

ofdmCheckName = [ ...
    "Sample-rate relationship"; ...
    "Orthogonality without offset"; ...
    "ICI under fractional offset"];

ofdmExpected = [ ...
    "fs = Nfft x SCS"; ...
    "FFT recovers original active tones"; ...
    "Leakage only when there is an offset"];

assert(numel(ofdmCheckName) == numel(ofdmExpected) && ...
    numel(ofdmExpected) == numel(resultText), ...
    'The OFDM verification table columns must have the same number of rows. Look first at the column lists just above: each column needs one entry per row.');

ofdmChecks = table( ...
    ofdmCheckName, ...
    ofdmExpected, ...
    resultText, ...
    VariableNames = {'Check','Expected','Pass'});

ofdmChecks

% The single-tone leakage check is shown separately so the original three
% rows stay unchanged.
ownBinResult = "Fail";
if checkOwnBinLoss
    ownBinResult = "Pass";
end

ownBinCheck = table("Single-tone leakage", ...
    "Measured loss = 1 - sinc^2(eps)", ...
    ownBinResult, ...
    VariableNames = {'Check','Expected','Pass'});

ownBinCheck
%% B3 — Orthogonality and ICI figure
% Left: no offset, every active tone comes back at full magnitude. Right: the
% current epsCFO offset, where energy appears outside the 72 active tones.

figure( ...
    Name = 'P00a - OFDM orthogonality and ICI', ...
    Color = 'w', ...
    Position = [100 100 1100 420]);

tiledlayout(1,2, TileSpacing='compact', Padding='compact');

nexttile;
stem(toneOffsets, abs(rxSpectrumClean(activeBins)), 'filled');
grid on;
xlabel('Active-tone offset from DC');
ylabel('Recovered magnitude');
title('No offset: tones remain orthogonal');

nexttile;
plot((-Nfft/2:Nfft/2-1), 20*log10(abs(rxSpectrumCFO)+eps));
grid on;
xlabel('FFT-bin offset from DC');
ylabel('Magnitude (dB)');
title(sprintf('%.1f-SCS offset: energy leaks into neighbours', epsCFO));
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% B4 is self-contained. Remove variables used only for B3 calculations,
% display tables, checks, and figures.

clear ofdmResults ofdmChecks ...
    ofdmQuantity ofdmValue ...
    ofdmCheckName ofdmExpected ...
    Nfft scs_Hz sampleRate_Hz ...
    activeToneCount toneOffsets activeBins inactiveBins ...
    txSpectrum txSymbols txTime ...
    rxSpectrumClean cleanError ...
    epsCFO sampleIndex rxTimeCFO rxSpectrumCFO iciPowerFraction ...
    checkSampleRate checkCleanOrthogonality checkICI isDefaultExample ...
    checkPassed resultText ...
    toneBin singleTone singleToneRx ownBinLossMeasured sincValue ...
    ownBinLossFormula checkOwnBinLoss leakageResults ownBinResult ownBinCheck myPrediction
%% B4 — Cyclic prefix in samples
% Clock reminder: this section's 2048-point reference is at 15 kHz, not the
% 30 kHz clock used for the 2048-point IFFT in B3.
% New words
% • Cyclic prefix (CP): a copy of a symbol's last samples, placed in front of it.
% 
% • Half-subframe: 0.5 ms of signal, seven OFDM symbols at 15 kHz spacing.
% 
% • Reference clock: the sample rate used for counting here, 2048 samples per 
% useful symbol at 15 kHz.
% Why it matters
% The cyclic prefix is a copy of the last part of each useful symbol, placed 
% in front of it. Its duration is set by the numerology, not by the FFT size, 
% so its length in samples follows the sample rate:
% 
% $$N_{\mathrm{CP}} = T_{\mathrm{CP}} \cdot f_s$$
% 
% At the 15 kHz reference with Nfft = 2048 (f_s = 30.72 MHz), the normal CP 
% is 144 samples. The first symbol of each 0.5 ms half-subframe gets a longer 
% CP, 16 samples more, so that seven symbols fill exactly 0.5 ms:
% 
% $$7 \times 2048 + 160 + 6 \times 144 = 15360 = 30.72\ \mathrm{MHz} \times 0.5\ \mathrm{ms}$$
% What to look for
% • In the results table, compare the two rows: when Nfft and the sample rate
% change together, read what happens to the sample counts and to the CP duration
% column.
% 
% • In the timing figure, the orange blocks are prefixes and the blue blocks 
% are useful bodies; check which symbol has the longer orange block.
% 
% • In the tail-copy figure, the shaded block at the front and the shaded block 
% at the end of the symbol should carry the same waveform, sample for sample.
% Common mistakes
% Do not think the CP has a fixed number of samples. It has a fixed duration; 
% its sample count changes whenever the sample rate changes.
% 
% Do not assume the 144 and 160 counts are what the toolbox uses for your carrier. 
% They belong to the Nfft = 2048 reference clock; the toolbox may choose a smaller 
% default FFT size, which gives proportionally smaller counts.
% Try it (personal exploration)
% Use N_CP = T_CP × f_s to predict the normal-CP sample count when the FFT
% size becomes 1024 at the same 15 kHz spacing, and type it into myPrediction
% below before you run this section. A given table after the results table
% shows your prediction beside the result. Then predict, in words, whether the
% CP duration column changes.
% 
% Later, in the tail-copy section, change tailCP to 160 and predict the length 
% of the transmitted symbol before running.

% Try it: type your prediction here (a number of samples) before running this section.
myPrediction = NaN;
% The reference sample rate is:
%   2048 x 15 kHz = 30.72 MHz.
referenceNfft = 2048;
referenceSCS_Hz = 15e3;
referenceFs_Hz = referenceNfft * referenceSCS_Hz;

% A 1 ms normal-CP subframe contains 14 OFDM symbols. It has two long CPs:
% one at the beginning of each 0.5 ms half-subframe.
cpNormal_2048 = 144;
cpLong_2048 = 160;
symbolsPerSubframe = 14;

samplesPerSubframe_2048 = ...
    symbolsPerSubframe * referenceNfft + ...
    12 * cpNormal_2048 + ...
    2 * cpLong_2048;

% Scale the reference timing to Nfft = 1024.
scaledNfft = 1024;
scaledFs_Hz = scaledNfft * referenceSCS_Hz;

cpNormal_1024 = cpNormal_2048 * scaledNfft / referenceNfft;
cpLong_1024 = cpLong_2048 * scaledNfft / referenceNfft;

cpNormal_us_2048 = cpNormal_2048 / referenceFs_Hz * 1e6;
cpNormal_us_1024 = cpNormal_1024 / scaledFs_Hz * 1e6;

% Check the reference timing and scaling rule.
checkReferenceSubframe = samplesPerSubframe_2048 == 30720;

checkReferenceDuration = ...
    abs(samplesPerSubframe_2048/referenceFs_Hz - 1e-3) < 1e-12;

% Relationship check, with no target number written in: at Nfft = 1024 the
% scaled CPs must be whole samples, and fourteen symbols with twelve short and
% two long prefixes must still fill exactly 1 ms at the scaled sample rate.
samplesPerSubframe_1024 = symbolsPerSubframe * scaledNfft + ...
    12 * cpNormal_1024 + 2 * cpLong_1024;
checkCPScaling = cpNormal_1024 == round(cpNormal_1024) && ...
    cpLong_1024 == round(cpLong_1024) && ...
    abs(samplesPerSubframe_1024 / scaledFs_Hz - 1e-3) < 1e-12;

checkCPDuration = ...
    abs(cpNormal_us_2048 - cpNormal_us_1024) < 1e-12;

assert(checkReferenceSubframe, ...
    'The 15 kHz, Nfft = 2048 subframe should contain 30720 samples. Look first at the counts of short and long CPs: twelve and two.');

assert(checkReferenceDuration, ...
    '30720 samples at 30.72 MHz should equal exactly 1 ms. Look first at referenceFs_Hz = referenceNfft * referenceSCS_Hz.');

assert(checkCPScaling, ...
    'The scaled CPs are not whole samples, or the scaled subframe is not 1 ms. Look first at the scaling line cpNormal_1024 = cpNormal_2048 * scaledNfft / referenceNfft. Common mistake: keeping a fixed sample count.');

assert(checkCPDuration, ...
    'CP duration should remain fixed when Nfft and sample rate scale together. Look first at scaledFs_Hz: the sample rate must scale with the FFT size.');

% Build numeric columns for a two-row sample-count comparison table.
cpNfft = [referenceNfft; scaledNfft];
cpSampleRateMHz = [referenceFs_Hz; scaledFs_Hz] / 1e6;
cpNormalSamples = [cpNormal_2048; cpNormal_1024];
cpLongSamples = [cpLong_2048; cpLong_1024];
cpNormalDurationUs = [cpNormal_us_2048; cpNormal_us_1024];

assert(numel(cpNfft) == numel(cpSampleRateMHz) && ...
    numel(cpSampleRateMHz) == numel(cpNormalSamples) && ...
    numel(cpNormalSamples) == numel(cpLongSamples) && ...
    numel(cpLongSamples) == numel(cpNormalDurationUs), ...
    'The CP results table columns must all have two rows. Look first at the column lists just above: each column needs one entry per row.');

cpResults = table( ...
    cpNfft, ...
    cpSampleRateMHz, ...
    cpNormalSamples, ...
    cpLongSamples, ...
    cpNormalDurationUs, ...
    VariableNames = { ...
    'Nfft', ...
    'SampleRate_MHz', ...
    'NormalCP_samples', ...
    'LongCP_samples', ...
    'NormalCP_us'});

cpResults

% Compare your Try-it prediction with the result, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run this section again.')
else
    predCompare = table(myPrediction, cpNormal_1024, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
%% B4 — After the run
% Compare the scaled sample counts in the table with the counts at 2048. Then
% form each duration as samples divided by the sample rate, and see whether
% the two numerologies keep the same prefix time.
%% B4 — Verification results


checkPassed = [ ...
    checkReferenceSubframe; ...
    checkReferenceDuration; ...
    checkCPScaling; ...
    checkCPDuration];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

cpCheckName = [ ...
    "2048-point subframe sample count"; ...
    "Reference subframe duration"; ...
    "CP sample-count scaling"; ...
    "CP duration after scaling"];

cpExpected = [ ...
    "30720 samples"; ...
    "1 ms at 30.72 MHz"; ...
    "Whole-sample CPs; the subframe still fills 1 ms"; ...
    "Normal CP remains 4.6875 microseconds"];

assert(numel(cpCheckName) == numel(cpExpected) && ...
    numel(cpExpected) == numel(resultText), ...
    'The CP verification table columns must have the same number of rows. Look first at the column lists just above: each column needs one entry per row.');

cpChecks = table( ...
    cpCheckName, ...
    cpExpected, ...
    resultText, ...
    VariableNames = {'Check','Expected','Pass'});

cpChecks
%% B4 — CP timing figure
% Top: the seven symbols of one 0.5 ms half-subframe, prefixes in orange and 
% useful bodies in blue. Bottom: the CP length of each symbol.

% This figure cell is intentionally self-contained, so it can be run after
% the B4 calculation cell has cleaned up its temporary workspace variables.

% Reference timing for normal CP at 15 kHz subcarrier spacing.
referenceNfft = 2048;
referenceSCS_Hz = 15e3;
referenceFs_Hz = referenceNfft * referenceSCS_Hz;

% In each 0.5 ms half-subframe, symbol 0 has a 160-sample CP and the other
% six symbols have 144-sample CPs.
cpNormal_2048 = 144;
cpLong_2048 = 160;
symbolsPerHalfSubframe = 7;

% One CP length and one useful-symbol-body length are stored for each of
% the seven symbols in the half-subframe.
cpLengthsHalfSubframe = [ ...
    cpLong_2048; ...
    repmat(cpNormal_2048, symbolsPerHalfSubframe-1, 1)];

usefulLengthsHalfSubframe = ...
    repmat(referenceNfft, symbolsPerHalfSubframe, 1);

% Locate the first sample of each CP-plus-body symbol interval.
symbolStartSamples = cumsum([0; ...
    cpLengthsHalfSubframe(1:end-1) + usefulLengthsHalfSubframe(1:end-1)]);

% The seven symbols must fill exactly 0.5 ms.
halfFrameSamples = sum(cpLengthsHalfSubframe + usefulLengthsHalfSubframe);
expectedHalfFrameSamples = referenceFs_Hz * 0.5e-3;

% Compare within a tight relative tolerance, not with ==, because
% expectedHalfFrameSamples is worked from a rate in hertz and may
% not match an integer sample count bit-for-bit.
checkHalfSubframe = abs(halfFrameSamples - expectedHalfFrameSamples) < 1e-9*max(1, abs(expectedHalfFrameSamples));

assert(checkHalfSubframe, ...
    'Seven symbols with one 160-sample CP and six 144-sample CPs should fill 0.5 ms. Look first at cpLengthsHalfSubframe: only symbol 0 gets the long CP.');

figure( ...
    Name = 'P00a - CP timing in one 0.5 ms half-subframe', ...
    Color = 'w', ...
    Position = [100 100 1250 760]);

% Moderate padding separates the shared title from the individual panels.
tl = tiledlayout(2,1, ...
    TileSpacing = 'compact', ...
    Padding = 'loose');

title(tl, ...
    'Normal CP at 15 kHz with Nfft = 2048: one 0.5 ms half-subframe', ...
    FontWeight = 'bold');
% Top panel — CP and useful body in all seven symbols

nexttile;
hold on;

for symbolIndex = 1:symbolsPerHalfSubframe

    % Orange: the cyclic prefix copied from the end of this symbol's body.
    rectangle( ...
        Position = [ ...
        symbolStartSamples(symbolIndex), ...
        0, ...
        cpLengthsHalfSubframe(symbolIndex), ...
        1], ...
        FaceColor = [0.90 0.30 0.10], ...
        EdgeColor = [0.15 0.15 0.15], ...
        LineWidth = 0.8);

    % Blue: the Nfft-sample useful IFFT body.
    rectangle( ...
        Position = [ ...
        symbolStartSamples(symbolIndex) + cpLengthsHalfSubframe(symbolIndex), ...
        0, ...
        usefulLengthsHalfSubframe(symbolIndex), ...
        1], ...
        FaceColor = [0.20 0.40 0.80], ...
        EdgeColor = [0.15 0.15 0.15], ...
        LineWidth = 0.8);

    % Place each symbol number inside its useful body. The narrow CP regions
    % are too small for labels at this full half-subframe scale.
    text( ...
        symbolStartSamples(symbolIndex) + ...
        cpLengthsHalfSubframe(symbolIndex) + ...
        usefulLengthsHalfSubframe(symbolIndex)/2, ...
        0.50, ...
        sprintf('%d', symbolIndex-1), ...
        HorizontalAlignment = 'center', ...
        VerticalAlignment = 'middle', ...
        Color = 'w', ...
        FontWeight = 'bold', ...
        FontSize = 10);
end

% Mark the end of the first CP and the end of the half-subframe. These are
% unlabeled to avoid crowding the visual timeline.
xline(cpLong_2048, ':k', LineWidth=1.0, HandleVisibility='off');
xline(halfFrameSamples, '-k', LineWidth=1.0, HandleVisibility='off');

xlim([0 halfFrameSamples]);
ylim([0 1]);
yticks([]);
grid on;
box on;

xlabel('Sample index');

title({ ...
    'Seven OFDM symbols: orange = cyclic prefix; blue = useful IFFT body', ...
    'Symbol 0 has a 160-sample CP; symbols 1–6 have 144-sample CPs'});
% Bottom panel — CP length by symbol

nexttile;
hold on;

% The lower plot is deliberately a measurement view, not a second timeline.
% A line-and-marker plot makes clear that there are only two CP lengths:
% 160 samples for symbol 0, and 144 samples for symbols 1 through 6.
symbolNumbers = 0:symbolsPerHalfSubframe-1;

% Light grey line connects the per-symbol values without adding a legend
% entry or competing with the two colored measurements.
plot(symbolNumbers, cpLengthsHalfSubframe, '-', ...
    Color = [0.55 0.55 0.55], ...
    LineWidth = 1.0, ...
    HandleVisibility = 'off');

% The first CP is the only lengthened prefix.
plot(0, cpLong_2048, 'o', ...
    MarkerSize = 9, ...
    MarkerFaceColor = [0.90 0.30 0.10], ...
    MarkerEdgeColor = [0.15 0.15 0.15], ...
    HandleVisibility = 'off');

% The remaining six prefixes have the ordinary normal-CP length.
plot(1:symbolsPerHalfSubframe-1, cpLengthsHalfSubframe(2:end), 'o', ...
    MarkerSize = 8, ...
    MarkerFaceColor = [0.20 0.40 0.80], ...
    MarkerEdgeColor = [0.15 0.15 0.15], ...
    HandleVisibility = 'off');

% The dashed line marks the ordinary 144-sample CP reference level.
yline(cpNormal_2048, '--k', ...
    LineWidth = 1.0, ...
    HandleVisibility = 'off');

grid on;
box on;

xlim([-0.6 symbolsPerHalfSubframe-0.4]);
xticks(symbolNumbers);

% The y-axis is intentionally zoomed around the two CP values. Showing the
% scale directly in the y-axis label is clearer than using a subtitle.
ylim([138 166]);
yticks(140:5:165);

xlabel('OFDM symbol index within the half-subframe');
ylabel('CP length (samples; axis zoomed)');

title('The first CP is 160 samples; all later CPs are 144 samples');

% Direct labels eliminate the legend and leave the data area uncluttered.
text( ...
    0.28, cpLong_2048 -2, ...
    'symbol 0: 160', ...
    HorizontalAlignment = 'left', ...
    VerticalAlignment = 'bottom', ...
    FontSize = 10, ...
    FontWeight = 'bold', ...
    Color = [0.65 0.12 0.05]);

text( ...
    3.5, cpNormal_2048 + 1.6, ...
    'symbols 1–6: 144', ...
    HorizontalAlignment = 'center', ...
    VerticalAlignment = 'bottom', ...
    FontSize = 10, ...
    Color = [0.08 0.24 0.58]);
%% B4 — Cyclic prefix as a copied tail
% The timing figure shows where the prefix sits. This section shows what it
% is: build one useful symbol, form a prefix from its end, and place that
% prefix in front.
%
% Try (from B4): type the transmitted length you expect for the tailCP you
% will use, then run this section. Change tailCP if you like, and predict again.
myPredictionLength = NaN;

% Build one useful OFDM symbol at the reference FFT size, using 72 active
% QPSK-like tones around DC as in B3.
tailNfft = 2048;
tailCP = 144;
tailSpectrum = zeros(tailNfft,1);
tailBins = tailNfft/2 + 1 + [-36:-1, 1:36].';
tailSpectrum(tailBins) = exp(1j*pi/2*randi([0 3], numel(tailBins), 1));
symbolBody = ifft(ifftshift(tailSpectrum));

% Rotate the body so its tail arrives at the front, then take the first
% tailCP samples of that rotation and place them in front of the body.
rotatedBody = circshift(symbolBody, tailCP);
symbolWithCP = [rotatedBody(1:tailCP); symbolBody];

% Property: the first tailCP samples of the transmitted symbol equal its
% own last tailCP samples.
sentTailStart = numel(symbolWithCP) - tailCP + 1;   % first sample of the tail of the transmitted symbol
checkCPIsTail = isequal(symbolWithCP(1:tailCP), symbolWithCP(sentTailStart:end));
checkSymbolLength = numel(symbolWithCP) == tailNfft + tailCP;

assert(checkCPIsTail, ...
    'The front of the transmitted symbol should equal its own tail. Look first at how the prefix is taken from the body and placed in front. Common mistake: copying the first samples of the body.');
assert(checkSymbolLength, ...
    'The symbol with its prefix should be Nfft + N_CP samples long. Look first at the order inside the concatenation: the prefix goes in front of the body.');

% Summarize the lengths of the body, the prefix, and the transmitted symbol.
tailResults = table( ...
    ["Useful body"; "Cyclic prefix"; "Transmitted symbol"], ...
    [tailNfft; tailCP; numel(symbolWithCP)], ...
    VariableNames = {'Part','Samples'});

tailResults
if isnan(myPredictionLength)
    disp('No length prediction recorded: type a number into myPredictionLength in this section and run this section again.')
else
    predLen = table(myPredictionLength, numel(symbolWithCP), ...
        VariableNames = {'YouPredicted','Result'});
    predLen
end
%% B4 — After the tail copy
% The table gives the three lengths for the tailCP you used. Because the front
% repeats the end, the symbol looks periodic over any Nfft-sample window that
% starts inside the prefix, which is what lets the receiver's FFT start
% slightly early without breaking orthogonality.

% The assertions above stop execution on failure; this table makes the
% successful tail-copy checks visible, as for the other beats.
tailCheckPassed = [checkCPIsTail; checkSymbolLength];
tailResultText = repmat("Pass", numel(tailCheckPassed), 1);
tailResultText(~tailCheckPassed) = "Fail";

tailChecks = table( ...
    ["CP equals the tail"; "Symbol length"], ...
    ["First N_CP samples = last N_CP samples of the body"; ...
     string(sprintf('Nfft + N_CP = %d + %d = %d', tailNfft, tailCP, tailNfft + tailCP))], ...
    tailResultText, ...
    VariableNames = {'Check','Expected','Pass'});

tailChecks

figure( ...
    Name = 'P00a - The cyclic prefix is a copy of the tail', ...
    Color = 'w', ...
    Position = [100 100 1200 640]);

tiledlayout(2,1, TileSpacing='loose', Padding='compact');

% Top: the whole transmitted symbol. Sample indices are shifted so the
% useful body starts at 0 and the prefix occupies negative indices.
nexttile;
sampleAxis = (-tailCP:tailNfft-1).';
plot(sampleAxis, real(symbolWithCP), Color=[0.20 0.40 0.80]);
hold on;
yLimits = max(abs(real(symbolWithCP))) * [-1.2 1.2];
patch([-tailCP 0 0 -tailCP], yLimits([1 1 2 2]), [0.90 0.30 0.10], ...
    FaceAlpha=0.25, EdgeColor='none');
patch([tailNfft-tailCP tailNfft tailNfft tailNfft-tailCP], yLimits([1 1 2 2]), ...
    [0.90 0.30 0.10], FaceAlpha=0.25, EdgeColor='none');
text(-tailCP/2, yLimits(2)*0.85, 'CP', HorizontalAlignment='center', FontWeight='bold');
text(tailNfft - tailCP/2, yLimits(2)*0.85, 'tail', HorizontalAlignment='center', FontWeight='bold');
hold off;
xlim([-tailCP-40 tailNfft+40]);
ylim(yLimits);
grid on;
xlabel('Sample index (useful body starts at 0)');
ylabel('Real part');
title('One OFDM symbol: the shaded tail is copied to the front as the prefix');

% Bottom: the prefix and the tail drawn on top of each other. If the CP is a
% true copy, the two traces coincide everywhere.
nexttile;
bodyTailStart = numel(symbolBody) - tailCP + 1;   % first sample of the tail of the body
plot(0:tailCP-1, real(symbolBody(bodyTailStart:end)), '-', ...
    Color=[0.90 0.30 0.10], LineWidth=3);
hold on;
plot(0:tailCP-1, real(symbolWithCP(1:tailCP)), 'k--', LineWidth=1.2);
hold off;
grid on;
xlim([0 tailCP-1]);
xlabel(sprintf('Sample within the %d-sample block', tailCP));
ylabel('Real part');
legend({sprintf('last %d samples of the body', tailCP), sprintf('first %d samples sent (CP)', tailCP)}, Location='best');
title('Prefix and tail overlap exactly: the CP is a copy, not new data');
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The Build it section follows. Figures and displayed
% tables remain visible after variables are cleared.

% The figure remains visible after local variables are cleared.
clear referenceNfft referenceSCS_Hz referenceFs_Hz ...
    cpNormal_2048 cpLong_2048 ...
    symbolsPerHalfSubframe ...
    cpLengthsHalfSubframe usefulLengthsHalfSubframe ...
    symbolStartSamples halfFrameSamples expectedHalfFrameSamples ...
    checkHalfSubframe symbolIndex symbolNumbers tl

% Also clear the tail-copy variables. The figures remain open.
clear tailNfft tailCP tailSpectrum tailBins symbolBody cpCopy symbolWithCP ...
    checkCPIsTail checkSymbolLength tailResults tailChecks ...
    tailCheckPassed tailResultText sampleAxis yLimits rotatedBody myPrediction ...
    sentTailStart bodyTailStart

% Clear the B4 calculation and table variables as well.
clear samplesPerSubframe_2048 symbolsPerSubframe scaledNfft scaledFs_Hz ...
    cpNormal_1024 cpLong_1024 cpNormal_us_2048 cpNormal_us_1024 ...
    checkReferenceSubframe checkReferenceDuration checkCPScaling checkCPDuration ...
    cpNfft cpSampleRateMHz cpNormalSamples cpLongSamples cpNormalDurationUs samplesPerSubframe_1024 ...
    cpResults cpChecks cpCheckName cpExpected checkPassed resultText
%% Build it — Make one OFDM symbol with its cyclic prefix
% Competency: turn one grid column into time samples with an IFFT, then put a 
% cyclic prefix in front by copying the tail.
% Problem
% You are given gridColumn, a column of 8 complex values: one tiny grid column 
% with 8 subcarriers. Build txSymbol, the samples you would send: first the IFFT 
% of the column (the body, 8 samples), then a prefix of Ncp = 2 samples copied 
% from the end of the body and placed in front.
% Allowed commands
% Square brackets [ ] and semicolons to stack columns; indexing x(a:b) and end; 
% numel; ifft; fft; abs; max; disp; fprintf. The plotting in Stage 4 is given.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at.
%% Stage 1 — switch it on
% Delete the % in front of the three code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% gridColumn = [1; 1j; -1; -1j; -1; 1; -1j; 1j];   % 8 subcarriers, one symbol
% Ncp = 2;   % prefix length, in samples
% disp(gridColumn)
%% Stage 1 check (given)
if ~exist('gridColumn','var') || ~exist('Ncp','var')
    disp('Stage 1 not done: delete the % in front of the three code lines above, then run that section.')
else
    assert(numel(gridColumn) == 8, ...
        'gridColumn should hold 8 values, one per subcarrier. Did you delete one?')
    assert(Ncp == 2 && Ncp == floor(Ncp), ...
        'Ncp should be the prefix length given in the problem (2 samples).')
    disp('Stage 1 OK')
end
%% Stage 2 — name and shape: the useful body
% Rename b to bodySamples, the name the checks expect. One IFFT turns the 8 
% subcarrier values into 8 time samples.
% Pass: Stage 2 OK.

% b = ifft(gridColumn);   % one inverse FFT of one grid column
%% Stage 2 check (given; the check goes back the other way with fft)
if ~exist('bodySamples','var')
    disp('Stage 2 not done: rename b to bodySamples, uncomment, and run.')
else
    assert(numel(bodySamples) == numel(gridColumn), ...
        'The body should have one sample per FFT bin. Look at what you passed to ifft.')
    assert(max(abs(fft(bodySamples) - gridColumn)) < 1e-12, ...
        'An FFT of the body should give gridColumn back. Did you use fft where ifft was needed?')
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: which body sample is copied to the front
% Before you build the prefix, type your prediction: txSymbol(1), the very first
% sample sent, is a copy of one sample of bodySamples. Which one? Type its
% position number (1 to 8). Use the rule "the prefix is a copy of the tail".
% Run this section and the check under it before you start Stage 3b: the check
% does not take a prediction once Stage 3b's names exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with the tail-start rule and does not print the value)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif ~exist('bodySamples','var') || ~exist('Ncp','var')
    disp('Stage 3a needs Stages 1 and 2 first: make gridColumn, Ncp, and bodySamples, then return here.')
elseif exist('cpPart','var') || exist('txSymbol','var')
    disp('Stage 3a refused: Stage 3b names already exist, so this is no longer a prediction. Run "clear cpPart txSymbol", then predict again.')
else
    % Different route: the tail starts Ncp samples before the end of the body.
    % This does not use cpPart or txSymbol.
    oraclePosition = numel(bodySamples) - Ncp + 1;
    okPrediction3 = (myPrediction == oraclePosition);
    stage3aCheck = table("Prediction = body position copied to the first sent sample", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at how long the prefix is, then at which samples of the body are its tail, then at which of those is sent first. Change myPrediction and run again.')
    end
end
%% Stage 3b — build the prefix
% Fill each blank with a whole right-hand side: cpPart is the last Ncp samples
% of bodySamples, and txSymbol is the prefix stacked in front of the body.
% Pass: your locked prediction and the matching body position appear side by
% side, and Stage 3 OK.

% cpPart = ___;
% txSymbol = ___;
%% Stage 3b check (given; the check builds the prefix by rotating the body, a different route from yours)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('cpPart','var') || ~exist('txSymbol','var')
    disp('Stage 3b not done: fill each blank with a whole right-hand side, uncomment, and run.')
else
    % Your locked prediction beside the body position that matches the first sent sample.
    matchPosition = find(abs(bodySamples - txSymbol(1)) < 1e-12, 1);
    stage3Prediction = table(myLockedPrediction, matchPosition, ...
        VariableNames = {'MyPrediction', 'BodyPositionBuilt'});
    stage3Prediction

    rotated = circshift(bodySamples, Ncp);   % the last Ncp samples move to the front
    oracle = [rotated(1:Ncp); bodySamples];
    copiedHead = max(abs(txSymbol(1:Ncp) - bodySamples(1:Ncp))) < 1e-12;
    okStage3 = [numel(txSymbol) == numel(bodySamples) + Ncp; ...
                ~(copiedHead && max(abs(txSymbol - oracle)) > 1e-12); ...
                max(abs(txSymbol - oracle)) < 1e-12];
    assert(okStage3(1), ...
        'txSymbol has the wrong length. It should be the body plus the prefix, nothing more.')
    assert(okStage3(2), ...
        'The prefix repeats the first samples of the body. Common mistake: the prefix is a copy of the tail.')
    assert(okStage3(3), ...
        'The prefix does not match the end of the body. Look at how you take the tail of the body and at the order inside [ ].')
    stage3Checks = table( ...
        ["Length is body plus prefix"; "Prefix is not a copy of the head"; "Prefix matches a rotation of the body"], ...
        okStage3, VariableNames = {'Check', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them. Rows marked
% "repeat of Stage 3" only repeat an earlier check; the other row uses a route
% you have not yet compared this way.

if ~exist('txSymbol','var') || ~exist('oracle','var') || ~exist('myLockedPrediction','var')
    disp('Stage 4 needs Stages 1 to 3 first: finish them, then Run All.')
else
    % The receiver drops the prefix and takes an FFT of what is left.
    recovered = fft(txSymbol(Ncp+1:end));
    sentTailStart = numel(txSymbol) - Ncp + 1;   % first sample of the tail of txSymbol

    % Each flag is computed from your result, so the table cannot say Pass by itself.
    buildFlags = [numel(txSymbol) == numel(gridColumn) + Ncp; ...
        max(abs(txSymbol(1:Ncp) - txSymbol(sentTailStart:end))) < 1e-12; ...
        max(abs(recovered - gridColumn)) < 1e-12];
    buildResult = repmat("Fail", numel(buildFlags), 1);
    buildResult(buildFlags) = "Pass";

    % Asserts above stop the run on failure; this table makes the passes visible.
    buildChecks = table(["Length (repeat of Stage 3)"; "Front equals tail (repeat of Stage 3)"; ...
        "Drop prefix, FFT gives the column back"], ...
        ["body plus prefix"; "first Ncp samples = last Ncp samples"; "same 8 values as gridColumn"], ...
        buildResult, VariableNames = {'Check','Expected','Pass'});
    buildChecks

    figure(Name = 'P00a Build it - my OFDM symbol', Color = 'w');
    sampleAxis = -Ncp:numel(bodySamples)-1;
    stem(sampleAxis, real(txSymbol), 'filled');
    hold on;
    stem(sampleAxis(1:Ncp), real(txSymbol(1:Ncp)), 'filled', Color = [0.90 0.30 0.10]);
    stem(sampleAxis(sentTailStart:end), real(txSymbol(sentTailStart:end)), 'filled', Color = [0.90 0.30 0.10]);
    hold off;
    grid on;
    xlabel('Sample index (body starts at 0; the prefix sits at negative indices)');
    ylabel('Real part');
    title('Orange: the prefix at the front and the tail it was copied from');
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): what
% do the two orange groups have in common, and why does dropping the prefix still
% give the receiver every subcarrier value back?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. The check uses your
% symbol and does not print a model sentence.
myAnswer = NaN;   % how many samples at the front of txSymbol match its tail, one-for-one?
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('txSymbol','var') || ~exist('Ncp','var')
    disp('Run Stages 1 to 4 first, then return here.')
else
    sentTailStart = numel(txSymbol) - Ncp + 1;
    nMatch = nnz(abs(txSymbol(1:Ncp) - txSymbol(sentTailStart:end)) < 1e-12);
    okInterp = (myAnswer == nMatch);
    interpCheck = table("Front samples that match the tail", ...
        okInterp, VariableNames = {'Check','Pass'});
    interpCheck
end
%% Build it — Cleanup
% If a later section says a variable is undefined, run the script from the top
% (Run All). Figures remain open. Names the Review needs are not used here.
clear buildFlags buildResult buildChecks predCompare oracle nMatch okInterp ...
    interpCheck myAnswer sentTailStart recovered copiedHead ...
    oraclePosition okPrediction3 stage3aCheck matchPosition okStage3 stage3Checks
%% Follow-on exercises
% These go one step past the beats: a new value, or a diagnosis. Copying a
% block from above and changing one number will not answer them. The checks
% do not print a model value.
%% E1 — New value
% Keep the 15 kHz spacing from B4 and set Nfft to 4096. What is the sample
% rate, in hertz? Type that number into myAnswer, then run this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE1 = abs(myAnswer - 4096*15e3) < 1e-6;
    e1Check = table("E1 sample rate", okE1, VariableNames = {'Check','Pass'});
    e1Check
end
%% E2 — Diagnosis
% A classmate used B3's 30 kHz clock (61.44 Msps) with B4's 144-sample prefix.
% What prefix duration, in microseconds, did they actually attach? Type that
% number into myAnswer, then run this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE2 = abs(myAnswer - 144/(61.44e6)*1e6) < 1e-6;
    e2Check = table("E2 prefix duration", okE2, VariableNames = {'Check','Pass'});
    e2Check
end
%% Exercise cleanup
clear myAnswer okE1 e1Check okE2 e2Check
%% Recap — P00a Grid and Waveform: OFDM and the Cyclic Prefix
% Every grid column is one IFFT; the samples then get a copied tail in front.
% Key relationships
% The sample rate is the FFT size times the spacing:
%
% $$f_s = N_{\mathrm{FFT}} \cdot \Delta f$$
%
% A fractional offset ε leaves only part of each tone's power in its own bin:
%
% $$P_{\mathrm{own}} \approx \left(\frac{\sin \pi\varepsilon}{\pi\varepsilon}\right)^2$$
%
% The CP is a fixed time, so its samples follow the rate:
%
% $$N_{\mathrm{CP}} = T_{\mathrm{CP}} \cdot f_s$$
% What this means in practice
% • Frequency offset between the two clocks must be kept small relative to
% the spacing; even a modest fraction of one spacing costs a noticeable share
% of each tone's power (read the single-tone row in B3).
%
% • The guard bins only catch the leakage that reaches the band edges; the
% rest becomes interference between the data tones themselves.
%
% • When you change the FFT size, recompute CP sample counts from the fixed
% duration and the new rate. Counts that belong to one clock do not carry
% over to another clock that happens to use the same Nfft.
%
% • The prefix carries no new information. It repeats the tail so the symbol
% looks periodic to the receiver's FFT.
%
% • You built one OFDM symbol by hand: an IFFT of an 8-value column, a short
% prefix taken from its tail, and a receiver check that drops the prefix and
% recovers every value.
%
% • Next in the album: P00b, the signal map and the coding chain.
%% Review — self-check
% Collapse or scroll past the Recap so it is out of sight, then write from
% memory, in your own words. Do not look back until you have written what you
% can. Nothing in the written lists below is graded by the script.
%
% First, restate each Key relationship from the front of the file, one line
% each. Then, for each command you write yourself (ifft and fft; x(k:end);
% [a; b]; numel), give its purpose, its inputs, and its outputs. When you have
% written all you can, scroll up to Key relationships and Key code terms and
% compare. Mark anything you missed.
% My key relationships
% 1.
%
% 2.
%
% 3.
% Commands I write (purpose; inputs; outputs)
% • ifft and fft:
%
% • x(k:end):
%
% • [a; b]:
%
% • numel:
% What I missed, and where to reread it
%
%% Review — retrieval
% Still keeping the Recap collapsed, type a number into myAnswer and run this
% section. From the bits-and-grid half of P00a, how many resource elements
% does one resource block occupy in one slot? The check uses a second route
% and does not print a model value.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    reFromFactors = 12 * 14;
    okReview = (myAnswer == reFromFactors);
    reviewCheck = table("REs in one RB in one slot", okReview, ...
        VariableNames = {'Check','Pass'});
    reviewCheck
end
