%% track01_two_to_the_mu_demo
%% Two to the Mu (album track 01): 5G NR numerology, spacing, timing, and grid shape
% This demonstration explores how the 5G NR numerology index, μ (said "mu"), 
% changes the OFDM resource grid.
% 
% A resource element (RE) is one subcarrier during one OFDM symbol. As μ goes 
% up, the subcarrier spacing gets wider and the OFDM symbols get shorter. The 
% grid changes shape, but a fixed patch of time and bandwidth still holds the 
% same total number of resource elements.
%% Guiding question
% What happens to an OFDM resource grid when the spacing between subcarriers 
% doubles?
% 
% A scenario: an operator runs a 100 MHz carrier at 30 kHz in a mid band and 
% at 120 kHz in a millimetre-wave band. What does each spacing buy, and what 
% does it cost in slot length, prefix length, and samples per second?
% This demonstration
% 1. B1 — Sweep the numerology from μ = 0 to μ = 4, including the extended 
% cyclic-prefix case at 60 kHz, and read the carrier's slot and grid sizes back 
% from the toolbox.
% 
% 2. B2 — Measure timing: the useful-symbol duration, the cyclic-prefix duration, 
% and the slot duration.
% 
% 3. B3 — Compare equal time–bandwidth patches and see whether their RE count 
% changes with μ.
% 
% 4. B4 — Build and OFDM-modulate one 10 ms frame at 30 kHz spacing, and count 
% its samples.
% 
% 5. Build it — Build a carrier yourself, predict its FFT size, and read its 
% slots, grid size, and frame length.
% Key relationships
% The subcarrier spacing doubles each time μ goes up by one:
% 
% $$\Delta f = 15\ \mathrm{kHz}\cdot 2^{\mu}$$
% 
% The slot duration halves each time μ goes up by one:
% 
% $$T_{\mathrm{slot}} = \frac{1\ \mathrm{ms}}{2^{\mu}}$$
% 
% With normal cyclic prefix, each slot holds 14 OFDM symbols, so a higher μ 
% gives shorter slots and more slots in each 1 ms subframe.
% Key ideas to remember
% • One setting, μ, moves the spacing, the symbol length, and the slot length 
% together; you choose μ, and the toolbox works out the rest.
% 
% • The clock does not move: a subframe and a frame last the same time at every 
% μ. Only how finely that time is cut into slots changes.
% 
% • Wide spacing buys short slots and better tolerance of Doppler and phase 
% noise; narrow spacing buys long symbols and long prefixes for long echoes.
% 
% • A slot is counted in symbols, not in time: normal CP always gives the same 
% count, and only 60 kHz may switch to the extended prefix, which gives fewer.
% 
% • Compare prefixes and symbols by how long they last, not by how many samples 
% they take; sample counts follow the FFT size the toolbox picks.
% 
% • Numerology reshapes the grid but does not add room: a fixed patch of time 
% and bandwidth keeps the same number of REs.
% 
% • A frame's sample count follows from the sample rate and the frame length, 
% and every cyclic prefix is part of it.
%% Prerequisites
% • The resource grid, REs, RBs, and the 14-symbol slot (track 00 Fundamentals, track00_fundamentals/p00a_bits_and_grid_demo)
% 
% • One IFFT per OFDM symbol, the sample rate, and the cyclic prefix as a copied 
% tail (track 00 Fundamentals, track00_fundamentals/p00a_ofdm_and_cp_demo). Cyclic-prefix sample counts are taught 
% there, not here.
% 
% This demonstration works with durations rather than raw sample counts, except 
% in B4, where one whole frame is counted.
% Words used in this demo
% • Subcarrier: one narrow frequency channel, one row of the grid. Subcarrier 
% spacing (SCS, Δf): the distance in frequency between neighbouring subcarriers, 
% in kHz.
% 
% • OFDM symbol: one short block of time, one column of the grid. Useful symbol: 
% the part of the symbol that carries the data, without its prefix.
% 
% • Resource element (RE): one subcarrier during one OFDM symbol, one cell of 
% the grid. Resource block (RB): 12 neighbouring subcarriers. NSizeGrid: how many 
% RBs wide the carrier's grid is.
% 
% • Carrier: the whole band of subcarriers one cell uses, described in MATLAB 
% by a carrier configuration object.
% 
% • Cyclic prefix (CP): a short guard placed in front of each OFDM symbol (track 00). 
% B2 introduces its two length settings.
% 
% • FFT size (Nfft): how many points the IFFT uses for each symbol. Sample rate 
% (f_s): how many samples are sent each second.
% 
% • Numerology, slot, subframe, frame, waveform, SSB, BWP, PDSCH, and DM-RS 
% are defined in the beat where they first appear, under New words.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used only for figures or 
% only in B4 are listed at the start of B3 and B4.
% 
% Commands you write
% • f(Name = value, ...) — Purpose: give a function named inputs. Inputs: input 
% names and values. Outputs: what the function returns.
% 
% • s.Name — Purpose: read one property of an object or field of a structure. 
% Inputs: the object and the property name. Outputs: its value.
% 
% • [a, b] = size(x) — Purpose: read the size of an array, rows first. Inputs: 
% an array. Outputs: the number of rows a and columns b.
% 
% • carrier = nrCarrierConfig(Name = value, ...) — Purpose: describe one carrier. 
% Inputs: SubcarrierSpacing (kHz), CyclicPrefix, NSizeGrid (RBs), and others. 
% Outputs: a carrier object with SlotsPerSubframe, SlotsPerFrame, SymbolsPerSlot, 
% and NSlot.
% 
% • grid = nrResourceGrid(carrier) — Purpose: make an empty one-slot grid. Inputs: 
% a carrier. Outputs: a K × L array of zeros (subcarriers by symbols).
% 
% • info = nrOFDMInfo(carrier) — Purpose: report the OFDM timing. Inputs: a 
% carrier. Outputs: a structure with Nfft, SampleRate (Hz), SymbolLengths, and 
% CyclicPrefixLengths (samples in one 1 ms subframe).
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Lists, indexing, and ranges: [a b c], {'a','b'}, x(n), x(n) = v, a:b, x(:), x.', G(:, cols), c{n} — 
% Purpose: read or write entries, count a range, reshape to a column or row, 
% pick columns, read text from a cell. Inputs: an array and positions. Outputs: 
% the entries or the changed array.
% 
% • Arithmetic, compare, and combine: + - * / ^, == ~= < >, && & ~, .^ ./ — Purpose: 
% compute; compare values; and, entry-wise and, not; power and divide for every entry. Inputs: numbers 
% or arrays. Outputs: true/false or numbers, entry by entry.
% 
% • Control flow: for ... end, if ... else ... end — Purpose: repeat a block 
% for each value of a list; run one block or the other. Inputs: a list or a 
% true/false test. Outputs: whatever the blocks store.
% 
% • Built-in helpers: zeros, ones, false, numel, nnz, sum, all, max, abs, round, 
% mod, log2, nextpow2, find, strcmp, isequal, exist, isnan, NaN, [] — Purpose: 
% make filled arrays, count, add, test, round, and look things up. Inputs: numbers, 
% arrays, or names. Outputs: numbers or true/false (NaN means "no number yet").
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, compose, sprintf, and 
% f = @(v) ... — Purpose: write and join text, turn numbers into text, fill 
% a format, and make a one-line helper such as listText. Inputs: text, numbers, 
% a format. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), fprintf, disp, clear, close all, rng — Purpose: show columns side 
% by side, stop with a hint when a check fails, print a banner or note, remove 
% variables or figures, repeat random values. Inputs: columns, a test and message, 
% text, names, a seed. Outputs: a shown table or line; an error if a check fails.
% Requirements
% MATLAB with 5G Toolbox (written for R2024b). Read each table and figure against 
% the sentence that interprets it; if the two disagree, trust the table.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year), so the random PDSCH bits in B4 repeat on every run

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It stays in the workspace until the end of the file, because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");
%% B1 — Numerology sweep
% New words
% • Numerology (μ): a whole number that sets the spacing as 15 kHz × 2^μ.
% 
% • Slot: a run of OFDM symbols, 14 with normal cyclic prefix.
% 
% • Subframe and frame: 1 ms and 10 ms; these never change with μ.
% Why it matters
% NR numerology is built on powers of two above a 15 kHz reference. Raising 
% μ by one doubles the subcarrier spacing and doubles the number of slots in 
% the same 1 ms subframe. The 1 ms subframe clock, and so the 10 ms radio frame, 
% does not change.
% 
% $$\Delta f = 15\ \mathrm{kHz}\cdot2^{\mu}$$
% 
% A wider spacing gives shorter slots. That can cut delay and cope better with 
% Doppler shift and phase noise, especially at high carrier frequencies. A narrower 
% spacing gives a longer cyclic prefix in time, which copes with longer echoes. 
% That is the trade-off μ makes.
% 
% A resource block (RB) holds 12 subcarriers, so a grid NSizeGrid RBs wide 
% has 12 × NSizeGrid subcarrier rows.
% What to look for
% • In the sweep table, compare the SlotsPerSF column with the Mu column as 
% μ goes up by one, then do the same for SlotsPerFrame.
% 
% • Compare GridK with the RB counts in nrbList, and GridL with SymPerSlot.
% 
% • Find the one row whose SymPerSlot differs from the others, and read its 
% CP and SCS columns.
% Common mistakes
% Do not confuse SlotsPerFrame with SlotsPerSubframe. SlotsPerFrame counts slots 
% in a 10 ms radio frame; SlotsPerSubframe counts slots in one 1 ms subframe.
% 
% Do not assume extended cyclic prefix exists at every spacing. In NR it is 
% allowed only at 60 kHz.
% Try it (personal exploration)
% Use the slots-per-subframe relationship in Key relationships to predict how 
% many slots fit in one subframe at 30 kHz spacing. Type that number into myPrediction 
% in the first code line below before you run this section. After the sweep 
% table, a given one-row table shows your prediction beside the toolbox's answer.
% 
% Then, optionally, add a μ = 5 row: append 5 to muList, 'normal' to cpList, 
% and an RB count such as 66 to nrbList, predict its spacing and slots with the 
% same rules, and run. Every check in this section tests a relationship, so it 
% holds for the new row too. (μ = 5 and μ = 6 are later-release data numerologies 
% for the highest bands, FR2-2; μ = 4 stays SSB-only. μ = 5 needs a toolbox 
% release that supports it; if nrCarrierConfig refuses it, remove the row.)

% Try it: type your prediction here (a number of slots) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Numerology sweep
%
% Each row defines one NR numerology case. The sweep includes normal CP at
% mu = 0, 1, 2, 3, and 4, plus extended CP at mu = 2 (60 kHz).
fprintf("B1 — Numerology sweep\n");   % banner title only; every number below goes into a table

% Three parallel input lists: entry n of each list, read together, is sweep case n.
muList  = [0 1 2 2 3 4];                                               % numerology index per case: 0 to 4, with 2 twice so 60 kHz appears with both CP types
cpList  = {'normal','normal','normal','extended','normal','normal'};   % CP type per case: 'extended' only beside mu = 2, the one spacing where NR allows it
nrbList = [270 273 135 135 264 20];                                    % grid width in RBs per case: example maximum-bandwidth counts (TS 38.101-1/-2); 240 kHz uses the 20-RB SSB width

% Count the cases from the list itself, so adding a row (the optional mu = 5 Try) needs no other edit.
nCases = numel(muList);

% Mark the one extended-CP case. It is worked out from the lists, not typed
% as "row 4", so the symbol-count check still finds it if rows are added.
isExtendedCP = (muList(:) == 2) & strcmp(cpList(:), 'extended');   % mu = 2 (60 kHz) is the only spacing where extended CP is allowed

% Reserve one entry per case for each value the toolbox will report. The
% loop fills entry n; the vectors become the sweep-table columns afterwards.
scs_kHz        = zeros(nCases,1);   % subcarrier spacing read back from the carrier, kHz
symbolsPerSlot = zeros(nCases,1);   % OFDM symbols in one slot
slotsPerSF     = zeros(nCases,1);   % slots in one 1 ms subframe
slotsPerFrame  = zeros(nCases,1);   % slots in one 10 ms frame
gridK          = zeros(nCases,1);   % rows of the one-slot grid (subcarriers)
gridL          = zeros(nCases,1);   % columns of the one-slot grid (OFDM symbols)

% Reserve one true/false flag per assert and per case. Each assert below
% stores its test here first, so the check table after the loop reports the
% computed result instead of a typed "Pass".
okSlotsPerSF    = false(nCases,1);   % SlotsPerSubframe equals 2^mu
okSlotsPerFrame = false(nCases,1);   % SlotsPerFrame equals 10 * 2^mu
okGridK         = false(nCases,1);   % grid rows equal 12 * NSizeGrid
okGridL         = false(nCases,1);   % grid columns equal SymbolsPerSlot
okSymbols       = false(nCases,1);   % 14 symbols per slot, or 12 for the extended-CP case

