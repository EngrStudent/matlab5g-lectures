%% track10_sound_it_out_demo
%% Sound It Out (album track 10): SRS up, CSI-RS down, reciprocity, and calibration
% In Steer the Beam, the base station aimed at your phone. To aim, it needs 
% the channel H. Who measures it? Either the base station listens to the phone 
% going up, or the phone measures coming down and reports.
% 
% This demonstration does both: it puts a sounding reference signal (SRS) 
% on the uplink grid and a CSI reference signal (CSI-RS) on the downlink grid, 
% checks that one channel object gives the same channel both ways, and then 
% breaks that agreement with mismatched radios and calibrates it back.
%% Guiding question
% When can a base station use the channel it hears from the phone to send 
% back to the phone, and what has to be fixed first?
% This demonstration
% 1. B1 — Sounding up: an SRS on a comb in the last symbol of an uplink slot.
% 
% 2. B2 — Measuring down: a CSI-RS on the downlink grid, and how its density 
% sets its RE count.
% 
% 3. B3 — Reciprocity: one TDL channel, swapped ends, and the transpose.
% 
% 4. B4 — Break it with mismatched radio chains, then calibrate both ends.
% 
% 5. Build it — Count an SRS comb by hand, then calibrate a toy TDD link.
% Key relationships
% In TDD the air is reciprocal: the uplink channel is the plain transpose 
% of the downlink channel,
% 
% $$\mathbf{H}_{\mathrm{UL}} = \mathbf{H}_{\mathrm{DL}}^{T}\quad(\text{transpose, not conjugate})$$
% 
% but each radio's transmit chain t and receive chain r add their own gains:
% 
% $$\mathbf{H}_{\mathrm{DL}} = \mathrm{diag}(\mathbf{r}_{\mathrm{UE}})\,\mathbf{H}\,\mathrm{diag}(\mathbf{t}_{\mathrm{gNB}}),\qquad 
% \mathbf{H}_{\mathrm{UL}} = \mathrm{diag}(\mathbf{r}_{\mathrm{gNB}})\,\mathbf{H}^{T}\,\mathrm{diag}(\mathbf{t}_{\mathrm{UE}})$$
% 
% An SRS on a comb of size K_TC over m RBs uses m × 12 / K_TC REs per symbol.
% Key ideas to remember
% • The phone sends an SRS so the base station can measure the uplink channel 
% per port across the band.
% 
% • The SRS sits on a comb: K_TC = 2, 4, or 8 puts it on every second, fourth, 
% or eighth subcarrier, so several phones can share the same symbols on different 
% teeth of the comb.
% 
% • The base station sends a CSI-RS so the phone can measure the downlink 
% and report CSI. Its row and density set where it goes and how many REs it 
% uses per resource block.
% 
% • In TDD both directions share one carrier, so the air is reciprocal: H_UL 
% = H_DLᵀ, a plain transpose.
% 
% • In FDD the two directions use carriers too far apart for the channels 
% to match, so reciprocity fails and the phone must measure the CSI-RS and 
% report.
% 
% • Real radios break the transpose: each node's transmit chain differs from 
% its own receive chain, so the measured channels disagree even though the 
% air agrees.
% 
% • Calibration divides those chain gains back out, so the downlink again 
% matches the uplink transposed; B4 tests which end has to be corrected.
% Prerequisites
% • The channel as a matrix H, transmit by receive antennas (album track 08 
% Clusters and Angles, track08/track08_clusters_and_angles_demo), and beams 
% that need it (album track 09 Steer the Beam, track09/track09_steer_the_beam_demo).
% 
% • Pilots and channel estimates from known REs (album track 07 Learn the 
% Channel, track07/track07_learn_the_channel_demo); TDL channels (album track 
% 06 Taps in Time, track06/track06_taps_in_time_demo).
% 
% • The resource grid (track 00 Fundamentals, track00_fundamentals/p00a_ofdm_and_cp_demo).
% 
% • Used here, not taught here: what the phone reports from the CSI-RS (CQI 
% and its target of about one in ten) is album track 11 (One in Ten).
% Words used in this demo
% • SRS (sounding reference signal): a known uplink signal the phone sends 
% so the base station can measure the uplink channel.
% 
% • CSI-RS (channel state information reference signal): a known downlink 
% signal the base station sends so the phone can measure and report.
% 
% • Comb, K_TC: the SRS uses every K_TC-th subcarrier. C_SRS: the bandwidth 
% index that sets how many RBs are sounded.
% 
% • CSI-RS row and density: the row of the TS 38.211 table sets the ports 
% and pattern; the density is REs per RB per port ('one', 'three', ...).
% 
% • TDD (time division duplex): uplink and downlink take turns on the same 
% carrier. FDD (frequency division duplex): they use two carriers at once.
% 
% • Reciprocity: the air channel one way is the transpose of the other way. 
% Calibration: removing the radio chains' gains so the transpose holds again.
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
% • + - * / and ./ — Purpose: arithmetic, and entry-by-entry division of two 
% vectors. Inputs: numbers or vectors. Outputs: the result.
% 
% • [a; b] and a*exp(1j*deg*pi/180) — Purpose: stack numbers into a column; 
% a complex gain of size a at deg degrees. Inputs: numbers. Outputs: a column; 
% a complex number.
% 
% • diag(v) — Purpose: a square matrix with v on its diagonal, used for per-antenna 
% gains. Inputs: a vector. Outputs: a matrix.
% 
% • H.' and A*B — Purpose: the plain transpose (no conjugate); matrix product. 
% Inputs: matrices. Outputs: a matrix.
% 
% • norm(A, 'fro') — Purpose: the size of a matrix, the square root of the 
% sum of |entries|². Inputs: a matrix. Outputs: a non-negative number.
% 
% Commands you read in the given code
% • carrier = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52, NCellID 
% = 1) — Purpose: the carrier. Inputs: spacing (kHz), RBs, cell ID. Outputs: 
% a configuration object.
% 
% • grid = nrResourceGrid(carrier) — Purpose: an empty slot grid. Inputs: 
% the carrier. Outputs: subcarriers × 14 symbols of zeros.
% 
% • nrSRSConfig, nrSRSIndices(carrier, srs), nrSRS(carrier, srs) — Purpose: 
% configure the SRS (NumSRSPorts, SymbolStart, NumSRSSymbols, KTC, CSRS), find 
% its REs, make its symbols. Inputs: the carrier and the configuration. Outputs: 
% a configuration object; a column of indices; a column of symbols. Used in 
% B1.
% 
% • nrCSIRSConfig, nrCSIRSIndices(carrier, csirs), nrCSIRS(carrier, csirs) 
% — Purpose: the same for the CSI-RS (RowNumber, Density, SymbolLocations, 
% SubcarrierLocations, NumRB). Used in B2.
% 
% • tdl = nrTDLChannel(Name = value, ...), [out, pathGains] = tdl(in), swapTransmitAndReceive(tdl) 
% — Purpose: a TDL channel; pass samples through it; reverse its link direction. 
% Inputs: DelayProfile, DelaySpread (s), MaximumDopplerShift (Hz), SampleRate 
% (Hz), antenna counts, NormalizeChannelOutputs; one column per transmit antenna. 
% Outputs: the channel object; the faded samples and path gains, samples × 
% paths × transmit × receive. Used in B3.
% 
% • Figure family: figure(Name = ...), imagesc, axis xy, colorbar, bar, xticks, 
% xticklabels, xlabel, ylabel, title — Purpose: draw a grid or bars, label 
% them, and name the figure. Inputs: data and text. Outputs: a figure. Used 
% in B1 and Build it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, a:b:c, x(:), A(idx) = v, A(end, :, :, :), 
% s.name — Purpose: read or write entries, count a range with a step, pick 
% one slice, read a field. Inputs: an array and positions. Outputs: the entries.
% 
% • Compare and combine: == < > <=, &&, .* ./ — Purpose: compare values; and; 
% work entry by entry. Inputs: numbers or arrays. Outputs: true/false or numbers.
% 
% • Built-in helpers: abs, angle, max, numel, size, isequal, squeeze, sum, diff, mod, find, ind2sub, 
% permute, complex, zeros, unique, round, eps, pi, exist, isnan, NaN — Purpose: 
% sizes, counts, sums, reorder dimensions, empty arrays, look a name up. Inputs: 
% numbers, arrays, or names. Outputs: numbers or true/false (NaN means "no 
% number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, sprintf, and f = @(v) 
% ... — Purpose: write and join text, turn numbers into text, fill a format, 
% and make a one-line helper such as listText or ce. Inputs: text, numbers, 
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
% Teaching draft built to the track01 r03 template (track10 r01, 2026-11-20) 
% from the live track10_demo.m on main 2881359. No run of this file has been 
% recorded yet; a clean run is not a teaching sign-off, so read each table and 
% figure against its interpretation sentence. Requires the 5G Toolbox (R2021a 
% or later for swapTransmitAndReceive). The calibration in B4 and the Build 
% it is a textbook teaching model in plain matrix algebra, not a toolbox API. 
% Teaching demo, not production code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year); the TDL uses its own default seed

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% ce makes a complex gain from a size and a phase in degrees; B4 and the Build it use it.
ce = @(a, deg) a*exp(1j*deg*pi/180);
%% B1 — Sounding up: the SRS on a comb
% New words
% • Comb offset: which tooth of the comb (0 to K_TC − 1) one phone uses.
% Beat-only commands
% • nrSRSConfig, nrSRSIndices, nrSRS — see Key code terms (read in the given 
% code).
% Why it matters
% The phone sends a known SRS so the base station can measure the uplink 
% channel, port by port, across the band. The SRS sits on a comb: with K_TC 
% = 2 it uses every second subcarrier, so a second phone can sound the same 
% symbol on the other tooth. That is why a picture of an SRS looks striped, 
% not solid. C_SRS = 3 (with B_SRS = 0) sounds 16 RBs.
% What to look for
% • In the SRS table: the number of SRS REs, the comb size, the symbol it 
% sits in, and the step between occupied subcarriers.
% 
% • In the figure: stripes in the last symbol only.
% Common mistakes
% Do not expect the SRS on every subcarrier: the comb leaves gaps for other 
% phones.
% 
% Do not count the SRS against the whole 52-RB carrier: C_SRS sets how many 
% RBs are sounded.
% Try it (personal exploration)
% Predict the number of SRS REs in the same 16 RBs if the comb is K_TC = 4 
% instead of 2. Type it into myPrediction before you run this section; the 
% one-row table at the end measures it on a separate SRS configuration.

