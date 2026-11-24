%% track08_clusters_and_angles_demo
%% Clusters and Angles (album track 08): CDL channels, antenna arrays, polarization, and rank
% In Taps in Time (album track 06), every echo had a time and a loudness. 
% The song's "last song" means that track; Learn the Channel (album track 
% 07) now sits between them. Now every echo has a direction too. Once echoes have directions, an antenna array can tell them 
% apart.
% 
% This demonstration builds a clustered delay line (CDL) channel, puts arrays 
% on both ends, measures how much power leaks between polarizations, and finds 
% out when a 2 × 2 array gives two streams and when it gives only one.
%% Guiding question
% When echoes arrive from different directions, how many independent streams 
% can a small antenna array carry, and what sets that number?
% This demonstration
% 1. B1 — Build a CDL channel and read its clusters: delays, powers, and angles.
% 
% 2. B2 — The arrays live on the channel: set their size and read how the 
% path gains grow.
% 
% 3. B3 — Polarization: XPR is a finite power ratio, so some power always 
% leaks.
% 
% 4. B4 — The rank trap: a channel from one direction is rank one, whatever 
% the array size.
% 
% 5. Build it — Build a two-path 2 × 2 channel by hand and watch its rank collapse 
% when the paths come from almost the same direction.
% Key relationships
% On a uniform linear array with half-wavelength spacing, a plane wave from 
% angle θ reaches element n with the phase
% 
% $$a_n(\theta) = e^{-j\pi n\sin\theta},\qquad n = 0, 1, \ldots, N-1$$
% 
% A channel built from paths p, each with gain g_p, arrival vector a_p, and 
% departure vector b_p, is
% 
% $$\mathbf{H} = \sum_p g_p\,\mathbf{a}_p\mathbf{b}_p^{T}$$
% 
% and the cross-polar leak is a power ratio: leak fraction = 10^(−XPR/10).
% Key ideas to remember
% • A CDL channel is a handful of clusters. Each cluster is a bundle of rays 
% (20 in TR 38.901) with a delay, a power, and four mean angles: departure 
% and arrival, in azimuth and zenith.
% 
% • TR 38.901 tabulates CDL-A to CDL-E. A, B, and C have no line of sight; 
% D and E start with a strong line-of-sight path.
% 
% • In the 5G Toolbox the arrays are properties of the channel: TransmitAntennaArray 
% and ReceiveAntennaArray take a Size of five numbers, [M N P Mg Ng].
% 
% • Element spacing is measured in wavelengths, and it sets how alike neighbouring 
% elements see the same wave.
% 
% • XPR, the cross-polarization power ratio, is finite. In nrCDLChannel the 
% default is 10 dB, the CDL-A cluster value, so the leak carries about a tenth 
% of the power.
% 
% • Rank is the number of usable parallel streams: the number of singular 
% values of H that are not negligible.
% 
% • More antennas do not always mean more streams. Paths from one narrow direction 
% line up the columns of H, and the matrix is close to rank one.
% Prerequisites
% • TDL channels, normalized delays, and average path gains (album track 06 
% Taps in Time, track06/track06_taps_in_time_demo).
% 
% • Complex numbers, phase, and the channel as a matrix (track 00 Fundamentals, 
% track00_fundamentals/p00b_softbits_and_dynamics_demo and track00_fundamentals/p00a_ofdm_and_cp_demo).
% 
% • Used here, not taught here: steering a beam with these phases is album 
% track 09 (Steer the Beam); measuring the channel to choose the rank is album 
% track 10 (Sound It Out).
% Words used in this demo
% • CDL (clustered delay line): a channel written as clusters of rays, each 
% with a delay, a power, and angles. Cluster: a group of rays from one scatterer.
% 
% • AoA, AoD, ZoA, ZoD: azimuth and zenith angles of arrival and departure, 
% in degrees.
% 
% • Antenna array: several antenna elements in a grid. Panel: one such grid; 
% a large array can have several panels.
% 
% • Polarization: the direction in which the electric field points. Co-polar: 
% same polarization at both ends. Cross-polar: the other one.
% 
% • XPR (cross-polarization power ratio): co-polar power over cross-polar 
% power, in dB.
% 
% • Singular values: the gains of the independent streams a matrix can carry, 
% largest first. Rank: how many of them are not negligible.
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
% • + - * / ^ and exp(1j*x) — Purpose: arithmetic, and a unit complex number 
% with phase x radians. Inputs: numbers. Outputs: the result.
% 
% • sind(x) — Purpose: the sine of an angle given in degrees. Inputs: degrees. 
% Outputs: a number from −1 to 1.
% 
% • [a; b] and v.' — Purpose: stack two numbers into a column; transpose without 
% conjugating. Inputs: numbers or a vector. Outputs: a column or a row.
% 
% • a*b.' — Purpose: the outer product of two columns, a matrix. Inputs: two 
% column vectors. Outputs: a matrix (here 2 × 2).
% 
% • s = svd(H) — Purpose: the singular values of a matrix, largest first. 
% Inputs: a matrix. Outputs: a column of non-negative numbers.
% 
% Commands you read in the given code
% • ch = nrCDLChannel(Name = value, ...) — Purpose: make a CDL channel. Inputs: 
% DelayProfile (such as "CDL-A"), DelaySpread (s), MaximumDopplerShift (Hz), 
% SampleRate (Hz), CarrierFrequency (Hz). Outputs: a channel object. Its TransmitAntennaArray 
% and ReceiveAntennaArray are structures with Size, ElementSpacing, and PolarizationAngles.
% 
% • s = info(ch) — Purpose: the channel's summary. Inputs: the channel object. 
% Outputs: a structure with PathDelays, AveragePathGains, AnglesAoA, AnglesAoD, 
% XPR, NumTransmitAntennas, and NumReceiveAntennas, among others.
% 
% • [out, pathGains] = ch(in) — Purpose: pass a waveform through the channel. 
% Inputs: one column per transmit antenna. Outputs: the faded waveform and 
% the path gains, samples × paths × transmit antennas × receive antennas.
% 
% • Figure family: figure(Name = ...), scatter, bar, xlabel, ylabel, title, 
% grid on, xticks, xticklabels — Purpose: draw points or bars, label them, 
% and name the figure. Inputs: data and text. Outputs: a figure. Used in B1 
% and Build it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, x(:), x(end), s.name, A(:, :, m, n) — 
% Purpose: read entries, count a range, reshape, read a field, pick one slice 
% of a many-dimensional array. Inputs: an array and positions. Outputs: the 
% entries.
% 
% • Compare and combine: == ~= < > <= >=, && ||, .* ./ .^ — Purpose: compare 
% values; and, or; work entry by entry. Inputs: numbers or arrays. Outputs: 
% true/false or numbers.
% 
% • Built-in helpers: abs, sum, max, prod, numel, size, isequal, squeeze, 
% complex, zeros, log10, round, det, norm, exist, isnan, NaN — Purpose: sizes, 
% sums, and dB; largest entries; shapes; empty arrays; determinant and norm; 
% look a name up. Inputs: numbers, arrays, or names. Outputs: numbers or true/false 
% (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, sprintf, and f = @(v) 
% ... — Purpose: write and join text, turn numbers into text, fill a format, 
% and make a one-line helper such as listText. Inputs: text, numbers, a format. 
% Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), fprintf, disp, clear, close all, rng — Purpose: show columns side 
% by side, stop with a hint when a check fails, print a banner or note, remove 
% variables or figures, repeat random values. Inputs: columns, a test and message, 
% text, names, a seed. Outputs: a shown table or line; an error if a check fails.
% Working status
% Status: unverified until M runs it in R2024b.
% 
% Teaching draft built to the track01 r03 template (track08 r01, 2026-11-20) 
% from the live track08_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox (R2023b 
% or later for the XPR field of info). The arrays are 5G Toolbox structures, 
% so the Phased Array System Toolbox is not needed here. A named profile's 
% clusters are read from info(ch); the PathDelays and AveragePathGains properties 
% apply only to DelayProfile = 'Custom'. Teaching demo, not production code; 
% not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year); the channels below also use their own default seed

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% The settings every beat uses.
fs = 15.36e6;       % sample rate, Hz (52 RBs at 15 kHz, Nfft = 1024, album track 02)
fc = 4e9;           % carrier frequency, Hz (a mid-band carrier)
%% B1 — Clusters and the channel object
% New words
% • Ray: one plane wave inside a cluster. TR 38.901 uses 20 rays per cluster, 
% spread a few degrees around the cluster's mean angles.
% Why it matters
% A CDL is not one delay tap with extra columns. It is a handful of clusters, 
% each a bundle of rays with a delay, a power, and angles. CDL-A to CDL-E are 
% the tabulated shapes, and nrCDLChannel is how the toolbox draws them. The 
% angles are the part a TDL (album track 06) left out, and they are what an 
% antenna array can use.
% What to look for
% • In the clusters table: the first four clusters' delays, powers, and arrival 
% and departure angles.
% 
% • In the figure: the clusters spread over delay and arrival angle, with 
% marker size showing power.
% Common mistakes
% Do not read one cluster as one ray: each cluster is 20 rays around its mean 
% angles.
% 
% Do not set PathDelays or AveragePathGains on a named profile: those properties 
% are for DelayProfile = 'Custom'. Read a named profile through info(ch).
% Try it (personal exploration)
% Each CDL-A cluster is 20 rays. Predict how many rays the whole CDL-A channel 
% draws. Type it into myPrediction before you run this section; the one-row 
% table at the end works it out from info(ch).

