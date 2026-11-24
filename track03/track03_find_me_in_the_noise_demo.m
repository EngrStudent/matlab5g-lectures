%% track03_find_me_in_the_noise_demo
%% Find Me in the Noise (album track 03): the SS/PBCH block, cell search, and the burst
% This demonstration follows a phone that wakes up knowing nothing: not the 
% cell, not the clock, not which beam points its way. It only knows what to 
% listen for.
% 
% The cell sends a synchronization signal block (SSB): a small tile of known 
% signals. The phone finds the tile in the noise, reads the cell's name from 
% it, learns which beam found it, and decodes the first broadcast message, 
% in four steps: PSS, SSS, PBCH DM-RS, and the MIB.
%% Guiding question
% How does a phone that knows nothing find a cell, its timing, and its name 
% in a noisy waveform?
% This demonstration
% 1. B1 — Build one SS/PBCH block by hand from its four pieces and check their 
% sizes and places.
% 
% 2. B2 — Cell search: bury the block in noise behind an unknown delay, find 
% the timing and N_ID(2) with the PSS, then N_ID(1) with the SSS.
% 
% 3. B3 — The trap: three cells share one PSS, and only the SSS tells them 
% apart.
% 
% 4. B4 — Which beam found me: the PBCH DM-RS gives the low bits of the SSB 
% index, and the BCH decodes the MIB with a CRC.
% 
% 5. B5 — The burst: check the Case A to G patterns, then count the SSB symbols 
% the generator sends in 20 ms.
% 
% 6. Build it — Split a cell ID into its two parts, place its PSS and SSS on 
% a tile, and find another cell with the same PSS.
% Key relationships
% The physical cell ID (PCI) is built from the two sync signals:
% 
% $$N_{\mathrm{ID}}^{\mathrm{cell}} = 3N_{\mathrm{ID}}^{(1)} + N_{\mathrm{ID}}^{(2)},\qquad 
% N_{\mathrm{ID}}^{(1)}\in\{0,\dots,335\},\ N_{\mathrm{ID}}^{(2)}\in\{0,1,2\}$$
% 
% so there are 336 × 3 = 1008 cells, and going back:
% 
% $$N_{\mathrm{ID}}^{(2)} = N_{\mathrm{ID}}^{\mathrm{cell}} \bmod 3,\qquad 
% N_{\mathrm{ID}}^{(1)} = \left\lfloor N_{\mathrm{ID}}^{\mathrm{cell}}/3\right\rfloor$$
% 
% One SS/PBCH block is 240 subcarriers by 4 OFDM symbols:
% 
% $$127_{\mathrm{PSS}} + 127_{\mathrm{SSS}} + 432_{\mathrm{PBCH}} + 144_{\mathrm{DM\text{-}RS}} 
% \le 240\times 4 = 960\ \text{REs}$$
% Key ideas to remember
% • An SS/PBCH block is 240 subcarriers by 4 symbols. Symbol 0 holds the PSS 
% and symbol 2 the SSS, 127 tones each in the middle; the PBCH fills symbols 
% 1 and 3 and both edges of symbol 2, and every fourth PBCH tone is a DM-RS.
% 
% • PCI = 3 × N_ID(1) + N_ID(2): 336 groups with three in each make 1008 cells, 
% and no two are the same.
% 
% • There are only three PSS sequences. Correlate the samples with all three: 
% the tallest peak gives where the block begins and which of the three you heard.
% 
% • Cells whose PCIs share a remainder mod 3 (such as 0, 3, and 6) share one 
% PSS; only the SSS pulls them apart, so the SSS search runs only over the 
% groups whose cells match the PSS already found.
% 
% • The PBCH DM-RS always comes in eight versions. With Lmax 8 or 64, the 
% one that matches gives the low three bits of the SSB index (with eight blocks 
% that names the beam that found you); with Lmax 4 it gives two index bits 
% plus the half-frame bit.
% 
% • Decode the PBCH and check the CRC: inside are the frame number and the 
% MIB, which points to CORESET 0, where the phone looks next.
% 
% • Blocks come in a burst inside one 5 ms half frame. Cases A to G name the 
% patterns, with up to 8 blocks in FR1 and 64 in FR2, and a phone that knows 
% nothing may assume the burst returns every 20 ms.
% Prerequisites
% • The resource grid, μ, nrCarrierConfig, nrResourceGrid, and nrOFDMInfo (album 
% track 01 Two to the Mu, track01/track01_two_to_the_mu_demo).
% 
% • nrOFDMModulate, nrOFDMDemodulate with CyclicPrefixFraction = 1, one tap 
% per subcarrier, and SNR on the time samples (album track 02 Copy the Tail, 
% track02/track02_copy_the_tail_demo).
% 
% • Used here, not taught here: CRC and LLRs (soft bits) are taught in album 
% track 04 (Every Check Agrees). The polar code that protects the PBCH is not 
% covered in the album: treat nrBCH and nrBCHDecode as a box.
% Words used in this demo
% • SSB (SS/PBCH block): the 240 × 4 tile a cell sends so phones can find it. 
% Its four pieces are named in B1 under New words.
% 
% • PCI (physical cell ID, N_ID^cell): the cell's name, 0 to 1007. N_ID(1) 
% (the group, 0 to 335) and N_ID(2) (the member, 0 to 2) are its two parts.
% 
% • Correlation: multiply the received samples by the conjugate of a known 
% sequence and add them up; a large result means the sequence is there.
% 
% • Timing offset: how many samples late the block starts in what the phone 
% received.
% 
% • SSB index (i_SSB): which block of the burst this is; each one can go out 
% on its own beam. Lmax: how many candidate blocks a burst has (4, 8, or 64).
% 
% • Half frame: 5 ms, half of a 10 ms frame. SFN (system frame number): the 
% count of 10 ms frames, 0 to 1023.
% 
% • MIB (master information block): the first message a phone decodes. CORESET 
% 0: the control region it points to, where the phone looks for SIB1 (system 
% information block 1). CRC: a check value that shows whether decoding worked.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • mod(a, b) and floor(x) — Purpose: the remainder after dividing a by b; 
% x rounded down to a whole number. Inputs: numbers. Outputs: a number.
% 
% • zeros(r, c) — Purpose: make an r × c array of zeros, an empty tile. Inputs: 
% the rows and the columns. Outputs: the array.
% 
% • x(ind) = v — Purpose: write the values v into the positions ind of x. Inputs: 
% an array, a list of positions, and as many values. Outputs: the changed array.
% 
% • nnz(x) — Purpose: count the entries that are not zero. Inputs: an array. 
% Outputs: a whole number.
% 
% • isequal(a, b) and ~ — Purpose: true when two arrays are the same size and 
% hold the same values; ~ turns true into false. Inputs: two or more arrays. 
% Outputs: true or false.
% 
% • s = nrPSS(pci) and s = nrSSS(pci) — Purpose: make the 127-entry primary 
% or secondary sync sequence for a cell. Inputs: a PCI, 0 to 1007. Outputs: 
% a column of 127 values.
% 
% • ind = nrPSSIndices and ind = nrSSSIndices — Purpose: where the PSS or SSS 
% goes on the 240 × 4 SSB tile. Inputs: none (or IndexStyle = 'subscript' for 
% row and column numbers). Outputs: 127 positions, counted down the columns 
% from 1.
% 
% Commands you read in the given code
% • nrPBCHIndices(pci), nrPBCHDMRSIndices(pci), and nrPBCHDMRS(pci, v) — 
% Purpose: where the PBCH and its DM-RS go on the tile, and the DM-RS values. 
% Inputs: the PCI, and for the DM-RS its version v (0 to 7; B4 explains it). 
% Outputs: 432 or 144 positions, or 144 values; nrPBCHIndices also returns 
% an info structure. Used in B1 and B4.
% Used in B1 and B4.
% 
% • nrOFDMModulate(grid, scs, nslot) and nrOFDMDemodulate(wave, nrb, scs, nslot, 
% CyclicPrefixFraction = 1) — Purpose: as in album track 02, but given the spacing 
% (kHz), the width in RBs, and the first slot number instead of a carrier. 
% Used in B2; nrOFDMDemodulate with a carrier is used again in B5.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, x(:), x.', G(:, cols), c{n}, s.name — Purpose: 
% read entries, count a range, reshape to a column or row, pick columns, read 
% a cell or a structure field. Inputs: an array and positions. Outputs: the 
% entries.
% 
% • Compare and combine: == ~= < > <= >=, && || & ~, .* ./ — Purpose: compare 
% values; and, or, not; multiply and divide entry by entry. Inputs: numbers 
% or arrays. Outputs: true/false or numbers, entry by entry.
% 
% • Control flow: for ... end, if ... else ... end — Purpose: repeat a block 
% for each value of a list; run one block or the other. Inputs: a list or a 
% true/false test. Outputs: whatever the blocks store.
% 
% • Built-in helpers: numel, size, sum, mean, all, max, min, abs, conj, sqrt, 
% round, double, find, sort, unique, reshape, ismember, randi, bitget, cell, false, 
% exist, isnan, NaN, [] — Purpose: count, add, average, test, find the largest, 
% conjugate, sort, and look things up. Inputs: numbers, arrays, or names. Outputs: 
% numbers or true/false (NaN means "no number yet").
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
% Requires the 5G Toolbox. There is no nrSSBConfig function: the burst is set 
% on nrDLCarrierConfig's SSBurst property (B5). Teaching demo, not production 
% code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year), so the stand-in MIB bits and the B2 noise repeat on every run

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");
%% B1 — Build one block by hand
% New words
% • PSS (primary synchronization signal) and SSS (secondary synchronization 
% signal): two known 127-entry sequences; the PSS carries N_ID(2) and the SSS 
% carries N_ID(1).
% 
% • PBCH (physical broadcast channel): carries the coded MIB, 432 QPSK symbols 
% in each block. PBCH DM-RS (demodulation reference signal): 144 known symbols 
% on every fourth PBCH tone, used to learn the channel.
% 
% • BCH codeword: the coded MIB bits, E = 864 bits, two per QPSK symbol.
% 
% Beat-only commands (B1)
% • cw = nrBCH(mib, sfn, hrf, lssb, kssb, pci) — Purpose: encode the MIB into 
% the BCH codeword. Inputs: 24 MIB bits, the SFN, the half-frame bit, Lmax, 
% k_SSB, and the PCI. Outputs: 864 bits.
% 
% • sym = nrPBCH(cw, pci, v) — Purpose: scramble and QPSK-map the codeword. 
% Inputs: the codeword, the PCI, and v, the DM-RS version (B4). Outputs: 432 symbols.
% 
% • Figure family: figure(Name = ...), imagesc, axis xy, colormap, colorbar, 
% xlabel, ylabel, title — Purpose: draw a tile as coloured cells, with row 0 
% at the bottom, a chosen set of colours, and a key. Inputs: data and text. 
% Outputs: a figure. Used again in Build it.
% Why it matters
% An SS/PBCH block is a 240 × 4 tile built from four known pieces: PSS, SSS, 
% PBCH, and PBCH DM-RS. Each piece has a fixed length (127, 127, 432, 144) and 
% a documented place on the tile, so you can build one block from the toolbox's 
% primitive functions and check its sizes before any search starts.
% What to look for
% • In the sizes table, read the length of each piece and the codeword length.
% 
% • In the places table, find the SSB symbol of the PSS and the SSS (1-based 
% columns), and the subcarrier range of the PSS.
% 
% • In the figure, find the PSS and SSS in the middle and the PBCH on both edges 
% of the SSS symbol.
% Common mistakes
% Do not treat "SSB" as one library object. There is no nrSSBConfig; the burst 
% is set later, on nrDLCarrierConfig's SSBurst property (B5).
% 
% Do not mix 0-based and 1-based counting: the standard counts subcarriers 
% and symbols from 0, and MATLAB positions start at 1.
% Try it (personal exploration)
% Use the four piece lengths in Why it matters to predict how many of the tile's 
% 240 × 4 REs stay empty (zero). Type that number into myPrediction in the 
% first code line below before you run this section; the one-row table at the 
% end compares it with the tile.
% 
% Then, optionally, change pci (0 to 1007) or ssbIndex (0 to 7) and run again: 
% the sizes and the empty count never change; only the sequences do. Every 
% check in this section tests a size or a place, so these changes do not stop 
% the run.

