%% track06_taps_in_time_demo
%% Taps in Time (album track 06): TDL channel models, delay spread, and Doppler
% One signal leaves the tower. It reaches you many times: off buildings, off 
% hills, off the road. Every copy is late, and every one has its own strength.
% 
% This demonstration models that with a short list of taps, a tapped delay 
% line (TDL), and tests one assumption most people get wrong. Then it lets 
% the taps move in time, as fast as the phone does.
%% Guiding question
% How does a short list of taps stand in for every echo of a signal, and what 
% sets how long the echoes last and how fast they change?
% This demonstration
% 1. B1 — Build a TDL channel and scale its delays with DelaySpread; check 
% the echoes against the cyclic prefix.
% 
% 2. B2 — The counterexample: in TDL-A the first tap is not the loudest.
% 
% 3. B3 — Doppler: 30 m/s at 3 GHz is about 300 Hz, not the 5 Hz default, 
% and it sets how fast the taps fade.
% 
% 4. B4 — The three knobs an estimator must be told, and what reusing a stale 
% estimate costs.
% 
% 5. Build it — Set up a TDL for a new scenario: its Doppler, its coherence 
% time, and whether its echoes fit the prefix.
% Key relationships
% Each tabulated delay is normalized to the delay spread, so the delays the 
% channel uses are
% 
% $$\tau_{n} = \tau_{n,\mathrm{model}}\cdot \mathrm{DS}$$
% 
% The maximum Doppler shift for speed v at wavelength λ = c / f_c, and the 
% textbook rule of thumb for the coherence time, are
% 
% $$f_D = \frac{v}{\lambda} = \frac{v\,f_c}{c},\qquad T_c \approx \frac{0.423}{f_D}$$
% Key ideas to remember
% • A TDL model is a short list of taps. Each tap is a delay and an average 
% power, and each one fades.
% 
% • 3GPP (TR 38.901) gives five shapes, TDL-A to TDL-E. A, B, and C have no 
% line of sight; in D and E the first tap carries a steady direct path on 
% top of the fading.
% 
% • The table lists the delays in units of the delay spread: multiply every 
% normalized delay by DelaySpread, and the shape stays the same while the 
% time stretches. DelaySpread defaults to 30 ns; 300 ns is a long one.
% 
% • TDL-A has 23 taps. Its first tap sits at delay 0, 13.4 dB down; the second, 
% a little later, is the strongest at 0 dB. Echoes do not have to fade in 
% order.
% 
% • Doppler is speed over wavelength. At 3 GHz the wavelength is about 10 cm, 
% so 30 m/s gives about 300 Hz. The toolbox default, MaximumDopplerShift = 
% 5 Hz, is a slow walk at that frequency.
% 
% • Doppler sets how fast the path gains move, not the delay profile. The coherence 
% time T_c ≈ 0.423 / f_D is the time scale over which the channel decorrelates; 
% refresh an estimate well inside it (a small fraction of T_c).
% 
% • The simplified profiles TDLA30, TDLB100, and TDLC300 are valid DelayProfile 
% values too; their number is the delay spread in ns.
% Prerequisites
% • The sample rate and the FFT-size rule, nrOFDMInfo, and the cyclic prefix 
% in samples (album track 02 Copy the Tail, track02/track02_copy_the_tail_demo).
% 
% • Echoes, delay, and why a prefix must cover them (track 00 Fundamentals, 
% track00_fundamentals/p00a_ofdm_and_cp_demo), and channel dynamics (track00_fundamentals/p00b_softbits_and_dynamics_demo).
% 
% • Used here, not taught here: angles of arrival and departure are not in 
% a TDL; they come in album track 08 (Clusters and Angles). Estimating the 
% channel from pilots comes in album track 07 (Learn the Channel).
% Words used in this demo
% • TDL (tapped delay line): a channel written as a list of taps, each a delay 
% and a complex gain. Tap: one echo path.
% 
% • Delay profile: the table of normalized delays and average powers (TDL-A 
% to TDL-E). Delay spread (DS): the power-weighted RMS spread of the delays, 
% in seconds.
% 
% • Path gain: the complex gain of one tap at one moment. Average path gain: 
% its long-run average power, in dB.
% 
% • NLOS / LOS: no line of sight / line of sight. Rayleigh and Ricean fading: 
% fading without and with a steady direct part.
% 
% • Doppler shift f_D: the largest frequency shift motion gives, in Hz. Coherence 
% time T_c: the time scale over which the channel decorrelates; an estimate 
% is refreshed well inside it.
% 
% • Cyclic prefix (CP): the copied tail in front of each OFDM symbol; echoes 
% shorter than it do not spill into the next symbol.
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
% • + - * / — Purpose: arithmetic. Inputs: numbers. Outputs: the result.
% 
% • ch = nrTDLChannel(Name = value, ...) — Purpose: make a TDL channel. Inputs: 
% DelayProfile (such as "TDL-A"), DelaySpread (seconds), MaximumDopplerShift 
% (Hz), and SampleRate (Hz). Outputs: a channel object; call it on a waveform 
% to fade it.
% 
% • s = info(ch) — Purpose: the channel's summary. Inputs: the channel object. 
% Outputs: a structure with PathDelays (seconds) and AveragePathGains (dB), 
% one entry per tap.
% 
% • max(x) and numel(x) — Purpose: the largest entry; the number of entries. 
% Inputs: an array. Outputs: a number.
% 
% • a < b — Purpose: compare two numbers. Inputs: numbers. Outputs: true or 
% false.
% 
% Commands you read in the given code
% • [out, pathGains] = ch(in) — Purpose: pass a waveform through the channel. 
% Inputs: a column of samples. Outputs: the faded waveform and the path gains, 
% one row per sample and one column per tap (more dimensions for the antennas). 
% Used in B3.
% 
% • ofdmInfo = nrOFDMInfo(carrier) — Purpose: as in album track 02: the sample 
% rate, the FFT size, and the CP lengths in samples (CyclicPrefixLengths). 
% Inputs: a carrier. Outputs: a structure. Used in B1 and Build it.
% 
% • Figure family: figure(Name = ...), stem, plot, xline, xlabel, ylabel, title, 
% legend, grid on — Purpose: draw stems or lines, mark a value, label them, 
% and name the figure. Inputs: data and text. Outputs: a figure. Used in B2, 
% B3, and Build it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, x(:), x.', x(end), c{n}, s.name, A(:, n, 
% 1, 1) — Purpose: read entries, count a range, reshape, read a cell or a field, 
% pick one column of a many-dimensional array. Inputs: an array and positions. 
% Outputs: the entries.
% 
% • Compare and combine: == ~= > <= >=, && ||, .* ./ .^ — Purpose: compare 
% values; and, or; work entry by entry. Inputs: numbers or arrays. Outputs: 
% true/false or numbers.
% 
% • Control flow: for ... end, if ... else ... end — Purpose: repeat a block 
% for each value of a list; run one block or the other. Inputs: a list or a 
% true/false test. Outputs: whatever the blocks store.
% 
% • Built-in helpers: abs, log10, round, find, isequal, strcmp, complex, zeros, 
% cell, exist, isnan, NaN — Purpose: sizes and dB, round, find a position, 
% compare numbers or text, make empty arrays, look a name up. Inputs: numbers, 
% arrays, or names. Outputs: numbers or true/false (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, sprintf, and f = @(v) 
% ... — Purpose: write and join text, turn numbers into text, fill a format, 
% and make a one-line helper such as listText or Tc. Inputs: text, numbers, 
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
% Teaching draft built to the track01 r03 template (track06 r01, 2026-11-20) 
% from the live track06_demo.m on main d3b954c. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox. A named 
% profile's delays and powers are read from info(ch); the PathDelays and AveragePathGains 
% properties apply only to DelayProfile = 'Custom'. Teaching demo, not production 
% code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year); the fading draws below also set their own seed

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% The sample rate every beat uses: 52 RBs at 15 kHz, Nfft = 1024 (album track 02).
fs = 15.36e6;       % sample rate, Hz (1024 × 15 kHz)
%% B1 — Build the channel, scale the delays
% New words
% • Normalized delay: a tap's delay in units of the delay spread, as TR 38.901 
% tabulates it.
% 
% • Echo length: here, the delay of the latest tap, which must fit inside 
% the cyclic prefix.
% Why it matters
% A TDL is a list of delays and average powers. The tabulated TDL-A delays 
% are normalized; multiplying by DelaySpread stretches the same shape in time, 
% and the powers stay put. Ten times the delay spread is ten times the echo 
% length, which is the prefix question from album track 02: does the latest 
% echo still fit inside the CP?
% What to look for
% • In the delays table, compare the first and the last delay, in ns and in 
% samples, for 30 ns and 300 ns.
% 
% • Find the CP length in samples, and compare the last delays with it.
% Common mistakes
% Do not expect the powers to change when DelaySpread changes: only the delays 
% stretch.
% 
% Do not compare a delay in seconds with a CP length in samples: convert first, 
% samples = seconds × f_s.
% Try it (personal exploration)
% TDL-A's latest tap is at normalized delay 9.6586. Predict where it lands, 
% in samples at f_s = 15.36 MHz, when DelaySpread = 300 ns. Type it into myPrediction 
% before you run this section; the one-row table at the end shows the value, 
% the CP length, and whether it fits.

