%% track05_say_it_again_demo
%% Say It Again (album track 05): transport blocks, MCS, HARQ, and DM-RS
% This demonstration follows one block of data on the downlink data channel 
% (PDSCH) from its size to its second chance. Last time a block arrived with 
% a CRC and the check could fail. Today: what the sender does next.
% 
% It does not start over. It says the same block again, coded differently, 
% and the receiver adds what it hears the second time to what it kept from 
% the first.
%% Guiding question
% How big is a transport block, and how does sending the same block again 
% rescue it when the first try fails?
% This demonstration
% 1. B1 — How big is a block? Work out the transport block size (TBS) from 
% the allocation and the target rate.
% 
% 2. B2 — The MCS table: read two rows of the menu and the block size each 
% one gives.
% 
% 3. B3 — Fail, send again, combine: redundancy version 0, then 2, into one 
% HARQ buffer.
% 
% 4. B4 — What never changes: the block on the retransmission, and what a new 
% rate would change instead.
% 
% 5. B5 — Where the DM-RS sits, and what each extra DM-RS symbol costs.
% 
% 6. Build it — Size a block for a new allocation by hand: its REs per PRB, 
% its coded bits G, its TBS, its CRC, and the code rate it really gets.
% Key relationships
% REs for data in the allocation, and the unquantized information size, for 
% nPRB PRBs, modulation order Qm, υ layers, and target rate R:
% 
% $$N_{\mathrm{RE}} = \min(156,\ N'_{\mathrm{RE}})\cdot n_{\mathrm{PRB}},\qquad N_{\mathrm{info}} 
% = N_{\mathrm{RE}}\cdot R\cdot Q_m\cdot \upsilon$$
% 
% The TBS is N_info quantized (a lookup table when N_info ≤ 3824), so it lands 
% close to N_info. The coded bits the channel carries in one slot are
% 
% $$G = N'_{\mathrm{RE}}\cdot n_{\mathrm{PRB}}\cdot Q_m\cdot \upsilon$$
% 
% where N'_RE (NREPerPRB) is 12 subcarriers × the allocated symbols, minus 
% the REs set aside for DM-RS.
% 
% Two code rates are used in this file. The rate over all tries is the TBS 
% over every coded bit sent, in one try or more (B3). The rate one try really 
% gets is the block with its CRC over the coded bits of one try:
% 
% $$R_{\mathrm{all\ tries}} = \frac{\mathrm{TBS}}{\text{coded bits sent}},\qquad 
% R_{\mathrm{real}} = \frac{\mathrm{TBS} + \mathrm{CRC}}{G}$$
% 
% Mapping type A, single-symbol DM-RS: the first DM-RS is on symbol l0 (DMRSTypeAPosition, 
% 2 or 3). The additional DM-RS symbols depend on l_d, the number of symbols 
% from the start of the slot to the last PDSCH symbol (an excerpt of TS 38.211 
% Table 7.4.1.1.2-3):
% 
% • l_d = 12: one additional position gives {l0, 9}; three give {l0, 5, 8, 
% 11}.
% 
% • l_d = 13 or 14: one additional position gives {l0, 11}; three give {l0, 
% 5, 8, 11}.
% Key ideas to remember
% • The transport block size is not the number of PDSCH bits. nrTBS works it 
% out from the modulation, the layers, the PRBs, the REs per PRB, and the target 
% rate: N_info = N_RE × R × Qm × layers, then quantized.
% 
% • NREPerPRB is 12 × the allocated symbols, minus what the DM-RS takes. G, 
% the coded bits the rate matcher sends, is NREPerPRB × PRBs × Qm × layers.
% 
% • The CRC follows from the TBS: 24 bits if the block is longer than 3824 
% bits, else 16.
% 
% • An MCS row is a modulation and a target code rate from a TS 38.214 table. 
% Choosing the row is link adaptation; it is not the retransmission.
% 
% • HARQ: a block that fails is sent again as a new redundancy version (RV 
% 0 to 3) of the same block, and the decoder soft-combines both in one HARQ 
% process buffer. The toolbox allows up to 32 HARQ processes.
% 
% • The block and its TBS are locked across RVs. Two RVs of the same block 
% are different coded words; a new rate would be a new block.
% 
% • In mapping type A the first DM-RS sits on symbol 2 or 3. Each additional 
% position (0 to 3) adds a DM-RS symbol whose place depends on the allocation 
% length, and costs REs: a smaller NREPerPRB and TBS.
% Prerequisites
% • The resource grid, RBs, the 14-symbol slot, and nrCarrierConfig (album 
% track 01 Two to the Mu, track01/track01_two_to_the_mu_demo).
% 
% • LDPC coding, the CRC, and LLRs (soft bits): album track 04 (Every Check 
% Agrees, track04/track04_every_check_agrees_demo).
% 
% • Rate matching as a read from a circular buffer, starting at an RV offset 
% (track 00 Fundamentals, track00_fundamentals/p00b_signal_map_and_coding_demo).
% 
% • Used here, not taught here: the DM-RS is used to learn the channel in album 
% track 07 (Learn the Channel). Here the channel is noise only, so no channel 
% estimate is needed.
% Words used in this demo
% • PDSCH (physical downlink shared channel): the downlink data channel. Transport 
% block: the data bits handed down for one PDSCH. TBS: its size in bits.
% 
% • PRB (physical resource block): 12 subcarriers for one slot. NREPerPRB: 
% the REs per PRB left for data. G: the coded bits the PDSCH carries.
% 
% • Qm: bits per symbol (2 for QPSK, 4 for 16QAM, 6 for 64QAM). Target code 
% rate R: data bits per coded bit sent.
% 
% • MCS (modulation and coding scheme): a row of the table that names Qm and 
% R. Link adaptation: choosing that row for the channel.
% 
% • HARQ (hybrid automatic repeat request): the receiver answers each block 
% with an ACK or a NACK, and a NACK brings the block again. HARQ process: one 
% block in flight, with its own soft buffer.
% 
% • RV (redundancy version, 0 to 3): where the rate matcher starts reading 
% the coded bits. Soft-combining: adding the LLRs of each try before decoding.
% 
% • DM-RS (demodulation reference signal): known symbols inside the allocation, 
% for learning the channel. Mapping type A: the PDSCH counts its DM-RS place 
% from the start of the slot.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • s.name = value — Purpose: set one property of a configuration object. 
% Inputs: a name, then a value. Outputs: the changed object.
% 
% • abs — Purpose: the size of a difference. Inputs: numbers. Outputs: the 
% result.
% 
% • carrier = nrCarrierConfig(Name = value, ...) — Purpose: describe the carrier: 
% its subcarrier spacing (kHz), its width (NSizeGrid, RBs), and its cell ID. 
% Inputs: name-value pairs. Outputs: a configuration object.
% 
% • pdsch = nrPDSCHConfig — Purpose: describe one PDSCH: PRBSet (the PRBs, 
% 0-based), SymbolAllocation ([first symbol, number of symbols]), Modulation, 
% NumLayers, MappingType, and DMRS (its DM-RS settings, such as DMRSAdditionalPosition). 
% Inputs: none; set the properties after. Outputs: a configuration object.
% 
% • [ind, info] = nrPDSCHIndices(carrier, pdsch) — Purpose: where the PDSCH 
% data goes on the grid, and a summary. Inputs: the two objects. Outputs: the 
% positions, and a structure with fields such as G, NREPerPRB, and DMRSSymbolSet 
% (the 0-based DM-RS symbols).
% 
% • tbs = nrTBS(modulation, nLayers, nPRB, NREPerPRB, R) — Purpose: the transport 
% block size. Inputs: the modulation name, the layers, the number of PRBs, 
% the REs per PRB, and the target code rate. Outputs: the TBS in bits.
% 
% • numel(x) — Purpose: count the entries of x. Inputs: an array. Outputs: 
% a whole number.
% 
% Commands you read in the given code
% • info = nrDLSCHInfo(A, R) and c = nrCRCEncode(b, crcName) — Purpose: the 
% coding plan for a block, and adding its CRC (album track 04). Inputs: the 
% TBS and the rate; the bits and info.CRC. Outputs: a structure; the longer 
% column. Used in the Build-it checks.
% 
% • Figure family: figure(Name = ...), bar, xticks, xticklabels, ylabel, title, 
% plot, xlabel, grid on — Purpose: draw bars or a line, label them, and name 
% the figure. Inputs: data and text. Outputs: a figure. Used in B5 and Build 
% it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, x(:), x.', x(end), t(rows, :), t.Name, 
% c{n}, s.name — Purpose: read entries, count a range, reshape, pick rows of 
% a table or one of its columns, read a cell or a field. Inputs: an array or 
% table and positions. Outputs: the entries.
% 
% • Compare and combine: == ~= < > <= >=, && || ~, .^ — Purpose: compare values; 
% and, or, not; raise to a power entry by entry. Inputs: numbers or arrays. 
% Outputs: true/false or numbers.
% 
% • Control flow: for ... end, if ... else ... end, break — Purpose: repeat 
% a block for each value of a list; run one block or the other; leave a loop 
% early. Inputs: a list or a true/false test. Outputs: whatever the blocks 
% store.
% 
% • Built-in helpers: numel, height, mean, all, diff, ismember, isequal, strcmp, 
% isnan, double, char, round, sqrt, randn, randi, zeros, strings, true, false, 
% exist, NaN, [] — Purpose: count, average, test, compare numbers or text, 
% convert, round, make noise, bits, or empty arrays, look a name up. Inputs: numbers, arrays, or 
% names. Outputs: numbers or true/false (NaN means "no number yet").
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
% Requirements
% Requires the 5G Toolbox, R2024a or later for nrPDSCHMCSTables. There is no 
% nrHARQEntity function: HARQ here is nrDLSCH with MultipleHARQProcesses and 
% a HARQ process ID, and the soft buffers of nrDLSCHDecoder. Teaching demo, 
% not production code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year), so the transport block repeats on every run

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");
%% B1 — How big is a block?
% New words
% • N_info: the unquantized information size, N_RE × R × Qm × layers. nrTBS 
% rounds it to an allowed TBS.
% 
% • Overhead: REs in the allocation that cannot carry data, here the DM-RS.
% Why it matters
% A block that fails must be sent again unchanged, so first we need its size. 
% The TBS is not the number of PDSCH bits. TS 38.214 clause 5.1.3.2 works it 
% out from N_info = N_RE × R × Qm × layers, quantized, with a lookup table 
% only when N_info ≤ 3824. The CRC length then follows from the TBS: 24 bits 
% if it is above 3824, else 16. G is the coded payload the rate matcher will 
% send; the TBS is the information word inside it.
% What to look for
% • In the sizes table, read NREPerPRB, G, the TBS, the CRC length, and the 
% estimate N_info.
% 
% • Compare the TBS with N_info: how far apart are they?
% Common mistakes
% Do not pass 12 × 14 as NREPerPRB: the allocation has fewer symbols, and the 
% DM-RS takes REs.
% Try it (personal exploration)
% Keep the same PRBs and symbols, and switch the modulation from QPSK to 16QAM. 
% Without running anything, predict the ratio G(16QAM) / G(QPSK): by what 
% factor do the coded bits grow? Type it into myPrediction before you run 
% this section; the one-row table at the end compares it with nrPDSCHIndices 
% for a second PDSCH set to 16QAM, so the PDSCH the later beats use stays QPSK.

