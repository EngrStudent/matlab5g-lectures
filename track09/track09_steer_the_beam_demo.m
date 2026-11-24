%% track09_steer_the_beam_demo
%% Steer the Beam (album track 09): steering vectors, array gain, grating lobes, and one RF chain
% In Clusters and Angles, echoes arrived from directions. Now we use that. 
% Take many small antennas sending the same signal, turn each one's phase 
% by the right step, and the copies add up in one direction and cancel in 
% others. That is beamforming.
% 
% This demonstration builds a line of antennas, steers it, measures the gain, 
% breaks it on purpose by spacing the antennas too far apart, and shows what 
% a beam pointed the wrong way does.
%% Guiding question
% How does a line of antennas point a beam with nothing but phase, how much 
% gain does it buy, and what goes wrong when the antennas are too far apart?
% This demonstration
% 1. B1 — Build a 16-element array and its steering vector, and read the phase 
% step between neighbours.
% 
% 2. B2 — Steer to broadside with unit-norm weights and measure the gain: 
% 10 log10(N).
% 
% 3. B3 — The grating-lobe counterexample: one-wavelength spacing gives a 
% second, full-strength lobe.
% 
% 4. B4 — One RF chain pointed the wrong way, and a glance at the CQI tables 
% a phone reports from.
% 
% 5. Build it — Build an 8-element steering vector by hand, measure its gain, 
% and find where its grating lobe lands when the spacing grows.
% Key relationships
% On a uniform linear array with spacing d, a plane wave from angle θ (measured 
% from broadside) reaches element n with the phase
% 
% $$a_n(\theta) = e^{-j2\pi (d/\lambda)\, n\sin\theta},\qquad n = 0, 1, \ldots, N-1$$
% 
% so neighbours differ by 2π (d/λ) sin θ, which is π sin θ at d = λ/2. With 
% unit-norm weights w = a/‖a‖ the power gain in the steered direction is
% 
% $$G = |\mathbf{w}^{H}\mathbf{a}|^{2} = N,\qquad G_{\mathrm{dB}} = 10\log_{10}N$$
% 
% and a grating lobe appears wherever sin θ_g = sin θ_0 ± λ/d lies between 
% −1 and 1.
% Key ideas to remember
% • A uniform linear array (ULA) is N elements on a line, d apart. A plane 
% wave from angle θ reaches neighbours with a fixed phase step.
% 
% • At half-wavelength spacing the phase step between neighbours is π sin θ. 
% Writing those phases down, one per element, gives the steering vector.
% 
% • Weighting each element by the conjugate of that phase lines the copies 
% up, and the main lobe leans towards θ. Every element keeps the same strength; 
% only the phase is turned.
% 
% • With the total power fixed (unit-norm weights), N elements in step give 
% a power gain of N: 16 elements give about 12 dB, sixty-four about eighteen.
% 
% • The gain is not created: it is taken from other directions, so the pattern 
% falls away from the steered angle.
% 
% • Spacing above half a wavelength aliases: at one wavelength a second, full-strength 
% grating lobe appears for any steering angle off broadside.
% 
% • One RF chain gives one analogue beam. Pointed the wrong way it can lose 
% all its gain, which is why the phone reports what it measures (CSI) and 
% the base station re-aims.
% Prerequisites
% • Steering vectors and the outer-product picture of a channel (album track 
% 08 Clusters and Angles, track08/track08_clusters_and_angles_demo).
% 
% • Complex numbers, phase, and dB (track 00 Fundamentals, track00_fundamentals/p00b_softbits_and_dynamics_demo 
% and track00_fundamentals/p00a_ofdm_and_cp_demo).
% 
% • Software: this track needs the Phased Array System Toolbox (phased.ULA, 
% phased.SteeringVector) as well as the 5G Toolbox; Staging stops with a message 
% if it is missing.
% 
% • Used here, not taught here: the CSI-RS a phone measures before it reports 
% is album track 10 (Sound It Out); the CQI target of about one in ten is album 
% track 11 (One in Ten).
% Words used in this demo
% • ULA (uniform linear array): N antenna elements on a line, equally spaced. 
% Broadside: the direction perpendicular to the line (0°). End-fire: along 
% the line (±90°).
% 
% • Steering vector: the column of phases a plane wave from one angle puts 
% on the elements.
% 
% • Weights: the complex numbers each element's signal is multiplied by. Unit-norm: 
% the squared magnitudes add up to 1, so the total power is fixed.
% 
% • Array factor (pattern): |wᴴ a(θ)| over all angles θ, in dB here. Main 
% lobe: the peak. Grating lobe: a second peak of the same height at a false 
% angle.
% 
% • RF chain: one converter and mixer path. Hybrid beamforming: a few RF chains 
% behind many elements, with analogue phase shifters.
% 
% • CSI (channel state information): what the phone reports about the channel. 
% CQI: the channel quality index in that report.
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
% • + - * / ^ and exp(1j*x) — Purpose: arithmetic, and unit complex numbers 
% with phase x radians (x may be a column, giving a column). Inputs: numbers. 
% Outputs: the result.
% 
% • (0:N-1).' — Purpose: the element numbers 0 to N − 1 as a column. Inputs: 
% N. Outputs: an N × 1 column.
% 
% • sind(x) and asind(y) — Purpose: the sine of an angle in degrees, and the 
% angle in degrees whose sine is y. Inputs: degrees; a number from −1 to 1. 
% Outputs: a number; degrees.
% 
% • norm(v) and w' * a — Purpose: the length of a vector; the inner product 
% of two columns (w' conjugates). Inputs: columns. Outputs: a number (real 
% for norm, complex for the product).
% 
% • abs(z)^2 and 10*log10(x) — Purpose: the power of a complex number; a power 
% ratio in dB. Inputs: a number. Outputs: a number.
% 
% Commands you read in the given code
% • arr = phased.ULA(NumElements = N, ElementSpacing = d) — Purpose: make a 
% uniform linear array (Phased Array System Toolbox). Inputs: the element 
% count; the spacing in metres (set it explicitly: the default is 0.5 m, not 
% half a wavelength). Outputs: an array object.
% 
% • sv = phased.SteeringVector(SensorArray = arr, PropagationSpeed = c) and 
% a = sv(fc, ang) — Purpose: make a steering-vector object, then evaluate 
% it. Inputs: the array and the speed of light (m/s); then the frequency (Hz) 
% and angles in degrees (a row for many). Outputs: N × 1 (or N × angles) unit-magnitude 
% phases, referenced to the array centre.
% 
% • t = nrCQITables — Purpose: the four CQI tables of TS 38.214 (R2024a and 
% later). Inputs: none. Outputs: an object whose CQITable1 to CQITable4 are 
% tables with CQIIndex, Modulation, TargetCodeRate (already divided by 1024), 
% SpectralEfficiency, and Qm. Used in B4.
% 
% • Figure family: figure(Name = ...), plot, legend, xlabel, ylabel, title, 
% grid on, hold on, hold off, xline, ylim — Purpose: draw curves, label them, and name the 
% figure. Inputs: data and text. Outputs: a figure. Used in B2, B3, and Build 
% it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b:c, x(:), x(end), x(mask), T.name — Purpose: 
% read entries, count a range with a step, reshape, pick the entries where 
% a mask is true, read a table column. Inputs: an array and positions. Outputs: 
% the entries.
% 
% • Compare and combine: == < > <= >=, & && ||, .* ./ — Purpose: compare values; 
% and, or; work entry by entry. Inputs: numbers or arrays. Outputs: true/false 
% or numbers.
% 
% • Built-in helpers: abs, angle, max, min, nnz, numel, height, size, isequal, 
% all, any, unique, round, real, isreal, sqrt, sum, cumprod, repmat, eps, 
% pi, exist, isnan, NaN — Purpose: sizes, counts, largest and smallest entries, 
% phase angles, products along a column, look a name up. Inputs: numbers, arrays, or names. Outputs: numbers 
% or true/false (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, sprintf, and f = @(v) 
% ... — Purpose: write and join text, turn numbers into text, fill a format, 
% and make a one-line helper such as listText or isPeak. Inputs: text, numbers, 
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
% Teaching draft built to the track01 r03 template (track09 r01, 2026-11-20) 
% from the live track09_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the Phased Array System 
% Toolbox (phased.ULA, phased.SteeringVector) and the 5G Toolbox, R2024a or 
% later (nrCQITables). The Key relationships write the phase with a minus 
% sign from element 0; the toolbox may use the opposite sign and references 
% the phase to the array centre. Neither changes any magnitude, gain, or pattern 
% in this file, so the beats only compare magnitudes. Teaching demo, not production 
% code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year); nothing below is random, kept for the template

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% Stop early with a clear message if the Phased Array System Toolbox is missing.
if isempty(ver('phased'))
    error('This track needs the Phased Array System Toolbox (phased.ULA, phased.SteeringVector).')
