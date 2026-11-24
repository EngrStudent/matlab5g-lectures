%% Track 01 — Two to the Mu
%% 5G NR numerology: spacing, timing, and grid shape
% This demonstration explores how the 5G NR numerology index, μ, changes the 
% OFDM resource grid.
% 
% A resource element (RE) is one subcarrier over one OFDM symbol. As μ increases, 
% subcarrier spacing increases and OFDM symbols become shorter. The grid changes 
% shape, but a fixed time–bandwidth region can contain the same total number of 
% resource elements.
%% Guiding question
% What happens to an OFDM resource grid when the spacing between subcarriers 
% doubles?
% This demonstration
% 1. Sweep numerology values from μ = 0 to μ = 4, including the extended cyclic-prefix 
% case at 60 kHz.
% 
% 2. Measure timing: useful-symbol duration, cyclic-prefix duration, and slot 
% duration.
% 
% 3. Compare equal time–bandwidth regions and show that their RE count remains 
% constant as μ changes.
% 
% 4. Build and OFDM-modulate one 10 ms frame at 30 kHz subcarrier spacing.
% Key relationships
% Subcarrier spacing increases by a factor of two for each increase in μ.
% 
% $$\Delta f = 15\ \mathrm{kHz}\cdot 2^{\mu}$$
% 
% Slot duration decreases by a factor of two for each increase in μ.
% 
% $$T_{\mathrm{slot}} = \frac{1\ \mathrm{ms}}{2^{\mu}}$$
% 
% For normal cyclic prefix, each slot contains 14 OFDM symbols. Increasing μ 
% therefore produces shorter slots and more slots in each 1 ms subframe.
%% Prerequisites
% • OFDM resource grids, resource elements, and resource blocks
% 
% • Subcarrier spacing and OFDM symbols
% 
% • The role of the cyclic prefix
% 
% This demonstration emphasizes durations rather than raw sample counts. FFT 
% size, sample rate, and cyclic-prefix lengths in samples are useful implementation 
% details, but they are treated as optional supporting material.
% Working status
% The script runs successfully in the intended MATLAB environment. The numerical 
% results and visualizations will be checked and interpreted section by section 
% as the demonstration is refined.
% 
% 
%% Staging for script

%clear working environment
clear; close all;
%set random seed (reproducibility)
rng(2026);
%% B1. Numerology sweep
% Why it matters
% NR numerology is built on powers of two relative to a 15 kHz reference grid. 
% Increasing μ by one doubles the subcarrier spacing and doubles the number of 
% slots in the same 1 ms subframe. The 1 ms subframe clock, and therefore the 
% 10 ms radio-frame timing structure, does not change.
% 
% $$\Delta f = 15\ \mathrm{kHz}\cdot2^{\mu}$$
% 
% A larger subcarrier spacing produces shorter slots. This can reduce transmission 
% latency and improve tolerance to Doppler shift and phase noise, particularly 
% at higher carrier frequencies. A smaller subcarrier spacing produces a longer 
% cyclic prefix in time, which can tolerate longer propagation echoes and larger 
% delay spreads.
% 
% A resource block (RB) contains 12 subcarriers. Therefore, a grid configured 
% with NSizeGrid resource blocks has 12 × NSizeGrid subcarrier rows.
% |What to look for|
% • SlotsPerSubframe should equal 2^μ.
% 
% • SlotsPerFrame should equal 10 × 2^μ.
% 
% • The resource grid should have 12 × NSizeGrid rows.
% 
% • A normal-cyclic-prefix slot has 14 OFDM symbols.
% 
% • The extended-cyclic-prefix case in this sweep has 12 OFDM symbols and uses 
% 60 kHz subcarrier spacing.
% |*Common mistakes.* 
% Do not confuse SlotsPerFrame with SlotsPerSubframe. SlotsPerFrame counts slots 
% in a 10 ms radio frame, whereas SlotsPerSubframe counts slots in one 1 ms subframe.
% 
% Do not assume that extended cyclic prefix is available at every subcarrier 
% spacing. In this demonstration, the extended-CP configuration is the 60 kHz 
% case.
% Try it (personal exploration). 
% Add a μ = 5 row to the sweep. Append 5 to muList, append 'normal' to cpList, 
% and append a resource-block count such as 32 to nrbList.
% 
% The code calculates subcarrier spacing from muList, so change muList rather 
% than entering a separate SubcarrierSpacing value. You can also change nrbList 
% and confirm that the grid height K remains equal to 12 × NSizeGrid.
% *Predict before running*. 
% For each row, predict the subcarrier spacing, slots per subframe, slots per 
% frame, and symbols per slot:
% 
% • Subcarrier spacing: $\text{15 kHz} \times 2^\mu $
% 
% • Slots per subframe: $ 2^\mu $
% 
% • Slots per frame: $10 \times 2^\mu $
% 
% • Symbols per slot: 14 for normal CP, or 12 for the extended-CP 60 kHz case
% 
% Pause at the 30 kHz row and predict SlotsPerSubframe before reading the result.
% 
% 

% B1 — Numerology sweep
%
% Each row defines one NR numerology case. The sweep includes normal CP at
% mu = 0, 1, 2, 3, and 4, plus extended CP at mu = 2 (60 kHz).
fprintf("B1 — Numerology sweep");

% The numerology index sets subcarrier spacing:
%   SCS = 15 kHz * 2^mu
muList = [0 1 2 2 3 4];

% Each cyclic-prefix type corresponds to the numerology in the same row.
cpList = {'normal','normal','normal','extended','normal','normal'};

% Example max-bandwidth RB counts from TS 38.101-1/-2 (240 kHz uses the
% 20 RB SSB width, because 240 kHz is SSB-only in Rel-15/16).
nrbList = [270 273 135 135 264 20];