% Try it: type your prediction here (REs) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Sounding up: the SRS on a comb
fprintf("B1 — Sounding up: the SRS on a comb\n");   % banner title only; every number below goes into a table

% The uplink carrier: 15 kHz spacing, 52 RBs, cell ID 1.
carrierUL = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52, NCellID = 1);   % kHz, RBs, cell ID

% One SRS port in the last symbol, on a comb-2, sounding the C_SRS = 3 bandwidth.
srs = nrSRSConfig;
srs.NumSRSPorts   = 1;    % one antenna port
srs.SymbolStart   = 13;   % last symbol of the slot (0-based), a common placement
srs.NumSRSSymbols = 1;    % one symbol
srs.KTC           = 2;    % comb size: every second subcarrier
srs.CSRS          = 3;    % row of the TS 38.211 C_SRS table: with B_SRS = 0 (the default), 16 RBs

srsInd = nrSRSIndices(carrierUL, srs);   % linear indices of the SRS REs in the slot grid
srsSym = nrSRS(carrierUL, srs);          % the SRS symbols, one per index
gridUL = nrResourceGrid(carrierUL);      % 624 subcarriers × 14 symbols of zeros
gridUL(srsInd) = srsSym;                 % place the SRS

% Where the SRS landed: its subcarriers (1-based rows) and its symbols (columns).
[srsSc, srsSymb] = ind2sub(size(gridUL), double(srsInd));
srsStep = unique(diff(srsSc));            % step between occupied subcarriers