% Build one carrier per case, read back what the toolbox derives from it,
% and test each relationship before moving to the next case.
for n = 1:nCases

    % Pull case n out of the three parallel lists so the lines below read
    % plainly. Curly braces read the text inside the cell, not a one-cell array.
    mu  = muList(n);
    cp  = cpList{n};
    nrb = nrbList(n);

    % Build the carrier from mu, so its spacing always follows the
    % numerology rule instead of being typed in separately.
    carrier = nrCarrierConfig( ...
        SubcarrierSpacing = 15*2^mu, ...   % 15 kHz reference times 2^mu: the numerology rule itself
        CyclicPrefix      = cp, ...        % this case's CP type, from cpList
        NSizeGrid         = nrb, ...       % this case's grid width in RBs, from nrbList
        NStartGrid        = 0);            % grid starts at common RB 0; the start does not change any count here

    % Read back the properties the toolbox computes from those inputs.
    % This is why the carrier object is used: we do not type these numbers.
    scs_kHz(n)        = carrier.SubcarrierSpacing;
    symbolsPerSlot(n) = carrier.SymbolsPerSlot;
    slotsPerSF(n)     = carrier.SlotsPerSubframe;
    slotsPerFrame(n)  = carrier.SlotsPerFrame;

    % Make the empty one-slot grid and record its size. size returns rows
    % first (K, subcarriers) and columns second (L, OFDM symbols).
    grid = nrResourceGrid(carrier);
    [gridK(n), gridL(n)] = size(grid);

    % Slots per subframe, checked against 2^mu worked out from mu alone, a
    % different route from the property read above.
    okSlotsPerSF(n) = slotsPerSF(n) == 2^mu;              % 2^mu slots per 1 ms
    assert(okSlotsPerSF(n), ...
        'SlotsPerSubframe does not equal 2^mu. Look first at muList and at the SubcarrierSpacing line: it should be 15*2^mu.');

    % A 10 ms frame is ten 1 ms subframes, so it holds 10 * 2^mu slots.
    okSlotsPerFrame(n) = slotsPerFrame(n) == 10*2^mu;     % 10 subframes per frame
    assert(okSlotsPerFrame(n), ...
        'SlotsPerFrame does not equal 10*2^mu. Look first at whether a frame was counted as one subframe: a frame is ten subframes.');

    % Every RB adds exactly 12 subcarrier rows to the grid.
    okGridK(n) = gridK(n) == 12*nrb;                      % 12 subcarriers per RB
    assert(okGridK(n), ...
        'Resource-grid height does not equal 12*NSizeGrid. Look first at nrbList: each RB is 12 subcarrier rows.');

    % The grid has one column per OFDM symbol of the slot.
    okGridL(n) = gridL(n) == symbolsPerSlot(n);
    assert(okGridL(n), ...
        'Resource-grid width does not equal SymbolsPerSlot. Look first at the [gridK(n), gridL(n)] = size(grid) line: rows come first, columns second.');

    % The symbol count depends on the CP type: the extended-CP case expects
    % 12 symbols per slot and every normal-CP case expects 14.
    if isExtendedCP(n)
        okSymbols(n) = symbolsPerSlot(n) == 12;   % extended CP: 12 symbols per slot
        assert(okSymbols(n), ...
            'Extended CP at 60 kHz should have 12 symbols per slot. Look first at cpList: the extended entry must sit in the same position as its 60 kHz mu.');
    else
        okSymbols(n) = symbolsPerSlot(n) == 14;   % normal CP: 14 symbols per slot
        assert(okSymbols(n), ...
            'Normal CP should have 14 symbols per slot. Look first at cpList: an extended entry may be paired with a mu other than 2, which NR does not allow.');
    end
end

% Gather the values read back from the toolbox into one table, one row
% per case. Short headings keep it readable in the Live Editor.
numerologySweep = table( ...
    muList(:), ...
    string(cpList(:)), ...
    scs_kHz, ...
    symbolsPerSlot, ...
    slotsPerSF, ...
    slotsPerFrame, ...
    gridK, ...
    gridL, ...
    VariableNames = { ...
        'Mu', 'CP', 'SCS_kHz', 'SymPerSlot', ...
        'SlotsPerSF', 'SlotsPerFrame', 'GridK', 'GridL'});

numerologySweep.Properties.VariableUnits{'SCS_kHz'} = 'kHz';   % unit label shown under the heading

% Writing the name alone shows the table. The display stays in the output
% even after the variable is cleared in the cleanup section.
numerologySweep

% Put your Try-it prediction beside the toolbox's 30 kHz value in a
% one-row table. The row is found by its spacing, so reordering the lists
% cannot point the comparison at the wrong case.
idx30 = find(scs_kHz == 30, 1);   % 30 kHz is the spacing the Try asks about; 1 = take the first match
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, slotsPerSF(idx30), predictionNote, ...
    VariableNames = {'MyPrediction', 'SlotsPerSF_30kHz', 'Note'});
b1Prediction
%%
% Read down the SlotsPerSF column: each step up in μ doubles it, which is the 
% 2^μ rule, and SlotsPerFrame is always ten times SlotsPerSF, because a 10 ms 
% frame holds ten 1 ms subframes. Find the 30 kHz row and compare its SlotsPerSF 
% with your prediction. GridK is 12 times each row's RB count, and GridL equals 
% SymPerSlot. Only the 60 kHz extended-CP row has 12 symbols per slot; every 
% normal-CP row has 14.
%% B1 — Assertion checks

% One row per assert in B1. Expected is the value the rule gives, worked
% out from muList, nrbList, or the CP type; Actual is what the toolbox
% returned. Each list runs over the cases in sweep order. Pass is computed
% from the stored flags. The asserts stop the run on a failure, so this
% table appears only when every check has passed, and shows the evidence.
isNormalCP = ~isExtendedCP;   % the cases that expect 14 symbols per slot

b1Checks = table( ...
    ["Slots per subframe = 2^mu"; ...
     "Slots per frame = 10 × 2^mu"; ...
     "Grid rows K = 12 × NSizeGrid"; ...
     "Grid columns L = SymbolsPerSlot"; ...
     "Symbols per slot, normal CP = 14"; ...
     "Symbols per slot, extended CP = 12"], ...
    [listText(2.^muList); ...
     listText(10*2.^muList); ...
     listText(12*nrbList); ...
     listText(symbolsPerSlot); ...
     listText(14*ones(nnz(isNormalCP),1)); ...
     listText(12*ones(nnz(isExtendedCP),1))], ...
    [listText(slotsPerSF); ...
     listText(slotsPerFrame); ...
     listText(gridK); ...
     listText(gridL); ...
     listText(symbolsPerSlot(isNormalCP)); ...
     listText(symbolsPerSlot(isExtendedCP))], ...
    [all(okSlotsPerSF); ...
     all(okSlotsPerFrame); ...
     all(okGridK); ...
     all(okGridL); ...
     all(okSymbols(isNormalCP)); ...
     all(okSymbols(isExtendedCP))], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep muList, cpList, and nrbList for B2, and listText for every later
% check table. Everything else was used only to build, test, or show B1.
clear numerologySweep b1Checks b1Prediction predictionNote ...
      isExtendedCP isNormalCP ...
      okSlotsPerSF okSlotsPerFrame okGridK okGridL okSymbols ...
      nCases scs_kHz symbolsPerSlot slotsPerSF slotsPerFrame gridK gridL ...
      n mu cp nrb carrier grid idx30 myPrediction
%% B2 — Timing: symbol, prefix, and slot
% New words
% • Useful symbol duration (T_u): how long the data part of one OFDM symbol 
% lasts, without its prefix.
% 
% • Ordinary prefix: a normal-length cyclic prefix. A half-subframe is 0.5 ms; 
% the first prefix in each half-subframe is slightly longer, so that every 0.5 
% ms boundary lines up at every μ. This demo reads the second, ordinary one; 
% track 00 has the sample counts.
% 
% • Extended CP: the longer prefix setting, allowed only at 60 kHz.
% Why it matters
% The useful OFDM symbol lasts one over the subcarrier spacing. As μ goes up, 
% the spacing widens and the useful symbol gets shorter:
% 
% $$T_u = \frac{1}{\Delta f}$$
% 
% The 1 ms subframe stays fixed:
% 
% $$T_{\mathrm{subframe}} = 1\ \mathrm{ms}$$
% 
% so a higher μ cuts that same 1 ms into more, shorter slots:
% 
% $$T_{\mathrm{slot}} = \frac{1\ \mathrm{ms}}{2^{\mu}}$$
% 
% The cyclic prefix is read here as a duration. The number of CP samples MATLAB 
% prints depends on the FFT size it picks, so it can change while the duration 
% stays the same; track00_fundamentals/p00a_ofdm_and_cp_demo shows why. An extended prefix 
% lasts one quarter of the useful symbol.
% What to look for
% • In the timing table, compare the Tu_us column with 1 / SCS for each row.
% 
% • Compare CP_2_us across the normal-CP rows as μ goes up, then compare the 
% two 60 kHz rows (normal and extended).
% 
% • Compare Slot_us with 1000 / 2^μ microseconds for each row.
% Common mistakes
% Do not compare the CP sample counts the toolbox prints with a fixed reference 
% count. Sample counts depend on the FFT size; durations are the fair comparison. 
% CP sample counts: see track00_fundamentals/p00a_ofdm_and_cp_demo.
% 
% Do not think a shorter slot holds fewer symbols. With normal CP every slot 
% holds 14 symbols; each symbol is simply shorter.
% Try it (personal exploration)
% The sweep has two 60 kHz rows: row 3 with normal CP and row 4 with extended 
% CP. Use T_u = 1/Δf and the rule "an extended prefix lasts one quarter of the 
% useful symbol" to predict the extended prefix's duration in microseconds for 
% row 4. Type it into myPrediction in the first code line below before you run 
% this section. After the timing table, a given one-row table shows your prediction 
% beside the result. Then compare it with row 3's ordinary prefix.
% Try it: type your prediction here (a number of microseconds) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Timing: useful symbol, cyclic prefix, and slot duration
%
% B1 defined the numerology, cyclic-prefix type, and grid size for each
% sweep case. Here, nrOFDMInfo converts each carrier configuration into
% waveform timing information: FFT size, sample rate, symbol lengths, and
% cyclic-prefix lengths.
fprintf("B2 — Timing: useful symbol, cyclic prefix, and slot duration\n");   % banner title only; the numbers go into tables

% One timing row per B1 case, counted from the list B1 kept.
nCases = numel(muList);

% Reserve one entry per case for each timing value. The loop fills entry n.
scs_kHz          = zeros(nCases,1);   % subcarrier spacing, kHz (needed for the 1 / SCS check)
nfft             = zeros(nCases,1);   % FFT size the toolbox picked
sampleRate_MHz   = zeros(nCases,1);   % sample rate, MHz
usefulSymbol_us  = zeros(nCases,1);   % useful symbol duration T_u, µs
cpSecond_us      = zeros(nCases,1);   % duration of the second (ordinary) prefix, µs
subframe_us      = zeros(nCases,1);   % all symbols and prefixes of one subframe added up, µs
slot_us          = zeros(nCases,1);   % one slot, µs
nSymbolLengths   = zeros(nCases,1);   % how many symbol lengths nrOFDMInfo lists for 1 ms
expectedSymbols  = zeros(nCases,1);   % SymbolsPerSlot × SlotsPerSubframe, the count it should list

% One true/false flag per assert and per case, filled by the loop and
% reported in the check table afterwards.
okUsefulSymbol = false(nCases,1);   % T_u equals 1 / SCS
okSymbolCount  = false(nCases,1);   % one symbol length per symbol of the subframe
okSubframe     = false(nCases,1);   % the subframe adds up to 1000 µs
okSlot         = false(nCases,1);   % a slot lasts 1000 / 2^mu µs

% Tolerances for comparing durations computed in floating point.
tolUseful_us = 1e-9;   % µs; far above rounding error, far below any real mistake (the smallest T_u here is about 4 µs)
tolTiming_us = 1e-6;   % µs; the subframe and slot sums add up many terms, so allow a little more rounding

% For each case, ask the toolbox for its OFDM timing, turn sample counts
% into durations, and test each timing rule before the next case.
for n = 1:nCases

    % Pull case n out of the parallel lists B1 kept.
    mu  = muList(n);
    cp  = cpList{n};
    nrb = nrbList(n);

    % Rebuild the same carrier as B1. NSizeGrid changes the FFT size the
    % toolbox picks, but not the durations, which is what this beat shows.
    carrier = nrCarrierConfig( ...
        SubcarrierSpacing = 15*2^mu, ...   % numerology rule, as in B1
        CyclicPrefix      = cp, ...        % this case's CP type
        NSizeGrid         = nrb);          % this case's width in RBs; it only affects Nfft and the sample rate

    % nrOFDMInfo reports the FFT size, sample rate, and the length in
    % samples of every symbol and prefix in one 1 ms subframe.
    info = nrOFDMInfo(carrier);

    % Record the spacing, FFT size, and sample rate for the table.
    scs_kHz(n)        = carrier.SubcarrierSpacing;
    nfft(n)           = info.Nfft;
    sampleRate_MHz(n) = info.SampleRate / 1e6;   % Hz to MHz

    % The useful part of a symbol is Nfft samples long. Dividing by the
    % sample rate gives seconds; times 1e6 gives microseconds.
    usefulSymbol_us(n) = info.Nfft / info.SampleRate * 1e6;   % × 1e6: seconds to µs

    % The first prefix in each 0.5 ms half-subframe is slightly longer (it keeps
    % the 0.5 ms boundaries aligned), so entry 2 is read as the ordinary prefix.
    cpSecond_us(n) = info.CyclicPrefixLengths(2) / info.SampleRate * 1e6;   % entry 2 = an ordinary prefix; × 1e6 = µs

    % SymbolLengths already includes each prefix, so adding all of them up
    % gives the length of the whole subframe.
    subframe_us(n) = sum(info.SymbolLengths) / info.SampleRate * 1e6;   % × 1e6: seconds to µs

    % The subframe is shared equally among its slots.
    slot_us(n) = subframe_us(n) / carrier.SlotsPerSubframe;

    % Count the symbol lengths listed, and the count the carrier says 1 ms holds.
    nSymbolLengths(n)  = numel(info.SymbolLengths);
    expectedSymbols(n) = carrier.SymbolsPerSlot * carrier.SlotsPerSubframe;

    % Check 1: the useful symbol lasts 1 / SCS. With SCS in kHz, 1e3 / SCS is in µs.
    okUsefulSymbol(n) = abs(usefulSymbol_us(n) - 1e3/scs_kHz(n)) < tolUseful_us;
    assert(okUsefulSymbol(n), ...
        'Useful-symbol duration does not equal 1 / subcarrier spacing. Look first at the usefulSymbol_us line: it should divide Nfft by the sample rate.');

    % Check 2: there is one symbol length for every symbol in every slot of 1 ms.
    okSymbolCount(n) = nSymbolLengths(n) == expectedSymbols(n);
    assert(okSymbolCount(n), ...
        'The number of symbol lengths does not match the 1 ms subframe. Look first at SymbolsPerSlot and SlotsPerSubframe for this row: extended CP has 12 symbols per slot.');

    % Check 3: whatever mu is, the subframe still lasts 1 ms = 1000 µs.
    okSubframe(n) = abs(subframe_us(n) - 1000) < tolTiming_us;   % 1000 µs = 1 ms
    assert(okSubframe(n), ...
        'The OFDM symbols and cyclic prefixes do not sum to 1 ms. Look first at the subframe_us line: it must add up SymbolLengths, which already include the prefixes.');

    % Check 4: the slot lasts 1000 / 2^mu µs, worked out from mu alone.
    okSlot(n) = abs(slot_us(n) - 1000/2^mu) < tolTiming_us;   % 1000 µs = 1 ms, shared by 2^mu slots
    assert(okSlot(n), ...
        'Slot duration does not equal 1 ms / 2^mu. Look first at the slot_us line: it divides the subframe by SlotsPerSubframe, not SlotsPerFrame.');
end

% Gather the timing values into one table, one row per case.
timingResults = table( ...
    muList(:), ...
    string(cpList(:)), ...
    nfft, ...
    sampleRate_MHz, ...
    usefulSymbol_us, ...
    cpSecond_us, ...
    slot_us, ...
    VariableNames = { ...
        'Mu', 'CP', 'Nfft', 'SampleRate_MHz', ...
        'Tu_us', 'CP_2_us', 'Slot_us'});

% A one-line description per column, stored with the table as its documentation.
timingResults.Properties.VariableDescriptions = { ...
    'Numerology index', ...
    'Cyclic-prefix type', ...
    'FFT size selected by nrOFDMInfo', ...
    'OFDM sample rate', ...
    'Useful symbol duration', ...
    'Second cyclic-prefix duration', ...
    'Slot duration'};

timingResults

% Put your Try-it prediction beside the 60 kHz extended-CP prefix in a
% one-row table. The row is found from the lists, not typed as "row 4".
idxExt = find(muList(:) == 2 & strcmp(cpList(:), 'extended'), 1);   % the 60 kHz extended-CP case the Try asks about; 1 = first match
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, cpSecond_us(idxExt), predictionNote, ...
    VariableNames = {'MyPrediction_us', 'ExtendedCP_60kHz_us', 'Note'});