% Reserve one entry per sweep case. These vectors will become columns in
% the results table displayed after all cases have been inspected.
nCases = numel(muList);

scs_kHz        = zeros(nCases,1);
symbolsPerSlot = zeros(nCases,1);
slotsPerSF     = zeros(nCases,1);
slotsPerFrame  = zeros(nCases,1);
gridK          = zeros(nCases,1);
gridL          = zeros(nCases,1);

% Construct and inspect one carrier configuration per sweep row.
for n = 1:nCases

    % Read one complete configuration from the parallel input lists.
    mu  = muList(n);
    cp  = cpList{n};
    nrb = nrbList(n);

    % Subcarrier spacing is derived from mu, rather than independently
    % selected. This keeps the configuration tied to the numerology rule.
    % this is the first toolbox function, receiving our parameters
    carrier = nrCarrierConfig( ...
        SubcarrierSpacing = 15*2^mu, ...
        CyclicPrefix      = cp, ...
        NSizeGrid         = nrb, ...
        NStartGrid        = 0);

    % Read back carrier timing properties calculated by 5G Toolbox.
    %  this is why we used the function, it computes the key properties
    scs_kHz(n)        = carrier.SubcarrierSpacing;
    symbolsPerSlot(n) = carrier.SymbolsPerSlot;
    slotsPerSF(n)     = carrier.SlotsPerSubframe;
    slotsPerFrame(n)  = carrier.SlotsPerFrame;

    % One resource grid represents one slot. Its dimensions are:
    %   K: 12 subcarriers per RB times NSizeGrid RBs
    %   L: one column per OFDM symbol in the slot
    % We are computing the carrier slot resources using our config
    grid = nrResourceGrid(carrier);
    [gridK(n), gridL(n)] = size(grid);

    % Check that numerology divides the fixed 1 ms subframe into 2^mu
    % slots. This is the timing relationship central to this section.
    assert(slotsPerSF(n) == 2^mu, ...
        'SlotsPerSubframe does not equal 2^mu.');

    % Check that a 10 ms radio frame contains ten 1 ms subframes.
    % Therefore, its slot count is 10 * 2^mu.
    assert(slotsPerFrame(n) == 10*2^mu, ...
        'SlotsPerFrame does not equal 10*2^mu.');

    % Check the definition of a resource block: every RB adds exactly
    % 12 subcarriers, and therefore 12 rows, to the resource grid.
    assert(gridK(n) == 12*nrb, ...
        'Resource-grid height does not equal 12*NSizeGrid.');

    % Check that the number of grid columns equals the number of OFDM
    % symbols in the configured slot.
    assert(gridL(n) == symbolsPerSlot(n), ...
        'Resource-grid width does not equal SymbolsPerSlot.');

    % Check the symbol count associated with the chosen cyclic prefix.
    % Normal CP uses 14 symbols per slot. The extended-CP 60 kHz case in
    % this sweep uses 12 symbols per slot.
    if mu == 2 && strcmp(cp,'extended')
        assert(symbolsPerSlot(n) == 12, ...
            'Extended CP at 60 kHz should have 12 symbols per slot.');
    else
        assert(symbolsPerSlot(n) == 14, ...
            'Normal CP should have 14 symbols per slot.');
    end
end

% Display the carrier properties and grid dimensions returned by the
% toolbox. Short headings keep the table readable in the Live Editor.
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

numerologySweep.Properties.VariableUnits{'SCS_kHz'} = 'kHz';

% Display once in the Live Editor. The displayed output remains visible
% even after the temporary table variable is cleared below.
numerologySweep
%%

% The assertions inside the loop stop execution if a numerology relationship
% fails. This table makes those successful checks visible and explains what
% each relationship confirms.

isExtendedCP = (muList(:) == 2) & strcmp(cpList(:), 'extended');

checkPassed = [ ...
    all(scs_kHz == 15*2.^muList(:)); ...
    all(slotsPerSF == 2.^muList(:)); ...
    all(slotsPerFrame == 10*2.^muList(:)); ...
    all(gridK == 12*nrbList(:)); ...
    all(gridL == symbolsPerSlot); ...
    all(symbolsPerSlot(~isExtendedCP) == 14) && ...
        all(symbolsPerSlot(isExtendedCP) == 12)];

passedText = repmat("Pass", numel(checkPassed), 1);
passedText(~checkPassed) = "Fail";


numerologyChecks = table( ...
    ["Subcarrier spacing"; ...
     "Slots per subframe"; ...
     "Slots per frame"; ...
     "Grid height"; ...
     "Grid width"; ...
     "Symbols per slot"], ...
    ["15 kHz × 2^mu"; ...
     "2^mu"; ...
     "10 × 2^mu"; ...
     "12 × NSizeGrid"; ...
     "SymbolsPerSlot"; ...
     "14 normal CP; 12 extended CP at 60 kHz"], ...
    passedText, ...
    VariableNames = {'Check', 'Expected', 'Result'});

numerologyChecks
%%

% Keep the three sweep-definition lists for B2. The remaining variables
% were used only to construct and verify the B1 results table.
clear numerologySweep numerologyChecks ...
      checkPassed passedText isExtendedCP ...
      nCases scs_kHz symbolsPerSlot slotsPerSF slotsPerFrame gridK gridL ...
      n mu cp nrb carrier grid
