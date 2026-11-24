%% track15_end_to_end_demo
%% End to End (album track 15): one config, one waveform, a real radio, and the bits back
% In Mirror Image, each flaw of a real radio went in on its own, and the 
% flaws combined by root-sum-square. Now everything from the album goes into 
% one scenario: one downlink configuration, one waveform, a chain of impairments 
% in the order the hardware has them, and a receiver that must hand back the 
% bits.
% 
% This demonstration generates a 10 ms downlink waveform from one config, 
% builds the impairment chain in hardware order, proves that the chain with 
% everything off returns the exact transport-block bits, and then turns the 
% impairments on one at a time and all together.
%% Guiding question
% When every piece of the link is in one chain, how do you prove the plumbing 
% is right, and how do you find which flaw costs what?
% This demonstration
% 1. B1 — One config, one waveform: nrDLCarrierConfig and nrWaveformGenerator, 
% and what the generator says it put in the grid.
% 
% 2. B2 — Make the radio real, in hardware order: the impairment stages, 
% each one switchable.
% 
% 3. B3 — The plumbing invariant: everything off, and the transport-block 
% bits come back.
% 
% 4. B4 — One change at a time, then all together: EVM per impairment and 
% the root-sum-square test.
% 
% 5. Build it — Read an impairment breakdown: the rss, the plain sum, whether 
% the pieces are independent, and what removing the largest one buys.
% Key relationships
% Waveform length for N subframes of 1 ms at sample rate f_s:
% 
% $$N_{\mathrm{samples}} = f_s \cdot N \cdot 1\ \mathrm{ms}$$
% 
% Noise EVM on the used resource elements (album track 02), with K̄ used 
% subcarriers per symbol on average:
% 
% $$\mathrm{EVM_{noise}} \approx 100\sqrt{\frac{\bar K}{N_{\mathrm{FFT}}\cdot\mathrm{SNR}}}\ \%$$
% 
% Independent impairments add in power:
% 
% $$\mathrm{EVM_{total}} \approx \sqrt{\textstyle\sum_i \mathrm{EVM}_i^2}$$
% Key ideas to remember
% • Start with nrDLCarrierConfig: the spacing, the grid size, the bandwidth. 
% Put the sync burst and the shared channel into that same config, and nrWaveformGenerator 
% hands back one waveform with everything in its place.
% 
% • Then make the radio real, in the order the hardware has it: phase noise 
% from comm.PhaseNoise, an IQ imbalance from iqimbal, and the amplifier from 
% comm.MemorylessNonlinearity, backed off from its peak; then the channel 
% (nrCDLChannel, with a panel array on the transmit side, clusters from every 
% angle, both polarizations); then the receiver's own noise, from comm.ThermalNoise.
% 
% • Put the amplifier after the channel and the noise and you have modelled 
% a different radio: it compresses the noise too, and the fading, and your 
% EVM blames the wrong part. Impairments go where the hardware puts them.
% 
% • On the receive side, nrTimingEstimate finds the start, nrOFDMDemodulate 
% gives back the grid, nrChannelEstimate learns the channel from the reference 
% signals, nrEqualizeMMSE undoes it, and the decoders check the CRC. Measure 
% EVM on the equalized symbols with comm.EVM, and the block error rate from 
% the CRC, slot after slot.
% 
% • The invariant: turn every impairment off, give it a clean channel and 
% plenty of signal, and the chain must hand back exactly the bits you sent.
% 
% • Change one thing at a time and keep the random seeds fixed. Turn on one 
% impairment and write down the EVM and the block error rate; then turn them 
% all on together and compare the total with your sum of squares.
% 
% • Independent pieces add in power: three percent and four percent make 
% about five, not seven. If the total is much bigger than the root of the 
% sum of squares, two of your pieces are not independent. Then sweep the SNR 
% and watch the waterfall move as each flaw comes in.
% Prerequisites
% • Impairments one at a time, the image at −k, and root-sum-square (album 
% track 14 Mirror Image, track14/track14_mirror_image_demo).
% 
% • Transport blocks, redundancy versions, and DM-RS (album track 05 Say It 
% Again, track05/track05_say_it_again_demo); the CRC and LDPC decoding (album 
% track 04 Every Check Agrees, track04/track04_every_check_agrees_demo).
% 
% • The noise EVM formula (album track 02 Copy the Tail, track02/track02_copy_the_tail_demo).
% 
% • OFDM modulation and the resource grid (track 00 Fundamentals, track00_fundamentals/p00a_ofdm_and_cp_demo).
% Words used in this demo
% • Waveform generator: one call that builds every channel and signal of 
% a downlink config into one waveform, and reports what it put where.
% 
% • Transport block (TB): the block of data bits handed to the shared channel 
% for one slot. TBS: its size in bits. RV: redundancy version. blkerr: the 
% decoder's flag that the CRC failed.
% 
% • Hardware order: the order in which the radio's parts touch the signal, 
% from the transmit mixer to the receive oscillator.
% 
% • Used resource elements: the grid positions the generator filled (here 
% the PDSCH and its DM-RS); EVM is measured on those only.
% 
% • Not covered in the album, named by the generator only: BWP (bandwidth 
% part, the block of RBs a phone is configured to use), CORESET (the region 
% where the PDCCH is sent), PDCCH (the downlink control channel that carries 
% scheduling grants).
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
% • + - * / and ^, .^ — Purpose: arithmetic and powers; .^ powers every entry 
% of a list. Inputs: numbers or lists. Outputs: the result.
% 
% • sqrt(x), sum(v), max(v) — Purpose: square root; the sum of a list; its 
% largest entry. Inputs: a number or a list. Outputs: a number.
% 
% • abs(x) and a < b, a <= b — Purpose: size of a number; test a comparison. 
% Inputs: numbers. Outputs: a number; true or false.
% 
% Commands you read in the given code
% • cfg = nrDLCarrierConfig(...), [wave, info] = nrWaveformGenerator(cfg) 
% — Used in B1; listed there.
% 
% • nrCarrierConfig, nrOFDMDemodulate — Purpose: a carrier that matches the 
% generator's grid, and the grid back from a waveform. Inputs: spacing (kHz), 
% RBs, cell ID; a carrier and a waveform (with Nfft and SampleRate). Outputs: 
% an object; a grid.
% 
% • iqimbal, comm.MemorylessNonlinearity, comm.PhaseNoise — the impairments 
% of album track 14, used in B2; listed there.
% 
% • nrPDSCHDecode, nrDLSCHDecoder — Used in B3; listed there.
% 
% • Figure family: figure(Name = ...), bar, yline, xticklabels, grid on, 
% xlabel, ylabel, title — Purpose: draw bars and label them. Inputs: data 
% and text. Outputs: a figure.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing, ranges, cells, and loops: x(k), x(:), x(end), a:b:c, c{k}, 
% for k = ... end, if ... end — Purpose: read or write entries, step through 
% values, repeat, choose. Inputs: arrays, cell arrays, ranges, tests. Outputs: 
% the entries or the repeated work.
% 
% • Compare and combine: == ~= < > <= >=, ~, &&, ||, any, all, isequal, iscell 
% — Purpose: compare values or whole arrays; not; and; or. Inputs: numbers 
% or arrays. Outputs: true/false.
% 
% • Built-in helpers: abs, angle, conj, exp, min, mean, numel, size, nnz, 
% zeros, round, double, logical, randn, isnan, NaN, reset — Purpose: 
% sizes, counts, complex helpers, random values, restarting a random object. 
% Inputs: numbers or arrays. Outputs: numbers or arrays (NaN means "no number 
% yet").
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
% Teaching draft built to the track01 r03 template (track15 r01, 2026-11-20) 
% from the live track15_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox and 
% the Communications Toolbox (iqimbal, comm.MemorylessNonlinearity, comm.PhaseNoise); 
% Staging stops with a message if the Communications Toolbox is missing. Simplifications, 
% all named in the beats: the channel is an identity (no nrCDLChannel), so 
% the receiver needs no timing estimate or channel estimate; the receiver 
% noise is a fixed Gaussian draw at a set SNR, standing in for comm.ThermalNoise; 
% the oscillator sits at the receiver; one transmit antenna, no panel mapping; 
% the SS burst and the PDCCH are switched off, so the grid holds the PDSCH 
% and its DM-RS only. Teaching demo, not production code; not affiliated with 
% or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year): the noise draw repeats on every run

