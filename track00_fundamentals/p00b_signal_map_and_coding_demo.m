%% P00b — Map of the Link: Signal Map and Coding
%% Which signal does which job, and how a block of bits is protected
% A phone has four jobs: find a cell, receive control instructions, receive 
% data, and report what it measures. Different signals and channels do those 
% jobs on the same time-frequency grid.
% 
% Before a block of bits is sent, it passes through a five-step coding chain: 
% CRC, channel coding, rate matching, scrambling, and modulation. This demonstration 
% runs a toy version of that chain on real bits.
%% Guiding question
% Until the phone finds the SSB, what can it read? And once it can read, how 
% does a block of bits survive the trip?
% This demonstration
% 1. B1a — Meet the three signals that find the cell, carry control, and carry 
% data (SSB, PDCCH, PDSCH), and count the REs in a PDSCH block.
% 
% 2. B1b — Meet the three known signals (DM-RS, CSI-RS, SRS) and draw their 
% placement patterns.
% 
% 3. B2 — Compute the code rate and the CRC miss scale for the narrated example, 
% then push eight bits through a toy CRC, a toy code, a circular buffer with 
% two redundancy versions, scrambling, and QPSK.
% Key relationships
% The code rate compares information bits with the coded bits actually sent:
% 
% $$R = \frac{K}{E}$$
% 
% An L-bit CRC misses a random error pattern with probability about
% 
% $$P_{\mathrm{miss}} \approx 2^{-L}$$
%% Prerequisites
% • The resource grid, REs, and RBs (P00a)
% 
% • Uplink means phone to base station; downlink means base station to phone
% 
% • Binary addition without carries (XOR)
% 
% Words used in this demo
% • Signal: a known pattern sent for a job, such as finding the cell or measuring 
% the channel. Channel (in a name such as PDSCH): a set of REs that carries bits.
% 
% • Uplink: phone to base station. Downlink: base station to phone. Base station: 
% the cell's radio mast.
% 
% • SSB (synchronization signal block): the first signal a phone looks for; 
% it gives the cell's identity and timing.
% 
% • PDCCH (physical downlink control channel): carries control instructions, 
% such as where each phone's data is.
% 
% • PDSCH (physical downlink shared channel): carries the downlink data.
% 
% • DM-RS (demodulation reference signal): known values placed inside the data 
% so the receiver can see how the radio path changed the signal there.
% 
% • CSI-RS (channel-state information reference signal): a downlink measurement 
% signal; the phone measures it and reports back (CSI).
% 
% • SRS (sounding reference signal): an uplink measurement signal the phone sends.
% 
% • Pilot or reference signal: values the receiver knows in advance. Channel 
% estimation: working out how the radio path changed the signal, from the pilots.
% 
% • Comb-2: on every second subcarrier.
% 
% • CRC (cyclic redundancy check): check bits added to a block so the receiver 
% can tell whether it arrived damaged. Generator: the fixed bit pattern the CRC 
% divides by. Remainder: what is left after that division.
% 
% • XOR: adding bits with no carry; 0+0=0, 0+1=1, 1+1=0.
% 
% • Channel coding: adding planned extra bits (redundancy) so errors can be 
% fixed. LDPC and polar codes are the two families NR uses.
% 
% • Code rate (R): information bits divided by the bits actually sent.
% 
% • Circular buffer: a list read as if its end joins its start. Rate matching: 
% reading exactly E bits from it. Redundancy version (RV): which start point 
% a transmission uses.
% 
% • Scrambling: XOR with a known random-looking sequence. HARQ: sending another 
% version when a block fails its CRC.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write
% yourself get their own entry; small helpers are grouped into families.
%
% Commands you write
% • a:b and a:s:b — Purpose: make a list of numbers. Inputs: start, optional
% step, and end. Outputs: a row of values.
%
% • mod(a, n) — Purpose: wrap a count at n (the remainder after dividing by n).
% Inputs: a value or list, and the wrap length n. Outputs: values in 0 .. n-1.
%
% • xor(a, b) — Purpose: add bits with no carry. Inputs: two bit lists of the
% same size. Outputs: a bit list.
%
% • for k = 1:n ... end — Purpose: repeat a block n times. Inputs: a range.
% Outputs: whatever the block stores.
%
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start a
% comment; start a section.
%
% • zeros, repelem, floor, numel, union, ismember, table, isnan — Purpose: the
% usual helpers in the given cells.
%
% Scope: the placement diagrams show direction, density, and containment only;
% they are not a standards-compliant scheduled slot. The toy chain uses a 4-bit
% CRC and a repetition code as stand-ins: NR uses 24-bit (and other) CRCs, LDPC
% codes for data, and polar codes for broadcast and control. No 5G Toolbox objects
% are used here.
%
% Album tracks that configure what this demo only names: 03 — SSB and cell
% search; 05 — PDSCH, transport block size, rate matching, and HARQ; 07 — DM-RS
% and channel estimation; 10 — CSI-RS, SRS, and TDD reciprocity; 15 — PDCCH and
% its control region. Album track 04 teaches the CRC and LDPC used in B2.
%% Staging for script

% Clear the workspace and close figures so every run starts from the same state.
clear; close all;
% Fix the random seed so the toy scrambling sequence is reproducible.
rng(2026);
%% B1a — Find, control, data: SSB, PDCCH, PDSCH
% New words
% • SSB (synchronization signal block): the first signal a phone looks for; 
% it gives the cell's identity and timing.
% 
% • PDCCH (physical downlink control channel): carries control instructions, 
% such as where each phone's data is.
% 
% • PDSCH (physical downlink shared channel): carries the downlink data itself.
% Why it matters
% The SSB is the first downlink signal a phone must find. Until it does, it 
% has no cell identity and no timing, so it cannot read anything else. After 
% that, PDCCH carries control instructions that tell each phone where its data 
% is, and PDSCH carries the shared downlink data in a block of REs.
% What to look for
% • In the first role table, read the Direction column for the three rows, and 
% the Purpose column: find which one the phone needs before it can read the 
% other two.
% 
% • The AlbumTrack column gives the album track that configures 
% each signal properly.
% 
% • In the printed comparison, check your PDSCH RE count against the computed 
% one.
% Common mistakes
% Do not think a phone can read PDCCH or PDSCH before it has found the SSB. 
% Without the SSB's timing it does not know where any symbol starts.
% 
% Do not read the AlbumTrack column as old track IDs. These are the album
% numbers: 05 is the PDSCH track and 15 is the PDCCH track.
% Try it (personal exploration)
% The teaching PDSCH block uses subcarrier rows 13 to 60 and OFDM symbols 4 
% to 14 (see pdschRows and pdschSymbols in the code). Count how many REs that 
% block holds, using "rows times columns", and type that number into myPrediction 
% in the first code line below before you run this section. A given line after 
% the role table prints your prediction beside the result.

% Try it: type your prediction here (a number of REs) before running this section.
myPrediction = NaN;
% Each row identifies one signal, its direction, its immediate job, and the
% album track that introduces its standards-based configuration.
signalName = [ ...
    "SSB"; ...
    "PDCCH"; ...
    "PDSCH"; ...
    "DM-RS"; ...
    "CSI-RS"; ...
    "SRS"];

signalDirection = [ ...
    "Downlink"; ...
    "Downlink"; ...
    "Downlink"; ...
    "Downlink"; ...
    "Downlink"; ...
    "Uplink"];

signalPurpose = [ ...
    "Cell discovery, identity, and timing"; ...
    "Control instructions and scheduling"; ...
    "Shared downlink data"; ...
    "Known pilot within a PDSCH allocation"; ...
    "Downlink channel measurement for CSI reporting"; ...
    "Uplink sounding for base-station channel measurement"];