%% B2 — Timing: Symbol, Prefix, and Slot
% Why it matters
% The useful OFDM symbol duration is the reciprocal of subcarrier spacing. As 
% μ increases, subcarrier spacing increases and the useful symbol becomes shorter.
% 
% $$T_u = \frac{1}{\Delta f}$$
% 
% A 1 ms subframe remains fixed in duration. 
% 
% $$T_{\mathrm{subframe}} = 1\ \mathrm{ms}$$
% 
% Increasing μ therefore divides that same 1 ms interval into more, shorter 
% slots.
% 
% $$T_{\mathrm{slot}} = \frac{1\ \mathrm{ms}}{2^{\mu}}$$
% 
% The cyclic prefix (CP) is best understood here as a duration. For normal CP, 
% an ordinary prefix is approximately 4.69 μs at the 15 kHz reference numerology. 
% The number of CP samples printed by MATLAB depends on the selected FFT size 
% and sample rate, so it can change even when the CP duration is unchanged.
% What to look for
% • Tu_us: useful OFDM symbol duration, equal to 1 / SCS.
% 
% • CPord_us: duration of an ordinary cyclic prefix.
% 
% • Tslot_us: slot duration, equal to 1000 / 2^μ microseconds.
% 
% The subframe duration should remain 1000 μs for every numerology.
% Common mistake. 
% Do not compare the CP sample counts printed by the toolbox directly with the 
% 144- and 160-sample reference values from TS 38.211 unless the FFT size is Nfft 
% = 2048. Sample counts depend on FFT size; durations are the meaningful comparison 
% in this section.
% Try it. 
% Change one normal-CP row to extended CP at 60 kHz and compare the ordinary 
% cyclic-prefix duration with the normal-CP result.
% Optional technical note
% The familiar CP reference lengths of 144 and 160 samples use the 2048-unit 
% timing reference. In each 0.5 ms half-subframe, the first prefix is lengthened 
% by 16 reference samples. This adjustment makes the symbols and prefixes fit 
% exactly into the half-subframe duration.
% 
% These counts apply directly only when Nfft = 2048. MATLAB may select a larger 
% or smaller default FFT size based on the occupied grid width. For example, the 
% 270-RB, 15 kHz carrier can use Nfft = 4096, which produces CP lengths of 288 
% and 320 samples rather than 144 and 160 samples.
% 
% The durations remain the same because both the sample count and the sample 
% rate scale with FFT size.
% Try it. 
% Request Nfft = 2048 when calling nrOFDMInfo for the μ = 0 carrier. The reported 
% CP lengths should then begin with 160 samples followed by ordinary prefixes 
% of 144 samples. 

% B2 — Timing: useful symbol, cyclic prefix, and slot duration
%
% B1 defined the numerology, cyclic-prefix type, and grid size for each
% sweep case. Here, nrOFDMInfo converts each carrier configuration into
% waveform timing information: FFT size, sample rate, symbol lengths, and
% cyclic-prefix lengths.
fprintf("B2 — Timing: useful symbol, cyclic prefix, and slot duration");

% One output row is collected for each numerology configuration.
nCases = numel(muList);

% Preallocate columns for the timing-results table.
nfft             = zeros(nCases,1);
sampleRate_MHz   = zeros(nCases,1);
usefulSymbol_us  = zeros(nCases,1);
cpSecond_us      = zeros(nCases,1);
subframe_us      = zeros(nCases,1);
slot_us          = zeros(nCases,1);

% Preallocate logical results for the executable timing checks. The asserts
% below stop execution if a check fails; these arrays make successful checks
% visible in a Live Editor table after the loop.
checkUsefulSymbol = false(nCases,1);
checkSymbolCount  = false(nCases,1);
checkSubframe     = false(nCases,1);
checkSlot         = false(nCases,1);

% Inspect the timing information for each carrier configuration.
for n = 1:nCases

    % Read the current sweep row. Subcarrier spacing remains tied to mu:
    %   SCS = 15 kHz * 2^mu
    mu  = muList(n);
    cp  = cpList{n};
    nrb = nrbList(n);

    % Build the carrier used by nrOFDMInfo. NSizeGrid affects the default
    % FFT size selected by the toolbox, but it does not change the physical
    % useful-symbol duration implied by the selected subcarrier spacing.
    carrier = nrCarrierConfig( ...
        SubcarrierSpacing = 15*2^mu, ...
        CyclicPrefix      = cp, ...
        NSizeGrid         = nrb);

    % nrOFDMInfo reports the implementation details used for OFDM waveform
    % generation, including Nfft, SampleRate, SymbolLengths, and
    % CyclicPrefixLengths.
    info = nrOFDMInfo(carrier);

    % Record the FFT size and sample rate selected by the toolbox.
    nfft(n)           = info.Nfft;
    sampleRate_MHz(n) = info.SampleRate / 1e6;

    % The useful OFDM symbol contains Nfft samples. Dividing by the sample
    % rate converts that sample count to a duration in microseconds.
    usefulSymbol_us(n) = info.Nfft / info.SampleRate * 1e6;

    % The first symbol in each half-subframe can have a lengthened prefix.
    % Prefix entry 2 is therefore used as the representative non-lengthened
    % prefix. Its sample count is converted to a duration in microseconds.
    cpSecond_us(n) = info.CyclicPrefixLengths(2) / info.SampleRate * 1e6;

    % SymbolLengths includes useful-symbol samples and CP samples across one
    % complete 1 ms subframe. Its total duration should therefore be 1000 us.
    subframe_us(n) = sum(info.SymbolLengths) / info.SampleRate * 1e6;

    % Numerology divides the fixed 1 ms subframe into SlotsPerSubframe slots.
    slot_us(n) = subframe_us(n) / carrier.SlotsPerSubframe;

    % Check 1: useful symbol duration must be the reciprocal of subcarrier
    % spacing. This is the direct timing consequence of changing mu.
    expectedUsefulSymbol_us = 1e3 / carrier.SubcarrierSpacing;
    checkUsefulSymbol(n) = abs(usefulSymbol_us(n) - expectedUsefulSymbol_us) < 1e-9;
    assert(checkUsefulSymbol(n), ...
        'Useful-symbol duration does not equal 1 / subcarrier spacing.');

    % Check 2: the timing information must contain one symbol length for
    % every symbol in every slot of the 1 ms subframe.
    expectedSymbolsPerSubframe = carrier.SymbolsPerSlot * carrier.SlotsPerSubframe;
    checkSymbolCount(n) = numel(info.SymbolLengths) == expectedSymbolsPerSubframe;
    assert(checkSymbolCount(n), ...
        'The number of symbol lengths does not match the 1 ms subframe.');

    % Check 3: regardless of numerology, a subframe remains exactly 1 ms.
    checkSubframe(n) = abs(subframe_us(n) - 1000) < 1e-6;
    assert(checkSubframe(n), ...
        'The OFDM symbols and cyclic prefixes do not sum to 1 ms.');

    % Check 4: increasing mu divides the 1 ms subframe into 2^mu slots.
    expectedSlot_us = 1000 / 2^mu;
    checkSlot(n) = abs(slot_us(n) - expectedSlot_us) < 1e-6;
    assert(checkSlot(n), ...
        'Slot duration does not equal 1 ms / 2^mu.');