% Stop early with a clear message if the Communications Toolbox is missing.
if isempty(ver('comm'))
    error('This track needs the Communications Toolbox (iqimbal, comm.MemorylessNonlinearity, comm.PhaseNoise). Install it, then run again.')
end

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
listText = @(v) strjoin(string(v(:).'), " ");

% EVM in percent, normalized by the reference power (album track 14).
evmPct = @(ref, rx) 100*sqrt(sum(abs(rx(:) - ref(:)).^2)/sum(abs(ref(:)).^2));
%% B1 — One config, one waveform
% New words
% • ResourceGridInCarrier: the grid the generator filled, before OFDM modulation. 
% WaveformResources: the generator's record of every resource it placed, 
% slot by slot.
% Beat-only commands
% • cfg = nrDLCarrierConfig(FrequencyRange = "FR1", ChannelBandwidth = 10, 
% NumSubframes = 10, WindowingPercent = 0) — a downlink config: FR1, 10 MHz, 
% 10 ms, no windowing. Its SSBurst, PDCCH, CSIRS, and PDSCH entries hold the 
% channels. 
% 
% • [wave, info] = nrWaveformGenerator(cfg) — the waveform, and a structure 
% info: info.ResourceGrids(1).ResourceGridInCarrier (the grid), info.ResourceGrids(1).Info 
% (Nfft, SampleRate, ...), and info.WaveformResources.PDSCH(1).Resources(s) 
% (per slot: ChannelIndices, DMRSIndices, TransportBlock, TransportBlockSize, 
% RV, ...).
% Why it matters
% A real stack starts from one config and one call. The generator already 
% places the shared channel, its DM-RS, and (if enabled) the sync burst and 
% the control channel, and it tells you what it placed. Before you build anything 
% on top of it, check two things: the waveform is as long as the config says, 
% and the grid holds exactly the resource elements the generator reports. 
% If either fails, every later number is built on sand. Here the sync burst 
% and the control channel are switched off, so the grid holds the PDSCH and 
% its DM-RS only.
% What to look for
% • In the waveform table: Nfft, the sample rate, the number of samples, 
% the grid size, and the used resource elements.
% 
% • In the resource table: the PDSCH and DM-RS counts the generator reports, 
% summed over the slots.
% Common mistakes
% Do not rebuild the grid by hand and then wonder why it disagrees with ResourceGridInCarrier: 
% the generator also places the DM-RS (and the sync burst and control channel 
% when they are on).
% 
% Do not treat cfg.PDSCH{1} as an nrPDSCHConfig: it is an nrWavegenPDSCHConfig, 
% with extra fields such as TargetCodeRate, SlotAllocation, and RNTI.
% Try it (personal exploration)
% Make the waveform 4 ms long instead of 10. Predict the number of samples. 
% Type it into myPrediction before you run this section; the one-row table 
% at the end generates it.

% Try it: type your prediction here (samples) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — One config, one waveform
fprintf("B1 — One config, one waveform\n");   % banner title only; every number below goes into a table

nSub = 10;                                 % subframes of 1 ms: a 10 ms frame
cfg = nrDLCarrierConfig(FrequencyRange = "FR1", ChannelBandwidth = 10, ...
    NumSubframes = nSub, WindowingPercent = 0);   % 10 MHz in FR1 (52 RB at 15 kHz); no windowing
cfg.SSBurst.Enable = false;                % no sync burst: the grid holds the PDSCH and its DM-RS only
cfg.PDCCH{1}.Enable = false;               % no control channel (on by default; it would share symbols with the PDSCH)
cfg.CSIRS{1}.Enable = false;               % no CSI-RS (off by default; set here so the grid is known)
[wave, info] = nrWaveformGenerator(cfg);
refGrid = info.ResourceGrids(1).ResourceGridInCarrier;   % subcarriers x symbols (x ports)
gi = info.ResourceGrids(1).Info;                          % Nfft, SampleRate, ...
pdschRes = info.WaveformResources.PDSCH(1).Resources;     % one entry per slot with a PDSCH

% What the generator says it placed: PDSCH data and DM-RS resource elements, summed over the slots.
nData = 0;
nDmrs = 0;
% Add the counts of every slot's resource entry.
for s = 1:numel(pdschRes)
    nData = nData + numel(pdschRes(s).ChannelIndices);
    nDmrs = nDmrs + numel(pdschRes(s).DMRSIndices);
end

% Two tests: the length matches the config, and the grid holds exactly what the generator reports.
nExpected = round(gi.SampleRate*nSub*1e-3);   % samples in nSub ms
okLength = size(wave, 1) == nExpected;
assert(okLength, ...
    'The waveform should be nSub ms of samples. Look first at the sample rate: it must come from info.ResourceGrids(1).Info, the numerology the waveform was made with.');
okOccupied = nnz(refGrid) == nData + nDmrs;
assert(okOccupied, ...
    'The grid should hold exactly the PDSCH and DM-RS elements. Look first at the other channels: the PDCCH (on by default) and the SS burst must be off, or they fill elements the PDSCH count does not include.');

b1Wave = table(gi.Nfft, gi.SampleRate/1e6, size(wave, 1), string(size(refGrid, 1)) + " x " + string(size(refGrid, 2)), nnz(refGrid), ...
    VariableNames = {'Nfft', 'SampleRate_MHz', 'Samples', 'GridSize', 'UsedREs'});
b1Wave

b1Res = table(numel(pdschRes), nData, nDmrs, pdschRes(1).TransportBlockSize, string(cfg.PDSCH{1}.Modulation), ...
    VariableNames = {'SlotsWithPDSCH', 'DataREs', 'DMRSREs', 'TBS_slot1_bits', 'Modulation'});
b1Res

% Try it: the same config, 4 subframes.
cfgTry = cfg;                              % a copy (configs are value objects)
cfgTry.NumSubframes = 4;                   % 4 ms
waveTry = nrWaveformGenerator(cfgTry);
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, size(waveTry, 1), predictionNote, ...
    VariableNames = {'MyPrediction', 'Samples_4ms', 'Note'});
b1Prediction
%%
% One config gave one 10 ms waveform at the sample rate of a 1024-point FFT, 
% and the grid holds exactly the PDSCH and DM-RS elements the generator reports. 
% The PDSCH fills every slot. Compare the 4 ms length with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["Waveform length"; "Used REs = PDSCH + DM-RS reported"], ...
    [string(nExpected) + " samples"; string(nData + nDmrs) + " REs"], ...
    [string(size(wave, 1)) + " samples"; string(nnz(refGrid)) + " REs"], ...
    [okLength; okOccupied], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep cfg, wave, refGrid, gi, and pdschRes: every later beat uses them.
clear b1Wave b1Res b1Checks b1Prediction predictionNote okLength okOccupied ...
      nSub info nData nDmrs s nExpected cfgTry waveTry myPrediction
%% B2 — Make the radio real, in hardware order
% New words
% • Stage: one impairment as a function from waveform to waveform. Drive: 
% the average power into the amplifier, in dBm.
% Beat-only commands
% • iqimbal(x, A, P); pa = comm.MemorylessNonlinearity(...); pnoise = comm.PhaseNoise(..., 
% RandomStream = "mt19937ar with seed", Seed = n) — the album track 14 impairments; 
% the phase noise here has its own seed, and reset(pnoise) starts it again.
% 
% • stages = {f1; f2; ...} and stages{k}(x) — a cell array of one-line functions, 
% and calling the k-th one on x.
% Why it matters
% Impairments are not a bag you sprinkle in any order. The transmit mixer 
% (IQ imbalance) comes first, then the transmit amplifier, then the channel, 
% then the receiver's own noise, then the receiver's oscillator. Each stage 
% is switchable, so the later beats can turn one on at a time with everything 
% else held fixed: the same noise draw and the same oscillator seed on every 
% run. The song starts with the transmit oscillator; this chain models the 
% receive one instead, at the end of the chain (E2 asks what that placement 
% changes).
% What to look for
% • In the stage table: the five stages in hardware order, what each does, 
% and its setting.
% 
% • In the power table: the generator's raw output power, beside the drive 
% the amplifier is set to.
% Common mistakes
% Do not put the receiver noise before the amplifier: the amplifier would 
% then treat noise as if it were signal, and a different radio is modelled.
% 
% Do not apply array steering weights to this single-port waveform as if 
% the toolbox had already mapped it onto a panel: it has not, and this demo 
% stays on one antenna.
% Try it (personal exploration)
% Swap the amplifier and the receiver noise (noise first) with only those 
% two stages on. Predict whether the EVM changes a lot or a little compared 
% with the hardware order, and type the EVM change in percentage points (swapped 
% minus hardware order) into myPrediction before you run this section; the 
% one-row table at the end measures both orders.

% Try it: type your prediction here (percentage points) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Make the radio real, in hardware order
fprintf("B2 — Make the radio real, in hardware order\n");   % banner title only; every number below goes into a table

fs = gi.SampleRate;           % sample rate, Hz
iqA = 0.5;                    % amplitude imbalance, dB (the album track 14 mixer)
iqP = 2;                      % phase imbalance, degrees
iip3 = 15;                    % amplifier input third-order intercept, dBm
driveDbm = -2;                % average drive into the amplifier, dBm (17 dB below the IIP3)
snrDb = 25;                   % receiver SNR, dB, relative to the clean waveform's average power
pnLevel = [-70 -110];         % receiver oscillator mask, dBc/Hz (the album track 14 oscillator)
pnOffset = [1e3 1e5];         % offsets for those levels, Hz
pnSeed = 15;                  % oscillator seed, so every run draws the same wander

rmsWave = sqrt(mean(abs(wave).^2));            % RMS of the clean waveform
gDrive = sqrt(10^((driveDbm - 30)/10))/rmsWave;   % amplitude scale that sets the drive (1 ohm), from the clean wave
noiseStd = rmsWave/sqrt(10^(snrDb/10));        % noise standard deviation per complex sample
noiseDraw = (randn(size(wave)) + 1j*randn(size(wave)))/sqrt(2);   % one fixed unit-power draw, reused on every run

pa = comm.MemorylessNonlinearity(Method = "Cubic polynomial", LinearGain = 0, ...
    IIP3 = iip3, AMPMConversion = 0);          % LinearGain in dB; AM/PM off, as in album track 14
pnoise = comm.PhaseNoise(Level = pnLevel, FrequencyOffset = pnOffset, SampleRate = fs, ...
    RandomStream = "mt19937ar with seed", Seed = pnSeed);

% The five stages, in hardware order. The amplifier scales up to the drive and back down,
% so the waveform keeps its level and only the distortion remains.
stageName = ["IQ imbalance (transmit mixer)"; "Amplifier (transmit)"; "Channel"; ...
             "Receiver noise"; "Phase noise (receiver oscillator)"];
stages = {@(x) iqimbal(x, iqA, iqP); ...
          @(x) pa(x*gDrive)/gDrive; ...
          @(x) x; ...
          @(x) x + noiseStd*noiseDraw; ...
          @(x) pnoise(x)};
stageSetting = ["A = " + iqA + " dB, P = " + iqP + " deg"; ...
                "IIP3 = " + iip3 + " dBm, drive = " + driveDbm + " dBm"; ...
                "identity (no nrCDLChannel in this demo)"; ...
                "SNR = " + snrDb + " dB, fixed draw"; ...
                "mask [" + listText(pnLevel) + "] dBc/Hz at [" + listText(pnOffset) + "] Hz, seed " + pnSeed];

b2Stages = table((1:5).', stageName, stageSetting, VariableNames = {'Order', 'Stage', 'Setting'});
b2Stages

% The generator's raw output power (1 ohm), for the record; gDrive scales it to driveDbm either way.
b2Power = table(round(10*log10(mean(abs(wave).^2)) + 30, 2), driveDbm, ...
    VariableNames = {'RawWave_dBm', 'Drive_dBm'});
b2Power

% A carrier that matches the generator's grid, for demodulation in every later beat.
scs = cfg.SCSCarriers{1};
carrier = nrCarrierConfig(SubcarrierSpacing = scs.SubcarrierSpacing, NSizeGrid = scs.NSizeGrid, ...
    NStartGrid = scs.NStartGrid, NCellID = cfg.NCellID);
demod = @(w) nrOFDMDemodulate(carrier, w, Nfft = gi.Nfft, SampleRate = fs, CyclicPrefixFraction = 1);
used = refGrid ~= 0;                           % the resource elements the generator filled
% One complex gain per OFDM symbol on the used elements: removes the common phase and the amplifier's average gain.
gainFix = @(rx) rx./(sum(conj(refGrid).*rx.*used, 1)./sum(abs(refGrid).^2.*used, 1));

% Try it: amplifier and noise only, in hardware order and swapped.
orders = {[2 4], [4 2]};                       % stage numbers, applied left to right
evmOrder = zeros(1, 2);
% Run each order once, applying its stages left to right.
for o = 1:2
    y = wave;
    % Apply the stages of this order one after the other.
    for s = orders{o}
        y = stages{s}(y);
    end
    rx = gainFix(demod(y));
    evmOrder(o) = evmPct(refGrid(used), rx(used));
end
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare your change with the measured one";
end
b2Prediction = table(round(evmOrder(1), 2), round(evmOrder(2), 2), myPrediction, round(evmOrder(2) - evmOrder(1), 2), predictionNote, ...
    VariableNames = {'HardwareOrder_percent', 'Swapped_percent', 'MyPrediction', 'MeasuredChange', 'Note'});
b2Prediction
%%
% The chain is five switchable stages in the order the radio has them. Nothing 
% is measured against a rule in this beat; B3 and B4 use the stages. Compare 
% the Try change with your prediction, and note that a small change in EVM 
% does not make the swapped order a model of the same radio.
%% B2 — Assertion checks

% B2 sets up the chain and has no asserts; the stage table above is its record.
disp('B2 has no asserts: B3 tests the chain with every stage off, and B4 with the stages on.')
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep the stages, the carrier, demod, used, and gainFix: B3 and B4 use them.
clear b2Stages b2Power b2Prediction predictionNote stageSetting scs orders evmOrder o y s rx myPrediction
%% B3 — The plumbing invariant: everything off, the bits come back
% New words
% • Plumbing invariant: a result that must hold exactly when nothing is impaired; 
% if it fails, the chain itself is wrong.
% Beat-only commands
% • cws = nrPDSCHDecode(sym, mod, nid, rnti, nVar) — PDSCH symbols to soft 
% bits (demapping and descrambling). Inputs: the received PDSCH symbols, the 
% modulation, the scrambling identity, the RNTI, and a noise variance. Outputs: 
% soft bits per codeword.
% 
% • dec = nrDLSCHDecoder; [bits, blkerr] = dec(soft, mod, nLayers, rv) — 
% rate recovery, LDPC decoding, and the CRC check. Set TargetCodeRate and 
% TransportBlockLength first. Outputs: the decoded bits and the CRC flag.
% Why it matters
% Before any impairment can be measured, the chain itself must be exact: 
% with every stage off, the receiver must return the very bits the generator 
% encoded. The generator records those bits in info.WaveformResources.PDSCH(1).Resources(s).TransportBlock, 
% so there is no need to rebuild a bit source by hand. This check runs on 
% every Run All with every stage off, whatever you change elsewhere.
% What to look for
% • In the decode table: the transport-block size, the CRC flag, and whether 
% the decoded bits equal the recorded ones.
% Common mistakes
% Do not compare the decoded bits with the grid symbols: the transport block 
% is information bits, before coding and modulation.
% 
% Do not decode with the wrong slot's indices: each Resources(s) entry belongs 
% to one slot, and its indices point into that slot's 14 symbols.
% Try it (personal exploration)
% Turn on only the receiver noise, at an SNR of −5 dB. Predict the CRC flag 
% (0 = passes, 1 = fails). Type it into myPrediction before you run this section; 
% the one-row table at the end decodes that waveform.

% Try it: type your prediction here (0 or 1) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — The plumbing invariant
fprintf("B3 — The plumbing invariant: everything off, the bits come back\n");   % banner title only; every number below goes into a table

res = pdschRes(1);                             % the first slot's PDSCH record
tb = res.TransportBlock;
if iscell(tb)
    tb = tb{1};                                % one codeword: take the first
end
pdschCfg = cfg.PDSCH{1};
nid = pdschCfg.NID;
if isempty(nid)
    nid = cfg.NCellID;                         % an empty NID means "use the cell ID"
end
nVarOff = 1e-12;                               % noise variance for the all-off decode: essentially none
slotSym = res.NSlot*14 + (1:14);               % this slot's 14 symbols in the 10 ms grid

% Two cases: everything off (the invariant), then the Try (noise only at -5 dB).
caseName = ["Everything off"; "Try: noise only, SNR -5 dB"];
caseWave = {wave, wave + rmsWave/sqrt(10^(-5/10))*noiseDraw};   % the Try uses the same noise draw, scaled
kAvg = nnz(used)/size(refGrid, 2);             % average used subcarriers per symbol
caseNVar = [nVarOff, kAvg/(gi.Nfft*10^(-5/10))];   % per-RE noise variance for the Try: Nfft x per-sample variance, relative to the average RE power (album track 02 rule)
rxBits = cell(2, 1);
blkerr = false(2, 1);
% Decode the first PDSCH slot of each case the same way.
for c = 1:2
    rxGrid = demod(caseWave{c});
    rxSlot = rxGrid(:, slotSym);
    soft = nrPDSCHDecode(rxSlot(res.ChannelIndices), pdschCfg.Modulation, nid, pdschCfg.RNTI, caseNVar(c));
    if iscell(soft)
        soft = soft{1};                        % one codeword
    end
    dec = nrDLSCHDecoder;                      % a fresh decoder per case: an empty soft buffer, so the cases do not combine
    dec.TargetCodeRate = pdschCfg.TargetCodeRate;
    dec.TransportBlockLength = res.TransportBlockSize;
    [rxBits{c}, blkerr(c)] = dec(soft, pdschCfg.Modulation, pdschCfg.NumLayers, res.RV);
end

% Three tests on the everything-off case: the record is one block of the size it says, the CRC passes, and the bits match.
okTb = numel(tb) == res.TransportBlockSize;
assert(okTb, ...
    'The recorded block should have TransportBlockSize bits. Look first at the resource: TransportBlock and TransportBlockSize must come from the same Resources(s) entry.');
okCrc = ~blkerr(1);
assert(okCrc, ...
    'With everything off the CRC should pass. Look first at the decoder settings: TargetCodeRate, TransportBlockLength, and the RV must be the generator''s, and the indices must be this slot''s.');
okBits = isequal(double(rxBits{1}(:)), double(tb(:)));
assert(okBits, ...
    'With everything off the bits should match the recorded TransportBlock. Look first at the slot: the indices, the RV, and the recorded block must all come from the same Resources(s) entry.');

b3Decode = table(caseName(1), res.NSlot, res.TransportBlockSize, logical(blkerr(1)), okBits, ...
    VariableNames = {'Case', 'Slot', 'TBS_bits', 'CRCFailed', 'BitsMatch'});
b3Decode

% Try it: the CRC flag with noise only at -5 dB.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(caseName(2), myPrediction, double(blkerr(2)), predictionNote, ...
    VariableNames = {'Case', 'MyPrediction', 'CRCFailed', 'Note'});
b3Prediction
%%
% With everything off, the decoder recovers the recorded transport block 
% bit for bit and the CRC passes: the plumbing is right, so anything that 
% changes later comes from the stages you switch on. Compare the Try flag 
% with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["Recorded block size"; "CRC passes, everything off"; "Bits equal the recorded block"], ...
    [string(res.TransportBlockSize) + " bits"; "blkerr = 0"; "all equal"], ...
    [string(numel(tb)) + " bits"; "blkerr = " + double(blkerr(1)); string(okBits)], ...
    [okTb; okCrc; okBits], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the decoder.
clear b3Decode b3Prediction b3Checks predictionNote okTb okCrc okBits ...
      res tb pdschCfg nid nVarOff slotSym dec caseName caseWave caseNVar rxBits blkerr c ...
      rxGrid rxSlot soft myPrediction kAvg
%% B4 — One change at a time, then all together
% New words
% • Single: a run with one stage on and the rest off. All-on: every stage 
% on at once.
% Beat-only commands
% None beyond the stages and helpers above.
% Why it matters
% With the plumbing proven, turn on one impairment, measure, turn it off, 
% and turn on the next, with the same noise draw and the same oscillator 
% seed every time. Each single gives that flaw's own EVM. If the flaws are 
% independent, the all-on EVM is the root-sum-square of the singles, as in 
% album track 14. The noise single can also be checked against the album 
% track 02 formula, using the average number of used subcarriers per symbol. 
% EVM is measured on the used elements after one complex gain per symbol 
% is removed, as a receiver's tracking would.
% What to look for
% • In the breakdown table: the EVM of each single, of all-on, and the rss 
% of the singles.
% 
% • In the figure: the singles as bars, and the rss and all-on as lines.
% Common mistakes
% Do not leave every stage on, see a large EVM, and guess which one did it: 
% switch them one at a time.
% 
% Do not reseed or redraw between runs: then the singles and the all-on are 
% not measured on the same noise and the same wander.
% Try it (personal exploration)
% Before running, predict the noise single, in percent, from the album track 
% 02 formula with SNR = 25 dB, N_FFT = 1024, and the average used subcarriers 
% per symbol (about 602 here). Type it into myPrediction; the one-row table 
% at the end shows the measured noise single.

% Try it: type your prediction here (percent) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — One change at a time, then all together
fprintf("B4 — One change at a time, then all together\n");   % banner title only; every number below goes into a table

rowName = ["IQ imbalance only"; "Amplifier only"; "Receiver noise only"; "Phase noise only"; "All on"];
onMask = logical([1 0 0 0 0; 0 1 0 0 0; 0 0 0 1 0; 0 0 0 0 1; 1 1 1 1 1]);   % rows: runs; columns: the five stages
evmRow = zeros(size(onMask, 1), 1);
% For each run: start from the clean wave, apply the stages that are on, in hardware order, and measure.
for r = 1:size(onMask, 1)
    reset(pnoise);                             % same oscillator wander on every run
    y = wave;
    % Apply the stages in hardware order, skipping the ones that are off.
    for s = 1:numel(stages)
        if onMask(r, s)
            y = stages{s}(y);
        end
    end
    rx = gainFix(demod(y));
    evmRow(r) = evmPct(refGrid(used), rx(used));
end
evmRss = sqrt(sum(evmRow(1:4).^2));            % rss of the four singles, percent
kAvg = nnz(used)/size(refGrid, 2);             % average used subcarriers per symbol
evmNoiseFormula = 100*sqrt(kAvg/(gi.Nfft*10^(snrDb/10)));   % album track 02 formula, percent

% Two tests: the noise single matches the formula, and all-on matches the rss of the singles.
okNoiseFormula = abs(evmRow(3) - evmNoiseFormula) < 0.05*evmNoiseFormula;
assert(okNoiseFormula, ...
    'The noise single should match the album track 02 formula. Look first at the scaling: noiseDraw must have unit power per complex sample (the /sqrt(2)), and noiseStd must come from the clean wave''s RMS; a 3 dB slip moves the single by a factor of about 1.4.');
okRss = abs(evmRow(5) - evmRss) < 0.2*evmRss;
assert(okRss, ...
    'All-on should land near the rss of the singles. Look first at gainFix: every run, the all-on included, must get the same per-symbol gain correction, or the amplifier gain and the common phase count as error.');

b4Breakdown = table([rowName; "rss of the four singles"; "Plain sum of the four singles"], ...
    round([evmRow; evmRss; sum(evmRow(1:4))], 3), VariableNames = {'Run', 'EVM_percent'});
b4Breakdown

figure(Name = "Track 15 — impairment breakdown");
bar(evmRow(1:4)); grid on;
yline(evmRss, '--', 'rss of singles');
yline(evmRow(5), '-', 'all on');
xticklabels(["IQ", "Amplifier", "Noise", "Phase noise"]);
ylabel('EVM (%)');
title('B4: one impairment at a time, then all together');

% Try it: your formula prediction beside the measured noise single.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, round(evmRow(3), 2), predictionNote, ...
    VariableNames = {'MyPrediction_percent', 'MeasuredNoise_percent', 'Note'});
b4Prediction
%%
% Each single shows one flaw's own cost; the noise is the largest here and 
% the oscillator the smallest. All-on lands close to the rss of the singles, 
% well below their plain sum, so these four pieces behave as independent 
% here. Compare the noise single with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["Noise single matches the album track 02 formula"; "All-on matches the rss of the singles"], ...
    [string(round(evmNoiseFormula, 3)) + " percent (within 5 percent of it)"; string(round(evmRss, 3)) + " percent (within 20 percent of it)"], ...
    [string(round(evmRow(3), 3)) + " percent"; string(round(evmRow(5), 3)) + " percent"], ...
    [okNoiseFormula; okRss], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the chain; keep listText for the Build it checks.
clear b4Breakdown b4Prediction b4Checks predictionNote okNoiseFormula okRss ...
      rowName onMask evmRow r y s rx evmRss kAvg evmNoiseFormula myPrediction ...
      cfg wave refGrid gi pdschRes fs iqA iqP iip3 driveDbm snrDb pnLevel pnOffset pnSeed ...
      rmsWave gDrive noiseStd noiseDraw pa pnoise stageName stages carrier demod used gainFix
%% Build it — Read an impairment breakdown
% Competency: from the EVM of each impairment alone and of all of them together, 
% compute the root-sum-square and the plain sum, decide whether the pieces 
% are independent, and work out what removing the largest piece would buy.
% Problem
% A colleague's breakdown table shows these singles: IQ imbalance 2.0 %, 
% amplifier 3.5 %, receiver noise 4.4 %, phase noise 1.0 %, and 6.1 % with 
% all four on. Work out the rss of the singles and their plain sum, the ratio 
% of the all-on to the rss, and whether the pieces behave as independent (the 
% ratio within 10 % of 1). Then work out the rss if the largest piece were 
% removed completely, and whether that would meet the 256QAM limit of 3.5 %.
% Allowed commands
% x = value and [a b c]; + - * / and ^, .^; sqrt(x), sum(v), max(v); abs(x) 
% and a < b, a <= b. The tables in the check sections and Stage 5 are given. 
% All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myEvm = [2.0 3.5 4.4 1.0];   % singles: IQ, amplifier, noise, phase noise, percent
% myAllOn = 6.1;               % all four on, percent
% myLimit256 = 3.5;            % 38.104 limit for 256QAM, percent
%% Stage 1 check (given)
if ~exist('myEvm','var') || ~exist('myAllOn','var') || ~exist('myLimit256','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal(myEvm, [2.0 3.5 4.4 1.0]) && myAllOn == 6.1 && myLimit256 == 3.5;
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the three lines you uncommented: [2.0 3.5 4.4 1.0], 6.1, and 3.5.')
    stage1Checks = table("Given values", "2 3.5 4.4 1, 6.1, 3.5", ...
        listText([myEvm myAllOn myLimit256]), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the rss of the singles
% Fill the blank: square every single, add, and take the root.
% Pass: Stage 2 OK.

% myRss = sqrt(sum(___.^2));
%% Stage 2 check (given; the check adds one squared single at a time in a loop, a different route from yours)
if ~exist('myRss','var')
    disp('Stage 2 not done: fill the blank, uncomment, and run.')
else
    % Different route: add the squares one at a time.
    given = [2.0 3.5 4.4 1.0];                 % the singles from the problem, percent
    sumSq = 0;
    % Add the square of each single in turn.
    for k = 1:numel(given)
        sumSq = sumSq + given(k)^2;
    end
    rssOracle = sqrt(sumSq);                   % percent
    okStage2 = abs(myRss - rssOracle) < 1e-9;
    assert(okStage2, ...
        'myRss is off. Common mistake: squaring the sum instead of summing the squares; the power goes on each single.')
    stage2Checks = table("rss of the singles", string(round(rssOracle, 3)) + " percent", ...
        string(round(myRss, 3)) + " percent", okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then the plain sum and the ratio
% Predict first: will the all-on be close to the rss, or close to the plain 
% sum? Type 1 for the rss or 2 for the plain sum into myPrediction. Then fill 
% the blanks: the plain sum of the singles, and the all-on over the rss.
% Pass: Stage 3 OK.

% myPrediction = ___;
% myLinear = ___(myEvm);
% myRatio = myAllOn/___;
%% Stage 3 check (given; the check adds the singles in a loop and divides, a different route from yours)
if ~exist('myLinear','var') || ~exist('myRatio','var')
    disp('Stage 3 not done: fill the blanks, uncomment, and run.')
else
    % Different route: add the singles one at a time.
    linOracle = 0;
    % Add each single in turn.
    for k = 1:numel(given)
        linOracle = linOracle + given(k);
    end
    ratioOracle = 6.1/rssOracle;               % all-on over the rss
    okStage3 = [abs(myLinear - linOracle) < 1e-9; abs(myRatio - ratioOracle) < 1e-9];
    assert(okStage3(1), ...
        'myLinear is off. Look first at the input: the plain sum is over the four singles, without the all-on.')
    assert(okStage3(2), ...
        'myRatio is off. Look first at the order: the all-on goes on top, so a ratio above 1 means the total is bigger than the rss.')
    if ~exist('myPrediction','var')
        myPrediction = NaN;   % no prediction line was uncommented
    end
    if isnan(myPrediction)
        predictionNote = "No prediction typed";
    else
        predictionNote = "1 = near the rss, 2 = near the plain sum";
    end
    stage3Prediction = table(myPrediction, predictionNote, VariableNames = {'MyPrediction', 'Note'});
    stage3Prediction
    stage3Checks = table(["Plain sum of the singles"; "All-on over rss"], ...
        [string(round(linOracle, 3)) + " percent"; string(round(ratioOracle, 4))], ...
        [string(round(myLinear, 3)) + " percent"; string(round(myRatio, 4))], ...
        okStage3, VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — the verdict, and the largest piece removed
% Fill the blanks: whether the ratio is within 10 % of 1, the rss with the 
% largest single removed (take its square out of the sum of squares), and 
% whether that meets the 256QAM limit.
% Pass: Stage 4 OK.

% myIndependent = abs(myRatio - 1) < ___;
% myWithout = sqrt(myRss^2 - ___(myEvm)^2);
% myMeets256 = myWithout <= ___;
%% Stage 4 check (given; the check finds the largest single in a loop and rebuilds the rss without it, a different route from yours)
if ~exist('myIndependent','var') || ~exist('myWithout','var') || ~exist('myMeets256','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: find the largest single, then add the squares of the others.
    kBig = 1;
    % Keep the index of the largest single seen so far.
    for k = 2:numel(given)
        if given(k) > given(kBig)
            kBig = k;
        end
    end
    sumSqOthers = 0;
    % Add the squares of every single except the largest.
    for k = 1:numel(given)
        if k ~= kBig
            sumSqOthers = sumSqOthers + given(k)^2;
        end
    end
    withoutOracle = sqrt(sumSqOthers);         % percent
    okStage4 = [isequal(logical(myIndependent), abs(ratioOracle - 1) < 0.1); ...
                abs(myWithout - withoutOracle) < 1e-9; ...
                isequal(logical(myMeets256), withoutOracle <= 3.5)];
    assert(okStage4(1), ...
        'myIndependent is off. Look first at the units of the tolerance: the ratio is a plain number, with no percent in it.')
    assert(okStage4(2), ...
        'myWithout is off. Look first at what is taken out: the square of the largest single, from the square of the rss, before the root.')
    assert(okStage4(3), ...
        'myMeets256 is off. Look first at which limit: this verdict is for 256QAM, and meeting it includes being equal to it.')
    stage4Checks = table(["Pieces behave as independent"; "rss without the largest single"; "Meets the 256QAM limit"], ...
        [string(abs(ratioOracle - 1) < 0.1); string(round(withoutOracle, 3)) + " percent"; string(withoutOracle <= 3.5)], ...
        [string(logical(myIndependent)); string(round(myWithout, 3)) + " percent"; string(logical(myMeets256))], ...
        okStage4, VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myRss','var') || ~exist('myLinear','var') || ~exist('myRatio','var') || ~exist('myWithout','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myRss > max(myEvm); ...
        myLinear > myRss; ...
        myWithout < myRss; ...
        myAllOn < myLinear];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["rss above the largest single"; "Plain sum above the rss"; ...
         "Removing a piece lowers the rss"; "All-on below the plain sum"], ...
        ["> " + string(max(myEvm)) + " percent"; "> " + string(round(myRss, 3)) + " percent"; ...
         "< " + string(round(myRss, 3)) + " percent"; "< " + string(round(myLinear, 3)) + " percent"], ...
        [string(round(myRss, 3)) + " percent"; string(round(myLinear, 3)) + " percent"; ...
         string(round(myWithout, 3)) + " percent"; string(myAllOn) + " percent"], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    figure(Name = "Track 15 — breakdown read");
    bar([myEvm myRss myAllOn]); grid on;
    yline(myLimit256, '--', '256QAM limit');
    xticklabels(["IQ", "Amplifier", "Noise", "Phase noise", "rss", "All on"]);
    ylabel('EVM (%)');
    title('Build it: the singles, their rss, and the measured all-on');
end
%%
% Your interpretation (write one or two sentences here): do these pieces 
% behave as independent, and which one would you fix first if the link had 
% to carry 256QAM?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks given sumSq k rssOracle okStage2 stage2Checks ...
      linOracle ratioOracle okStage3 stage3Checks stage3Prediction predictionNote ...
      kBig sumSqOthers withoutOracle okStage4 stage4Checks buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B1)
% A 20 MHz carrier at 30 kHz (51 RB, 1024-point FFT) replaces B1's carrier. 
% How many samples is one slot now, how many slots are in 10 ms, and how does 
% the 10 ms total compare with B1's? Explain why the FFT size is 1024 here, 
% as it was in B1.
% 
% Your answer:
% E2 — Explanation (B2)
% B2 put the receiver's oscillator after the receiver noise. Why does that 
% oscillator act on the noise as well as the signal? If you moved it before 
% the noise stage, what would change in B4's phase-noise single, and what 
% in the all-on run? Explain both.
% 
% Your answer:
% E3 — Diagnosis (B3)
% A classmate checks the plumbing by comparing the decoded bits with randi([0 
% 1], TBS, 1). The CRC flag says 0, but about half the bits disagree. What 
% went wrong, and why does the CRC flag still say the block is fine?
% 
% Your answer:
% E4 — New values (B4)
% A link uses 600 subcarriers per symbol on average with a 1024-point FFT. 
% What noise EVM does the album track 02 formula give at 30 dB and at 20 dB? 
% If the IQ image alone costs 3.37 %, what is the lowest SNR, in dB, that 
% keeps the total of the two within the 64QAM limit of 8 %?
% 
% Your answer:
% E5 — Diagnosis (B4)
% A breakdown at another setting gives an all-on EVM 1.45 times the rss of 
% the singles, so two pieces are not independent. The noise draw and the 
% oscillator seed were fixed, and every run got the same gain correction. 
% Name one cause in B2's order (not the noise), and one run that separates 
% it from the others, with the result you would expect.
% 
% Your answer:
% E6 — Explanation (Key ideas)
% This demo kept the channel an identity and skipped the timing and channel 
% estimates. Suppose you add an nrCDLChannel with a delay spread but keep 
% the receiver as it is. Say what would go wrong in the B3 check and which 
% receive step fixes each problem.
% 
% Your answer:
%% Recap — End to End (album track 15)
% One config and one call give the whole downlink waveform, and the generator 
% records what it placed and the bits it sent. The impairments go in where 
% the hardware puts them, each one switchable. With everything off, the chain 
% must return the exact bits; with one flaw at a time, each shows its own 
% cost; all together, independent flaws add in power.
% Key relationships
% $$N_{\mathrm{samples}} = f_s \cdot N \cdot 1\ \mathrm{ms},\qquad \mathrm{EVM_{noise}} 
% \approx 100\sqrt{\frac{\bar K}{N_{\mathrm{FFT}}\cdot\mathrm{SNR}}}\ \%,\qquad 
% \mathrm{EVM_{total}} \approx \sqrt{\textstyle\sum_i \mathrm{EVM}_i^2}$$
% What this means in practice
% • Check the waveform and the grid against the generator's own record before 
% building on them.
% 
% • Prove the plumbing first: everything off, the bits come back.
% 
% • Change one thing at a time with the seeds fixed, then compare all-on with 
% the rss.
% 
% • You read a breakdown: the rss, the plain sum, independence, and what 
% removing the largest piece buys.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 14 (track14/track14_mirror_image_demo), where does an IQ-imbalance 
% image appear, and how far below the wanted signal?
% The album, end to end
% • 01 Two to the Mu: numerology sets the spacing, the slot, and the grid.
% 
% • 02 Copy the Tail: the cyclic prefix gives one tap per tone; EVM measures 
% what is left.
% 
% • 03 Find Me in the Noise: the SS/PBCH block lets a phone find and name 
% the cell.
% 
% • 04 Every Check Agrees: LDPC and the CRC protect each block.
% 
% • 05 Say It Again: transport blocks, MCS, HARQ, and the DM-RS.
% 
% • 06 Taps in Time: TDL channels give delays and Doppler.
% 
% • 07 Learn the Channel: pilots estimate the channel; the equalizer undoes 
% it.
% 
% • 08 Clusters and Angles: CDL channels add angles, arrays, and polarization.
% 
% • 09 Steer the Beam: steering vectors and array gain.
% 
% • 10 Sound It Out: SRS and CSI-RS sound the channel; reciprocity needs 
% calibration.
% 
% • 11 One in Ten: one link loop, BLER waterfalls, and the CQI target.
% 
% • 12 How Far: positioning from timing.
% 
% • 13 Signals from Orbit: round trips and Doppler from a satellite.
% 
% • 14 Mirror Image: phase noise, IQ imbalance, the amplifier, and the EVM 
% budget.
% 
% • 15 End to End: all of it in one chain. This is the last track of the 
% album.
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
% • + - * / and ^, .^:
% 
% • sqrt(x), sum(v), max(v):
% 
% • abs(x) and a < b, a <= b:
% What I missed, and where to reread it
% 