end

% The settings every beat uses.
c = 299792458;                % speed of light, m/s
fc = 3e9;                      % carrier frequency, Hz (a mid-band carrier)
lambda = c/fc;                 % wavelength, m (about 0.1 m)
N = 16;                        % number of array elements
ang = -90:0.5:90;              % angles for every pattern, degrees from broadside (0.5 degree steps)
%% B1 — Build the array and its steering vector
% New words
% • Phase step: the phase difference between neighbouring elements for one 
% arrival angle.
% Beat-only commands
% • angle(z) — the phase of a complex number in radians, between −π and π.
% Why it matters
% A uniform linear array points a beam by applying a progressive phase across 
% its elements. phased.ULA and phased.SteeringVector are the documented way 
% to build that column of phases instead of writing the formula only by hand. 
% Every entry has magnitude 1: steering changes phases, not strengths.
% What to look for
% • In the steering table: the magnitudes of the broadside vector, and the 
% size of the phase step between neighbours at 30°.
% Common mistakes
% Do not put degrees into sin inside exp: use sind, or convert to radians.
% 
% angle wraps at ±π; do not difference wrapped phases.
% 
% Do not confuse broadside (0°, the array normal) with end-fire (±90°, along 
% the line).
% Try it (personal exploration)
% At half-wavelength spacing, predict the size of the phase step between neighbours, 
% in degrees, for a wave from end-fire (90°). Type it into myPrediction before 
% you run this section; the one-row table at the end reads it from the toolbox 
% steering vector.

% Try it: type your prediction here (degrees) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Build the array and its steering vector
fprintf("B1 — Build the array and its steering vector\n");   % banner title only; every number below goes into a table