end

% Display the timing values returned or derived from nrOFDMInfo. Short
% headings keep the table readable in the Live Editor output pane.
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

timingResults.Properties.VariableDescriptions = { ...
    'Numerology index', ...
    'Cyclic-prefix type', ...
    'FFT size selected by nrOFDMInfo', ...
    'OFDM sample rate', ...
    'Useful symbol duration', ...
    'Second cyclic-prefix duration', ...
    'Slot duration'};

timingResults
%%

% The assertions in the preceding loop stop execution if a timing
% relationship fails. This table makes the successful checks visible.

checkPassed = [ ...
    all(checkUsefulSymbol); ...
    all(checkSymbolCount); ...
    all(checkSubframe); ...
    all(checkSlot)];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

timingChecks = table( ...
    ["Useful symbol duration"; ...
     "Symbol count per subframe"; ...
     "Subframe duration"; ...
     "Slot duration"], ...
    ["Tu = 1 / SCS"; ...
     "SymbolsPerSlot × SlotsPerSubframe"; ...
     "1 ms"; ...
     "1 ms / 2^mu"], ...
    resultText, ...
    VariableNames = {'Check','Expected','Result'});

timingChecks
%%

% Preserve the B1 sweep definitions for later reference or reruns.
% Clear variables used only to calculate, verify, and display B2 results.

clear timingResults timingChecks ...
      nCases ...
      nfft sampleRate_MHz usefulSymbol_us cpSecond_us subframe_us slot_us ...
      checkUsefulSymbol checkSymbolCount checkSubframe checkSlot ...
      checkPassed resultText ...
      n mu cp nrb carrier info ...
      expectedUsefulSymbol_us expectedSymbolsPerSubframe expectedSlot_us
%% B3 — Same Time–Bandwidth Box, New Grid Shape
% Why it matters
% A resource element (RE) is one subcarrier during one OFDM symbol.
% 
% This section holds time and bandwidth fixed: one 1 ms interval and a 2.88 
% MHz frequency span. As μ increases, each subcarrier becomes twice as wide, so 
% fewer subcarriers fit into the same bandwidth. At the same time, OFDM symbols 
% become shorter, so more OFDM symbols fit into the same 1 ms interval.
% 
% The resource-grid dimensions therefore change with numerology:
% 
% • Higher μ produces fewer subcarrier rows in the same bandwidth.
% 
% • Higher μ produces more OFDM-symbol columns in the same time interval.
% 
% These changes cancel when the time and bandwidth are fixed. The grid has a 
% different K × L shape, but its total number of resource elements remains unchanged.
% 
% $$N_{\mathrm{RE}} =\left(\frac{B}{15\ \mathrm{kHz}\cdot 2^{\mu}}\right)\left(14\cdot2^{\mu}\right)=14\frac{B}{15\ 
% \mathrm{kHz}}$$
% 
% For a fixed bandwidth B, the factor 2^μ cancels. The resource-element count 
% therefore does not depend on numerology.
% What to look for
% • Each checkerboard represents the same 1 ms × 2.88 MHz region.
% 
% • Each panel has the same total area in resource elements: 2688 _*RE*_s.
% 
% • The grid dimensions change with μ. Higher μ produces fewer subcarrier rows 
% and more OFDM-symbol columns.
% 
% • White vertical lines mark slot boundaries within the 1 ms interval.
% 
% • The μ = 4, 240 kHz panel is included to complete the mathematical sweep. 
% 
% In NR, this numerology is associated with _*SSB*_ use rather than a general 
% data-carrier grid.
% Common mistake. 
% A higher numerology does not create more resource elements in the same bandwidth 
% and time interval. It changes the shape of the resource grid while preserving 
% the total _*RE*_ count.
% 
% *The 2.88 MHz example*
% 
% At μ = 0, the 2.88 MHz region contains 192 subcarriers, or 16 resource blocks. 
% Each increase in μ halves the number of subcarriers:
% 
% • μ = 0: 192 subcarriers = 16 RB
% 
% • μ = 1: 96 subcarriers = 8 RB
% 
% • μ = 2: 48 subcarriers = 4 RB
% 
% • μ = 3: 24 subcarriers = 2 RB
% 
% • μ = 4: 12 subcarriers = 1 RB
% 
% In the same 1 ms interval, the number of normal-CP OFDM symbols increases 
% from 14 to 14 × 2^μ. The product remains constant:
% 
% 192 subcarriers × 14 symbols = 2688 REs.
% 
% Every later panel has fewer subcarriers and more symbols, but the product 
% remains 2688 REs.
% Try it (personal exploration). 
% Change patchMHz to 5.76. Before running the code, predict the resource-element 
% count using 14 × B / 15 kHz. Then compare your prediction with the value checked 
% by the assertion and shown in the figure titles.
% 
% 