b2Prediction
%%
% Tu_us halves each time μ goes up, because it is 1 / SCS. In the normal-CP 
% rows, CP_2_us shrinks in the same ratio, so the prefix stays the same fraction 
% of the symbol. Now compare the two 60 kHz rows: row 4's CP_2_us against one 
% quarter of its Tu_us, and against row 3's ordinary prefix. Slot_us is 1000 
% μs divided by SlotsPerSF from B1. The Nfft and SampleRate_MHz columns change 
% with the RB count, but none of these durations do.
%% B2 — Assertion checks

% One row per assert in B2. Expected comes from the rule (1 / SCS, the
% carrier's symbol count, 1 ms, 1 ms / 2^mu); Actual comes from nrOFDMInfo.
% Each list runs over the cases in sweep order, durations in µs. Pass is
% computed from the stored flags.
b2Checks = table( ...
    ["Useful symbol T_u = 1 / SCS (µs)"; ...
     "Symbol lengths in 1 ms = SymbolsPerSlot × SlotsPerSubframe"; ...
     "Subframe = 1000 µs"; ...
     "Slot = 1000 / 2^mu µs"], ...
    [listText(1e3 ./ scs_kHz); ...
     listText(expectedSymbols); ...
     listText(1000*ones(nCases,1)); ...
     listText(1000 ./ 2.^muList)], ...
    [listText(usefulSymbol_us); ...
     listText(nSymbolLengths); ...
     listText(subframe_us); ...
     listText(slot_us)], ...
    [all(okUsefulSymbol); ...
     all(okSymbolCount); ...
     all(okSubframe); ...
     all(okSlot)], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% B3 and B4 do not use the B1 lists, so they go too. listText stays for the
% later check tables.
clear timingResults b2Checks b2Prediction predictionNote ...
      muList cpList nrbList nCases ...
      scs_kHz nfft sampleRate_MHz usefulSymbol_us cpSecond_us subframe_us slot_us ...
      nSymbolLengths expectedSymbols ...
      okUsefulSymbol okSymbolCount okSubframe okSlot tolUseful_us tolTiming_us ...
      n mu cp nrb carrier info idxExt myPrediction
%% B3 — Same time–bandwidth box, new grid shape
% Key code terms used in this section
% • figure, tiledlayout, nexttile — Purpose: open a figure window, split it 
% into panels, and move to the next panel. Inputs: a name, colour, and size; 
% rows and columns. Outputs: the figure and its panels.
% 
% • imagesc, axis xy, colormap — Purpose: draw an array as coloured cells, put 
% row 0 at the bottom, and choose the colours. Inputs: the axis ranges, the 
% array, and a list of RGB colours. Outputs: the picture.
% 
% • xline, title, xlabel, ylabel — Purpose: draw vertical lines and label the 
% panel and its axes. Inputs: positions and a line style; text. Outputs: the 
% lines and labels.
% New words
% • Time–bandwidth box: a fixed patch of the grid, here 1 ms long and patchMHz 
% wide.
% 
% • K × L: a grid's size; K rows of subcarriers by L columns of OFDM symbols.
% 
% • SSB-only numerology: μ = 4 (240 kHz) is used in NR only for the SSB, not 
% for data.
% Why it matters
% This section holds time and bandwidth fixed: one 1 ms interval and one frequency 
% span, patchMHz. As μ goes up, each subcarrier gets twice as wide, so fewer 
% subcarriers fit into the same bandwidth. At the same time the OFDM symbols get 
% shorter, so more of them fit into the same 1 ms.
% 
% So the grid changes shape with numerology:
% 
% • a higher μ gives fewer subcarrier rows in the same bandwidth;
% 
% • a higher μ gives more OFDM-symbol columns in the same time.
% 
% With time and bandwidth fixed, the two changes cancel. Writing B for the bandwidth:
% 
% $$N_{\mathrm{RE}} =\left(\frac{B}{15\ \mathrm{kHz}\cdot 2^{\mu}}\right)\left(14\cdot2^{\mu}\right)=14\frac{B}{15\ \mathrm{kHz}}$$
% 
% The factor 2^μ cancels, so the RE count does not depend on numerology.
% What to look for
% • Each checkerboard in the figure covers the same 1 ms × patchMHz patch; compare 
% the number of rows and columns from panel to panel.
% 
% • In the table, compare the REs column across the rows, and compare GridK_1ms 
% and GridL_1ms as μ goes up. In B3 these count the whole 1 ms patch, not one 
% slot as in B1.
% 
% • Compare SlotsPerSF with the Mu column, and the white vertical lines in 
% each panel with SlotsPerSF.
% 
% • Read the label on the μ = 4 panel.
% Common mistakes
% Do not think a higher numerology creates more resource elements in the same 
% bandwidth and time. It changes the shape of the grid, not its total.
% 
% Do not count the symbols of one slot as the symbols in 1 ms. At μ above 0 
% a 1 ms patch holds several slots side by side.
% Try it (personal exploration)
% Change patchMHz to 5.76 (the first code line after the banner) and use N_RE 
% = 14 B / 15 kHz to predict the RE count in each panel. Type it into myPrediction 
% in the first code line below before you run this section. After the table, 
% a given one-row table shows your prediction and the patch width beside the 
% result. Set patchMHz back to 2.88 afterwards.
% Try it: type your prediction here (a number of REs) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Same time-bandwidth box, new grid shape
%
% This section compares normal-CP grids over the same 1 ms time interval
% and the same frequency span. As mu increases, the number of subcarriers
% decreases while the number of OFDM symbols in 1 ms increases.
fprintf("B3 — Same time-bandwidth box, new grid shape\n");   % banner title only; the numbers go into tables

patchMHz = 2.88;   % width of every panel, MHz: 12 × 240 kHz, the smallest width that holds whole RBs at every mu from 0 to 4 (the Try changes it)

% For normal CP, a fixed B-Hz by 1-ms region contains:
%   N_RE = 14 * B / 15 kHz
%
% The value is independent of mu because the subcarrier-count factor 1/2^mu
% cancels the symbol-count factor 2^mu. Work it out once, from patchMHz
% alone, as the independent value every panel is checked against.
expectedRE = 14 * patchMHz * 1e6 / 15e3;   % 14 symbols in 1 ms at 15 kHz; MHz × 1e6 = Hz; 15e3 Hz = the 15 kHz reference

muValues = (0:4).';           % the five numerologies drawn, one panel each; mu = 4 is drawn though it is SSB-only
nCases   = numel(muValues);   % one panel and one table row per numerology

% Reserve one entry per numerology for each column of the grid-shape table.
scs_kHz          = zeros(nCases,1);   % subcarrier spacing, kHz
nrbExact         = zeros(nCases,1);   % patch width in RBs before rounding (must be a whole number)
nrbValues        = zeros(nCases,1);   % patch width in whole RBs, passed to the carrier
subcarriers      = zeros(nCases,1);   % 12 × RBs: subcarrier rows in the patch
actualPatchMHz   = zeros(nCases,1);   % width the configured carrier really has, MHz
slotsPerSF       = zeros(nCases,1);   % slots in the 1 ms, read back from the carrier
symbolsIn1ms     = zeros(nCases,1);   % OFDM symbols the carrier says 1 ms holds
gridK            = zeros(nCases,1);   % rows of the built 1 ms grid
gridL            = zeros(nCases,1);   % columns of the built 1 ms grid
reCount          = zeros(nCases,1);   % K × L: resource elements in the patch

% One true/false flag per assert and per numerology, reported in the check
% table after the loop.
okIntegerRBs  = false(nCases,1);   % the patch holds a whole number of RBs
okPatchWidth  = false(nCases,1);   % the configured width equals patchMHz
okGridColumns = false(nCases,1);   % the 1 ms grid has the expected number of symbols
okSlotsPerSF  = false(nCases,1);   % slots per subframe equal 2^mu
okRECount     = false(nCases,1);   % the RE count equals expectedRE

tolExact = 1e-9;   % tolerance for comparing values that are whole numbers or exact sums in floating point

% One wide figure, so five narrow panels have room for their labels.
figure( ...
    Name     = 'Track 1 - same box, five numerologies', ...
    Color    = 'w', ...                   % white background, as on a printed page
    Units    = 'pixels', ...
    Position = [100 100 1700 520]);       % left, bottom, width, height in pixels: wide and short for a 1 × 5 row of panels

% A 1 × 5 grid of panels. "Loose" spacing keeps neighbouring titles apart.
tl = tiledlayout(1,5, ...                 % 1 row of 5 panels, one per numerology
    TileSpacing = 'loose', ...
    Padding     = 'compact');

% For each numerology: size the patch in RBs, build the 1 ms grid slot by
% slot, test it, and draw it as a checkerboard in its own panel.
for n = 1:nCases

    % This panel's numerology and spacing.
    mu = muValues(n);
    scs_kHz(n) = 15 * 2^mu;   % 15 kHz reference times 2^mu: the numerology rule

    % How many 12-subcarrier RBs fit across patchMHz at this spacing
    % (MHz × 1e3 = kHz, divided by the kHz width of one RB).
    nrbExact(n) = patchMHz * 1e3 / (12 * scs_kHz(n));   % 1e3: MHz to kHz; 12 subcarriers per RB, so 12 × SCS is one RB's width in kHz

    % The patch must hold a whole number of RBs, or rounding would quietly
    % give a different width and the comparison would no longer be fair.
    okIntegerRBs(n) = abs(nrbExact(n) - round(nrbExact(n))) < tolExact;
    assert(okIntegerRBs(n), ...
        'patchMHz must contain an integer number of RBs at every mu. Look first at patchMHz: it must be a whole multiple of 12 × 240 kHz = 2.88 MHz.');

    nrbValues(n) = round(nrbExact(n));   % now known to be whole; round only removes floating-point dust

    % Build one normal-CP carrier exactly patchMHz wide.
    carrier = nrCarrierConfig( ...
        SubcarrierSpacing = scs_kHz(n), ...   % this panel's spacing
        CyclicPrefix      = 'normal', ...      % normal CP, so every slot has 14 symbols
        NSizeGrid         = nrbValues(n));     % the whole number of RBs that fills the patch

    subcarriers(n) = 12 * carrier.NSizeGrid;   % 12 subcarriers per RB, for the table

    % nrResourceGrid makes one slot at a time, so build the 1 ms grid by
    % placing every slot of the subframe side by side, left to right.
    subframeGrid = [];   % start empty; each pass adds one slot's columns
    for slot = 0:carrier.SlotsPerSubframe-1   % every slot of the 1 ms, numbered from 0
        carrier.NSlot = slot;                       % slots are numbered from 0
        slotGrid = nrResourceGrid(carrier);         % one empty slot
        subframeGrid = [subframeGrid slotGrid]; %#ok<AGROW>   % append its columns on the right; growing is fine for at most 16 slots
    end

    % Record the 1 ms grid's size and the carrier's own counts for the table.
    [gridK(n), gridL(n)] = size(subframeGrid);
    slotsPerSF(n)       = carrier.SlotsPerSubframe;
    symbolsIn1ms(n)     = carrier.SymbolsPerSlot * carrier.SlotsPerSubframe;
    reCount(n)          = gridK(n) * gridL(n);

    % Work back from the built grid to its width: the rows nrResourceGrid
    % made (not the RB count above) times the spacing.
    actualPatchMHz(n) = gridK(n) * carrier.SubcarrierSpacing / 1e3;   % kHz to MHz
    okPatchWidth(n) = abs(actualPatchMHz(n) - patchMHz) < tolExact;
    assert(okPatchWidth(n), ...
        'The built grid is not patchMHz wide. Look first at the nrbValues(n) line and the NSizeGrid input to nrCarrierConfig.');

    % The slot loop must have placed every slot: columns = 14 normal-CP
    % symbols times 2^mu slots, worked out from mu alone.
    okGridColumns(n) = gridL(n) == 14*2^mu;
    assert(okGridColumns(n), ...
        'The 1 ms grid does not contain the expected number of symbols. Look first at the slot loop: it must run over every slot from 0 to SlotsPerSubframe-1.');

    % Slots per subframe read back, checked against 2^mu from mu alone.
    okSlotsPerSF(n) = slotsPerSF(n) == 2^mu;
    assert(okSlotsPerSF(n), ...
        'SlotsPerSubframe read back from the carrier does not equal 2^mu. Look first at the slotsPerSF(n) line: it should read carrier.SlotsPerSubframe, not SlotsPerFrame.');

    % The central B3 result: the same box holds the same number of REs.
    okRECount(n) = abs(reCount(n) - expectedRE) < tolExact;
    assert(okRECount(n), ...
        'RE count in the fixed time-bandwidth box changed with mu. Look first at GridK_1ms and GridL_1ms in the table: K must shrink as L grows.');

    % A checkerboard of 0s and 1s makes each RE visible as its own cell.
    % It is only a picture of the grid, not a transmitted waveform.
    checker = mod((0:gridK(n)-1).' + (0:gridL(n)-1), 2);

    % Draw the checkerboard over 0 to 1000 µs and 0 to patchMHz in kHz.
    nexttile;
    imagesc([0 1000], [0 patchMHz*1e3], checker);   % x from 0 to 1000 µs, y from 0 to the patch width in kHz
    axis xy;                                                  % put frequency 0 at the bottom, as on a graph
    colormap(gca, [0.15 0.15 0.15; 0.85 0.55 0.15]);          % dark grey and orange, one colour per checker value

    % Draw a white line at each slot boundary inside the 1 ms (none at mu = 0).
    if carrier.SlotsPerSubframe > 1
        xline((1:carrier.SlotsPerSubframe-1) * ...
            1000 / carrier.SlotsPerSubframe, '-w');
    end

    % Two short title lines per panel, so neighbouring titles do not overlap.
    % The mu = 4 panel is labelled SSB-only: NR uses 240 kHz only for the SSB.
    if mu == 4   % 240 kHz, the SSB-only numerology
        panelTitle = { ...
            sprintf('\\mu = %d, %d kHz', mu, scs_kHz(n)), ...
            sprintf('%d \\times %d REs (SSB-only \\mu)', gridK(n), gridL(n))};
    else
        panelTitle = { ...
            sprintf('\\mu = %d, %d kHz', mu, scs_kHz(n)), ...
            sprintf('%d \\times %d REs', gridK(n), gridL(n))};
    end

    title(panelTitle, ...
        FontSize = 9, ...                 % points: small enough for five panels side by side
        FontWeight = 'normal', ...
        Interpreter = 'tex');

    xlabel('time (\mus)');
    ylabel('frequency (kHz)');
end

% The shared title is set after the loop from the counted grids, so it
% reports what was measured, not the formula's prediction.
title(tl, sprintf( ...
    'Fixed 1 ms \\times %.2f MHz box\nCounted REs per panel: %s', ...
    patchMHz, listText(unique(reCount))), ...
    FontSize = 15, ...                    % points: larger than the panel titles so it reads as the heading
    FontWeight = 'bold', ...
    Interpreter = 'tex');                 % lets \times print as a symbol

% Gather the grid shapes into one table. Every row is the same 1 ms by
% patchMHz box; only its K × L shape changes.
boxShapes = table( ...
    muValues, ...
    scs_kHz, ...
    nrbValues, ...
    subcarriers, ...
    slotsPerSF, ...
    symbolsIn1ms, ...
    gridK, ...
    gridL, ...
    reCount, ...
    VariableNames = { ...
        'Mu', 'SCS_kHz', 'RBs', 'Subcarriers', 'SlotsPerSF', ...
        'SymbolsIn1ms', 'GridK_1ms', 'GridL_1ms', 'REs'});

boxShapes

% Put your Try-it prediction beside the first panel's RE count in a one-row table.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, patchMHz, reCount(1), predictionNote, ...   % reCount(1) = first panel; patchMHz shows the Try's width was set
    VariableNames = {'MyPrediction', 'PatchMHz', 'REs_FirstPanel', 'Note'});
b3Prediction
%%
% With the default 2.88 MHz patch every row holds 2688 REs. At 15 kHz that 
% patch is 16 RBs (192 subcarriers) by 14 symbols; each step up in μ halves the subcarriers and doubles the symbols, 
% down to 12 subcarriers by 224 symbols at 240 kHz. SlotsPerSF equals 2^μ in 
% every row, and the white lines in each panel split the 1 ms into that many 
% slots. The μ = 4 panel is labelled SSB because 240 kHz is used only for the 
% synchronization signal block.
%% B3 — Assertion checks

% One row per assert in B3. Each list runs over mu = 0 to 4. Expected comes
% from patchMHz and mu alone; Actual comes from the configured carriers and
% the grids built in the loop. Pass is computed from the stored flags.
b3Checks = table( ...
    ["Whole number of RBs in the patch"; ...
     "Built grid width = patchMHz (MHz)"; ...
     "Symbols in the 1 ms grid = 14 × 2^mu"; ...
     "Slots per subframe = 2^mu"; ...
     "RE count = 14 × B / 15 kHz"], ...
    [listText(round(nrbExact)); ...
     listText(patchMHz*ones(nCases,1)); ...
     listText(14*2.^muValues); ...
     listText(2.^muValues); ...
     listText(expectedRE*ones(nCases,1))], ...
    [listText(nrbExact); ...
     listText(actualPatchMHz); ...
     listText(gridL); ...
     listText(slotsPerSF); ...
     listText(reCount)], ...
    [all(okIntegerRBs); ...
     all(okPatchWidth); ...
     all(okGridColumns); ...
     all(okSlotsPerSF); ...
     all(okRECount)], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The figure stays open after its handles are cleared. B4 starts from its
% own names, so nothing from B3 is kept except listText.
clear boxShapes b3Checks b3Prediction predictionNote ...
      patchMHz expectedRE muValues nCases tolExact ...
      scs_kHz nrbExact nrbValues subcarriers actualPatchMHz ...
      slotsPerSF symbolsIn1ms gridK gridL reCount ...
      okIntegerRBs okPatchWidth okGridColumns okSlotsPerSF okRECount ...
      n mu carrier subframeGrid slotGrid slot checker tl panelTitle myPrediction
%% B4 — A real frame, counted
% Key code terms used in this section
% • nrPDSCHConfig, nrPDSCHIndices, nrPDSCH, nrPDSCHDMRSIndices, nrPDSCHDMRS 
% — Purpose: describe a data allocation, find its RE positions, make its data 
% symbols, and find and make its pilots. Inputs: the carrier, the PDSCH configuration, 
% and (for nrPDSCH) the coded bits. Outputs: positions, symbols, and a structure 
% with G (coded bits), Gd (data REs), NREPerPRB, and DMRSSymbolSet.
% 
% • [waveform, info] = nrOFDMModulate(carrier, grid) and nrOFDMDemodulate(carrier, 
% waveform) — Purpose: turn a grid into the samples that are sent, and back 
% again. Inputs: a carrier and a grid (or waveform). Outputs: the waveform and 
% its OFDM information; or a grid.
% 
% • randi([0 1], n, 1), complex(x) — Purpose: n random bits; an array that can 
% hold complex values. Inputs: the range and size; an array. Outputs: the array.
% 
% • colorbar, yline — Purpose: add a colour key (set its Ticks and TickLabels) 
% and horizontal lines. Inputs: none; positions and a line style. Outputs: the 
% key and the lines. The other figure commands are listed at the start of B3.
% New words
% • Waveform: the list of time samples that is actually transmitted.
% 
% • BWP (bandwidth part): a block of the carrier's RBs that one device is set 
% up to use.
% 
% • PDSCH and DM-RS (example only): data, and known pilot values placed among 
% the data. Album track05 (Say It Again) and track07 (Learn the Channel) teach 
% them; here they only mark "these REs are occupied".
% Why it matters
% An NR radio frame lasts 10 ms. This section builds a complete 10 ms resource 
% grid, fills some resource elements, and OFDM-modulates the grid into a waveform.
% 
% The waveform holds useful-symbol samples and cyclic-prefix samples, so the 
% frame's sample count is set by the sample rate and the fixed 10 ms duration:
% 
% $$N_{\mathrm{samples}} = f_s \cdot 10\ \mathrm{ms}$$
% 
% The toolbox picks the FFT size for the carrier, and the sample rate follows 
% from it:
% 
% $$f_s = N_{\mathrm{FFT}}\,\Delta f$$
% 
% The documented default rule: the toolbox picks the smallest power of two 
% (at least 128) for Nfft such that the occupied subcarriers, 12 × NSizeGrid, 
% fill no more than 85 % of it.
% 
% The figure shows the same resource grid that goes into the OFDM modulator: 
% some resource elements are empty, some carry PDSCH data, and some carry DM-RS.
% Configuration used here
% The carrier uses 30 kHz spacing, nSizeGrid = 51 resource blocks, and physical 
% cell ID 42. The example places QPSK PDSCH data in a 24-RB bandwidth part starting 
% at common resource block 10, on OFDM symbols 2 to 13 of every slot, with DM-RS 
% on selected REs inside that allocation. Read the PDSCH and DM-RS setup only 
% as "something occupies these REs"; the competency here is the frame and its 
% sample count.
% What to look for
% • In the frame table, read the FFT size and the sample rate, then the waveform 
% length and its duration.
% 
% • In the figure, dashed grey vertical lines mark slot boundaries and solid 
% black lines mark 1 ms subframe boundaries; count the slots between two black 
% lines.
% 
% • Dotted horizontal lines mark the edges of the BWP; check that every PDSCH 
% and DM-RS RE lies between them and inside the symbol allocation.
% Common mistakes
% Do not assume Nfft equals the number of occupied subcarriers. 12 × NSizeGrid 
% is generally not a power of two, and the toolbox picks a power-of-two FFT 
% size large enough for the grid.
% 
% Do not count only the useful-symbol samples. The frame's samples include every 
% cyclic prefix; leaving them out undercounts both the samples and the duration.
% Try it (personal exploration)
% Use the default FFT-size rule above to find the smallest nSizeGrid at which 
% the FFT size becomes larger than the default carrier's. Then use N_samples 
% = f_s × 10 ms, with f_s = Nfft × Δf, to predict how many samples a 10 ms frame 
% holds for that carrier. In the next section (B4 — Configure the carrier and 
% construct one frame grid), set nSizeGrid to that value and type your sample 
% count into myPrediction, both in its first code lines. Then run B4's sections 
% in order through B4 — Assertion checks (Run and Advance, or Run All). A given 
% one-row table after the waveform is built shows your prediction beside the 
% result. Every check in B4 tests a relationship, so changing nSizeGrid does 
% not stop the run; set nSizeGrid back to 51 and myPrediction back to NaN afterwards.
%% B4 — Configure the carrier and construct one frame grid

% Try it: set nSizeGrid and type your prediction (a number of samples) here, then run B4's sections in order.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so
nSizeGrid = 51;   % grid width in RBs: 51 RB at 30 kHz is a 20 MHz FR1 channel; the Try changes this line (keep it at 34 or more so the BWP below fits)

% This carrier represents a 20 MHz FR1 channel configuration at 30 kHz
% subcarrier spacing. NSizeGrid is the occupied grid width in RBs; the
% nominal channel bandwidth also includes guard-band space.
carrier = nrCarrierConfig( ...
    NCellID            = 42, ...           % physical cell ID: any value from 0 to 1007 works; 42 is an arbitrary example that seeds the DM-RS sequence
    SubcarrierSpacing  = 30, ...           % kHz, mu = 1: a common FR1 data spacing
    CyclicPrefix       = 'normal', ...     % normal CP: 14 symbols per slot
    NSizeGrid          = nSizeGrid, ...    % grid width in RBs, from the line above
    NStartGrid         = 0);               % grid starts at common RB 0, so BWP RB numbers equal grid rows / 12

carrier.NFrame = 0;   % frame number 0: build the first 10 ms frame (NSlot is set slot by slot in the loop below)

% PDSCH is used here only to mark some REs as occupied. Mapping type, RNTI,
% NID, and modulation are taught in later tracks.
pdsch = nrPDSCHConfig;

pdsch.NSizeBWP  = 24;   % BWP width in RBs: a 24-RB block, narrower than the carrier so empty REs stay visible
pdsch.NStartBWP = 10;   % BWP starts at common RB 10, so the BWP sits away from the grid edge in the figure

% PRBSet counts RBs from the start of the BWP; using 0 to NSizeBWP-1
% fills every RB of the BWP.
pdsch.PRBSet = 0:pdsch.NSizeBWP-1;

pdsch.MappingType = 'A';   % type A: the allocation is placed relative to the start of the slot (the usual choice for a full-slot allocation)

% SymbolAllocation is [first symbol, number of symbols], counted from 0.
% Start at symbol 2 and run to the end of the 14-symbol slot (12 symbols).
pdsch.SymbolAllocation = [2 carrier.SymbolsPerSlot-2];

pdsch.Modulation = 'QPSK';   % QPSK: two coded bits per data RE, the simplest NR data modulation
pdsch.NumLayers  = 1;        % one layer, matching the one-antenna grid

pdsch.RNTI = 1005;   % receiver ID that scrambles the data: an arbitrary example value from 1 to 65519
pdsch.NID  = [];     % empty: use the cell ID (carrier.NCellID) for scrambling, the default behaviour

% Read the frame structure once: slots in a 10 ms frame and symbols per slot.
slotsPerFrame  = carrier.SlotsPerFrame;
symbolsPerSlot = carrier.SymbolsPerSlot;

% The whole-frame grid has one row per subcarrier and one column per OFDM
% symbol of the 10 ms frame.
gridRows         = 12 * carrier.NSizeGrid;   % 12 subcarrier rows per RB
frameSymbolCount = slotsPerFrame * symbolsPerSlot;

% frameGrid holds the complex RE values that go into the modulator.
% labelMap mirrors it for the figure: 0 = empty, 1 = PDSCH, 2 = DM-RS.
frameGrid = complex(zeros(gridRows, frameSymbolCount));
labelMap  = zeros(gridRows, frameSymbolCount);

% Build the frame one slot at a time: make the slot, fill its PDSCH and
% DM-RS REs, then copy it into its own columns of the frame grid.
for slotNumber = 0:slotsPerFrame-1

    % The PDSCH and DM-RS positions depend on the slot number, so tell the
    % carrier which slot is being built before asking for any indices.
    carrier.NSlot = slotNumber;

    % One empty slot, and a matching label map for the figure.
    slotGrid   = nrResourceGrid(carrier);
    slotLabels = zeros(size(slotGrid));

    % Ask where the PDSCH REs go in this slot. pdschInfo.G is the number of
    % coded bits that allocation needs; pdschInfo.Gd is its number of REs.
    [pdschIndices, pdschInfo] = nrPDSCHIndices(carrier, pdsch);

    % Random bits stand in for real data: this beat studies occupancy and
    % sample count, not decoding. nrPDSCH turns them into QPSK symbols.
    codedBits    = randi([0 1], pdschInfo.G, 1);   % G random 0/1 bits in one column
    pdschSymbols = nrPDSCH(carrier, pdsch, codedBits);

    % Write the data symbols into their REs, and mark those REs as PDSCH.
    slotGrid(pdschIndices)   = pdschSymbols;
    slotLabels(pdschIndices) = 1;   % label 1 = PDSCH

    % DM-RS: known pilot values on selected REs inside the allocation.
    dmrsIndices = nrPDSCHDMRSIndices(carrier, pdsch);
    dmrsSymbols = nrPDSCHDMRS(carrier, pdsch);

    % Write the pilots into their REs, and mark those REs as DM-RS.
    slotGrid(dmrsIndices)   = dmrsSymbols;
    slotLabels(dmrsIndices) = 2;   % label 2 = DM-RS

    % Slot s (counted from 0) owns frame columns s*14 + 1 to s*14 + 14.
    frameColumns = slotNumber*symbolsPerSlot + (1:symbolsPerSlot);

    % Copy the finished slot and its labels into those columns.
    frameGrid(:, frameColumns) = slotGrid;
    labelMap(:, frameColumns)  = slotLabels;
end

% Keep the last slot's PDSCH information. The allocation is the same in
% every slot, so these values describe the PDSCH of any one slot.
pdschInfoFinal = pdschInfo;
%% B4 — OFDM-modulate the complete frame

% The modulator needs to know which slot the grid starts at: frameGrid
% begins at slot 0 of frame 0.
carrier.NSlot = 0;   % slot 0: where frameGrid starts

% nrOFDMModulate turns the whole frame grid into a time-domain waveform and
% reports the FFT size and sample rate it used.
[waveform, ofdmInfo] = nrOFDMModulate(carrier, frameGrid);

% One antenna gives one waveform column, so its row count is the number
% of time samples in the frame.
nSamples = size(waveform, 1);

% Turn the sample count into a duration for the results table.
sampleRate_MHz   = ofdmInfo.SampleRate / 1e6;              % Hz to MHz
frameDuration_ms = nSamples / ofdmInfo.SampleRate * 1e3;   % samples / (samples per second) = seconds; × 1e3 = ms

% Put your Try-it prediction beside the waveform's sample count in a one-row table.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction in B4 — Configure the carrier, then run B4's sections again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, carrier.NSizeGrid, nSamples, predictionNote, ...   % NSizeGrid shows the Try's width was set
    VariableNames = {'MyPrediction', 'NSizeGrid', 'SamplesInFrame', 'Note'});
b4Prediction
%% B4 — Verify frame dimensions and waveform duration

% Check 1: a frame lasts 10 ms, so its sample count must equal the sample
% rate times 10 ms, and also ten subframes of symbol lengths (prefixes included).
expectedSamples = round(ofdmInfo.SampleRate * 10e-3);   % 10e-3 s = 10 ms
subframeSamples = sum(ofdmInfo.SymbolLengths);          % one 1 ms subframe, prefixes included
okFrameSamples  = (nSamples == expectedSamples) && (nSamples == 10*subframeSamples);
assert(okFrameSamples, ...
    'The OFDM waveform does not contain exactly 10 ms of samples. Look first at frameGrid: every slot of the frame must be placed before nrOFDMModulate.');

% Check 2 (independent route): count what the slot loop actually placed.
% Every slot should add the toolbox's per-slot PDSCH RE count (Gd) and its
% DM-RS count, with no slot skipped and none written over another.
nPDSCHPlaced = nnz(labelMap == 1);   % PDSCH-labelled REs in the whole frame
nDMRSPlaced  = nnz(labelMap == 2);   % DM-RS-labelled REs in the whole frame
okSlotsPlaced = (nPDSCHPlaced == slotsPerFrame * pdschInfoFinal.Gd) && ...
    (nDMRSPlaced == slotsPerFrame * numel(dmrsIndices));
assert(okSlotsPlaced, ...
    'The frame grid does not hold one full allocation per slot. Look first at the frameColumns line inside the slot loop: each slot needs its own SymbolsPerSlot columns.');

% Check 3 (independent route): go back the receiver's way. Demodulating
% the waveform should give back the grid that went in, column for column.
carrier.NSlot = 0;                               % the waveform starts at slot 0, as when it was modulated
rxGrid = nrOFDMDemodulate(carrier, waveform);
roundTripTolerance = 1e-4;   % largest error allowed, as a fraction of the largest grid value: far above rounding error, far below one misplaced symbol
if isequal(size(rxGrid), size(frameGrid))
    % Worst-case error over every RE, relative to the largest RE value.
    roundTripError = max(abs(rxGrid(:) - frameGrid(:))) / max(abs(frameGrid(:)));
else
    roundTripError = Inf;   % a grid of the wrong size counts as a total mismatch
end
okRoundTrip = roundTripError < roundTripTolerance;
assert(okRoundTrip, ...
    'Demodulating the waveform does not give the frame grid back. Look first at what was passed to nrOFDMModulate: it must be frameGrid, the complex frame grid, not labelMap or a single slot.');

% Check 4: QPSK carries two coded bits per data RE, so G = 2 × Gd.
okQPSKBits = (pdschInfoFinal.G == 2 * pdschInfoFinal.Gd);
assert(okQPSKBits, ...
    'QPSK should use two coded bits per PDSCH modulation symbol. Look first at pdsch.Modulation: it should be QPSK.');

% Documented default FFT-size rule: the smallest power of two (at least
% 128) that keeps the occupied subcarriers at or below 85 % of the FFT.
% It is computed, not typed in, and it is shown but never asserted,
% because it describes toolbox behaviour, not an NR requirement.
ruleNfft      = max(128, 2^nextpow2(12*carrier.NSizeGrid/0.85));   % 128 = smallest FFT the rule allows; 0.85 = the 85 % fill limit
okDefaultRule = (ofdmInfo.Nfft == ruleNfft);
if ~okDefaultRule
    disp('Note: this release picked a different FFT size from the documented default rule; the frame still lasts 10 ms, so the lesson holds.')
end
%% B4 — Frame and waveform results

% Format display values as text so the Live Editor table avoids unnecessary
% trailing zeroes while the numeric variables remain available for checks.
frameDurationText = compose("%.3f ms", frameDuration_ms);
sampleRateText    = compose("%.2f MHz", sampleRate_MHz);
sampleCountText   = compose("%d samples", nSamples);
fftText           = compose("Nfft = %d", ofdmInfo.Nfft);

% One two-column table: what was configured, how the grid is filled, and
% what came out of the modulator.
frameResults = table( ...
    ["Carrier configuration"; ...
     "Frame structure"; ...
     "Resource grid"; ...
     "PDSCH allocation per slot"; ...
     "PDSCH coded bits per slot"; ...
     "DM-RS symbols in slot"; ...
     "FFT size"; ...
     "Sample rate"; ...
     "Waveform length"; ...
     "Waveform duration"], ...
    [compose("%d kHz SCS, %d RB, cell ID %d", ...
         carrier.SubcarrierSpacing, carrier.NSizeGrid, carrier.NCellID); ...
     compose("%d slots × %d symbols = %d OFDM symbols", ...
         slotsPerFrame, symbolsPerSlot, frameSymbolCount); ...
     compose("%d subcarriers × %d OFDM symbols", ...
         size(frameGrid,1), size(frameGrid,2)); ...
     compose("%d REs (%d REs per PRB)", ...
         pdschInfoFinal.Gd, pdschInfoFinal.NREPerPRB); ...
     compose("%d bits, %s", pdschInfoFinal.G, pdsch.Modulation); ...
     listText(pdschInfoFinal.DMRSSymbolSet); ...
     fftText; ...
     sampleRateText; ...
     sampleCountText; ...
     frameDurationText], ...
    VariableNames = {'Quantity','Value'});

frameResults
%% B4 — Frame grid figure
% The same labels that marked the grid before modulation: white is empty, blue 
% is PDSCH, orange is DM-RS.

L = carrier.SymbolsPerSlot;   % symbols per slot, used to place the slot and subframe lines
figure(Name = 'Track 01 - one frame, labelled grid', Color = 'w');

% Draw labelMap with symbol and subcarrier numbers counted from 0; [0 2]
% fixes the colour range so 0, 1, and 2 always get the same three colours.
imagesc(0:size(labelMap,2)-1, 0:size(labelMap,1)-1, labelMap, [0 2]);
axis xy;                                                      % subcarrier 0 at the bottom
colormap(gca, [1 1 1; 0.20 0.40 0.80; 0.90 0.30 0.10]);       % white = empty, blue = PDSCH, orange = DM-RS

% A colour key with one named tick per label value.
cb = colorbar;
cb.Ticks = [0 1 2];   % one tick per label value: empty, PDSCH, DM-RS
cb.TickLabels = {'empty','PDSCH','DM-RS'};

% Dashed grey lines between slots; solid black lines every 1 ms subframe.
% The 0.5 shift puts each line on the edge between two columns, not through one.
xline((1:carrier.SlotsPerFrame-1)*L - 0.5, '--', Color = [0.5 0.5 0.5]);         % mid grey, quieter than the subframe lines
xline((1:9)*L*carrier.SlotsPerSubframe - 0.5, '-k', LineWidth = 1.2);            % the 9 inner subframe edges of a 10-subframe frame; 1.2 pt so they stand out

% Dotted black lines at the bottom and top edges of the BWP (12 rows per RB).
yline([pdsch.NStartBWP, pdsch.NStartBWP + pdsch.NSizeBWP]*12 - 0.5, ':k', LineWidth = 1.2);   % 1.2 pt, as for the subframe lines

xlabel(sprintf('OFDM symbol index in frame (%d per slot, %d slots per 1 ms subframe)', ...
    L, carrier.SlotsPerSubframe));
ylabel('subcarrier index k (12 per RB)');
title(sprintf('One 10 ms frame: %d kHz, %d RB, PDSCH and DM-RS in a %d-RB BWP', ...
    carrier.SubcarrierSpacing, carrier.NSizeGrid, pdsch.NSizeBWP));
%%
% For the default carrier the toolbox picks Nfft = 1024 (612 occupied subcarriers 
% fit within 85 % of 1024 but not of 512), so the sample rate is 1024 × 30 kHz 
% = 30.72 MHz and the 10 ms frame holds 307200 samples, prefixes included. Track 00 
% (track00_fundamentals/p00a_ofdm_and_cp_demo) used the same 30.72 MHz rate with Nfft = 2048 at 15 kHz: same rate, half the 
% FFT, twice the spacing. The grid has 612 subcarrier rows and one column per 
% OFDM symbol of the frame; the Frame structure row gives the count. In the figure, 
% count the slots between two black subframe lines and check that it matches 
% the slots in the Frame structure row divided by ten. All PDSCH and DM-RS REs 
% lie inside the dotted BWP edges, from symbol 2 onward in each slot. If 
% you ran the Try with a larger nSizeGrid, compare the FFT size and sample count 
% rows with your prediction instead.
%% B4 — Assertion checks

% One row per assert in B4, plus the default FFT-size rule, which is shown
% but not asserted. Expected comes from the sample rate, the per-slot
% counts, the tolerance, or the rule; Actual comes from the waveform and the
% filled grid. Pass is computed from the stored flags.
b4Checks = table( ...
    ["Frame samples = SampleRate × 10 ms = 10 × sum(SymbolLengths)"; ...
     "Every slot placed once (PDSCH REs, DM-RS REs)"; ...
     "Demodulated grid = frameGrid (relative error below)"; ...
     "QPSK coded bits G = 2 × Gd"; ...
     "Default FFT-size rule (Nfft); shown, not asserted"], ...
    [listText([expectedSamples, 10*subframeSamples]); ...
     listText([slotsPerFrame*pdschInfoFinal.Gd, slotsPerFrame*numel(dmrsIndices)]); ...
     string(roundTripTolerance); ...
     string(2*pdschInfoFinal.Gd); ...
     string(ruleNfft)], ...
    [string(nSamples); ...
     listText([nPDSCHPlaced, nDMRSPlaced]); ...
     string(roundTripError); ...
     string(pdschInfoFinal.G); ...
     string(ofdmInfo.Nfft)], ...
    [okFrameSamples; ...
     okSlotsPlaced; ...
     okRoundTrip; ...
     okQPSKBits; ...
     okDefaultRule], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% The figures stay open. The Build it below starts from its own names;
% listText stays because its check sections use it.
clear nSizeGrid carrier pdsch slotsPerFrame symbolsPerSlot gridRows frameSymbolCount ...
      frameGrid labelMap slotNumber slotGrid slotLabels pdschIndices pdschInfo ...
      codedBits pdschSymbols dmrsIndices dmrsSymbols frameColumns pdschInfoFinal ...
      waveform ofdmInfo nSamples sampleRate_MHz frameDuration_ms ...
      b4Prediction predictionNote ...
      expectedSamples subframeSamples okFrameSamples ...
      nPDSCHPlaced nDMRSPlaced okSlotsPlaced ...
      rxGrid roundTripTolerance roundTripError okRoundTrip okQPSKBits ...
      ruleNfft okDefaultRule ...
      frameDurationText sampleRateText sampleCountText fftText frameResults ...
      b4Checks L cb myPrediction
%% Build it — Configure a carrier and read its numerology
% Competency: given μ and NSizeGrid, build the carrier yourself, predict the 
% FFT size the toolbox will pick for it, and read its slots per subframe, its 
% one-slot grid size (K × L), and the number of samples in one 10 ms frame.
% Problem
% You are given myMu = 2 and myNRB = 11. Build a normal-CP carrier with spacing 
% 15 kHz × 2^myMu and myNRB resource blocks. Before you read any OFDM information 
% for it, predict the FFT size the toolbox will pick. Then read how many slots 
% it fits into one subframe, make its one-slot resource grid and find its size, 
% and work out how many samples one 10 ms frame holds from the FFT size and 
% the spacing.
% Allowed commands
% nrCarrierConfig with Name = value inputs; reading a property with a dot (myCarrier.Name); 
% nrResourceGrid; size with [a, b] = size(x); nrOFDMInfo and its fields; ordinary 
% arithmetic. The tables and figure in the check sections and Stage 5 are given. 
% The commands are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), replace each ___ with your 
% own code, and run that section. Then run the check section under it. Each 
% blank is a whole right-hand side: write it from Key code terms, not by copying 
% a line from the beats above. A check never gives the answer; it tells you 
% what to look at. When a check passes, it shows a small table of what it tested.
%% Stage 1 — switch it on
% Delete the % in front of the two code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myMu = 2;     % numerology index: given for this exercise
% myNRB = 11;   % grid width in resource blocks: given; no carrier above uses this width
%% Stage 1 check (given)
if ~exist('myMu','var') || ~exist('myNRB','var')
    disp('Stage 1 not done: delete the % in front of the two code lines above, then run that section.')
else
    % Both given values must still be in place before the later stages use them.
    okStage1 = (myMu == 2) && (myNRB == 11);   % the two values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the two lines you uncommented: they should set myMu = 2 and myNRB = 11.')
    stage1Checks = table("myMu and myNRB as given", listText([2 11]), ...   % expected: the given 2 and 11
        listText([myMu myNRB]), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — build the carrier
% Replace ___ with one nrCarrierConfig call that makes a normal-CP carrier 
% from myMu and myNRB, using Name = value inputs. Uncomment the line and run.
% Pass: Stage 2 OK.

% myCarrier = ___;
%% Stage 2 check (given; the check goes back from the spacing to μ with log2)
if ~exist('myCarrier','var')
    disp('Stage 2 not done: replace ___, uncomment, and run.')
elseif ~isa(myCarrier, 'nrCarrierConfig')
    disp('Stage 2 not yet: myCarrier is not a carrier object. Look first at the function you called: Key code terms, nrCarrierConfig.')
else
    % Undo the numerology rule (spacing / 15 kHz = 2^mu, so log2 gives mu
    % back), and compare the width and CP with what was asked for.
    okStage2 = [log2(myCarrier.SubcarrierSpacing/15) == myMu; ...
                myCarrier.NSizeGrid == myNRB; ...
                strcmp(myCarrier.CyclicPrefix, 'normal')];
    assert(okStage2(1), ...
        'The spacing does not match myMu. Look first at SubcarrierSpacing: it is in kHz and follows the numerology rule.')
    assert(okStage2(2), ...
        'The grid width does not match myNRB. Look first at NSizeGrid in your nrCarrierConfig call.')
    assert(okStage2(3), ...
        'This Build it uses normal CP. Look first at the CyclicPrefix input: normal is the default, so you can leave it out.')
    stage2Checks = table( ...
        ["mu from the spacing (log2 of SCS / 15)"; "NSizeGrid = myNRB"; "Cyclic prefix is normal"], ...
        [string(myMu); string(myNRB); "normal"], ...
        [string(log2(myCarrier.SubcarrierSpacing/15)); string(myCarrier.NSizeGrid); string(myCarrier.CyclicPrefix)], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: the FFT size
% Before you read any OFDM information for myCarrier, type your prediction: 
% what FFT size will the toolbox pick for it? Work it out from the default 
% FFT-size rule in B4 (Why it matters). Run this section and the check under 
% it before you start Stage 3b: the check does not take a prediction once the 
% names from Stage 3b or Stage 4 exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with the toolbox and does not print the toolbox's value)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif ~exist('myCarrier','var')
    disp('Stage 3a needs Stage 2 first: make myCarrier, then return here.')
elseif exist('myInfo','var') || exist('mySlotsPerSF','var') || exist('myK','var') || exist('myFrameSamples','var')
    disp('Stage 3a refused: names from Stage 3b or Stage 4 already exist, so this is no longer a prediction. Run "clear myInfo mySlotsPerSF myGrid myK myL myFrameSamples", then predict again.')
else
    checkInfo3a   = nrOFDMInfo(myCarrier);                % the toolbox's own FFT size, a route different from your rule
    okPrediction3 = (myPrediction == checkInfo3a.Nfft);
    stage3aCheck = table("Prediction = the toolbox's FFT size", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at the occupied subcarriers of this carrier, then at the smallest power of two, at least 128, that keeps them at or below 85 % of the FFT. Change myPrediction and run again.')
    end
end
%% Stage 3b — read the slots, the grid, and the OFDM information
% Replace each ___: read the carrier's slots-per-subframe property, make its 
% one-slot resource grid, take the grid's size (rows first), and get the OFDM 
% information for your carrier.
% Pass: your locked prediction and the FFT size you read appear side by side, 
% and Stage 3 OK.

% mySlotsPerSF = ___;
% myGrid = ___;
% [myK, myL] = ___;
% myInfo = ___;
%% Stage 3b check (given; the check counts symbols in a fresh nrOFDMInfo, a different route from yours)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('mySlotsPerSF','var') || ~exist('myK','var') || ~exist('myL','var') || ~exist('myInfo','var')
    disp('Stage 3b not done: replace each ___, uncomment, and run.')
elseif ~isstruct(myInfo) || ~isfield(myInfo, 'Nfft')
    disp('Stage 3b not yet: myInfo should be the structure of OFDM information. Look first at Key code terms, nrOFDMInfo.')
else
    % Your locked prediction beside the FFT size you read, in one row.
    stage3Prediction = table(myLockedPrediction, myInfo.Nfft, ...
        VariableNames = {'MyPrediction', 'MyInfoNfft'});
    stage3Prediction

    % Different route: nrOFDMInfo lists one length per symbol in 1 ms, so
    % that count divided by the symbols in one slot is the slots in 1 ms.
    checkInfo   = nrOFDMInfo(myCarrier);
    oracleSlots = numel(checkInfo.SymbolLengths) / myCarrier.SymbolsPerSlot;

    % Five tests: two catch common mistakes (frame count, swapped K and L),
    % three compare your values with the different route and the rule.
    okStage3 = [mySlotsPerSF ~= myCarrier.SlotsPerFrame; ...
                mySlotsPerSF == oracleSlots; ...
                ~(myK == myCarrier.SymbolsPerSlot && myL == 12*myNRB); ...
                myK == 12*myNRB && myL == myCarrier.SymbolsPerSlot; ...
                myInfo.Nfft == checkInfo.Nfft];
    assert(okStage3(1), ...
        'That is the number of slots in a whole 10 ms frame. Look first at which carrier property you read: the Stage asks for one 1 ms subframe.')
    assert(okStage3(2), ...
        'The slot count does not match the symbols in 1 ms. Look first at which carrier property you read.')
    assert(okStage3(3), ...
        'K and L are swapped. Look first at the order size returns: rows (subcarriers) come first.')
    assert(okStage3(4), ...
        'The grid size is not one slot of this carrier. Look first at what you passed to nrResourceGrid.')
    assert(okStage3(5), ...
        'myInfo is not the OFDM information of myCarrier. Look first at what you passed to nrOFDMInfo.')
    stage3Checks = table( ...
        ["Not the slots in a frame"; "Slots = symbols in 1 ms / SymbolsPerSlot"; ...
         "K and L not swapped"; "Grid = 12 × NSizeGrid by SymbolsPerSlot"; ...
         "myInfo is this carrier's (Nfft)"], ...
        ["not " + string(myCarrier.SlotsPerFrame); string(oracleSlots); ...
         "not " + listText([myCarrier.SymbolsPerSlot, 12*myNRB]); ...
         listText([12*myNRB, myCarrier.SymbolsPerSlot]); string(checkInfo.Nfft)], ...
        [string(mySlotsPerSF); string(mySlotsPerSF); listText([myK myL]); listText([myK myL]); ...
         string(myInfo.Nfft)], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — samples in one frame, from the FFT size and the spacing
% Replace ___ with your own expression for the samples in one 10 ms frame, 
% worked out from the FFT size in myInfo and the carrier's spacing, using f_s 
% = N_FFT × Δf and N_samples = f_s × 10 ms. SubcarrierSpacing is in kHz. Do 
% not read SampleRate for this stage; Stage 5 uses it as a second route.
% Pass: Stage 4 OK.

% myFrameSamples = ___;
%% Stage 4 check (given; the check adds up every symbol length, prefixes included, a different route from yours)
if ~exist('myLockedPrediction','var') || ~exist('myInfo','var')
    disp('Stage 4 needs Stages 3a and 3b first.')
elseif ~exist('myFrameSamples','var')
    disp('Stage 4 not done: replace ___, uncomment, and run.')
else
    % Different route: ten subframes, each the sum of its symbol lengths
    % with prefixes. usefulOnly is a common mistake: no prefixes at all.
    oracleFrame = 10 * sum(myInfo.SymbolLengths);
    usefulOnly  = myInfo.Nfft * myCarrier.SymbolsPerSlot * myCarrier.SlotsPerFrame;

    % Sample counts are whole numbers; within half a sample means equal.
    okStage4 = [abs(myFrameSamples - usefulOnly) > 0.5; ...         % 0.5 = half a sample
                abs(1e3*myFrameSamples - oracleFrame) > 0.5; ...    % 1e3: the kHz-for-Hz slip
                abs(myFrameSamples - oracleFrame) < 0.5];
    assert(okStage4(1), ...
        'That count is the useful samples only. Look first at what a 10 ms frame of samples holds besides the useful part of each symbol, and at N_samples = f_s × 10 ms.')
    assert(okStage4(2), ...
        'Your count is a thousand times too small. Look first at the units: SubcarrierSpacing is in kHz, and the sample rate is in samples per second.')
    assert(okStage4(3), ...
        'The frame sample count is off. Look first at the field you read from myInfo and at the frame duration in seconds.')
    stage4Checks = table( ...
        ["Prefixes included (not the useful-only count)"; "Units: spacing in Hz"; ...
         "Frame samples = 10 × sum(SymbolLengths)"], ...
        ["not " + string(usefulOnly); "not " + string(oracleFrame/1e3); string(oracleFrame)], ...
        [string(myFrameSamples); string(myFrameSamples); string(myFrameSamples)], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure. Rows marked "repeat of Stage n" only repeat an earlier check; the 
% others use a route you did not use.

if ~exist('myFrameSamples','var') || ~exist('oracleFrame','var') || ~exist('myGrid','var') || ~exist('myLockedPrediction','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myCarrier.SubcarrierSpacing == 15*2^myMu; ...
        mySlotsPerSF == 2^myMu; ...
        myK == 12*myNRB && myL == myCarrier.SymbolsPerSlot; ...
        myInfo.Nfft == myLockedPrediction; ...
        abs(myFrameSamples - myInfo.SampleRate*10e-3) < 0.5; ...         % 0.5 = half a sample; 10e-3 s = 10 ms
        abs(myFrameSamples/myInfo.SampleRate - 10e-3) < 1e-12];          % 1e-12 s: far below one sample period

    % One row per result: the rule's value, your value, and the computed flag.
    buildChecks = table( ...
        ["Spacing (kHz) = 15 × 2^mu (repeat of Stage 2)"; "Slots per subframe = 2^mu (from mu alone)"; ...
         "One-slot grid = 12 × NSizeGrid by SymbolsPerSlot (repeat of Stage 3b)"; ...
         "FFT size = your locked prediction (repeat of Stage 3a)"; ...
         "Frame samples = SampleRate × 10 ms (the route you did not use)"; "Frame duration (ms) = 10"], ...
        [string(15*2^myMu); string(2^myMu); ...
         listText([12*myNRB, myCarrier.SymbolsPerSlot]); ...
         string(myLockedPrediction); string(myInfo.SampleRate*10e-3); "10"], ...
        [string(myCarrier.SubcarrierSpacing); string(mySlotsPerSF); ...
         listText([myK myL]); string(myInfo.Nfft); ...
         string(myFrameSamples); string(1e3*myFrameSamples/myInfo.SampleRate)], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: one 1 ms subframe of this carrier, slot by slot. The
    % checkerboard has one cell per RE across every slot of the subframe.
    mySubframeChecker = mod((0:myK-1).' + (0:myL*mySlotsPerSF-1), 2);
    figure(Name = 'Track 01 Build it - my carrier, one subframe', Color = 'w');
    imagesc([0 1000], [0 myK*myCarrier.SubcarrierSpacing], mySubframeChecker);   % 0 to 1000 µs across, 0 to the carrier width in kHz up
    axis xy;                                                  % frequency 0 at the bottom
    colormap(gca, [0.15 0.15 0.15; 0.85 0.55 0.15]);          % same two colours as B3, so the figures compare directly
    xline((1:mySlotsPerSF-1) * 1000/mySlotsPerSF, '-w', LineWidth = 1.5);   % white slot boundaries; 1.5 pt so they show on the checkerboard
    xlabel('time (\mus)');
    ylabel('frequency (kHz)');
    title(sprintf('My carrier: %d kHz, %d RB, one 1 ms subframe', ...
        myCarrier.SubcarrierSpacing, myCarrier.NSizeGrid));
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): 
% how many slots does the figure show in 1 ms, and how does that follow from 
% μ? Why does the frame sample count depend on the FFT size the toolbox picked, 
% while the frame still lasts 10 ms?
% 
% My interpretation:
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. Keep myMu, and add one 
% RB to the carrier (myNRB + 1). By what factor does the number of samples in 
% one 10 ms frame change? (Type 2 for twice as many, 1 for no change.) Add one 
% line to your interpretation saying why. The check works it out with nrOFDMInfo 
% and does not print the value.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('myInfo','var') || ~exist('myCarrier','var')
    disp('Run Stages 1 to 4 first, then return here.')
else
    carrierPlus = nrCarrierConfig(SubcarrierSpacing = myCarrier.SubcarrierSpacing, ...
        NSizeGrid = myCarrier.NSizeGrid + 1);                 % the same carrier, one RB wider
    infoPlus    = nrOFDMInfo(carrierPlus);
    factorFrame = sum(infoPlus.SymbolLengths) / sum(myInfo.SymbolLengths);   % ratio of samples per 1 ms, so per 10 ms too
    okInterp    = abs(myAnswer - factorFrame) < 0.01;
    interpHint  = "";
    if ~okInterp
        interpHint = "the FFT-size rule: does one more RB need a larger power of two?";
    end
    interpCheck = table("Frame-sample factor, one RB wider", okInterp, interpHint, ...
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
      checkInfo3a okPrediction3 stage3aCheck ...
      stage3Prediction checkInfo oracleSlots okStage3 stage3Checks ...
      oracleFrame usefulOnly okStage4 stage4Checks ...
      buildFlags buildChecks mySubframeChecker ...
      myAnswer carrierPlus infoPlus factorFrame okInterp interpHint interpCheck
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them. 
% Each exercise has a check: type your numbers into its myE variable and run 
% that section. The check works the values out by a second route (the toolbox, 
% or the rule from a different starting point), shows Pass or a pointer for 
% each entry, and never prints the value. You may use MATLAB as a calculator 
% in a new section of your own. Write the reasons on the Your answer lines; 
% the script does not grade them.
%% E1 — New values (B1, B2)
% A carrier uses 60 kHz spacing with extended CP. How many whole slots does 
% it send in 2.5 ms, and how many OFDM symbols is that? Explain each number 
% from slots per subframe and symbols per slot, and say why extended CP changes 
% one of the two counts but not the other. Type the two numbers into myE1 as 
% [slots, symbols].
% 
% Your answer:
myE1 = NaN;   % [slots in 2.5 ms, OFDM symbols in 2.5 ms]
if any(isnan(myE1)) || numel(myE1) ~= 2
    disp('Type two numbers into myE1, then run this section again.')
else
    e1Car  = nrCarrierConfig(SubcarrierSpacing = 60, CyclicPrefix = 'extended');   % second route: the toolbox
    e1Ref  = [2.5*e1Car.SlotsPerSubframe, 2.5*e1Car.SlotsPerSubframe*e1Car.SymbolsPerSlot];   % 2.5 = the window in ms
    okE1   = abs(myE1(:) - e1Ref(:)) < 1e-9;
    e1Hint = ["slots per 1 ms subframe at this spacing, times the window in ms"; ...
              "symbols per slot with extended CP"];
    e1Hint(okE1) = "";
    e1Check = table(["Slots in 2.5 ms"; "OFDM symbols in 2.5 ms"], okE1, e1Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e1Check
end
%% E2 — Diagnosis (B2)
% A classmate reads CyclicPrefixLengths(1), the first entry, as "the" prefix 
% for each normal-CP spacing, turns it into μs, and finds that it does not halve 
% exactly each time μ goes up. What did they read, and why is it different 
% from the ordinary prefix? By how many μs is that first prefix longer than 
% the ordinary one at 30 kHz, and at 120 kHz? Does the extra length depend on 
% μ? Type the two extra lengths into myE2 as [at 30 kHz, at 120 kHz], in μs.
% 
% Your answer:
myE2 = NaN;   % [extra length at 30 kHz (μs), extra length at 120 kHz (μs)]
if any(isnan(myE2)) || numel(myE2) ~= 2
    disp('Type two numbers into myE2, then run this section again.')
else
    e2Scs = [30 120];   % the two spacings the exercise asks about, kHz
    e2Ref = zeros(1, 2);
    for e2n = 1:2
        e2Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = e2Scs(e2n), NSizeGrid = 24));   % second route: the toolbox
        e2Ref(e2n) = 1e6 * (e2Info.CyclicPrefixLengths(1) - e2Info.CyclicPrefixLengths(2)) / e2Info.SampleRate;   % × 1e6: s to µs
    end
    okE2   = abs(myE2(:) - e2Ref(:)) <= 0.01*abs(e2Ref(:));   % within 1 %
    e2Hint = ["first prefix minus the second, in samples, over the sample rate"; ...
              "the same subtraction at 120 kHz; compare it with 30 kHz"];
    e2Hint(okE2) = "";
    e2Check = table(["Extra first-prefix length at 30 kHz (µs)"; "Extra first-prefix length at 120 kHz (µs)"], okE2, e2Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e2Check
end
%% E3 — Diagnosis (B4)
% Someone counts the samples in the default B4 frame (30 kHz, 51 RB) as SlotsPerFrame 
% × SymbolsPerSlot × (Nfft + CyclicPrefixLengths(2)), one ordinary prefix per 
% symbol, and comes up short of the waveform's length. How many samples short, 
% and why? Then: what fraction of a frame's samples are cyclic-prefix samples, 
% and why does that fraction not depend on μ? Type [samples short, fraction] 
% into myE3, the fraction as a decimal. You may read nrOFDMInfo in a section 
% of your own.
% 
% Your answer:
myE3 = NaN;   % [samples short, prefix fraction of the frame]
if any(isnan(myE3)) || numel(myE3) ~= 2
    disp('Type two numbers into myE3, then run this section again.')
else
    e3Car   = nrCarrierConfig(SubcarrierSpacing = 30, NSizeGrid = 51);   % the default B4 carrier
    e3Info  = nrOFDMInfo(e3Car);                                          % second route: the toolbox's lengths
    e3Frame = 10 * sum(e3Info.SymbolLengths);                             % ten subframes, prefixes included
    e3Naive = e3Car.SlotsPerFrame * e3Car.SymbolsPerSlot * (e3Info.Nfft + e3Info.CyclicPrefixLengths(2));
    e3Ref   = [e3Frame - e3Naive, sum(e3Info.CyclicPrefixLengths) / sum(e3Info.SymbolLengths)];
    okE3    = [abs(myE3(1) - e3Ref(1)) < 0.5; ...    % whole samples: within half a sample
               abs(myE3(2) - e3Ref(2)) < 0.005];      % "roughly": within half a percentage point
    e3Hint  = ["which prefixes are not ordinary, and how many of them a frame holds"; ...
               "all prefix samples over all samples, in one subframe"];
    e3Hint(okE3) = "";
    e3Check = table(["Samples short"; "Prefix fraction of the frame"], okE3, e3Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e3Check
end
%% E4 — New values (B3)
% Take a 1 ms × 4.32 MHz patch. At which μ from 0 to 4 does it first fail to 
% hold a whole number of RBs? How many patch widths up to 10 MHz hold a whole 
% number of RBs at every μ from 0 to 4? Explain from the width of one RB at 
% μ = 4. Then: how many REs does a 0.5 ms × 4.32 MHz patch hold at μ = 2, and 
% why would the count be the same at μ = 0? Type [first failing μ, number of 
% widths, REs] into myE4.
% 
% Your answer:
myE4 = NaN;   % [first failing mu, number of widths up to 10 MHz, REs in 0.5 ms × 4.32 MHz at mu = 2]
if any(isnan(myE4)) || numel(myE4) ~= 3
    disp('Type three numbers into myE4, then run this section again.')
else
    e4RBkHz  = 12 * 15 * 2.^(0:4);                        % one RB's width in kHz at mu = 0 to 4
    e4Whole  = abs(4320./e4RBkHz - round(4320./e4RBkHz)) < 1e-9;   % 4320 kHz = 4.32 MHz
    e4Fail   = find(~e4Whole, 1) - 1;                     % -1: positions count from 1, mu from 0
    e4Widths = 180 * (1:floor(10000/180));                % every width up to 10 MHz that holds whole RBs at mu = 0, kHz
    e4Every  = sum(all(mod(e4Widths.', e4RBkHz) == 0, 2));   % widths that hold whole RBs at every mu
    e4Car    = nrCarrierConfig(SubcarrierSpacing = 60, NSizeGrid = 4320/720);   % second route: a toolbox grid at mu = 2
    e4RE     = size(nrResourceGrid(e4Car), 1) * e4Car.SymbolsPerSlot * e4Car.SlotsPerSubframe / 2;   % / 2: half of 1 ms
    e4Ref    = [e4Fail, e4Every, e4RE];
    okE4     = abs(myE4(:) - e4Ref(:)) < 1e-9;
    e4Hint   = ["the RB width at each mu, and which one 4.32 MHz does not divide"; ...
                "whole multiples of the widest RB"; ...
                "subcarriers in 4.32 MHz at 60 kHz, times the symbols in 0.5 ms"];
    e4Hint(okE4) = "";
    e4Check = table(["First failing mu"; "Widths up to 10 MHz, whole RBs at every mu"; "REs, 0.5 ms × 4.32 MHz, mu = 2"], ...
        okE4, e4Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e4Check
end
%% E5 — Explanation (nrResourceGrid, size)
% A one-slot grid from nrResourceGrid has size 288 × 14. How many RBs wide 
% is the carrier, and which of the two numbers counts subcarriers? Can you tell 
% μ from this size alone (normal CP, μ from 0 to 3)? Type [RBs, 1 if you can 
% tell μ or 0 if you cannot] into myE5, then say why on the answer line.
% 
% Your answer:
myE5 = NaN;   % [RBs, 1 = mu can be told from the size, 0 = it cannot]
if any(isnan(myE5)) || numel(myE5) ~= 2
    disp('Type two numbers into myE5, then run this section again.')
else
    e5RB    = 288 / size(nrResourceGrid(nrCarrierConfig(NSizeGrid = 1)), 1);   % second route: rows per RB from the toolbox
    e5Sizes = zeros(4, 2);
    for e5mu = 0:3
        e5Sizes(e5mu+1, :) = size(nrResourceGrid(nrCarrierConfig(SubcarrierSpacing = 15*2^e5mu, NSizeGrid = e5RB)));
    end
    e5Tell  = double(size(unique(e5Sizes, 'rows'), 1) > 1);   % 1 only if the size differs between numerologies
    e5Ref   = [e5RB, e5Tell];
    okE5    = abs(myE5(:) - e5Ref(:)) < 1e-9;
    e5Hint  = ["which number size returns first, and subcarriers per RB"; ...
               "build the same width at each mu and compare the sizes"];
    e5Hint(okE5) = "";
    e5Check = table(["RBs"; "Can mu be told from the size"], okE5, e5Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e5Check
end
%% E6 — Reasoning (B4, default FFT-size rule)
% Using the default FFT-size rule from B4: what is the largest NSizeGrid that 
% still gets Nfft = 512 at 30 kHz spacing? Is it the same at 120 kHz? Type both 
% into myE6 as [at 30 kHz, at 120 kHz]. Then explain: what does the spacing 
% change for a given NSizeGrid (the FFT size, the sample rate, or both), and 
% why does the frame still last 10 ms?
% 
% Your answer:
myE6 = NaN;   % [largest NSizeGrid with Nfft 512 at 30 kHz, the same at 120 kHz]
if any(isnan(myE6)) || numel(myE6) ~= 2
    disp('Type two numbers into myE6, then run this section again.')
else
    e6Scs = [30 120];   % kHz
    e6Ref = zeros(1, 2);
    for e6n = 1:2
        for e6RB = 1:80   % second route: ask the toolbox for every width up to 80 RB
            e6Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = e6Scs(e6n), NSizeGrid = e6RB));
            if e6Info.Nfft == 512
                e6Ref(e6n) = e6RB;   % keeps the largest width that still gets 512
            end
        end
    end
    okE6   = abs(myE6(:) - e6Ref(:)) < 1e-9;
    e6Hint = ["the 85 % fill limit of a 512-point FFT, in subcarriers, then in whole RBs"; ...
              "whether the spacing appears in the rule at all"];
    e6Hint(okE6) = "";
    e6Check = table(["Largest NSizeGrid for Nfft 512, 30 kHz"; "Largest NSizeGrid for Nfft 512, 120 kHz"], okE6, e6Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e6Check
end
%% Exercise cleanup
clear myE1 e1Car e1Ref okE1 e1Hint e1Check myE2 e2Scs e2Ref e2n e2Info okE2 e2Hint e2Check ...
      myE3 e3Car e3Info e3Frame e3Naive e3Ref okE3 e3Hint e3Check ...
      myE4 e4RBkHz e4Whole e4Fail e4Widths e4Every e4Car e4RE e4Ref okE4 e4Hint e4Check ...
      myE5 e5RB e5Sizes e5mu e5Tell e5Ref okE5 e5Hint e5Check ...
      myE6 e6Scs e6Ref e6n e6RB e6Info okE6 e6Hint e6Check
%% Recap — Two to the Mu (album track 01)
% The numerology index μ changes the spacing and timing of the NR OFDM grid 
% while preserving the fixed 1 ms subframe and 10 ms radio-frame structure.
% Key relationships
% Subcarrier spacing doubles whenever μ increases by one:
% 
% $$\Delta f = 15\ \mathrm{kHz}\cdot2^{\mu}$$
% 
% The 1 ms subframe remains fixed. With normal cyclic prefix, each slot contains 
% 14 OFDM symbols, so slot duration decreases as μ increases:
% 
% $$T_{\mathrm{slot}} = \frac{1\ \mathrm{ms}}{2^{\mu}}$$
% 
% A fixed time–bandwidth region changes shape with μ. Higher μ produces fewer 
% subcarrier rows in the same bandwidth and more OFDM-symbol columns in the same 
% time. The total number of resource elements remains unchanged:
% 
% $$N_{\mathrm{RE}} = 14\frac{B}{15\ \mathrm{kHz}} = 2688\qquad \text{for } 
% B = 2.88\ \mathrm{MHz}$$
% 
% A radio frame always lasts 10 ms. After OFDM modulation, its sample count 
% is determined by sample rate and frame duration:
% 
% $$N_{\mathrm{samples}} = f_s\cdot 10\ \mathrm{ms} = 307200\qquad \text{for } 
% f_s = 30.72\ \mathrm{MHz}$$
% What this means in practice
% • Larger subcarrier spacing produces shorter OFDM symbols and shorter slots. 
% This can support lower latency and improve tolerance to Doppler shift and phase 
% noise.
% 
% • Smaller subcarrier spacing produces longer symbol and cyclic-prefix durations. 
% This can better tolerate longer propagation delays.
% 
% • Numerology does not create additional resource elements in a fixed time 
% and bandwidth region. It changes the K × L shape of the resource grid.
% 
% • The waveform sample count includes both useful-symbol samples and cyclic-prefix 
% samples.
% 
% • You built a carrier from μ and NSizeGrid yourself, predicted the FFT size 
% the toolbox picked for it, read its slots per subframe and its one-slot grid 
% size, and counted the samples in one 10 ms frame, prefixes included.
% 
% • Next in the album: track02 (Copy the Tail).
%% Review — self-check
% Best done at the start of your next session, before you open track02. Collapse 
% the Recap section above (or scroll until it and the header are out of sight), 
% then write from memory, in your own words. Do not look back until you have 
% written what you can.
% 
% First, each of the seven key ideas, one line each. Then, for each command 
% you write yourself (listed below by name only), its purpose, its inputs, and 
% its outputs.
% 
% When you have written all you can, scroll up to Key ideas to remember and 
% Key code terms to remember and compare. Mark anything you missed or got wrong, 
% and reread the beat where it was used. The families of helpers and the short 
% lists at the start of B3 and B4 are not part of this review. Nothing in this 
% written list is checked by the script; the retrieval section below is.
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
% • f(Name = value, ...):
% 
% • s.Name:
% 
% • [a, b] = size(x):
% 
% • nrCarrierConfig:
% 
% • nrResourceGrid:
% 
% • nrOFDMInfo:
% What I missed, and where to reread it
% 
%% Review — retrieval
% Still keeping the Recap collapsed: from track 00's bits-and-grid demo (track00_fundamentals/p00a_bits_and_grid_demo), 
% how far from the centre of the constellation is every QPSK point (±1 ± j)/√2? 
% Type the distance into myAnswer and run this section. Then, in one line, 
% say why it is the same for all four points. The check measures all four points 
% and does not print the value.
% 
% Why:
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    qpskPoints = [1+1j; 1-1j; -1+1j; -1-1j] / sqrt(2);          % the four QPSK points
    okReview   = all(abs(abs(qpskPoints) - myAnswer) < 1e-6);   % second route: the magnitude of every point
    reviewCheck = table("Distance of every QPSK point from the centre", okReview, ...
        VariableNames = {'Check', 'Pass'});
    reviewCheck
end