% Try it: type your prediction here (a number of REs) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Build one block by hand
fprintf("B1 — Build one block by hand\n");   % banner title only; every number below goes into a table

% The cell and the block. pci is the cell's name; its two parts come from
% mod and floor. The block settings feed the BCH encoder and the DM-RS.
pci      = 397;               % physical cell ID: any whole number 0 to 1007
nid2     = mod(pci,3);        % N_ID(2), carried by the PSS: 0, 1, or 2
nid1     = floor(pci/3);      % N_ID(1), carried by the SSS: 0 to 335
ssbIndex = 5;                 % SSB index i_SSB of this block: 0 to Lmax - 1
lssb     = 8;                 % Lmax, candidate blocks per half frame: 8 (Case A above 3 GHz)
hrf      = 0;                 % half-frame bit: 0 = the first 5 ms of the frame
sfn      = 113;               % system frame number: 0 to 1023
kssb     = 0;                 % k_SSB, the block's subcarrier offset, in subcarriers
v        = mod(ssbIndex, 8);  % the 3 low bits of the SSB index: the DM-RS version (B4 explains it)

% Make each piece and its positions on the tile. The positions count down
% the columns from 1 (the toolbox's linear indexes on a 240 × 4 tile).
ssb    = zeros(240, 4);                       % 240 subcarriers × 4 OFDM symbols
pssSym = nrPSS(pci);    pssInd = nrPSSIndices;
sssSym = nrSSS(pci);    sssInd = nrSSSIndices;
mib    = randi([0 1], 24, 1);                 % stand-in MIB (BCCH-BCH message): 24 random bits
cw     = nrBCH(mib, sfn, hrf, lssb, kssb, pci);
[pbchInd, pbchInfo] = nrPBCHIndices(pci);
pbchSym = nrPBCH(cw, pci, v);
dmrsSym = nrPBCHDMRS(pci, v);                 % DM-RS version v (B4)
dmrsInd = nrPBCHDMRSIndices(pci);

% Write every piece into its positions on the tile.
ssb(pssInd)  = pssSym;   ssb(sssInd)  = sssSym;
ssb(pbchInd) = pbchSym;  ssb(dmrsInd) = dmrsSym;

% Sizes: each test is stored first so the check table reports it.
okSyncLength = numel(pssSym) == 127 && numel(sssSym) == 127;   % 127 entries each
assert(okSyncLength, ...
    'The PSS or SSS is not 127 long. Look first at the nrPSS and nrSSS lines: they take the PCI only.');
okCodeword = numel(cw) == 864 && pbchInfo.G == 864;            % E = 864 coded bits
assert(okCodeword, ...
    'The BCH codeword is not 864 bits. Look first at the nrBCH inputs: 24 MIB bits, then sfn, hrf, lssb, kssb, and pci.');
okPBCH = numel(pbchInd) == 432 && pbchInfo.Gd == 432;          % 432 QPSK symbols
assert(okPBCH, ...
    'The PBCH is not 432 symbols. Look first at nrPBCHIndices: it takes the PCI.');
okDMRS = numel(dmrsSym) == 144 && numel(dmrsInd) == 144;       % 144 DM-RS symbols
assert(okDMRS, ...
    'The PBCH DM-RS is not 144 symbols. Look first at nrPBCHDMRS(pci, v) and nrPBCHDMRSIndices(pci).');
okFill = numel(pbchInd) + numel(dmrsInd) == 2*240 + 2*48;      % symbols 1 and 3 in full, plus 48 tones on each edge of symbol 2
assert(okFill, ...
    'PBCH and DM-RS do not fill symbols 1 and 3 and the SSS-symbol edges. Common mistake: counting the DM-RS inside the 432 PBCH symbols.');

% Places: the same positions as row (subcarrier) and column (symbol)
% numbers, both counted from 1.
pssSub = nrPSSIndices(IndexStyle = 'subscript');              % columns: subcarrier, symbol, port
sssSub = nrSSSIndices(IndexStyle = 'subscript');
okSyncSymbols = all(pssSub(:,2) == 1) && all(sssSub(:,2) == 3);   % 1-based: SSB symbol 0 and symbol 2
assert(okSyncSymbols, ...
    'The PSS or SSS is in the wrong symbol. Common mistake: 1-based column 1 is SSB symbol 0, and column 3 is symbol 2.');
okPSSTones = min(pssSub(:,1)) == 57 && max(pssSub(:,1)) == 183;   % 1-based 57..183 = 0-based subcarriers 56..182
assert(okPSSTones, ...
    'The PSS is not on subcarriers 56 to 182. Common mistake: the toolbox counts from 1, so look for 57 to 183.');

% The pieces in one row, and the places in another.
b1Sizes = table(numel(pssSym), numel(sssSym), numel(cw), numel(pbchSym), numel(dmrsSym), ...
    VariableNames = {'PSS', 'SSS', 'BCHCodewordBits', 'PBCH', 'DMRS'});
b1Sizes
b1Places = table(pssSub(1,2), sssSub(1,2), min(pssSub(:,1)), max(pssSub(:,1)), ...
    VariableNames = {'PSSColumn', 'SSSColumn', 'PSSFirstRow', 'PSSLastRow'});
b1Places

% Mechanism figure: the tile, one colour per piece.
lbl = zeros(240,4);                                           % 0 = empty RE
lbl(pssInd) = 1;  lbl(sssInd) = 2;  lbl(pbchInd) = 3;  lbl(dmrsInd) = 4;   % one label per piece
figure(Name = 'Track 03 B1 - one SS/PBCH block', Color = 'w');
imagesc(0:3, 0:239, lbl, [0 4]);                              % 0-based symbols across, subcarriers up; colour range 0 to 4
axis xy;                                                      % subcarrier 0 at the bottom
colormap([1 1 1; 0.85 0.2 0.2; 0.2 0.4 0.85; 0.3 0.7 0.3; 0.1 0.1 0.1]);   % white, red, blue, green, black
cb = colorbar;  cb.Ticks = 0:4;  cb.TickLabels = {'zero','PSS','SSS','PBCH','PBCH DM-RS'};   % one key entry per label
xlabel('SSB OFDM symbol');
ylabel('subcarrier k');
title(sprintf('SSB for PCI %d: 240 subcarriers x 4 symbols', pci));

% Put your Try-it prediction beside the number of empty REs on the tile.
emptyREs = nnz(ssb == 0);
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, emptyREs, predictionNote, ...
    VariableNames = {'MyPrediction', 'EmptyREs', 'Note'});