% Try it: type your prediction here (a number of rays) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Clusters and the channel object
fprintf("B1 — Clusters and the channel object\n");   % banner title only; every number below goes into a table

% A CDL-A channel at a mid-band carrier, read through info.
ch = nrCDLChannel(DelayProfile = "CDL-A", ...      % 23-cluster NLOS profile
                  DelaySpread = 30e-9, ...         % RMS delay spread, s
                  MaximumDopplerShift = 10, ...    % slow motion, Hz
                  SampleRate = fs, ...             % sample rate, Hz
                  CarrierFrequency = fc);          % carrier, Hz
ci = info(ch);                                      % cluster delays, powers, angles, and antenna counts
[pMax, iMax] = max(ci.AveragePathGains);           % strongest cluster: power (dB) and its number

% Two tests: CDL-A has 23 clusters, each with its own angles, and the strongest
% is cluster 2 at 0 dB, not the first one (TR 38.901 Table 7.7.1-1).
okClusters = numel(ci.PathDelays) == 23 && numel(ci.AnglesAoA) == 23 && numel(ci.AnglesAoD) == 23;
assert(okClusters, ...
    'CDL-A should have 23 clusters, each with its angles. Look first at DelayProfile: it should be "CDL-A".');
okStrongest = iMax == 2 && abs(pMax) < 0.05;
assert(okStrongest, ...
    'The strongest CDL-A cluster should be cluster 2 at 0 dB. Common mistake: reading the powers in linear units, not dB.');