% B3 — Same time-bandwidth box, new grid shape
%
% This section compares normal-CP grids over the same 1 ms time interval
% and the same frequency span. As mu increases, the number of subcarriers
% decreases while the number of OFDM symbols in 1 ms increases.
fprintf("B3 — Same time-bandwidth box, new grid shape");

% The frequency width of every panel. This value must accommodate an integer
% number of RBs at every numerology in the mu = 0:4 sweep.
patchMHz = 2.88;

% For normal CP, a fixed B-Hz by 1-ms region contains:
%   N_RE = 14 * B / 15 kHz
%
% The value is independent of mu because the subcarrier-count factor 1/2^mu
% cancels the symbol-count factor 2^mu.
expectedRE = 14 * patchMHz * 1e6 / 15e3;

% The five numerologies shown in the figure.
muValues = (0:4).';
nCases = numel(muValues);

% Preallocate columns for the displayed grid-shape table.
scs_kHz          = zeros(nCases,1);
nrbValues        = zeros(nCases,1);
subcarriers      = zeros(nCases,1);
slotsPerSubframe = zeros(nCases,1);
symbolsIn1ms     = zeros(nCases,1);
gridK            = zeros(nCases,1);
gridL            = zeros(nCases,1);
reCount          = zeros(nCases,1);

% Store the logical outcomes used by the executable assertions. They become
% the visible Pass/Fail results in the check table after the loop.
checkIntegerRBs   = false(nCases,1);
checkPatchWidth   = false(nCases,1);
checkGridColumns  = false(nCases,1);
checkRECount      = false(nCases,1);

% Create one panel per numerology.
% A wide figure gives five narrow numerology panels enough room for their
% labels and two-line titles.
figure( ...
    Name     = 'Track 1 - same box, five numerologies', ...
    Color    = 'w', ...
    Units    = 'pixels', ...
    Position = [100 100 1700 520]);

% "Loose" spacing prevents neighbouring tile titles from overlapping.
tl = tiledlayout(1,5, ...
    TileSpacing = 'loose', ...
    Padding     = 'compact');

% Keep the shared title short. The detailed K x L dimensions appear in each
% panel title and in the B3 results table.
title(tl, sprintf( ...
    'Fixed 1 ms \\times %.2f MHz box\n%d REs at every \\mu', ...
    patchMHz, expectedRE), ...
    FontSize = 15, ...
    FontWeight = 'bold', ...
    Interpreter = 'tex');

