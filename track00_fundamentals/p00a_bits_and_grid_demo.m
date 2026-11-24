%% P00a — Grid and Waveform: Bits and Grid
%% From bits to constellation symbols to resource elements
% This demonstration follows the first half of the path that every 5G NR transmission 
% takes: bits become complex modulation symbols, and each symbol is placed in 
% one cell of the OFDM resource grid.
% 
% A resource element (RE) is one subcarrier during one OFDM symbol. Twelve 
% subcarriers form a resource block (RB). A bandwidth part (BWP) is a window 
% of consecutive common resource blocks (CRBs) that a device is set up to use.
%% Guiding question
% How does a pair of bits become a point on the complex plane, and where in 
% the grid does that point go?
% This demonstration
% 1. B1 — Map bits to QPSK and 16-QAM symbols, normalize them to unit average 
% power, and see Gray labels: nearest neighbours differ in exactly one bit.
% 
% 2. B2 — Count the subcarriers in a 51-RB carrier and the REs in one RB over 
% one slot, then convert a PRB number inside a BWP into a CRB number.
% Key relationships
% QPSK takes the first bit for the sign of the real part and the second bit 
% for the sign of the imaginary part:
% 
% $$s = \frac{(1-2b_0) + j\,(1-2b_1)}{\sqrt{2}}$$
% 
% A square constellation with M points carries
% 
% $$\text{bits per symbol} = \log_2 M$$
% 
% One RB over one normal-CP slot holds
% 
% $$N_{\mathrm{RE}} = 12 \times 14 = 168$$
% 
% and a PRB inside a BWP is numbered from the BWP start:
% 
% $$n_{\mathrm{CRB}} = N_{\mathrm{BWP}}^{\mathrm{start}} + n_{\mathrm{PRB}}$$
%% Prerequisites
% • Complex numbers: real (I) and imaginary (Q) parts, magnitude
% 
% • Binary labels and the idea of a bit error
% 
% • What a subcarrier and an OFDM symbol are (at the level of the P00a lecture)
% 
% Scope: this is a fundamentals script. It does not use 5G Toolbox objects and 
% does not model a complete NR link. Numerology μ is left to Track 01; every 
% grid here is the normal-CP, 14-symbol slot.
% Words used in this demo
% • Modulation symbol, constellation, unit average power, and Gray labelling
% (nearest neighbours differ in one bit). QPSK has 4 points; 16-QAM has 16.
%
% • Resource element (RE): one subcarrier during one OFDM symbol. Resource
% block (RB): 12 neighbouring subcarriers. A slot is 14 OFDM symbols (normal
% CP).
%
% • CRB: an RB numbered from the bottom of the carrier, starting at 0. BWP:
% a window of CRBs a device is set up to use. PRB: an RB numbered from the
% bottom of the BWP, starting at 0.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write
% yourself (in the Build it, the Try its, and the exercises) get their own entry;
% small helpers are grouped into families. Figure-only commands sit with the figures.
%
% Commands you write
% • x(a:b:c) and end — Purpose: pick entries from a list. Inputs: a start, an
% optional step, and an end; end means the last entry. Outputs: the chosen
% entries.
%
% • [a b] and [a; b] — Purpose: build a row or stack a column. Inputs: the items.
% Outputs: one list.
%
% • + - * / and 1j — Purpose: arithmetic and the imaginary unit. Inputs: numbers.
% Outputs: the result. sqrt(x) is the square root.
%
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
%
% • log2, abs, real, imag, mean, numel, table, isnan — Purpose: the usual
% math and display helpers in the given cells. Inputs: numbers or arrays.
% Outputs: the computed value or a displayed table.
%
% Read each table and figure against the sentence that follows it.
%% Staging for script

% Clear the workspace and close figures so every run starts from the same state.
clear; close all;
% Fix the random seed so any random values are reproducible.
rng(2026);
%% B1 — Bits become modulation symbols
% New words
% • Modulation symbol: the complex number sent for a small group of bits.
% 
% • Constellation: all the points a modulation can send, drawn on the I-Q plane.
% 
% • Gray labelling: bit labels chosen so closest neighbours differ in one bit.
% Why it matters
% A transmitter cannot send bits directly; it sends complex amplitudes. QPSK 
% has four points and therefore carries two bits per symbol: bit 0 selects the 
% positive sign, bit 1 the negative sign, the first bit sets the real part, and 
% the second bit sets the imaginary part. Dividing by √2 keeps the average symbol 
% power at 1, so changing the modulation order does not silently change the transmit 
% power.
% 
% $$s = \frac{(1-2b_0) + j\,(1-2b_1)}{\sqrt{2}}$$
% 
% Larger constellations pack more bits into each symbol, at the cost of points 
% that sit closer together:
% 
% $$\text{bits per symbol} = \log_2 M$$
% 
% The labels are Gray coded: any two nearest neighbours differ in only one bit. 
% Noise usually moves a received point to a neighbour, so a small slip usually 
% costs one bit, not several. NR 16-QAM (TS 38.211 §5.1.4) uses bits b0 and b2 
% for the real level and b1 and b3 for the imaginary level:
% 
% $$s = \frac{(1-2b_0)\,[2-(1-2b_2)] + j\,(1-2b_1)\,[2-(1-2b_3)]}{\sqrt{10}}$$
% What to look for
% • In the results table, compare the BitsPerSymbol column with log2 of the 
% ConstellationPoints_M column.
% 
% • In the 16-QAM panel, read the four-bit label of any point and of the point 
% next to it horizontally or vertically. Count how many bit positions differ.
% 
% • The highlighted pair in the 16-QAM panel is one such neighbour pair.
% Compare the two labels yourself; do not rely on the caption to name a bit.
% Common mistakes
% Do not drop the 1/√2 (QPSK) or 1/√10 (16-QAM) scale. Without it the points 
% are in the right places but the average power is 2 or 10, not 1.
% 
% Do not assume binary counting order is Gray order. Labelling the 16-QAM levels 
% −3, −1, 1, 3 as 00, 01, 10, 11 puts two bit changes between −1 and 1.
% Try it (personal exploration)
% Use the log2 M rule to predict how many bits one 64-QAM symbol carries, and 
% type that number into myPrediction in the first code line below before you 
% run this section. After the results tables, a given line prints your prediction 
% beside the result.
% 
% Then count, by hand, the closest-neighbour pairs in a 4 × 4 grid of points 
% (pairs side by side in each row, plus pairs one above the other in each column), 
% type it into myPredictionPairs, and compare with the grayResults table.
% 
% Optional: use the 16-QAM equation in Why it matters to work out the label of 
% the point just to the right of the point labelled 0000, then find it in the 
% figure.

