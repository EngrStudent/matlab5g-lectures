%% P00b — Map of the Link: Soft Bits and Channel Dynamics
%% Confidence in every bit, and how fast the channel moves
% A receiver does not have to decide 0 or 1 straight away. A soft decision keeps 
% a guess and a confidence for each bit, and the decoder uses both.
% 
% The channel itself moves. Motion sets how long a channel estimate stays useful, 
% distance sets how early the phone must transmit, and the duplex mode decides 
% whether the channel measured one way can be used the other way.
%% Guiding question
% How sure is the receiver about each bit, and how long does what it learned 
% about the channel stay true?
% This demonstration
% 1. B3 — Compute one LLR by hand, then convert 400 noisy BPSK samples into 
% LLRs and see that soft information is a spread of confidences, not just 0 and 
% 1.
% 
% 2. B4 — Compute Doppler, coherence time, and coherent slots for a moving phone, 
% coherence bandwidth for a delay spread, timing advance for a distance, and compare 
% TDD with FDD.
% Key relationships
% The LLR is the log of the two likelihoods. For BPSK in Gaussian noise, with
% bit 0 sent as +1, that ratio simplifies to the shortcut 2y/σ²:
%
% $$\mathrm{LLR}=\log\frac{P(y\mid b=0)}{P(y\mid b=1)}=\frac{2y}{\sigma^2}$$
%
% Motion and distance set the time scales:
%
% $$f_D=\frac{v f_c}{c},\qquad T_c\approx\frac{0.423}{f_D},\qquad \mathrm{TA}=\frac{2d}{c}$$
%% Prerequisites
% • BPSK and QPSK mapping (P00a), and the idea of Gaussian noise
% 
% • The slot as a unit of time (a 30 kHz slot lasts 0.5 ms)
% 
% Words used in this demo
% • BPSK: the simplest modulation; bit 0 is sent as +1 and bit 1 as −1.
% 
% • Noise: random disturbance added to the signal on the way. Gaussian noise: 
% noise whose values follow the bell-shaped curve. Noise variance (σ²): how 
% spread out the noise is.
% 
% • Received value (y): the number the receiver actually measures.
% 
% • Hard decision: choosing 0 or 1 and keeping nothing else. Soft decision: 
% keeping a guess and how sure it is.
% 
% • Probability: how likely something is, from 0 (never) to 1 (certain). log: 
% the natural logarithm, a built-in function that turns ratios into sums.
% 
% • LLR (log-likelihood ratio): log of (chance the bit is 0) / (chance it is 
% 1). Its sign is the guess; its size is the confidence.
% 
% • BER (bit error rate): the share of bits decided wrongly. Decoder: the part 
% of the receiver that uses the code to fix errors.
% 
% • Carrier frequency (f_c): the centre radio frequency; GHz = a thousand million 
% cycles per second. Wavelength (λ): the length of one radio wave in metres.
% 
% • Doppler shift (f_D): how much motion shifts the received frequency.
% 
% • Coherence time (T_c): roughly how long the channel stays the same. Channel 
% estimate: the receiver's latest picture of the channel.
% 
% • Delay spread: how long the echoes keep arriving. Coherence bandwidth: the 
% frequency span over which the channel looks flat.
% 
% • Timing advance (TA): how early the phone transmits so its signal arrives 
% on time.
% 
% • TDD and FDD: sharing one carrier by taking turns, or using two carriers at 
% once. Reciprocity: using a channel measured one way for the other way.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write
% yourself get their own entry; small helpers are grouped into families.
%
% Commands you write
% • * / and .* ./ — Purpose: multiply and divide, on one value or element by
% element on a list. Inputs: two numbers or lists. Outputs: a number or a list.
%
% • exp and log — Purpose: exponential and natural logarithm, used in the
% likelihood-ratio check. Inputs: a number or list. Outputs: a number or list.
%
% • abs(x) — Purpose: the size of a value, dropping its sign. Inputs: a number
% or list. Outputs: a non-negative number or list.
%
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start a
% comment; start a section.
%
% • randn, randi, mean, numel, table, isnan — Purpose: the usual helpers in the
% given cells.
%
% Scope: no 5G Toolbox objects are used. Album tracks that build on this: 04 —
% LDPC decoding with soft bits; 06 — Doppler and channel time variation; 07 —
% equalization and decoder LLRs; 09 — CSI and beamforming; 10 — TDD/FDD
% reciprocity and reference signals.
%% Staging for script

% Clear the workspace and close figures so every run starts from the same state.
clear; close all;
% Fix the random seed so the noisy BPSK experiment is reproducible.
rng(2026);