% A 16-element half-wavelength ULA and its steering-vector object.
array = phased.ULA(NumElements = N, ...             % 16 elements
                   ElementSpacing = 0.5*lambda);    % half a wavelength, m
sv = phased.SteeringVector(SensorArray = array, ... % the array above
                           PropagationSpeed = c);   % speed of light, m/s
a0  = sv(fc, 0);                                    % broadside (0 degrees), 16 × 1
a30 = sv(fc, 30);                                   % 30 degrees, 16 × 1

% Phase step between neighbours, without wrapping: the angle of each ratio
% a(n+1)/a(n). Its size does not depend on the toolbox's sign convention.
step30 = abs(angle(a30(2:end) ./ a30(1:end-1)))*180/pi;   % 15 steps, degrees

% Two tests: every entry has magnitude 1, and every step at 30 degrees is
% π sin 30° (90 degrees), the half-wavelength rule.
okUnit = all(abs(abs([a0; a30]) - 1) < 1e-12);
assert(okUnit, ...
    'Every steering-vector entry should have magnitude 1. Look first at the array: it must be built with phased.ULA, not your own weights.');
okStep = all(abs(step30 - 180*sind(30)) < 1e-9);
assert(okStep, ...
    'The phase step at 30 degrees should be the same for every pair of neighbours. Common mistake: setting ElementSpacing in wavelengths instead of metres.');

b1Steering = table(string(listText(unique(round(abs(a0), 6)))), string(listText(unique(round(step30, 6)))), ...
    VariableNames = {'Magnitudes_a0', 'PhaseStep30_deg'});
b1Steering

% Put your Try-it prediction beside the end-fire phase step.
a90 = sv(fc, 90);                                            % end-fire, 16 × 1
tryStep = abs(angle(a90(2) / a90(1)))*180/pi;                % one neighbour pair, degrees
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, round(tryStep, 6), predictionNote, ...
    VariableNames = {'MyPrediction', 'PhaseStep90_deg', 'Note'});
b1Prediction
%%
% Broadside needs no phase step at all: a wave from straight ahead reaches 
% every element at once, so the vector is all ones up to one common phase. 
% At 30° each element is a quarter turn behind its neighbour. The magnitudes 
% never change. Compare the end-fire step with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["Every entry has magnitude 1"; ...
     "Phase step at 30° = π sin 30°"], ...
    ["1"; "90°"], ...
    [string(listText(unique(round(abs([a0; a30]), 6)))); string(listText(unique(round(step30, 6)))) + "°"], ...
    [okUnit; okStep], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep array, sv, and a0: B2 steers with them. Keep c, fc, lambda, N, ang, and listText.
clear b1Steering b1Checks b1Prediction predictionNote okUnit okStep ...
      a30 step30 a90 tryStep myPrediction
%% B2 — Pattern, gain, and the power invariant
% New words
% • Coherent gain: the power gain from adding N copies in phase.
% Why it matters
% One setup throughout: a fixed total transmit power, split by unit-norm weights 
% w (‖w‖ = 1). In the steered direction |wᴴa| = √N, so the power gain over 
% one element is 10 log10(N): 16 elements give 12.04 dB. The power is not 
% created; it is taken from other directions. (If instead each element keeps 
% its own full power, the total grows by N too and the gain over one element 
% is 20 log10(N). That is a different setup, not a mistake.)
% What to look for
% • In the gain table: the norm of the weights, the pattern peak, and where 
% it sits.
% 
% • In the figure: a main lobe at 0° falling away on both sides.
% Common mistakes
% Do not mix the two setups (fixed total power and fixed power per element).
% 
% Do not forget to normalize the weights: without it, a longer array silently 
% radiates more total power.
% Try it (personal exploration)
% Predict the pattern peak, in dB, for a 32-element half-wavelength array 
% with unit-norm broadside weights. Type it into myPrediction before you run 
% this section; the one-row table at the end measures it on a separate 32-element 
% array.

% Try it: type your prediction here (dB) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Pattern, gain, and the power invariant
fprintf("B2 — Pattern, gain, and the power invariant\n");   % banner title only; every number below goes into a table