% Album track numbers, written without
% a "T" prefix so they cannot be mistaken for other numbering.
introducedIn = [ ...
    "03"; ...
    "15"; ...
    "05"; ...
    "07"; ...
    "10"; ...
    "10"];

% MATLAB tables require columns of equal height. This check makes that
% assumption explicit before constructing the learner-facing table.
checkTableRows = numel(signalName) == numel(signalDirection) && ...
    numel(signalDirection) == numel(signalPurpose) && ...
    numel(signalPurpose) == numel(introducedIn);

assert(checkTableRows, ...
    'Every signal-role table column must contain one entry per signal. Look first at the four lists above: add or remove a signal in all of them.');

% Display the role table: one row per signal, with its direction, job, and
% the album track that configures it properly.
signalMap = table( ...
    signalName, ...
    signalDirection, ...
    signalPurpose, ...
    introducedIn, ...
    VariableNames = {'Signal','Direction','Purpose','AlbumTrack'});

% Show the first half of the role table: the three signals that find the cell,
% carry control, and carry data.
firstSignals = signalMap(1:3, :)

% The teaching grid used in B1a and B1b. These dimensions are chosen for a
% readable picture; they are not a particular standardized carrier bandwidth.
nSubcarriers = 72;
nSymbols = 14;

% PDSCH example. Display labels: 0 = empty, 1 = PDSCH (B1b adds 2 = DM-RS).
% PDSCH is drawn as a dense rectangular allocation in the later OFDM symbols.
pdschRows = 13:60;
pdschSymbols = 4:14;

pdschDmrsGrid = zeros(nSubcarriers, nSymbols);
pdschDmrsGrid(pdschRows, pdschSymbols) = 1;

% Count the PDSCH block's REs straight from the grid (a different route from
% "rows times columns").
pdschRECount = nnz(pdschDmrsGrid == 1);