% Try it: type your prediction here (a number of samples) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Build the channel, scale the delays
fprintf("B1 — Build the channel, scale the delays\n");   % banner title only; every number below goes into a table

% Two delay spreads on the same TDL-A profile, no motion.
dsList = [30e-9 300e-9];            % DelaySpread values, s (30 ns and 300 ns)
delays = cell(size(dsList));        % each one's tap delays, s
gains  = cell(size(dsList));        % each one's average tap powers, dB

% For each delay spread: make the channel and read its taps from info(ch).
for k = 1:numel(dsList)
    ch = nrTDLChannel(DelayProfile = "TDL-A", ...   % 23-tap NLOS profile
        DelaySpread = dsList(k), ...                % RMS delay spread, s
        MaximumDopplerShift = 0, ...                % no motion, Hz
        SampleRate = fs);                           % sample rate, Hz
    chInfo    = info(ch);
    delays{k} = chInfo.PathDelays;
    gains{k}  = chInfo.AveragePathGains;
end

% The CP the echoes must fit in: normal CP, 52 RBs at 15 kHz (album track 02).
ofdmInfo = nrOFDMInfo(nrCarrierConfig(NSizeGrid = 52));   % 15 kHz by default
cpLen = ofdmInfo.CyclicPrefixLengths(2);                   % CP of a symbol that is not first in its half subframe, samples

% Two tests: the normalized delays are the same for both spreads, and the
% powers do not change. (TDL-A's first delay is 0, so compare d/DS directly
% instead of dividing one profile by the other.)
normDiff = max(abs(delays{2}/dsList(2) - delays{1}/dsList(1)));   % largest change in normalized delay
okShape = normDiff < 1e-9;
assert(okShape, ...
    'The normalized delays d/DelaySpread changed. Look first at the DelaySpread input: it is in seconds.');