% The first four clusters, side by side.
b1Clusters = table((1:4).', ci.PathDelays(1:4).'*1e9, ci.AveragePathGains(1:4).', ...
    ci.AnglesAoA(1:4).', ci.AnglesAoD(1:4).', ...
    VariableNames = {'Cluster', 'Delay_ns', 'Power_dB', 'AoA_deg', 'AoD_deg'});
b1Clusters

% Put your Try-it prediction beside the ray count.
tryRays = numel(ci.PathDelays)*20;     % clusters × 20 rays per cluster
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, tryRays, predictionNote, ...
    VariableNames = {'MyPrediction', 'Rays', 'Note'});
b1Prediction

% The clusters in delay and arrival angle: marker size grows with power.
pw = 10.^(ci.AveragePathGains/10);                 % cluster powers, linear
figure(Name = 'Track 08 B1 - CDL-A clusters', Color = 'w');
scatter(ci.PathDelays*1e9, ci.AnglesAoA, 20 + 300*pw/max(pw), 'filled');   % one marker per cluster
grid on;
xlabel('cluster delay (ns)');
ylabel('AoA (deg)');
title('B1: CDL-A clusters: delay, angle, power (marker size)');
%%
% The clusters spread out in delay and in angle at once: that is the picture 
% a TDL cannot draw. Several clusters share the same angles, so they look like 
% one direction to an array. As in TDL-A, the first cluster is not the strongest. 
% Compare the ray count with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["23 clusters, each with AoA and AoD"; ...
     "Strongest cluster is 2, at 0 dB"], ...
    ["23"; "cluster 2, 0 dB"], ...
    [string(numel(ci.PathDelays)); "cluster " + string(iMax) + ", " + string(pMax) + " dB"], ...
    [okClusters; okStrongest], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep ch: B2 puts arrays on it. Keep fs, fc, and listText.
clear b1Clusters b1Checks b1Prediction predictionNote okClusters okStrongest ...
      ci pMax iMax tryRays pw myPrediction
%% B2 — The arrays live on the channel
% New words
% • Size = [M N P Mg Ng]: M rows and N columns of elements, P polarizations 
% (1 or 2), and Mg × Ng panels.
% 
% • ElementSpacing = [λv λh dgv dgh]: vertical and horizontal element spacing, 
% then vertical and horizontal panel spacing, all in wavelengths.
% Why it matters
% In the 5G Toolbox CDL, the transmit and receive arrays are properties of 
% the channel, not a separate object you pass later. Changing the element 
% count changes the MIMO size of every path gain the channel draws. The channel 
% only uses what is set on it.
% What to look for
% • In the arrays table: the element counts info reports for each end, and 
% the size of the path gains.
% Common mistakes
% The counts come from the channel's summary, not the object.
% Try it (personal exploration)
% A base station panel has Size = [4 4 2 1 1]. Predict how many transmit antenna 
% elements info reports for it. Type it into myPrediction before you run this 
% section; the one-row table at the end reads it from a separate channel.

% Try it: type your prediction here (a number of elements) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — The arrays live on the channel
fprintf("B2 — The arrays live on the channel\n");   % banner title only; every number below goes into a table

% Put a 2 × 2 single-polarized array at the transmitter and a 2 × 1 at the receiver.
ch.TransmitAntennaArray.Size = [2 2 1 1 1];                % 2 rows × 2 columns, 1 polarization, 1 panel: 4 elements
ch.ReceiveAntennaArray.Size  = [2 1 1 1 1];                % 2 rows × 1 column, 1 polarization, 1 panel: 2 elements
ch.TransmitAntennaArray.ElementSpacing = [0.5 0.5 1.0 1.0];   % wavelengths: element vertical, horizontal; panel vertical, horizontal
ci = info(ch);
nTx = ci.NumTransmitAntennas;                              % transmit elements
nRx = ci.NumReceiveAntennas;                               % receive elements

% One input sample, one column per transmit element, just to read the path-gain size.
[~, pg] = ch(complex(zeros(1, nTx)));

% Two tests: the counts follow the Size vectors, and the path gains are
% samples × paths × transmit × receive.
okCounts = nTx == prod(ch.TransmitAntennaArray.Size) && nRx == prod(ch.ReceiveAntennaArray.Size);
assert(okCounts, ...
    'The element counts do not follow Size. Look first at the five numbers: every one of them multiplies the count.');
okShape = size(pg, 2) == numel(ci.PathDelays) && size(pg, 3) == nTx && size(pg, 4) == nRx;
assert(okShape, ...
    'The path gains are not paths × Tx × Rx. Common mistake: reading the dimensions in the order Rx then Tx.');

b2Arrays = table(nTx, nRx, string(listText(size(pg))), ...
    VariableNames = {'NumTransmitAntennas', 'NumReceiveAntennas', 'PathGainsSize'});