% Three tests: the RE count, the symbol, and the comb step.
okSrsCount = numel(srsInd) == 16*12/srs.KTC;
assert(okSrsCount, ...
    'The SRS should use 16 RBs × 12 subcarriers / K_TC REs. Look first at srs.CSRS and srs.KTC.');
okSrsSymbol = isequal(unique(srsSymb), srs.SymbolStart + 1);
assert(okSrsSymbol, ...
    'The SRS should sit only in the last symbol. Look first at srs.SymbolStart: it is 0-based, so 13 is column 14.');
okSrsComb = isequal(srsStep, srs.KTC);
assert(okSrsComb, ...
    'Occupied subcarriers should be K_TC apart. Common mistake: expecting the SRS on every subcarrier.');

b1Srs = table(numel(srsInd), srs.KTC, unique(srsSymb), listText(srsStep), ...
    VariableNames = {'SRS_REs', 'KTC', 'Symbol_1based', 'SubcarrierStep'});
b1Srs

% Put your Try-it prediction beside the count on a separate comb-4 SRS.
srsTry = nrSRSConfig(NumSRSPorts = 1, SymbolStart = 13, NumSRSSymbols = 1, KTC = 4, CSRS = 3);   % as srs, but comb-4
tryCount = numel(nrSRSIndices(carrierUL, srsTry));   % REs
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, tryCount, predictionNote, ...
    VariableNames = {'MyPrediction', 'SRS_REs_KTC4', 'Note'});
b1Prediction

% The last five symbols of the uplink grid: the SRS stripes in symbol 14.
figure(Name = 'Track 10 B1 - SRS comb', Color = 'w');
imagesc(10:14, 1:size(gridUL, 1), abs(gridUL(:, 10:14)));   % magnitude of the last five symbols
axis xy;
colorbar;
xlabel('OFDM symbol (1-based)');
ylabel('subcarrier');
title(sprintf('B1: SRS comb-%d in the last symbol', srs.KTC));
%%
% The SRS fills 96 REs: 16 RBs × 12 subcarriers, every second one, all in 
% symbol 14. The gaps are not wasted: another phone can sound on the other 
% tooth of the comb in the same symbol, and the base station tells them apart 
% by their subcarriers. Compare the comb-4 count with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["SRS RE count = 16 × 12 / K_TC"; ...
     "SRS only in the last symbol"; ...
     "Comb step = K_TC"], ...
    [string(16*12/srs.KTC); string(srs.SymbolStart + 1); string(srs.KTC)], ...
    [string(numel(srsInd)); listText(unique(srsSymb)); listText(srsStep)], ...
    [okSrsCount; okSrsSymbol; okSrsComb], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep carrierUL: nothing later needs the SRS itself.
clear b1Srs b1Checks b1Prediction predictionNote okSrsCount okSrsSymbol okSrsComb ...
      srs srsInd srsSym gridUL srsSc srsSymb srsStep srsTry tryCount myPrediction
%% B2 — Measuring down: the CSI-RS
% New words
% • Density: how many CSI-RS REs each port uses in each resource block.
% Beat-only commands
% • nrCSIRSConfig, nrCSIRSIndices, nrCSIRS — see Key code terms (read in 
% the given code).
% Why it matters
% The downlink measurement uses a different known signal, the CSI-RS, sent 
% by the base station so the phone can measure and report CSI. It is not the 
% SRS run backwards: it has its own sequence and its own placement table. 
% The row of the TS 38.211 table sets the number of ports and the pattern; 
% the density says how often it appears in each resource block. Row 2 is one 
% port, and with density 'one' it takes one RE per RB.
% What to look for
% • In the CSI-RS table: the RE count, the row, the density, and the symbol 
% it sits in.
% Common mistakes
% Do not feed an SRS configuration to a CSI-RS function: each signal has its 
% own object.
% 
% Do not count the CSI-RS per subcarrier: density counts REs per RB per port.
% Try it (personal exploration)
% Predict the number of CSI-RS REs over the same 52 RBs for row 1 with density 
% 'three' (row 1 is also one port). Type it into myPrediction before you run 
% this section; the one-row table at the end measures it on a separate CSI-RS 
% configuration.

% Try it: type your prediction here (REs) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Measuring down: the CSI-RS
fprintf("B2 — Measuring down: the CSI-RS\n");   % banner title only; every number below goes into a table

% The downlink carrier: the same numerology as the uplink.
carrierDL = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52, NCellID = 1);   % kHz, RBs, cell ID

% One CSI-RS port, row 2, density 'one', in symbol 4 (0-based) over all 52 RBs.
csirs = nrCSIRSConfig;
csirs.RowNumber = 2;               % row of the TS 38.211 CSI-RS location table: 1 port
csirs.Density   = 'one';           % one RE per RB per port
csirs.SymbolLocations     = 4;     % first OFDM symbol of the pattern, 0-based
csirs.SubcarrierLocations = 0;     % subcarrier inside the RB, 0-based
csirs.NumRB = 52;                  % RBs spanned