okPowers = isequal(gains{1}, gains{2});
assert(okPowers, ...
    'The average powers changed with DelaySpread. Common mistake: changing DelayProfile between the two channels.');

b1Delays = table(dsList(:)*1e9, [delays{1}(1); delays{2}(1)]*1e9, [max(delays{1}); max(delays{2})]*1e9, ...
    [max(delays{1}); max(delays{2})]*fs, [cpLen; cpLen], ...
    VariableNames = {'DelaySpread_ns', 'FirstDelay_ns', 'LastDelay_ns', 'LastDelay_samples', 'CP_samples'});
b1Delays

% Put your Try-it prediction beside the latest tap at 300 ns, in samples.
tryLast = max(delays{2})*fs;          % latest tap at 300 ns, samples
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, round(tryLast, 1), cpLen, tryLast < cpLen, predictionNote, ...
    VariableNames = {'MyPrediction', 'LastDelay_samples', 'CP_samples', 'Fits', 'Note'});
b1Prediction
%%
% Both profiles start at delay 0 and keep the same shape; the 300 ns profile 
% is the 30 ns one stretched ten times, with the same powers. Compare each 
% last delay in samples with the CP: an echo inside the CP does not spill into 
% the next symbol. Compare the 300 ns value with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["Normalized delays d/DS unchanged"; ...
     "Average powers unchanged"], ...
    ["largest change < 1e-9"; "same 23 values"], ...
    ["largest change " + string(normDiff); string(numel(gains{2})) + " values, same = " + string(okPowers)], ...
    [okShape; okPowers], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep fs and listText. Everything made in B1 was used only to build, test,
% or show B1.
clear b1Delays b1Checks b1Prediction predictionNote okShape okPowers normDiff ...
      dsList delays gains k ch chInfo ofdmInfo cpLen tryLast myPrediction
%% B2 — The counterexample: first is not loudest
% New words
% • Tabulated average: the power a tap has on average, as the table lists 
% it. A faded realisation: what one draw of the channel gives at one moment.
% 
% Beat-only commands (B2)
% • [m, i] = max(x) — Purpose: the largest entry and its position. Inputs: 
% an array. Outputs: the value and its index.
% Why it matters
% TDL-A's first tabulated tap is −13.4 dB and the second is 0 dB, so "the earliest 
% path is the strongest path" is false for this profile. A search that always 
% locks onto tap 1 would lock onto a weak arrival. One faded draw can still 
% put the strongest moment on another tap: the claim is about the tabulated 
% averages, not one realisation.
% What to look for
% • In the powers table, read the first four average powers.
% 
% • In the figure, find the tallest stem and its delay.
% Common mistakes
% Do not test one call of the path gains to show that tap 2 is loudest: one 
% draw can say otherwise. Read AveragePathGains.
% Try it (personal exploration)
% TDL-C is another NLOS profile. Predict which tap number is the loudest on 
% the TDL-C table (1 if you think the first tap is). Type it into myPrediction 
% before you run this section; the one-row table at the end reads it from 
% a TDL-C channel.

% Try it: type your prediction here (a tap number) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — The counterexample
fprintf("B2 — The counterexample: first is not loudest\n");   % banner title only; every number below goes into a table

% TDL-A at the default spread, and its tabulated taps.
ch = nrTDLChannel(DelayProfile = "TDL-A", ...   % 23-tap NLOS profile
    DelaySpread = 30e-9, ...                    % default RMS delay spread, s
    MaximumDopplerShift = 0, ...                % no motion, Hz
    SampleRate = fs);                           % sample rate, Hz
chInfo = info(ch);
gains  = chInfo.AveragePathGains;               % average tap powers, dB

% Three tests: tap 1 is −13.4 dB, tap 2 is 0 dB, and tap 2 is louder.
okTap1 = abs(gains(1) + 13.4) < 0.05;           % TR 38.901 Table 7.7.2-1, tap 1: −13.4 dB
assert(okTap1, ...
    'TDL-A tap 1 should be -13.4 dB. Look first at DelayProfile: it should be "TDL-A".');
okTap2 = abs(gains(2) - 0.0) < 0.05;            % tap 2: 0 dB
assert(okTap2, ...
    'TDL-A tap 2 should be 0 dB. Common mistake: reading the path gains of one draw instead of AveragePathGains.');
okNotFirst = gains(2) > gains(1);
assert(okNotFirst, ...
    'Tap 2 should be louder than tap 1. Look first at the order: gains(1) is the first tap.');

first4Delays = chInfo.PathDelays(1:4);   first4Delays = first4Delays(:);   % first four delays, s, as a column
first4Gains  = gains(1:4);               first4Gains  = first4Gains(:);    % first four powers, dB, as a column
b2Powers = table((1:4).', first4Delays*1e9, first4Gains, ...
    VariableNames = {'Tap', 'Delay_ns', 'AveragePower_dB'});
b2Powers

% The whole profile: delay against average power.
figure(Name = 'Track 06 B2 - TDL-A average powers', Color = 'w');
stem(chInfo.PathDelays*1e9, gains, 'filled');   % one stem per tap
grid on;
xlabel('delay (ns)');
ylabel('average power (dB)');
title('TDL-A at 30 ns: the first tap is not the loudest');