b1Prediction
%% B1 — After the run
% The sizes table shows the four pieces at their fixed lengths, with two coded 
% bits per PBCH QPSK symbol. The places table shows the PSS in column 1 and 
% the SSS in column 3, which are SSB symbols 0 and 2 counted from 0, and the 
% PSS on rows 57 to 183, the middle 127 of the 240 subcarriers. In the figure, 
% the PBCH fills symbols 1 and 3 and the two edges of symbol 2, with its DM-RS 
% dotted on every fourth tone. Compare EmptyREs with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flags. The
% asserts stop the run on a failure, so this table appears only when every
% check has passed, and shows the evidence.
b1Checks = table( ...
    ["PSS and SSS lengths = 127"; ...
     "BCH codeword = 864 bits (and pbchInfo.G)"; ...
     "PBCH = 432 symbols (and pbchInfo.Gd)"; ...
     "DM-RS = 144 symbols and 144 positions"; ...
     "PBCH + DM-RS = 2 × 240 + 2 × 48"; ...
     "PSS in column 1, SSS in column 3 (1-based)"; ...
     "PSS rows 57 to 183 (1-based)"], ...
    [listText([127 127]); ...
     listText([864 864]); ...
     listText([432 432]); ...
     listText([144 144]); ...
     string(2*240 + 2*48); ...
     listText([1 3]); ...
     listText([57 183])], ...
    [listText([numel(pssSym) numel(sssSym)]); ...
     listText([numel(cw) pbchInfo.G]); ...
     listText([numel(pbchInd) pbchInfo.Gd]); ...
     listText([numel(dmrsSym) numel(dmrsInd)]); ...
     string(numel(pbchInd) + numel(dmrsInd)); ...
     listText([unique(pssSub(:,2)) unique(sssSub(:,2))]); ...
     listText([min(pssSub(:,1)) max(pssSub(:,1))])], ...
    [okSyncLength; okCodeword; okPBCH; okDMRS; okFill; okSyncSymbols; okPSSTones], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep the cell (pci, nid2), the block settings B4 checks (v, lssb, hrf,
% sfn, mib), the tile and the PSS/SSS positions for B2, and listText.
% Everything else was used only to build, test, or show B1.
clear b1Sizes b1Places b1Checks b1Prediction predictionNote emptyREs ...
      okSyncLength okCodeword okPBCH okDMRS okFill okSyncSymbols okPSSTones ...
      nid1 ssbIndex kssb pssSym sssSym cw pbchInd pbchInfo pbchSym dmrsSym dmrsInd ...
      pssSub sssSub lbl cb myPrediction
%% B2 — Find the cell: PSS in time, then SSS
% New words
% • Hypothesis: one guess the receiver tests, here one of the three PSS sequences 
% or one of the 336 SSS groups.
% 
% • Correlation peak: the largest correlation value; where it sits gives the 
% timing, and which hypothesis made it gives the ID.
% 
% Beat-only commands (B2)
% • [offset, mag] = nrTimingEstimate(rx, nrb, scs, nslot, ref) — Purpose: correlate 
% a received waveform with a reference grid. Inputs: the samples, the width 
% in RBs, the spacing in kHz, the first slot number, and a reference grid. Outputs: 
% the timing offset in samples (where the slot starts) and the correlation 
% magnitude at every offset.
% 
% • randn(size(x)) — Purpose: Gaussian random numbers, mean 0 and power 1. 
% Inputs: a size. Outputs: an array.
% 
% • Line-plot family: plot(..., DisplayName = ...), hold on, xline, grid on, 
% legend — Purpose: draw several curves on one plot, each with a name for the 
% legend, and mark a position. Inputs: data and text. Outputs: a figure.
% Why it matters
% The phone does not yet know the cell ID or the frame timing. There are only 
% three PSS sequences, so it slides across the samples and tries all three: 
% the tallest peak tells it two things at once, where the block begins and 
% which of the three it heard (N_ID(2)). Then it demodulates at that timing 
% and tries every SSS group, N_ID(1), paired with that N_ID(2); the best match 
% is the group, and the PCI follows.
% What to look for
% • In the search table, compare the found timing with the planted delay D, 
% and the found N_ID(2) and PCI with the true ones.
% 
% • In the figure, find the tallest of the three curves and where its peak sits.
% Common mistakes
% Do not demodulate before finding the timing peak: the FFT windows would sit 
% in the wrong place.
% 
% Do not search the SSS over all 1008 PCIs: only the cells that share the PSS 
% you already found can be the cell.
% Try it (personal exploration)
% The cell is pci = 397 from B1. Suppose Step 1 below had picked the wrong 
% PSS, the next one round, (true N_ID(2) + 1) mod 3, while Step 2 still found 
% the true group N_ID(1). Which PCI would the phone then report? Type that 
% number into myPrediction before you run this section; the one-row table at 
% the end compares it with the PCI built from the found parts.
% 
% Then, optionally, change D (the planted delay, in samples) and run again: 
% the timing search should still land within one sample of it, so changing 
% D does not stop the run. Leave snrdB at 10 dB for the Try: at a much lower 
% SNR the search itself fails, and the checks stop the run with a message that 
% names the step (PSS ID, PSS timing, or SSS ID).

% Try it: type your prediction here (a PCI) before running this section.
myPrediction = NaN;   % your Try-it guess (a PCI); NaN means "not typed yet", and the comparison table below says so

% B2 — Find the cell
fprintf("B2 — Find the cell: PSS in time, then SSS\n");   % banner title only

% One 15 kHz slot, 20 RBs wide (just the SSB), with the block on symbols
% 2 to 5 (Case A's first block), OFDM-modulated with no windowing.
nrb = 20;                                     % slot width in RBs: 20 RB = 240 subcarriers, the SSB width
scs = 15;                                     % subcarrier spacing in kHz
slotGrid = zeros(240, 14);                    % 240 subcarriers × 14 symbols: one slot
slotGrid(:, 3:6) = ssb;                       % 1-based columns 3 to 6 = symbols 2 to 5
[tx, ofdmInfo] = nrOFDMModulate(slotGrid, scs, 0);   % 0 = first slot number

% The channel: an unknown delay and noise. The SNR is measured against the
% average power of the whole slot, empty symbols included.
D     = 333;                                  % planted delay in samples (Try: any value from 0 to a few thousand)
snrdB = 10;                                   % SNR in dB, relative to the slot's average sample power
rx = [zeros(D,1); tx; zeros(200,1)];          % D samples of silence before, 200 after
nPow = mean(abs(tx).^2) / 10^(snrdB/10);      % noise power per sample
rx = rx + sqrt(nPow/2)*(randn(size(rx)) + 1j*randn(size(rx)));   % /2: half the noise power in I, half in Q

% Step 1: three PSS hypotheses. For each, build a reference slot holding
% only that PSS and correlate it with the received samples; keep each
% hypothesis's timing, its peak, and its whole curve for the figure.
peak = zeros(1,3);  offs = zeros(1,3);  magAll = cell(1,3);
for h = 0:2
    ref = zeros(240,14);                      % one slot, empty
    tmp = zeros(240,4);  tmp(pssInd) = nrPSS(h);  ref(:,3:6) = tmp;   % PSS of hypothesis h only, on the SSB symbols
    [offs(h+1), mag] = nrTimingEstimate(rx, nrb, scs, 0, ref);       % 0 = first slot number
    peak(h+1) = max(mag);  magAll{h+1} = mag;
end
[~, best] = max(peak);
nid2Hat = best - 1;                           % -1: hypothesis h is stored at position h+1
offHat  = offs(best);

okPSSID = nid2Hat == nid2;
assert(okPSSID, ...
    'Step 1 (PSS ID) failed: wrong N_ID(2). Look first at snrdB: raise it, and check that the reference holds nrPSS(h).');
okTiming = abs(offHat - D) <= 1;              % within 1 sample of the planted delay
assert(okTiming, ...
    'Step 1 (PSS timing) failed: the offset is not within 1 sample of D. Look first at snrdB, then at the reference slot''s SSB columns.');

% Step 2: demodulate at that timing, then score the 336 SSS candidates
% that share the PSS just found. Each pass correlates one candidate.
rxSlot = nrOFDMDemodulate(rx(offHat+1 : offHat+numel(tx)), nrb, scs, 0, CyclicPrefixFraction = 1);   % 0 = first slot; 1 = window on the exact body
rxSSB  = rxSlot(:, 3:6);                      % the four SSB symbols
rxSSS  = rxSSB(sssInd);
score  = zeros(1,336);
for g = 0:335
    score(g+1) = abs(sum(conj(nrSSS(3*g + nid2Hat)) .* rxSSS));
end
[~, gBest] = max(score);
nid1Hat = gBest - 1;                          % -1: group g is stored at position g+1
pciHat  = 3*nid1Hat + nid2Hat;                % PCI = 3 N_ID(1) + N_ID(2)

okPCI = pciHat == pci;
assert(okPCI, ...
    'Step 2 (SSS ID) failed: wrong N_ID(1). Look first at the timing offset, then at snrdB.');

% The search in one row.
b2Search = table(D, offHat, nid2, nid2Hat, pci, nid1Hat, pciHat, ...
    VariableNames = {'PlantedD', 'FoundOffset', 'TrueNID2', 'FoundNID2', ...
                     'TruePCI', 'FoundNID1', 'FoundPCI'});
b2Search
b2Peaks = table((0:2).', peak(:), offs(:), ...
    VariableNames = {'PSSHypothesis', 'PeakMagnitude', 'Offset'});
b2Peaks

% Mechanism figure: the three correlation curves, with the planted delay.
figure(Name = 'Track 03 B2 - PSS correlation: the tallest peak', Color = 'w');
hold on;
for h = 0:2
    plot(0:numel(magAll{h+1})-1, magAll{h+1}, DisplayName = sprintf('PSS hypothesis N_{ID}^{(2)} = %d', h));
end
xline(D, '--k', 'planted D', DisplayName = 'planted delay D');
xlabel('timing offset (samples)');
ylabel('correlation magnitude');
grid on;
legend;
title('PSS search: the tallest peak gives N_{ID}^{(2)} and the timing');

% Put your Try-it prediction beside the PCI built from the found group and
% the wrong PSS: the next one round, (found N_ID(2) + 1) mod 3.
pciIfWrongPSS = 3*nid1Hat + mod(nid2Hat + 1, 3);
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, pciIfWrongPSS, predictionNote, ...
    VariableNames = {'MyPrediction', 'PCIWithWrongPSS', 'Note'});
b2Prediction
%% B2 — After the run
% The peaks table shows one hypothesis far taller than the other two, and 
% its offset sits on the planted delay (within one sample). That one curve 
% in the figure peaks at the dashed line. With the timing known, the SSS search 
% over 336 groups returns the true group, so the found PCI equals the true 
% one. Compare PCIWithWrongPSS with your prediction: a wrong PSS moves the 
% reported cell even when the group is right.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Step 1: found N_ID(2) = true N_ID(2)"; ...
     "Step 1: |found offset − D| <= 1 sample"; ...
     "Step 2: found PCI = true PCI"], ...
    [string(nid2); ...
     string(D) + " ± 1"; ...
     string(pci)], ...
    [string(nid2Hat); ...
     string(offHat); ...
     string(pciHat)], ...
    [okPSSID; okTiming; okPCI], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep pci for B3 and B5, and rxSSB, pciHat, v, lssb, hrf, sfn, and mib for
% B4. Everything else was used only to build, test, or show B2.
clear b2Search b2Peaks b2Checks b2Prediction predictionNote ...
      okPSSID okTiming okPCI ...
      ssb pssInd sssInd nid2 nrb scs slotGrid tx ofdmInfo D snrdB nPow rx ...
      peak offs magAll h ref tmp mag best nid2Hat offHat ...
      rxSlot rxSSS score g gBest nid1Hat pciIfWrongPSS myPrediction