% Unit-norm broadside weights: fixed total power, every element the same strength.
w = a0 / norm(a0);                                  % 16 × 1, norm 1
svAng = sv(fc, ang);                                % steering vectors for every angle, 16 × 361
pattern = 20*log10(abs(w' * svAng) + eps);          % array factor, dB (eps avoids log of 0)
[pk, idx] = max(pattern);                           % peak value (dB) and its index

% Three tests: the weights are unit-norm, the peak is 10 log10(N), and it sits
% at the steered angle, 0 degrees.
okNorm = abs(norm(w) - 1) < 1e-12;
assert(okNorm, ...
    'The weights should have norm 1. Look first at w: divide the steering vector by its own norm.');
okPeak = abs(pk - 10*log10(N)) < 0.05;
assert(okPeak, ...
    'The peak should be 10 log10(N) dB. Common mistake: using 20 log10(N), the fixed-power-per-element setup.');
okPeakAngle = ang(idx) == 0;
assert(okPeakAngle, ...
    'The peak should sit at 0 degrees, where the weights point. Look first at w: it must come from a0.');

b2Gain = table(norm(w), pk, 10*log10(N), ang(idx), ...
    VariableNames = {'NormW', 'Peak_dB', 'TenLog10N_dB', 'PeakAngle_deg'});
b2Gain

% Put your Try-it prediction beside the peak of a separate 32-element array.
arr32 = phased.ULA(NumElements = 32, ElementSpacing = 0.5*lambda);   % 32 elements, half a wavelength, m
sv32 = phased.SteeringVector(SensorArray = arr32, PropagationSpeed = c);
w32 = sv32(fc, 0) / norm(sv32(fc, 0));                               % unit-norm broadside weights
tryPeak = max(20*log10(abs(w32' * sv32(fc, ang)) + eps));            % dB
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, round(tryPeak, 2), predictionNote, ...
    VariableNames = {'MyPrediction', 'Peak32_dB', 'Note'});
b2Prediction

% The pattern: one main lobe at broadside.
figure(Name = 'Track 09 B2 - broadside pattern', Color = 'w');
plot(ang, pattern);                                 % array factor over angle
grid on;
ylim([-40 15]);
xlabel('angle from broadside (deg)');
ylabel('array factor (dB)');
title('B2: N = 16, half-wavelength ULA, unit-norm weights at broadside');
%%
% The peak is 10 log10(16) = 12.04 dB, exactly where the weights point. Every 
% element kept the same strength and the total power stayed 1: the main lobe 
% borrows its power from the other directions, which is why the pattern drops 
% into deep nulls on either side. Compare the 32-element peak with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Weights are unit-norm (by construction)"; ...
     "Peak = 10 log10(N)"; ...
     "Peak at the steered angle"], ...
    ["1"; string(round(10*log10(N), 2)) + " dB"; "0°"], ...
    [string(norm(w)); string(round(pk, 2)) + " dB"; string(ang(idx)) + "°"], ...
    [okNorm; okPeak; okPeakAngle], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep sv, svAng, a0, and w: B3 compares patterns with them and B4 reuses w.
clear b2Gain b2Checks b2Prediction predictionNote okNorm okPeak okPeakAngle ...
      pattern pk idx arr32 sv32 w32 tryPeak myPrediction array
%% B3 — The grating-lobe counterexample
% New words
% • Grating lobe: a second main lobe, as strong as the first, at a false angle. 
% It appears when the spacing is more than half a wavelength.
% Beat-only commands
% • isPeak = @(p) ... — a one-line helper, given below: true where a sample 
% is higher than both neighbours. Base MATLAB, so the Signal Processing Toolbox 
% is not needed.
% Why it matters
% If the element spacing is larger than half a wavelength, the array factor 
% aliases and a grating lobe appears. The beam still looks sharp, but it no 
% longer has one pointing direction: it sends as much power to the false angle 
% as to the real one. Both arrays here are steered to 30°. At d = λ the lobe 
% lands where sin θ_g = sin 30° − 1, at −30°. (Steered to broadside, the d 
% = λ lobes sit exactly on ±90°, where a peak finder cannot see them.)
% What to look for
% • In the lobes table: how many lobes come within 8 dB of the peak, and at 
% which angles, for d = λ/2 and d = λ.
% 
% • In the figure: the second, equal lobe of the wide array.
% Common mistakes
% Do not tighten a beam by stretching the array without adding elements: the 
% beam narrows, but grating lobes appear.
% 
% Do not set ElementSpacing in wavelengths: phased.ULA takes metres, so multiply 
% by lambda.
% Try it (personal exploration)
% Steered to 30°, a 0.75-wavelength array also has a grating lobe. Predict 
% its angle in degrees. Type it into myPrediction before you run this section; 
% the one-row table at the end finds it on a separate array.

% Try it: type your prediction here (degrees) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — The grating-lobe counterexample
fprintf("B3 — The grating-lobe counterexample\n");   % banner title only; every number below goes into a table

steer = 30;            % steering angle for both arrays, degrees
spacingWide = 1.0;     % wide spacing, wavelengths

% Half-wavelength array (sv from B1), steered to 30 degrees with unit-norm weights.
wN = sv(fc, steer) / norm(sv(fc, steer));
patN = 20*log10(abs(wN' * svAng) + eps);            % dB

% One-wavelength array, steered the same way.
arrayWide = phased.ULA(NumElements = N, ElementSpacing = spacingWide*lambda);   % 16 elements, one wavelength apart, m
svW = phased.SteeringVector(SensorArray = arrayWide, PropagationSpeed = c);
wW = svW(fc, steer) / norm(svW(fc, steer));
patW = 20*log10(abs(wW' * svW(fc, ang)) + eps);     % dB

% Local maxima in base MATLAB: samples higher than both neighbours, then only
% those within 8 dB of the pattern's peak.
isPeak = @(p) [false, (p(2:end-1) > p(1:end-2) & p(2:end-1) > p(3:end)), false];
peaksN = isPeak(patN) & patN > max(patN) - 8;       % lobe mask, half-wavelength
peaksW = isPeak(patW) & patW > max(patW) - 8;       % lobe mask, one wavelength

% Two tests: half a wavelength gives one lobe, at the steered angle; one
% wavelength adds a grating lobe at -30 degrees.
okOneLobe = nnz(peaksN) == 1 && ang(peaksN) == steer;
assert(okOneLobe, ...
    'The half-wavelength array should have one lobe, at 30 degrees. Look first at wN: it must be steered with sv(fc, steer).');
okGrating = nnz(peaksW) == 2 && any(ang(peaksW) == -30) && any(ang(peaksW) == steer);
assert(okGrating, ...
    'The one-wavelength array should have lobes at 30 and -30 degrees. Common mistake: steering it to broadside, where the grating lobes sit on ±90 degrees.');

b3Lobes = table(["λ/2"; "λ"], [nnz(peaksN); nnz(peaksW)], ...
    [string(listText(ang(peaksN))); string(listText(ang(peaksW)))], ...
    VariableNames = {'Spacing', 'LobesWithin8dB', 'Angles_deg'});
b3Lobes

% Put your Try-it prediction beside the grating lobe of a separate 0.75-wavelength array.
arrTry = phased.ULA(NumElements = N, ElementSpacing = 0.75*lambda);   % 16 elements, 0.75 wavelength apart, m
svTry = phased.SteeringVector(SensorArray = arrTry, PropagationSpeed = c);
wTry = svTry(fc, steer) / norm(svTry(fc, steer));
patTry = 20*log10(abs(wTry' * svTry(fc, ang)) + eps);
lobeTry = ang(isPeak(patTry) & patTry > max(patTry) - 8 & ang ~= steer);   % the lobe that is not at 30 degrees
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, string(listText(lobeTry)), predictionNote, ...
    VariableNames = {'MyPrediction', 'GratingLobe_deg_on_grid', 'Note'});
b3Prediction

% Both patterns on one axis.
figure(Name = 'Track 09 B3 - grating lobes', Color = 'w');
plot(ang, patN, ang, patW);                          % half-wavelength and one-wavelength
grid on;
ylim([-40 15]);
legend('d = 0.5 \lambda', sprintf('d = %.2f \\lambda', spacingWide), Location = 'south');
xlabel('angle from broadside (deg)');
ylabel('array factor (dB)');
title('B3: stretching the array past \lambda/2 aliases the beam');
%%
% At one wavelength the second lobe is as tall as the first: the array cannot 
% tell 30° from −30°, and half the power goes the wrong way. The half-wavelength 
% array has one lobe. Its beam is wider, but it points one way. The Try angle 
% is read on the 0.5° grid, so it can sit up to a quarter degree from the 
% exact value. Compare it with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["λ/2: one lobe, at 30°"; ...
     "λ: lobes at 30° and −30°"], ...
    ["1 lobe: 30"; "2 lobes: -30 30"], ...
    [string(nnz(peaksN)) + " lobe(s): " + listText(ang(peaksN)); string(nnz(peaksW)) + " lobe(s): " + listText(ang(peaksW))], ...
    [okOneLobe; okGrating], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep sv, a0, and w for B4.
clear b3Lobes b3Checks b3Prediction predictionNote okOneLobe okGrating ...
      steer spacingWide wN patN arrayWide svW wW patW isPeak peaksN peaksW ...
      arrTry svTry wTry patTry lobeTry svAng myPrediction
%% B4 — One RF chain, and where CSI comes from
% New words
% • Analogue weight: one fixed set of phase shifts behind a single RF chain; 
% it makes one beam at a time.
% Why it matters
% Hybrid beamforming puts a few RF chains behind many elements. Each chain 
% drives an analogue beam, and that beam only pays off if it points at the 
% user. The phone does not send the whole channel matrix back; it reports 
% compressed channel state information, including a CQI index from the TS 
% 38.214 tables. nrCQITables holds those tables. They are a menu of reported 
% values, not a beamformer.
% What to look for
% • In the one-RF-chain table: the power with the broadside weight from B2 
% for a wave from broadside and a wave from 30°.
% 
% • In the CQI table: the first rows of CQI table 1.
% Common mistakes
% Do not read a CQI index as a beam angle: it is a quality level (a modulation 
% and code rate).
% 
% Do not assume one RF chain keeps the full 10 log10(N) when its steer is 
% wrong.
% Try it (personal exploration)
% The broadside weight w from B2 is unit-norm. Predict the power |wᴴa|² it 
% collects from a wave arriving from broadside. Type it into myPrediction 
% before you run this section; the one-row table at the end shows it.

% Try it: type your prediction here (a power ratio, not dB) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — One RF chain, and where CSI comes from
fprintf("B4 — One RF chain, and where CSI comes from\n");   % banner title only; every number below goes into a table

% The B2 broadside weight as a single analogue beam, against two incoming waves.
aInc = sv(fc, 30);                     % a wave from 30 degrees, 16 × 1
onBore = abs(w' * a0)^2;               % power collected from broadside
offBore = abs(w' * aInc)^2;            % power collected from 30 degrees

% The CQI tables (TS 38.214 Section 5.2.2.1).
ct = nrCQITables;                      % four read-only tables
cqi1 = ct.CQITable1;                   % table 1: QPSK, 16QAM, 64QAM
rate1 = cqi1.TargetCodeRate(cqi1.CQIIndex == 1);   % CQI 1's target code rate (already divided by 1024)

% Three tests: the beam collects N from where it points, nothing from 30
% degrees (a null), and CQI table 1 has 16 rows with CQI 1 at 78/1024.
okOnBore = abs(onBore - N) < 1e-9;
assert(okOnBore, ...
    'The broadside weight should collect N from broadside. Look first at w: it must be a0 divided by its norm.');
okNull = offBore < 1e-9;
assert(okNull, ...
    'At half-wavelength spacing, 30 degrees is a null of the 16-element broadside beam. Common mistake: steering w to 30 degrees, not broadside.');
okCQI = height(cqi1) == 16 && abs(rate1 - 78/1024) < 1e-4;
assert(okCQI, ...
    'CQI table 1 should have 16 rows (CQI 0 to 15) and CQI 1 at 78/1024. Look first at the column: TargetCodeRate, not SpectralEfficiency.');

b4OneChain = table(["broadside"; "30°"], [onBore; offBore], 10*log10([onBore; offBore] + eps), ...
    VariableNames = {'IncomingWave', 'Power', 'Power_dB'});
b4OneChain
b4CQI = cqi1(1:5, :)                   % CQI 0 to 4 (CQI 0 is "out of range", shown as NaN)

% Put your Try-it prediction beside the broadside power.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, onBore, predictionNote, ...
    VariableNames = {'MyPrediction', 'OnBorePower', 'Note'});
b4Prediction
%%
% Pointed right, the single beam collects the full coherent gain. A wave from 
% 30° puts a quarter-turn step on the elements, and 16 such steps make four 
% full turns that cancel exactly: that direction is a null, so the beam collects 
% nothing. That is why the phone measures and reports, and the base station 
% re-aims. Compare the broadside power with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["Broadside power = N"; ...
     "30° wave on the broadside beam: a null"; ...
     "CQI table 1: 16 rows, CQI 1 at 78/1024"], ...
    [string(N); "< 1e-9"; "16 rows, " + string(round(78/1024, 4))], ...
    [string(round(onBore, 9)); string(offBore); string(height(cqi1)) + " rows, " + string(round(rate1, 4))], ...
    [okOnBore; okNull; okCQI], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The beats are done. Keep c, fc, lambda, N, ang, and listText for the Build it.
clear b4OneChain b4CQI b4Checks b4Prediction predictionNote okOnBore okNull okCQI ...
      aInc onBore offBore ct cqi1 rate1 sv a0 w myPrediction
%% Build it — Steer an 8-element array by hand
% Competency: build a steering vector by hand from the phase-step rule, turn 
% it into unit-norm weights, measure the gain in the steered direction, and 
% predict where a grating lobe lands when the spacing grows.
% Problem
% An 8-element ULA with half-wavelength spacing must point at 20°. Build its 
% steering vector from the Key relationships, make unit-norm weights, and 
% find the power gain in dB. Then find the phase step between neighbours in 
% degrees, and the angle of the grating lobe if the same array, still steered 
% to 20°, were stretched to 0.8-wavelength spacing.
% Allowed commands
% (0:N-1).'; exp(1j*x); sind and asind; norm and w' * a; abs(z)^2 and 10*log10; 
% ordinary arithmetic + - * / ^ and pi. The tables and the figure in the check 
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

% myN = 8;              % number of elements
% myTheta = 20;         % steering angle, degrees from broadside
% myD = 0.5;            % element spacing, wavelengths
% myDWide = 0.8;        % stretched spacing for Stage 4, wavelengths
%% Stage 1 check (given)
if ~exist('myN','var') || ~exist('myTheta','var') || ~exist('myD','var') || ~exist('myDWide','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal([myN myTheta myD myDWide], [8 20 0.5 0.8]);   % the values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the four lines you uncommented: 8, 20, 0.5, and 0.8.')
    stage1Checks = table("Given values", "8 20 0.5 0.8", listText([myN myTheta myD myDWide]), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the steering vector
% Fill the blanks: the element numbers as a column, then the steering vector 
% a_n = e^{−j2π (d/λ) n sin θ} from the Key relationships, with d/λ = myD.
% Pass: Stage 2 OK.

% myIdx = (0:___-1).';
% myA = exp(-1j*2*pi*___*myIdx*sind(___));
%% Stage 2 check (given; the check builds the vector by multiplying one phase step again and again, a different route from yours)
if ~exist('myIdx','var') || ~exist('myA','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: start at 1 and multiply by the same phase step, element by element.
    stepOracle = exp(-1j*2*pi*myD*sind(myTheta));                 % one neighbour-to-neighbour step
    aOracle = cumprod([1; repmat(stepOracle, myN - 1, 1)]);       % 1, step, step^2, ...
    sizeOk = isequal(size(myA), [myN 1]);
    okStage2 = [isequal(myIdx, (0:myN-1).') && sizeOk; ...
                sizeOk && max(abs(myA - aOracle)) < 1e-12];
    assert(okStage2(1), ...
        'myIdx or the size of myA is off. Look first at the transpose: the element numbers must be a column, 0 to myN - 1.')
    assert(okStage2(2), ...
        'myA is off. Common mistake: using sin with degrees; use sind, and check that the spacing is myD.')
    stage2Checks = table( ...
        ["Element numbers and size"; "Steering vector"], ...
        ["0 to " + string(myN - 1) + ", " + myN + " × 1"; "matches step^n"], ...
        [string(min(myIdx(:))) + " to " + string(max(myIdx(:))) + ", " + listText(size(myA)); string(okStage2(2))], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then weights and gain
% First type your prediction: the power gain in dB. Then fill the blanks: 
% unit-norm weights, the power collected in the steered direction, and that 
% power in dB.
% Pass: your prediction and your value appear side by side in a one-row table, 
% and Stage 3 OK.

% myPrediction = ___;
% myW = myA / norm(___);
% myGain = abs(myW' * ___)^2;
% myGainDB = 10*log10(___);
%% Stage 3 check (given; the check adds up the squared magnitudes, a different route from yours)
if ~exist('myW','var') || ~exist('myGain','var') || ~exist('myGainDB','var') || ~exist('myPrediction','var')
    disp('Stage 3 not done: type your prediction, fill the blanks, uncomment, and run.')
else
    % Your prediction beside your value, in one row.
    stage3Prediction = table(myPrediction, round(myGainDB, 2), ...
        VariableNames = {'MyPrediction', 'MyGainDB'});
    stage3Prediction

    % Different route: with w = a/‖a‖, |wᴴa|² = ‖a‖², the sum of |a_n|².
    gainOracle = sum(abs(aOracle).^2);

    % Three tests: unit norm, the gain, and the dB value.
    okStage3 = [isequal(size(myW), [myN 1]) && abs(sum(abs(myW).^2) - 1) < 1e-12; ...
                abs(myGain - gainOracle) < 1e-9; ...
                abs(myGainDB - 10*log10(gainOracle)) < 1e-9];
    assert(okStage3(1), ...
        'myW is not unit-norm. Look first at what you divided by: the norm of myA.')
    assert(okStage3(2), ...
        'myGain is off. Common mistake: forgetting the square, which gives an amplitude, not a power.')
    assert(okStage3(3), ...
        'myGainDB is off. Look first at the factor: a power ratio uses 10 log10.')
    stage3Checks = table( ...
        ["Unit-norm weights"; "Power gain"; "Power gain in dB"], ...
        ["sum |w|² = 1"; string(round(gainOracle, 4)); string(round(10*log10(gainOracle), 2)) + " dB"], ...
        [string(round(sum(abs(myW(:)).^2), 12)); string(round(myGain, 4)); string(round(myGainDB, 2)) + " dB"], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — the phase step and the grating lobe
% Fill the blanks: the phase step between neighbours in degrees (360 (d/λ) 
% sin θ), and the grating-lobe angle at the stretched spacing from sin θ_g 
% = sin θ_0 − λ/d (Key relationships).
% Pass: Stage 4 OK.

% myStepDeg = 360*___*sind(myTheta);
% myGrating = asind(sind(myTheta) - 1/___);
%% Stage 4 check (given; the check measures the steered array's response at your angle, a different route from yours)
if ~exist('myStepDeg','var') || ~exist('myGrating','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route 1: the phase step read from two neighbouring entries.
    stepDegOracle = abs(angle(aOracle(2)/aOracle(1)))*180/pi;
    % Different route 2: at a true grating lobe, the stretched array steered to
    % myTheta collects the full gain N from a wave at myGrating.
    idxW = (0:myN-1).';
    wWide = exp(-1j*2*pi*myDWide*idxW*sind(myTheta))/sqrt(myN);   % unit-norm, steered to myTheta
    lobePower = abs(wWide' * exp(-1j*2*pi*myDWide*idxW*sind(real(myGrating))))^2;

    % Two tests: the step, and a full-strength lobe at your angle (and not at the steered angle itself).
    okStage4 = [abs(myStepDeg - stepDegOracle) < 1e-9; ...
                isreal(myGrating) && abs(lobePower - myN) < 1e-6 && abs(myGrating - myTheta) > 1];
    assert(okStage4(1), ...
        'myStepDeg is off. Look first at the spacing: use myD, the half-wavelength spacing, here.')
    assert(okStage4(2), ...
        'myGrating is not a full-strength lobe. Common mistake: using myD instead of myDWide, which gives no real angle.')
    stage4Checks = table( ...
        ["Phase step, degrees"; "Full-strength lobe at myGrating"], ...
        [string(round(stepDegOracle, 2)) + "°"; "power " + string(myN)], ...
        [string(round(myStepDeg, 2)) + "°"; "power " + string(round(lobePower, 4))], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myW','var') || ~exist('myGainDB','var') || ~exist('myGrating','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Patterns of your weights at both spacings, computed here from the Key relationships.
    idxB = (0:myN-1).';
    patHalf = 20*log10(abs(myW' * exp(-1j*2*pi*myD*idxB*sind(ang))) + eps);         % dB, half wavelength
    wStretch = exp(-1j*2*pi*myDWide*idxB*sind(myTheta))/sqrt(myN);                     % same steer, stretched
    patWide = 20*log10(abs(wStretch' * exp(-1j*2*pi*myDWide*idxB*sind(ang))) + eps);  % dB, 0.8 wavelength
    [pkHalf, iHalf] = max(patHalf);

    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [all(abs(abs(myA) - 1) < 1e-12); ...
        abs(myGainDB - 10*log10(myN)) < 1e-9; ...
        abs(pkHalf - myGainDB) < 0.05 && abs(ang(iHalf) - myTheta) <= 0.5; ...
        abs(myStepDeg - 180*sind(myTheta)) < 1e-9; ...
        max(patHalf(abs(ang - myTheta) > 20)) < myGainDB - 10];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["Every element the same strength"; "Gain = 10 log10(N)"; "Pattern peak at myTheta with your gain"; ...
         "Half-wavelength step = 180 sin θ"; "Side lobes over 20° away: 10 dB below the peak"], ...
        ["|a_n| = 1"; string(round(10*log10(myN), 2)) + " dB"; string(myTheta) + "°, " + string(round(myGainDB, 2)) + " dB"; ...
         string(round(180*sind(myTheta), 2)) + "°"; "< " + string(round(myGainDB - 10, 2)) + " dB"], ...
        [string(listText(unique(round(abs(myA), 9)))); string(round(myGainDB, 2)) + " dB"; string(ang(iHalf)) + "°, " + string(round(pkHalf, 2)) + " dB"; ...
         string(round(myStepDeg, 2)) + "°"; string(round(max(patHalf(abs(ang - myTheta) > 20)), 2)) + " dB"], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: your beam at half a wavelength and stretched.
    figure(Name = 'Track 09 Build it - my beam', Color = 'w');
    plot(ang, patHalf, ang, patWide);                  % the two patterns
    hold on;
    xline([myTheta real(myGrating)], '--');            % steered angle and your grating-lobe angle
    hold off;
    grid on;
    ylim([-40 15]);
    legend('d = 0.5 \lambda', 'd = 0.8 \lambda', 'myTheta and myGrating', Location = 'south');
    xlabel('angle from broadside (deg)');
    ylabel('array factor (dB)');
    title(sprintf('My %d-element beam: gain %.2f dB at %d deg', myN, myGainDB, myTheta));
end
%%
% Your interpretation (write one or two sentences here): how much gain did 
% your 8 elements buy, and where did that power come from? What changed in 
% the pattern when the spacing grew to 0.8 wavelengths, and why is that a 
% problem for a base station?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; c, fc, lambda, N, ang, and listText stay in case you rerun a check.
clear okStage1 stage1Checks stepOracle aOracle sizeOk okStage2 stage2Checks ...
      stage3Prediction gainOracle okStage3 stage3Checks ...
      stepDegOracle idxW wWide lobePower okStage4 stage4Checks ...
      idxB patHalf wStretch patWide pkHalf iHalf buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B2)
% Work out the coherent gain, in dB, of 128 and of 256 half-wavelength elements 
% with unit-norm weights. How many dB does each doubling of N add, and why 
% does a large array cost more and more elements for each extra dB?
% 
% Your answer:
% E2 — New values (B3 and Build it)
% A 16-element array has 0.6-wavelength spacing. Is there a grating lobe (an 
% angle between −90° and 90°) when it is steered to 30°? When it is steered 
% to 60°? Give the angle where there is one, and work out the largest spacing 
% that keeps a 60° steer free of grating lobes.
% 
% Your answer:
% E3 — Diagnosis (B1)
% A classmate builds phased.ULA(NumElements = 16) with no ElementSpacing, 
% so it keeps the 0.5 m default. At 3 GHz, what is d/λ? How many grating lobes 
% does a broadside beam then have between −90° and 90°, and why does MATLAB 
% give no warning?
% 
% Your answer:
% E4 — Explanation (B2)
% A 100-element array is fed either 1 W per element or 1 W in total. For each, 
% give the gain over a single element fed 1 W, in dB, and the EIRP in W. What 
% is the EIRP ratio between the two, and which setup is the fair comparison 
% when the transmitter's power budget is fixed?
% 
% Your answer:
% E5 — Diagnosis (B1)
% Take the B1 steering vector of the 16-element half-wavelength array (phases 
% referenced to the array centre) and print diff(angle(a)) as the arrival 
% angle grows from 0°. At what angle does a jump first appear, and why exactly 
% there?
% 
% Your answer:
% E6 — Explanation (B4)
% With the broadside weight on 16 half-wavelength elements, a wave from 30° 
% gave a null. Find the smallest angle off broadside that gives a null (where 
% the elements' phases make exactly one full turn across the array). What 
% does that say about how precisely a single analogue beam must be aimed as 
% N grows?
% 
% Your answer:
%% Recap — Steer the Beam (album track 09)
% A phase ramp steers: give each element the conjugate of the phase a wave 
% from θ would put on it, and the copies add up in that direction. With the 
% total power fixed, N elements buy 10 log10(N) dB, taken from other directions. 
% Spacing above half a wavelength aliases into grating lobes. A single analogue 
% beam aimed the wrong way can collect nothing, so the phone measures and 
% reports, and the base station re-aims.
% Key relationships
% $$a_n(\theta) = e^{-j2\pi (d/\lambda)\, n\sin\theta},\qquad G_{\mathrm{dB}} = 10\log_{10}N,\qquad 
% \sin\theta_g = \sin\theta_0 \pm \lambda/d$$
% What this means in practice
% • phased.ULA takes its spacing in metres: set 0.5*lambda explicitly.
% 
% • phased.SteeringVector takes the array and the propagation speed; the frequency 
% goes in the call, sv(fc, ang).
% 
% • angle wraps at ±π: do not difference wrapped phases.
% 
% • Normalize the weights so the total power stays fixed; then the gain is 
% 10 log10(N).
% 
% • Keep the spacing at or below half a wavelength unless the steering range 
% is limited.
% 
% • You built an 8-element steering vector by hand, measured its gain, and 
% found where its grating lobe lands at 0.8-wavelength spacing.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 08 (track08/track08_clusters_and_angles_demo), why can a 2 × 2 channel 
% whose paths all come from one direction carry only one stream?
% 
% • Next in the album: track10 (Sound It Out).
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
% • + - * / ^ and exp(1j*x):
% 
% • (0:N-1).':
% 
% • sind and asind:
% 
% • norm and w' * a:
% 
% • abs(z)^2 and 10*log10:
% What I missed, and where to reread it
% 