% Compare your Try-it prediction with the result, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run it again.')
else
    predCompare = table(myPrediction, pdschRECount, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
%% B1a — After the run
% All three signals go down, from the base station to the phone, and they come
% in a fixed order: SSB first, then PDCCH to say where the data is, then PDSCH 
% with the data. The PDSCH block is a solid rectangle of REs, so its count is 
% its height in subcarriers times its width in symbols.
%% B1b — Pilots and measurements: DM-RS, CSI-RS, SRS
% New words
% • DM-RS (demodulation reference signal): known values (a pilot) placed inside 
% the PDSCH block so the receiver can measure the radio path right where the 
% data sits.
% 
% • CSI-RS (channel-state information reference signal): a downlink measurement 
% signal; the phone measures it and reports what it found.
% 
% • SRS (sounding reference signal): an uplink measurement signal the phone 
% sends, here on every second subcarrier (called comb-2).
% Why it matters
% DM-RS is a known pilot embedded inside the PDSCH allocation, so the receiver 
% can estimate the channel right where the data sits. CSI-RS is sent down so 
% the phone can measure the channel and report back. SRS is sent up so the base 
% station can measure the uplink.
% 
% Known signals cost REs that could have carried data. That is the trade-off 
% each pattern makes: dense enough to measure the channel, sparse enough to leave 
% room for data.
% What to look for
% • In the second role table, read the Direction column: find the one signal 
% that goes up.
% 
% • In the figure, compare where DM-RS sits relative to the PDSCH block, how 
% many REs CSI-RS uses, and how often SRS repeats across subcarriers.
% 
% • In the RE-count table, compare the DM-RS count with the PDSCH count.
% Common mistakes
% Do not confuse DM-RS with CSI-RS. DM-RS lives inside a data allocation and 
% serves that data; CSI-RS is a separate measurement signal for reporting.
% 
% Do not think the base station sends SRS. The phone sends it, so it is the 
% one uplink row in the map.
% Try it (personal exploration)
% Predict which of these three signals is the only uplink one. Then use the 
% SRS index range in the code (comb-2 over the 72 teaching subcarriers, in one 
% symbol) to predict the SRS RE count, and type that number into myPrediction 
% in the first code line below before you run this section. After the RE-count 
% table, a given table shows your predictions beside the results. Do the same
% for the DM-RS count: type it into myPredictionDmrs, using its row and symbol ranges.

% Try it: type your predictions here (a number of REs) before running this section.
myPrediction = NaN;        % SRS RE count
myPredictionDmrs = NaN;    % DM-RS RE count, from its row and symbol ranges

% The second half of the role table: the three known signals.
laterSignals = signalMap(4:6, :)
% Build focused grid-placement examples
% Rather than place every signal into one artificial slot, build three focused
% examples: a dense PDSCH allocation containing sparse DM-RS pilots, a sparse 
% CSI-RS downlink measurement pattern, and a comb-shaped SRS uplink pattern.

% The teaching grid and the PDSCH block were built in B1a. DM-RS now replaces
% selected PDSCH display elements (label 2) because pilots physically occupy
% REs within that data allocation.
% These pilot rows are spaced in frequency. The two selected pilot symbols
% demonstrate that DM-RS can appear at multiple positions in time.
dmrsRows = 13:4:60;
dmrsSymbols = [5 10];
pdschDmrsGrid(dmrsRows, dmrsSymbols) = 2;

% CSI-RS example
%
% CSI-RS is a sparse known downlink signal. It is shown independently so
% learners do not confuse it with DM-RS, which lives inside PDSCH.
csirsGrid = zeros(nSubcarriers, nSymbols);

csirsRows = 8:8:64;
csirsSymbol = 7;
csirsGrid(csirsRows, csirsSymbol) = 1;

% SRS example
%
% SRS is an uplink comb. In this comb-2 illustration, every second
% subcarrier is occupied in one OFDM symbol.
srsGrid = zeros(nSubcarriers, nSymbols);

srsRows = 1:2:nSubcarriers;
srsSymbol = nSymbols;
srsGrid(srsRows, srsSymbol) = 1;

% The following checks explain why these examples have been drawn as they
% have, and confirm that they implement the intended teaching relationships.

% DM-RS must be placed inside the PDSCH allocation.
checkDMRSInsidePDSCH = ...
    all(ismember(dmrsRows, pdschRows)) && ...
    all(ismember(dmrsSymbols, pdschSymbols));

% Comb-2 means half the subcarriers are occupied in its configured symbol.
checkSRSComb2 = numel(srsRows) == nSubcarriers/2;

% CSI-RS is sparse: it occupies fewer REs than one complete OFDM symbol.
checkCSIRSSparse = nnz(csirsGrid) < nSubcarriers;

% The SRS example must occupy only one OFDM symbol.
checkSRSOneSymbol = nnz(any(srsGrid ~= 0, 1)) == 1;

% Direction is read from the role table and the After-the-run cell, not
% re-asserted here from the same strings that built the table.

assert(checkDMRSInsidePDSCH, ...
    'DM-RS must be placed inside the illustrated PDSCH allocation. Look first at dmrsRows and dmrsSymbols against pdschRows and pdschSymbols. Common mistake: confusing DM-RS with CSI-RS.');

assert(checkSRSComb2, ...
    'A comb-2 SRS should occupy every second subcarrier. Look first at the step in srsRows: comb-2 means a step of 2.');

assert(checkCSIRSSparse, ...
    'The CSI-RS illustration should remain sparse. Look first at csirsRows: CSI-RS uses only a few REs.');

assert(checkSRSOneSymbol, ...
    'The SRS illustration should occupy one configured OFDM symbol. Look first at srsSymbol: it should be a single symbol.');

% Count the REs each pattern uses, so the density trade-off is a number and
% not only a picture.
dmrsRECount = numel(dmrsRows) * numel(dmrsSymbols);
csirsRECount = nnz(csirsGrid);
srsRECount = nnz(srsGrid);
dmrsShare = dmrsRECount / pdschRECount;

% Display the RE count of each pattern and the share of the PDSCH block that
% the DM-RS pilots take.
reCountResults = table( ...
    ["PDSCH block"; "DM-RS inside it"; "CSI-RS"; "SRS (comb-2)"; "DM-RS share of PDSCH"], ...
    [string(pdschRECount); string(dmrsRECount); string(csirsRECount); ...
     string(srsRECount); string(sprintf('%.1f %%', 100*dmrsShare))], ...
    VariableNames = {'Pattern','REs'});

reCountResults

% Compare your Try-it prediction with the result, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run it again.')
else
    predCompare = table(myPrediction, srsRECount, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
if isnan(myPredictionDmrs)
    disp('No DM-RS prediction recorded: type a number into myPredictionDmrs at the top of this section and run this section again.')
else
    predDmrs = table(myPredictionDmrs, dmrsRECount, ...
        VariableNames = {'YouPredicted','Result'});
    predDmrs
end
%% B1b — After the run
% Two of the three known signals go down and one, SRS, goes up: the phone sends
% it so the base station can measure the uplink. DM-RS and CSI-RS are both downlink
% pilots but do different jobs, which the figure below makes visible. In the
% RE-count table, compare the DM-RS count with the PDSCH count, and read the
% CSI-RS and SRS counts against the patterns in the figure.
%% B1b — Verification results


% Assertions stop execution when a stated relationship fails. This table
% makes the verified relationships visible in the Live Editor.

checkPassed = [ ...
    checkTableRows; ...
    checkDMRSInsidePDSCH; ...
    checkSRSComb2; ...
    checkCSIRSSparse; ...
    checkSRSOneSymbol];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

signalMapCheckName = [ ...
    "Signal-role table dimensions"; ...
    "DM-RS placement"; ...
    "SRS comb pattern"; ...
    "CSI-RS density"; ...
    "SRS time occupancy"];

signalMapExpected = [ ...
    "Six matched table rows"; ...
    "DM-RS lies within PDSCH"; ...
    "Every second subcarrier"; ...
    "Sparse known-signal pattern"; ...
    "One OFDM symbol"];

assert(numel(signalMapCheckName) == numel(signalMapExpected) && ...
    numel(signalMapExpected) == numel(resultText), ...
    'The signal-map verification table columns must have equal height. Look first at the column lists just above: each column needs one entry per row.');

signalMapChecks = table( ...
    signalMapCheckName, ...
    signalMapExpected, ...
    resultText, ...
    VariableNames = {'Check','Expected','Pass'});

signalMapChecks
%% B1b — Focused placement figure
% Top: DM-RS occupies selected REs inside a PDSCH allocation. Middle: CSI-RS 
% occupies a few REs in a downlink grid. Bottom: SRS forms a frequency comb in 
% one uplink symbol. Empty REs are light gray so the grid boundary stays visible.

figure( ...
    Name = 'P00b - focused NR signal patterns', ...
    Color = 'w', ...
    Units = 'pixels', ...
    Position = [80 80 900 1450]);

tl = tiledlayout(3,1, ...
    TileSpacing = 'compact', ...
    Padding = 'compact');

title(tl, ...
    'Known Signals Have Different Jobs and Different Grid Patterns', ...
    FontWeight = 'bold', ...
    FontSize = 15);

% Panel 1 — PDSCH with DM-RS
axPdsch = nexttile;

imagesc(axPdsch, 0:nSymbols-1, 0:nSubcarriers-1, pdschDmrsGrid);
axis(axPdsch, 'xy');
box(axPdsch, 'on');
clim(axPdsch, [0 2]);

colormap(axPdsch, [ ...
    0.96 0.96 0.96; ... % 0: empty
    0.20 0.40 0.80; ... % 1: PDSCH
    0.90 0.30 0.10]);   % 2: DM-RS

xlabel(axPdsch, 'OFDM symbol');
ylabel(axPdsch, 'Subcarrier');

title(axPdsch, { ...
    'PDSCH with DM-RS', ...
    'Known pilots occupy selected REs inside data'});

text(axPdsch, ...
    mean(pdschSymbols)-1, mean(pdschRows)-1, 'PDSCH', ...
    HorizontalAlignment='center', ...
    VerticalAlignment='middle', ...
    Color='w', ...
    FontWeight='bold', ...
    FontSize=11);

cbPdsch = colorbar(axPdsch);
cbPdsch.Ticks = [0 1 2];
cbPdsch.TickLabels = {'empty','PDSCH','DM-RS'};

% Panel 2 — CSI-RS
axCSIRS = nexttile;

imagesc(axCSIRS, 0:nSymbols-1, 0:nSubcarriers-1, csirsGrid);
axis(axCSIRS, 'xy');
box(axCSIRS, 'on');
clim(axCSIRS, [0 1]);

colormap(axCSIRS, [ ...
    0.96 0.96 0.96; ... % 0: empty
    0.25 0.70 0.35]);   % 1: CSI-RS

xlabel(axCSIRS, 'OFDM symbol');
ylabel(axCSIRS, 'Subcarrier');

title(axCSIRS, { ...
    'CSI-RS: measurement downlink', ...
    'Sparse known REs for the phone to measure'});

cbCSIRS = colorbar(axCSIRS);
cbCSIRS.Ticks = [0 1];
cbCSIRS.TickLabels = {'empty','CSI-RS'};

% Panel 3 — SRS
axSRS = nexttile;

imagesc(axSRS, 0:nSymbols-1, 0:nSubcarriers-1, srsGrid);
axis(axSRS, 'xy');
box(axSRS, 'on');
clim(axSRS, [0 1]);

colormap(axSRS, [ ...
    0.96 0.96 0.96; ... % 0: empty
    0.55 0.20 0.75]);   % 1: SRS

xlabel(axSRS, 'OFDM symbol');
ylabel(axSRS, 'Subcarrier');

title(axSRS, { ...
    'SRS: sounding uplink', ...
    'Comb-2: every second subcarrier in one symbol'});

cbSRS = colorbar(axSRS);
cbSRS.Ticks = [0 1];
cbSRS.TickLabels = {'empty','SRS'};
%% B1b — Cleanup (B1a and B1b)

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% B2 is independent of B1. The figure and displayed tables remain visible
% after B1-specific variables are removed from the workspace.

clear signalMap signalMapChecks firstSignals laterSignals ...
    signalName signalDirection signalPurpose introducedIn ...
    nSubcarriers nSymbols ...
    pdschRows pdschSymbols pdschDmrsGrid ...
    dmrsRows dmrsSymbols ...
    csirsGrid csirsRows csirsSymbol ...
    srsGrid srsRows srsSymbol ...
    checkTableRows checkDMRSInsidePDSCH checkSRSComb2 ...
    checkCSIRSSparse checkSRSOneSymbol ...
    checkSSBDownlink checkSRSUplink checkOtherSignalsDownlink ...
    checkPassed resultText ...
    signalMapCheckName signalMapExpected ...
    axPdsch axCSIRS axSRS ...
    cbPdsch cbCSIRS cbSRS tl ...
    pdschRECount dmrsRECount csirsRECount srsRECount dmrsShare reCountResults myPrediction myPredictionDmrs predCompare predDmrs
%% B2 — The coding chain
% New words
% • CRC: check bits that let the receiver detect, not fix, a damaged block.
% 
% • Circular buffer: a list read as if its end joins its start.
% 
% • Redundancy version (RV): which start point in that buffer a transmission 
% reads from.
% Why it matters
% Before transmission, an information block passes five steps, each with one 
% job:
% 
% 1. CRC: append check bits so the receiver can detect an error. It never corrects 
% one.
% 
% 2. Channel coding: add structured redundancy so errors can be corrected.
% 
% 3. Rate matching: read exactly E coded bits from a circular buffer, starting 
% at a point set by the redundancy version (RV).
% 
% 4. Scrambling: XOR with a known sequence so a neighbour cell's interference 
% looks like noise.
% 
% 5. Modulation: map bits to constellation symbols.
% 
% The code rate is the information bits divided by the coded bits sent:
% 
% $$R = \frac{K}{E}$$
% 
% A CRC detects errors by polynomial division in binary: the sender appends 
% the remainder, so a clean received block divides with remainder zero. An error 
% pattern that happens to be a multiple of the generator also gives zero and slips 
% through, which is why an L-bit CRC misses about
% 
% $$P_{\mathrm{miss}} \approx 2^{-L}$$
% 
% of random error patterns.
% What to look for
% • In the code-rate table, compare R with K divided by E, and the miss count 
% with 2 to the power of the CRC length.
% 
% • In the toy-chain table, read the CRC remainder in each of the three received 
% cases: zero means "looks clean", nonzero means "error detected".
% 
% • In the circular-buffer panel, find where RV0 and RV2 start reading and whether 
% either read wraps past the end of the buffer.
% 
% • Compare the toy chain's lengths: 8 information bits, then the CRC, then the 
% code, then E bits, then E/2 QPSK symbols.
% Common mistakes
% Do not think a CRC corrects errors. It only says "something is wrong"; correction 
% is the channel code's job, or a retransmission's.
% 
% Do not think a passing CRC is a guarantee. A very likely right block is not 
% a certainly right block.
% 
% Do not confuse the redundancy version with a different code. Every RV reads 
% the same circular buffer; only the starting point changes.
% Try it (personal exploration)
% Use R = K/E to predict the toy chain's code rate: count the information bits 
% in toyMessage and read toyE in the code. Type the rate (a decimal) into myPrediction 
% in the first code line below before you run this section. After the toy-chain 
% tables, a given table shows your predictions beside the results. Also predict,
% from 2^−L, roughly how often a 4-bit CRC lets a random error pattern through,
% and type that rate into myPredictionMiss.
% 
% Then change toyE to 24 (keep it even, for QPSK), predict the new toy rate 
% and the number of QPSK symbols, and run again. The toy checks hold for any 
% even toyE from 14 to 24 (the buffer size), so the run does not stop.

% Try it: type your predictions here before running this section.
myPrediction = NaN;        % toy code rate, R = K/E
myPredictionMiss = NaN;    % approximate miss rate of a 4-bit CRC, from 2^(-L)

% The K and E just below belong to a narrated example, not the toy chain
% you are rating. Their rate is shown after the toy compare.
informationBits_K = 1000;
transmittedBits_E = 2000;
codeRate_R = informationBits_K / transmittedBits_E;

% A 24-bit CRC misses a random error pattern with probability approximately
% 2^(-24), or roughly one pattern in 16.8 million.
crcLength_bits = 24;
crcMissProbability = 2^(-crcLength_bits);
crcMissOneIn = 1 / crcMissProbability;

% Each row identifies one transformation in the simplified coding chain.
codingStep = (1:5).';

codingOperation = [ ...
    "CRC"; ...
    "Channel coding"; ...
    "Rate matching"; ...
    "Scrambling"; ...
    "Modulation"];

codingPurpose = [ ...
    "Detect errors"; ...
    "Add structured redundancy"; ...
    "Select exactly E coded bits"; ...
    "Make neighbouring-cell interference resemble noise"; ...
    "Map bits to constellation symbols"];

assert(numel(codingStep) == numel(codingOperation) && ...
    numel(codingOperation) == numel(codingPurpose), ...
    'The coding-chain table columns must have the same number of rows. Look first at the column lists just above: each column needs one entry per row.');

codingChain = table( ...
    codingStep, ...
    codingOperation, ...
    codingPurpose, ...
    VariableNames = {'Step','Operation','Purpose'});

codingChain

% This separate table contains the numerical code-rate and CRC example.
codingQuantity = [ ...
    "Information bits, K"; ...
    "Transmitted coded bits, E"; ...
    "Code rate, R = K/E"; ...
    "CRC length"; ...
    "Approximate random-error miss probability"; ...
    "Approximate one-in miss count"];

codingValue = [ ...
    string(sprintf('%d bits', informationBits_K)); ...
    string(sprintf('%d bits', transmittedBits_E)); ...
    string(sprintf('%.2f', codeRate_R)); ...
    string(sprintf('%d bits', crcLength_bits)); ...
    string(sprintf('2^{-%d}', crcLength_bits)); ...
    string(sprintf('1 in %.0f', crcMissOneIn))];

assert(numel(codingQuantity) == numel(codingValue), ...
    'The coding-results table columns must have the same number of rows. Look first at the column lists just above: each column needs one entry per row.');

codingResults = table( ...
    codingQuantity, ...
    codingValue, ...
    VariableNames = {'Quantity','Value'});

% (The narrated example table is shown after the toy-rate compare.)
% A toy coding chain on real bits
% The same five steps, small enough to follow bit by bit. The 4-bit CRC and
% the repetition code are stand-ins for NR's longer CRCs and its LDPC and polar 
% codes; the circular buffer uses NR's RV start fractions for LDPC base graph 
% 1 (0, 17/66, 33/66, and 56/66 of the buffer).

% Step 1: CRC. Divide the message, padded with four zeros, by the generator
% g(x) = x^4 + x + 1 in binary, and append the 4-bit remainder.
toyMessage = [1 0 1 1 0 0 1 0];
crcGenerator = [1 0 0 1 1];
toyCRCLength = numel(crcGenerator) - 1;
toyCRC = crcRemainder([toyMessage zeros(1, toyCRCLength)], crcGenerator);
toyCodeword = [toyMessage toyCRC];

% The receiver divides what it gets by the same generator.
remainderClean = crcRemainder(toyCodeword, crcGenerator);

% A single flipped bit (bit 3) leaves a nonzero remainder: detected.
rxFlipped = toyCodeword;
rxFlipped(3) = 1 - rxFlipped(3);
remainderFlipped = crcRemainder(rxFlipped, crcGenerator);

% An error pattern equal to the generator itself (bits 4 to 8) is a multiple
% of g(x), so the remainder is zero and the error is missed.
generatorError = zeros(1, numel(toyCodeword));
generatorError(4:8) = crcGenerator;
rxMissed = double(xor(toyCodeword, generatorError));
remainderMissed = crcRemainder(rxMissed, crcGenerator);

% Every possible single-bit error should be detected by this CRC.
singleErrorDetected = false(1, numel(toyCodeword));
for bitIndex = 1:numel(toyCodeword)
    rxOne = toyCodeword;
    rxOne(bitIndex) = 1 - rxOne(bitIndex);
    singleErrorDetected(bitIndex) = any(crcRemainder(rxOne, crcGenerator));
end

% Step 2: channel coding. A rate-1/2 repetition code (each bit sent twice)
% stands in for LDPC; it adds redundancy without being the NR code.
toyCoded = repelem(toyCodeword, 2);
toyNcb = numel(toyCoded);

% Step 3: rate matching. Read toyE bits from the circular buffer, starting at
% the RV start position k0 and wrapping around the end when needed.
% Counting convention (used for the rest of this file): k0 is 0-based, as in
% the specification. MATLAB list indices are 1-based, so add 1 only when the
% position is used to index an array.
toyE = 18;
rvFractions = [0 17 33 56] / 66;
toyK0 = floor(rvFractions * toyNcb);
readRV0 = zeros(1, toyE);
readRV2 = zeros(1, toyE);
for readStep = 0:toyE-1
    readRV0(readStep + 1) = mod(toyK0(1) + readStep, toyNcb) + 1;
    readRV2(readStep + 1) = mod(toyK0(3) + readStep, toyNcb) + 1;
end
rateMatchedRV0 = toyCoded(readRV0);
rateMatchedRV2 = toyCoded(readRV2);

% Step 4: scrambling. XOR with a known pseudo-random sequence; the receiver,
% knowing the same sequence, undoes it with a second XOR.
scramblingSequence = randi([0 1], 1, toyE);
toyScrambled = double(xor(rateMatchedRV0, scramblingSequence));
toyDescrambled = double(xor(toyScrambled, scramblingSequence));

% Step 5: modulation. QPSK takes the bits in pairs.
toyQPSK = ((1 - 2*toyScrambled(1:2:end)) + 1j*(1 - 2*toyScrambled(2:2:end))) / sqrt(2);

toyRate = numel(toyMessage) / toyE;

checkToyClean = all(remainderClean == 0);
checkToyFlipDetected = any(remainderFlipped ~= 0);
checkToyMiss = all(remainderMissed == 0);
checkToyAllSingles = all(singleErrorDetected);
checkToyLength = numel(rateMatchedRV0) == toyE && numel(rateMatchedRV2) == toyE;
checkToyWrap = readRV2(end) < readRV2(1);
checkToyCoverage = numel(union(readRV0, readRV2)) == toyNcb;
checkToyScrambling = isequal(toyDescrambled, rateMatchedRV0);
checkToyQPSK = numel(toyQPSK) == toyE/2;

assert(checkToyClean, 'A clean CRC codeword should leave a zero remainder. Look first at the zeros padding before crcRemainder and at crcGenerator.');
assert(checkToyFlipDetected, 'A single flipped bit should leave a nonzero CRC remainder. Look first at rxFlipped: exactly one bit should differ from toyCodeword.');
assert(checkToyMiss, 'An error pattern equal to the generator should leave a zero remainder (a missed error). Look first at generatorError: it must hold crcGenerator itself. Common mistake: thinking a passing CRC is a guarantee.');
assert(checkToyAllSingles, 'Every single-bit error should be detected by the 4-bit CRC. Look first at crcGenerator: it must start and end with 1.');
assert(checkToyLength, 'Rate matching should read exactly E bits for each RV. Look first at the 0:toyE-1 range in readRV0 and readRV2.');
assert(checkToyWrap, 'The RV2 read should wrap past the end of the circular buffer. Look first at toyE and toyK0(3): from this start, a read of fewer than 13 bits does not reach the end. Common mistake: no wrap.');
assert(checkToyCoverage, 'RV0 and RV2 together should cover every bit of the buffer. Look first at toyE: a read shorter than half the buffer leaves gaps.');
assert(checkToyScrambling, 'Descrambling with the same sequence should recover the rate-matched bits. Look first at scramblingSequence: the receiver must XOR with the same one.');
assert(checkToyQPSK, 'QPSK should produce E/2 symbols. Look first at toyE: QPSK needs an even number of bits.');

% Display each stage of the toy chain as bit strings, so the lengths and the
% CRC bits can be read directly.
toyChainResults = table( ...
    ["Information bits (K)"; "CRC remainder appended"; "Codeword"; ...
     "Repetition-coded buffer"; "RV0 start, RV2 start (k0)"; ...
     "Rate-matched bits, RV0 (E)"; "Scrambled bits"; "QPSK symbols"; "Toy code rate K/E"], ...
    [strjoin(string(toyMessage), ""); strjoin(string(toyCRC), ""); ...
     strjoin(string(toyCodeword), ""); strjoin(string(toyCoded), ""); ...
     sprintf('%d, %d of %d', toyK0(1), toyK0(3), toyNcb); ...
     strjoin(string(rateMatchedRV0), ""); strjoin(string(toyScrambled), ""); ...
     string(numel(toyQPSK)); sprintf('%d/%d = %.3f', numel(toyMessage), toyE, toyRate)], ...
    VariableNames = {'Stage','Bits'});

toyChainResults

% Display the CRC remainder in the three received cases. The verdict is computed
% from the remainder and from whether an error was actually added, never typed.
errorAdded = [false; true; true];
remainderIsZero = [all(remainderClean == 0); all(remainderFlipped == 0); all(remainderMissed == 0)];
crcVerdict = repmat("error detected", 3, 1);
crcVerdict(remainderIsZero & ~errorAdded) = "looks clean";
crcVerdict(remainderIsZero & errorAdded) = "error missed";
toyCRCResults = table( ...
    ["Clean codeword"; "Bit 3 flipped"; "Generator-shaped error, bits 4 to 8"], ...
    [strjoin(string(remainderClean), ""); strjoin(string(remainderFlipped), ""); ...
     strjoin(string(remainderMissed), "")], ...
    crcVerdict, ...
    VariableNames = {'ReceivedCase','Remainder','Verdict'});

toyCRCResults

% Compare your Try-it prediction with the result, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run it again.')
else
    predCompare = table(myPrediction, toyRate, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
if isnan(myPredictionMiss)
    disp('No CRC-miss prediction recorded: type a number into myPredictionMiss at the top of this section and run this section again.')
else
    predMiss = table(myPredictionMiss, 2^(-toyCRCLength), ...
        VariableNames = {'YouPredicted','Result'});
    predMiss
end

% Narrated example (not the toy chain): 1000 information bits in 2000 sent
% bits. Its code rate is one half. A 24-bit CRC is shown here for scale.
codingResults

%% B2 — After the run
% Compare the clean, flipped, and generator-shaped remainders in the CRC
% table. In the circular-buffer panel, compare where the two RVs start and
% whether either wrap leaves bits the other never sent. Then read the
% narrated-example table above as a contrast, not as the toy rate.
%% B2 — Verification results


% These assertions verify the narrated worked example and the stated coding
% chain order.

checkCodeRate = abs(codeRate_R - 0.5) < 1e-12;

checkCRCMissScale = crcMissOneIn > 1e7 && crcMissOneIn < 2e7;

checkCodingChainLength = height(codingChain) == 5;

assert(checkCodeRate, ...
    'K = 1000 and E = 2000 should produce code rate R = 0.5. Look first at the line codeRate_R = informationBits_K / transmittedBits_E.');

assert(checkCRCMissScale, ...
    'A 24-bit CRC miss rate should be approximately one in 16.8 million. Look first at crcLength_bits and the 2^(-L) line.');

assert(checkCodingChainLength, ...
    'The introductory coding chain should contain five operations. Look first at codingOperation: five steps, CRC to modulation.');

checkPassed = [ ...
    checkCodeRate; ...
    checkCRCMissScale; ...
    checkCodingChainLength];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

codingCheckName = [ ...
    "Worked code rate"; ...
    "24-bit CRC detection scale"; ...
    "Coding-chain length"];

codingExpected = [ ...
    "1000 / 2000 = 0.5"; ...
    "Approximately 1 in 2^24 random patterns"; ...
    "Five operations"];

assert(numel(codingCheckName) == numel(codingExpected) && ...
    numel(codingExpected) == numel(resultText), ...
    'The coding verification-table columns must have the same number of rows. Look first at the column lists just above: each column needs one entry per row.');

codingChecks = table( ...
    codingCheckName, ...
    codingExpected, ...
    resultText, ...
    VariableNames = {'Check','Expected','Pass'});

codingChecks

% The toy-chain assertions above stop execution on failure; this table makes
% the successful toy checks visible.
toyCheckPassed = [checkToyClean; checkToyFlipDetected; checkToyMiss; ...
    checkToyAllSingles; checkToyLength; checkToyWrap; checkToyCoverage; ...
    checkToyScrambling; checkToyQPSK];
toyResultText = repmat("Pass", numel(toyCheckPassed), 1);
toyResultText(~toyCheckPassed) = "Fail";

toyChecks = table( ...
    ["Clean CRC remainder"; "Single flip detected"; "Generator-shaped error"; ...
     "All single-bit errors"; "Rate-matched length"; "RV2 wraps"; ...
     "RV0 + RV2 coverage"; "Descrambling"; "QPSK symbol count"], ...
    ["0000"; "Nonzero remainder"; "Zero remainder: missed"; ...
     "All 12 detected"; "E bits per RV"; "Read passes the buffer end"; ...
     "Every buffer bit sent at least once"; "XOR twice returns the bits"; "E/2"], ...
    toyResultText, ...
    VariableNames = {'Check','Expected','Pass'});

toyChecks
%% B2 — Coding-chain figure
% An overview of the five steps with the narrated worked example. The mechanism 
% itself is in the toy-chain figure that follows.

% This is a conceptual process diagram. Later tracks use toolbox objects for
% actual NR coding, rate matching, HARQ, and decoding.

figure( ...
    Name = 'P00b - schematic coding chain', ...
    Color = 'w', ...
    Units = 'pixels', ...
    Position = [100 100 1200 330]);

ax = axes;
% Hold the axes so each rectangle, arrow, and label adds to the drawing
% instead of replacing it.
hold(ax, 'on');
axis(ax, 'off');
xlim(ax, [0 6]);
ylim(ax, [0 1]);

chainLabels = { ...
    'Information bits'; ...
    'CRC'; ...
    'Channel coding'; ...
    'Rate matching'; ...
    'Scrambling'; ...
    'Modulation'};

chainColors = [ ...
    0.20 0.40 0.80; ...
    0.85 0.20 0.20; ...
    0.20 0.65 0.35; ...
    0.90 0.55 0.10; ...
    0.55 0.20 0.75; ...
    0.15 0.15 0.15];

for stepIndex = 1:numel(chainLabels)

    boxLeft = stepIndex - 0.88;
    boxBottom = 0.38;
    boxWidth = 0.72;
    boxHeight = 0.28;

    rectangle( ...
        Position = [boxLeft boxBottom boxWidth boxHeight], ...
        Curvature = 0.08, ...
        FaceColor = chainColors(stepIndex,:), ...
        EdgeColor = [0.15 0.15 0.15], ...
        LineWidth = 1.0);

    text( ...
        boxLeft + boxWidth/2, ...
        boxBottom + boxHeight/2, ...
        chainLabels{stepIndex}, ...
        HorizontalAlignment = 'center', ...
        VerticalAlignment = 'middle', ...
        FontSize = 9, ...
        FontWeight = 'bold', ...
        Color = 'w');

    if stepIndex < numel(chainLabels)
        xStart = boxLeft + boxWidth;
        xEnd = stepIndex + 0.12;

        plot([xStart xEnd], [0.52 0.52], '-k', ...
            LineWidth = 1.1, ...
            HandleVisibility = 'off');

        plot(xEnd, 0.52, '>', ...
            MarkerSize = 6, ...
            MarkerFaceColor = 'k', ...
            MarkerEdgeColor = 'k', ...
            HandleVisibility = 'off');
    end
end

text( ...
    3.0, 0.15, ...
    sprintf('Worked example: K = %d bits, E = %d bits, R = K/E = %.2f', ...
    informationBits_K, transmittedBits_E, codeRate_R), ...
    HorizontalAlignment = 'center', ...
    VerticalAlignment = 'middle', ...
    FontSize = 11, ...
    FontWeight = 'bold');

title('Before transmission: protect the block, fit it to the grid, then map it to symbols');
%% B2 — Toy-chain figure
% Top: the toy bits at each stage (dark = 1, light = 0, blank = no bit). Bottom 
% left: the circular buffer, with the bits RV0 and RV2 read. Bottom right: the 
% CRC remainder in the three received cases.

figure( ...
    Name = 'P00b - toy coding chain on real bits', ...
    Color = 'w', ...
    Position = [100 80 1200 820]);

tlToy = tiledlayout(2,2, TileSpacing='loose', Padding='compact');

% Stage rows are padded with NaN so rows of different lengths fit one image.
stageRows = {toyMessage, toyCodeword, toyCoded, rateMatchedRV0, toyScrambled};
stageNames = {'information bits','+ CRC','coded buffer','rate-matched (RV0)','scrambled'};
stageImage = nan(numel(stageRows), toyNcb);
for rowIndex = 1:numel(stageRows)
    stageImage(rowIndex, 1:numel(stageRows{rowIndex})) = stageRows{rowIndex};
end

nexttile([1 2]);
imagesc(stageImage, AlphaData=~isnan(stageImage));
colormap(gca, [0.85 0.90 0.97; 0.15 0.30 0.65]);
clim([0 1]);
hold on;
% Outline the four CRC bits in the codeword row.
rectangle(Position=[numel(toyMessage)+0.5, 1.5, toyCRCLength, 1], ...
    EdgeColor=[0.85 0.20 0.20], LineWidth=2.5);
hold off;
yticks(1:numel(stageNames));
yticklabels(stageNames);
xlabel('Bit position');
title('Each stage changes the bits: the CRC adds 4, the code doubles them, rate matching keeps E');

% Circular buffer: draw the toyNcb coded bits around a circle, then mark the
% positions RV0 and RV2 read on two outer rings.
nexttile;
angles = pi/2 - 2*pi*(0:toyNcb-1)/toyNcb;
scatter(cos(angles), sin(angles), 120, toyCoded, 'filled', MarkerEdgeColor='k');
colormap(gca, [0.85 0.90 0.97; 0.15 0.30 0.65]);
clim([0 1]);
hold on;
scatter(1.18*cos(angles(readRV0)), 1.18*sin(angles(readRV0)), 30, ...
    [0.10 0.55 0.25], 'filled');
scatter(1.32*cos(angles(readRV2)), 1.32*sin(angles(readRV2)), 30, ...
    [0.85 0.45 0.10], 'filled');
text(1.55*cos(angles(toyK0(1)+1)), 1.55*sin(angles(toyK0(1)+1)), 'RV0 start', ...
    HorizontalAlignment='center', Color=[0.10 0.55 0.25], FontWeight='bold');
text(1.55*cos(angles(toyK0(3)+1)), 1.55*sin(angles(toyK0(3)+1)), 'RV2 start', ...
    HorizontalAlignment='center', Color=[0.85 0.45 0.10], FontWeight='bold');
hold off;
axis equal off;
xlim([-1.9 1.9]); ylim([-1.9 1.9]);
title({sprintf('Circular buffer of %d coded bits', toyNcb), sprintf('inner dots: RV0 reads %d; outer dots: RV2 reads %d and wraps', toyE, toyE)});

% CRC remainders as decimal values: zero means the check passes.
nexttile;
remainderValues = [bin2dec(char(remainderClean + '0')), ...
    bin2dec(char(remainderFlipped + '0')), bin2dec(char(remainderMissed + '0'))];
bar(categorical({'clean','bit 3 flipped','generator-shaped error'}, ...
    {'clean','bit 3 flipped','generator-shaped error'}), remainderValues, ...
    FaceColor=[0.20 0.40 0.80]);
grid on;
ylabel('CRC remainder (as a 4-bit number)');
title({'Zero remainder = looks clean', 'the generator-shaped error is missed'});
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The Build it section follows. Figures and displayed tables remain visible
% after cleanup.

clear codingChain codingResults codingChecks ...
    informationBits_K transmittedBits_E codeRate_R ...
    crcLength_bits crcMissProbability crcMissOneIn ...
    codingStep codingOperation codingPurpose ...
    codingQuantity codingValue ...
    checkCodeRate checkCRCMissScale checkCodingChainLength ...
    checkPassed resultText ...
    codingCheckName codingExpected ...
    ax chainLabels chainColors stepIndex ...
    boxLeft boxBottom boxWidth boxHeight xStart xEnd ...
    toyMessage crcGenerator toyCRCLength toyCRC toyCodeword ...
    remainderClean rxFlipped remainderFlipped generatorError rxMissed remainderMissed ...
    singleErrorDetected bitIndex rxOne toyCoded toyNcb toyE rvFractions toyK0 ...
    readRV0 readRV2 rateMatchedRV0 rateMatchedRV2 scramblingSequence ...
    toyScrambled toyDescrambled toyQPSK toyRate ...
    checkToyClean checkToyFlipDetected checkToyMiss checkToyAllSingles ...
    checkToyLength checkToyWrap checkToyCoverage checkToyScrambling checkToyQPSK ...
    toyChainResults toyCRCResults toyCheckPassed toyResultText toyChecks ...
    tlToy stageRows stageNames stageImage rowIndex angles remainderValues ...
    errorAdded remainderIsZero crcVerdict myPrediction myPredictionMiss predCompare predMiss codingResults
%% Build it — Read a retransmission from a circular buffer
% Competency: read exactly E bits from a circular buffer, starting at the redundancy 
% version's start point and wrapping past the end.
% Problem
% You are given codedBuffer, a buffer of 20 coded bits. To make the reading 
% visible, each entry holds its own position number (1 to 20) instead of a bit. 
% A retransmission with RV2 starts at k0 = floor(33 × Ncb / 66), counted from 
% 0, and reads E = 14 entries in order, going back to the start of the buffer 
% when it passes the end. Build readIdx, the 14 positions read, and rmOut, the 
% 14 entries read.
% Allowed commands
% The colon a:b; indexing x(v); numel; floor; mod; the arithmetic operators + 
% - * /; disp; fprintf. The plotting in Stage 5 is given.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at.
%% Stage 1 — switch it on
% Delete the % in front of the two code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% codedBuffer = 1:20;   % entry n holds the number n, so you can see what was read
% disp(codedBuffer)
%% Stage 1 check (given)
if ~exist('codedBuffer','var')
    disp('Stage 1 not done: delete the % in front of the two code lines above, then run that section.')
else
    assert(numel(codedBuffer) == 20, ...
        'codedBuffer should hold 20 entries. Look at the 1:20 range.')
    disp('Stage 1 OK')
end
%% Stage 2 — name and shape: buffer size, read length, start point
% Rename n, e, and s to Ncb, E, and k0, the names the checks expect. Ncb is 
% the buffer size; E is how many entries this transmission reads; k0 is the RV2 
% start point.
% Pass: Stage 2 OK.

% n = numel(codedBuffer);
% e = 14;
% s = floor(33 * n / 66);   % RV2 start, counted from 0
%% Stage 2 check (given)
if ~exist('Ncb','var') || ~exist('E','var') || ~exist('k0','var')
    disp('Stage 2 not done: rename n, e, and s to Ncb, E, and k0, uncomment, and run.')
else
    assert(Ncb == numel(codedBuffer), ...
        'Ncb should be the number of entries in codedBuffer. Look at what numel is given.')
    assert(k0 >= 0 && k0 < Ncb && k0 == floor(k0), ...
        'k0 should be a whole number from 0 to Ncb - 1. Look at the floor around the fraction.')
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: the last position read
% Before you build the index list, type your prediction: which buffer position
% is the last one read? Count on from the start point and remember the wrap.
% k0 is 0-based; the position you type should be a MATLAB (1-based) index.
% Run this section and the check under it before you start Stage 3b: the check
% does not take a prediction once Stage 3b's names exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with the wrap rule and does not print the value)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif ~exist('Ncb','var') || ~exist('E','var') || ~exist('k0','var')
    disp('Stage 3a needs Stage 2 first: make Ncb, E, and k0, then return here.')
elseif exist('readIdx','var') || exist('rmOut','var')
    disp('Stage 3a refused: Stage 3b or Stage 4 names already exist, so this is no longer a prediction. Run "clear readIdx rmOut", then predict again.')
else
    % Different route: the last read is E steps on from k0, wrapped, then
    % converted to a MATLAB index. This does not use readIdx.
    oracleLast = mod(k0 + E - 1, Ncb) + 1;
    okPrediction3 = (myPrediction == oracleLast);
    stage3aCheck = table("Prediction = last MATLAB index read for this RV", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at the 0-based start k0, then count E entries with a wrap at Ncb, then add 1 for MATLAB. Change myPrediction and run again.')
    end
end
%% Stage 3b — build the read positions
% Fill the blank with a whole right-hand side: a list of E MATLAB indices that
% starts at the RV start, steps one place at a time, and wraps at the buffer end.
% k0 itself is 0-based.
% Pass: your locked prediction and the last index you built appear side by side,
% and Stage 3 OK.

% readIdx = ___;
%% Stage 3b check (given; it looks at readIdx before anything is read with it)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('readIdx','var')
    disp('Stage 3b not done: fill the blank with a whole right-hand side, uncomment, and run.')
else
    % Your locked prediction beside the last index you built.
    stage3Prediction = table(myLockedPrediction, readIdx(end), ...
        VariableNames = {'MyPrediction', 'LastIndexBuilt'});
    stage3Prediction

    okStage3 = [numel(readIdx) == E; ...
                readIdx(1) == k0 + 1; ...
                max(readIdx) <= Ncb; ...
                min(readIdx) >= 1];
    assert(okStage3(1), ...
        'readIdx should hold exactly E positions. Look at how many steps you took.')
    assert(okStage3(2), ...
        'The read does not start at the RV start point. Common mistake: off by one between counting from 0 and from 1.')
    assert(okStage3(3), ...
        'Some positions are past the end of the buffer. Common mistake: no wrap. Look at how you wrap at the buffer length.')
    assert(okStage3(4), ...
        'A position is 0, which MATLAB cannot index. Common mistake: off by one; MATLAB counts from 1.')
    stage3Checks = table( ...
        ["Length is E"; "Starts at k0 + 1"; "No index past Ncb"; "No index below 1"], ...
        okStage3, VariableNames = {'Check', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — read the bits
% Fill the blank with a whole right-hand side so rmOut holds the entries of
% codedBuffer at the positions in readIdx.
% Pass: your locked prediction and the last entry read appear side by side, and
% Stage 4 OK.

% rmOut = ___;
%% Stage 4 check (given; the check rotates the buffer, a different route from yours)
if ~exist('myLockedPrediction','var') || ~exist('readIdx','var')
    disp('Stage 4 needs Stages 3a and 3b first.')
elseif ~exist('rmOut','var')
    disp('Stage 4 not done: fill the blank, uncomment, and run.')
else
    predCompare = table(myLockedPrediction, rmOut(end), ...
        VariableNames = {'MyPrediction','LastEntryRead'});
    predCompare
    rotated = circshift(codedBuffer, -k0);   % the RV start point moves to the front
    oracle = rotated(1:E);
    assert(numel(rmOut) == E, ...
        'rmOut should hold E entries. Look at what you put inside the brackets.')
    assert(isequal(rmOut, oracle), ...
        'rmOut does not match the circular read. Look at the order of the entries around the wrap.')
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them. Rows marked
% "repeat of Stage n" only repeat an earlier check; the wrap row uses a sign
% you have not yet compared this way.

if ~exist('rmOut','var') || ~exist('oracle','var') || ~exist('myLockedPrediction','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your result, so the table cannot say Pass by itself.
    buildFlags = [numel(rmOut) == E; ...
        rmOut(1) == codedBuffer(k0 + 1); ...
        any(diff(readIdx) < 0); ...
        isequal(rmOut, oracle)];
    buildResult = repmat("Fail", numel(buildFlags), 1);
    buildResult(buildFlags) = "Pass";

    % Asserts above stop the run on failure; this table makes the passes visible.
    buildChecks = table(["Read length (repeat of Stage 3)"; "Start point (repeat of Stage 3)"; ...
        "Wraps past the end"; "Matches the rotated buffer (repeat of Stage 4)"], ...
        ["E entries"; "position k0 + 1"; "a position drops back near 1"; "same as circshift by -k0"], ...
        buildResult, VariableNames = {'Check','Expected','Pass'});
    buildChecks

    figure(Name = 'P00b Build it - my circular-buffer read', Color = 'w');
    ringAngle = pi/2 - 2*pi*(0:Ncb-1)/Ncb;   % position 1 at the top, going clockwise
    plot(cos(ringAngle), sin(ringAngle), 'o', MarkerSize = 14, Color = [0.6 0.6 0.6]);
    hold on;
    plot(cos(ringAngle(readIdx)), sin(ringAngle(readIdx)), 'o', MarkerSize = 14, ...
        MarkerFaceColor = [0.20 0.40 0.80], MarkerEdgeColor = 'k');
    plot(cos(ringAngle(readIdx(1))), sin(ringAngle(readIdx(1))), 'p', MarkerSize = 22, ...
        MarkerFaceColor = [0.90 0.30 0.10], MarkerEdgeColor = 'k');
    text(1.2*cos(ringAngle), 1.2*sin(ringAngle), string(1:Ncb), HorizontalAlignment = 'center');
    hold off;
    axis equal off;
    title({'Blue: positions read for this RV', 'Star: the RV start point'});
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): which
% buffer positions did this read skip, and why would a retransmission with a
% different RV be useful to the receiver?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. The check uses your
% read and does not print a model sentence.
myAnswer = NaN;   % how many buffer positions did this read skip?
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('readIdx','var') || ~exist('Ncb','var')
    disp('Run Stages 1 to 5 first, then return here.')
else
    nSkipped = numel(setdiff(1:Ncb, readIdx));
    okInterp = (myAnswer == nSkipped);
    interpCheck = table("Positions this read skipped", ...
        okInterp, VariableNames = {'Check','Pass'});
    interpCheck
end
%% Build it — Cleanup
% If a later section says a variable is undefined, run the script from the top
% (Run All). Figures remain open. Names the Review needs are not used here.
clear buildFlags buildResult buildChecks predCompare oracle nSkipped okInterp ...
    interpCheck myAnswer ringAngle oracleLast okPrediction3 stage3aCheck ...
    okStage3 stage3Checks
%% Follow-on exercises
% These go one step past the beats: a new value, or a diagnosis. Copying a
% block from above and changing one number will not answer them. The checks
% do not print a model value.
%% E1 — New value
% If the rate matcher emits 20 bits and maps them to QPSK, how many symbols
% does it produce? Type that number into myAnswer, then run this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE1 = (myAnswer == 20/2);
    e1Check = table("E1 QPSK symbols", okE1, VariableNames = {'Check','Pass'});
    e1Check
end
%% E2 — Diagnosis
% k0 is 0-based. A classmate used codedBuffer(k0) as the first MATLAB index.
% For this Build-it's k0, what index should they have used? Type that number
% into myAnswer, then run this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
elseif ~exist('k0','var')
    disp('Run the Build it stages first, then return here.')
else
    okE2 = (myAnswer == k0 + 1);
    e2Check = table("E2 first MATLAB index", okE2, VariableNames = {'Check','Pass'});
    e2Check
end
%% Exercise cleanup
clear myAnswer okE1 e1Check okE2 e2Check
%% Recap — P00b Map of the Link: Signal Map and Coding
% The SSB comes first; after it, control, data with its pilots, and two measurement
% signals share one grid. Every block of bits is protected by the same five-step
% chain.
% Key relationships
% The code rate compares information bits with the coded bits sent:
%
% $$R = \frac{K}{E}$$
%
% An L-bit CRC misses a random error pattern with probability about
%
% $$P_{\mathrm{miss}} \approx 2^{-L}$$
% What this means in practice
% • A phone that has not found the SSB cannot read control or data. SRS is the
% one signal in this map the phone sends.
%
% • Pilots and measurement signals cost REs: every DM-RS RE is an RE that does
% not carry data.
%
% • A CRC detects but never corrects, and a passing CRC is very likely right,
% not certainly right; a longer CRC makes a random miss far rarer.
%
% • Rate matching fits the coded block to the E bits the grid has room for,
% and a new RV on a retransmission sends bits the first attempt skipped.
%
% • You built a circular-buffer read of E positions from an RV start point,
% wrapping past the end, checked against a rotated copy of the buffer.
%
% • Next in the album: the soft-bits and dynamics half of P00b.
%% Review — self-check
% Collapse or scroll past the Recap so it is out of sight, then write from
% memory, in your own words. Do not look back until you have written what you
% can. Nothing in the written lists below is graded by the script.
%
% First, restate each Key relationship from the front of the file, one line
% each. Then, for each command you write yourself (a:b and a:s:b; mod; xor;
% for ... end), give its purpose, its inputs, and its outputs. When you have
% written all you can, scroll up to Key relationships and Key code terms and
% compare. Mark anything you missed.
% My key relationships
% 1.
%
% 2.
% Commands I write (purpose; inputs; outputs)
% • a:b and a:s:b:
%
% • mod:
%
% • xor:
%
% • for ... end:
% What I missed, and where to reread it
%
%% Review — retrieval
% Still keeping the Recap collapsed, type a number into myAnswer and run this
% section. From P00a, how many bits does one QPSK symbol carry? Using that,
% how many QPSK symbols does this file's toy chain produce at its default E
% of 18? The check uses a second route and does not print a model value.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    symbolsFromDefaultE = 18 / 2;
    okReview = (myAnswer == symbolsFromDefaultE);
    reviewCheck = table("QPSK symbols at the toy default E", okReview, ...
        VariableNames = {'Check','Pass'});
    reviewCheck
end
%% Local functions

function remainder = crcRemainder(bits, generator)
% Divide a bit vector by a generator polynomial in binary (XOR, no carries)
% and return the last numel(generator) - 1 bits, which are the remainder.
work = double(bits);
generatorLength = numel(generator);
for k = 1:numel(work) - generatorLength + 1
    if work(k) == 1
        work(k:k+generatorLength-1) = double(xor(work(k:k+generatorLength-1), generator));
    end
end
remainder = work(end-generatorLength+2:end);
end