for n = 1:nCases

    % The current numerology determines subcarrier spacing.
    mu = muValues(n);
    scs_kHz(n) = 15 * 2^mu;

    % Each RB contains 12 subcarriers. Calculate how many complete RBs fit
    % into the requested frequency span at this subcarrier spacing.
    nrbExact = patchMHz * 1e3 / (12 * scs_kHz(n));

    % The selected patch must contain an integer number of RBs. This avoids
    % silently rounding to a different frequency width.
    checkIntegerRBs(n) = abs(nrbExact - round(nrbExact)) < 1e-12;
    assert(checkIntegerRBs(n), ...
        'patchMHz must contain an integer number of RBs at every mu.');

    nrbValues(n) = round(nrbExact);

    % Configure one normal-CP carrier with the required number of RBs.
    carrier = nrCarrierConfig( ...
        SubcarrierSpacing = scs_kHz(n), ...
        CyclicPrefix      = 'normal', ...
        NSizeGrid         = nrbValues(n));

    % The configured bandwidth should equal the requested patch width.
    subcarriers(n) = 12 * carrier.NSizeGrid;
    actualPatchMHz = subcarriers(n) * carrier.SubcarrierSpacing / 1e3;

    checkPatchWidth(n) = abs(actualPatchMHz - patchMHz) < 1e-12;
    assert(checkPatchWidth(n), ...
        'Configured grid width does not equal patchMHz.');

    % Build a complete 1 ms subframe grid by placing its slots side by side.
    % nrResourceGrid returns one slot at a time, so each iteration appends
    % one slot's OFDM-symbol columns to the subframe grid.
    subframeGrid = [];

    for slot = 0:carrier.SlotsPerSubframe-1
        carrier.NSlot = slot;
        slotGrid = nrResourceGrid(carrier);
        subframeGrid = [subframeGrid slotGrid]; %#ok<AGROW>
    end

    % K is the number of subcarrier rows. L is the total number of OFDM
    % symbol columns across the complete 1 ms subframe.
    [gridK(n), gridL(n)] = size(subframeGrid);
    symbolsIn1ms(n) = carrier.SymbolsPerSlot * carrier.SlotsPerSubframe;
    reCount(n) = gridK(n) * gridL(n);

    % Check that concatenating all slots produced the expected number of
    % OFDM-symbol columns for one complete subframe.
    checkGridColumns(n) = gridL(n) == symbolsIn1ms(n);
    assert(checkGridColumns(n), ...
        'The 1 ms grid does not contain the expected number of symbols.');

    % Check the central B3 result: fixed time and bandwidth produce the
    % same RE count at every numerology.
    checkRECount(n) = abs(reCount(n) - expectedRE) < 1e-9;
    assert(checkRECount(n), ...
        'RE count in the fixed time-bandwidth box changed with mu.');

    % Use alternating values only to make resource-element boundaries
    % visually apparent. The checkerboard is not a transmitted waveform.
    checker = mod((0:gridK(n)-1).' + (0:gridL(n)-1), 2);

    nexttile;
    imagesc([0 1000], [0 patchMHz*1e3], checker);
    axis xy;
    colormap(gca, [0.15 0.15 0.15; 0.85 0.55 0.15]);

    % Mark boundaries between slots inside the fixed 1 ms interval.
    if carrier.SlotsPerSubframe > 1
        xline((1:carrier.SlotsPerSubframe-1) * ...
            1000 / carrier.SlotsPerSubframe, '-w');
    end

    % The 240 kHz panel completes the mathematical sweep. It is labelled
    % separately because it represents SSB use rather than general data use.
    % Use two short title lines. This avoids overlap between neighbouring
        % panels in the five-column layout.
    if mu == 4
        panelTitle = { ...
            sprintf('\\mu = %d, %d kHz', mu, scs_kHz(n)), ...
            sprintf('%d \\times %d REs (SSB)', gridK(n), gridL(n))};
    else
        panelTitle = { ...
            sprintf('\\mu = %d, %d kHz', mu, scs_kHz(n)), ...
            sprintf('%d \\times %d REs', gridK(n), gridL(n))};
    end

    title(panelTitle, ...
        FontSize = 9, ...
        FontWeight = 'normal', ...
        Interpreter = 'tex');

    xlabel('time (\mus)');
    ylabel('frequency (kHz)');
end

% Display the different grid shapes. Every row represents the same 1 ms
% time span and the same patchMHz frequency span.
boxShapes = table( ...
    muValues, ...
    scs_kHz, ...
    nrbValues, ...
    subcarriers, ...
    slotsPerSubframe, ...
    symbolsIn1ms, ...
    gridK, ...
    gridL, ...
    reCount, ...
    VariableNames = { ...
        'Mu', 'SCS_kHz', 'RBs', 'Subcarriers', 'SlotsPerSF', ...
        'SymbolsIn1ms', 'GridK', 'GridL', 'REs'});

boxShapes
%%

% The assertions above stop execution when a grid no longer represents the
% requested fixed time-bandwidth box. This table makes those checks visible.

checkPassed = [ ...
    all(checkIntegerRBs); ...
    all(checkPatchWidth); ...
    all(checkGridColumns); ...
    all(checkRECount)];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

boxChecks = table( ...
    ["Integer number of RBs"; ...
     "Configured frequency width"; ...
     "Symbols in the 1 ms grid"; ...
     "RE count in every panel"], ...
    ["patchMHz / (12 × SCS) is an integer"; ...
     "12 × RBs × SCS = patchMHz"; ...
     "SymbolsPerSlot × SlotsPerSubframe"; ...
     "14 × B / 15 kHz"], ...
    resultText, ...
    VariableNames = {'Check','Expected','Result'});

boxChecks

%%
% The figure remains open after its handle is cleared. B4 is self-contained,
% so no B3 calculation variables need to remain in the workspace.

clear boxShapes boxChecks ...
      patchMHz expectedRE ...
      muValues nCases ...
      scs_kHz nrbValues subcarriers slotsPerSubframe symbolsIn1ms ...
      gridK gridL reCount ...
      checkIntegerRBs checkPatchWidth checkGridColumns checkRECount ...
      checkPassed resultText ...
      n mu nrbExact actualPatchMHz ...
      carrier subframeGrid slotGrid slot checker tl
%% B4 — A Real Frame, Counted
% Why it matters
% An NR radio frame lasts 10 ms. This section constructs a complete 10 ms resource 
% grid, fills selected resource elements, and OFDM-modulates the grid into a waveform.
% 
% The waveform contains useful OFDM-symbol samples and cyclic-prefix samples. 
% Therefore, the frame sample count is determined by the sample rate and the fixed 
% 10 ms frame duration:
% 
% $$N_{\mathrm{samples}} = f_s \cdot 10\ \mathrm{ms}$$
% 
% For this 30 kHz, 51-RB example, the toolbox default is expected to use Nfft 
% = 1024. The resulting sample rate is:
% 
% $$f_s = N_{\mathrm{fft}}\Delta f    = 1024 \cdot 30\ \mathrm{kHz}    = 30.72\ 
% \mathrm{MHz}$$
% 
% At 30.72 MHz, a 10 ms frame contains 307200 samples.
% 
% $$307200 = 30.72\ \mathrm{MHz}\cdot10\ \mathrm{ms}$$
% 
% The figure shows the same resource grid supplied to the OFDM modulator. Some 
% resource elements are empty, some carry PDSCH data, and some carry DM-RS reference 
% signals.
% 
% 
% Configuration used here
% The carrier uses 30 kHz subcarrier spacing, 51 resource blocks, and physical 
% cell ID 42. At this numerology, the 10 ms frame contains 20 slots.
% 
% The example places QPSK PDSCH data in a 24-RB bandwidth part (BWP) beginning 
% at common resource block 10. The allocation occupies OFDM symbols 2 through 
% 13 in each slot. DM-RS reference signals occupy selected resource elements within 
% that allocation.
% 
% For this section, interpret the PDSCH and DM-RS configuration as an example 
% of resource elements being occupied. The detailed configuration fields are not 
% needed to understand the frame duration or sample count.
% What to look for
% • The FFT size, Nfft, selected by the toolbox.
% 
% • The waveform sample rate.
% 
% • The total number of waveform samples in the 10 ms frame.
% 
% • The result that sample count divided by sample rate equals 10 ms.
% 
% • Dashed vertical lines marking slot boundaries.
% 
% • Solid vertical lines marking 1 ms subframe boundaries.
% 
% • PDSCH and DM-RS resource elements appearing only inside the configured BWP 
% and symbol allocation.
% Common mistakes
% Nfft is not generally equal to the number of occupied subcarriers. This carrier 
% has 51 RBs, or 612 occupied subcarriers, but 612 is not a power of two. The 
% toolbox selects an FFT size suitable for the configured grid; in this example, 
% the expected default is Nfft = 1024.
% 
% The frame sample count includes cyclic-prefix samples. Counting only useful-symbol 
% samples underestimates the duration and the total number of waveform samples.
% Try it (personal exploration)
% Increase NSizeGrid until the toolbox changes its default FFT size from 1024 
% to 2048. Before running the code, predict the new frame sample count using the 
% selected FFT size, the 30 kHz subcarrier spacing, and the 10 ms frame duration.
% 
% 
% 
% Then compare the prediction with the reported waveform length and verify that 
% the waveform duration remains 10 ms.

%% B4 — Configure the carrier and construct one frame grid

% This carrier represents a 20 MHz FR1 channel configuration at 30 kHz
% subcarrier spacing. NSizeGrid is the occupied grid width in RBs; the
% nominal channel bandwidth also includes guard-band space.
carrier = nrCarrierConfig( ...
    NCellID            = 42, ...
    SubcarrierSpacing  = 30, ...
    CyclicPrefix       = 'normal', ...
    NSizeGrid          = 51, ...
    NStartGrid         = 0);

% This demonstration constructs frame 0. NFrame identifies the 10 ms radio
% frame; NSlot is updated below as each slot is placed into the frame grid.
carrier.NFrame = 0;

% PDSCH is used here only to create an example of occupied REs. The detailed
% meaning of mapping type, RNTI, NID, and modulation is outside this section.
pdsch = nrPDSCHConfig;

% A bandwidth part contains 24 RBs beginning at common resource block 10.
pdsch.NSizeBWP  = 24;
pdsch.NStartBWP = 10;

% PRBSet is numbered relative to the beginning of the BWP. This allocation
% uses every RB in the 24-RB BWP.
pdsch.PRBSet = 0:pdsch.NSizeBWP-1;

% Mapping type A places the allocation relative to the slot timing structure.
pdsch.MappingType = 'A';

% SymbolAllocation uses zero-based symbol indexing. The allocation begins at
% symbol 2 and occupies the remaining 12 symbols of the normal-CP slot.
pdsch.SymbolAllocation = [2 carrier.SymbolsPerSlot-2];

% QPSK maps two coded bits onto each PDSCH modulation symbol.
pdsch.Modulation = 'QPSK';
pdsch.NumLayers  = 1;

% RNTI identifies the intended receiver. An empty NID directs the PDSCH
% configuration to use the physical cell ID from carrier.NCellID.
pdsch.RNTI = 1005;
pdsch.NID  = [];

% A frame contains SlotsPerFrame slots. Each normal-CP slot contains
% SymbolsPerSlot OFDM symbols.
slotsPerFrame  = carrier.SlotsPerFrame;
symbolsPerSlot = carrier.SymbolsPerSlot;

% Preallocate the complete frame grid. The grid has one row per occupied
% subcarrier and one column per OFDM symbol in the 10 ms radio frame.
gridRows         = 12 * carrier.NSizeGrid;
frameSymbolCount = slotsPerFrame * symbolsPerSlot;

% frameGrid holds complex-valued OFDM resource elements for modulation.
% labelMap holds display labels: 0 = empty, 1 = PDSCH, 2 = DM-RS.
frameGrid = complex(zeros(gridRows, frameSymbolCount));
labelMap  = zeros(gridRows, frameSymbolCount);

% Construct one slot at a time, then place that slot in its corresponding
% columns of the complete 10 ms frame grid.
for slotNumber = 0:slotsPerFrame-1

    % nrPDSCHIndices and nrPDSCHDMRSIndices use carrier.NSlot to determine
    % the slot-specific allocation and reference-signal positions.
    carrier.NSlot = slotNumber;

    % nrResourceGrid returns one slot of one-antenna resource elements.
    slotGrid = nrResourceGrid(carrier);

    % slotLabels mirrors slotGrid and is used only for the final figure.
    slotLabels = zeros(size(slotGrid));

    % Obtain PDSCH RE indices and transport-block size information. G is the
    % number of coded bits required by the configured PDSCH allocation.
    [pdschIndices, pdschInfo] = nrPDSCHIndices(carrier, pdsch);

    % Generate placeholder coded bits and map them to QPSK PDSCH symbols.
    % Random bits are sufficient because this section studies grid occupancy,
    % waveform duration, and sample count rather than decoding performance.
    codedBits = randi([0 1], pdschInfo.G, 1);
    pdschSymbols = nrPDSCH(carrier, pdsch, codedBits);

    slotGrid(pdschIndices)   = pdschSymbols;
    slotLabels(pdschIndices) = 1;

    % DM-RS provides known reference symbols for channel estimation. It
    % occupies selected REs within the configured PDSCH allocation.
    dmrsIndices = nrPDSCHDMRSIndices(carrier, pdsch);
    dmrsSymbols = nrPDSCHDMRS(carrier, pdsch);

    slotGrid(dmrsIndices)   = dmrsSymbols;
    slotLabels(dmrsIndices) = 2;

    % Convert a zero-based slot number into the corresponding frame-grid
    % column range. Each slot contributes SymbolsPerSlot columns.
    frameColumns = slotNumber*symbolsPerSlot + (1:symbolsPerSlot);

    frameGrid(:, frameColumns) = slotGrid;
    labelMap(:, frameColumns)  = slotLabels;
end

% Preserve PDSCH information from the final slot. The configured allocation
% is identical in every slot, so these values describe PDSCH per slot.
pdschInfoFinal = pdschInfo;
%%
%% B4 — OFDM-modulate the complete frame

% OFDM modulation requires the carrier slot number to identify the start of
% the supplied grid. frameGrid begins at slot 0 of frame 0.
carrier.NSlot = 0;

% nrOFDMModulate transforms the complete resource grid into a time-domain
% waveform and returns the FFT size and sample rate selected by the toolbox.
[waveform, ofdmInfo] = nrOFDMModulate(carrier, frameGrid);

% The waveform has one column per transmit antenna. This example has one
% antenna, so its row count is the number of time-domain samples.
nSamples = size(waveform, 1);

% Convert the waveform length into a duration for display and verification.
sampleRate_MHz = ofdmInfo.SampleRate / 1e6;
frameDuration_ms = nSamples / ofdmInfo.SampleRate * 1e3;
%%
%% B4 — Verify frame dimensions and waveform duration

% A complete NR radio frame lasts 10 ms. The sample count must therefore
% equal sample rate multiplied by 10 ms, including cyclic-prefix samples.
expectedSamples = round(ofdmInfo.SampleRate * 10e-3);
checkFrameSamples = (nSamples == expectedSamples);

assert(checkFrameSamples, ...
    'The OFDM waveform does not contain exactly 10 ms of samples.');

% The frame grid must contain one 14-symbol normal-CP slot for every slot
% in the 10 ms frame. This confirms that all slots were placed in the grid.
checkFrameSymbols = (size(frameGrid,2) == slotsPerFrame * symbolsPerSlot);

assert(checkFrameSymbols, ...
    'The frame grid does not contain the expected number of OFDM symbols.');

% Every resource block contributes 12 subcarrier rows to the resource grid.
% This confirms that the preallocated grid height matches the carrier.
checkGridRows = (size(frameGrid,1) == 12 * carrier.NSizeGrid);

assert(checkGridRows, ...
    'The frame-grid height does not equal 12*NSizeGrid.');

% QPSK carries two coded bits per modulation symbol. This confirms that the
% PDSCH configuration and index information agree for one slot.
checkQPSKBits = (pdschInfoFinal.G == 2 * pdschInfoFinal.Gd);

assert(checkQPSKBits, ...
    'QPSK should use two coded bits per PDSCH modulation symbol.');

% Nfft = 1024 and 307200 samples are expected for this configuration under
% the current documented default FFT-selection behavior. This is displayed
% as a check, rather than asserted as a universal NR timing requirement.
checkExpectedDefault = (ofdmInfo.Nfft == 1024) && (nSamples == 307200);
%%
%% B4 — Frame and waveform results

% Format display values as text so the Live Editor table avoids unnecessary
% trailing zeroes while the numeric variables remain available for checks.

frameDurationText = compose('%.3f ms', frameDuration_ms);
sampleRateText    = compose('%.2f MHz', sampleRate_MHz);
sampleCountText   = compose('%d samples', nSamples);
fftText           = compose('Nfft = %d', ofdmInfo.Nfft);

% This compact vertical table summarizes the configured frame, the occupied
% grid, the PDSCH allocation, and the resulting OFDM waveform.
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
    [compose('%d kHz SCS, %d RB, cell ID %d', ...
         carrier.SubcarrierSpacing, carrier.NSizeGrid, carrier.NCellID); ...
     compose('%d slots × %d symbols = %d OFDM symbols', ...
         slotsPerFrame, symbolsPerSlot, frameSymbolCount); ...
     compose('%d subcarriers × %d OFDM symbols', ...
         size(frameGrid,1), size(frameGrid,2)); ...
     compose('%d REs (%d REs per PRB)', ...
         pdschInfoFinal.Gd, pdschInfoFinal.NREPerPRB); ...
     compose('%d bits, %s', pdschInfoFinal.G, pdsch.Modulation); ...
     string(num2str(pdschInfoFinal.DMRSSymbolSet)); ...
     fftText; ...
     sampleRateText; ...
     sampleCountText; ...
     frameDurationText], ...
    VariableNames = {'Quantity','Value'});