% Try it: type your prediction here (a ratio) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — How big is a block?
fprintf("B1 — How big is a block?\n");   % banner title only; every number below goes into a table

% The carrier and one PDSCH on it, as in the plan.
carrier = nrCarrierConfig( ...
    SubcarrierSpacing = 15, ...   % subcarrier spacing, kHz
    NSizeGrid = 52, ...           % carrier width, RBs
    NCellID = 1);                 % physical cell ID (scrambling)
pdsch = nrPDSCHConfig;                      % default PDSCH, then set what matters
pdsch.PRBSet           = 0:23;              % 24 PRBs, 0-based
pdsch.SymbolAllocation = [2 12];            % [first symbol, number of symbols]: symbols 2 to 13
pdsch.Modulation       = 'QPSK';            % Qm = 2 bits per symbol
pdsch.NumLayers        = 1;                 % one layer
pdsch.MappingType      = 'A';               % type A: DM-RS counted from the slot start

% Where the data goes, the REs per PRB, and the coded bits G.
[pdschInd, indInfo] = nrPDSCHIndices(carrier, pdsch);
tcr  = 0.48;                                % target code rate (no unit): mid-range for QPSK
nPRB = numel(pdsch.PRBSet);                 % PRBs this PDSCH has
tbs  = nrTBS(pdsch.Modulation, pdsch.NumLayers, nPRB, indInfo.NREPerPRB, tcr);   % transport block size, bits
crcLen = 24*(tbs > 3824) + 16*(tbs <= 3824);                                     % CRC bits: 24 above 3824, else 16
qm     = indInfo.G/(nPRB*indInfo.NREPerPRB*pdsch.NumLayers);                     % bits per RE, read from G (2 for QPSK)
nInfo  = nPRB*indInfo.NREPerPRB*tcr*qm*pdsch.NumLayers;                          % unquantized N_info, bits

% Two tests: the block fits inside the coded bits, and the TBS lands within
% a few percent of N_info.
okFits = tbs > 0 && indInfo.G > tbs;
assert(okFits, ...
    'G should exceed the TBS. Look first at what you passed to nrTBS: numel(PRBSet) and indInfo.NREPerPRB.');
okNearInfo = abs(tbs/nInfo - 1) < 0.05;     % within 5 %
assert(okNearInfo, ...
    'The TBS is far from N_info. Common mistake: passing 12*14 as NREPerPRB.');

b1Sizes = table(nPRB, indInfo.NREPerPRB, indInfo.G, nInfo, tbs, crcLen, ...
    VariableNames = {'nPRB', 'NREPerPRB', 'G', 'N_info', 'TBS', 'CRC_bits'});
b1Sizes

% Try it: the same allocation at 16QAM, on a second PDSCH (no assert on it).
pdschTry = nrPDSCHConfig;                   % a separate PDSCH, so pdsch stays QPSK
pdschTry.PRBSet           = pdsch.PRBSet;
pdschTry.SymbolAllocation = pdsch.SymbolAllocation;
pdschTry.Modulation       = '16QAM';        % Qm = 4
pdschTry.NumLayers        = pdsch.NumLayers;
pdschTry.MappingType      = pdsch.MappingType;
[~, tryInfo] = nrPDSCHIndices(carrier, pdschTry);
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, tryInfo.G/indInfo.G, predictionNote, ...
    VariableNames = {'MyPrediction', 'G_16QAM_over_G_QPSK', 'Note'});