% Try it: type your two predictions here (numbers) before running this section.
myPrediction = NaN;
myPredictionPairs = NaN;
% Each row is one two-bit QPSK label. The first column controls I and the
% second column controls Q.
qpskBits = [ ...
    0 0; ...
    0 1; ...
    1 0; ...
    1 1];

% Convert 0/1 bit labels into +/- signs, then normalize QPSK to unit
% average power. A bit value of 0 becomes +1 and a bit value of 1 becomes -1.
qpskSymbols = (1 - 2*qpskBits(:,1) + 1j*(1 - 2*qpskBits(:,2))) / sqrt(2);

% M-ary modulation carries log2(M) bits per symbol. QPSK and 16-QAM bit
% counts are taken from the label arrays, so a mismatch with the constellation
% size can fail. 64-QAM is named only for the Try.
modulationOrder = [4; 16; 64];
bitsPerSymbol = [size(qpskBits, 2); NaN; log2(modulationOrder(3))];

% A square 16-QAM constellation has I and Q levels +/-1 and +/-3. Dividing
% by sqrt(10) gives unit average power for equally likely constellation points.
qam16Levels = [-3 -1 1 3];
[qam16I, qam16Q] = meshgrid(qam16Levels, qam16Levels);
qam16Symbols = (qam16I(:) + 1j*qam16Q(:)) / sqrt(10);

% Check the specific QPSK examples stated in the narration.
checkQpsk00 = abs(qpskSymbols(1) - (1 + 1j)/sqrt(2)) < 1e-12;
checkQpsk01 = abs(qpskSymbols(2) - (1 - 1j)/sqrt(2)) < 1e-12;

% Check that both constellations have unit average power.
checkQpskPower = abs(mean(abs(qpskSymbols).^2) - 1) < 1e-12;
checkQam16Power = abs(mean(abs(qam16Symbols).^2) - 1) < 1e-12;

assert(checkQpsk00, 'QPSK bits [0 0] should map to (1+j)/sqrt(2). Look first at the sign rule in qpskSymbols: bit 0 should give +, bit 1 should give -.');
assert(checkQpsk01, 'QPSK bits [0 1] should map to (1-j)/sqrt(2). Look first at which bit sets the imaginary part: it should be the second column of qpskBits.');
assert(checkQpskPower, 'The QPSK constellation should have unit average power. Look first at the / sqrt(2) scale. Common mistake: dropping the scale.');
assert(checkQam16Power, 'The 16-QAM constellation should have unit average power. Look first at the / sqrt(10) scale on qam16Symbols. Common mistake: dropping the scale.');

% NR 16-QAM Gray labels (TS 38.211 §5.1.4). Row n holds bits b0 b1 b2 b3
% for one constellation point; dec2bin lists all sixteen four-bit words.
qam16GrayBits = dec2bin(0:15, 4) - '0';
bitsPerSymbol(2) = size(qam16GrayBits, 2);
checkBitsQpsk = 2^bitsPerSymbol(1) == numel(qpskSymbols);
checkBits16 = 2^bitsPerSymbol(2) == size(qam16GrayBits, 1);
assert(checkBitsQpsk, ...
    'The QPSK bit-label width does not name four points. Look first at size(qpskBits, 2) and numel(qpskSymbols).');
assert(checkBits16, ...
    'The 16-QAM bit-label width does not name sixteen points. Look first at size(qam16GrayBits, 2) and the number of labels.');

% b0 and b2 set the real level; b1 and b3 set the imaginary level.
qam16GraySymbols = ((1 - 2*qam16GrayBits(:,1)) .* (2 - (1 - 2*qam16GrayBits(:,3))) + ...
    1j*(1 - 2*qam16GrayBits(:,2)) .* (2 - (1 - 2*qam16GrayBits(:,4)))) / sqrt(10);