%% B3 — The trap: three cells, one PSS
% New words
% • One-to-one map (bijection): every (N_ID(1), N_ID(2)) pair gives a different 
% PCI, and every PCI from 0 to 1007 comes from exactly one pair.
% 
% Beat-only commands (B3)
% • [A, B] = ndgrid(a, b) — Purpose: every pairing of the values in a with 
% the values in b, as two arrays of the same size. Inputs: two lists. Outputs: 
% two arrays.
% 
% • unique(A, 'rows') — Purpose: the different rows of A, each once. Inputs: 
% an array. Outputs: those rows; size(..., 1) counts them.
% Why it matters
% PCI = 3 × N_ID(1) + N_ID(2) maps the 336 × 3 pairs onto 0 to 1007, one each. 
% N_ID(2) is carried by the PSS and N_ID(1) by the SSS. So cells 0, 3, and 6 
% sing the same primary sequence: stop after the PSS and you would swear they 
% were one cell. Only the secondary pulls them apart.
% What to look for
% • In the map table, read how many different PCIs the pairs make, and the smallest 
% and largest.
% 
% • In the trap table, read how many different PSS and SSS sequences the 1008 
% cells send, and whether cells 0, 3, and 6 have different SSS.
% Common mistakes
% Do not think 1008 cell IDs means 1008 different PSS sequences. There are 
% only three.
% Try it (personal exploration)
% Predict how many of the PCIs from 0 to 99 share cell 397's PSS, that is, 
% have the same N_ID(2). Type that number into myPrediction before you run 
% this section; the one-row table at the end compares it with a count over 
% PCIs 0 to 99.

% Try it: type your prediction here (a number of cells) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — The trap
fprintf("B3 — The trap: three cells, one PSS\n");   % banner title only

% Every pairing of N_ID(1) = 0..335 with N_ID(2) = 0..2, turned into PCIs.
[n1, n2] = ndgrid(0:335, 0:2);                % 336 groups × 3 members
allPCI = 3*n1(:) + n2(:);                     % PCI = 3 N_ID(1) + N_ID(2), one per pair

% Build the PSS and the SSS of all 1008 cells, one column per PCI, so the
% checks count sequences rather than re-reading the PCI formula.
allPSS = zeros(127, 1008);  allSSS = zeros(127, 1008);       % 127 entries per sequence, 1008 cells
for p = 0:1007
    allPSS(:,p+1) = nrPSS(p);                                 % +1: PCI p is stored in column p+1
    allSSS(:,p+1) = nrSSS(p);