b1Prediction
%% B1 — After the run
% NREPerPRB is less than 12 × 12 because the DM-RS takes one symbol's REs in 
% each PRB. G is larger than the TBS, roughly 1/R times it, so the code has 
% room for parity bits. 
% The TBS is not N_info itself: the quantizing step lands on a nearby allowed 
% size, here just above N_info. It does not always round up: for a large N_info 
% it can fall just below (see the 16QAM row of the B2 table). Compare the ratio 
% with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags.
b1Checks = table( ...
    ["0 < TBS < G"; ...
     "TBS within 5 % of N_info"], ...
    ["less than " + string(indInfo.G); "ratio 0.95 to 1.05"], ...
    [string(tbs); "ratio " + string(round(tbs/nInfo, 3))], ...
    [okFits; okNearInfo], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep carrier, pdsch, indInfo, tcr, nPRB, and tbs: B2 to B5 use them.
% Everything else made in B1 was used only to build, test, or show B1.
clear b1Sizes b1Checks b1Prediction predictionNote okFits okNearInfo ...
      pdschInd crcLen qm nInfo pdschTry tryInfo myPrediction
%% B2 — The MCS table
% New words
% • MCS index: the row number of the MCS table, 0 to 31. In QAM64Table the 
% last three rows are reserved: their rate is NaN.
% 
% • QAM64Table: MCS index table 1 of TS 38.214, the table whose highest modulation 
% is 64QAM.
% 
% Beat-only commands (B2)
% • tabs = nrPDSCHMCSTables — Purpose: the four PDSCH MCS tables. Inputs: 
% none. Outputs: an object whose properties QAM64Table, QAM256Table, QAM64LowSETable, 
% and QAM1024Table are tables with columns MCSIndex, Qm, TargetCodeRate, SpectralEfficiency, 
% and Modulation. TargetCodeRate is the fraction (the specification's value 
% divided by 1024).
% Why it matters
% The MCS table is the agreed menu: each row names a modulation and a target 
% code rate, and those two numbers go straight into nrTBS. A higher MCS on 
% the same allocation gives a larger TBS. Choosing the row is link adaptation; 
% it is not the retransmission (that is B3).
% What to look for
% • In the rows table, read the modulation, Qm, and R of the two rows, and 
% the TBS each one gives on the B1 allocation.
% Common mistakes
% Do not read TargetCodeRate as bits per RE: bits per RE is Qm × R, the 
% SpectralEfficiency column.
% 
% Read Qm and R from the table you index: MCS 5 is QPSK in QAM64Table but 
% 16QAM in QAM256Table.
% Try it (personal exploration)
% MCS 9 and MCS 10 sit on the QPSK to 16QAM boundary of QAM64Table. Look up 
% their Qm and R in tabs.QAM64Table and predict the difference in bits per 
% RE, Qm × R (MCS 10 minus MCS 9). Type it into myPrediction before you run 
% this section; the one-row table at the end shows Qm × R for both rows, the 
% difference, and the TBS each row gives.

% Try it: type your prediction here (a difference in bits per RE) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — The MCS table
fprintf("B2 — The MCS table\n");   % banner title only; every number below goes into a table

% The menu, and two rows of it: a low MCS and a high MCS.
tabs = nrPDSCHMCSTables;          % all four PDSCH MCS tables
t = tabs.QAM64Table;              % MCS index table 1
mcsLow  = 4;                      % low MCS index (QPSK row)
mcsHigh = 16;                     % high MCS index (16QAM row)
rowLow  = t(t.MCSIndex == mcsLow, :);    % the one row with that index
rowHigh = t(t.MCSIndex == mcsHigh, :);

% Three tests: each row exists once, each rate is a fraction, and the higher
% row gives the larger TBS on the B1 allocation.
okRows = height(rowLow) == 1 && height(rowHigh) == 1;
assert(okRows, ...
    'MCS rows 4 and 16 should each appear once. Look first at the table: QAM64Table has MCSIndex 0 to 31.');
rLow  = double(rowLow.TargetCodeRate(1));    % target code rate of the low row (fraction)
rHigh = double(rowHigh.TargetCodeRate(1));   % target code rate of the high row (fraction)
okFraction = rLow > 0 && rLow < 1 && rHigh > 0 && rHigh < 1;
assert(okFraction, ...
    'TargetCodeRate should be a fraction between 0 and 1. Common mistake: reading the specification value R x 1024.');
tbsLow  = nrTBS(char(rowLow.Modulation(1)),  1, nPRB, indInfo.NREPerPRB, rLow);    % TBS for the low row, bits
tbsHigh = nrTBS(char(rowHigh.Modulation(1)), 1, nPRB, indInfo.NREPerPRB, rHigh);   % TBS for the high row, bits
okBigger = tbsHigh > tbsLow;
assert(okBigger, ...
    'The higher MCS should give the larger TBS. Look first at the modulation passed to nrTBS: take it from each row.');

b2Rows = table([mcsLow; mcsHigh], string([rowLow.Modulation(1); rowHigh.Modulation(1)]), ...
    double([rowLow.Qm(1); rowHigh.Qm(1)]), [rLow; rHigh], [tbsLow; tbsHigh], ...
    VariableNames = {'MCSIndex', 'Modulation', 'Qm', 'R', 'TBS'});
b2Rows

% Try it: MCS 9 and MCS 10 on the same allocation (no assert on them).
row9  = t(t.MCSIndex == 9, :);    % last QPSK row
row10 = t(t.MCSIndex == 10, :);   % first 16QAM row
tbs9  = nrTBS(char(row9.Modulation(1)),  1, nPRB, indInfo.NREPerPRB, double(row9.TargetCodeRate(1)));
tbs10 = nrTBS(char(row10.Modulation(1)), 1, nPRB, indInfo.NREPerPRB, double(row10.TargetCodeRate(1)));
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
qmr9  = double(row9.Qm(1))  * double(row9.TargetCodeRate(1));    % bits per RE, MCS 9
qmr10 = double(row10.Qm(1)) * double(row10.TargetCodeRate(1));   % bits per RE, MCS 10
b2Prediction = table(myPrediction, round(qmr9, 4), round(qmr10, 4), round(qmr10 - qmr9, 4), tbs9, tbs10, predictionNote, ...
    VariableNames = {'MyPrediction', 'QmR_MCS9', 'QmR_MCS10', 'Difference', 'TBS_MCS9', 'TBS_MCS10', 'Note'});
b2Prediction
%% B2 — After the run
% The high row doubles Qm and raises R, so its TBS is several times the low 
% row's on the same PRBs. A row is a choice made before the block is sent; 
% B3 is about what happens after it fails. Compare the Qm × R difference with 
% your prediction, and see how small the step in TBS is across the boundary.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["MCS rows 4 and 16 found once each"; ...
     "TargetCodeRate is a fraction (0 to 1)"; ...
     "TBS(MCS 16) > TBS(MCS 4)"], ...
    ["1 and 1"; "0 < R < 1"; "more than " + string(tbsLow)], ...
    [string(height(rowLow)) + " and " + string(height(rowHigh)); listText(round([rLow rHigh], 4)); string(tbsHigh)], ...
    [okRows; okFraction; okBigger], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B2 was used only to build, test, or show B2.
clear b2Rows b2Checks b2Prediction predictionNote okRows okFraction okBigger ...
      tabs t mcsLow mcsHigh rowLow rowHigh rLow rHigh tbsLow tbsHigh row9 row10 tbs9 tbs10 qmr9 qmr10 myPrediction
%% B3 — Fail, send again, combine
% New words
% • ACK / NACK: the receiver's answer for one block: received, or send it again.
% 
% • blkerr: the decoder's flag, true when the block's CRC fails after decoding.
% 
% • Soft buffer: the LLRs a HARQ process keeps from earlier tries of the same 
% block, so the next try adds to them.
% 
% Beat-only commands (B3)
% • enc = nrDLSCH, setTransportBlock(enc, blk, 0, harqID), and cw = enc(mod, 
% nLayers, G, rv, harqID) — Purpose: the downlink shared-channel encoder (CRC, 
% LDPC, rate matching); load one block into a HARQ process; send G coded bits 
% of it starting at redundancy version rv. Inputs: the block, its HARQ process 
% ID, the modulation name, the layers, G, and rv. Outputs: G coded bits. Properties 
% used: TargetCodeRate and MultipleHARQProcesses.
% 
% • dec = nrDLSCHDecoder, resetSoftBuffer(dec, 0, harqID), and [blk, blkerr] 
% = dec(llr, mod, nLayers, rv, harqID) — Purpose: the matching decoder; empty 
% one process's soft buffer; combine the new LLRs with the buffer and decode. 
% Inputs: the LLRs, the modulation, the layers, rv, and the HARQ process ID. 
% Outputs: the decoded block and blkerr. The TBS is set as the property TransportBlockLength, 
% not passed as an input.
% 
% • sym = nrPDSCH(carrier, pdsch, cw) and llr = nrPDSCHDecode(carrier, pdsch, 
% rx, nVar) — Purpose: scramble and modulate the coded bits into PDSCH symbols; 
% turn received symbols back into LLRs. Inputs: the two objects, the coded 
% bits or the received symbols, and the noise variance. Outputs: the symbols; 
% a cell holding the LLRs.
% Why it matters
% A failed block is not thrown away. The sender sends a new redundancy version 
% of the same transport block (RV 0, then RV 2 here), and the decoder soft-combines 
% the two observations in one HARQ buffer. Two effects help at once: the second 
% try collects more energy for the bits both tries carry, and, because each 
% RV starts reading the coded bits at a different place, it brings new coded 
% bits the first one did not send (incremental redundancy). This beat does 
% not separate the two. The script scans the whole SNR list on a fixed noise 
% seed, records both flags at every SNR, and marks the first SNR where RV 0 
% alone fails and RV 0 + 2 passes.
% What to look for
% • In the scan table, read blkerr after RV 0 alone and after RV 0 + 2 at each 
% SNR: find the rows where both fail, where only RV 0 fails, and where neither 
% fails.
% 
% • In the result table, find the chosen SNR and the two flags there.
% Common mistakes
% Do not call setTransportBlock again for the retransmission: that would load 
% a different block.
% 
% Do not pass the TBS to the decoder as an input argument, as some LTE functions 
% did: it is the TransportBlockLength property.
% Try it (personal exploration)
% Each try sends G coded bits of the same block. Predict the code rate over 
% both tries: the TBS divided by all the coded bits sent in the two tries (the 
% first rate in Key relationships; B1's sizes table gives the TBS and G). Type 
% it into myPrediction before you run this section; the one-row table at the 
% end works it out.

% Try it: type your prediction here (a rate between 0 and 1) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Fail, send again, combine
fprintf("B3 — Fail, send again, combine\n");   % banner title only; every number below goes into a table

% The HARQ settings: the PDSCH's modulation and layers, two RVs, one process.
modName = pdsch.Modulation;       % 'QPSK', the same modulation as the PDSCH
nl      = pdsch.NumLayers;        % layers: 1
rv      = [0 2];                  % redundancy versions: first try, then the retransmission
harqID  = 0;                      % HARQ process ID (0 to 31 in the toolbox)
outlen  = indInfo.G;              % coded bits per try, G
trBlk   = randi([0 1], tbs, 1, 'int8');   % the transport block, tbs random bits

% The encoder: load the block once into HARQ process harqID.
enc = nrDLSCH;
enc.TargetCodeRate = tcr;                   % same target rate as nrTBS used
enc.MultipleHARQProcesses = true;           % keep a block per HARQ process
setTransportBlock(enc, trBlk, 0, harqID);   % (encoder, block, codeword 0, HARQ process)

% The decoder: it must know the TBS and the rate.
dec = nrDLSCHDecoder;
dec.TargetCodeRate = tcr;                   % same target rate
dec.TransportBlockLength = tbs;             % TBS, bits: a property, not a step argument
dec.MultipleHARQProcesses = true;           % one soft buffer per HARQ process

% The SNRs to scan, per RE, and what the scan keeps.
snrList  = -3:0.5:4;              % per-RE SNR candidates, dB
carrier.NSlot = 0;                % slot 0 (sets the scrambling)
chosen   = NaN;                   % first SNR where combining rescues the block (NaN = none yet)
errFlags = true(size(rv));        % blkerr after RV 0 alone and after RV 0 + 2
rxBitsCombined = [];              % the block the combined decode returned
scanSNR = [];  scanErr = zeros(0, 2);   % every SNR tried, and its two flags

% For each SNR: empty the HARQ buffer, then send RV 0 and RV 2 through the
% same noise draws, decoding each into the same buffer. Every SNR in the list
% is tried; the first one where RV 0 alone fails and RV 0 + 2 passes is kept.
for snrdB = snrList
    resetSoftBuffer(dec, 0, harqID);     % fresh HARQ buffer at each SNR
    rng(7);                              % seed 7: the same noise draws at every SNR
    ef = false(size(rv));                % blkerr for each try at this SNR
    % Each try: encode at its RV, map to PDSCH symbols, add noise, back to LLRs, decode.
    for k = 1:numel(rv)
        cw   = enc(modName, nl, outlen, rv(k), harqID);   % G coded bits starting at RV rv(k)
        sym  = nrPDSCH(carrier, pdsch, cw);               % scrambled, modulated PDSCH symbols
        sigP = mean(abs(sym).^2);                         % mean symbol power (linear)
        noise = sqrt(sigP/2/10^(snrdB/10)) * (randn(size(sym)) + 1j*randn(size(sym)));   % complex noise at this per-RE SNR
        rx   = sym + noise;                               % the channel is noise only (H = 1), so no equalizer
        nVar = sigP/10^(snrdB/10);                        % noise variance per RE (linear)
        soft = nrPDSCHDecode(carrier, pdsch, rx, nVar);   % LLRs, descrambled
        [rxBits, ef(k)] = dec(soft{1}, modName, nl, rv(k), harqID);   % combine with the buffer and decode
    end
    scanSNR(end+1, 1) = snrdB;           %#ok<AGROW> every SNR tried
    scanErr(end+1, :) = ef;              %#ok<AGROW> its two flags
    if isnan(chosen) && ef(1) && ~ef(2)
        chosen = snrdB;  errFlags = ef;  rxBitsCombined = rxBits;   % the first rescue is kept; the scan goes on
    end
end

% The scan must find an SNR where RV 0 fails and RV 0 + 2 passes.
okRescue = ~isnan(chosen) && errFlags(1) && ~errFlags(2);
assert(okRescue, ...
    'No SNR in snrList gave "RV 0 fails, RV 0 + 2 passes". Look first at snrList: widen it to lower and higher SNRs.');

b3Scan = table(scanSNR, scanErr(:,1), scanErr(:,2), ...
    VariableNames = {'SNR_dB', 'BlkErr_RV0', 'BlkErr_RV0plus2'});
b3Scan
b3Result = table(chosen, errFlags(1), errFlags(2), ...
    VariableNames = {'ChosenSNR_dB', 'BlkErr_RV0', 'BlkErr_RV0plus2'});
b3Result

% Put your Try-it prediction beside the code rate after both tries.
rateBoth = tbs/(numel(rv)*outlen);    % TBS over all coded bits sent (no unit)
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, round(rateBoth, 3), predictionNote, ...
    VariableNames = {'MyPrediction', 'RateAfterBothTries', 'Note'});
b3Prediction
%% B3 — After the run
% At the chosen SNR the first try alone fails its CRC, and the same block, 
% sent again at RV 2 and added to what the decoder kept, passes. Read the 
% other rows too: at lower SNRs both tries fail, so a retransmission does not 
% always rescue a block; at higher SNRs RV 0 alone already passes. Compare 
% the rate over both tries with your prediction and with the target rate tcr.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flag.
b3Checks = table( ...
    ["An SNR where RV 0 fails and RV 0 + 2 passes"], ...
    ["found: blkerr 1 then 0"], ...
    ["SNR " + string(chosen) + " dB: blkerr " + string(double(errFlags(1))) + " then " + string(double(errFlags(2)))], ...
    [okRescue], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep enc, trBlk, rxBitsCombined, modName, nl, outlen, and harqID: B4 reads
% them. Everything else made in B3 was used only to build, test, or show B3.
clear b3Scan b3Result b3Checks b3Prediction predictionNote okRescue ...
      rv dec snrList chosen errFlags scanSNR scanErr snrdB ef k cw sym sigP noise rx nVar soft rxBits ...
      rateBoth myPrediction
%% B4 — What never changes
% New words
% • Retransmission: the same transport block, sent again at a new RV.
% 
% • New block: what a change of rate, MCS, or allocation makes; it gets a new 
% TBS and is not a retransmission.
% 
% Beat-only commands (B4)
% • blk = getTransportBlock(enc, 0, harqID) — Purpose: read the block a HARQ 
% process of the encoder holds. Inputs: the encoder, codeword 0, and the HARQ 
% process ID. Outputs: the block's bits.
% Why it matters
% A retransmission is a new coding of the same information word, so the block 
% and its TBS must not change when only the RV changes. Picking the highest 
% MCS every time would make the first try fail more often, and it would not 
% grow the block on the retry: the retry is not allowed to change it. (That 
% half is for discussion only: no code here measures it; the error-rate curves 
% of album track 11 do.)
% What to look for
% • In the invariance table, read whether the encoder still holds the original 
% block, whether the RV 0 and RV 2 coded words differ, and whether the combined 
% decode of B3 returned the original block.
% Common mistakes
% Do not raise the MCS on the retransmission.
% 
% Do not think a bigger RV carries more information bits: every RV codes the 
% same TBS bits.
% Try it (personal exploration)
% Keep the B1 allocation but change the target rate from 0.48 to 0.40. Predict 
% N_info for that new block, N_RE × R × Qm × layers. Type it into myPrediction 
% before you run this section; the one-row table at the end compares it with 
% the N_info worked out from nrPDSCHIndices, and shows the TBS nrTBS picks 
% for it.

% Try it: type your prediction here (N_info, in bits) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — What never changes
fprintf("B4 — What never changes\n");   % banner title only; every number below goes into a table

% Code the same block at RV 0 and at RV 2, and read back what the HARQ process holds.
cw0 = enc(modName, nl, outlen, 0, harqID);    % RV 0 coded bits
cw2 = enc(modName, nl, outlen, 2, harqID);    % RV 2 coded bits
heldBlk = getTransportBlock(enc, 0, harqID);  % the block in HARQ process harqID

% Three tests: the block is unchanged, the two coded words differ, and the
% combined decode of B3 returned the original block.
okSameBlk = isequal(heldBlk, trBlk);
assert(okSameBlk, ...
    'The encoder should still hold the original block. Common mistake: calling setTransportBlock again before the retransmission.');
okDiffer = ~isequal(cw0, cw2);
assert(okDiffer, ...
    'RV 0 and RV 2 of the same block should differ. Look first at the RV argument of each enc call.');
okCombined = isequal(rxBitsCombined, trBlk);
assert(okCombined, ...
    'The combined decode should return the original block. Look first at B3: the decoder must use the same HARQ process ID.');

b4Invariance = table(okSameBlk, okDiffer, okCombined, numel(trBlk), ...
    VariableNames = {'BlockHeldUnchanged', 'RV0_RV2_Differ', 'CombinedIsOriginal', 'TBS'});
b4Invariance

% Try it: a real change. A different target rate is a different block size.
tryRate = 0.40;                                                                  % Try-it target rate (no unit)
qmB4 = indInfo.G/(nPRB*indInfo.NREPerPRB*pdsch.NumLayers);                       % bits per RE, read from G
nInfoOther = nPRB*indInfo.NREPerPRB*tryRate*qmB4*pdsch.NumLayers;                % unquantized N_info, bits
tbsOther = nrTBS(pdsch.Modulation, pdsch.NumLayers, nPRB, indInfo.NREPerPRB, tryRate);   % TBS of that new block, bits
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, tryRate, nInfoOther, tbsOther, predictionNote, ...
    VariableNames = {'MyPrediction', 'R', 'N_info', 'TBS', 'Note'});
b4Prediction
%% B4 — After the run
% The encoder holds the same bits after both RVs, and the two coded words differ: 
% a retransmission is the same block coded from a different start. The block 
% the combined decode returned is the one that was sent. A new rate gives a 
% new N_info and a new TBS, so it would be a new block, not a retransmission. 
% Compare N_info with your prediction.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["Encoder still holds the original block"; ...
     "RV 0 and RV 2 coded words differ"; ...
     "Combined decode = original block"], ...
    [string(numel(trBlk)) + " of " + string(numel(trBlk)) + " bits equal"; "more than 0 positions differ"; ...
     string(numel(trBlk)) + " of " + string(numel(trBlk)) + " bits equal"], ...
    [string(nnz(heldBlk == trBlk)) + " of " + string(numel(trBlk)) + " bits equal"; ...
     string(nnz(cw0 ~= cw2)) + " positions differ"; ...
     string(nnz(rxBitsCombined == trBlk)) + " of " + string(numel(trBlk)) + " bits equal"], ...
    [okSameBlk; okDiffer; okCombined], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B4, and the B3 values kept for it, was used only to
% build, test, or show the beats.
clear b4Invariance b4Checks b4Prediction predictionNote okSameBlk okDiffer okCombined ...
      cw0 cw2 heldBlk tryRate qmB4 nInfoOther tbsOther myPrediction ...
      enc trBlk rxBitsCombined modName nl outlen harqID
%% B5 — Where the DM-RS sits
% New words
% • DMRSTypeAPosition: the first DM-RS symbol for mapping type A, 2 or 3 (0-based).
% 
% • DMRSAdditionalPosition: 0 to 3 extra DM-RS symbols. Their places depend 
% on the allocation length (TS 38.211 clause 7.4.1.1.2).
% 
% Beat-only commands (B5)
% • dmrs = nrPDSCHDMRSConfig — Purpose: the DM-RS settings of a PDSCH, set 
% as pdsch.DMRS. Inputs: none. Outputs: a configuration object with properties 
% such as DMRSTypeAPosition and DMRSAdditionalPosition.
% Why it matters
% The phone has to know where the pilots sit before it can learn the channel 
% (album track 07). In mapping type A the first DM-RS is on symbol 2 or 3, 
% and each additional position adds a DM-RS symbol. Every DM-RS symbol takes 
% REs from the data, so the REs per PRB and the TBS fall as the positions rise. 
% B1 used the default, no additional position.
% What to look for
% • In the DM-RS table, read the symbol set, NREPerPRB, and the TBS for each 
% DMRSAdditionalPosition.
% 
% • In the figure, read how much the TBS falls for each added DM-RS symbol.
% Common mistakes
% Do not assume the extra DM-RS symbols always land on one fixed list: their 
% places depend on the allocation length.
% 
% Do not forget that DM-RS REs are set aside: they are not data.
% Try it (personal exploration)
% With DMRSAdditionalPosition = 3 this 12-symbol allocation has four DM-RS 
% symbols, and each one takes all 12 REs of its symbol in a PRB. Predict NREPerPRB 
% for that setting. Type it into myPrediction before you run this section; 
% the one-row table at the end compares it with nrPDSCHIndices.

% Try it: type your prediction here (a number of REs per PRB) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B5 — Where the DM-RS sits
fprintf("B5 — Where the DM-RS sits\n");   % banner title only; every number below goes into a table

% Fresh DM-RS settings, then each additional position in turn.
pdsch.DMRS = nrPDSCHDMRSConfig;      % default DM-RS: type A position 2, no additional position
apList   = 0:3;                      % DMRSAdditionalPosition values to try
dmrsText = strings(numel(apList), 1);    % DM-RS symbols, as text, filled in the loop
firstSym = zeros(numel(apList), 1);      % first DM-RS symbol (0-based)
nreList  = zeros(numel(apList), 1);      % REs per PRB for data
tbsList  = zeros(numel(apList), 1);      % TBS, bits

% For each setting: read the DM-RS symbols and NREPerPRB from nrPDSCHIndices
% (nrPDSCHDMRSIndices returns positions only), and work out the TBS again.
for a = 1:numel(apList)
    pdsch.DMRS.DMRSAdditionalPosition = apList(a);
    [~, pinfo] = nrPDSCHIndices(carrier, pdsch);         % pinfo.DMRSSymbolSet: 0-based DM-RS symbols
    dmrsText(a) = listText(pinfo.DMRSSymbolSet);
    firstSym(a) = pinfo.DMRSSymbolSet(1);
    nreList(a)  = pinfo.NREPerPRB;
    tbsList(a)  = nrTBS(pdsch.Modulation, pdsch.NumLayers, nPRB, pinfo.NREPerPRB, tcr);   % bits
end

% Two tests: the first DM-RS is on symbol 2 or 3 at every setting, and each
% added DM-RS symbol lowers NREPerPRB.
okFirst = all(ismember(firstSym, [2 3]));     % symbols 2 or 3, 0-based
assert(okFirst, ...
    'The first type A DM-RS should be on symbol 2 or 3. Look first at MappingType: it should be ''A''.');
okCost = all(diff(nreList) < 0);
assert(okCost, ...
    'NREPerPRB should fall at each added DM-RS position. Common mistake: setting the property on a copy, not on pdsch.DMRS.');

b5DMRS = table(apList(:), dmrsText, nreList, tbsList, ...
    VariableNames = {'AdditionalPosition', 'DMRSSymbols', 'NREPerPRB', 'TBS'});
b5DMRS

% The cost of each DM-RS setting, in TBS.
figure(Name = 'Track 05 B5 - DM-RS cost', Color = 'w');
plot(apList, tbsList, '-o');                  % TBS against DMRSAdditionalPosition
xticks(apList);
xlabel('DMRSAdditionalPosition');
ylabel('TBS (bits)');
title('More DM-RS symbols, fewer REs for data, smaller TBS');
grid on;

% Put your Try-it prediction beside NREPerPRB for DMRSAdditionalPosition = 3.
tryNRE = nreList(apList == 3);        % REs per PRB at position 3
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b5Prediction = table(myPrediction, tryNRE, predictionNote, ...
    VariableNames = {'MyPrediction', 'NREPerPRB_Pos3', 'Note'});
b5Prediction
%% B5 — After the run
% The first DM-RS stays on symbol 2 at every setting, and the extra symbols 
% land later in the slot. Each one takes 12 REs per PRB, so NREPerPRB and the 
% TBS step down together. More pilots help the phone track a changing channel 
% (album track 07) but cost data. Compare NREPerPRB at position 3 with your 
% prediction.
%% B5 — Assertion checks

% One row per assert in B5. Pass is computed from the stored flags.
b5Checks = table( ...
    ["First DM-RS on symbol 2 or 3 (all settings)"; ...
     "NREPerPRB falls at each added position"], ...
    ["2 or 3"; "strictly falling"], ...
    [listText(firstSym); listText(nreList)], ...
    [okFirst; okCost], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b5Checks
%% B5 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B5, and the B1 values kept for the beats, was used only
% to build, test, or show them; the Build it makes its own carrier and PDSCH.
clear b5DMRS b5Checks b5Prediction predictionNote okFirst okCost ...
      apList dmrsText firstSym nreList tbsList a pinfo tryNRE myPrediction ...
      carrier pdsch indInfo tcr nPRB tbs
%% Build it — Size a block for a new allocation
% Competency: given an allocation, a modulation, a target rate, and a DM-RS 
% setting, set up the PDSCH, work out its REs per PRB and coded bits G by hand, 
% get its TBS and CRC length, and find the code rate the block really gets.
% Problem
% You are given 40 PRBs (0 to 39), 16QAM, a target rate of 0.6, and one additional 
% DM-RS position, on a full-slot type A allocation (all 14 symbols, 0 to 13; 
% B1 used 12). Set up the carrier and the PDSCH. Predict where the additional 
% DM-RS sits, then work out NREPerPRB and G by hand and compare them with nrPDSCHIndices. 
% Get the TBS with nrTBS, its CRC length, and the rate one try really gets 
% (the second rate in Key relationships).
% Allowed commands
% nrCarrierConfig, nrPDSCHConfig and setting its properties, nrPDSCHIndices, 
% nrTBS, numel, arithmetic, and abs. The tables and the figure in the check 
% sections and Stage 5 are given. These are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myPRBSet = 0:39;          % PRBs, 0-based: 40 PRBs, given for this exercise
% myModulation = '16QAM';   % modulation: given (Qm = 4)
% myRate = 0.6;             % target code rate (no unit): given
% myAddPos = 1;             % DMRSAdditionalPosition: given
%% Stage 1 check (given)
if ~exist('myPRBSet','var') || ~exist('myModulation','var') || ~exist('myRate','var') || ~exist('myAddPos','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = isequal(myPRBSet, 0:39) && strcmp(myModulation, '16QAM') && myRate == 0.6 && myAddPos == 1;   % the values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the four lines you uncommented: 0:39, ''16QAM'', 0.6, and 1.')
    stage1Checks = table("Given values", "40 PRBs, 16QAM, 0.6, 1", ...
        string(numel(myPRBSet)) + " PRBs, " + string(myModulation) + ", " + string(myRate) + ", " + string(myAddPos), okStage1, ...   % expected: the given values
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — set up the carrier and the PDSCH
% Fill the blanks: the carrier is 15 kHz and 52 RBs wide, as in B1; the PDSCH's 
% PRBs, modulation, and additional DM-RS position come from Stage 1; its symbol 
% allocation is the whole slot; then ask nrPDSCHIndices for the summary.
% Pass: Stage 2 OK.

% myCarrier = ___;
% myPdsch = nrPDSCHConfig;
% myPdsch.PRBSet = ___;
% myPdsch.SymbolAllocation = ___;
% myPdsch.Modulation = ___;
% myPdsch.DMRS.DMRSAdditionalPosition = ___;
% [~, myInfo] = nrPDSCHIndices(___, ___);
%% Stage 2 check (given; it counts the DM-RS symbols and does not list them)
if ~exist('myCarrier','var') || ~exist('myPdsch','var') || ~exist('myInfo','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Five tests: the carrier, the PRBs, the whole slot, the modulation, and
    % the DM-RS symbol count (one at the type A position plus one per
    % additional position).
    okStage2 = [myCarrier.SubcarrierSpacing == 15 && myCarrier.NSizeGrid == 52; ...
                isequal(myPdsch.PRBSet(:), myPRBSet(:)); ...
                isequal(myPdsch.SymbolAllocation, [0 14]); ...
                strcmp(myPdsch.Modulation, myModulation); ...
                numel(myInfo.DMRSSymbolSet) == 1 + myAddPos];
    assert(okStage2(1), ...
        'The carrier is not 15 kHz and 52 RBs. Look first at the Name = value pairs of nrCarrierConfig.')
    assert(okStage2(2), ...
        'The PDSCH does not have the Stage 1 PRBs. Look first at the PRBSet line.')
    assert(okStage2(3), ...
        'The allocation is not the whole slot. Look first at SymbolAllocation: [first symbol, number of symbols].')
    assert(okStage2(4), ...
        'The PDSCH modulation is not the Stage 1 one. Look first at the Modulation line.')
    assert(okStage2(5), ...
        'The DM-RS symbol count is off. Common mistake: setting DMRSAdditionalPosition on a new nrPDSCHDMRSConfig that is never put into myPdsch.DMRS.')
    stage2Checks = table( ...
        ["Carrier 15 kHz, 52 RB"; "PDSCH PRBs"; "Whole slot"; "PDSCH modulation"; "DM-RS symbols (count)"], ...
        ["15 kHz, 52 RB"; string(numel(myPRBSet)); "0 14"; string(myModulation); string(1 + myAddPos)], ...
        [string(myCarrier.SubcarrierSpacing) + " kHz, " + string(myCarrier.NSizeGrid) + " RB"; string(numel(myPdsch.PRBSet)); ...
         listText(myPdsch.SymbolAllocation); string(myPdsch.Modulation); string(numel(myInfo.DMRSSymbolSet))], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: where the additional DM-RS sits
% Before you read the DM-RS symbols from myInfo, type your prediction: on which 
% symbol (0-based) does the additional DM-RS of this allocation sit? Use the 
% l_d table in Key relationships. Run this section and the check under it 
% before you start Stage 3b: the check does not take a prediction once Stage 
% 3b's names exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with nrPDSCHIndices and does not print the symbol)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif ~exist('myInfo','var')
    disp('Stage 3a needs Stage 2 first: make myInfo, then return here.')
elseif exist('myNRE','var') || exist('myG','var')
    disp('Stage 3a refused: Stage 3b names already exist, so this is no longer a prediction. Run "clear myNRE myQm myG", then predict again.')
else
    okPrediction3 = myPrediction == max(myInfo.DMRSSymbolSet);   % the last DM-RS symbol is the additional one here
    stage3aCheck = table("Prediction = the additional DM-RS symbol", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at l_d for this allocation: count from the start of the slot to its last symbol. Change myPrediction and run again.')
    end
end
%% Stage 3b — NREPerPRB and G by hand
% Fill the blanks: NREPerPRB for this allocation, counted by hand from its 
% symbols and its DM-RS symbols; Qm for this modulation; and G for this PDSCH 
% (one layer).
% Pass: your locked prediction and the DM-RS symbols appear side by side, 
% and Stage 3 OK.

% myNRE = ___;
% myQm = ___;
% myG = ___;
%% Stage 3b check (given; the check reads nrPDSCHIndices' summary, a different route from your hand count)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('myNRE','var') || ~exist('myQm','var') || ~exist('myG','var')
    disp('Stage 3b not done: fill the blanks, uncomment, and run.')
else
    % Your locked prediction beside the DM-RS symbols, in one row.
    stage3Prediction = table(myLockedPrediction, listText(myInfo.DMRSSymbolSet), ...
        VariableNames = {'MyPrediction', 'DMRSSymbols'});
    stage3Prediction

    % Three tests: your NREPerPRB, Qm, and G match the toolbox's summary.
    okStage3 = [myNRE == myInfo.NREPerPRB; ...
                myQm == myInfo.G/(myInfo.NREPerPRB*numel(myPdsch.PRBSet)); ...   % bits per RE in the toolbox's G
                myG == myInfo.G];
    assert(okStage3(1), ...
        'myNRE does not match NREPerPRB. Look first at the two counts: the allocated symbols, and the DM-RS symbols.')
    assert(okStage3(2), ...
        'myQm is off. Look first at Words used: Qm is the bits per symbol of the modulation.')
    assert(okStage3(3), ...
        'myG does not match info.G. Common mistake: multiplying by the 52 RBs of the carrier instead of the PDSCH''s PRBs.')
    stage3Checks = table( ...
        ["myNRE = info.NREPerPRB"; "myQm = bits per RE in info.G"; "myG = info.G"], ...
        [string(myInfo.NREPerPRB); string(myInfo.G/(myInfo.NREPerPRB*numel(myPdsch.PRBSet))); string(myInfo.G)], ...
        [string(myNRE); string(myQm); string(myG)], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — the TBS, its CRC, and the rate it really gets
% Fill the blanks: the TBS from nrTBS for this PDSCH and target rate; N_info 
% by hand; the CRC length for this TBS; and the rate one try really gets, 
% the second rate in Key relationships.
% Pass: Stage 4 OK.

% myTBS = ___;
% myNinfo = ___;
% myCRCLen = ___;
% myRealRate = ___;
%% Stage 4 check (given; the check asks nrDLSCHInfo and nrCRCEncode for the CRC, a different route from yours)
if ~exist('myTBS','var') || ~exist('myNinfo','var') || ~exist('myCRCLen','var') || ~exist('myRealRate','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: the CRC bits nrCRCEncode adds for this TBS and rate,
    % and the TBS nrTBS gives with every input taken from the objects.
    oracleCRC = numel(nrCRCEncode(zeros(myTBS, 1), nrDLSCHInfo(myTBS, myRate).CRC)) - myTBS;
    oracleTBS = nrTBS(myPdsch.Modulation, myPdsch.NumLayers, numel(myPdsch.PRBSet), myInfo.NREPerPRB, myRate);

    % Five tests: the TBS, N_info with the target rate, the TBS near N_info,
    % the CRC length, and the real rate by the second definition.
    okStage4 = [myTBS == oracleTBS; ...
                abs(myNinfo - myInfo.NREPerPRB*numel(myPdsch.PRBSet)*myQm*myRate) < 1e-9; ...   % same N_info, to rounding
                abs(myTBS/myNinfo - 1) < 0.05; ...                                              % within 5 %
                myCRCLen == oracleCRC; ...
                abs(myRealRate - (oracleTBS + oracleCRC)/myInfo.G) < 1e-9];                      % the second rate definition
    assert(okStage4(1), ...
        'myTBS is not nrTBS''s TBS for this PDSCH. Look first at the inputs: the PDSCH''s own PRB count and NREPerPRB, and the target rate.')
    assert(okStage4(2), ...
        'myNinfo is off. Look first at the last factor: N_info uses the target rate myRate.')
    assert(okStage4(3), ...
        'The TBS is far from N_info. Look first at the last input of nrTBS: the target rate, not the number of layers.')
    assert(okStage4(4), ...
        'myCRCLen does not match. Look first at Key ideas: the CRC length depends on whether the TBS is above 3824.')
    assert(okStage4(5), ...
        'myRealRate is not the rate one try really gets. Common mistake: using the TBS alone, or NREPerPRB, instead of the block with its CRC over G.')
    stage4Checks = table( ...
        ["TBS = nrTBS for this PDSCH"; "N_info = NREPerPRB × PRBs × Qm × R"; "TBS within 5 % of N_info"; ...
         "CRC length (nrCRCEncode)"; "Real rate = (TBS + CRC) / G"], ...
        [string(oracleTBS); string(myInfo.NREPerPRB*numel(myPdsch.PRBSet)*myQm*myRate); "ratio 0.95 to 1.05"; ...
         string(oracleCRC); string(round((oracleTBS + oracleCRC)/myInfo.G, 4))], ...
        [string(myTBS); string(myNinfo); "ratio " + string(round(myTBS/myNinfo, 4)); string(myCRCLen); string(round(myRealRate, 4))], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myRealRate','var') || ~exist('myG','var') || ~exist('myInfo','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Routes you did not use: count the data positions nrPDSCHIndices returns.
    [s5Ind, ~] = nrPDSCHIndices(myCarrier, myPdsch);         % one index per data RE (one layer)
    s5NRE = numel(s5Ind)/numel(myPdsch.PRBSet);              % data REs per PRB, counted
    s5G   = numel(s5Ind)*myQm;                               % coded bits: one Qm-bit symbol per data RE

    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myNRE == s5NRE; ...
        myG == s5G; ...
        myTBS < myG; ...
        myCRCLen == 24*(myTBS > 3824) + 16*(myTBS <= 3824); ...
        abs(myRealRate - myRate) < 0.02];

    % One row per result: the rule's value, your value, and the computed flag.
    buildChecks = table( ...
        ["NREPerPRB = data REs counted / PRBs"; "G = data REs counted × Qm"; "TBS < G"; ...
         "CRC: 24 above 3824, else 16 (repeat of Stage 4)"; "(TBS + CRC) / G close to R"], ...
        [string(s5NRE); string(s5G); "less than " + string(myG); ...
         string(24*(myTBS > 3824) + 16*(myTBS <= 3824)); string(myRate) + " ± 0.02"], ...
        [string(myNRE); string(myG); string(myTBS); string(myCRCLen); string(round(myRealRate, 4))], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: the coded bits, and the block inside them.
    figure(Name = 'Track 05 Build it - my block', Color = 'w');
    bar(1:3, [myG, myTBS + myCRCLen, myTBS]);               % bits
    xticks(1:3);
    xticklabels({'G (coded bits)', 'TBS + CRC', 'TBS'});
    ylabel('bits');
    title(sprintf('%d PRBs, %s, R = %.2f: NREPerPRB = %d, real rate %.3f', ...
        numel(myPRBSet), myModulation, myRate, myNRE, myRealRate));
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): 
% where did the REs per PRB go, and how did that set G? How close did the TBS 
% land to N_info, and why is the real rate not exactly the target?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. Keep everything else, 
% but give your PDSCH three additional DM-RS positions instead of one. How 
% many REs per PRB would it have for data? The check asks nrPDSCHIndices on 
% a copy and does not print the count.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('myPdsch','var') || ~exist('myCarrier','var')
    disp('Run Stage 2 first, then return here.')
else
    pdsch3 = myPdsch;                                        % a copy (a value object), so myPdsch keeps its setting
    pdsch3.DMRS.DMRSAdditionalPosition = 3;
    [~, info3] = nrPDSCHIndices(myCarrier, pdsch3);
    okInterp = myAnswer == info3.NREPerPRB;
    interpHint = "";
    if ~okInterp
        interpHint = "how many DM-RS symbols are there now, and how many REs does each take in a PRB?";
    end
    interpCheck = table("NREPerPRB with three additional positions", okInterp, interpHint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    interpCheck
end
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks okStage2 stage2Checks ...
      okPrediction3 stage3aCheck stage3Prediction okStage3 stage3Checks ...
      oracleCRC oracleTBS okStage4 stage4Checks s5Ind s5NRE s5G buildFlags buildChecks ...
      myAnswer pdsch3 info3 okInterp interpHint interpCheck
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them. 
% Each exercise has a check: type your numbers into its myE variable and run 
% that section. The check works the values out by a second route (the toolbox, 
% or the rule from a different starting point), shows Pass or Fail with a pointer 
% for each entry, and never prints the value. Write the reasons on the Your 
% answer lines; the script does not grade them.
%% E1 — New values (B1)
% Give the B1 PDSCH the whole 52-RB carrier (PRBSet 0 to 51), keeping QPSK, 
% symbols 2 to 13, no additional DM-RS, and R = 0.48. Work out NREPerPRB and 
% G by hand, then get the TBS with nrTBS in a section of your own. Type [G, 
% TBS, CRC bits] into myE1. Why is the CRC not the same length as in B1?
% 
% Your answer:
myE1 = NaN;   % [G, TBS, CRC bits]
if any(isnan(myE1)) || numel(myE1) ~= 3
    disp('Type three numbers into myE1, then run this section again.')
else
    e1Car = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);
    e1P = nrPDSCHConfig;  e1P.PRBSet = 0:51;  e1P.SymbolAllocation = [2 12];  e1P.Modulation = 'QPSK';
    [~, e1Info] = nrPDSCHIndices(e1Car, e1P);                 % second route: the toolbox's summary
    e1TBS = nrTBS('QPSK', 1, 52, e1Info.NREPerPRB, 0.48);
    e1CRC = numel(nrCRCEncode(zeros(e1TBS,1), nrDLSCHInfo(e1TBS, 0.48).CRC)) - e1TBS;
    e1Ref = [e1Info.G, e1TBS, e1CRC];
    okE1  = myE1(:) == e1Ref(:);
    e1Hint = ["NREPerPRB × PRBs × Qm"; "nrTBS with this PDSCH's own PRB count"; "is the TBS above 3824?"];
    e1Hint(okE1) = "";
    e1Check = table(["G"; "TBS"; "CRC bits"], okE1, e1Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e1Check
end
%% E2 — Diagnosis (B1)
% A classmate sizes the B1 PDSCH (24 PRBs, QPSK, R = 0.48) but passes 52, the 
% carrier width, as nPRB to nrTBS. What TBS do they get? The PDSCH still sends 
% only B1's G coded bits per try. What real rate (TBS + CRC) / G would one 
% try need? Type [their TBS, that rate] into myE2, and say why that block cannot 
% be sent in one try.
% 
% Your answer:
myE2 = NaN;   % [their TBS, real rate (TBS + CRC) / G]
if any(isnan(myE2)) || numel(myE2) ~= 2
    disp('Type two numbers into myE2, then run this section again.')
else
    e2Car = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);
    e2P = nrPDSCHConfig;  e2P.PRBSet = 0:23;  e2P.SymbolAllocation = [2 12];  e2P.Modulation = 'QPSK';
    [~, e2Info] = nrPDSCHIndices(e2Car, e2P);
    e2TBS = nrTBS('QPSK', 1, 52, e2Info.NREPerPRB, 0.48);
    e2CRC = numel(nrCRCEncode(zeros(e2TBS,1), nrDLSCHInfo(e2TBS, 0.48).CRC)) - e2TBS;
    e2Ref = [e2TBS, (e2TBS + e2CRC)/e2Info.G];
    okE2  = abs(myE2(:) - e2Ref(:)) <= max(0.01*abs(e2Ref(:)), 1e-9);
    e2Hint = ["nrTBS with 52 as nPRB"; "the block with its CRC over the 24-PRB G"];
    e2Hint(okE2) = "";
    e2Check = table(["Their TBS"; "Real rate needed"], okE2, e2Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e2Check
end
%% E3 — New values (B2)
% MCS 17 is the first 64QAM row of QAM64Table. Find its Qm and R, and those 
% of MCS 16. Type [Qm × R for MCS 17, Qm × R for MCS 16] into myE3. Without 
% computing any TBS, explain why the scheduler would not see a jump in bits 
% per RE at this modulation boundary, and why the table is built that way.
% 
% Your answer:
myE3 = NaN;   % [Qm x R for MCS 17, Qm x R for MCS 16]
if any(isnan(myE3)) || numel(myE3) ~= 2
    disp('Type two numbers into myE3, then run this section again.')
else
    e3t = nrPDSCHMCSTables().QAM64Table;
    e3Ref = [double(e3t.Qm(e3t.MCSIndex == 17))*double(e3t.TargetCodeRate(e3t.MCSIndex == 17)), ...
             double(e3t.Qm(e3t.MCSIndex == 16))*double(e3t.TargetCodeRate(e3t.MCSIndex == 16))];   % second route: Qm times R from the table
    okE3  = abs(myE3(:) - e3Ref(:)) <= 0.002*abs(e3Ref(:));
    e3Hint = ["Qm and R of the MCS 17 row"; "Qm and R of the MCS 16 row"];
    e3Hint(okE3) = "";
    e3Check = table(["Qm × R, MCS 17"; "Qm × R, MCS 16"], okE3, e3Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e3Check
end
%% E4 — Explanation (B3)
% After the first try of B3, what is in the HARQ soft buffer? Type the number 
% of the best answer into myE4: (1) the decoded bits of the first try; (2) 
% the first try's LLRs, placed at their positions in the coded-bit buffer; 
% (3) the received symbols of the first try; (4) nothing, because the first 
% try failed its CRC. Then explain why combining both tries does better than 
% decoding each on its own and keeping whichever passes, and why B3 empties 
% the buffer at each new SNR.
% 
% Your answer:
myE4 = NaN;   % 1, 2, 3, or 4
if isnan(myE4) || numel(myE4) ~= 1
    disp('Type one number into myE4, then run this section again.')
else
    okE4 = myE4 == find(["bits", "LLRs", "symbols", "nothing"] == "LLRs");   % the decoder keeps soft values
    e4Hint = "";
    if ~okE4
        e4Hint = "what does the decoder combine the new LLRs with?";
    end
    e4Check = table("Contents of the soft buffer", okE4, e4Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e4Check
end
%% E5 — Diagnosis (B4)
% A first try goes out at MCS 5 of QAM64Table on the B1 allocation (24 PRBs, 
% symbols 2 to 13, no additional DM-RS). It fails. The retransmission can 
% only get 20 PRBs, so a classmate works out a new TBS with nrTBS for 20 PRBs. 
% Type [the first try's TBS, the classmate's TBS, G of the 20-PRB retransmission] 
% into myE5. Which TBS must the retransmission carry, and what does that do 
% to its code rate?
% 
% Your answer:
myE5 = NaN;   % [TBS on 24 PRBs, TBS on 20 PRBs, G on 20 PRBs]
if any(isnan(myE5)) || numel(myE5) ~= 3
    disp('Type three numbers into myE5, then run this section again.')
else
    e5t = nrPDSCHMCSTables().QAM64Table;
    e5Mod = char(e5t.Modulation(e5t.MCSIndex == 5));  e5R = double(e5t.TargetCodeRate(e5t.MCSIndex == 5));
    e5Car = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);
    e5P = nrPDSCHConfig;  e5P.PRBSet = 0:19;  e5P.SymbolAllocation = [2 12];  e5P.Modulation = e5Mod;
    [~, e5Info] = nrPDSCHIndices(e5Car, e5P);
    e5Ref = [nrTBS(e5Mod, 1, 24, e5Info.NREPerPRB, e5R), nrTBS(e5Mod, 1, 20, e5Info.NREPerPRB, e5R), e5Info.G];
    okE5  = myE5(:) == e5Ref(:);
    e5Hint = ["nrTBS with MCS 5's modulation and rate on 24 PRBs"; "the same on 20 PRBs"; "NREPerPRB × 20 × Qm"];
    e5Hint(okE5) = "";
    e5Check = table(["TBS, 24 PRBs"; "TBS, 20 PRBs"; "G, 20 PRBs"], okE5, e5Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e5Check
end
%% E6 — New values (B5)
% A shorter type A PDSCH uses symbols 2 to 11 (SymbolAllocation = [2 10]), 
% with DMRSTypeAPosition 2. Using the l_d table in Key relationships, list 
% its DM-RS symbols for DMRSAdditionalPosition = 1 and 3, and work out NREPerPRB 
% for each. Type [NREPerPRB for position 1, NREPerPRB for position 3, the symbol 
% of the one additional DM-RS for position 1] into myE6. Why is that additional 
% DM-RS not on symbol 11 as in B5?
% 
% Your answer:
myE6 = NaN;   % [NREPerPRB pos 1, NREPerPRB pos 3, additional DM-RS symbol for pos 1]
if any(isnan(myE6)) || numel(myE6) ~= 3
    disp('Type three numbers into myE6, then run this section again.')
else
    e6Car = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);
    e6P = nrPDSCHConfig;  e6P.PRBSet = 0:23;  e6P.SymbolAllocation = [2 10];
    e6P.DMRS.DMRSAdditionalPosition = 1;  [~, e6a] = nrPDSCHIndices(e6Car, e6P);   % second route: the toolbox
    e6P.DMRS.DMRSAdditionalPosition = 3;  [~, e6b] = nrPDSCHIndices(e6Car, e6P);
    e6Ref = [e6a.NREPerPRB, e6b.NREPerPRB, max(e6a.DMRSSymbolSet)];
    okE6  = myE6(:) == e6Ref(:);
    e6Hint = ["12 × symbols − 12 × DM-RS symbols"; "12 × symbols − 12 × DM-RS symbols"; "l_d for this allocation"];
    e6Hint(okE6) = "";
    e6Check = table(["NREPerPRB, position 1"; "NREPerPRB, position 3"; "Additional DM-RS symbol"], okE6, e6Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e6Check
end
%% Exercise cleanup
clear myE1 e1Car e1P e1Info e1TBS e1CRC e1Ref okE1 e1Hint e1Check ...
      myE2 e2Car e2P e2Info e2TBS e2CRC e2Ref okE2 e2Hint e2Check ...
      myE3 e3t e3Ref okE3 e3Hint e3Check myE4 okE4 e4Hint e4Check ...
      myE5 e5t e5Mod e5R e5Car e5P e5Info e5Ref okE5 e5Hint e5Check ...
      myE6 e6Car e6P e6a e6b e6Ref okE6 e6Hint e6Check
%% Recap — Say It Again (album track 05)
% A block's size comes from its allocation and its rate. When it fails, the 
% sender says it again: the same block, at a new redundancy version, and the 
% receiver combines both tries in one HARQ buffer. The DM-RS takes its share 
% of the REs first.
% Key relationships
% $$N_{\mathrm{info}} = N_{\mathrm{RE}}\cdot R\cdot Q_m\cdot \upsilon,\qquad G = N'_{\mathrm{RE}}\cdot 
% n_{\mathrm{PRB}}\cdot Q_m\cdot \upsilon$$
% 
% with N'_RE = 12 × the allocated symbols − the DM-RS REs, and the TBS N_info 
% quantized to a nearby allowed size. The rate over all tries is TBS / coded 
% bits sent; the rate one try really gets is (TBS + CRC) / G.
% What this means in practice
% • nrTBS needs the PDSCH's own PRBs and its REs per PRB, not the carrier's 
% size or 12 × 14.
% 
% • The MCS row sets Qm and R before the block is sent; that is link adaptation. 
% Read Qm and R from the table you index.
% 
% • A NACK brings the same block at a new RV; the decoder adds the new LLRs 
% to its soft buffer for that HARQ process. The retry adds energy and new coded 
% bits, and it does not always rescue the block.
% 
% • The TBS never changes on a retransmission; a new rate or MCS is a new block.
% 
% • Each DM-RS symbol takes 12 REs per PRB here, so more DM-RS means a smaller 
% TBS. Where the extra DM-RS sit depends on l_d.
% 
% • You set up a new PDSCH, worked out its REs per PRB and G by hand, and found 
% its TBS, its CRC, and the rate the block really gets.
% 
% • Next in the album: track06 (Taps in Time).
%% Review — self-check
% Collapse the Recap section above (or scroll until it and the header are 
% out of sight), then write from memory, in your own words. Do not look back 
% until you have written what you can.
% 
% First, each of the seven key ideas, one line each. Then, for each command 
% you write yourself (listed below by name only), its purpose, its inputs, and 
% its outputs.
% 
% When you have written all you can, scroll up to Key ideas to remember and 
% Key code terms to remember and compare. Mark anything you missed or got wrong, 
% and reread the beat where it was used. The commands you read, the families 
% of helpers, and the short lists at the start of each beat are not part of 
% this review. Nothing in this written list is checked by the script; the 
% retrieval section below is.
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
% • s.name = value and abs:
% 
% • nrCarrierConfig:
% 
% • nrPDSCHConfig:
% 
% • nrPDSCHIndices:
% 
% • nrTBS:
% 
% • numel:
% What I missed, and where to reread it
% 
%% Review — retrieval
% Still keeping the Recap collapsed: from album track 04 (Every Check Agrees, 
% track04/track04_every_check_agrees_demo), how many CRC bits does a payload 
% of A = 3825 bits get? Type the number into myAnswer and run this section. 
% Then, in one line, say why the receiver decides ACK or NACK from the CRC, 
% and not from the LDPC parity checks alone. The check asks nrCRCEncode and 
% does not print its value.
% 
% Why:
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    okReview = myAnswer == numel(nrCRCEncode(zeros(3825,1), nrDLSCHInfo(3825, 0.5).CRC)) - 3825;   % second route: count the bits added
    reviewCheck = table("CRC bits for A = 3825", okReview, ...
        VariableNames = {'Check', 'Pass'});
    reviewCheck
end