%% B3 — Soft Bits and Log-Likelihood Ratios
% New words
% • Hard / soft decision: keep only 0 or 1, or keep a guess plus how sure it is.
% 
% • LLR: log of (chance the bit is 0) / (chance it is 1).
% 
% • Noise variance (σ²): how spread out the noise is.
% Why it matters
% A hard decision gives only a bit value: 0 or 1. A soft decision gives a bit 
% estimate and a measure of confidence. A decoder such as LDPC can then trust 
% confident bits and lean on the code to fix doubtful ones.
% 
% The log-likelihood ratio, or LLR, is the log of the two likelihoods: how
% well "bit 0 was sent" explains the received value, versus "bit 1 was sent".
% Its sign is the guess: positive favours bit 0, negative favours bit 1. Its
% size is the confidence: large means sure, near zero means unsure. For BPSK in
% Gaussian noise, with bit 0 sent as +1 and bit 1 as −1, that ratio simplifies
% to the shortcut
%
% $$x=1-2b,\qquad \mathrm{LLR}=\frac{2y}{\sigma^2}$$
% 
% So the LLR grows with how far the received value y sits from zero, and shrinks 
% as the noise variance σ² grows.
% What to look for
% • In the worked table, check the LLR row against 2 × y / σ² using the two 
% input rows above it, and read the hard decision from the sign.
% 
% • In the experiment table, compare the hard-decision BER with the mean |LLR|: 
% the BER counts only wrong signs, while |LLR| shows how confident the decisions 
% were.
% 
% • In the figure, look at the overlap of the two histograms near LLR = 0: that 
% is where the receiver is unsure. In the lower panel, check that LLR is a straight 
% line in y when σ² is fixed.
% Common mistakes
% Do not treat an LLR as a hard bit written as a different number. Its sign 
% gives the hard decision, but its magnitude carries the reliability that the 
% decoder needs.
% 
% Do not flip the sign convention. Here a positive LLR means bit 0, because 
% bit 0 is sent as +1.
% Try it (personal exploration)
% Run this section once as it stands and read the worked table. Then set 
% receivedValue = 0.8, keep noiseVariance = 0.5, use LLR = 2y/σ² to predict 
% the new LLR, and type it into myPrediction in the first code line below before 
% you run again. A given table just after the LLR is computed shows your
% prediction beside the result. Also decide, before running, whether the
% decision becomes more or less confident than the default y = 0.4 case, and
% type +1 into myPredictionConf for more confident or -1 for less.
%
% Every check in this section holds for any received value. The one check that
% compares with the narrated number is skipped, with a printed note, when you
% change the example, so the run does not stop. Put receivedValue back to 0.4
% when you are done.

% Try it: type your predictions here before running this section.
myPrediction = NaN;
myPredictionConf = NaN;   % +1 more confident than y = 0.4, -1 less
% Worked LLR calculation


% The narration's worked example uses a received BPSK value of 0.4 and a
% Gaussian-noise variance of 0.5.
receivedValue = 0.4;
noiseVariance = 0.5;

% For BPSK in Gaussian noise, the LLR is twice the received value divided
% by the noise variance.
llrWorked = 2 * receivedValue / noiseVariance;