csirsInd = nrCSIRSIndices(carrierDL, csirs);   % linear indices of the CSI-RS REs
csirsSym = nrCSIRS(carrierDL, csirs);          % the CSI-RS symbols
gridDL = nrResourceGrid(carrierDL);            % 624 × 14 zeros
gridDL(csirsInd) = csirsSym;                   % place the CSI-RS
[~, csirsSymb] = ind2sub(size(gridDL), double(csirsInd));   % symbol (column) of each RE

% Two tests: the RE count is density × RBs, and the symbol is 5 (1-based).
okCsiCount = numel(csirsInd) == 1*csirs.NumRB;
assert(okCsiCount, ...
    'Row 2 with density one should give one RE per RB, 52 in all. Look first at csirs.Density and csirs.NumRB.');
okCsiSymbol = isequal(unique(csirsSymb), csirs.SymbolLocations + 1);
assert(okCsiSymbol, ...
    'The CSI-RS should sit in symbol 5 (1-based). Look first at csirs.SymbolLocations: it is 0-based.');

b2Csirs = table(numel(csirsInd), csirs.RowNumber, string(csirs.Density), listText(unique(csirsSymb)), ...
    VariableNames = {'CSIRS_REs', 'Row', 'Density', 'Symbol_1based'});
b2Csirs

% Put your Try-it prediction beside the count for a separate row-1, density-'three' CSI-RS.
csirsTry = nrCSIRSConfig(RowNumber = 1, Density = 'three', SymbolLocations = 4, ...
    SubcarrierLocations = 0, NumRB = 52);
tryCount = numel(nrCSIRSIndices(carrierDL, csirsTry));   % REs
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, tryCount, predictionNote, ...
    VariableNames = {'MyPrediction', 'CSIRS_REs_Row1', 'Note'});
b2Prediction
%%
% The CSI-RS takes 52 REs: one per RB in one symbol. That is sparser than 
% the SRS in B1, and it is a different signal with its own table, sent the 
% other way. From it the phone estimates the downlink channel and reports 
% what it can carry (album track 11). Compare the row-1 count with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["CSI-RS RE count = density × RBs"; ...
     "CSI-RS in symbol 5"], ...
    [string(csirs.NumRB); string(csirs.SymbolLocations + 1)], ...
    [string(numel(csirsInd)); listText(unique(csirsSymb))], ...
    [okCsiCount; okCsiSymbol], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the CSI-RS or the carriers.
clear b2Csirs b2Checks b2Prediction predictionNote okCsiCount okCsiSymbol ...
      csirs csirsInd csirsSym gridDL csirsSymb csirsTry tryCount myPrediction carrierDL carrierUL
%% B3 — Reciprocity: one channel, swapped ends
% New words
% • Path gains: the complex gain of each path between each transmit and each 
% receive antenna, over time.
% Beat-only commands
% • permute(A, [1 2 4 3]) — reorder an array's dimensions; here, swap dimensions 
% 3 and 4 (transmit and receive).
% Why it matters
% In TDD the uplink and the downlink take turns on the same carrier, so the 
% air between two antennas is the same both ways: H_UL = H_DLᵀ, a plain transpose, 
% not the conjugate transpose. nrTDLChannel can model that with one object: 
% swapTransmitAndReceive swaps the roles of its antennas without changing 
% the fading. The documentation asks for NormalizeChannelOutputs = false before 
% the swap. The setting matters for the received waveforms (E3), not for the 
% path gains compared here.
% What to look for
% • In the reciprocity table: the path-gain sizes before and after the swap, 
% the antenna counts that info reports, and the relative residual after the 
% transpose.
% Common mistakes
% Do not swap the antenna counts by hand and build a new channel: that is 
% a new random channel, not the same air reversed.
% 
% Do not compare with the conjugate transpose: reciprocity is a plain transpose, 
% .' in MATLAB.
% 
% Do not leave NormalizeChannelOutputs at its default (true) before the swap.
% Try it (personal exploration)
% Hr(3, 1) is the reversed channel from transmit antenna 3 to receive antenna 
% 1. Predict which entry of the forward Hf it equals, as [row column]. Type 
% it into myPrediction before you run this section; the one-row table at the 
% end finds the matching entry of Hf.

% Try it: type your prediction here ([row column]) before running this section.
myPrediction = [NaN NaN];   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Reciprocity: one channel, swapped ends
fprintf("B3 — Reciprocity: one channel, swapped ends\n");   % banner title only; every number below goes into a table

% A static TDL-C channel: 2 transmit antennas (gNB) and 4 receive antennas (UE) for now.
fs = 15.36e6;                          % sample rate, Hz (a 15 kHz carrier with a 1024-point FFT)
tdl = nrTDLChannel(DelayProfile = "TDL-C", DelaySpread = 30e-9, ...   % delay spread, s
    MaximumDopplerShift = 0, SampleRate = fs);                           % Doppler, Hz: 0 means no fading over time
tdl.NumTransmitAntennas = 2;           % gNB antennas sending
tdl.NumReceiveAntennas  = 4;           % UE antennas listening
tdl.NormalizeChannelOutputs = false;   % documented condition for reciprocity across the swap

% Downlink: 64 samples of zeros are enough, because only the path gains are read.
[~, pgFwd] = tdl(complex(zeros(64, 2)));   % path gains, 64 × paths × 2 × 4

% Reverse the link: the same object, the same fading, the antennas' roles swapped.
swapTransmitAndReceive(tdl);
tdlInfo = info(tdl);                                  % antenna counts after the swap
[~, pgRev] = tdl(complex(zeros(64, tdlInfo.NumTransmitAntennas)));   % one column per transmit antenna