b2Arrays

% Put your Try-it prediction beside the count for a [4 4 2 1 1] panel, on a separate channel.
chTry = nrCDLChannel;                                      % a separate default CDL channel
chTry.TransmitAntennaArray.Size = [4 4 2 1 1];             % 4 × 4 elements, 2 polarizations, 1 panel
tryCount = info(chTry).NumTransmitAntennas;
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, tryCount, predictionNote, ...
    VariableNames = {'MyPrediction', 'NumTransmitAntennas', 'Note'});
b2Prediction
%%
% Setting Size on the channel changed every path gain it draws: one slice 
% per transmit and receive element pair, for every cluster. Nothing else needed 
% telling. Compare the panel's count with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Counts follow Size"; ...
     "Path gains: paths × Tx × Rx"], ...
    ["4 Tx, 2 Rx"; "23 × 4 × 2 after the sample dimension"], ...
    [string(nTx) + " Tx, " + string(nRx) + " Rx"; listText(size(pg))], ...
    [okCounts; okShape], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% B3 builds its own channel. Clear everything B2 made, and ch with it.
clear b2Arrays b2Checks b2Prediction predictionNote okCounts okShape ...
      ch ci nTx nRx pg chTry tryCount myPrediction
%% B3 — Polarization: XPR as a power ratio
% New words
% • Dual-polarized element: one element with two feeds at different polarization 
% angles. PolarizationAngles = [0 90] means vertical and horizontal.
% Why it matters
% XPR is the power that stays in the intended polarization against the power 
% that leaks into the other. It is a finite dB number, not infinite isolation. 
% Here both ends are one dual-polarized element (Size = [1 1 2 1 1]) set to 
% vertical and horizontal, so H is 2 × 2: co-polar on the diagonal, the leak 
% off it. With the default ±45° slants at the transmitter the two come out 
% equal on average, so vertical and horizontal make XPR visible.
% What to look for
% • In the polarization table: the XPR info reports, the measured co-polar 
% over cross-polar power, and the leak fraction.
% Common mistakes
% Do not treat dual polarization as two independent channels for free: the 
% leak is set by the XPR.
% 
% Do not read a 10 dB XPR as a 10 % amplitude leak: it is a power ratio of 
% 10, so the leak carries about a tenth of the power.
% Try it (personal exploration)
% CDL-C has a smaller XPR. Predict the leak fraction, cross-polar over co-polar 
% power, for CDL-C. Type it into myPrediction before you run this section; 
% the one-row table at the end reads CDL-C's XPR from info and works it out.

% Try it: type your prediction here (a fraction) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Polarization: XPR as a power ratio
fprintf("B3 — Polarization: XPR as a power ratio\n");   % banner title only; every number below goes into a table

% One dual-polarized element at each end, vertical and horizontal.
chP = nrCDLChannel(DelayProfile = "CDL-A", ...     % XPR 10 dB in the table
                   DelaySpread = 30e-9, ...        % RMS delay spread, s
                   MaximumDopplerShift = 10, ...   % slow motion, Hz
                   SampleRate = fs, ...            % sample rate, Hz
                   CarrierFrequency = fc);         % carrier, Hz
chP.TransmitAntennaArray.Size = [1 1 2 1 1];             % one element, two polarizations
chP.ReceiveAntennaArray.Size  = [1 1 2 1 1];             % one element, two polarizations
chP.TransmitAntennaArray.PolarizationAngles = [0 90];    % vertical and horizontal, degrees
chP.ReceiveAntennaArray.PolarizationAngles  = [0 90];    % vertical and horizontal, degrees
xprTable = info(chP).XPR;                                % the profile's XPR, dB

% 2000 samples (about 0.13 ms) of path gains; add up the co- and cross-polar power.
[~, pgP] = chP(complex(zeros(2000, 2)));                 % samples × paths × 2 Tx × 2 Rx
pCo = sum(abs(pgP(:, :, 1, 1)).^2 + abs(pgP(:, :, 2, 2)).^2, 'all');   % same polarization at both ends
pX  = sum(abs(pgP(:, :, 1, 2)).^2 + abs(pgP(:, :, 2, 1)).^2, 'all');   % the leak
measuredDB = 10*log10(pCo/pX);                           % measured co/cross ratio, dB (one draw)

% Two tests: info reports CDL-A's 10 dB, and on this draw the co-polar power
% clearly beats the leak (a finite ratio, not isolation).
okXPR = abs(xprTable - 10) < 1e-9;
assert(okXPR, ...
    'info should report XPR = 10 dB for CDL-A. Look first at DelayProfile: XPR comes from the profile''s table.');
okCoStronger = measuredDB > 3;
assert(okCoStronger, ...
    'The co-polar power did not beat the leak by 3 dB. Common mistake: leaving the default ±45° slants, which share the power equally.');

b3Polar = table(xprTable, measuredDB, pX/pCo, 10^(-xprTable/10), ...
    VariableNames = {'XPR_info_dB', 'Measured_dB', 'MeasuredLeakFraction', 'LeakFraction_fromXPR'});
b3Polar

% Put your Try-it prediction beside CDL-C's leak fraction.
tryXPR = info(nrCDLChannel(DelayProfile = "CDL-C")).XPR;   % CDL-C's XPR, dB
tryLeak = 10^(-tryXPR/10);                                % leak fraction
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, tryXPR, round(tryLeak, 3), predictionNote, ...
    VariableNames = {'MyPrediction', 'XPR_CDLC_dB', 'LeakFraction', 'Note'});