% Compare your Try-it prediction with the result, side by side, before any check runs.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run it again.')
else
    predCompare = table(myPrediction, llrWorked, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
if isnan(myPredictionConf)
    disp('No confidence call recorded: type +1 or -1 into myPredictionConf at the top of this section and run this section again.')
else
    defaultAbsLLR = abs(2 * 0.4 / noiseVariance);
    confCompare = table(myPredictionConf, sign(abs(llrWorked) - defaultAbsLLR), ...
        VariableNames = {'YouPredicted','Result'});
    confCompare
end

% The LLR sign supplies the hard decision. In this convention, a negative
% value means bit 1; therefore, a positive value means bit 0.
estimatedBit = double(llrWorked < 0);

% The magnitude is the receiver's confidence measure.
llrConfidence = abs(llrWorked);

% Independent route: the log of the ratio of the two Gaussian likelihoods
% must give the same number as the 2y/sigma^2 shortcut, for any y.
likelihoodRatio = exp(-(receivedValue - 1)^2 / (2*noiseVariance)) / ...
    exp(-(receivedValue + 1)^2 / (2*noiseVariance));
checkWorkedLLR = abs(llrWorked - log(likelihoodRatio)) < 1e-12;

% The decision must follow the side of zero that y itself is on: bit 1 is
% sent as -1, so a negative y means bit 1. This holds for any y.
checkWorkedDecision = estimatedBit == double(receivedValue < 0);

assert(checkWorkedLLR, ...
    'The LLR does not match the log of the likelihood ratio. Look first at the 2 and the noiseVariance in the llrWorked line. Common mistake: dropping the factor of 2.');

assert(checkWorkedDecision, ...
    'The decision is on the wrong side of zero. Look first at the < 0 test in estimatedBit. Common mistake: flipping the sign convention.');

% isDefaultExample is true only for the narrated numbers. The check against
% the narrated value runs only then; otherwise it is skipped with a note.
isDefaultExample = receivedValue == 0.4 && noiseVariance == 0.5;
if isDefaultExample
    checkNarratedLLR = abs(llrWorked - (2*0.4/0.5)) < 1e-12;
    assert(checkNarratedLLR, ...
        'The default example does not give the narrated LLR. Look first at the llrWorked line. Common mistake: dropping the factor of 2.');
else
    checkNarratedLLR = NaN;   % NaN marks "skipped" in the verification table
    disp('Default-only check skipped: the narrated-value check is written for y = 0.4 and noise variance 0.5.')
end

% Display the worked calculation as a compact table.
llrQuantity = [ ...
    "Received value, y"; ...
    "Noise variance, σ²"; ...
    "LLR = 2y / σ²"; ...
    "Hard decision"; ...
    "Confidence, |LLR|"];

llrValue = [ ...
    string(sprintf('%.1f', receivedValue)); ...
    string(sprintf('%.1f', noiseVariance)); ...
    string(sprintf('%.1f', llrWorked)); ...
    string(sprintf('bit %d', estimatedBit)); ...
    string(sprintf('%.1f', llrConfidence))];

llrWorkedResults = table( ...
    llrQuantity, ...
    llrValue, ...
    VariableNames = {'Quantity','Value'});

llrWorkedResults
%% B3 — After the worked example
% Read the sign of the LLR for the guess, and its size for the confidence.
% Compare that size with how close y sits to zero, and with the default y = 0.4
% case if you changed the received value.
%% B3 — Noisy BPSK experiment
% The worked calculation above uses one received value. This experiment
% creates many BPSK transmissions and shows that noise produces a range of
% LLR confidence values.

% Generate a short random bit sequence for the visual experiment.
nBits = 400;
transmittedBits = randi([0 1], nBits, 1);

% BPSK maps bit 0 to +1 and bit 1 to -1.
transmittedBPSK = 1 - 2*transmittedBits;

% This variance controls the spread of the received BPSK points.
experimentNoiseVariance = 0.5;
noiseSamples = sqrt(experimentNoiseVariance) * randn(nBits,1);

% The received values are transmitted BPSK symbols plus Gaussian noise.
receivedBPSK = transmittedBPSK + noiseSamples;

% Convert each received value into an LLR. A decoder would receive these
% LLRs rather than the hard decisions below.
% Likelihood-ratio route (the Gaussian shortcut 2y/σ² is what you will build
% in the Build it section, by a different path).
likelyZero = exp(-(receivedBPSK - 1).^2 / (2*experimentNoiseVariance));
likelyOne = exp(-(receivedBPSK + 1).^2 / (2*experimentNoiseVariance));
llrValues = log(likelyZero ./ likelyOne);

% Hard decisions are included only to count ordinary decision errors.
hardDecisions = double(llrValues < 0);
hardDecisionErrors = sum(hardDecisions ~= transmittedBits);
hardDecisionBER = hardDecisionErrors / nBits;

% A soft-information vector should contain more than two distinct values.
checkSoftRange = numel(unique(round(llrValues,4))) > 2;

assert(checkSoftRange, ...
    'Soft information should contain more than two distinct LLR values. Look first at llrValues: it must use receivedBPSK, not the hard decisions.');

bpskQuantity = [ ...
    "BPSK symbols simulated"; ...
    "Noise variance"; ...
    "Hard-decision errors"; ...
    "Hard-decision BER"; ...
    "Mean |LLR|"];

bpskValue = [ ...
    string(nBits); ...
    string(sprintf('%.2f', experimentNoiseVariance)); ...
    string(hardDecisionErrors); ...
    string(sprintf('%.3f', hardDecisionBER)); ...
    string(sprintf('%.2f', mean(abs(llrValues))))];

bpskResults = table( ...
    bpskQuantity, ...
    bpskValue, ...
    VariableNames = {'Quantity','Value'});

bpskResults
%% B3 — After the experiment
% Some received values land on the wrong side of zero, so the hard decisions
% make a few errors. The LLRs are many different values, not two: each one
% tells the decoder how much to trust that bit, which a hard 0 or 1 throws away.
%% B3 — Verification results

% The assertions stop execution if the stated LLR relationships fail. This
% table makes the successful checks visible in a Live Script.

checkPassed = [ ...
    checkWorkedLLR; ...
    checkNarratedLLR; ...
    checkWorkedDecision; ...
    checkSoftRange];

% Pass, Fail, or Skipped, all computed from the flags (NaN means skipped).
resultText = repmat("Pass", numel(checkPassed), 1);
resultText(checkPassed == 0) = "Fail";
resultText(isnan(checkPassed)) = "Skipped (default-only)";

llrCheckName = [ ...
    "Worked LLR"; ...
    "Narrated worked value"; ...
    "LLR sign convention"; ...
    "Soft-information range"];

llrExpected = [ ...
    "2y / sigma^2 = log of the likelihood ratio"; ...
    "default y and σ² give the narrated LLR (default only)"; ...
    "Decision follows the sign of y"; ...
    "LLRs are continuous confidence values"];

llrChecks = table( ...
    llrCheckName, ...
    llrExpected, ...
    resultText, ...
    VariableNames = {'Check','Expected','Pass'});

llrChecks

%% B3 — Soft-bit figure

% The top panel compares LLR distributions for sent bits 0 and 1. The
% overlap near zero represents uncertain received values.
%
% The lower panel makes the formula visible: LLR is proportional to y when
% the noise variance is held fixed.

figure( ...
    Name = 'P00b - LLRs are soft decisions', ...
    Color = 'w', ...
    Units = 'pixels', ...
    Position = [100 80 900 900]);

tl = tiledlayout(2,1, ...
    TileSpacing = 'compact', ...
    Padding = 'loose');

title(tl, { ...
    'Soft Bits: LLR Sign Gives the Guess', ...
    'LLR Magnitude Gives the Confidence'}, ...
    FontWeight = 'bold', ...
    FontSize = 15);

% Top panel — LLR distributions
axLLRHistogram = nexttile;

histogram(axLLRHistogram, llrValues(transmittedBits == 0), 30, ...
    FaceColor = [0.20 0.40 0.80], ...
    FaceAlpha = 0.65, ...
    EdgeColor = 'none', ...
    DisplayName = 'sent bit 0');

hold(axLLRHistogram, 'on');

histogram(axLLRHistogram, llrValues(transmittedBits == 1), 30, ...
    FaceColor = [0.90 0.30 0.10], ...
    FaceAlpha = 0.65, ...
    EdgeColor = 'none', ...
    DisplayName = 'sent bit 1');

% LLR = 0 is the hard-decision boundary.
xline(axLLRHistogram, 0, '--k', ...
    LineWidth = 1.0, ...
    HandleVisibility = 'off');

grid(axLLRHistogram, 'on');
box(axLLRHistogram, 'on');

xlabel(axLLRHistogram, 'LLR');
ylabel(axLLRHistogram, 'Count');

title(axLLRHistogram, ...
    'Values near zero are uncertain; large magnitudes are confident');

legend(axLLRHistogram, Location='northwest');

% Bottom panel — received BPSK values and their LLRs
axLLRScatter = nexttile;

scatter(axLLRScatter, receivedBPSK, llrValues, 18, transmittedBits, ...
    'filled');

grid(axLLRScatter, 'on');
box(axLLRScatter, 'on');

xlabel(axLLRScatter, 'Received BPSK value, y');
ylabel(axLLRScatter, 'LLR');

title(axLLRScatter, ...
    'For fixed noise variance, LLR scales linearly with the received value');

colormap(axLLRScatter, [ ...
    0.20 0.40 0.80; ... % sent bit 0
    0.90 0.30 0.10]);   % sent bit 1

clim(axLLRScatter, [0 1]);

cbLLR = colorbar(axLLRScatter);
cbLLR.Ticks = [0 1];
cbLLR.TickLabels = {'sent bit 0','sent bit 1'};

%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.
% B4 does not need B3 variables. The figure and displayed tables remain
% visible after local calculation variables are cleared.

clear llrWorkedResults bpskResults llrChecks ...
      receivedValue noiseVariance llrWorked estimatedBit llrConfidence ...
      nBits transmittedBits transmittedBPSK experimentNoiseVariance ...
      noiseSamples receivedBPSK llrValues hardDecisions ...
      hardDecisionErrors hardDecisionBER ...
      llrQuantity llrValue bpskQuantity bpskValue ...
      checkWorkedLLR checkWorkedDecision checkSoftRange ...
      checkNarratedLLR isDefaultExample ...
      checkPassed resultText llrCheckName llrExpected ...
      axLLRHistogram axLLRScatter cbLLR tl likelihoodRatio myPrediction myPredictionConf predCompare confCompare defaultAbsLLR likelyZero likelyOne

%% B4 — Time, Distance, Motion, and Duplexing
% New words
% • Doppler shift: how much motion shifts the received frequency.
% 
% • Coherence time: roughly how long the channel stays the same.
% 
% • Timing advance: how early the phone transmits so it arrives on time.
% Why it matters
% Wireless channels change as the transmitter, receiver, or nearby objects 
% move. Doppler shift describes the fastest change caused by motion:
% 
% $$f_D=\frac{v f_c}{c}=\frac{v}{\lambda}$$
% 
% A useful coherence-time convention is:
% 
% $$T_c\approx\frac{0.423}{f_D}$$
% 
% Coherence time is roughly how long the channel stays similar enough for an 
% earlier channel estimate to remain useful. Comparing it with the slot length 
% says how often the receiver must re-estimate.
% 
% Coherence bandwidth previews the delay-spread side, using the convention
% 
% $$B_c\approx\frac{1}{5\,\tau_{\mathrm{rms}}}$$
% 
% Timing advance makes the phone transmit early by the round-trip delay, so 
% its uplink arrives on time:
% 
% $$\mathrm{TA}=\frac{2d}{c}$$
% 
% TDD uses uplink and downlink on the same carrier at different times, so after 
% radio calibration the channel measured one way can serve the other. FDD uses 
% separate uplink and downlink carriers at the same time and does not get that 
% reciprocity automatically.
% What to look for
% • In the results table, check the Doppler row against speed × carrier frequency 
% / c, then the coherence-time row against 0.423 divided by that Doppler.
% 
% • Divide the coherence time by the 30 kHz slot duration and compare with the 
% "Approximate coherent slots" row.
% 
% • Check the timing-advance row against 2 × distance / c, and the coherence-bandwidth 
% row against 1 / (5 × delay spread).
% 
% • In the figure, compare the two bar lengths in the top panel, and read the 
% timing-advance label in the bottom panel.
% Common mistakes
% Do not confuse delay spread with Doppler. Delay spread describes how long 
% the echoes last; Doppler describes how quickly the channel changes with motion.
% 
% Do not read TDD reciprocity as "all radios are identical". The transmit and 
% receive chains need calibration before reciprocity is used.
% Try it (personal exploration)
% Use f_D = v f_c / c (convert km/h to m/s first) to predict the Doppler shift 
% for the default speed and carrier, and type it in hertz into myPrediction 
% in the first code line below before you run this section. After the results 
% table, a given line prints your prediction beside the result. Then predict 
% with T_c ≈ 0.423 / f_D how many 30 kHz slots fit inside the coherence time, 
% and with TA = 2d/c the timing advance, and compare with the table.
% 
% Then change speed_kmh to 240 and predict the new Doppler and the number of 
% coherent slots before running; or change distance_m to 10000 and predict the 
% timing advance. The checks that compare with the narrated numbers are skipped, 
% with a printed note, when you change the example, so the run does not stop.

% Try it: type your prediction here (a number of hertz) before running this section.
myPrediction = NaN;
% Mobility and propagation calculations

% Use the exact SI speed of light for calculations. Spoken hand calculations
% may round this to 3 × 10^8 m/s.
speedOfLight = 299792458;

% This mobility example matches the narration: 120 km/h at a 3.5 GHz
% carrier frequency.
speed_kmh = 120;
speed_mps = speed_kmh / 3.6;
carrierFrequency_Hz = 3.5e9;

% Wavelength converts carrier frequency into a physical distance scale.
wavelength_m = speedOfLight / carrierFrequency_Hz;

% Doppler is relative speed divided by wavelength.
doppler_Hz = speed_mps / wavelength_m;

% This script uses the stated 0.423/fD coherence-time convention.
coherenceTime_s = 0.423 / doppler_Hz;

% At 30 kHz SCS, a normal-CP slot lasts 0.5 ms.
slotDuration_s = 0.5e-3;
coherentSlots = coherenceTime_s / slotDuration_s;

% This range example calculates the timing advance for a phone 3 km from
% the base station. The timing advance is based on round-trip delay.
distance_m = 3000;
timingAdvance_s = 2 * distance_m / speedOfLight;

% Coherence bandwidth previews the later delay-spread discussion. This uses
% the stated convention Bc ≈ 1/(5*tau_rms).
rmsDelaySpread_s = 300e-9;
coherenceBandwidth_Hz = 1 / (5 * rmsDelaySpread_s);

% TDD and FDD are better compared in a table than forced into a numerical
% plot because their key difference is structural, not scalar.
duplexMode = [ ...
    "TDD"; ...
    "FDD"];

directionSeparation = [ ...
    "Same carrier; uplink and downlink alternate in time"; ...
    "Different uplink and downlink carrier frequencies"];

channelImplication = [ ...
    "Air reciprocity can be used after radio calibration"; ...
    "Air reciprocity is not automatic across frequency"];

duplexResults = table( ...
    duplexMode, ...
    directionSeparation, ...
    channelImplication, ...
    VariableNames = {'Mode','DirectionSeparation','ChannelImplication'});

duplexResults
% TDD and FDD differ in structure, not in a number: TDD shares one carrier
% and takes turns, so after calibration one direction's measurement serves the
% other; FDD uses two carriers, so it does not get that for free.

% This table reports numerical quantities from the worked mobility and
% propagation examples.
dynamicsQuantity = [ ...
    "Speed"; ...
    "Carrier frequency"; ...
    "Wavelength"; ...
    "Maximum Doppler shift"; ...
    "Coherence time"; ...
    "30 kHz slot duration"; ...
    "Approximate coherent slots"; ...
    "Timing advance at 3 km"; ...
    "Coherence bandwidth at 300 ns RMS delay spread"];

dynamicsValue = [ ...
    string(sprintf('%.1f m/s (%.0f km/h)', speed_mps, speed_kmh)); ...
    string(sprintf('%.1f GHz', carrierFrequency_Hz/1e9)); ...
    string(sprintf('%.4f m', wavelength_m)); ...
    string(sprintf('%.1f Hz', doppler_Hz)); ...
    string(sprintf('%.3f ms', coherenceTime_s*1e3)); ...
    string(sprintf('%.1f ms', slotDuration_s*1e3)); ...
    string(sprintf('%.2f slots', coherentSlots)); ...
    string(sprintf('%.2f microseconds', timingAdvance_s*1e6)); ...
    string(sprintf('%.1f kHz', coherenceBandwidth_Hz/1e3))];

dynamicsResults = table( ...
    dynamicsQuantity, ...
    dynamicsValue, ...
    VariableNames = {'Quantity','Value'});

dynamicsResults

% Compare your Try-it prediction with the result, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run it again.')
else
    predCompare = table(myPrediction, doppler_Hz, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
%% B4 — After the run
% Compare Doppler, coherence time, and coherent slots in the table. Then read
% the timing-advance and coherence-bandwidth rows, and the TDD/FDD contrast
% above, against the figure that follows.
%% B4 — Verification results

% These checks verify the approximate narrated values. Tolerances are used
% because spoken calculations round the speed of light and displayed values.

% Relationship checks, which hold for any speed, carrier, distance, or delay
% spread you try. Each one reaches the answer by a different route.
checkDopplerRoute = abs(doppler_Hz - speed_mps * carrierFrequency_Hz / speedOfLight) < 1e-6;

assert(checkDopplerRoute, ...
    'Doppler from v / lambda does not match v f_c / c. Look first at wavelength_m and at speed_mps = speed_kmh / 3.6.');

% These checks compare with the narrated values, so they run only for the
% default example. Tolerances are used because spoken calculations round the
% speed of light and displayed values.
isDefaultExample = speed_kmh == 120 && carrierFrequency_Hz == 3.5e9 && ...
    distance_m == 3000 && rmsDelaySpread_s == 300e-9;
if isDefaultExample
    checkDoppler = abs(doppler_Hz - 389) < 3;
    checkCoherentSlots = coherentSlots > 2.0 && coherentSlots < 2.5;
    checkTimingAdvance = abs(timingAdvance_s*1e6 - 20) < 0.1;
    checkCoherenceBandwidth = abs(coherenceBandwidth_Hz/1e3 - 666.7) < 1.0;
else
    % NaN marks "skipped" in the verification table.
    checkDoppler = NaN;
    checkCoherentSlots = NaN;
    checkTimingAdvance = NaN;
    checkCoherenceBandwidth = NaN;
    disp('Default-only checks skipped: the narrated-value checks are written for 120 km/h, 3.5 GHz, 3 km, and 300 ns.')
end

checkDuplexModes = height(duplexResults) == 2 && ...
    all(ismember(["TDD"; "FDD"], duplexResults.Mode));

assert(~(checkDoppler == 0), ...
    'The default example does not give the narrated Doppler. Look first at speed_mps = speed_kmh / 3.6.');

assert(~(checkCoherentSlots == 0), ...
    'The default example does not stay coherent for the narrated number of slots. Look first at slotDuration_s (0.5 ms at 30 kHz) and the 0.423 / f_D line.');

assert(~(checkTimingAdvance == 0), ...
    'The default example does not give the narrated timing advance. Look first at the factor 2 in timingAdvance_s: the delay is there and back.');

assert(~(checkCoherenceBandwidth == 0), ...
    'The default example does not give the narrated coherence bandwidth. Look first at rmsDelaySpread_s and the 1 / (5 tau) line. Common mistake: confusing delay spread with Doppler.');

assert(checkDuplexModes, ...
    'The duplexing table should contain both TDD and FDD. Look first at duplexMode: it lists the two modes.');

checkPassed = [ ...
    checkDopplerRoute; ...
    checkDoppler; ...
    checkCoherentSlots; ...
    checkTimingAdvance; ...
    checkCoherenceBandwidth; ...
    checkDuplexModes];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(checkPassed == 0) = "Fail";
resultText(isnan(checkPassed)) = "Skipped (default-only)";

dynamicsCheckName = [ ...
    "Doppler, second route"; ...
    "Doppler at the default speed and carrier"; ...
    "Coherent 30 kHz slots"; ...
    "Timing advance at the default distance"; ...
    "Coherence bandwidth at the default delay spread"; ...
    "Duplexing comparison"];

dynamicsExpected = [ ...
    "v / lambda = v f_c / c"; ...
    "matches the default narrated Doppler (default only)"; ...
    "matches the default coherent-slot range (default only)"; ...
    "matches the default timing advance (default only)"; ...
    "matches the default coherence bandwidth (default only)"; ...
    "Both TDD and FDD are represented"];

dynamicsChecks = table( ...
    dynamicsCheckName, ...
    dynamicsExpected, ...
    resultText, ...
    VariableNames = {'Check','Expected','Pass'});

dynamicsChecks

%% B4 — Motion and propagation figure
% The upper panel compares coherence time with the duration of a 30 kHz
% slot. The lower panel illustrates timing advance as a round-trip delay
% associated with a one-way phone-to-base-station distance.

figure( ...
    Name = 'P00b - Doppler, coherence, and timing advance', ...
    Color = 'w', ...
    Units = 'pixels', ...
    Position = [100 80 900 1000]);

tl = tiledlayout(2,1, ...
    TileSpacing = 'compact', ...
    Padding = 'loose');

title(tl, { ...
    'Motion and Distance Set Different Wireless Time Scales', ...
    'Doppler Changes the Channel; Timing Advance Aligns Arrival Time'}, ...
    FontWeight = 'bold', ...
    FontSize = 15);

% Top panel — Coherence time and slot duration

axCoherence = nexttile;

% Both bars use milliseconds, so direct visual comparison is meaningful.
timeLabels = categorical( ...
    {'Coherence time', '30 kHz slot'}, ...
    {'Coherence time', '30 kHz slot'});

timeValues_ms = [coherenceTime_s*1e3, slotDuration_s*1e3];

bar(axCoherence, timeLabels, timeValues_ms, ...
    FaceColor = [0.20 0.40 0.80], ...
    EdgeColor = [0.15 0.15 0.15]);

grid(axCoherence, 'on');
box(axCoherence, 'on');

ylabel(axCoherence, 'Duration (ms)');

title(axCoherence, { ...
    sprintf('%.0f km/h at %.1f GHz gives f_D = %.0f Hz', speed_kmh, carrierFrequency_Hz/1e9, doppler_Hz), ...
    sprintf('Approximately %.1f normal-CP 30 kHz slots fit within T_c', ...
    coherentSlots)});

text(axCoherence, 1, timeValues_ms(1) + 0.05, ...
    sprintf('%.2f ms', timeValues_ms(1)), ...
    HorizontalAlignment='center', ...
    VerticalAlignment='bottom', ...
    FontWeight='bold');

text(axCoherence, 2, timeValues_ms(2) + 0.05, ...
    sprintf('%.1f ms', timeValues_ms(2)), ...
    HorizontalAlignment='center', ...
    VerticalAlignment='bottom', ...
    FontWeight='bold');

% Bottom panel — Timing advance and distance

axTimingAdvance = nexttile;

% This is a propagation-distance timeline, not a mixed-units bar chart.
% The horizontal line represents the one-way distance d between the base
% station and phone; the label states the round-trip timing correction 2d/c.

distanceAxis_km = [0 distance_m/1000];

plot(axTimingAdvance, distanceAxis_km, [0 0], '-k', ...
    LineWidth=2.0, ...
    HandleVisibility='off');

hold(axTimingAdvance, 'on');

plot(axTimingAdvance, 0, 0, 'o', ...
    MarkerSize=10, ...
    MarkerFaceColor=[0.20 0.40 0.80], ...
    MarkerEdgeColor=[0.15 0.15 0.15], ...
    HandleVisibility='off');

plot(axTimingAdvance, distance_m/1000, 0, 'o', ...
    MarkerSize=10, ...
    MarkerFaceColor=[0.90 0.30 0.10], ...
    MarkerEdgeColor=[0.15 0.15 0.15], ...
    HandleVisibility='off');

grid(axTimingAdvance, 'on');
box(axTimingAdvance, 'on');

xlim(axTimingAdvance, [-0.25 distance_m/1000 + 0.25]);
ylim(axTimingAdvance, [-1 1]);
yticks(axTimingAdvance, []);

xlabel(axTimingAdvance, 'One-way distance from base station to phone (km)');

title(axTimingAdvance, ...
    'Timing advance compensates for round-trip propagation delay');

text(axTimingAdvance, 0, 0.30, 'Base station', ...
    HorizontalAlignment='center', ...
    FontWeight='bold', ...
    Color=[0.08 0.22 0.55]);

text(axTimingAdvance, distance_m/1000, 0.30, 'Phone', ...
    HorizontalAlignment='center', ...
    FontWeight='bold', ...
    Color=[0.65 0.12 0.05]);

text(axTimingAdvance, distance_m/2000, -0.30, ...
    sprintf('one-way distance d = %.1f km', distance_m/1000), ...
    HorizontalAlignment='center', ...
    FontSize=11);

text(axTimingAdvance, distance_m/2000, 0.65, ...
    sprintf('timing advance = 2d/c = %.2f microseconds', ...
    timingAdvance_s*1e6), ...
    HorizontalAlignment='center', ...
    FontSize=11, ...
    FontWeight='bold', ...
    BackgroundColor='w');

%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.
% The Build it section follows. Figures and table output remain
% visible after section-specific working variables are removed.

clear duplexResults dynamicsResults dynamicsChecks ...
      speedOfLight speed_kmh speed_mps carrierFrequency_Hz ...
      wavelength_m doppler_Hz coherenceTime_s slotDuration_s coherentSlots ...
      distance_m timingAdvance_s rmsDelaySpread_s coherenceBandwidth_Hz ...
      duplexMode directionSeparation channelImplication ...
      dynamicsQuantity dynamicsValue ...
      checkDoppler checkCoherentSlots checkTimingAdvance ...
      checkCoherenceBandwidth checkDuplexModes ...
      checkDopplerRoute isDefaultExample ...
      checkPassed resultText dynamicsCheckName dynamicsExpected ...
      timeLabels timeValues_ms distanceAxis_km ...
      axCoherence axTimingAdvance tl myPrediction
%% Build it — Turn received values into soft bits
% Competency: compute BPSK LLRs from received values and a noise variance, and 
% read the hard decision from each LLR's sign.
% Problem
% You are given yRx, five received BPSK values, and noiseVar = 0.5, the noise 
% variance. Bit 0 was sent as +1 and bit 1 as −1. Build llrOut, the five LLRs, 
% with LLR = 2y/σ², and bitOut, the five hard decisions (1 where the LLR is 
% negative, 0 otherwise).
% Allowed commands
% Square brackets [ ]; numel; zeros; size; the arithmetic operators + - * / 
% and element-by-element .* ./; the comparisons < and >; sum; abs; disp; fprintf. 
% The plotting in Stage 5 is given.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at.
%% Stage 1 — switch it on
% Delete the % in front of the three code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% yRx = [0.9 -0.2 0.05 -1.3 0.4];   % five received values
% noiseVar = 0.5;                   % noise variance, sigma squared
% disp(yRx)
%% Stage 1 check (given)
if ~exist('yRx','var') || ~exist('noiseVar','var')
    disp('Stage 1 not done: delete the % in front of the three code lines above, then run that section.')
else
    assert(numel(yRx) == 5 && noiseVar > 0, ...
        'yRx should hold five values and noiseVar should be positive. Did you change a line?')
    disp('Stage 1 OK')
end
%% Stage 2 — name and shape: a place for the answers
% Rename z to llrOut, the name the checks expect. It starts as zeros, one per 
% received value; Stage 3 fills it.
% Pass: Stage 2 OK.

% z = zeros(size(yRx));
%% Stage 2 check (given)
if ~exist('llrOut','var')
    disp('Stage 2 not done: rename z to llrOut, uncomment, and run.')
else
    assert(isequal(size(llrOut), size(yRx)), ...
        'llrOut should have one entry per received value. Look at size(yRx).')
    disp('Stage 2 OK')
end
%% Stage 3 — compute the LLRs
% Fill the blanks so each LLR is the Gaussian shortcut in terms of yRx and
% noiseVar, for every value at once.
% Pass: Stage 3 OK.

% llrOut = ___ * yRx / ___;
%% Stage 3 check (given; the check uses the two Gaussian likelihoods, a different route)
if ~exist('llrOut','var') || all(llrOut == 0)
    disp('Stage 3 not done: fill the blanks, uncomment, and run.')
else
    likelyZero = exp(-(yRx - 1).^2 / (2*noiseVar));   % how well +1 explains each value
    likelyOne = exp(-(yRx + 1).^2 / (2*noiseVar));    % how well -1 explains each value
    oracle = log(likelyZero ./ likelyOne);
    assert(max(abs(llrOut + oracle)) > 1e-9, ...
        'Every LLR has the wrong sign. Common mistake: flipping the sign convention; bit 0 was sent as +1.')
    assert(max(abs(llrOut - oracle/2)) > 1e-9, ...
        'Every LLR is half the right size. Common mistake: dropping the factor of 2.')
    assert(max(abs(llrOut - oracle)) < 1e-9, ...
        'The LLRs do not match the likelihood ratio. Look at the denominator.')
    disp('Stage 3 OK')
end
%% Stage 4 — predict, then read the hard decisions
% First type your prediction: how many of the five decisions will be 1? Use 
% the sign rule only. Then fill the blank with the comparison that is true where 
% the LLR favours bit 1.
% Pass: your prediction and the count print side by side, and Stage 4 OK.

% myPrediction = ___;
% bitOut = llrOut ___ 0;
%% Stage 4 check (given)
if ~exist('bitOut','var') || ~exist('myPrediction','var') || isnan(myPrediction)
    disp('Stage 4 not done: type a numeric prediction into myPrediction, fill the blank, uncomment, and run.')
else
    predCompare = table(myPrediction, sum(bitOut), ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
    assert(isequal(double(bitOut), double(oracle < 0)), ...
        'Some decisions are inverted. Common mistake: flipping the sign convention; a negative LLR means bit 1.')
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('bitOut','var') || ~exist('oracle','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your result, so the table cannot say Pass by itself.
    [~, orderLLR] = sort(abs(llrOut));
    [~, orderY] = sort(abs(yRx));
    buildFlags = [max(abs(llrOut - oracle)) < 1e-9; ...
        isequal(double(bitOut), double(yRx < 0)); ...
        isequal(orderLLR, orderY)];
    buildResult = repmat("Fail", numel(buildFlags), 1);
    buildResult(buildFlags) = "Pass";

    % Asserts above stop the run on failure; this table makes the passes visible.
    buildChecks = table(["LLR value"; "Decision from sign"; "Confidence grows with |y|"], ...
        ["log of the likelihood ratio"; "1 exactly where y is negative"; "sort(|LLR|) matches sort(|y|)"], ...
        buildResult, VariableNames = {'Check','Expected','Pass'});
    buildChecks

    figure(Name = 'P00b Build it - my soft bits', Color = 'w');
    bar(1:numel(llrOut), llrOut, FaceColor = [0.20 0.40 0.80]);
    hold on;
    yline(0, 'k-', LineWidth = 1.2);
    text(1:numel(llrOut), llrOut + 0.4*sign(llrOut + eps), ...
        compose('bit %d', double(bitOut)), HorizontalAlignment = 'center');
    hold off;
    grid on;
    xlabel('Received value number');
    ylabel('LLR');
    title({'Above zero: guess bit 0; below zero: guess bit 1', 'bar height = confidence'});
end
%% Build it — Interpretation
% Your interpretation (write one or two sentences here): which received value
% gives the least confident bit, and what would a decoder do with it that a
% hard 0 or 1 cannot tell it?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. The check uses your
% LLRs and does not print a model sentence.
myAnswer = NaN;   % which received-value number (1 to 5) is the least confident?
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('llrOut','var')
    disp('Run Stages 1 to 5 first, then return here.')
else
    [~, leastConf] = min(abs(llrOut));
    okInterp = (myAnswer == leastConf);
    interpCheck = table("Least-confident received value", ...
        okInterp, VariableNames = {'Check','Pass'});
    interpCheck
end
%% Build it — Cleanup
% If a later section says a variable is undefined, run the script from the top
% (Run All). Figures remain open. Names the Review needs are not used here.
clear buildFlags buildResult buildChecks predCompare oracle leastConf okInterp ...
    interpCheck myAnswer orderLLR orderY
%% Follow-on exercises
% These go one step past the beats: a new value, or a diagnosis. Copying a
% block from above and changing one number will not answer them. The checks
% do not print a model value.
%% E1 — New value
% A received BPSK value is y = -0.5 and the noise variance is 0.5. What is the
% LLR from the Gaussian shortcut? Type that number into myAnswer, then run
% this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE1 = abs(myAnswer - (2*(-0.5)/0.5)) < 1e-12;
    e1Check = table("E1 LLR", okE1, VariableNames = {'Check','Pass'});
    e1Check
end
%% E2 — Diagnosis
% If the phone's speed doubles and the carrier stays the same, by what factor
% does the Doppler shift change? Type that factor into myAnswer, then run
% this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE2 = abs(myAnswer - 2) < 1e-12;
    e2Check = table("E2 Doppler factor", okE2, VariableNames = {'Check','Pass'});
    e2Check
end
%% Exercise cleanup
clear myAnswer okE1 e1Check okE2 e2Check
%% Recap — P00b Map of the Link: Soft Bits and Channel Dynamics
% Soft bits carry a guess and a confidence; motion and distance set how long
% channel knowledge lasts and how early the phone must send.
% Key relationships
% The LLR is the log of the two likelihoods. For BPSK in Gaussian noise it
% simplifies to the shortcut 2y/σ²:
%
% $$\mathrm{LLR}=\log\frac{P(y\mid b=0)}{P(y\mid b=1)}=\frac{2y}{\sigma^2}$$
%
% Motion and distance set the time scales:
%
% $$f_D=\frac{v f_c}{c},\qquad T_c\approx\frac{0.423}{f_D},\qquad \mathrm{TA}=\frac{2d}{c}$$
% What this means in practice
% • Soft bits feed the LDPC decoder: the sign is the guess, the size tells the
% decoder how much to trust it.
%
% • Compare coherence time with the slot: a fast-moving phone at a high carrier
% frequency needs channel estimates refreshed every few slots.
%
% • Timing advance is 2d/c, so a farther phone transmits earlier. TDD can reuse
% a downlink measurement for the uplink after calibration; FDD cannot do that
% automatically.
%
% • You built a soft-bit converter: five received values to five LLRs and five
% hard decisions, checked against the likelihood ratio itself.
%
% • Next in the album: Track 01.
%% Review — self-check
% Collapse or scroll past the Recap so it is out of sight, then write from
% memory, in your own words. Do not look back until you have written what you
% can. Nothing in the written lists below is graded by the script.
%
% First, restate each Key relationship from the front of the file, one line
% each. Then, for each command you write yourself (* / and .* ./; exp and log;
% abs), give its purpose, its inputs, and its outputs. When you have written
% all you can, scroll up to Key relationships and Key code terms and compare.
% Mark anything you missed.
% My key relationships
% 1.
%
% 2.
% Commands I write (purpose; inputs; outputs)
% • * / and .* ./:
%
% • exp and log:
%
% • abs:
% What I missed, and where to reread it
%
%% Review — retrieval
% Still keeping the Recap collapsed, type a number into myAnswer and run this
% section. From the signal-map half of P00b, does a CRC detect errors (1),
% correct them (2), or both (3)? The check uses a second route and does not
% print a model value.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    crcDetectOnly = 1;   % detect, not correct
    okReview = (myAnswer == crcDetectOnly);
    reviewCheck = table("CRC role", okReview, VariableNames = {'Check','Pass'});
    reviewCheck
end