frameResults
%%
%% B4 — Verification results

% The assertions above stop execution if an invariant fails. This table makes
% the verification results visible in the Live Editor.

checkPassed = [ ...
    checkFrameSamples; ...
    checkFrameSymbols; ...
    checkGridRows; ...
    checkQPSKBits; ...
    checkExpectedDefault];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

frameChecks = table( ...
    ["Waveform sample count"; ...
     "Frame-grid symbol count"; ...
     "Frame-grid row count"; ...
     "QPSK coded-bit count"; ...
     "Expected default FFT result"], ...
    ["SampleRate × 10 ms"; ...
     "SlotsPerFrame × SymbolsPerSlot"; ...
     "12 × NSizeGrid"; ...
     "G = 2 × Gd"; ...
     "Nfft = 1024 and 307200 samples"], ...
    resultText, ...
    VariableNames = {'Check','Expected','Result'});

frameChecks
%% Recap — Two to the Mu (Track 01)
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
% time. The total number of resource elements remains unchanged.
% 
% For the 1 ms × 2.88 MHz example: $N_{\mathrm{RE}} = 2688$
% 
% A radio frame always lasts 10 ms. After OFDM modulation, its sample count 
% is determined by sample rate and frame duration:
% 
% $$N_{\mathrm{RE}} = 14\frac{B}{15\ \mathrm{kHz}} = 2688\qquad \text{for } 
% B = 2.88\ \mathrm{MHz}$$
% 
% 
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
%