b3Prediction
%%
% The measured ratio lands near the table XPR but not exactly on it: one draw 
% of 23 clusters is a sample, not the average. Either way the leak is a finite 
% share of the power. Compare CDL-C's leak fraction with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["info XPR for CDL-A"; ...
     "Co-polar beats the leak by > 3 dB"], ...
    ["10 dB"; "> 3 dB"], ...
    [string(xprTable) + " dB"; string(round(measuredDB, 2)) + " dB"], ...
    [okXPR; okCoStronger], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything B3 made was only for B3.
clear b3Polar b3Checks b3Prediction predictionNote okXPR okCoStronger ...
      chP xprTable pgP pCo pX measuredDB tryXPR tryLeak myPrediction
%% B4 — Correlation and the rank trap
% New words
% • Steering vector: the column of phases a plane wave from one angle puts 
% on the array's elements (Key relationships).
% 
% • Outer product a*a': a matrix built from one column; it has rank one.
% Why it matters
% A large array does not guarantee a high-rank channel. If every path arrives 
% from one narrow direction, the columns of H line up, and extra antennas buy 
% beam gain but almost no extra streams. The toy below is the extreme case: 
% one direction, so H = a a' exactly. One CDL-A draw, whose clusters come 
% from many directions, is the comparison.
% What to look for
% • In the rank table: the two singular values of the toy and of one CDL-A 
% 2 × 2 snapshot, and each s2/s1.
% Common mistakes
% Do not read "2 × 2" as "two layers will always pass": the geometry decides 
% the rank.
% 
% Do not judge rank from one large singular value alone: compare the second 
% with the first.
% Try it (personal exploration)
% The toy channel is H = a a' with a the 2-element half-wavelength steering 
% vector at 20°. Predict its larger singular value (hint: every entry of a 
% has magnitude 1). Type it into myPrediction before you run this section; 
% the one-row table at the end shows it.

% Try it: type your prediction here (a number) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Correlation and the rank trap
fprintf("B4 — Correlation and the rank trap\n");   % banner title only; every number below goes into a table

% The toy: one plane wave from 20° on a 2-element half-wavelength array.
theta = 20;                                   % arrival angle, degrees
a = [1; exp(-1j*pi*sind(theta))];             % steering vector (Key relationships)
Hrank1 = a*a';                                % outer product: rank one
svals = svd(Hrank1);                          % singular values, largest first

% One CDL-A 2 × 2 snapshot: no motion, path gains summed over clusters (a
% narrowband H at one frequency), last sample.
ch2 = nrCDLChannel(DelayProfile = "CDL-A", ...    % clusters from many directions
                   DelaySpread = 30e-9, ...       % RMS delay spread, s
                   MaximumDopplerShift = 0, ...   % no motion, Hz
                   SampleRate = fs, ...           % sample rate, Hz
                   CarrierFrequency = fc);        % carrier, Hz
ch2.TransmitAntennaArray.Size = [1 2 1 1 1];      % 1 row × 2 columns: a horizontal pair, 1 polarization
ch2.ReceiveAntennaArray.Size  = [1 2 1 1 1];      % a horizontal pair, so the azimuth spread sets the rank
[~, pg2] = ch2(complex(zeros(8, 2)));             % 8 samples, 2 transmit columns
Hsnap = squeeze(sum(pg2(end, :, :, :), 2));       % 2 × 2: transmit × receive, paths summed
sv = svd(Hsnap);                                  % singular values, largest first

% Two tests: the toy is rank one to rounding, and the CDL-A snapshot is not
% (its second singular value is a clear share of the first).
okToy = svals(2) < 1e-12;
assert(okToy, ...
    'The toy should be rank one. Look first at Hrank1: it must be a times a'', one column times its own conjugate row.');
okCdlRank2 = sv(2)/sv(1) > 0.05;
assert(okCdlRank2, ...
    'The CDL-A snapshot looks rank one. Common mistake: summing over the antenna dimensions instead of over the paths (dimension 2).');

b4Rank = table(["Toy a a'"; "CDL-A snapshot"], [svals(1); sv(1)], [svals(2); sv(2)], ...
    [svals(2)/svals(1); sv(2)/sv(1)], ...
    VariableNames = {'Channel', 's1', 's2', 's2_over_s1'});
b4Rank

% Put your Try-it prediction beside the toy's larger singular value.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, svals(1), predictionNote, ...
    VariableNames = {'MyPrediction', 'Toy_s1', 'Note'});
b4Prediction
%%
% One direction gives one stream: the toy's second singular value is zero 
% to rounding, so the 2 × 2 array carries one layer. The CDL-A snapshot's clusters 
% come from many directions, so its second singular value is a real share 
% of the first. The Build it shows what happens in between. Compare the toy's 
% larger singular value with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["Toy is rank one (by construction: a a' always is)"; ...
     "CDL-A snapshot s2/s1 > 0.05"], ...
    ["s2 < 1e-12"; "> 0.05"], ...
    [string(svals(2)); string(round(sv(2)/sv(1), 4))], ...
    [okToy; okCdlRank2], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The beats are done. Keep fs, fc, and listText for the Build it.