end
nDiffPSS   = size(unique(allPSS.', 'rows'), 1);               % different PSS sequences among the 1008 cells
nDiffSSS   = size(unique(allSSS.', 'rows'), 1);               % different SSS sequences
nDiffPairs = size(unique([allPSS; allSSS].', 'rows'), 1);     % different (PSS, SSS) pairs

% The map is one-to-one: the pairs make 0 to 1007 once each, and every cell
% sends a different (PSS, SSS) pair.
okOneToOne = isequal(sort(allPCI).', 0:1007) && nDiffPairs == 1008;
assert(okOneToOne, ...
    'The PCI map does not hit 0 to 1007 once each. Look first at allPCI: it should be 3*n1 + n2.');

% The trap: only three PSS sequences exist, cells 0, 3, and 6 share one,
% and every cell's SSS is its own.
okSharedPSS = nDiffPSS == 3 && isequal(allPSS(:,1), allPSS(:,4), allPSS(:,7));   % columns 1, 4, 7 = cells 0, 3, 6
assert(okSharedPSS, ...
    'There should be three PSS sequences, with cells 0, 3, and 6 sharing one. Common mistake: the PSS depends on N_ID(2) only.');
okSSSDiffer = nDiffSSS == 1008;
assert(okSSSDiffer, ...
    'Every cell should have its own SSS. Look first at the nrSSS calls: they need the PCI, not N_ID(2).');

% The map and the trap, each in one row.
b3Map = table(numel(allPCI), numel(unique(allPCI)), min(allPCI), max(allPCI), ...
    VariableNames = {'Pairs', 'DifferentPCIs', 'SmallestPCI', 'LargestPCI'});
b3Map
b3Trap = table(nDiffPSS, nDiffSSS, nDiffPairs, ~isequal(allSSS(:,1), allSSS(:,4)), ~isequal(allSSS(:,4), allSSS(:,7)), ...
    VariableNames = {'DifferentPSS', 'DifferentSSS', 'DifferentPairs', 'SSS_0_3_Differ', 'SSS_3_6_Differ'});
b3Trap

% Put your Try-it prediction beside a count over PCIs 0 to 99, made by
% comparing sequences rather than remainders.
tryRange  = 0:99;                                             % Try: the PCIs to count, 0 to 99
nSharePSS = nnz(all(allPSS(:, tryRange+1) == nrPSS(pci), 1)); % PCIs in tryRange whose PSS equals cell pci's
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, pci, nSharePSS, predictionNote, ...
    VariableNames = {'MyPrediction', 'PCI', 'SharingItsPSS_0to99', 'Note'});
b3Prediction
%% B3 — After the run
% The map table shows 1008 pairs making 1008 different PCIs, from 0 to 1007: 
% no two cells share a name. The trap table counts the sequences themselves: 
% three PSS among 1008 cells, but 1008 different SSS, so a search that stopped 
% after the PSS would merge cells. Compare SharingItsPSS_0to99 with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flags.
b3Checks = table( ...
    ["PCI map is one-to-one onto 0..1007, one (PSS, SSS) pair each"; ...
     "Three PSS; cells 0, 3, 6 share one"; ...
     "Every cell has its own SSS"], ...
    ["0 to 1007, once each; 1008 pairs"; "3 PSS"; "1008 SSS"], ...
    [string(numel(unique(allPCI))) + " different, " + string(min(allPCI)) + " to " + string(max(allPCI)) + "; " + string(nDiffPairs) + " pairs"; ...
     string(nDiffPSS) + " PSS"; ...
     string(nDiffSSS) + " SSS"], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B3 was used only to build, test, or show B3.
clear b3Map b3Trap b3Checks b3Prediction predictionNote ...
      okOneToOne okSharedPSS okSSSDiffer n1 n2 allPCI tryRange nSharePSS myPrediction ...
      allPSS allSSS p nDiffPSS nDiffSSS nDiffPairs
%% B4 — Which beam found me: DM-RS index and MIB
% New words
% • Beam: a direction the cell aims a block at. Each SSB index can go out on 
% its own beam, so knowing the index tells the phone which beam found it.
% 
% • LLR (soft bit): a number whose sign is the bit and whose size is the confidence 
% (taught in album track 04).
% 
% • CRC flag (errFlag): 0 when the decoded bits pass their CRC, 1 when they 
% do not.
% 
% • ibar_SSB: the DM-RS version, 0 to 7, written v in the code. With Lmax 
% = 8 it is the SSB index mod 8; with Lmax = 4 it is i_SSB + 4 × the half-frame 
% bit.
% 
% Beat-only commands (B4)
% • soft = nrPBCHDecode(sym, pci, v, nVar) — Purpose: undo the QPSK mapping 
% and the scrambling of the PBCH. Inputs: the equalized PBCH symbols, the PCI, 
% v, and the noise variance. Outputs: 864 soft bits.
% 
% • [~, errFlag, trblk, lsbofsfn, hrfHat, msbidxoffset] = nrBCHDecode(soft, 
% L, lssb, pci) — Purpose: decode the BCH and check its CRC. Inputs: the soft 
% bits, the polar decoder's list length L (8 here), Lmax, and the PCI. Outputs: 
% the CRC flag, the 24 MIB bits (trblk), the four low SFN bits, the half-frame 
% bit, and the top bit of k_SSB (msbidxoffset); ~ skips the first output.
% Why it matters
% With the PCI known, the PBCH DM-RS has eight versions (ibar_SSB = 0 to 7 
% when Lmax = 8). The one that matches gives the low three bits of the SSB 
% index, and with eight or fewer blocks that names the beam that found the 
% phone. The same DM-RS symbols give a one-tap channel estimate, so the PBCH 
% can be equalized, descrambled, and decoded, and the CRC says whether the 
% MIB came through.
% What to look for
% • In the results table, compare FoundV with TrueV, and read the CRC flag, 
% the MIB match, and the half-frame bit.
% 
% • The aside table shows the four low SFN bits that came back from the decode, 
% read in two ways. It is read, not checked.
% Common mistakes
% Do not use ibar_SSB = ssbIndex when Lmax is 4. Then ibar_SSB = i_SSB + 4 × 
% n_hf (TS 38.211 clause 7.4.1.4.1): two SSB-index bits plus the half-frame 
% bit.
% 
% Do not skip the DM-RS step.
% Try it (personal exploration)
% Below the decode, a given Try line decodes the same PBCH again with the wrong 
% DM-RS version, tryV = mod(vHat + 1, 8). Predict its CRC flag (0 = pass, 1 
% = fail) and type it into myPrediction before you run this section. The Try 
% decode is separate from the real one, so it does not stop the run.

% Try it: type your prediction here (0 or 1) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — Which beam found me
fprintf("B4 — Which beam found me: DM-RS index and MIB\n");   % banner title only

% Step 3: eight PBCH DM-RS hypotheses give the 3 low bits of the SSB index.
% Each pass correlates one DM-RS version with the received DM-RS REs.
rxDMRS = rxSSB(nrPBCHDMRSIndices(pciHat));
dScore = zeros(1,8);
for ib = 0:7
    dScore(ib+1) = abs(sum(conj(nrPBCHDMRS(pciHat, ib)) .* rxDMRS));
end
[~, ibBest] = max(dScore);
vHat = ibBest - 1;                            % -1: version ib is stored at position ib+1
okDMRSIndex = vHat == v;
assert(okDMRSIndex, ...
    'The DM-RS search did not find the SSB index bits. Look first at pciHat from B2: the DM-RS depends on the PCI.');

% Step 4: one-tap channel from the DM-RS, then PBCH and BCH decode.
refD = nrPBCHDMRS(pciHat, vHat);
H    = mean(rxDMRS ./ refD);                  % one complex gain for the whole block
nVar = mean(abs(rxDMRS - H*refD).^2);         % noise variance left on the DM-RS
pbchRx = rxSSB(nrPBCHIndices(pciHat)) / H;
soft   = nrPBCHDecode(pbchRx, pciHat, vHat, nVar);
[~, errFlag, trblk, lsbofsfn, hrfHat, msbidxoffset] = nrBCHDecode(soft, 8, lssb, pciHat);   % 8 = polar list length

okCRC = errFlag == 0;
assert(okCRC, ...
    'The BCH CRC failed. Look first at vHat and pciHat: the PBCH must be decoded with the found DM-RS version and PCI.');
okMIB = isequal(double(trblk(:)), mib);
assert(okMIB, ...
    'The decoded MIB bits differ from the sent ones. Common mistake: comparing a row with a column; both are columns here.');
okHalfFrame = double(hrfHat) == hrf;
assert(okHalfFrame, ...
    'The half-frame bit does not match. Look first at hrf in B1 and the hrfHat output of nrBCHDecode.');

% The Try decode: the same PBCH with the wrong DM-RS version.
tryV = mod(vHat + 1, 8);                      % Try: the wrong DM-RS version (any value other than vHat)
softTry = nrPBCHDecode(pbchRx, pciHat, tryV, nVar);
[~, errFlagTry] = nrBCHDecode(softTry, 8, lssb, pciHat);      % 8 = polar list length

% The search and the decode in one row.
b4Results = table(v, vHat, double(errFlag), okMIB, hrf, double(hrfHat), double(msbidxoffset(1)), ...
    VariableNames = {'TrueV', 'FoundV', 'CRCFlag', 'MIBMatches', 'TrueHRF', 'FoundHRF', 'kSSB_MSB'});
b4Results

% Aside: two readings of the four low SFN bits that came back. Read, not
% asserted.
sfnBits = double(lsbofsfn(:).');
b4SFNAside = table(sfn, string(listText(bitget(sfn,4:-1:1))), string(listText(sfnBits)), ...
    sum(sfnBits .* 2.^(numel(sfnBits)-1:-1:0)), mod(sfn,16), ...   % the bits read most significant first; mod 16 keeps the 4 low bits
    VariableNames = {'SFN', 'SpecOrderPrediction', 'DecodedBits', 'DecodedAsNumber', 'SFNmod16'});
b4SFNAside

% Put your Try-it prediction beside the Try decode's CRC flag.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, tryV, double(errFlagTry), predictionNote, ...
    VariableNames = {'MyPrediction', 'TryV', 'TryCRCFlag', 'Note'});
b4Prediction
%% B4 — After the run
% The DM-RS search returns the true v, the three low bits of the SSB index: 
% the beam that found the phone. With that version and one channel tap, the 
% PBCH decodes, the CRC flag is 0, the 24 MIB bits match what was sent, and 
% the half-frame bit matches too. Compare TryCRCFlag with your prediction, 
% and say why the DM-RS step must come before the decode.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["DM-RS search finds v (SSB index mod 8)"; ...
     "BCH CRC passes (errFlag = 0)"; ...
     "Decoded MIB = sent MIB (24 bits)"; ...
     "Decoded half-frame bit = hrf"], ...
    [string(v); "0"; "24 of 24 bits equal"; string(hrf)], ...
    [string(vHat); string(double(errFlag)); string(nnz(double(trblk(:)) == mib)) + " of 24 bits equal"; ...
     string(double(hrfHat))], ...
    [okDMRSIndex; okCRC; okMIB; okHalfFrame], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Only pci (for B5) and listText are needed after this beat.
clear b4Results b4SFNAside b4Checks b4Prediction predictionNote ...
      okDMRSIndex okCRC okMIB okHalfFrame ...
      rxDMRS dScore ib ibBest vHat refD H nVar pbchRx soft ...
      errFlag trblk lsbofsfn hrfHat msbidxoffset tryV softTry errFlagTry sfnBits ...
      rxSSB pciHat v lssb hrf sfn mib myPrediction
%% B5 — The burst: Cases and the 20 ms count
% New words
% • SS burst: the set of candidate blocks a cell sends, all inside one 5 ms 
% half frame, repeated every Period (5, 10, 20, ... ms).
% 
% • Case A to Case G: the block patterns in TS 38.213 clause 4.1, picked by 
% spacing and band. Each gives the first OFDM symbol of every candidate block 
% and Lmax.
% 
% • TransmittedBlocks: which candidate blocks the cell actually sends (1) or 
% skips (0).
% 
% Beat-only commands (B5)
% • struct('field', {values...}) — Purpose: a list of records, one per value, 
% each with the same fields. Inputs: field names and a cell array of values 
% per field. Outputs: a structure array; cases(n).mu reads one field.
% 
% • cfg = nrDLCarrierConfig(Name = value, ...) and wave = nrWaveformGenerator(cfg) 
% — Purpose: describe a whole downlink carrier and build it as a waveform (album 
% track 02, B5). cfg.SSBurst holds the burst: BlockPattern, TransmittedBlocks, 
% and Period (ms); cfg.PDSCH{1} and cfg.PDCCH{1} are the data and control channels. 
% Inputs: the settings. Outputs: the configuration, then the samples.
% Why it matters
% A cell does not send one SSB; it sends a burst of candidate blocks in one 
% 5 ms half frame, and repeats it every Period. Cases A to G give where each 
% block starts and how many there are: up to 8 in FR1 and 64 in FR2. Each block 
% has an index, and the network can aim a beam with each one. A phone that 
% knows nothing may assume the burst returns every 20 ms.
% 
% Case A at or below 3 GHz has Lmax = 4, with first symbols 2, 8, 16, and 22; 
% with Period = 20 that pattern appears once in 20 ms.
% What to look for
% • In the cases table, read Lmax for each case and compare LastSymbol with 
% SymbolsPerHalfFrame.
% 
% • In the generator table, compare the expected SSB symbols with the measured 
% ones: are there any extra?
% Common mistakes
% Do not expect the burst every 5 ms regardless of Period.
% 
% Do not leave the default PDSCH and PDCCH on and then wonder why extra symbols 
% are occupied.
% Try it (personal exploration)
% Set cfg.SSBurst.Period = 5 in the generator block below and predict how 
% many of the waveform's OFDM symbols carry an SSB in its 20 ms. Type that number 
% into myPrediction before you run this section; the one-row table at the end 
% compares it with the measured count. The expected list is worked out from 
% TransmittedBlocks, Period, and NumSubframes, so the check holds for the new 
% value too. You may also try TransmittedBlocks = [1 0 0 0].

% Try it: type your prediction here (a number of OFDM symbols) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B5 — The burst
fprintf("B5 — The burst: Cases and the 20 ms count\n");   % banner title only

% Licensed-spectrum candidate first symbols in one half frame (TS 38.213
% clause 4.1): each block starts at base + step × n, for each n listed.
% mu sets the spacing, 15 × 2^mu kHz.
cases = struct( ...
 'name', {'A <=3GHz','A >3GHz','B <=3GHz','B >3GHz','C <=3GHz paired','C >3GHz paired','D','E','F','G'}, ...   % case and band
 'mu',   {0,0,1,1,1,1,3,4,5,6}, ...                                             % numerology: 15, 30, 120, 240, 480, 960 kHz
 'base', {[2 8],[2 8],[4 8 16 20],[4 8 16 20],[2 8],[2 8],[4 8 16 20],[8 12 16 20 32 36 40 44],[2 9],[2 9]}, ...   % first symbols for n = 0
 'step', {14,14,28,28,14,14,28,56,14,14}, ...                                   % symbols between repeats of the base pattern
 'n',    {0:1,0:3,0,0:1,0:1,0:3,[0:3 5:8 10:13 15:18],[0:3 5:8],0:31,0:31});    % repeat numbers n

% Reserve one entry per case for each value and flag.
nCases     = numel(cases);
caseLmax   = zeros(nCases,1);   % candidate blocks per half frame
caseLast   = zeros(nCases,1);   % last symbol of the last block (0-based)
caseHalf   = zeros(nCases,1);   % OFDM symbols in one 5 ms half frame
caseStarts = zeros(nCases,1);   % different first symbols among the candidates
okLmax     = false(nCases,1);   % Lmax is 4, 8, or 64
okInside   = false(nCases,1);   % every block ends inside the half frame
okDistinct = false(nCases,1);   % no two candidate blocks start on the same symbol

% For each case: list every candidate first symbol, then test the three
% rules before moving to the next case.
for n = 1:nCases
    c = cases(n);
    first = reshape(c.base(:) + c.step*c.n, 1, []);           % every candidate first symbol, one row
    caseLmax(n) = numel(first);
    caseHalf(n) = 14 * 2^c.mu * 5;                            % 14 symbols per slot, 2^mu slots per ms, 5 ms (normal CP)
    caseLast(n) = max(first) + 3;                             % a block is 4 symbols long

    okLmax(n) = ismember(caseLmax(n), [4 8 64]);              % the three allowed Lmax values
    assert(okLmax(n), ...
        'Lmax must be 4, 8, or 64. Look first at this case''s n list: it sets how many times the base pattern repeats.');
    okInside(n) = caseLast(n) < caseHalf(n);
    assert(okInside(n), ...
        'A block ends past the half frame. Look first at this case''s mu: the half frame holds 14 * 2^mu * 5 symbols.');
    caseStarts(n) = numel(unique(first));
    okDistinct(n) = caseStarts(n) == caseLmax(n);
    assert(okDistinct(n), ...
        'Two candidate blocks collide. Look first at this case''s base and step values.');
end

% The cases in one table, one row per case.
b5Cases = table(string({cases.name}).', 15*2.^[cases.mu].', caseLmax, caseLast, caseHalf, ...
    VariableNames = {'Case', 'SCS_kHz', 'Lmax', 'LastSymbol', 'SymbolsPerHalfFrame'});
b5Cases

% The toolbox's burst: Case A (Lmax = 4), one 20 ms waveform, with the data
% and control channels off so only the SS burst is on air.
cfg = nrDLCarrierConfig( ...
    FrequencyRange   = 'FR1', ...   % frequency range 1
    ChannelBandwidth = 10, ...      % channel bandwidth in MHz: 52 RB at 15 kHz
    NumSubframes     = 20, ...      % waveform length in 1 ms subframes: 20 ms
    WindowingPercent = 0, ...       % no windowing, so symbol energies do not spill
    NCellID          = pci);        % the B1 cell
cfg.SSBurst.BlockPattern      = 'Case A';   % 15 kHz pattern
cfg.SSBurst.TransmittedBlocks = [1 1 1 1];  % 4 blocks, all sent: Lmax = 4 (carrier at or below 3 GHz)
cfg.SSBurst.Period            = 20;         % burst period in ms (Try: 5)
cfg.PDSCH{1}.Enable = false;                % no data channel
cfg.PDCCH{1}.Enable = false;                % no control channel
wave = nrWaveformGenerator(cfg);

% Demodulate and find the symbols with energy. The default CSI-RS is off,
% and a CORESET alone carries no signal without a PDCCH, so only the SSB
% symbols should light up.
car  = nrCarrierConfig( ...
    SubcarrierSpacing = 15, ...      % kHz, as in the generator's default carrier
    NSizeGrid         = 52, ...      % RBs, as in the generator's default carrier
    NCellID           = pci);        % the B1 cell
grid = nrOFDMDemodulate(car, wave, CyclicPrefixFraction = 1);   % 1 = FFT window at the end of the prefix
symE = sum(abs(grid).^2, 1);                                  % energy in each OFDM symbol
active = find(symE > 1e-6*max(symE)) - 1;                     % 1e-6: far below an SSB symbol; -1 for 0-based symbol numbers

% The expected list, worked out from TransmittedBlocks, Period, and
% NumSubframes: a burst starts at 0, Period, 2 x Period, ... ms while that
% start is inside the waveform, each burst repeats the sent Case A blocks
% (14 symbols per ms), and any symbol past the waveform's end is dropped.
firstA = [2 8 16 22];                         % Case A at or below 3 GHz: first symbols for n = 0, 1
tb     = cfg.SSBurst.TransmittedBlocks;
per    = cfg.SSBurst.Period(1);               % burst period in ms
nRep   = ceil(cfg.NumSubframes/per);          % bursts that start inside the waveform (ceil: a last, partial period still gets its burst)
nSym   = 14*cfg.NumSubframes;                 % OFDM symbols in the waveform: 14 per ms at 15 kHz
expected = [];
for r = 0:nRep-1
    for b = find(tb)
        expected = [expected, firstA(b) + (0:3) + r*per*14];   %#ok<AGROW> 4 symbols per block; 14 symbols per ms at 15 kHz
    end
end
expected = expected(expected < nSym);         % drop any block symbol past the waveform's end (0-based numbers)

okBurstSymbols = isequal(sort(active), sort(expected));
assert(okBurstSymbols, ...
    'The SSB symbols do not match TransmittedBlocks, Period, and NumSubframes. Look first at ExpectedSymbols against MeasuredSymbols: missing or extra bursts point to Period and NumSubframes; extra symbols inside a burst point to PDSCH and PDCCH, which must both be disabled.');

% The generator's burst in one row.
b5Generator = table(string(listText(sort(expected))), string(listText(sort(active))), numel(active), size(grid,2), ...
    VariableNames = {'ExpectedSymbols', 'MeasuredSymbols', 'SSBSymbols', 'TotalSymbols'});
b5Generator

% Put your Try-it prediction beside the measured count.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b5Prediction = table(myPrediction, per, numel(active), predictionNote, ...
    VariableNames = {'MyPrediction', 'Period_ms', 'SSBSymbols', 'Note'});
b5Prediction
%% B5 — After the run
% Every case in the table has Lmax 4, 8, or 64, and every last block ends inside 
% its half frame, with symbols to spare. In the generator table the measured 
% list equals the expected one and nothing else lights up: with Period = 20, 
% the four Case A blocks sit in the first 2 ms of the 20 ms waveform, and the 
% rest is silent. Compare SSBSymbols with your prediction.
%% B5 — Assertion checks

% One row per assert in B5. The first three run once per case; Pass is all
% of them.
b5Checks = table( ...
    ["Lmax is 4, 8, or 64 (every case)"; ...
     "Last block ends inside the half frame (every case)"; ...
     "No two candidate blocks collide (every case)"; ...
     "Generator SSB symbols = expected list"], ...
    ["4, 8, or 64"; ...
     "< " + listText(caseHalf); ...
     listText(caseLmax) + " different starts"; ...
     string(listText(sort(expected)))], ...
    [listText(caseLmax); ...
     listText(caseLast); ...
     listText(caseStarts) + " different starts"; ...
     string(listText(sort(active)))], ...
    [all(okLmax); all(okInside); all(okDistinct); okBurstSymbols], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b5Checks
%% B5 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Only listText is needed after this beat (for the Build it checks).
clear b5Cases b5Generator b5Checks b5Prediction predictionNote ...
      okLmax okInside okDistinct okBurstSymbols ...
      cases nCases caseLmax caseLast caseHalf caseStarts n c first ...
      cfg wave car grid symE active firstA tb per nRep nSym expected r b myPrediction pci
%% Build it — Split a cell ID, place its sync signals, and find its PSS twin
% Competency: given a PCI, work out N_ID(1) and N_ID(2), place the cell's PSS 
% and SSS on an empty SSB tile, and find another cell that sends the same PSS 
% but a different SSS.
% Problem
% You are given myPCI = 711. Find its N_ID(2) by matching its PSS against 
% the three PSS sequences, then its N_ID(1). Predict how many REs the PSS and 
% SSS will fill, then make an empty 240 × 4 tile, write the cell's PSS and SSS 
% into their positions, and count the REs you filled. Find the largest PCI 
% below myPCI that sends the same PSS, and show that its PSS is the same and 
% its SSS is not.
% Allowed commands
% mod and floor; arithmetic; zeros; nrPSS, nrSSS, nrPSSIndices, and nrSSSIndices; 
% writing into positions x(ind) = v; nnz; isequal and ~. The for loop in Stage 
% 2, the tables, and the figure in the check sections and Stage 5 are given. 
% These are in Key code terms to remember.
% these are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code line, then run this section.
% Pass: the check below prints Stage 1 OK.

% myPCI = 711;   % physical cell ID: given for this exercise; no cell above uses it, so every answer is new
%% Stage 1 check (given)
if ~exist('myPCI','var')
    disp('Stage 1 not done: delete the % in front of the code line above, then run that section.')
else
    % The given value must still be in place before the later stages use it.
    okStage1 = myPCI == 711;   % the value Stage 1 gives
    assert(okStage1, ...
        'Stage 1 value changed. Look first at the line you uncommented: it should set myPCI = 711.')
    stage1Checks = table("myPCI as given", "711", string(myPCI), okStage1, ...   % expected: the given 711
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — find N_ID(2) by its PSS, then N_ID(1)
% The loop is given: it tries the three PSS sequences, h = 0, 1, and 2. Fill 
% the blanks so that myNID2 is set to the h whose PSS equals your cell's PSS. 
% Then fill N_ID(1) from the PCI and the N_ID(2) you found.
% Pass: Stage 2 OK.

% for h = 0:2
%     if isequal(nrPSS(___), nrPSS(___))
%         myNID2 = ___;
%     end
% end
% myNID1 = ___;
%% Stage 2 check (given; the check uses mod and floor, a different route from yours)
if ~exist('myNID1','var') || ~exist('myNID2','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: the remainder and the rounded-down quotient.
    oracleNID2 = mod(myPCI, 3);
    oracleNID1 = floor(myPCI/3);

    % Three tests: N_ID(2), N_ID(1), and the two parts rebuild the PCI.
    okStage2 = [myNID2 == oracleNID2; ...
                myNID1 == oracleNID1; ...
                3*myNID1 + myNID2 == myPCI];
    assert(okStage2(1), ...
        'myNID2 is not the PSS that matches. Look first at the two nrPSS calls: one for h, one for your cell.')
    assert(okStage2(2), ...
        'myNID1 is off. Common mistake: forgetting to take N_ID(2) away before dividing; N_ID(1) is a whole number from 0 to 335.')
    assert(okStage2(3), ...
        'The two parts do not rebuild the PCI. Look first at myNID1.')
    stage2Checks = table( ...
        ["N_ID(2) = PCI mod 3"; "N_ID(1) = floor(PCI / 3)"; "3 × N_ID(1) + N_ID(2) = PCI"], ...
        [string(oracleNID2); string(oracleNID1); string(myPCI)], ...
        [string(myNID2); string(myNID1); string(3*myNID1 + myNID2)], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: the filled REs
% Before you build the tile, type your prediction: how many REs of the 240 
% × 4 tile will hold a value once the PSS and the SSS are written in? Run this 
% section and the check under it before you start Stage 3b: the check does 
% not take a prediction once Stage 3b's names exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with the toolbox's index lists and does not print their count)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif exist('mySSB','var') || exist('myFilled','var')
    disp('Stage 3a refused: Stage 3b names already exist, so this is no longer a prediction. Run "clear mySSB myFilled", then predict again.')
else
    okPrediction3 = myPrediction == numel(nrPSSIndices) + numel(nrSSSIndices);   % the positions the toolbox fills
    stage3aCheck = table("Prediction = PSS positions + SSS positions", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at how many entries each sync sequence has (New words, B1). Change myPrediction and run again.')
    end
end
%% Stage 3b — place the PSS and SSS on a tile
% Fill the blanks: an empty 240 × 4 tile; the cell's PSS written into its 
% positions; the cell's SSS written into its positions; the count of REs that 
% are not zero.
% Pass: your locked prediction and your count appear side by side, and Stage 
% 3 OK.

% mySSB = ___;
% mySSB(___) = ___;
% mySSB(___) = ___;
% myFilled = ___;
%% Stage 3b check (given; the check reads the pieces back from their positions, a different route from yours)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('mySSB','var') || ~exist('myFilled','var')
    disp('Stage 3b not done: fill the blanks, uncomment, and run.')
else
    % Your locked prediction beside your count, in one row.
    stage3Prediction = table(myLockedPrediction, myFilled, ...
        VariableNames = {'MyPrediction', 'MyFilled'});
    stage3Prediction

    % Different route: read the values back from the PSS and SSS positions
    % and compare them with this cell's sequences; count the pieces' lengths.
    oracleFilled = numel(nrPSS(myPCI)) + numel(nrSSS(myPCI));
    nPSSok = 0;  nSSSok = 0;
    if isequal(size(mySSB), [240 4])                          % read back only from a tile of the right size
        nPSSok = nnz(mySSB(nrPSSIndices) == nrPSS(myPCI));  % PSS entries in the right place
        nSSSok = nnz(mySSB(nrSSSIndices) == nrSSS(myPCI));  % SSS entries in the right place
    end

    % Four tests: the tile's size, the PSS and the SSS in their places, and
    % the count.
    okStage3 = [isequal(size(mySSB), [240 4]); ...
                nPSSok == 127; ...                            % 127 entries per sync sequence
                nSSSok == 127; ...
                myFilled == oracleFilled];
    assert(okStage3(1), ...
        'The tile is not 240 × 4. Common mistake: rows are subcarriers (240) and columns are OFDM symbols (4).')
    assert(okStage3(2), ...
        'The PSS positions do not hold this cell''s PSS. Look first at what you passed to nrPSS: it takes the PCI.')
    assert(okStage3(3), ...
        'The SSS positions do not hold this cell''s SSS. Look first at what you passed to nrSSS: it takes the PCI.')
    assert(okStage3(4), ...
        'The count of filled REs is off. Look first at what you passed to nnz: it should be the whole tile.')
    stage3Checks = table( ...
        ["Tile is 240 × 4"; "PSS positions hold nrPSS(myPCI)"; "SSS positions hold nrSSS(myPCI)"; ...
         "Filled REs = PSS length + SSS length"], ...
        [listText([240 4]); "127 of 127 equal"; "127 of 127 equal"; string(oracleFilled)], ...
        [listText(size(mySSB)); string(nPSSok) + " of 127 equal"; string(nSSSok) + " of 127 equal"; string(myFilled)], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — the PSS twin
% Fill the blanks: myTwin, the largest PCI below myPCI that sends the same 
% PSS; mySamePSS, true when the twin's PSS equals your cell's; and myDiffSSS, 
% true when the twin's SSS differs from your cell's.
% Pass: Stage 4 OK.

% myTwin = ___;
% mySamePSS = ___;
% myDiffSSS = ___;
%% Stage 4 check (given; the check walks down from myPCI comparing PSS sequences, a different route from yours)
if ~exist('myTwin','var') || ~exist('mySamePSS','var') || ~exist('myDiffSSS','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: step down from myPCI - 1 and stop at the first cell
    % whose PSS sequence equals this cell's.
    oracleTwin = NaN;
    for p = myPCI-1:-1:0
        if isequal(nrPSS(p), nrPSS(myPCI))
            oracleTwin = p;
            break
        end
    end
    oracleSamePSS = isequal(nrPSS(oracleTwin), nrPSS(myPCI));
    oracleDiffSSS = ~isequal(nrSSS(oracleTwin), nrSSS(myPCI));

    % Three tests: the twin, and your two flags against the check's own tests.
    okStage4 = [myTwin == oracleTwin; ...
                isequal(mySamePSS, oracleSamePSS); ...
                isequal(myDiffSSS, oracleDiffSSS)];
    assert(okStage4(1), ...
        'myTwin is not the largest PCI below myPCI with the same PSS. Common mistake: a step of 1 changes N_ID(2); look first at how far apart cells that share a PSS are.')
    assert(okStage4(2), ...
        'mySamePSS does not agree with the check''s own PSS test. Look first at which two cells you compared.')
    assert(okStage4(3), ...
        'myDiffSSS does not agree with the check''s own SSS test. Look first at the ~, and at which two cells you compared.')
    stage4Checks = table( ...
        ["Twin = largest PCI below myPCI with the same PSS"; "Twin's PSS = my PSS"; "Twin's SSS differs from my SSS"], ...
        [string(oracleTwin) + " (check's walk down)"; string(oracleSamePSS) + " (check's own nrPSS test)"; ...
         string(oracleDiffSSS) + " (check's own nrSSS test)"], ...
        [string(myTwin); string(mySamePSS); string(myDiffSSS)], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myDiffSSS','var') || ~exist('oracleFilled','var') || ~exist('myNID1','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % N_ID(1) by a route you did not use: score your tile's SSS against the
    % 336 SSS of the cells that share your N_ID(2), as B2's Step 2 does.
    s5Score = zeros(1,336);
    for g = 0:335
        s5Score(g+1) = abs(sum(conj(nrSSS(3*g + myNID2)) .* mySSB(nrSSSIndices)));
    end
    [~, s5Best] = max(s5Score);
    nid1FromSSS = s5Best - 1;                                 % -1: group g is stored at position g+1

    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myNID1 == nid1FromSSS; ...
        nnz(mySSB(:,[2 4])) == 0; ...                         % 1-based columns 2 and 4 (symbols 1 and 3) stay empty: no PBCH yet
        myFilled == 2*127; ...                                % two 127-entry sequences
        mySamePSS && myDiffSSS];

    % One row per result: the rule's value, your value, and the computed flag.
    buildChecks = table( ...
        ["N_ID(1) = best SSS group on your tile (B2's Step 2)"; "Symbols 1 and 3 empty (no PBCH placed)"; ...
         "Filled REs = 2 × 127 (repeat of Stage 3)"; "Twin: same PSS, different SSS (repeat of Stage 4)"], ...
        [string(nid1FromSSS); "0 REs filled"; string(2*127); "true true"], ...
        [string(myNID1); string(nnz(mySSB(:,[2 4]))) + " REs filled"; string(myFilled); listText([mySamePSS myDiffSSS])], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: your tile, with the filled REs in colour.
    myLabels = zeros(240,4);                                  % 0 = empty RE
    myLabels(nrPSSIndices) = 1;  myLabels(nrSSSIndices) = 2;  % 1 = PSS, 2 = SSS
    figure(Name = 'Track 03 Build it - my tile', Color = 'w');
    imagesc(0:3, 0:239, myLabels, [0 2]);                     % 0-based symbols across, subcarriers up; colour range 0 to 2
    axis xy;                                                  % subcarrier 0 at the bottom
    colormap([1 1 1; 0.85 0.2 0.2; 0.2 0.4 0.85]);            % white, red, blue: the B1 colours
    xlabel('SSB OFDM symbol');
    ylabel('subcarrier k');
    title(sprintf('PCI %d: N_{ID}^{(1)} = %d, N_{ID}^{(2)} = %d; twin %d', myPCI, myNID1, myNID2, myTwin));
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): 
% which two numbers make up your PCI, and which sync signal carries each? Why 
% does your twin send the same PSS, and what would a phone that stopped after 
% the PSS conclude about the two cells?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. Counting myPCI itself, 
% how many of the PCIs from 0 to myPCI send the same PSS as myPCI? The check 
% compares PSS sequences and does not print the count.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('myPCI','var')
    disp('Run Stage 1 first, then return here.')
else
    nSame = 0;
    for p = 0:myPCI
        nSame = nSame + isequal(nrPSS(p), nrPSS(myPCI));      % second route: compare the sequences
    end
    okInterp = myAnswer == nSame;
    interpHint = "";
    if ~okInterp
        interpHint = "cells that share a PSS share N_ID(2); how many groups N_ID(1) reach up to myPCI?";
    end
    interpCheck = table("PCIs 0 to myPCI sharing its PSS", okInterp, interpHint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    interpCheck
end
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks oracleNID2 oracleNID1 okStage2 stage2Checks h ...
      okPrediction3 stage3aCheck stage3Prediction oracleFilled nPSSok nSSSok okStage3 stage3Checks ...
      oracleTwin oracleSamePSS oracleDiffSSS okStage4 stage4Checks p ...
      s5Score g s5Best nid1FromSSS buildFlags buildChecks myLabels ...
      myAnswer nSame okInterp interpHint interpCheck
      oracleSamePSS oracleDiffSSS okStage4 stage4Checks twinCheck buildFlags buildChecks myLabels
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them. 
% Each exercise has a check: type your numbers into its myE variable and run 
% that section. The check works the values out by a second route (sequence 
% matching, the toolbox, or the rule from a different starting point), shows 
% Pass or Fail with a pointer for each entry, and never prints the value. Write 
% the reasons on the Your answer lines; the script does not grade them.
%% E1 — New values (B1, B3)
% Take the largest cell ID, PCI 1007. What are its N_ID(1) and N_ID(2)? Which 
% two other PCIs are in the same SSS group, and how many cells in all send 
% the same PSS as 1007? Type the five numbers into myE1 as [N_ID(1), N_ID(2), 
% the smaller other PCI, the larger other PCI, cells sharing the PSS]. Explain 
% each number from the PCI formula.
% 
% Your answer:
myE1 = NaN;   % [N_ID(1), N_ID(2), other PCI (smaller), other PCI (larger), cells sharing the PSS]
if any(isnan(myE1)) || numel(myE1) ~= 5
    disp('Type five numbers into myE1, then run this section again.')
else
    [e1n1, e1n2] = ndgrid(0:335, 0:2);                        % second route: search the pairs, not divide
    e1k   = find(3*e1n1(:) + e1n2(:) == 1007);
    e1Grp = setdiff(3*e1n1(e1k) + (0:2), 1007);               % the other members of its group
    e1PSS = 0;
    for p = 0:1007
        e1PSS = e1PSS + isequal(nrPSS(p), nrPSS(1007));
    end
    e1Ref = [e1n1(e1k), e1n2(e1k), sort(e1Grp), e1PSS];
    okE1  = myE1(:) == e1Ref(:);
    e1Hint = ["floor of the PCI over 3"; "the remainder"; "same N_ID(1), other N_ID(2)"; "same N_ID(1), other N_ID(2)"; ...
              "one per SSS group"];
    e1Hint(okE1) = "";
    e1Check = table(["N_ID(1)"; "N_ID(2)"; "Other PCI, smaller"; "Other PCI, larger"; "Cells sharing the PSS"], okE1, e1Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e1Check
end
%% E2 — Diagnosis (B2)
% A classmate's SSS search loops over all 1008 PCIs, nrSSS(0) to nrSSS(1007), 
% and keeps the best score, without using the N_ID(2) from the PSS step. How 
% many times more SSS candidates do they score than B2's search? Type that 
% number into myE2. Then: another classmate keeps B2's search but takes N_ID(2) 
% from the second-tallest PSS peak. Name the information each classmate threw 
% away, and say what kind of wrong answer each search can return that B2's 
% cannot.
% 
% Your answer:
myE2 = NaN;   % how many times more SSS candidates than B2
if isnan(myE2) || numel(myE2) ~= 1
    disp('Type one number into myE2, then run this section again.')
else
    e2Ref = numel(0:1007) / numel(unique(floor((0:1007)/3)));   % second route: count the groups
    okE2  = abs(myE2 - e2Ref) < 1e-9;
    e2Hint = "";
    if ~okE2
        e2Hint = "how many SSS candidates does B2 score, and how many PCIs are there?";
    end
    e2Check = table("Work ratio", okE2, e2Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e2Check
end
%% E3 — New values and explanation (B2, album track 02's FFT-size rule)
% B2's slot is 20 RBs at 15 kHz. Use the default FFT-size rule to work out 
% its N_FFT and sample rate, then the planted delay D = 333 samples in μs. 
% How far, in km, does a radio wave travel in that time (3e8 m/s)? Type the 
% four numbers into myE3 as [N_FFT, sample rate in Hz, delay in μs, distance 
% in km]. Explain why the timing a phone finds this way cannot, on its own, 
% tell it how far away the cell is.
% 
% Your answer:
myE3 = NaN;   % [N_FFT, sample rate (Hz), delay (μs), distance (km)]
if any(isnan(myE3)) || numel(myE3) ~= 4
    disp('Type four numbers into myE3, then run this section again.')
else
    e3Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 20));   % second route: the toolbox
    e3t    = 333/e3Info.SampleRate;                           % s
    e3Ref  = [e3Info.Nfft, e3Info.SampleRate, 1e6*e3t, 3e8*e3t/1e3];   % 1e6: s to μs; 1e3: m to km
    okE3   = abs(myE3(:) - e3Ref(:)) <= 0.02*abs(e3Ref(:));   % within 2 %
    e3Hint = ["the FFT-size rule with K = 240"; "N_FFT times the spacing"; "samples over the sample rate"; "speed times time"];
    e3Hint(okE3) = "";
    e3Check = table(["N_FFT"; "Sample rate (Hz)"; "Delay (μs)"; "Distance (km)"], okE3, e3Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e3Check
end
%% E4 — New values (B4, Common mistakes)
% A cell has Lmax = 4. Its block with SSB index 2 goes out in the second half 
% of the frame (half-frame bit 1). Which DM-RS version ibar_SSB does the phone 
% find? For a cell with Lmax = 64, which ibar_SSB goes with SSB index 45? Type 
% both into myE4 as [first, second], and say why the DM-RS alone cannot name 
% that second beam.
% 
% Your answer:
myE4 = NaN;   % [ibar_SSB for Lmax 4, ibar_SSB for Lmax 64]
if any(isnan(myE4)) || numel(myE4) ~= 2
    disp('Type two numbers into myE4, then run this section again.')
else
    e4Ref = [bitor(2, bitshift(1, 2)), bitand(45, 7)];        % second route: bit operations (half-frame bit as bit 2; three low bits)
    okE4  = myE4(:) == e4Ref(:);
    e4Hint = ["two index bits plus the half-frame bit"; "how many index bits does the DM-RS carry?"];
    e4Hint(okE4) = "";
    e4Check = table(["Lmax 4, index 2, half-frame 1"; "Lmax 64, index 45"], okE4, e4Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e4Check
end
%% E5 — New values (B5)
% Take Case B above 3 GHz from the B5 cases table (30 kHz) and send every candidate 
% block with Period = 5. How many OFDM symbols carry an SSB in a 20 ms waveform? 
% A 30 kHz slot is 0.5 ms and holds 14 symbols: about how many milliseconds 
% after its half frame starts does the last block of a burst end? Type both 
% into myE5 as [symbols, ms], and explain both numbers from the table's values 
% and the period.
% 
% Your answer:
myE5 = NaN;   % [SSB symbols in 20 ms, end of the last block (ms)]
if any(isnan(myE5)) || numel(myE5) ~= 2
    disp('Type two numbers into myE5, then run this section again.')
else
    e5First = reshape([4 8 16 20].' + 28*(0:1), 1, []);       % Case B > 3 GHz candidate first symbols
    e5Sym   = numel(e5First) * 4 * (20/5);                    % 4 symbols per block; 20 ms / 5 ms bursts
    e5End   = (max(e5First) + 4) * (0.5/14);                  % symbols elapsed at the end of the last block × ms per symbol
    e5Ref   = [e5Sym, e5End];
    okE5    = abs(myE5(:) - e5Ref(:)) <= 0.01*abs(e5Ref(:));  % within 1 %
    e5Hint  = ["blocks per burst × symbols per block × bursts"; "symbols up to the end of the last block, then ms"];
    e5Hint(okE5) = "";
    e5Check = table(["SSB symbols in 20 ms"; "Last block ends (ms)"], okE5, e5Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e5Check
end
%% E6 — Diagnosis (B5)
% A classmate sets Period = 10 for the B5 Case A burst (all four blocks sent) 
% in a 20 ms waveform and expects four bursts, one per 5 ms. How many bursts 
% are there, how many OFDM symbols carry an SSB, and on which symbol does the 
% second burst's first block start? A second classmate makes the waveform 15 
% ms long with Period = 10 and expects one and a half bursts: how many bursts 
% does it hold? Type the four numbers into myE6 as [bursts in 20 ms, SSB symbols, 
% start symbol, bursts in 15 ms]. What did each classmate confuse?
% 
% Your answer:
myE6 = NaN;   % [bursts in 20 ms, SSB symbols, second burst's first symbol, bursts in 15 ms]
if any(isnan(myE6)) || numel(myE6) ~= 4
    disp('Type four numbers into myE6, then run this section again.')
else
    e6Starts20 = 0:10:19;  e6Starts15 = 0:10:14;              % second route: list the burst start times (ms)
    e6Ref = [numel(e6Starts20), numel(e6Starts20)*4*4, 14*e6Starts20(2) + 2, numel(e6Starts15)];   % 4 blocks × 4 symbols; 14 symbols per ms; first block on symbol 2
    okE6  = myE6(:) == e6Ref(:);
    e6Hint = ["Period sets the gap between bursts"; "blocks × symbols per block × bursts"; ...
              "14 symbols per ms, plus the first block's symbol"; "does a burst that starts inside the waveform count?"];
    e6Hint(okE6) = "";
    e6Check = table(["Bursts in 20 ms"; "SSB symbols"; "Second burst's first symbol"; "Bursts in 15 ms"], okE6, e6Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e6Check
end
%% Exercise cleanup
clear myE1 e1n1 e1n2 e1k e1Grp e1PSS e1Ref okE1 e1Hint e1Check p myE2 e2Ref okE2 e2Hint e2Check ...
      myE3 e3Info e3t e3Ref okE3 e3Hint e3Check myE4 e4Ref okE4 e4Hint e4Check ...
      myE5 e5First e5Sym e5End e5Ref okE5 e5Hint e5Check myE6 e6Starts20 e6Starts15 e6Ref okE6 e6Hint e6Check
%% Recap — Find Me in the Noise (album track 03)
% A phone that knows nothing finds a cell in four steps: the PSS gives the 
% timing and N_ID(2), the SSS gives N_ID(1) and so the PCI, the PBCH DM-RS 
% gives the beam, and the BCH gives the MIB with a CRC.
% Key relationships
% The cell's name comes from its two sync signals:
% 
% $$N_{\mathrm{ID}}^{\mathrm{cell}} = 3N_{\mathrm{ID}}^{(1)} + N_{\mathrm{ID}}^{(2)},\qquad 
% 336\times 3 = 1008\ \text{cells}$$
% 
% One SS/PBCH block is 240 subcarriers by 4 symbols, holding the PSS and SSS 
% (127 each), the PBCH (432), and its DM-RS (144).
% What this means in practice
% • PSS: N_ID(2) and the timing, from the tallest of three correlation peaks.
% 
% • SSS: N_ID(1), searched over the 336 groups that match the PSS, and so the 
% PCI; cells that share a PSS are told apart only here.
% 
% • PBCH DM-RS: the low three bits of the SSB index, the beam that found you, 
% and a channel estimate for the decode.
% 
% • BCH: the MIB and the low SFN bits, with a CRC; the MIB points to CORESET 
% 0, where the phone looks next for SIB1. CRC and LLRs return in album track 
% 04 (Every Check Agrees).
% 
% • The burst: Cases A to G, Lmax 4, 8, or 64, all inside one 5 ms half frame, 
% repeated every Period.
% 
% • You found a PCI's two parts yourself, placed its PSS and SSS on a tile, 
% and found another cell that sends the same PSS.
% 
% • Next in the album: track04 (Every Check Agrees).
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
% • mod(a, b) and floor(x):
% 
% • zeros(r, c):
% 
% • x(ind) = v:
% 
% • nnz(x):
% 
% • isequal(a, b) and ~:
% 
% • nrPSS and nrSSS:
% 
% • nrPSSIndices and nrSSSIndices:
% What I missed, and where to reread it
% 
%% Review — retrieval
% Still keeping the Recap collapsed: from album track 02 (Copy the Tail, 
% track02/track02_copy_the_tail_demo), how many samples long is the normal 
% cyclic prefix of a 15 kHz, 52-RB carrier? Type the number into myAnswer and 
% run this section. Then, in one line, say why B2 here can demodulate with 
% CyclicPrefixFraction = 1 and still need no phase correction. The check asks 
% nrOFDMInfo and does not print its value.
% 
% Why:
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    reviewInfo = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52));   % second route: the toolbox
    okReview = myAnswer == reviewInfo.CyclicPrefixLengths(2);                          % symbol 1: a normal prefix
    reviewCheck = table("Normal CP samples, 15 kHz, 52 RB", okReview, ...
        VariableNames = {'Check', 'Pass'});
    reviewCheck
end