% Try it: the loudest tap on TDL-C (no assert on it).
chTry = nrTDLChannel(DelayProfile = "TDL-C", ...   % 24-tap NLOS profile
    DelaySpread = 30e-9, MaximumDopplerShift = 0, SampleRate = fs);   % s, Hz, Hz
[~, tryLoudest] = max(info(chTry).AveragePathGains);   % tap number of the loudest average power
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, tryLoudest, predictionNote, ...
    VariableNames = {'MyPrediction', 'LoudestTapTDLC', 'Note'});
b2Prediction
%%
% The first TDL-A tap arrives at delay 0 but 13.4 dB down; the loudest arrives 
% a little later. A receiver that assumes the first arrival is the strongest 
% would time itself on a weak echo. Compare the TDL-C answer with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["TDL-A tap 1 = -13.4 dB"; ...
     "TDL-A tap 2 = 0 dB"; ...
     "Tap 2 louder than tap 1"], ...
    ["-13.4 ± 0.05"; "0 ± 0.05"; "true"], ...
    [string(gains(1)); string(gains(2)); string(okNotFirst)], ...
    [okTap1; okTap2; okNotFirst], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B2 was used only to build, test, or show B2.
clear b2Powers b2Checks b2Prediction predictionNote okTap1 okTap2 okNotFirst ...
      ch chInfo gains first4Delays first4Gains chTry tryLoudest myPrediction
%% B3 — Doppler: fading in time
% New words
% • Wavelength λ = c / f_c: the length of one cycle of the carrier, in metres.
% 
% • Fading in time: each tap's complex gain wanders around its average power; 
% Doppler sets how fast.
% 
% Beat-only commands (B3)
% • Seed = 7 and RandomStream = "mt19937ar with seed" — Purpose: name-value 
% inputs of nrTDLChannel that make its fading draws repeat. Inputs: a whole 
% number and the stream name. Outputs: none of their own.
% 
% • f = @(x) ... — Purpose: a one-line function, here Tc(f) = 0.423 / f. Inputs: 
% a number. Outputs: the formula's value.
% Why it matters
% The maximum Doppler shift is f_D = v / λ = v f_c / c. At 3 GHz, λ is about 
% 0.1 m, so a car at 30 m/s gives about 300 Hz. The toolbox default MaximumDopplerShift 
% = 5 Hz is only about 0.5 m/s at that carrier: a slow walk, not a drive. 
% That number sets how fast the path gains move, not the delay profile. The 
% coherence time, T_c ≈ 0.423 / f_D, is the time scale over which the channel 
% decorrelates: a little over a millisecond at 300 Hz, and tens of milliseconds 
% at 5 Hz. Refresh an estimate well inside it, a small fraction of T_c.
% What to look for
% • In the Doppler table, read λ, f_D, the speed the 5 Hz default stands for, 
% and T_c at both Doppler values.
% 
% • In the figure, compare how fast tap 2 fades over 10 ms at 5 Hz and at 
% 300 Hz.
% Common mistakes
% Do not leave the 5 Hz default in a high-speed script.
% 
% Do not confuse Doppler (how fast the channel changes in time) with delay 
% spread (how long the echoes last).
% Try it (personal exploration)
% Predict f_D for a cyclist at v = 3 m/s on the same 3 GHz carrier. Type it 
% into myPrediction before you run this section; the one-row table at the 
% end works it out.

% Try it: type your prediction here (in Hz) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Doppler: fading in time
fprintf("B3 — Doppler: fading in time\n");   % banner title only; every number below goes into a table

% The carrier, the speed, and the Doppler they give.
c  = 299792458;       % speed of light, m/s
fc = 3e9;             % carrier frequency, Hz
v  = 30;              % speed, m/s (a car)
lambda = c/fc;        % wavelength, m
fD = v/lambda;        % maximum Doppler shift, Hz
vDefault = 5*lambda;  % the speed the 5 Hz default stands for at this carrier, m/s
Tc = @(f) 0.423 ./ f; % coherence time rule of thumb, s, for a Doppler f in Hz

% Two tests: 3 GHz is a 10 cm wavelength, and 30 m/s gives 300 Hz.
okLambda = abs(lambda - 0.1) < 1e-4;    % within 0.1 mm
assert(okLambda, ...
    'The wavelength at 3 GHz should be about 0.1 m. Look first at the units: fc in Hz, c in m/s.');
okFD = abs(fD - 300) < 0.5;             % within 0.5 Hz
assert(okFD, ...
    'f_D should be about 300 Hz. Common mistake: multiplying v by lambda instead of dividing.');

b3Doppler = table(lambda, fc/1e9, v, fD, vDefault, Tc(fD)*1e3, Tc(5)*1e3, ...
    VariableNames = {'Lambda_m', 'fc_GHz', 'v_mps', 'fD_Hz', 'vFor5Hz_mps', 'Tc_ms_at_fD', 'Tc_ms_at_5Hz'});
b3Doppler

% Fade tap 2 for 10 ms at 5 Hz and at f_D, on the same seed, and keep its
% path gain over time.
nSamp10ms = round(fs*10e-3);          % samples in 10 ms
tAx = (0:nSamp10ms-1).'/fs;           % time axis, s
fdList = [5 fD];                      % the two Doppler values, Hz
pgTap2 = zeros(nSamp10ms, numel(fdList));   % tap-2 path gain at each sample, one column per Doppler
for m = 1:numel(fdList)
    chK = nrTDLChannel(DelayProfile = "TDL-A", ...   % same profile as B1 and B2
        DelaySpread = 30e-9, ...                     % s
        MaximumDopplerShift = fdList(m), ...         % Hz
        SampleRate = fs, ...                         % Hz
        Seed = 7, RandomStream = "mt19937ar with seed");   % same fading draws for both
    [~, pg] = chK(complex(zeros(nSamp10ms, 1)));     % path gains: samples × taps × tx × rx antennas
    pgTap2(:, m) = pg(:, 2, 1, 1);                   % tap 2 (the strongest), first antenna pair