% The documented comparison: the reversed gains equal the forward gains with
% the transmit and receive dimensions swapped.
pgFwdSwapped = permute(pgFwd, [1 2 4 3]);
sameSize = isequal(size(pgRev), size(pgFwdSwapped));
if sameSize
    rel = max(abs(pgRev(:) - pgFwdSwapped(:))) / max(abs(pgFwd(:)));   % relative residual
else
    rel = NaN;                                                          % shapes differ: no comparison
end

% The same idea as a matrix: sum the paths at the last sample for a 2 × 4 and a 4 × 2.
Hf = squeeze(sum(pgFwd(end, :, :, :), 2));   % forward, 2 × 4 (transmit × receive)
Hr = squeeze(sum(pgRev(end, :, :, :), 2));   % reversed, 4 × 2
relH = norm(Hf.' - Hr, 'fro') / norm(Hf, 'fro');

% Three tests: the swapped shape, the path gains, and the summed matrix.
okSwapShape = sameSize && tdlInfo.NumTransmitAntennas == 4;
assert(okSwapShape, ...
    'After the swap the gains should be 64 × paths × 4 × 2. Look first at swapTransmitAndReceive(tdl): call it once, on the same object.');
okReciprocal = sameSize && rel < 1e-9;
assert(okReciprocal, ...
    'The reversed path gains should equal the forward ones with dimensions 3 and 4 swapped. Look first at swapTransmitAndReceive: it must act on the same object, called once.');
okTranspose = relH < 1e-9;
assert(okTranspose, ...
    'The reversed 4 × 2 should be the plain transpose of the forward 2 × 4. Common mistake: using '' (conjugate transpose) instead of .''.');

b3Recip = table(listText(size(pgFwd)), listText(size(pgRev)), rel, relH, ...
    VariableNames = {'ForwardGainsSize', 'ReversedGainsSize', 'RelResidual_PathGains', 'RelResidual_H'});
b3Recip

% Put your Try-it prediction beside the entry of Hf that matches Hr(3, 1).
[tryRow, tryCol] = find(abs(Hf - Hr(3, 1)) == min(abs(Hf(:) - Hr(3, 1))), 1);
if any(isnan(myPrediction))
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(listText(myPrediction), listText([tryRow tryCol]), predictionNote, ...
    VariableNames = {'MyPrediction', 'MatchingEntryOfHf', 'Note'});
b3Prediction
%%
% Both residuals sit at rounding level: the reversed channel is the forward 
% channel with its transmit and receive ends swapped, entry for entry, a plain 
% transpose with no conjugate. That is the air being reciprocal on one carrier. 
% In FDD the uplink carrier is far from the downlink one, the fading differs, 
% and no swap makes them agree. Compare the matching entry with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["Swapped shape and antenna count"; ...
     "Path gains reciprocal (permuted)"; ...
     "Summed H: reversed = forward.'"], ...
    ["64 × paths × 4 × 2, 4 transmit"; "< 1e-9"; "< 1e-9"], ...
    [listText(size(pgRev)) + ", " + string(tdlInfo.NumTransmitAntennas) + " transmit"; string(rel); string(relH)], ...
    [okSwapShape; okReciprocal; okTranspose], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Nothing later needs the TDL channel.
clear b3Recip b3Checks b3Prediction predictionNote tryRow tryCol okSwapShape okReciprocal okTranspose ...
      fs tdl tdlInfo pgFwd pgRev pgFwdSwapped sameSize rel Hf Hr relH myPrediction
%% B4 — Break it with radios, then calibrate
% New words
% • Radio chain: the amplifiers, filters, and mixers behind one antenna; its 
% transmit chain and its receive chain have different complex gains.
% Beat-only commands
% • diag(v), H.', and norm(A, 'fro') — see Key code terms (commands you write).
% Why it matters
% The air is reciprocal, but the measured channel includes the radios at both 
% ends. The downlink uses the gNB's transmit chains t_gNB and the phone's receive 
% chains r_UE; the uplink uses the phone's transmit chains t_UE and the gNB's 
% receive chains r_gNB (Key relationships). Because t ≠ r at each node, the 
% measured H_UL and H_DLᵀ disagree even though the air agrees. Calibration 
% divides the known (or estimated) chain gains back out. This is a textbook 
% teaching model in plain matrix algebra, not a toolbox API.
% What to look for
% • In the residual table: the residual before calibration, after calibrating 
% both ends, and after calibrating the gNB side only.
% Common mistakes
% Do not blame the air for a disagreement that is in the radios.
% 
% Do not calibrate one end and assume the job is done.
% Try it (personal exploration)
% Suppose the phone's radio chains are perfectly matched, t_UE = r_UE (keep 
% r_UE as it is). Predict the residual after calibrating the gNB side only. 
% Type it into myPrediction before you run this section; the one-row table 
% at the end measures it on a separate uplink.

% Try it: type your prediction here (residual, a non-negative number) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Break it with radios, then calibrate
fprintf("B4 — Break it with radios, then calibrate\n");   % banner title only; every number below goes into a table

% A 2 × 2 toy air channel: rows are UE antennas, columns are gNB antennas.
Hphys = [0.9+0.1i, 0.2; 0.1-0.2i, 1.1];   % complex air gains, no units (a toy channel)

% Each node's transmit chains differ from its own receive chains (size, phase in degrees).
tGNB = [1; ce(0.8,  10)];   rGNB = [1; ce(1.1, -25)];   % gNB transmit vs receive
tUE  = [1; ce(0.9,  20)];   rUE  = [1; ce(1.2, -15)];   % UE transmit vs receive