clear b4Rank b4Checks b4Prediction predictionNote okToy okCdlRank2 ...
      theta a Hrank1 svals ch2 pg2 Hsnap sv myPrediction
%% Build it — Two paths, two antennas, and the rank
% Competency: build a 2 × 2 channel from two paths by hand, from their angles 
% and gains; read its rank from the singular values; and show that the rank 
% collapses when the two paths come from almost the same directions.
% Problem
% Two paths reach a 2-element half-wavelength receive array from a 2-element 
% half-wavelength transmit array. Path 1 leaves at 10° and arrives at 20°; 
% path 2 leaves at 50° and arrives at −40°, with gain 0.6 at 60° of phase. 
% Build H, find s2/s1, then move path 2 to within 3° of path 1 at both ends 
% and find s2/s1 again. Finally, work out what fraction of the power leaks 
% between polarizations at XPR = 7 dB.
% Allowed commands
% [a; b]; exp(1j*x); sind; ordinary arithmetic + - * / ^; the outer product 
% a*b.'; svd. The tables and the figure in the check sections and Stage 5 
% are given. All of these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myAoA = [20 -40];                     % arrival angles of paths 1 and 2, degrees
% myAoD = [10 50];                      % departure angles of paths 1 and 2, degrees
% myGain = [1, 0.6*exp(1j*pi/3)];       % complex path gains (path 2: 0.6 at 60 degrees of phase)
% myXPRdB = 7;                          % cross-polarization power ratio, dB (the CDL-C value)
%% Stage 1 check (given)
if ~exist('myAoA','var') || ~exist('myAoD','var') || ~exist('myGain','var') || ~exist('myXPRdB','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal(myAoA, [20 -40]) && isequal(myAoD, [10 50]) && numel(myGain) == 2 ...
        && abs(myGain(2) - 0.6*exp(1j*pi/3)) < 1e-12 && myXPRdB == 7;   % the values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the lines you uncommented: [20 -40], [10 50], the two gains, and 7.')
    stage1Checks = table("Given values", "AoA 20 -40, AoD 10 50, |g2| 0.6, XPR 7 dB", ...
        "AoA " + listText(myAoA) + ", AoD " + listText(myAoD) + ", |g2| " + string(abs(myGain(min(2, end)))) ...
        + ", XPR " + string(myXPRdB) + " dB", okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the four steering vectors
% Fill the blanks: each steering vector is [1; e^{−jπ sin θ}] (Key relationships), 
% with θ the path's arrival angle for the receive vectors and its departure 
% angle for the transmit vectors.
% Pass: Stage 2 OK.

% myA1 = [1; exp(-1j*pi*sind(___))];     % receive, path 1
% myA2 = [1; exp(-1j*pi*sind(___))];     % receive, path 2
% myB1 = [1; exp(-1j*pi*sind(___))];     % transmit, path 1
% myB2 = [1; exp(-1j*pi*sind(___))];     % transmit, path 2
%% Stage 2 check (given; the check builds each vector from the element numbers 0 and 1, a different route from yours)
if ~exist('myA1','var') || ~exist('myA2','var') || ~exist('myB1','var') || ~exist('myB2','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: a_n = exp(-j π n sin θ) for n = 0 and 1.
    steer = @(th) exp(-1j*pi*(0:1).'*sind(th));
    sizesOk = isequal(size(myA1), [2 1]) && isequal(size(myA2), [2 1]) && isequal(size(myB1), [2 1]) && isequal(size(myB2), [2 1]);
    okStage2 = [sizesOk; ...
                sizesOk && max(abs([myA1 - steer(myAoA(1)); myA2 - steer(myAoA(2))])) < 1e-12; ...
                sizesOk && max(abs([myB1 - steer(myAoD(1)); myB2 - steer(myAoD(2))])) < 1e-12];
    assert(okStage2(1), ...
        'Each steering vector should be a 2 × 1 column. Look first at the semicolon inside the brackets.')
    assert(okStage2(2), ...
        'A receive vector is off. Look first at which angle you used: the arrival angles, myAoA, for myA1 and myA2.')
    assert(okStage2(3), ...
        'A transmit vector is off. Common mistake: using the arrival angle for the transmit side; use myAoD.')
    stage2Checks = table( ...
        ["2 × 1 columns"; "Receive vectors"; "Transmit vectors"], ...
        ["2 1 each"; "match exp(-jπ n sin AoA)"; "match exp(-jπ n sin AoD)"], ...
        [listText(size(myA1)) + ", " + listText(size(myB1)); string(okStage2(2)); string(okStage2(3))], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then build H and read its rank
% First type your prediction: s2/s1 for the two well-separated paths, between 
% 0 (rank one) and 1 (two equal streams). Then fill the blanks: H as the sum 
% of the two paths' gain × receive vector × transmit row (Key relationships), 
% its singular values, and their ratio.
% Pass: your prediction and your value appear side by side in a one-row table, 
% and Stage 3 OK.

% myPrediction = ___;
% myH = myGain(1)*myA1*myB1.' + myGain(2)*___*___.';
% mySv = svd(___);
% myRatio = mySv(2) / mySv(1);
%% Stage 3 check (given; the check uses |det H| and the total power, a different route from yours)
if ~exist('myH','var') || ~exist('mySv','var') || ~exist('myRatio','var') || ~exist('myPrediction','var')
    disp('Stage 3 not done: type your prediction, fill the blanks, uncomment, and run.')
else
    % Your prediction beside your value, in one row.
    stage3Prediction = table(myPrediction, round(myRatio, 4), ...
        VariableNames = {'MyPrediction', 'MyRatio'});
    stage3Prediction

    % Different route: for a 2 × 2 matrix, s1·s2 = |det H| and s1² + s2² = the
    % sum of |entries|², so s1 and s2 follow without svd.
    oracleH = myGain(1)*steer(myAoA(1))*steer(myAoD(1)).' + myGain(2)*steer(myAoA(2))*steer(myAoD(2)).';
    pTot = sum(abs(oracleH(:)).^2);                       % s1² + s2²
    pDet = abs(det(oracleH));                             % s1 · s2
    oracleS1 = sqrt((pTot + sqrt(pTot^2 - 4*pDet^2))/2);  % larger root
    oracleS2 = pDet/oracleS1;

    % Three tests: H, the singular values, and the ratio.
    okStage3 = [isequal(size(myH), [2 2]) && max(abs(myH(:) - oracleH(:))) < 1e-12; ...
                numel(mySv) == 2 && abs(mySv(1) - oracleS1) < 1e-9 && abs(mySv(2) - oracleS2) < 1e-9; ...
                abs(myRatio - oracleS2/oracleS1) < 1e-9];
    assert(okStage3(1), ...
        'myH is off. Common mistake: using the conjugate transpose '' on the transmit vector; use .'' as in path 1.')
    assert(okStage3(2), ...
        'mySv is off. Look first at what you passed to svd: the matrix you just built.')
    assert(okStage3(3), ...
        'myRatio is off. Look first at the order: the second singular value over the first.')
    stage3Checks = table( ...
        ["H = sum of g a b.'"; "Singular values"; "s2 / s1"], ...
        ["2 × 2, matches"; listText(round([oracleS1 oracleS2], 4)); string(round(oracleS2/oracleS1, 4))], ...
        [listText(size(myH)) + ", " + string(okStage3(1)); listText(round(mySv(:).', 4)); string(round(myRatio, 4))], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — two paths from almost one direction, and the polarization leak
% Fill the blanks: move path 2 to 3° from path 1 at both ends (AoA and AoD 
% each 3° above path 1's), rebuild H, and find s2/s1. Then the leak fraction 
% from myXPRdB (Key relationships).
% Pass: Stage 4 OK.

% myA2n = [1; exp(-1j*pi*sind(myAoA(1) + ___))];
% myB2n = [1; exp(-1j*pi*sind(myAoD(1) + ___))];
% myHn = myGain(1)*myA1*myB1.' + myGain(2)*myA2n*myB2n.';
% mySvN = svd(myHn);
% myRatioN = mySvN(2) / mySvN(1);
% myLeak = 10^(-___/10);
%% Stage 4 check (given; the check uses |det H| again and 1 over the XPR as a power ratio, a different route from yours)
if ~exist('myHn','var') || ~exist('myRatioN','var') || ~exist('myLeak','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: the same |det| and power formula on the moved paths.
    oracleHn = myGain(1)*steer(myAoA(1))*steer(myAoD(1)).' + myGain(2)*steer(myAoA(1) + 3)*steer(myAoD(1) + 3).';
    pTotN = sum(abs(oracleHn(:)).^2);
    pDetN = abs(det(oracleHn));
    oracleS1n = sqrt((pTotN + sqrt(pTotN^2 - 4*pDetN^2))/2);
    oracleRatioN = (pDetN/oracleS1n)/oracleS1n;
    oracleLeak = 1/10^(myXPRdB/10);                      % cross over co power

    % Three tests: the moved H, its ratio, and the leak.
    okStage4 = [isequal(size(myHn), [2 2]) && max(abs(myHn(:) - oracleHn(:))) < 1e-12; ...
                abs(myRatioN - oracleRatioN) < 1e-9; ...
                abs(myLeak - oracleLeak) < 1e-12];
    assert(okStage4(1), ...
        'myHn is off. Look first at the offsets you added: 3 degrees at both ends.')
    assert(okStage4(2), ...
        'myRatioN is off. Common mistake: taking the ratio from mySv (the first H) instead of mySvN.')
    assert(okStage4(3), ...
        'myLeak is off. Look first at the sign of the exponent: a larger XPR must give a smaller leak.')
    stage4Checks = table( ...
        ["H with path 2 moved 3° from path 1"; "s2 / s1, close paths"; "Leak fraction at myXPRdB"], ...
        ["2 × 2, matches"; string(round(oracleRatioN, 5)); string(round(oracleLeak, 4))], ...
        [listText(size(myHn)) + ", " + string(okStage4(1)); string(round(myRatioN, 5)); string(round(myLeak, 4))], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myRatio','var') || ~exist('myRatioN','var') || ~exist('myLeak','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myRatioN < myRatio/100; ...
        abs(sum(mySv.^2) - sum(abs(myH(:)).^2)) < 1e-9; ...
        myRatioN < myRatio; ...
        myRatioN < 0.01; ...
        abs(10*log10(1/myLeak) - myXPRdB) < 1e-9];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["Close paths: s2/s1 below a hundredth of far-apart"; "s1² + s2² = total power"; "Close paths: smaller s2/s1"; ...
         "Close paths: near rank one (s2/s1 < 0.01)"; "10 log10(1/leak) = XPR"], ...
        ["less than " + string(round(myRatio/100, 5)); string(round(sum(abs(myH(:)).^2), 4)); "less than " + string(round(myRatio, 4)); ...
         "< 0.01"; string(myXPRdB) + " dB"], ...
        [string(round(myRatioN, 5)); string(round(sum(mySv.^2), 4)); string(round(myRatioN, 5)); ...
         string(round(myRatioN, 5)); string(round(10*log10(1/myLeak), 4)) + " dB"], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: s2/s1 for the two geometries.
    figure(Name = 'Track 08 Build it - my rank', Color = 'w');
    bar([myRatio myRatioN]);                           % one bar per geometry
    xticks(1:2);
    xticklabels({'paths far apart', 'paths 3° apart'});
    grid on;
    ylabel('s_2 / s_1');
    title(sprintf('Rank from geometry: s2/s1 = %.3f vs %.4f', myRatio, myRatioN));
end
%%
% Your interpretation (write one or two sentences here): how many streams 
% could this 2 × 2 channel carry with the paths far apart, and with them 3° 
% apart? What changed in H to cause it, and what share of the power would cross 
% between polarizations at 7 dB?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; fs, fc, and listText stay in case you rerun a check.
clear okStage1 stage1Checks steer sizesOk okStage2 stage2Checks ...
      stage3Prediction oracleH pTot pDet oracleS1 oracleS2 okStage3 stage3Checks ...
      oracleHn pTotN pDetN oracleS1n oracleRatioN oracleLeak okStage4 stage4Checks buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (Build it)
% In your Build it, move path 2 to 10° and then 30° from path 1 at both ends 
% (same gains) and work out s2/s1 each time. Put them in order with your 3° 
% value and your far-apart value. Roughly how does s2/s1 grow while the separation 
% is small, and what does that say about two users or two paths only a few 
% degrees apart?
% 
% Your answer:
% E2 — New values (B3)
% Work out the leak fraction for XPR = 3 dB and for XPR = 20 dB. For each, 
% say whether the two polarizations behave like two nearly separate streams 
% or like one shared one, and why a dual-polarized element can help rank even 
% when every path comes from one direction.
% 
% Your answer:
% E3 — Diagnosis (B2)
% A base station uses TransmitAntennaArray.Size = [4 2 2 1 3] with ElementSpacing 
% = [0.5 0.5 2 1] at 4 GHz. How many transmit elements does info report? 
% Which of the two panel spacings does this array actually use, and what is 
% it in metres? Say why the other one does not matter here.
% 
% Your answer:
% E4 — Explanation (B4)
% The toy H = a a' is 2 × 2 but rank one. Explain in terms of its columns why 
% a second stream has nowhere to go. A transmitter that sends one stream along 
% the best direction gets a power gain of s1²: what is that in dB for the toy, 
% and where does it come from?
% 
% Your answer:
% E5 — Diagnosis (B1)
% A classmate sees that CDL-A's first cluster arrives at delay 0 and says "that 
% is the line-of-sight path". From the B1 clusters table, how many dB below 
% cluster 2 is cluster 1? What would a line-of-sight first path look like in 
% that table instead?
% 
% Your answer:
% E6 — Explanation (Key relationships)
% Work out the phase step between neighbouring elements for a wave from 20° 
% with half-wavelength spacing, and again with one-wavelength spacing. Which 
% spacing makes two neighbouring elements see the wave more alike? Explain 
% why closely spaced elements make it harder to tell two paths apart, and so 
% lower the rank.
% 
% Your answer:
%% Recap — Clusters and Angles (album track 08)
% A CDL channel is a handful of clusters, each a bundle of rays with a delay, 
% a power, and angles at both ends. The arrays sit on the channel, so their 
% size and spacing shape every path gain. Polarization adds a second, leaky 
% dimension set by the XPR. The rank of H, the number of usable streams, comes 
% from the geometry: paths from many directions give several streams, paths 
% from one direction give one.
% Key relationships
% $$a_n(\theta) = e^{-j\pi n\sin\theta},\qquad \mathbf{H} = \sum_p g_p\,\mathbf{a}_p\mathbf{b}_p^{T},\qquad 
% \text{leak} = 10^{-\mathrm{XPR}/10}$$
% What this means in practice
% • Read a named CDL profile's clusters, angles, XPR, and antenna counts through 
% info(ch).
% 
% • Set the arrays on the channel: Size takes five numbers and ElementSpacing 
% four.
% 
% • XPR is a finite power ratio: 10 dB leaves about a tenth of the power in 
% the other polarization.
% 
% • Judge rank by s2/s1, not by the matrix size.
% 
% • Paths a few degrees apart line up the columns of H and leave it close 
% to rank one.
% 
% • You built a 2 × 2 channel from two paths by hand, read its rank from svd, 
% and watched it collapse when the paths moved together.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 06 (track06/track06_taps_in_time_demo), what does DelaySpread do to 
% a profile's tabulated normalized delays?
% 
% • Next in the album: track09 (Steer the Beam).
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
% • sind:
% 
% • [a; b] and .':
% 
% • a*b.':
% 
% • svd:
% What I missed, and where to reread it
% 