end

figure(Name = 'Track 06 B3 - fading in time', Color = 'w');
plot(tAx*1e3, 20*log10(abs(pgTap2(:,1))), tAx*1e3, 20*log10(abs(pgTap2(:,2))));   % dB over time
grid on;
xlabel('time (ms)');
ylabel('|path gain|, tap 2 (dB)');
legend('f_D = 5 Hz', sprintf('f_D = %.0f Hz', fD));
title('Same profile, two Doppler settings');

% Put your Try-it prediction beside f_D for 3 m/s.
tryV  = 3;                    % Try-it speed, m/s
tryFD = tryV/lambda;          % its Doppler, Hz
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, tryV, round(tryFD, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'v_mps', 'fD_Hz', 'Note'});
b3Prediction
%%
% The same profile fades very differently: at 5 Hz the tap barely moves in 
% 10 ms, and at 300 Hz it swings through several deep fades. The Doppler table 
% says why: the coherence time at 300 Hz is a little over a millisecond, at 
% 5 Hz tens of milliseconds. Compare the cyclist's f_D with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["Wavelength at 3 GHz ≈ 0.1 m"; ...
     "f_D for 30 m/s at 3 GHz ≈ 300 Hz"], ...
    ["0.1 ± 1e-4 m"; "300 ± 0.5 Hz"], ...
    [string(round(lambda, 5)) + " m"; string(round(fD, 2)) + " Hz"], ...
    [okLambda; okFD], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep fD, Tc, pgTap2, and fdList: B4 reuses the 10 ms draws. Everything else
% made in B3 was used only to build, test, or show B3.
clear b3Doppler b3Checks b3Prediction predictionNote okLambda okFD ...
      c fc v lambda vDefault nSamp10ms tAx m chK pg tryV tryFD myPrediction
%% B4 — Shortcuts, and what the estimator must track
% New words
% • Stale estimate: a channel estimate made at one moment and reused later, 
% after the channel has moved.
% 
% • Reuse error: how far the path gain has moved between the two moments, 
% as a fraction of its size then.
% Why it matters
% TDL-A, B, and C are compact stand-ins for a measured channel. They are useful 
% because they repeat, but they hide the angles (album track 08), and they 
% do not excuse an estimator from tracking whatever time variation you asked 
% for. Three knobs tell it what channel to face: DelayProfile, DelaySpread, 
% and MaximumDopplerShift. At 300 Hz an estimate goes stale within a slot; 
% at 5 Hz it stays usable for many slots. (The song's "estimator from last 
% time" is taught in the next album track, 07 Learn the Channel.)
% What to look for
% • In the knobs table, read the profile, the delay spread, f_D, and f_s.
% 
% • In the check table, compare how far tap 2 swings in dB at 5 Hz and at f_D.
% 
% • In the reuse table, compare the reuse error from symbol 2 to symbol 13 
% at 5 Hz and at 300 Hz.
% Common mistakes
% Do not mix a TDL-A delay table with a CDL angle plot: a TDL has no angles.
% 
% Do not estimate once per slot at 300 Hz as if the channel were static.
% Try it (personal exploration)
% At 15 kHz one OFDM symbol lasts 1 ms / 14. Use T_c from the B3 Doppler table 
% to predict how many symbols fit in one coherence time at f_D ≈ 300 Hz. Type 
% it into myPrediction before you run this section; the one-row table at the 
% end works it out.
% 
% Then, optionally, change the reuse gap (symbol 13 below) and run again: 
% the reuse errors are read, not checked, so this does not stop the run.

% Try it: type your prediction here (a number of symbols) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Shortcuts, and what the estimator must track
fprintf("B4 — Shortcuts, and what the estimator must track\n");   % banner title only; every number below goes into a table

% The channel an estimator is told to face: three knobs and the sample rate.
chFast = nrTDLChannel(DelayProfile = "TDL-A", ...   % profile
    DelaySpread = 30e-9, ...                        % RMS delay spread, s
    MaximumDopplerShift = fD, ...                   % Doppler from B3, Hz
    SampleRate = fs);                               % sample rate, Hz

% Behaviour, not read-back: over B3's 10 ms, tap 2 swings more in dB at f_D
% than at 5 Hz (the spread of 20 log10|g| over time).
swingDB = [std(20*log10(abs(pgTap2(:, 1)))), std(20*log10(abs(pgTap2(:, 2))))];   % dB, at 5 Hz and at f_D
okFaster = swingDB(2) > swingDB(1);
assert(okFaster, ...
    'Tap 2 should swing more at f_D than at 5 Hz. Look first at B3: the second column of pgTap2 must be the f_D draw.');

b4Knobs = table(string(chFast.DelayProfile), chFast.DelaySpread*1e9, chFast.MaximumDopplerShift, fs/1e6, ...
    VariableNames = {'DelayProfile', 'DelaySpread_ns', 'fD_Hz', 'fs_MHz'});
b4Knobs

% Reuse an estimate from symbol 2 on symbol 13, using B3's 10 ms draws of tap 2.
tSym = 1e-3/14;                       % one 15 kHz OFDM symbol, s (about 71.4 µs)
symFrom = 2;  symTo = 13;             % the two symbol numbers (0-based in the slot)
nFrom = round(symFrom*tSym*fs) + 1;   % sample at the start of symbol 2 (1-based)
nTo   = round(symTo*tSym*fs) + 1;     % sample at the start of symbol 13
reuseErr = abs(pgTap2(nTo, :) - pgTap2(nFrom, :)) ./ abs(pgTap2(nFrom, :));   % one value per Doppler

b4Reuse = table(fdList(:), [(nTo - nFrom)/fs*1e3; (nTo - nFrom)/fs*1e3], 100*reuseErr(:), ...
    VariableNames = {'fD_Hz', 'Gap_ms', 'ReuseError_percent'});
b4Reuse

% Put your Try-it prediction beside the symbols in one coherence time at f_D.
trySym = Tc(fD)/tSym;                 % OFDM symbols in T_c at f_D
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, round(trySym, 1), predictionNote, ...
    VariableNames = {'MyPrediction', 'SymbolsPerTc', 'Note'});