% The Gray-labelled points must be the same sixteen points as the unlabelled
% meshgrid constellation above; only the labels are new.
nearestMatch = min(abs(qam16GraySymbols.' - qam16Symbols), [], 1);
checkGraySamePoints = all(nearestMatch < 1e-12);

% Nearest neighbours in 16-QAM are 2/sqrt(10) apart. Count the bit positions
% that differ between every pair of points, then keep only neighbour pairs.
neighbourDistance = 2 / sqrt(10);
pairDistance = abs(qam16GraySymbols - qam16GraySymbols.');
isNeighbour = abs(pairDistance - neighbourDistance) < 1e-9;
bitDifferences = sum(abs(permute(qam16GrayBits, [1 3 2]) - ...
    permute(qam16GrayBits, [3 1 2])), 3);
neighbourPairCount = nnz(isNeighbour) / 2;

checkGrayNeighbours = all(bitDifferences(isNeighbour) == 1);
% Second counting route, with no number written in: count side-by-side pairs
% (same Q level, one I step apart) and one-above-the-other pairs (same I
% level, one Q step apart) separately, then add them.
levelStep = 2 / sqrt(10);
gapI = abs(real(qam16GraySymbols) - real(qam16GraySymbols.'));
gapQ = abs(imag(qam16GraySymbols) - imag(qam16GraySymbols.'));
sideBySidePairs = nnz(abs(gapI - levelStep) < 1e-9 & gapQ < 1e-9) / 2;
aboveBelowPairs = nnz(abs(gapQ - levelStep) < 1e-9 & gapI < 1e-9) / 2;
checkNeighbourPairCount = neighbourPairCount == sideBySidePairs + aboveBelowPairs;

assert(checkGraySamePoints, ...
    'The Gray-labelled 16-QAM points do not match the 16-QAM constellation. Look first at the 2 - (1 - 2b) level terms and the / sqrt(10) scale in qam16GraySymbols.');
assert(checkGrayNeighbours, ...
    'Some nearest-neighbour 16-QAM points differ in more than one bit, so the labels are not Gray coded. Look first at which bits set the real level: b0 and b2, not b0 and b1. Common mistake: binary counting order.');
assert(checkNeighbourPairCount, ...
    'The neighbour-pair count from distances does not match the side-by-side plus one-above-the-other count. Look first at neighbourDistance: closest points are 2/sqrt(10) apart.');

% Summarize bits per symbol for the three modulation orders, plus the Gray
% neighbour count, so the table can be read against log2(M).
modulationResults = table( ...
    ["QPSK"; "16-QAM"; "64-QAM"], ...
    modulationOrder, ...
    bitsPerSymbol, ...
    VariableNames = {'Modulation','ConstellationPoints_M','BitsPerSymbol'});

modulationResults

% Summarize the Gray check: how many neighbour pairs exist and how many bits
% differ across them (both numbers should be read against the Try-it prediction).
grayResults = table( ...
    ["Nearest-neighbour pairs in 16-QAM"; ...
     "Bit differences between neighbours"], ...
    [string(neighbourPairCount); ...
     string(sprintf('%d to %d', min(bitDifferences(isNeighbour)), max(bitDifferences(isNeighbour))))], ...
    VariableNames = {'Quantity','Value'});

grayResults

% Compare your Try-it predictions with the results, side by side.
if isnan(myPrediction) || isnan(myPredictionPairs)
    disp('No prediction recorded: type a number into myPrediction and myPredictionPairs at the top of this section and run this section again.')
else
    predCompare = table( ...
        ["64-QAM bits per symbol"; "Nearest-neighbour pairs"], ...
        [myPrediction; myPredictionPairs], ...
        [bitsPerSymbol(3); neighbourPairCount], ...
        VariableNames = {'Quantity','YouPredicted','Result'});
    predCompare
end

%% B1 — After the run
% Read BitsPerSymbol against log2 of the constellation size. In the Gray
% table, every neighbour pair should differ in exactly one bit: the most
% likely noise error, a slip to the next point, then corrupts one bit.

%% B1 — Verification results

% The assertions above stop execution if a relationship fails. This table
% makes the successful checks visible in the Live Editor.
checkPassed = [ ...
    checkQpsk00; ...
    checkQpsk01; ...
    checkQpskPower; ...
    checkQam16Power; ...
    checkBitsQpsk; ...
    checkBits16; ...
    checkGraySamePoints; ...
    checkGrayNeighbours; ...
    checkNeighbourPairCount];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

modulationChecks = table( ...
    ["QPSK mapping for bits [0 0]"; ...
     "QPSK mapping for bits [0 1]"; ...
     "QPSK average power"; ...
     "16-QAM average power"; ...
     "QPSK labels cover the points"; ...
     "16-QAM labels cover the points"; ...
     "Gray labels on the same 16 points"; ...
     "Gray neighbours"; ...
     "Neighbour-pair count"], ...
    ["(1 + j) / sqrt(2)"; ...
     "(1 - j) / sqrt(2)"; ...
     "1"; ...
     "1"; ...
     "2^(bit width) equals the number of points"; ...
     "2^(bit width) equals the number of labels"; ...
     "Same points as the 16-QAM grid"; ...
     "Every neighbour pair differs in one bit"; ...
     "Distance count equals side-by-side plus above-below"], ...
    [string(qpskSymbols(1)); ...
     string(qpskSymbols(2)); ...
     string(mean(abs(qpskSymbols).^2)); ...
     string(mean(abs(qam16Symbols).^2)); ...
     string(numel(qpskSymbols)); ...
     string(size(qam16GrayBits, 1)); ...
     string(checkGraySamePoints); ...
     string(checkGrayNeighbours); ...
     string(neighbourPairCount)], ...
    resultText, ...
    VariableNames = {'Check','Expected','Actual','Pass'});

modulationChecks
%% B1 — Constellation figures
% Left: QPSK with its two-bit labels. Right: 16-QAM with all sixteen Gray labels; 
% the highlighted pair shows one bit changing between neighbours.

figure( ...
    Name = 'P00a - QPSK and Gray-labelled 16-QAM', ...
    Color = 'w', ...
    Position = [100 100 1100 480]);

tiledlayout(1,2, TileSpacing='loose', Padding='compact');

nexttile;
plot(real(qpskSymbols), imag(qpskSymbols), 'o', ...
    MarkerSize=9, MarkerFaceColor=[0.20 0.40 0.80]);
grid on; axis equal;
xlim([-1.4 1.4]); ylim([-1.4 1.4]);
xlabel('In-phase component');
ylabel('Quadrature component');
title({'QPSK: two bits per symbol', 'first bit sets I, second bit sets Q'});

text(real(qpskSymbols)+0.06, imag(qpskSymbols), ...
    ["00"; "01"; "10"; "11"]);

nexttile;
plot(real(qam16GraySymbols), imag(qam16GraySymbols), 'o', ...
    MarkerSize=7, MarkerFaceColor=[0.90 0.45 0.10]);
hold on;
grid on; axis equal;
xlim([-1.3 1.3]); ylim([-1.3 1.3]);

% Write each point's four-bit Gray label (b0 b1 b2 b3) just above the point.
grayLabels = string(char(qam16GrayBits + '0'));
text(real(qam16GraySymbols), imag(qam16GraySymbols) + 0.09, grayLabels, ...
    HorizontalAlignment='center', FontSize=8);

% Highlight one neighbour pair (vertical, not the optional Try's
% right-of-0000 pair) so the figure shows a one-bit neighbour without
% naming the optional item.
pairA = qam16GraySymbols(bin2dec('0000') + 1);
pairB = qam16GraySymbols(bin2dec('0001') + 1);
plot(real([pairA pairB]), imag([pairA pairB]), '-', ...
    Color=[0.10 0.55 0.25], LineWidth=2.5);
text(mean(real([pairA pairB])), mean(imag([pairA pairB])) - 0.18, 'one neighbour pair', ...
    HorizontalAlignment='center', Color=[0.10 0.55 0.25], FontWeight='bold');
hold off;

xlabel('In-phase component');
ylabel('Quadrature component');
title({'16-QAM, Gray labels b_0b_1b_2b_3:', 'neighbours differ in exactly one bit'});
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.
% B2 does not use B1 values. The figure remains open after its variables
% are cleared.
clear modulationResults grayResults modulationChecks myPrediction myPredictionPairs predCompare ...
    levelStep gapI gapQ sideBySidePairs aboveBelowPairs ...
    checkBitsQpsk checkBits16 ...    levelStep gapI gapQ sideBySidePairs aboveBelowPairs ...
      qpskBits qpskSymbols ...
      modulationOrder bitsPerSymbol ...
      qam16Levels qam16I qam16Q qam16Symbols ...
      qam16GrayBits qam16GraySymbols nearestMatch ...
      neighbourDistance pairDistance isNeighbour bitDifferences neighbourPairCount ...
      grayLabels pairA pairB ...
      checkQpsk00 checkQpsk01 checkQpskPower checkQam16Power ...
      checkGraySamePoints checkGrayNeighbours checkNeighbourPairCount ...
      checkPassed resultText
%% B2 — Resource elements, resource blocks, and BWP numbering
% New words
% • Resource element (RE): one subcarrier during one OFDM symbol.
% 
% • Resource block (RB): twelve neighbouring subcarriers.
% 
% • Bandwidth part (BWP): a window of CRBs a device is set up to use; PRBs are 
% counted from its bottom edge (see Words used in this demo).
% Why it matters
% Each modulation symbol occupies one resource element: one subcarrier during 
% one OFDM symbol. Grouping twelve subcarriers into a resource block gives the 
% scheduler a coarser unit to hand out, so it does not have to address every 
% RE separately. With normal cyclic prefix, one slot has 14 OFDM symbols:
% 
% $$N_{\mathrm{RE}} = 12 \times 14 = 168$$
% 
% Common resource blocks (CRBs) are numbered across the whole carrier. A bandwidth 
% part is a window of consecutive CRBs that a device is set up to use, so a device 
% can work on a narrower slice than the full carrier. Physical resource blocks 
% (PRBs) are numbered again from the start of that window:
% 
% $$n_{\mathrm{CRB}} = N_{\mathrm{BWP}}^{\mathrm{start}} + n_{\mathrm{PRB}}$$
% What to look for
% • In the results table, compare the carrier width in subcarriers with 12 × 
% the number of RBs, and the "One RB in one slot" row with 12 × 14.
% 
% • In the left panel, the dashed lines mark the BWP edges and the green band 
% marks the example PRB. Read its CRB number off the axis, counting from CRB 0 
% at the bottom.
% 
% • In the right panel, count the cells of the zoomed RB: rows are subcarriers, 
% columns are OFDM symbols, and one cell is outlined as a single RE.
% Common mistakes
% Do not treat a PRB number as a CRB number. PRB numbering restarts at the BWP 
% start, so the same PRB index lands on different CRBs in different BWPs.
% 
% Do not count resource blocks in subcarriers or REs in RBs: an RB is 12 subcarriers 
% wide in frequency only, and it becomes 168 REs only once you also fix one slot 
% of 14 symbols.
% Try it (personal exploration)
% Use the PRB-to-CRB equation to predict the CRB number of PRB 5 in a BWP 
% that starts at CRB 10, and type it into myPrediction below before you run 
% this section. A given line after the results table prints your prediction 
% beside the result.
% 
% Then change examplePRB to 23, the last PRB of this BWP, predict again with 
% the same equation, and run. The CRB check reads the answer back from the grid, 
% so it holds for any PRB inside the BWP; only your printed prediction changes.

% Try it: type your prediction here (a number) before running this section.
myPrediction = NaN;
% The carrier example used throughout Track 01 has 51 resource blocks.
carrierRBs = 51;
subcarriersPerRB = 12;
symbolsPerSlot = 14;

% Convert the carrier width from RBs to subcarriers.
carrierSubcarriers = carrierRBs * subcarriersPerRB;

% Count REs in one RB over one normal-CP slot.
rePerRBPerSlot = subcarriersPerRB * symbolsPerSlot;

% This example BWP begins at CRB 10. PRB numbers count from the BWP's first
% CRB, not from the bottom of the carrier.
nStartBWP = 10;
examplePRB = 5;
correspondingCRB = nStartBWP + examplePRB;

% Build a schematic 24-RB BWP inside the 51-RB carrier. This is not a
% channel allocation; it is a visual vocabulary aid.
bwpRBs = 24;
bwpFirstSubcarrier = nStartBWP * subcarriersPerRB + 1;
bwpLastSubcarrier = (nStartBWP + bwpRBs) * subcarriersPerRB;

schematicGrid = zeros(carrierSubcarriers, symbolsPerSlot);
schematicGrid(bwpFirstSubcarrier:bwpLastSubcarrier, :) = 1;

checkCarrierHeight = carrierSubcarriers == 612;
checkRECount = rePerRBPerSlot == 168;
% Read the CRB back from the grid instead of trusting the equation: find the
% BWP's subcarriers in schematicGrid, take the first subcarrier of the example
% PRB, and see which 12-subcarrier block of the carrier it falls in.
bwpSubcarrierRows = find(schematicGrid(:, 1) == 1);
prbFirstRow = bwpSubcarrierRows(examplePRB * subcarriersPerRB + 1);
crbFromGrid = floor((prbFirstRow - 1) / subcarriersPerRB);
checkCRBNumbering = crbFromGrid == correspondingCRB;
checkBWPInsideCarrier = bwpLastSubcarrier <= carrierSubcarriers;

assert(checkCarrierHeight, 'A 51-RB carrier should contain 612 subcarriers. Look first at carrierRBs and subcarriersPerRB (12 subcarriers per RB).');
assert(checkRECount, 'One RB over one normal-CP slot should contain 168 REs. Look first at symbolsPerSlot (14 for normal CP). Common mistake: counting REs in RBs.');
assert(checkCRBNumbering, 'The CRB read back from the grid does not match correspondingCRB. Look first at examplePRB (it must be less than bwpRBs) and nStartBWP. Common mistake: treating a PRB number as a CRB number.');
assert(checkBWPInsideCarrier, 'The configured BWP must fit inside the carrier. Look first at nStartBWP + bwpRBs: it must not exceed carrierRBs.');

% Summarize the grid vocabulary numbers in one table.
gridResults = table( ...
    ["Carrier width"; ...
     "Normal-CP slot width"; ...
     "One RB in one slot"; ...
     "BWP start"; ...
     "Example PRB"; ...
     "Corresponding CRB"], ...
    [compose('%d RB = %d subcarriers', carrierRBs, carrierSubcarriers); ...
     compose('%d OFDM symbols', symbolsPerSlot); ...
     compose('%d REs', rePerRBPerSlot); ...
     compose('CRB %d', nStartBWP); ...
     compose('PRB %d within the BWP', examplePRB); ...
     compose('CRB %d', correspondingCRB)], ...
    VariableNames = {'Quantity','Value'});

gridResults

% Compare your Try-it prediction with the result, side by side.
if isnan(myPrediction)
    disp('No prediction recorded: type a number into myPrediction at the top of this section and run this section again.')
else
    predCompare = table(myPrediction, correspondingCRB, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
end
%% B2 — After the run
% Read the carrier-width and RB-slot rows against 12 subcarriers per RB and
% 14 symbols per slot. Read the Corresponding CRB row against the PRB-to-CRB
% equation, and check that the green band in the figure sits on that CRB.
%% B2 — Verification results

% The assertions above stop execution if a relationship fails. This table
% makes the successful checks visible in the Live Editor.
checkPassed = [ ...
    checkCarrierHeight; ...
    checkRECount; ...
    checkCRBNumbering; ...
    checkBWPInsideCarrier];

resultText = repmat("Pass", numel(checkPassed), 1);
resultText(~checkPassed) = "Fail";

gridChecks = table( ...
    ["Carrier height"; ...
     "REs in one RB and one slot"; ...
     "PRB-to-CRB numbering"; ...
     "BWP placement"], ...
    ["RBs times 12 subcarriers"; ...
     "12 subcarriers times 14 symbols"; ...
     "CRB read from the grid equals NStartBWP + PRB"; ...
     "BWP ends within the carrier"], ...
    [string(carrierSubcarriers); ...
     string(rePerRBPerSlot); ...
     string(crbFromGrid); ...
     string(bwpLastSubcarrier)], ...
    resultText, ...
    VariableNames = {'Check','Expected','Actual','Pass'});

gridChecks
%% B2 — Resource-grid vocabulary figure
% Left: the whole 51-RB carrier for one slot, with the 24-RB BWP and the example 
% PRB marked. Right: a zoom on that one RB, showing its 12 × 14 = 168 REs. 
% The colours are a vocabulary aid, not a channel allocation.

figure( ...
    Name = 'P00a - Carrier, BWP, PRB, and RE vocabulary', ...
    Color = 'w', ...
    Position = [100 100 1150 560]);

tiledlayout(1,2, TileSpacing='loose', Padding='compact');

% Mark the example PRB with display value 2 so it stands out from the BWP.
exampleFirstSubcarrier = correspondingCRB * subcarriersPerRB + 1;
exampleLastSubcarrier = (correspondingCRB + 1) * subcarriersPerRB;
vocabularyGrid = schematicGrid;
vocabularyGrid(exampleFirstSubcarrier:exampleLastSubcarrier, :) = 2;

nexttile;
imagesc(0:symbolsPerSlot-1, 0:carrierRBs-1, ...
    vocabularyGrid(1:subcarriersPerRB:end, :));
axis xy;
colormap(gca, [1.00 1.00 1.00; 0.20 0.40 0.80; 0.10 0.65 0.30]);
clim([0 2]);
hold on;
yline(nStartBWP - 0.5, '--k', 'BWP start = CRB 10', LabelHorizontalAlignment='left');
yline(nStartBWP + bwpRBs - 0.5, '--k', 'BWP end', LabelHorizontalAlignment='left');
text(symbolsPerSlot/2 - 0.5, correspondingCRB + 1.6, ...
    sprintf('PRB %d of the BWP = CRB %d', examplePRB, correspondingCRB), ...
    HorizontalAlignment='center', FontWeight='bold', Color=[0.10 0.45 0.20]);
hold off;
xlabel('OFDM symbol in one slot');
ylabel('Common resource block (CRB) index');
title({'51-RB carrier, one slot:', 'a 24-RB BWP starting at CRB 10'});

nexttile;
% Show only the example RB: 12 subcarriers by 14 symbols, one cell per RE.
% Alternate values only make RE boundaries visible; they are not data.
zoomGrid = mod((0:subcarriersPerRB-1).' + (0:symbolsPerSlot-1), 2);
imagesc(0:symbolsPerSlot-1, 0:subcarriersPerRB-1, zoomGrid);
axis xy;
colormap(gca, [0.85 0.93 0.87; 0.70 0.86 0.75]);
hold on;
% Outline one RE: subcarrier 0 of the RB during OFDM symbol 3.
rectangle(Position=[3-0.5, 0-0.5, 1, 1], EdgeColor='r', LineWidth=2.5);
text(3, -1.1, 'one RE', HorizontalAlignment='center', Color='r', FontWeight='bold');
hold off;
ylim([-1.8 subcarriersPerRB-0.5]);
xlabel('OFDM symbol in one slot');
ylabel('Subcarrier within the RB');
title({['Zoom on CRB ' num2str(correspondingCRB) ': 12 subcarriers \times 14 symbols'], ...
    sprintf('= %d resource elements', rePerRBPerSlot)});
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.
% Figures and displayed tables remain open after the beat-local variables
% are cleared. The Build it section follows.
clear gridResults gridChecks myPrediction predCompare ...
    bwpSubcarrierRows prbFirstRow crbFromGrid ...
      carrierRBs subcarriersPerRB symbolsPerSlot carrierSubcarriers ...
      rePerRBPerSlot nStartBWP examplePRB correspondingCRB ...
      bwpRBs bwpFirstSubcarrier bwpLastSubcarrier schematicGrid ...
      exampleFirstSubcarrier exampleLastSubcarrier vocabularyGrid zoomGrid ...
      checkCarrierHeight checkRECount checkCRBNumbering checkBWPInsideCarrier ...
      checkPassed resultText
%% Build it — Map bits to QPSK symbols
% Competency: turn a row of bits into unit-power QPSK symbols with the B1 sign 
% rule.
% Problem
% You are given myBits, a row of 12 bits. Build qpskOut, a row of complex 
% symbols, one for each pair of bits. Each pair of bits makes one symbol: the first bit of the pair sets 
% the sign of the real part, the second bit sets the sign of the imaginary part 
% (bit 0 gives plus, bit 1 gives minus), and every symbol is divided by √2 so 
% the average power is 1.
% Allowed commands
% Square brackets [ ] to build a row; indexing x(a:b:c) and end; numel; the 
% arithmetic operators + - * /; 1j; sqrt; disp; fprintf; plot; text. Nothing 
% else is needed.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at.
%% Stage 1 — switch it on
% Delete the % in front of the two code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myBits = [0 1 1 1 0 0 1 0 1 1 0 1];   % twelve bits, read left to right
% disp(myBits)
%% Stage 1 check (given)
if ~exist('myBits','var')
    disp('Stage 1 not done: delete the % in front of the two code lines above, then run that section.')
else
    assert(mod(numel(myBits), 2) == 0, ...
        'myBits should hold an even number of bits, because QPSK takes them in pairs. Did you delete a bit?')
    disp('Stage 1 OK')
end
%% Stage 2 — name and shape: split the bits into first and second bits of each pair
% Rename x and y to the names in the problem: firstBits takes bits 1, 3, 5, 
% ... and secondBits takes bits 2, 4, 6, ...
% Pass: Stage 2 OK, and both rows have half as many bits as myBits.

% x = myBits(1:2:end);   % every second bit, starting at bit 1
% y = myBits(2:2:end);   % every second bit, starting at bit 2
%% Stage 2 check (given; the check takes a different route from yours)
if ~exist('firstBits','var') || ~exist('secondBits','var')
    disp('Stage 2 not done: rename x and y to firstBits and secondBits, uncomment, and run.')
else
    pairs = reshape(myBits, 2, []);   % row 1 = first bits, row 2 = second bits
    assert(numel(firstBits) == numel(myBits)/2 && numel(secondBits) == numel(myBits)/2, ...
        'firstBits and secondBits should each hold half the bits. Look at the 1:2:end and 2:2:end steps.')
    assert(isequal(firstBits, pairs(1,:)) && isequal(secondBits, pairs(2,:)), ...
        'The bits are in the wrong rows. firstBits should start at bit 1 and secondBits at bit 2.')
    disp('Stage 2 OK')
end
%% Stage 3 — predict, then build the QPSK mapping
% First type your prediction: in which quadrant of the I-Q plane will symbol
% 2 (made from bits 3 and 4 of myBits) land? Number the quadrants 1 to 4, going
% anticlockwise from the top right (1: I and Q both positive). Use the sign rule
% only. Then build a +1/−1 list from firstBits and a +1/−1 list from secondBits,
% combine them into complex symbols, and scale to unit average power.
% Pass: your prediction and the quadrant sit side by side in a table, and Stage 3 OK.

% myPrediction = ___;
% iSigns = ___;          % +1 or −1 from firstBits
% qSigns = ___;          % +1 or −1 from secondBits
% qpskOut = (___ + 1j*___) / ___;
%% Stage 3 check (given; the check uses a lookup table, a different route from yours)
if ~exist('qpskOut','var') || ~exist('myPrediction','var') || isnan(myPrediction)
    disp('Stage 3 not done: type a numeric prediction into myPrediction, fill the blanks, uncomment, and run.')
else
    % Quadrant of symbol 2, worked out from its angle (a different route).
    quadrantOfSymbol2 = 1 + mod(floor(angle(qpskOut(2)) / (pi/2)), 4);
    predCompare = table(myPrediction, quadrantOfSymbol2, ...
        VariableNames = {'YouPredicted','Result'});
    predCompare
    lookup = [1+1j, 1-1j, -1+1j, -1-1j] / sqrt(2);   % labels 00, 01, 10, 11
    oracle = lookup(2*firstBits + secondBits + 1);
    assert(abs(mean(abs(qpskOut).^2) - 1) < 1e-12, ...
        'The average power is not 1. Common mistake: dropping the 1/sqrt(2) scale.')
    swapped = (imag(qpskOut) + 1j*real(qpskOut));
    assert(~(max(abs(swapped - oracle)) < 1e-12 && max(abs(qpskOut - oracle)) > 1e-12), ...
        'Real and imaginary parts are swapped. The first bit of each pair sets the real part.')
    assert(max(abs(qpskOut - oracle)) < 1e-12, ...
        'Some symbols have the wrong sign. Check that bit 0 gives plus and bit 1 gives minus.')
    disp('Stage 3 OK')
end
%% Stage 4 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('qpskOut','var') || ~exist('oracle','var')
    disp('Stage 4 needs Stages 1 to 3 first: finish them, then Run All.')
else
    % Each flag is computed from your result, so the table cannot say Pass by itself.
    buildFlags = [numel(qpskOut) == numel(myBits)/2; ...
        abs(mean(abs(qpskOut).^2) - 1) < 1e-12; ...
        max(abs(qpskOut - oracle)) < 1e-12];
    buildResult = repmat("Fail", numel(buildFlags), 1);
    buildResult(buildFlags) = "Pass";

    % Asserts above stop the run on failure; this table makes the passes visible.
    buildChecks = table(["Symbol count"; "Average power"; "Signs match the rule"], ...
        ["half the number of bits"; "1"; "same as the 00/01/10/11 lookup"], ...
        [string(numel(qpskOut)); string(mean(abs(qpskOut).^2)); string(max(abs(qpskOut - oracle)))], ...
        buildResult, VariableNames = {'Check','Expected','Actual','Pass'});
    buildChecks

    figure(Name = 'P00a Build it - my QPSK mapper', Color = 'w');
    plot(real(qpskOut), imag(qpskOut), 'o', MarkerSize = 10, MarkerFaceColor = [0.20 0.40 0.80]);
    hold on;
    text(real(qpskOut) + 0.07, imag(qpskOut), ...
        compose('%d%d', firstBits(:), secondBits(:)));
    hold off;
    grid on; axis equal;
    xlim([-1.4 1.4]); ylim([-1.4 1.4]);
    xlabel('In-phase (real) part');
    ylabel('Quadrature (imaginary) part');
    title('My QPSK mapper: first bit sets I, second bit sets Q');
end
%% Build it — Interpretation
% Your interpretation (write one or two sentences here): why do all six symbols
% land on only four points, and why are they all the same distance from the centre?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. The check uses your
% symbols and does not print a model sentence.
myAnswer = NaN;   % how many distinct points do the six symbols occupy?
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('qpskOut','var')
    disp('Run Stages 1 to 4 first, then return here.')
else
    nDistinct = numel(unique(round(qpskOut, 10)));
    okInterp = (myAnswer == nDistinct);
    interpCheck = table("Distinct points among the symbols you built", ...
        okInterp, VariableNames = {'Check','Pass'});
    interpCheck
end
%% Build it — Cleanup
% If a later section says a variable is undefined, run the script from the top
% (Run All). Figures remain open. Names the Review needs are not used here.
clear buildFlags buildResult buildChecks predCompare oracle lookup ...
    nDistinct okInterp interpCheck myAnswer quadrantOfSymbol2 swapped
%% Follow-on exercises
% These go one step past the beats: a new value, or a diagnosis. Copying a
% block from above and changing one number will not answer them. The checks
% do not print a model value.
%% E1 — New value
% A square constellation has 256 points and uses the same log2 M rule as B1.
% How many bits does one symbol carry? Type that number into myAnswer, then
% run this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE1 = abs(myAnswer - log2(256)) < 1e-12;
    e1Check = table("E1 bits per symbol", okE1, VariableNames = {'Check','Pass'});
    e1Check
end
%% E2 — Diagnosis
% A classmate's QPSK points sit in the right places, but their average power
% is 2 instead of 1. What factor did they most likely drop? Type that factor
% as a number into myAnswer, then run this section.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer in this section, then run it again.')
else
    okE2 = abs(myAnswer - sqrt(2)) < 1e-12;
    e2Check = table("E2 dropped scale", okE2, VariableNames = {'Check','Pass'});
    e2Check
end
%% Exercise cleanup
clear myAnswer okE1 e1Check okE2 e2Check
%% Recap — P00a Grid and Waveform: Bits and Grid
% Bits become complex symbols, and each symbol sits in one resource element of
% the grid.
% Key relationships
% QPSK sets the signs of I and Q from two bits and scales by √2:
%
% $$s = \frac{(1-2b_0) + j\,(1-2b_1)}{\sqrt{2}}$$
%
% A constellation with M points carries
%
% $$\text{bits per symbol} = \log_2 M$$
%
% One RB over one normal-CP slot holds
%
% $$N_{\mathrm{RE}} = 12 \times 14$$
%
% and PRBs are numbered from the BWP start:
%
% $$n_{\mathrm{CRB}} = N_{\mathrm{BWP}}^{\mathrm{start}} + n_{\mathrm{PRB}}$$
% What this means in practice
% • Higher-order modulation carries more bits per RE but packs points closer,
% so it needs a cleaner channel. Gray labels keep a typical noise slip down to
% one bit error.
%
% • Unit average power means changing the modulation does not change the transmit
% power by accident.
%
% • A scheduler hands out RBs, and one RB-slot is the 12-by-14 product of REs,
% before any pilots or control are taken out.
%
% • A device configured with a BWP counts PRBs from the BWP start; converting
% to CRBs means adding the BWP's starting CRB.
%
% • You built a QPSK mapper: it turns any even-length row of bits into unit-power
% symbols and passes the same checks as B1.
%
% • Next in the album: the OFDM-and-CP half of P00a.
%% Review — self-check
% Collapse or scroll past the Recap so it is out of sight, then write from
% memory, in your own words. Do not look back until you have written what you
% can. Nothing in the written lists below is graded by the script.
%
% First, restate each Key relationship from the front of the file, one line
% each. Then, for each command you write yourself (x(a:b:c) and end; [a b] and
% [a; b]; + - * / and 1j, including sqrt), give its purpose, its inputs, and
% its outputs. When you have written all you can, scroll up to Key relationships
% and Key code terms and compare. Mark anything you missed.
% My key relationships
% 1.
%
% 2.
%
% 3.
%
% 4.
% Commands I write (purpose; inputs; outputs)
% • x(a:b:c) and end:
%
% • [a b] and [a; b]:
%
% • + - * / and 1j, sqrt:
% What I missed, and where to reread it
%
%% Review — retrieval
% Still keeping the Recap collapsed, type a number into myAnswer and run this
% section. From your complex-number background, what is the magnitude of
% (1 + j)/√2? The check uses a second route and does not print a model value.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    magFromParts = sqrt(real((1+1j)/sqrt(2))^2 + imag((1+1j)/sqrt(2))^2);
    okReview = abs(myAnswer - magFromParts) < 1e-6;
    reviewCheck = table("Magnitude of (1+j)/sqrt(2)", okReview, ...
        VariableNames = {'Check','Pass'});
    reviewCheck
end