% What each side actually measures, radios included (Key relationships).
Hdl = diag(rUE)  * Hphys   * diag(tGNB);   % gNB transmits, UE receives
Hul = diag(rGNB) * Hphys.' * diag(tUE);    % UE transmits, gNB receives
residRaw = norm(Hdl.' - Hul, 'fro');       % how far the measurements are from reciprocal

% Calibration on both ends: divide each chain's gain back out, leaving the air.
HdlCal = diag(1./rUE)  * Hdl * diag(1./tGNB);
HulCal = diag(1./rGNB) * Hul * diag(1./tUE);
residCal = norm(HdlCal.' - HulCal, 'fro');

% The common mistake on purpose: correct only the gNB side, by its ratio t/r.
residGnbOnly = norm(Hdl.' - diag(tGNB./rGNB) * Hul, 'fro');

% Three tests: mismatched radios break reciprocity, both ends restore it, one end does not.
okBroken = residRaw > 1e-3;
assert(okBroken, ...
    'Mismatched chains should visibly break reciprocity. Look first at tGNB, rGNB, tUE, rUE: each pair must differ.');
okCalibrated = residCal < 1e-12;
assert(okCalibrated, ...
    'Calibrating both ends should restore the transpose. Look first at HdlCal and HulCal: divide by r on the left and t on the right.');
okGnbOnly = residGnbOnly > 1e-3;
assert(okGnbOnly, ...
    'Calibrating only the gNB side should leave a residual here. Look first at residGnbOnly: it multiplies Hul by diag(tGNB./rGNB).');

b4Resid = table(residRaw, residCal, residGnbOnly, ...
    VariableNames = {'Raw', 'BothEndsCalibrated', 'GnbSideOnly'});
b4Resid

% Put your Try-it prediction beside the gNB-only residual with a matched phone (t_UE = r_UE).
HulTry = diag(rGNB) * Hphys.' * diag(rUE);                  % the uplink if the phone transmits through r_UE
tryResid = norm(Hdl.' - diag(tGNB./rGNB) * HulTry, 'fro');
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, tryResid, predictionNote, ...
    VariableNames = {'MyPrediction', 'GnbOnlyMatchedPhone', 'Note'});
b4Prediction
%%
% The raw residual is clearly above zero: the radios, not the air, broke the 
% transpose. Dividing out all four chain gains brings it to rounding level. 
% Correcting only the gNB side left a residual, and here a larger one than 
% doing nothing (exercise E6 asks why). Compare the matched-phone residual with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["Radios break reciprocity"; ...
     "Both ends calibrated (by construction: the model)"; ...
     "gNB side only leaves a residual"], ...
    ["> 1e-3"; "< 1e-12"; "> 1e-3"], ...
    [string(residRaw); string(residCal); string(residGnbOnly)], ...
    [okBroken; okCalibrated; okGnbOnly], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The Build it starts fresh with its own my... values; keep ce and listText.
clear b4Resid b4Checks b4Prediction predictionNote okBroken okCalibrated okGnbOnly ...
      Hphys tGNB rGNB tUE rUE Hdl Hul residRaw HdlCal HulCal residCal residGnbOnly ...
      HulTry tryResid myPrediction
%% Build it — Count an SRS comb and calibrate a TDD link by hand
% Competency: count the REs of an SRS comb from its bandwidth and comb size, 
% write the measured downlink and uplink channels with radio chains included, 
% measure how far they are from reciprocal, and calibrate the base station 
% so the transpose holds again.
% Problem
% A phone sounds 24 RBs with a comb-4 SRS. Count the SRS REs in one symbol, 
% and how many phones could share that symbol on different teeth of the comb. 
% Then take a 2 × 2 TDD link whose phone has ideal radio chains (every gain 
% 1) and whose base station has transmit chains myT and receive chains myR. 
% Write the measured downlink and uplink channels, measure the residual from 
% reciprocity, and calibrate the base station side to remove it.
% Allowed commands
% x = value; + - * / and ./; [a; b] and ce(a, deg); diag(v); H.' and A*B; 
% norm(A, 'fro'). The tables and the figure in the check sections and Stage 
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

% myRB = 24;                                  % RBs sounded
% myKTC = 4;                                  % comb size
% myH = [1, 0.3+0.4j; 0.2-0.1j, 0.8+0.2j];    % air channel, rows = phone antennas, columns = base-station antennas
% myT = [1; ce(0.9, 30)];                     % base-station transmit chains (size, degrees)
% myR = [1; ce(1.05, -20)];                   % base-station receive chains (size, degrees)
%% Stage 1 check (given)
if ~exist('myRB','var') || ~exist('myKTC','var') || ~exist('myH','var') || ~exist('myT','var') || ~exist('myR','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal([myRB myKTC], [24 4]) && isequal(size(myH), [2 2]) && ...
        abs(myH(1, 2) - (0.3+0.4j)) < 1e-12 && isequal(size(myT), [2 1]) && isequal(size(myR), [2 1]) && ...
        abs(myT(2) - ce(0.9, 30)) < 1e-12 && abs(myR(2) - ce(1.05, -20)) < 1e-12;
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the five lines you uncommented: 24, 4, the 2 × 2 myH, and the two columns myT and myR.')
    stage1Checks = table("Given values", "24 4, 2 × 2 myH, 2 × 1 myT and myR", ...
        listText([myRB myKTC]) + ", " + listText(size(myH)) + ", " + listText(size(myT)) + ", " + listText(size(myR)), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — count the comb
% Fill the blanks: the SRS REs in one symbol (RBs × 12 subcarriers ÷ comb 
% size, from the Key relationships), and the number of phones that can share 
% the symbol, one per tooth of the comb.
% Pass: Stage 2 OK.

% mySrsREs = ___*12/___;
% myPhones = ___;
%% Stage 2 check (given; the check counts the subcarriers a comb actually visits, a different route from yours)
if ~exist('mySrsREs','var') || ~exist('myPhones','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: list the subcarriers 0, K, 2K, ... in the band and count them,
    % and count the distinct comb offsets (the remainders of every subcarrier by K).
    srsOracle = numel(0:myKTC:myRB*12 - 1);
    phonesOracle = numel(unique(mod(0:myRB*12 - 1, myKTC)));
    okStage2 = [mySrsREs == srsOracle; myPhones == phonesOracle];
    assert(okStage2(1), ...
        'mySrsREs is off. Look first at the division: the comb keeps one subcarrier in every myKTC.')
    assert(okStage2(2), ...
        'myPhones is off. Look first at the comb: each phone needs its own tooth, and the teeth repeat every myKTC subcarriers.')
    stage2Checks = table( ...
        ["SRS REs in one symbol"; "Phones sharing the symbol"], ...
        [string(srsOracle); string(phonesOracle)], ...
        [string(mySrsREs); string(myPhones)], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3 — the measured channels and the residual
% Fill the blanks: the downlink the phone measures (the base station transmits 
% through myT; the phone's receive chains are 1), the uplink the base station 
% measures (the phone's transmit chains are 1; the base station receives through 
% myR), and the residual between the downlink's transpose and the uplink.
% Pass: Stage 3 OK.

% myHdl = myH * diag(___);
% myHul = diag(___) * myH.';
% myResid = norm(myHdl.' - ___, 'fro');
%% Stage 3 check (given; the check scales rows and columns entry by entry, a different route from yours)
if ~exist('myHdl','var') || ~exist('myHul','var') || ~exist('myResid','var')
    disp('Stage 3 not done: fill the blanks, uncomment, and run.')
else
    % Different route: scaling column n by myT(n) is myH .* myT.'; scaling row n by myR(n) is myR .* myH.'.
    hdlOracle = myH .* myT.';
    hulOracle = myR .* myH.';
    residOracle = sqrt(sum(abs(hdlOracle.' - hulOracle).^2, 'all'));
    okStage3 = [isequal(size(myHdl), [2 2]) && max(abs(myHdl(:) - hdlOracle(:))) < 1e-12; ...
                isequal(size(myHul), [2 2]) && max(abs(myHul(:) - hulOracle(:))) < 1e-12; ...
                abs(myResid - residOracle) < 1e-12];
    assert(okStage3(1), ...
        'myHdl is off. Look first at which chains the downlink uses: the base station transmits, so myT, on the right.')
    assert(okStage3(2), ...
        'myHul is off. Look first at which chains the uplink uses: the base station receives, so myR, on the left of myH.''.')
    assert(okStage3(3), ...
        'myResid is off. Common mistake: comparing myHdl with myHul without the transpose .'' on myHdl.')
    stage3Checks = table( ...
        ["Downlink with radios"; "Uplink with radios"; "Residual from reciprocity"], ...
        ["matches myH .* myT.'"; "matches myR .* myH.'"; string(round(residOracle, 4))], ...
        [string(okStage3(1)); string(okStage3(2)); string(round(myResid, 4))], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — predict, then calibrate the base station
% First type your prediction: the size |myCal(2)| of the second calibration 
% factor. Then fill the blanks: the calibration factors (transmit chain divided 
% by receive chain, entry by entry), the calibrated uplink, and its residual 
% from the downlink's transpose.
% Pass: your prediction and your value appear side by side in a one-row table, 
% and Stage 4 OK.

% myPrediction = ___;
% myCal = ___ ./ ___;
% myHulCal = diag(___) * myHul;
% myResidCal = norm(myHdl.' - ___, 'fro');
%% Stage 4 check (given; the check rebuilds the uplink as if the base station received through myT, a different route from yours)
if ~exist('myPrediction','var') || ~exist('myCal','var') || ~exist('myHulCal','var') || ~exist('myResidCal','var')
    disp('Stage 4 not done: type your prediction, fill the blanks, uncomment, and run.')
else
    % Your prediction beside your value, in one row.
    stage4Prediction = table(myPrediction, round(abs(myCal(end)), 4), ...
        VariableNames = {'MyPrediction', 'MyCalSize'});
    stage4Prediction

    % Different route: a calibrated uplink looks as if the base station had received
    % through its own transmit chains, so it must equal myT .* myH.'.
    hulCalOracle = myT .* myH.';
    okStage4 = [isequal(size(myCal), [2 1]) && max(abs(myCal .* myR - myT)) < 1e-12; ...
                isequal(size(myHulCal), [2 2]) && max(abs(myHulCal(:) - hulCalOracle(:))) < 1e-12; ...
                myResidCal < 1e-12];
    assert(okStage4(1), ...
        'myCal is off. Common mistake: dividing the wrong way round; the factor is transmit over receive.')
    assert(okStage4(2), ...
        'myHulCal is off. Look first at the blank: multiply myHul on the left by diag(myCal).')
    assert(okStage4(3), ...
        'myResidCal is not at rounding level. Look first at what you compared: myHdl.'' with myHulCal.')
    stage4Checks = table( ...
        ["Calibration factors t ./ r"; "Calibrated uplink"; "Residual after calibration"], ...
        ["myCal .* myR = myT"; "matches myT .* myH.'"; "< 1e-12"], ...
        [string(okStage4(1)); string(okStage4(2)); string(myResidCal)], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('mySrsREs','var') || ~exist('myResid','var') || ~exist('myResidCal','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [mySrsREs*myKTC == myRB*12; ...
        myResid > 1e-3; ...
        myResidCal < 1e-12; ...
        abs(abs(myCal(2)) - abs(myT(2))/abs(myR(2))) < 1e-12; ...
        max(abs(myHulCal - myHdl.'), [], 'all') < 1e-12];

    % One row per result: what the rule says, your value, and the computed flag.
    buildChecks = table( ...
        ["SRS REs × comb = all subcarriers"; "Radios break reciprocity"; "Calibration restores it"; ...
         "|calibration| = |t| / |r|"; "Calibrated uplink = downlink transpose, entry by entry"], ...
        [string(myRB*12); "> 1e-3"; "< 1e-12"; string(round(abs(myT(2))/abs(myR(2)), 4)); "max difference < 1e-12"], ...
        [string(mySrsREs*myKTC); string(round(myResid, 4)); string(myResidCal); ...
         string(round(abs(myCal(2)), 4)); string(max(abs(myHulCal - myHdl.'), [], 'all'))], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: the residual before and after your calibration.
    figure(Name = 'Track 10 Build it - my calibration', Color = 'w');
    bar([myResid myResidCal]);                          % two bars: raw and calibrated
    xticks(1:2);
    xticklabels({'before calibration', 'after calibration'});
    ylabel('||H_{DL}^T - H_{UL}||_F');
    title(sprintf('My TDD link: residual %.3f before, %.1e after', myResid, myResidCal));
end
%%
% Your interpretation (write one or two sentences here): what did your calibration 
% factor do to the second base-station antenna, in size and in phase? Why 
% was calibrating the base station alone enough for this link, and what in 
% B4 made it not enough there?
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; ce and listText stay in case you rerun a check.
clear okStage1 stage1Checks srsOracle phonesOracle okStage2 stage2Checks ...
      hdlOracle hulOracle residOracle okStage3 stage3Checks ...
      stage4Prediction hulCalOracle okStage4 stage4Checks ...
      buildFlags buildChecks
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them, 
% because each one asks for a reason as well as a value. You may use MATLAB 
% as a calculator in a new section of your own. Write your answers on the Your 
% answer lines. Your teacher has model answers.
% E1 — New values (B1 and Build it)
% An SRS sounds 48 RBs on a comb-8 in four symbols. How many SRS REs does one 
% phone use in the slot, and how many phones can sound the same symbols on 
% different teeth? What does a phone gain, and what does it give up, with a 
% comb-2 instead?
% 
% Your answer:
% E2 — New values (B2)
% Over 24 RBs, how many REs does a one-port CSI-RS use with density 'one', 
% and how many with density 'three'? Why might a base station accept the denser 
% pattern for a signal the phone uses to track timing and frequency?
% 
% Your answer:
% E3 — Diagnosis (B3)
% A classmate leaves NormalizeChannelOutputs at its default, true, on the 
% 2 × 4 link (2 transmit, 4 receive) and then swaps it. By what amplitude 
% factor does the default change each direction's output, and what is the 
% ratio between the two directions?
% 
% Your answer:
% E4 — Explanation (B3)
% An FDD cell sends downlink at 1845 MHz and listens to uplink at 1750 MHz. 
% Explain why the base station cannot use the SRS it hears to aim its downlink, 
% using the idea that a channel's fading changes over a frequency span of about 
% one over its delay spread (take 300 ns). What does the phone do instead?
% 
% Your answer:
% E5 — Diagnosis (Build it)
% A classmate calibrates with myR ./ myT instead of myT ./ myR and finds the 
% residual got bigger, not smaller. Explain why, and say what the residual 
% would be if the base station's chains were already matched (myT = myR).
% 
% Your answer:
% E6 — Explanation (B4)
% In B4, calibrating only the gNB side gave a larger residual than not calibrating 
% at all. Explain how a correction at one end can make the mismatch worse, 
% and why the calibrated system still needs the phone's chains to be handled.
% 
% Your answer:
%% Recap — Sound It Out (album track 10)
% The phone sends an SRS on a comb so the base station can measure the uplink; 
% the base station sends a CSI-RS so the phone can measure the downlink and 
% report. In TDD the air is reciprocal, H_UL = H_DLᵀ, a plain transpose; in 
% FDD it is not, so the phone reports. Real radios break the transpose, because 
% each node's transmit chain differs from its receive chain, and calibrating 
% both ends restores it.
% Key relationships
% $$\mathbf{H}_{\mathrm{UL}} = \mathbf{H}_{\mathrm{DL}}^{T},\qquad 
% \mathbf{H}_{\mathrm{DL}} = \mathrm{diag}(\mathbf{r}_{\mathrm{UE}})\,\mathbf{H}\,\mathrm{diag}(\mathbf{t}_{\mathrm{gNB}}),\qquad 
% N_{\mathrm{SRS}} = m \cdot 12 / K_{TC}$$
% What this means in practice
% • nrSRSConfig sets the comb with KTC and the sounded bandwidth with CSRS; 
% count REs per symbol as RBs × 12 / KTC.
% 
% • nrCSIRSConfig sets the pattern with RowNumber and the REs per RB with 
% Density.
% 
% • Before swapTransmitAndReceive, set NormalizeChannelOutputs to false, and 
% compare with permute(pathGains, [1 2 4 3]).
% 
% • Reciprocity is a plain transpose, .' in MATLAB, not '.
% 
% • Calibration divides those chain gains back out, so the downlink again 
% matches the uplink transposed.
% 
% • You counted an SRS comb by hand, wrote the measured TDD channels with 
% radios included, and calibrated the base station back to reciprocity.
% 
% • Retrieval prompt (answer in one line; the answer key has it): from album 
% track 09 (track09/track09_steer_the_beam_demo), why does a base station need 
% the channel, or the direction, before it can steer a beam at your phone?
% 
% • Next in the album: track11 (One in Ten).
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
% • [a; b] and a*exp(1j*deg*pi/180):
% 
% • diag(v):
% 
% • H.' and A*B:
% 
% • norm(A, 'fro'):
% What I missed, and where to reread it
% 