b4Prediction
%%
% The knobs table is the channel the estimator is told to face. Between symbol 
% 2 and symbol 13 the tap barely moves at 5 Hz, and it moves a lot more at 
% 300 Hz; the exact errors depend on the draw. An estimate from the start of 
% a slot is no longer safe at the end of it at 300 Hz: the 11-symbol gap is 
% more than half of T_c there (divide it by SymbolsPerTc), far more than a 
% small fraction of T_c, so the channel has partly decorrelated. Compare the 
% symbols per coherence time with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flag.
b4Checks = table( ...
    ["Tap 2 swings more at f_D than at 5 Hz"], ...
    ["std at f_D > std at 5 Hz"], ...
    [string(round(swingDB(2), 2)) + " dB vs " + string(round(swingDB(1), 2)) + " dB"], ...
    [okFaster], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B4, and the B3 values kept for it, was used only to
% build, test, or show the beats. Keep fs and listText.
clear b4Knobs b4Reuse b4Checks b4Prediction predictionNote swingDB okFaster ...
      chFast tSym symFrom symTo nFrom nTo reuseErr trySym myPrediction ...
      fD Tc pgTap2 fdList
%% Build it — Set up a TDL for a new scenario
% Competency: given a carrier frequency, a speed, a profile, and a delay spread, 
% work out the wavelength, the Doppler shift, and the coherence time; build 
% the TDL channel; and test whether its latest echo fits inside the cyclic 
% prefix.
% Problem
% A car drives at 120 km/h past a cell at 3.5 GHz. The channel is TDL-C with 
% a delay spread of 100 ns, sampled at the B1 rate. Work out λ and f_D, build 
% the channel with those values, read its latest tap delay in samples, then 
% work out the coherence time, how many 15 kHz OFDM symbols fit in it, and 
% whether the latest echo fits in the CP.
% Allowed commands
% Ordinary arithmetic + - * /; nrTDLChannel with name-value inputs; info; max 
% and numel; the comparison <. The tables and the figure in the check sections 
% and Stage 5 are given. All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section. The last 
% two lines read the CP length in samples from nrOFDMInfo, as in B1.
% Pass: the check below prints Stage 1 OK.

% myFc = 3.5e9;          % carrier frequency, Hz: given for this exercise
% myV = 120/3.6;         % speed, m/s: 120 km/h divided by 3.6
% myDS = 100e-9;         % RMS delay spread, s: given
% myProfile = "TDL-C";   % delay profile: given
% myC = 299792458;       % speed of light, m/s
% myOfdm = nrOFDMInfo(nrCarrierConfig(NSizeGrid = 52));   % 15 kHz carrier, 52 RBs, as in B1
% myCP = myOfdm.CyclicPrefixLengths(2);                     % normal CP, samples
%% Stage 1 check (given)
if ~exist('myFc','var') || ~exist('myV','var') || ~exist('myDS','var') || ~exist('myProfile','var') ...
        || ~exist('myC','var') || ~exist('myCP','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = myFc == 3.5e9 && abs(myV - 120/3.6) < 1e-12 && myDS == 100e-9 && myProfile == "TDL-C" && myC == 299792458;   % the values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the lines you uncommented: 3.5e9, 120/3.6, 100e-9, "TDL-C", and 299792458.')
    stage1Checks = table("Given values", "3.5 GHz, 33.33 m/s, 100 ns, TDL-C", ...
        string(myFc/1e9) + " GHz, " + string(round(myV, 2)) + " m/s, " + string(myDS*1e9) + " ns, " + myProfile, okStage1, ...   % expected: the given values
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — wavelength and Doppler
% Fill the blanks: the wavelength from the speed of light and the carrier, 
% then the Doppler shift from the speed and the wavelength.
% Pass: Stage 2 OK.

% myLambda = ___ / ___;
% myFD = ___ / myLambda;
%% Stage 2 check (given; the check works f_D out as v f_c / c, a different route from yours)
if ~exist('myLambda','var') || ~exist('myFD','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: f_D = v f_c / c, and λ f_c = c.
    oracleFD = myV*myFc/myC;

    % Two tests: the wavelength times the carrier is the speed of light, and
    % f_D matches the other route.
    okStage2 = [abs(myLambda*myFc - myC) < 1e-3; ...        % m/s, to rounding
                abs(myFD - oracleFD) < 1e-6];               % Hz, to rounding
    assert(okStage2(1), ...
        'myLambda is off. Look first at the order: the speed of light divided by the carrier frequency.')
    assert(okStage2(2), ...
        'myFD is off. Common mistake: multiplying the speed by the wavelength instead of dividing.')
    stage2Checks = table( ...
        ["λ × f_c = c"; "f_D = v f_c / c"], ...
        [string(myC) + " m/s"; string(round(oracleFD, 3)) + " Hz"], ...
        [string(round(myLambda*myFc, 3)) + " m/s"; string(round(myFD, 3)) + " Hz"], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then build the channel and read its latest echo
% First type your prediction: how many samples late is the latest TDL-C tap 
% (TDL-C's latest normalized delay is 8.6523)? Then fill the blanks: the channel 
% with your profile, delay spread, and Doppler at the B1 sample rate fs; its 
% tap delays from info; and the latest delay in samples.
% Pass: your prediction and your value appear side by side in a one-row table, 
% and Stage 3 OK.

% myPrediction = ___;
% myCh = nrTDLChannel(DelayProfile = ___, DelaySpread = ___, MaximumDopplerShift = ___, SampleRate = fs);
% myDelays = info(___).PathDelays;
% myMaxSamp = max(___) * fs;
%% Stage 3 check (given; the check reads the normalized delays and the knobs back, a different route from yours)
if ~exist('myCh','var') || ~exist('myDelays','var') || ~exist('myMaxSamp','var') || ~exist('myPrediction','var')
    disp('Stage 3 not done: type your prediction, fill the blanks, uncomment, and run.')
else
    % Your prediction beside your value, in one row.
    stage3Prediction = table(myPrediction, round(myMaxSamp, 2), ...
        VariableNames = {'MyPrediction', 'MyMaxSamples'});
    stage3Prediction

    % Different route: the latest delay divided by the delay spread is the
    % table's latest normalized delay.
    oracleNorm = max(myDelays)/myDS;      % latest normalized delay (no unit)

    % Three tests: the channel holds your knobs, it has the 24 TDL-C taps,
    % and the latest delay in samples matches the normalized value.
    okStage3 = [myCh.DelayProfile == myProfile && myCh.DelaySpread == myDS && myCh.MaximumDopplerShift == myFD; ...
                numel(myDelays) == 24; ...                                           % TR 38.901 Table 7.7.2-3: 24 taps
                abs(myMaxSamp - oracleNorm*myDS*fs) < 1e-9 && abs(oracleNorm - 8.6523) < 1e-3];   % table value, 4 decimals
    assert(okStage3(1), ...
        'The channel does not hold your knobs. Look first at the three name-value inputs: myProfile, myDS, and myFD.')
    assert(okStage3(2), ...
        'The channel should have 24 taps. Look first at DelayProfile: it should be the TDL-C profile from Stage 1.')
    assert(okStage3(3), ...
        'myMaxSamp is off. Common mistake: taking the last entry instead of the largest, or leaving it in seconds.')
    stage3Checks = table( ...
        ["Channel holds myProfile, myDS, myFD"; "Number of taps"; "Latest delay in samples"], ...
        [myProfile + ", " + string(myDS*1e9) + " ns, " + string(round(myFD, 2)) + " Hz"; "24"; string(round(oracleNorm*myDS*fs, 3))], ...
        [string(myCh.DelayProfile) + ", " + string(myCh.DelaySpread*1e9) + " ns, " + string(round(myCh.MaximumDopplerShift, 2)) + " Hz"; ...
         string(numel(myDelays)); string(round(myMaxSamp, 3))], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — coherence time, symbols, and the CP test
% Fill the blanks: the coherence time from the rule of thumb in Key relationships; 
% how many 15 kHz OFDM symbols (1 ms / 14 each) fit in it; and whether the 
% latest echo is shorter than the CP.
% Pass: Stage 4 OK.

% myTc = 0.423 / ___;
% mySymPerTc = myTc / (___ / 14);
% myFits = ___ < myCP;
%% Stage 4 check (given; the check works T_c out from λ and v, a different route from yours)
if ~exist('myTc','var') || ~exist('mySymPerTc','var') || ~exist('myFits','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: T_c = 0.423 λ / v, and symbols = T_c × 14000.
    oracleTc  = 0.423*myLambda/myV;       % s
    oracleSym = oracleTc*14000;           % 14 symbols per ms at 15 kHz

    % Three tests: T_c, the symbol count, and the fit test.
    okStage4 = [abs(myTc - oracleTc) < 1e-12; ...
                abs(mySymPerTc - oracleSym) < 1e-6; ...
                islogical(myFits) && myFits == (oracleNorm*myDS*fs < myCP)];
    assert(okStage4(1), ...
        'myTc is off. Look first at what you divided 0.423 by: the Doppler shift in Hz.')
    assert(okStage4(2), ...
        'mySymPerTc is off. Look first at the units: the slot time must be in seconds, like myTc.')
    assert(okStage4(3), ...
        'myFits is off. Look first at the units: compare the latest delay in samples with the CP in samples.')
    stage4Checks = table( ...
        ["T_c = 0.423 λ / v"; "Symbols in T_c"; "Latest echo inside the CP"], ...
        [string(round(oracleTc*1e3, 4)) + " ms"; string(round(oracleSym, 2)); string(oracleNorm*myDS*fs < myCP)], ...
        [string(round(myTc*1e3, 4)) + " ms"; string(round(mySymPerTc, 2)); string(myFits)], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myFits','var') || ~exist('myCh','var') || ~exist('myTc','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    myGains = info(myCh).AveragePathGains;                    % average tap powers, dB
    buildFlags = [abs(myFD - myV/(myC/myFc)) < 1e-6; ...
        abs(myMaxSamp - max(myDelays)*fs) < 1e-9; ...
        abs(myTc*myFD - 0.423) < 1e-12; ...
        myFits == (myMaxSamp < myCP); ...
        abs(max(myGains)) < 0.05];                            % the loudest TDL-C tap is the 0 dB one (to 0.05 dB, as in B2)

    % One row per result: the rule's value, your value, and the computed flag.
    buildChecks = table( ...
        ["f_D = v / λ"; "Latest delay = max(PathDelays) × f_s"; "T_c × f_D = 0.423"; ...
         "Fits = latest delay < CP"; "Loudest average tap at 0 dB"], ...
        [string(round(myV/(myC/myFc), 3)); string(round(max(myDelays)*fs, 3)); "0.423"; ...
         string(myMaxSamp < myCP); "0"], ...
        [string(round(myFD, 3)); string(round(myMaxSamp, 3)); string(round(myTc*myFD, 6)); ...
         string(myFits); string(max(myGains))], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: your profile in samples, with the CP marked.
    figure(Name = 'Track 06 Build it - my channel', Color = 'w');
    stem(myDelays*fs, myGains, 'filled');                    % one stem per tap: delay in samples, power in dB
    xline(myCP, '--', 'CP');                                  % the CP length, samples
    grid on;
    xlabel('delay (samples at f_s)');
    ylabel('average power (dB)');
    title(sprintf('%s at %.0f ns: f_D = %.0f Hz, T_c = %.2f ms', myProfile, myDS*1e9, myFD, myTc*1e3));
end
%%
% Your interpretation (write one or two sentences here): what set the Doppler 
% shift, and how many OFDM symbols can one channel estimate last at this speed? 
% Does the latest echo fit in the CP, and would it still fit at ten times the 
% delay spread?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; fs and listText stay in case you rerun a check.
clear okStage1 stage1Checks oracleFD okStage2 stage2Checks ...
      stage3Prediction oracleNorm okStage3 stage3Checks ...
      oracleTc oracleSym okStage4 stage4Checks myGains buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B1)
% A hilly rural cell is modelled as TDL-A with a delay spread of 1000 ns. Work 
% out the latest echo in microseconds and in samples at the B1 rate. Does it 
% fit in the normal CP? Name the problem it causes if it does not.
% 
% Your answer:
% E2 — Diagnosis (B1, Common mistakes)
% A classmate sets TDL-A with DelaySpread = 600e-9 and says "600 ns is far less 
% than the 4.7 µs CP, so every echo fits". What did they compare, and what 
% should they have compared? Is their conclusion right? What is the largest 
% delay spread for which every TDL-A echo still fits in the normal CP?
% 
% Your answer:
% E3 — New values (B3)
% A high-speed train runs at 500 km/h past a 2.6 GHz cell. Work out λ, f_D, 
% the coherence time, and how many 15 kHz OFDM symbols fit in it. Compare with 
% the Build it car, and say what this means for how often the DM-RS has to 
% be sent.
% 
% Your answer:
% E4 — Explanation (B2)
% Explain the difference between the first tap, the loudest tap on average 
% (AveragePathGains), and the loudest tap in one slot. Why should a receiver 
% not lock its timing to whichever tap happens to be loudest in one slot?
% 
% Your answer:
% E5 — Diagnosis (B3)
% A 28 GHz simulation leaves MaximumDopplerShift at its default. Work out the 
% wavelength, the speed that default really models, and the f_D a walker at 
% 1.4 m/s should have. What would the simulation get wrong about channel 
% estimation?
% 
% Your answer:
% E6 — New values and explanation (B4)
% Suppose an estimate may be used at most 0.1 T_c away from the pilot it came 
% from. For the B3 car at 30 m/s (T_c from the B3 Doppler table), how many 
% 15 kHz symbols is 0.1 T_c, and so roughly how far apart may DM-RS symbols 
% be? Which DMRSAdditionalPosition setting from album track 05 B5 comes closest, 
% and what does it cost?
% 
% Your answer:
%% Recap — Taps in Time (album track 06)
% A TDL model is a short list of taps: each a delay scaled by the delay spread, 
% an average power, and a fade. The delay spread sets how long the echoes last; 
% the speed and the carrier set how fast they change.
% Key relationships
% $$\tau_{n} = \tau_{n,\mathrm{model}}\cdot \mathrm{DS},\qquad f_D = \frac{v\,f_c}{c},\qquad 
% T_c \approx \frac{0.423}{f_D}$$
% What this means in practice
% • Compare the latest echo with the CP in the same units: samples or seconds, 
% never the delay spread alone.
% 
% • The first tap is not always the loudest; read AveragePathGains before you 
% assume.
% 
% • The default MaximumDopplerShift of 5 Hz is a walker at low band, not a car; 
% set it from the speed and the carrier.
% 
% • T_c ≈ 0.423 / f_D is the time scale over which the channel decorrelates; 
% refresh an estimate well inside it (a small fraction of T_c), so faster 
% means more DM-RS.
% 
% • An estimator must be told the profile, the delay spread, and the Doppler 
% shift the channel really has.
% 
% • You set up a new TDL scenario, worked out its Doppler and coherence time, 
% and tested its latest echo against the CP.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 02 (track02/track02_copy_the_tail_demo), why must every echo 
% arrive within the cyclic prefix?
% 
% • Next in the album: track07 (Learn the Channel).
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
% • + - * /:
% 
% • nrTDLChannel:
% 
% • info:
% 
% • max and numel:
% 
% • a < b:
% What I missed, and where to reread it
% 
