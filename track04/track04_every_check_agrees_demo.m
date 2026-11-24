%% track04_every_check_agrees_demo
%% Every Check Agrees (album track 04): LDPC base graphs, lifting, soft decoding, and the CRC
% This demonstration follows one block of data bits through the code that 
% protects it on the 5G data channel. The code is LDPC (low-density parity 
% check): thousands of small parity checks, each on a handful of bits.
% 
% The sender picks one of two base graphs, lifts it to the block's size, adds 
% a CRC, and encodes. The receiver passes soft beliefs back and forth until 
% every check agrees. And then it asks the CRC whether the word it found is 
% the one that was sent.
%% Guiding question
% How does a block of bits survive the noise, and why is "every parity check 
% agrees" not yet proof that it did?
% This demonstration
% 1. B1 — Which base graph? Check the toolbox's choice against the rule in 
% TS 38.212 for five (A, R) points.
% 
% 2. B2 — Lift, segment, encode: read Zc, K, and N for each graph, and split 
% a large block into two code blocks.
% 
% 3. B3 — Soft bits in, iterations out: decode one block at three SNRs and 
% count the iterations and the bit errors.
% 
% 4. B4 — The trap: a valid LDPC codeword that passes every check, and the 
% CRC that still rejects it.
% 
% 5. Build it — Pick the base graph for a new block by the rule, work out its 
% lifted sizes and filler bits, encode it, and catch a wrong bit with the CRC.
% Key relationships
% A word c is an LDPC codeword when every parity check of the code is met:
% 
% $$\mathbf{H}\,\mathbf{c}^{T} = \mathbf{0}\pmod 2$$
% 
% Base graph 2 (BG2) is used when, for A payload bits at target code rate R,
% 
% $$A \le 292,\quad\text{or}\quad A \le 3824\ \text{and}\ R \le 0.67,\quad\text{or}\quad R \le 0.25;$$
% 
% otherwise base graph 1 (BG1). Lifting by Zc sets the block sizes:
% 
% $$\text{BG1: } K = 22Z_c,\ N = 66Z_c \qquad \text{BG2: } K = 10Z_c,\ N = 50Z_c$$
% 
% For one code block, Zc is the smallest lifting size with K_b Z_c ≥ B, where 
% B = A + the CRC bits. K_b is 22 for BG1; for BG2 it is 10 if B > 640, 9 if 
% B > 560, 8 if B > 192, and 6 otherwise. The lifting sizes are 2 to 16, then 
% 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64 72 80 88 96 104 112 120 128 
% 144 160 176 192 208 224 240 256 288 320 352 384 (or read Zc from nrDLSCHInfo).
% 
% For a BPSK bit x = 1 − 2b received as y in noise of variance σ², the soft 
% bit compares how likely y is under each bit:
% 
% $$\mathrm{LLR} = \ln\frac{p(y\mid b=0)}{p(y\mid b=1)} = \frac{2y}{\sigma^2}$$
% 
% With 0 and 1 equally likely before y arrives, this is also the log ratio 
% of the two bit probabilities given y, ln P(b=0 | y)/P(b=1 | y).
% Key ideas to remember
% • An LDPC code is a sparse set of parity checks, H c^T = 0 mod 2. Each check 
% covers only a few bits, and a codeword meets every one of them.
% 
% • NR has two base graphs. BG2 is for short or low-rate blocks: A ≤ 292, or 
% A ≤ 3824 with R ≤ 0.67, or R ≤ 0.25. Everything else uses BG1.
% 
% • The base graph is lifted by a factor Zc (up to 384). BG1 gives K = 22 Zc 
% and N = 66 Zc; BG2 gives K = 10 Zc and N = 50 Zc. The first 2 Zc systematic 
% bits are never sent, which is why N is 66 Zc and not 68 Zc.
% 
% • A CRC goes on first: 24 bits when A > 3824, else 16. If the result is longer 
% than one code block can hold (8448 bits for BG1, 3840 for BG2), it is split 
% into C code blocks, and each gets its own 24-bit CRC.
% 
% • Filler bits pad each code block up to K. The segmenter and the encoder 
% mark them −1, and they are known zeros, so they carry no information.
% 
% • The decoder takes soft bits (LLRs), not 0s and 1s: the sign is the guess 
% (+ means 0) and the size is the confidence. More SNR tends to mean fewer 
% iterations and fewer errors.
% 
% • A decoder can land on a different valid codeword. Then every LDPC check 
% passes on the wrong word, and only the CRC catches it.
% Prerequisites
% • The coding chain (CRC, code, rate matching) as a map (track 00 Fundamentals, 
% track00_fundamentals/p00b_signal_map_and_coding_demo), and soft bits and SNR 
% in dB (track00_fundamentals/p00b_softbits_and_dynamics_demo).
% 
% • A CRC that says whether a decode worked: album track 03 (Find Me in the 
% Noise, track03/track03_find_me_in_the_noise_demo) used one on the MIB as 
% a box; here you see what it guards against.
% 
% • Used here, not taught here: rate matching, which picks the coded bits that 
% are actually sent, starting at a redundancy-version offset, comes in album 
% track 05 (Say It Again). This demo sends all N coded bits.
% Words used in this demo
% • LDPC (low-density parity check) code: a code defined by a sparse parity-check 
% matrix H. Parity check: one row of H, a rule that some bits must add up to 
% 0 mod 2. Codeword: a word that meets every check.
% 
% • A: the payload, the number of data bits before any CRC (the transport block 
% size). R: the target code rate, data bits per coded bit sent.
% 
% • Base graph (BG1, BG2): the small pattern H is built from. Lifting size Zc: 
% the factor each entry of the base graph is blown up by.
% 
% • K: the bits in one code block, fillers included. N: the coded bits nrLDPCEncode 
% returns for one code block. C: the number of code blocks.
% 
% • CRC (cyclic redundancy check): check bits worked out from the data, so the 
% receiver can test whether the data came through.
% 
% • Filler bits: known zeros that pad a code block up to K. LLR (log-likelihood 
% ratio): a soft bit; its sign is the guess and its size the confidence.
% 
% • Iteration: one round of the decoder passing beliefs between the bits and 
% the checks.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • <= && || ~ — Purpose: compare two numbers; and, or, not. Inputs: numbers 
% or true/false values. Outputs: true or false. && and || stop as soon as 
% the answer is known.
% 
% • info = nrDLSCHInfo(A, R) — Purpose: the coding plan for a block. Inputs: 
% the payload A in bits and the target code rate R. Outputs: a structure with 
% fields such as BGN (the base graph, 1 or 2), CRC (the CRC name), C, Zc, K, 
% and N.
% 
% • b = randi([0 1], n, 1) — Purpose: n random bits. Inputs: the range and 
% the size. Outputs: a column of 0s and 1s.
% 
% • c = nrCRCEncode(b, crcName) and [b, err] = nrCRCDecode(c, crcName) — Purpose: 
% add CRC bits to the end of a block; check them and strip them off. Inputs: 
% a column of bits and the CRC name (info.CRC). Outputs: the longer column; 
% the bits and err, which is 0 when the CRC passes.
% 
% • cbs = nrCodeBlockSegmentLDPC(c, bgn) — Purpose: split a CRC'd block into 
% code blocks and pad each with filler bits (−1) up to K. Inputs: the column 
% and the base graph. Outputs: a K × C array, one column per code block.
% 
% • cw = nrLDPCEncode(cbs, bgn) — Purpose: LDPC-encode each code block. Inputs: 
% the K × C array and the base graph. Outputs: an N × C array of coded bits, 
% with fillers kept as −1.
% 
% • size(x, 1) and nnz(test) — Purpose: the number of rows of x; how many entries 
% of a test are true. Inputs: an array; a true/false array such as x == -1. 
% Outputs: a whole number.
% 
% • x(n) = v — Purpose: change entry n of x to v. Inputs: an array, a position, 
% and a value. Outputs: the changed array.
% 
% Commands you read in the given code
% • [out, nIter, checks] = nrLDPCDecode(llr, bgn, maxIter) — Purpose: decode 
% soft bits. Inputs: an N × C array of LLRs, the base graph, and the most iterations 
% allowed. Outputs: the K decoded bits per block, the iterations used, and the 
% value of each parity check at the end (0 = met). Used in B3 and B4.
% 
% • Figure family: figure(Name = ...), bar, xticks, xticklabels, ylabel, title 
% — Purpose: draw one bar per value, label the bars and the axis, and name 
% the figure. Inputs: data and text. Outputs: a figure. Used in Build it.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), a:b, x(:), x.', x(mask), s.name — Purpose: read 
% entries, count a range, reshape to a column or row, keep the entries where 
% a mask is true, read a structure field. Inputs: an array and positions. Outputs: 
% the entries.
% 
% • Compare and combine: == ~= < > >=, .* ./ .^ — Purpose: compare values; 
% multiply, divide, and raise to a power entry by entry. Inputs: numbers or 
% arrays. Outputs: true/false or numbers, entry by entry.
% 
% • Control flow: for ... end, if ... else ... end — Purpose: repeat a block 
% for each value of a list; run one block or the other. Inputs: a list or a 
% true/false test. Outputs: whatever the blocks store.
% 
% • Built-in helpers: numel, sum, max, isequal, islogical, isscalar, double, 
% sqrt, randn, zeros, exist, isnan, NaN — Purpose: count, add, find the largest, 
% compare, test what kind of value a name holds, convert to numbers, make noise 
% or empty arrays, look a name up. Inputs: numbers, arrays, or names. Outputs: numbers or true/false 
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
% Requirements
% Requires the 5G Toolbox. Teaching demo, not production code; not affiliated 
% with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year), so the data bits and the B3 noise repeat on every run

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");
%% B1 — Which base graph?
% New words
% • BGN: the base graph number nrDLSCHInfo returns, 1 or 2.
% 
% • Hand rule: the base-graph test from TS 38.212, written out in MATLAB as 
% one true/false line.
% Why it matters
% NR LDPC has two base graphs. BG2 is the graph for short or low-rate blocks; 
% BG1 is the graph for large, higher-rate blocks. The rule in TS 38.212 picks 
% one from the payload A and the target rate R together: BG2 if A ≤ 292, or 
% A ≤ 3824 and R ≤ 0.67, or R ≤ 0.25; otherwise BG1. The toolbox's info.BGN 
% should follow that rule at every point.
% What to look for
% • In the table, compare the Rule column with the BGN column for each of the 
% five (A, R) points.
% 
% • Find the point where A is under the 3824-bit limit but R is too high, 
% and the point where R alone sends it to BG2.
% Common mistakes
% Do not pick a graph from A alone. 3824 and 0.67 go together in one test: 
% a block of 3000 bits can land on either graph, depending on R.
% Try it (personal exploration)
% A block of A = 300 bits at R = 0.70 is just past the first limit (292). Use 
% the rule to predict its BGN (1 or 2). Type it into myPrediction before you 
% run this section; the one-row table at the end compares it with nrDLSCHInfo.

% Try it: type your prediction here (1 or 2) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B1 — Which base graph?
fprintf("B1 — Which base graph?\n");   % banner title only; every number below goes into a table

% Five (A, R) points: payload in bits, target code rate (data bits per coded bit).
points = [200 0.5; 3000 0.6; 3000 0.8; 8000 0.2; 8000 0.5];   % [A R] per row: bits, rate (no unit)
nPoints = size(points, 1);            % how many points
ruleBGN = zeros(nPoints, 1);          % base graph from the hand rule, filled in the loop
toolBGN = zeros(nPoints, 1);          % base graph from nrDLSCHInfo, filled in the loop

% For each point, apply the TS 38.212 rule by hand and ask the toolbox,
% so the two answers can be compared side by side.
for i = 1:nPoints
    A = points(i,1);  R = points(i,2);                                    % payload (bits) and rate for this point
    useBG2 = (A <= 292) || (A <= 3824 && R <= 0.67) || (R <= 0.25);      % TS 38.212 limits: 292 and 3824 bits, rates 0.67 and 0.25
    ruleBGN(i) = 2*useBG2 + 1*(~useBG2);                                  % true gives 2, false gives 1
    info = nrDLSCHInfo(A, R);                                             % the toolbox's coding plan for (A, R)
    toolBGN(i) = info.BGN;                                                % its base graph
end

% The toolbox and the rule must agree at all five points.
okRuleMatch = isequal(ruleBGN, toolBGN);
assert(okRuleMatch, ...
    'nrDLSCHInfo and the hand rule disagree. Look first at the A <= 3824 && R <= 0.67 term: both limits sit in one test.');

% One row per point.
b1Graphs = table(points(:,1), points(:,2), ruleBGN, toolBGN, ...
    VariableNames = {'A_bits', 'R', 'Rule', 'BGN'});
b1Graphs

% Put your Try-it prediction beside the toolbox's answer for A = 300, R = 0.70.
tryA = 300;  tryR = 0.70;                       % Try-it point: bits, rate
tryBGN = nrDLSCHInfo(tryA, tryR).BGN;           % the toolbox's base graph for it
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, tryA, tryR, tryBGN, predictionNote, ...
    VariableNames = {'MyPrediction', 'A_bits', 'R', 'BGN', 'Note'});
b1Prediction
%% B1 — After the run
% The Rule and BGN columns agree on every row. Two blocks of 3000 bits land 
% on different graphs: at R = 0.6 the A ≤ 3824 and R ≤ 0.67 test sends it to 
% BG2, and at R = 0.8 nothing does, so it uses BG1. At R = 0.2 even a large 
% block uses BG2. Compare the Try-it BGN with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Pass is computed from the stored flag.
b1Checks = table( ...
    ["nrDLSCHInfo BGN = hand rule at all five points"], ...
    [listText(ruleBGN)], ...
    [listText(toolBGN)], ...
    [okRuleMatch], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B1 was used only to build, test, or show B1.
clear b1Graphs b1Checks b1Prediction predictionNote okRuleMatch ...
      points nPoints ruleBGN toolBGN i A R useBG2 info tryA tryR tryBGN myPrediction
%% B2 — Lift, segment, encode
% New words
% • Lifting: every entry of the base graph becomes a Zc × Zc block (all zeros 
% or a shifted identity), so one small pattern serves many block sizes.
% 
% • Kcb: the most bits one code block can hold, 8448 for BG1 and 3840 for BG2. 
% Segmentation: splitting a longer block into C code blocks.
% Why it matters
% Lifting fixes the sizes: K = 22 Zc and N = 66 Zc for BG1, K = 10 Zc and N 
% = 50 Zc for BG2. The CRC goes on before anything else: 24 bits when A > 3824, 
% else 16. If the CRC'd block is longer than Kcb, it is split into C code blocks, 
% each with its own 24-bit CRC, and each is encoded on its own.
% What to look for
% • In the graphs table, read Zc, then check K/Zc and N/Zc for each graph.
% 
% • In the split table, read C, the columns nrCodeBlockSegmentLDPC made, and 
% the rows nrLDPCEncode returned.
% Common mistakes
% Do not expect the encoded length to be A/R. nrLDPCEncode returns N = 66 Zc 
% or 50 Zc bits per block; rate matching (album track 05) picks how many are 
% sent.
% 
% Do not forget the CRC bits when you ask whether a block will split: it is 
% A plus the CRC that has to fit.
% Try it (personal exploration)
% Predict how many code blocks C a payload of A = 20000 bits at R = 0.5 is 
% split into. (BG1 holds at most 8448 bits per code block, and each block gives 
% up 24 of them to its own CRC.) Type it into myPrediction before you run this 
% section; the one-row table at the end compares it with nrDLSCHInfo.

% Try it: type your prediction here (a number of code blocks) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Lift, segment, encode
fprintf("B2 — Lift, segment, encode\n");   % banner title only; every number below goes into a table

% One block on each graph: the B1 points (8000, 0.5) for BG1 and (200, 0.5) for BG2.
info1 = nrDLSCHInfo(8000, 0.5);   % 8000 bits at rate 0.5: BG1
info2 = nrDLSCHInfo(200, 0.5);    % 200 bits at rate 0.5: BG2

% Each graph and its lifted sizes.
okBG1 = info1.BGN == 1;
assert(okBG1, ...
    '8000 bits at R = 0.5 should use BG1. Look first at B1: A is above 3824 and R above 0.25.');
okN1 = info1.N == 66*info1.Zc;    % BG1: 66 Zc coded bits per block
assert(okN1, ...
    'BG1 should give N = 66 Zc. Common mistake: counting the 2 Zc punctured bits, which would give 68 Zc.');
okBG2 = info2.BGN == 2;
assert(okBG2, ...
    '200 bits at R = 0.5 should use BG2. Look first at B1: A is below 292.');
okN2 = info2.N == 50*info2.Zc;    % BG2: 50 Zc coded bits per block
assert(okN2, ...
    'BG2 should give N = 50 Zc. Common mistake: using the BG1 factor 66.');

b2Graphs = table([1; 2], [info1.Zc; info2.Zc], [info1.K; info2.K], [info1.K/info1.Zc; info2.K/info2.Zc], ...
    [info1.N; info2.N], [info1.N/info1.Zc; info2.N/info2.Zc], ...
    VariableNames = {'BGN', 'Zc', 'K', 'K_over_Zc', 'N', 'N_over_Zc'});
b2Graphs

% A payload too big for one BG1 code block: CRC it, split it, encode each block.
A_split = 10000;   % payload, bits: above the 8448-bit BG1 code block
R_split = 0.5;     % target code rate (no unit)
infoS   = nrDLSCHInfo(A_split, R_split);                                % its coding plan
blk     = randi([0 1], A_split, 1);                                     % random data bits
cbs     = nrCodeBlockSegmentLDPC(nrCRCEncode(blk, infoS.CRC), infoS.BGN);   % K × C code blocks
encoded = nrLDPCEncode(cbs, infoS.BGN);                                 % N × C coded bits

% The split matches the plan, and each encoded column is N bits long.
okSplit = infoS.C > 1 && size(cbs, 2) == infoS.C;
assert(okSplit, ...
    'The 10000-bit block should split into info.C > 1 columns. Look first at the CRC: segment the CRC''d block, not blk alone.');
okRows = size(encoded, 1) == infoS.N;
assert(okRows, ...
    'The encoded rows should equal info.N. Common mistake: passing a different base graph to nrLDPCEncode than to the segmenter.');

b2Split = table(A_split, infoS.BGN, infoS.C, size(cbs,2), infoS.Zc, size(cbs,1), size(encoded,1), ...
    VariableNames = {'A_bits', 'BGN', 'C', 'Columns', 'Zc', 'K_rows', 'N_rows'});
b2Split

% Put your Try-it prediction beside the toolbox's C for A = 20000, R = 0.5.
tryA = 20000;                          % Try-it payload, bits
tryC = nrDLSCHInfo(tryA, 0.5).C;       % code blocks the toolbox plans for it
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, tryA, tryC, predictionNote, ...
    VariableNames = {'MyPrediction', 'A_bits', 'C', 'Note'});
b2Prediction
%% B2 — After the run
% Both graphs give whole-number ratios: K/Zc is 22 or 10 and N/Zc is 66 or 
% 50, so lifting sets every size. The 10000-bit block does not fit one BG1 
% code block, so it is split into C columns of K bits each, and every column 
% encodes to N bits. Compare the Try-it C with your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["(8000, 0.5) uses BG1"; ...
     "BG1: N = 66 Zc"; ...
     "(200, 0.5) uses BG2"; ...
     "BG2: N = 50 Zc"; ...
     "10000 bits split into info.C > 1 columns"; ...
     "Encoded rows = info.N"], ...
    ["1"; string(66*info1.Zc); "2"; string(50*info2.Zc); "C > 1, columns = " + string(infoS.C); string(infoS.N)], ...
    [string(info1.BGN); string(info1.N); string(info2.BGN); string(info2.N); ...
     "C = " + string(infoS.C) + ", columns = " + string(size(cbs,2)); string(size(encoded,1))], ...
    [okBG1; okN1; okBG2; okN2; okSplit; okRows], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep info2: B3 and B4 decode a BG2 block of the same size. Everything else
% made in B2 was used only to build, test, or show B2.
clear b2Graphs b2Split b2Checks b2Prediction predictionNote ...
      okBG1 okN1 okBG2 okN2 okSplit okRows info1 A_split R_split infoS blk cbs encoded ...
      tryA tryC myPrediction
%% B3 — Soft bits in, iterations out
% New words
% • BPSK: one bit per symbol, sent as x = 1 − 2b, so 0 goes out as +1 and 1 
% as −1.
% 
% • maxIter: the most decoder iterations allowed. The decoder stops early once 
% every check is met.
% 
% Beat-only commands (B3)
% • y = x + sqrt(s2)*randn(size(x)) — Purpose: add real Gaussian noise of variance 
% s2 to every sample. Inputs: the samples and the variance. Outputs: noisy 
% samples of the same size.
% Why it matters
% The decoder sees log-likelihoods, not hard bits. For BPSK in noise of variance 
% σ², the LLR of a received y is 2y/σ²: its sign is the guess and its size 
% the confidence. At high SNR the beliefs are strong, the checks agree quickly, 
% and the block comes back clean. At low SNR the decoder uses more of its budget 
% and can still leave errors. The filler bits are known zeros: they are sent 
% as 0, given LLR 0 here, and left out of the error count. LLR 0 treats them 
% as erased, as the toolbox example does; a known zero could equally get a 
% large positive LLR.
% What to look for
% • In the decode table, read the iterations and the bit errors at −6, −4.5, 
% and 0 dB: this code sits right at its threshold near −6 dB.
% 
% • Find the row where the errors reach zero.
% Common mistakes
% Do not feed 0/1 hard bits into nrLDPCDecode: map to LLRs first.
% 
% Do not read a failed decode as "the CRC failed too", or a clean one as proof: 
% that is B4's trap.
% Try it (personal exploration)
% The decode table below gives the iterations used at each SNR, out of a budget 
% of maxIter = 25. Predict how many iterations the decoder uses at 0 dB, the 
% highest SNR in snrList: close to 1, or close to 25? Type a number into myPrediction 
% before you run this section; the one-row table at the end compares it with 
% the decoder.
% 
% Then, optionally, change the first entry of snrList from −6 to −7 and run 
% again: watch the iterations and the errors in that row. Only the highest 
% SNR is checked, so this change does not stop the run.
% 
% Note: this SNR is per coded BPSK bit with every coded bit sent, so it is 
% not the same axis as the error-rate curves of album tracks 05 and 11.

% Try it: type your prediction here (a number of iterations) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Soft bits in, iterations out
fprintf("B3 — Soft bits in, iterations out\n");   % banner title only; every number below goes into a table

% One BG2 code block: 200 random data bits, CRC'd, padded, and encoded.
bgn    = info2.BGN;                                                              % base graph 2, from B2
oneBlk = nrCodeBlockSegmentLDPC(nrCRCEncode(randi([0 1], 200, 1), info2.CRC), bgn);   % K × 1, fillers are -1
cw     = nrLDPCEncode(oneBlk, bgn);                                              % N × 1, fillers kept as -1

% nrLDPCEncode has already left out the 2 Zc punctured systematic bits (that
% is why N = 50 Zc for BG2, not 52 Zc), so no extra step is needed.
% Fillers: send them as 0, and score only the data positions.
isFill = (cw == -1);                  % filler positions in the codeword (true/false)
cwTx   = double(cw);                  % coded bits as numbers, ready to map
cwTx(isFill) = 0;                     % fillers are known zeros
isData = (oneBlk ~= -1);              % data positions in the code block (true/false)

% Decoder budget and the SNRs to try, per coded BPSK bit.
maxIter = 25;                         % most iterations allowed (iterations)
snrList = [-6 -4.5 0];                % SNR per coded bit, dB (the code's threshold is near -6 dB)
iterList = zeros(numel(snrList), 1);  % iterations used, filled in the loop
errList  = zeros(numel(snrList), 1);  % data-bit errors, filled in the loop

% For each SNR: send the block as BPSK, add noise, turn each sample into an
% LLR, decode, and count the wrong data bits.
for s = 1:numel(snrList)
    sigma2 = 10^(-snrList(s)/10);                        % noise variance for unit-power BPSK (linear)
    y      = (1 - 2*cwTx) + sqrt(sigma2)*randn(size(cwTx));   % BPSK: 0 -> +1, 1 -> -1, plus noise
    llr    = 2*y / sigma2;                               % LLR = 2y/sigma^2: + means bit 0
    llr(isFill) = 0;                                     % fillers: LLR 0, as in the live demo
    [decOut, actNumIter] = nrLDPCDecode(llr, bgn, maxIter);   % K decoded bits and the iterations used
    iterList(s) = actNumIter;
    errList(s)  = sum(double(decOut(isData)) ~= oneBlk(isData));   % wrong data bits
end

% At the highest SNR the block must come back clean.
okHighSNR = errList(end) == 0;
assert(okHighSNR, ...
    'The 0 dB decode left bit errors. Look first at maxIter (25 here) and at the filler mask isData.');

b3Decode = table(snrList(:), iterList, errList, ...
    VariableNames = {'SNR_dB', 'Iterations', 'BitErrors'});
b3Decode

% Put your Try-it prediction beside the iterations used at the highest SNR.
tryIter = iterList(end);              % iterations at the highest SNR in snrList
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, snrList(end), tryIter, maxIter, predictionNote, ...
    VariableNames = {'MyPrediction', 'SNR_dB', 'Iterations', 'MaxIter', 'Note'});
b3Prediction
%% B3 — After the run
% As the SNR rises the LLRs grow, so the decoder tends to need fewer iterations 
% and leave fewer errors; at 0 dB this block comes back with no errors. Near 
% the threshold, at −6 and −4.5 dB, the exact counts depend on the noise drawn: 
% this is the steep "waterfall" of an LDPC code. Compare Iterations with your 
% prediction: the decoder stops as soon as every check is met.
%% B3 — Assertion checks

% One row per assert in B3. Pass is computed from the stored flag.
b3Checks = table( ...
    ["No data-bit errors at the highest SNR"], ...
    ["0 at " + string(snrList(end)) + " dB"], ...
    [string(errList(end)) + " at " + string(snrList(end)) + " dB"], ...
    [okHighSNR], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep bgn and maxIter: B4 decodes on the same graph with the same budget.
% Everything else made in B3 was used only to build, test, or show B3.
clear b3Decode b3Checks b3Prediction predictionNote okHighSNR ...
      oneBlk cw isFill cwTx isData snrList iterList errList s sigma2 y llr decOut actNumIter ...
      tryIter myPrediction
%% B4 — The trap: every check agrees on the wrong word
% New words
% • Wrong-but-valid word: a codeword that meets every LDPC check but is not 
% the one that was sent.
% 
% • Outer check: the CRC, worked out on the data before the LDPC code, and 
% tested after the decoder.
% Why it matters
% "Every check agrees" can still be the wrong word. An LDPC code has a huge 
% number of valid codewords, and a decoder that lands on a different one sees 
% every parity check pass. The CRC is the outer test that still catches it. 
% Here that event is staged, not caught in the wild: the sender's CRC'd word 
% is A; the decoder is handed, with noiseless LLRs, a word W that differs from 
% A in one data bit, with the CRC bits not worked out again. W is encoded, so 
% it is a valid LDPC codeword, and the decoder meets every check on it; the 
% CRC rejects it. This shows what a wrong-but-valid landing looks like, not 
% how often a real decoder lands on one.
% What to look for
% • In the trap table, read the failing LDPC checks on W and the CRC result 
% err for A and for W (0 means pass).
% Common mistakes
% Do not treat a clean parity check as proof of the original message.
% 
% Do not think the CRC is just one more LDPC parity bit: it is worked out on 
% the data before the LDPC code and tested after it.
% Try it (personal exploration)
% This time do not re-encode. Take W's codeword cwW and flip one coded bit 
% (bit 1) on its way to the decoder, with the same noiseless LLRs. Predict 
% how many of the decoder's output bits differ from W's code block. Type the 
% number into myPrediction before you run this section; the one-row table 
% at the end shows the count.

% Try it: type your prediction here (a number of output bits that differ from W) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — The trap
fprintf("B4 — The trap: every check agrees on the wrong word\n");   % banner title only; every number below goes into a table

% What the sender meant: 200 data bits with their CRC.
msgA = randi([0 1], 200, 1);               % data bits
crcA = nrCRCEncode(msgA, info2.CRC);       % A: the data plus its 16 CRC bits

% A different word W: one data bit flipped, CRC bits NOT worked out again.
wrongBit = 1;                              % which data bit to flip (1 to 200)
crcW = crcA;                               % start from A
crcW(wrongBit) = 1 - crcW(wrongBit);       % flip that bit only

% Encode W: a valid LDPC codeword by construction. The decoder sees it with
% no noise: a strong LLR of +10 or -10 per bit, and 0 for the fillers.
cwW   = nrLDPCEncode(nrCodeBlockSegmentLDPC(crcW, bgn), bgn);   % N × 1, fillers -1
fillW = (cwW == -1);                                             % filler positions
llrW  = 10*(1 - 2*double(max(cwW, 0)));                          % noiseless LLRs: size 10 (fillers counted as 0 first)
llrW(fillW) = 0;                                                 % fillers: LLR 0
[~, itW, pcW] = nrLDPCDecode(llrW, bgn, maxIter);                % iterations and final parity checks
nFailChecks = sum(pcW(:) ~= 0);                                  % checks not met (0 = all met)

% The CRC on A and on W.
[~, errA] = nrCRCDecode(crcA, info2.CRC);   % 0 = the CRC passes
[~, errW] = nrCRCDecode(crcW, info2.CRC);

% Three tests: every check agrees on W, the CRC accepts A, and it rejects W.
okChecksAgree = nFailChecks == 0;
assert(okChecksAgree, ...
    'W should meet every LDPC check. Look first at cwW: it must be nrLDPCEncode output, and the fillers must have LLR 0.');
okCrcA = errA == 0;
assert(okCrcA, ...
    'The CRC should accept A. Look first at the CRC name: use info2.CRC for both encode and decode.');
okCrcW = errW ~= 0;
assert(okCrcW, ...
    'The CRC should reject W. Common mistake: working the CRC out again on W, which would make it pass.');

b4Trap = table(["A (sent)"; "W (staged)"], [NaN; nFailChecks], [NaN; itW], double([errA; errW]), ...
    VariableNames = {'Word', 'FailingChecks', 'Iterations', 'CRC_err'});
b4Trap

% Try it: one coded bit of cwW flipped on the way, NOT re-encoded (no assert on it).
tryBit = 1;                                                     % coded bit to flip (a data position, not a filler)
llrTry = llrW;                                                  % W's noiseless LLRs
llrTry(tryBit) = -llrTry(tryBit);                               % the flipped bit now votes the wrong way
[decTry, ~, pcTry] = nrLDPCDecode(llrTry, bgn, maxIter);        % decoded code block and final parity checks
blkW = nrCodeBlockSegmentLDPC(crcW, bgn);                       % W's code block (fillers -1)
tryDiff = sum(double(decTry(blkW ~= -1)) ~= blkW(blkW ~= -1));  % output bits that differ from W (fillers left out)
tryFail = sum(pcTry(:) ~= 0);                                   % checks not met after decoding
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b4Prediction = table(myPrediction, tryDiff, predictionNote, ...
    VariableNames = {'MyPrediction', 'BitsDifferentFromW', 'Note'});
b4Prediction
b4TryChecks = table(tryFail, ...
    VariableNames = {'FailingChecksAfterDecoding'});
b4TryChecks
%% B4 — After the run
% Every LDPC check is met on W, so a receiver that stopped at the decoder would 
% accept a wrong word. The CRC gives err = 0 for A and a nonzero err for W, 
% so the receiver rejects W and can ask for the block again. Compare BitsDifferentFromW 
% with your prediction, then read how many checks fail after decoding.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags.
b4Checks = table( ...
    ["W meets every LDPC check"; ...
     "CRC accepts A"; ...
     "CRC rejects W"], ...
    ["0 failing"; "err = 0"; "err ~= 0"], ...
    [string(nFailChecks) + " failing"; "err = " + string(errA); "err = " + string(errW)], ...
    [okChecksAgree; okCrcA; okCrcW], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Everything made in B4 (and the B2 and B3 values kept for it) was used only
% to build, test, or show the beats; the Build it starts fresh.
clear b4Trap b4Checks b4Prediction b4TryChecks predictionNote okChecksAgree okCrcA okCrcW ...
      msgA crcA wrongBit crcW cwW fillW llrW itW pcW nFailChecks errA errW ...
      tryBit llrTry decTry blkW tryDiff pcTry tryFail myPrediction info2 bgn maxIter
%% Build it — Plan, lift, and encode a new block, and catch a wrong bit
% Competency: given a payload and a target rate, pick the base graph by the 
% rule, work out the lifted sizes and the filler bits, encode the block, and 
% show that the CRC rejects a word with one wrong data bit.
% Problem
% You are given myA = 1000 bits at myR = 0.4. Write each part of the base-graph 
% rule as its own true/false value and pick the graph. Predict the filler bits 
% from the Zc rule, then read the coding plan from nrDLSCHInfo and work out 
% K, N, the CRC length, and the fillers. Encode a random block of myA bits, 
% then make a one-bit error pattern, add it to the CRC'd word (mod 2) without 
% working the CRC out again, and test the result with the CRC.
% Allowed commands
% Arithmetic and mod; <= && || ~; nrDLSCHInfo; randi; zeros; nrCRCEncode and 
% nrCRCDecode; nrCodeBlockSegmentLDPC; nrLDPCEncode; size and nnz; changing 
% one entry x(n) = v. The tables and the figure in the check sections and Stage 
% 5 are given. These are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% myA = 1000;   % payload, bits: given for this exercise; no beat above uses it
% myR = 0.4;    % target code rate (no unit): given
%% Stage 1 check (given)
if ~exist('myA','var') || ~exist('myR','var')
    disp('Stage 1 not done: delete the % in front of the code lines above, then run that section.')
else
    % The given values must still be in place before the later stages use them.
    okStage1 = myA == 1000 && myR == 0.4;   % the values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the lines you uncommented: myA = 1000 and myR = 0.4.')
    stage1Checks = table("myA and myR as given", "1000 0.4", listText([myA myR]), okStage1, ...   % expected: the given values
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — the three parts of the base-graph rule
% Write each part of the rule in Key relationships as its own true/false value 
% for myA and myR: myTerm1 for the payload-only part, myTerm2 for the part 
% that needs both the payload and the rate, myTerm3 for the rate-only part. 
% Then turn them into myBGN, 2 for BG2 and 1 for BG1.
% Pass: Stage 2 OK.

% myTerm1 = ___;
% myTerm2 = ___;
% myTerm3 = ___;
% myBGN = ___;
%% Stage 2 check (given; the check asks nrDLSCHInfo about each part on its own, a different route from your rule)
if ~exist('myTerm1','var') || ~exist('myTerm2','var') || ~exist('myTerm3','var') || ~exist('myBGN','var')
    disp('Stage 2 not done: fill the blanks, uncomment, and run.')
else
    % Different route: probe nrDLSCHInfo at points where only one part of
    % the rule can be true, so each of your parts is tested on its own.
    oracleTerm1 = nrDLSCHInfo(myA, 0.99).BGN == 2;                          % rate 0.99: only the payload-only part can pick BG2
    oracleTerm3 = nrDLSCHInfo(100000, myR).BGN == 2;                        % 100000 bits: only the rate-only part can pick BG2
    oracleTerm2 = nrDLSCHInfo(max(myA, 293), max(myR, 0.26)).BGN == 2;     % 293 bits and rate 0.26: just past the other two parts
    oracleBGN   = nrDLSCHInfo(myA, myR).BGN;

    % Four tests: each part, then the graph.
    okStage2 = [isequal(logical(myTerm1), oracleTerm1); ...
                isequal(logical(myTerm2), oracleTerm2); ...
                isequal(logical(myTerm3), oracleTerm3); ...
                myBGN == oracleBGN];
    assert(okStage2(1), ...
        'myTerm1 disagrees with the toolbox. Look first at the payload-only limit in Key relationships.')
    assert(okStage2(2), ...
        'myTerm2 disagrees with the toolbox. Common mistake: joining its two limits with || instead of &&.')
    assert(okStage2(3), ...
        'myTerm3 disagrees with the toolbox. Look first at the rate-only limit in Key relationships.')
    assert(okStage2(4), ...
        'myBGN does not match nrDLSCHInfo. Look first at how the three parts combine: any one of them picks BG2.')
    stage2Checks = table( ...
        ["Payload-only part"; "Payload-and-rate part"; "Rate-only part"; "myBGN = nrDLSCHInfo's BGN"], ...
        [string(oracleTerm1); string(oracleTerm2); string(oracleTerm3); string(oracleBGN)], ...
        [string(logical(myTerm1)); string(logical(myTerm2)); string(logical(myTerm3)); string(myBGN)], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: the filler bits
% Before you read anything from nrDLSCHInfo, type your prediction: how many 
% filler bits will the code block hold? Use the Zc rule in Key relationships 
% with B = myA + the CRC bits. Run this section and the check under it before 
% you start Stage 3b: the check does not take a prediction once Stage 3b's 
% names exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with the segmenter and does not print its count)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif exist('myInfo','var') || exist('myFill','var')
    disp('Stage 3a refused: Stage 3b names already exist, so this is no longer a prediction. Run "clear myInfo myFill", then predict again.')
else
    p3Info = nrDLSCHInfo(myA, myR);                                                % the toolbox's plan, used only inside the check
    p3Fill = nnz(nrCodeBlockSegmentLDPC(nrCRCEncode(zeros(myA,1), p3Info.CRC), p3Info.BGN) == -1);   % fillers the segmenter writes
    okPrediction3 = myPrediction == p3Fill;
    stage3aCheck = table("Prediction = fillers the segmenter writes", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at B = myA + CRC bits, then at K_b for that B, then at the smallest Zc with K_b × Zc >= B; K for your graph comes from Zc. Change myPrediction and run again.')
    end
    clear p3Info p3Fill
end
%% Stage 3b — the lifted sizes and the fillers
% Fill the blanks: the coding plan from nrDLSCHInfo; K and N from its Zc for 
% your graph; the CRC length for this A; and the fillers.
% Pass: your locked prediction and your count appear side by side, and Stage 
% 3 OK.

% myInfo = ___;
% myK = ___;
% myN = ___;
% myCRCLen = ___;
% myFill = ___;
%% Stage 3b check (given; the check counts the -1 entries the segmenter writes, a different route from yours)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('myInfo','var') || ~exist('myK','var') || ~exist('myN','var') || ~exist('myCRCLen','var') ...
        || ~exist('myFill','var')
    disp('Stage 3b not done: fill the blanks, uncomment, and run.')
else
    % Your locked prediction beside your count, in one row.
    stage3Prediction = table(myLockedPrediction, myFill, ...
        VariableNames = {'MyPrediction', 'MyFill'});
    stage3Prediction

    % Different route: CRC an all-zero block of myA bits, segment it, and
    % count the fillers (-1) and the CRC bits added.
    oracleCrcd = nrCRCEncode(zeros(myA, 1), myInfo.CRC);                 % myA data bits plus the CRC
    oracleFill = nnz(nrCodeBlockSegmentLDPC(oracleCrcd, myInfo.BGN) == -1);   % fillers the segmenter adds

    % Four tests: K and N match the plan, the CRC length matches what
    % nrCRCEncode added, and the fillers match the count.
    okStage3 = [myK == myInfo.K; ...
                myN == myInfo.N; ...
                myCRCLen == numel(oracleCrcd) - myA; ...
                myFill == oracleFill];
    assert(okStage3(1), ...
        'myK does not match info.K. Look first at the factor: it depends on your graph from Stage 2.')
    assert(okStage3(2), ...
        'myN does not match info.N. Common mistake: using the factor for the other graph.')
    assert(okStage3(3), ...
        'myCRCLen is off. Look first at Key ideas: the CRC length depends on whether A is above 3824.')
    assert(okStage3(4), ...
        'myFill does not match the segmenter. Look first at what fills K besides the fillers.')
    stage3Checks = table( ...
        ["myK = info.K"; "myN = info.N"; "myCRCLen = bits nrCRCEncode adds"; "myFill = -1 entries from the segmenter"], ...
        [string(myInfo.K); string(myInfo.N); string(numel(oracleCrcd) - myA); string(oracleFill)], ...
        [string(myK); string(myN); string(myCRCLen); string(myFill)], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — encode the block, then catch a wrong bit
% Fill the blanks: myA random bits; their CRC'd word; the codeword on your 
% graph; the number of coded rows. Then make an error pattern of zeros the 
% size of the CRC'd word with a single 1 at data bit 10, add it to the CRC'd 
% word mod 2 (no new CRC), and test the result with the CRC.
% Pass: Stage 4 OK.

% myBlk = ___;
% myCrcd = ___;
% myCw = ___;
% myRows = ___;
% myErrPattern = zeros(size(myCrcd));
% myErrPattern(___) = 1;
% myBad = mod(___ + ___, 2);
% [~, myErrBad] = nrCRCDecode(___, ___);
%% Stage 4 check (given)
if ~exist('myCw','var') || ~exist('myRows','var') || ~exist('myBad','var') || ~exist('myErrBad','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: the CRC on the untouched word, and where the result
    % differs from it.
    [~, oracleErrGood] = nrCRCDecode(myCrcd, myInfo.CRC);   % 0 for the word as sent
    oracleWhere = find(myBad ~= myCrcd);                     % positions where the result differs

    % Five tests: the codeword has info.N rows, it keeps the fillers as -1,
    % the result differs in one place, that place is data bit 10, and the
    % CRC accepts the good word and rejects the result.
    okStage4 = [myRows == myInfo.N && size(myCw, 2) == 1; ...
                nnz(myCw == -1) == myFill; ...
                numel(oracleWhere) == 1; ...
                isequal(oracleWhere, 10); ...
                oracleErrGood == 0 && myErrBad ~= 0];
    assert(okStage4(1), ...
        'The codeword should be one column of info.N rows. Look first at the graph you passed: the same myBGN to both commands.')
    assert(okStage4(2), ...
        'The codeword should keep the fillers as -1. Common mistake: segmenting myBlk instead of myCrcd, which changes the fillers.')
    assert(okStage4(3), ...
        'myBad should differ from myCrcd in exactly one place. Look first at the error pattern: one 1, the rest 0.')
    assert(okStage4(4), ...
        'The wrong bit is not data bit 10. Look first at the position you set in myErrPattern.')
    assert(okStage4(5), ...
        'The CRC should accept myCrcd and reject myBad. Common mistake: passing myCrcd to nrCRCDecode instead of myBad.')
    stage4Checks = table( ...
        ["Codeword rows = info.N, one column"; "Fillers kept as -1 in the codeword"; ...
         "myBad differs from myCrcd in one place"; "That place is data bit 10"; "CRC: myCrcd passes, myBad fails"], ...
        [string(myInfo.N) + " rows, 1 column"; string(myFill); "1"; "10"; "0 and nonzero"], ...
        [string(myRows) + " rows, " + string(size(myCw, 2)) + " column"; string(nnz(myCw == -1)); ...
         string(numel(oracleWhere)); listText(oracleWhere); string(oracleErrGood) + " and " + string(myErrBad)], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myErrBad','var') || ~exist('myFill','var') || ~exist('myBGN','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % Each flag is computed from your results, so the table cannot say Pass by itself.
    ruleBG2 = (myA <= 292) || (myA <= 3824 && myR <= 0.67) || (myR <= 0.25);   % the rule written out in one line: limits in bits and rates
    mySeg   = nrCodeBlockSegmentLDPC(myCrcd, myBGN);                            % your CRC'd word, segmented again
    buildFlags = [myBGN == 2*ruleBG2 + 1*(~ruleBG2); ...
        myK/myInfo.Zc == 22*(myBGN == 1) + 10*(myBGN == 2); ...                                     % K/Zc: 22 for BG1, 10 for BG2
        myN/myInfo.Zc == 66*(myBGN == 1) + 50*(myBGN == 2); ...                                     % N/Zc: 66 for BG1, 50 for BG2
        size(mySeg, 1) == myA + myCRCLen + myFill; ...
        myErrBad ~= 0];

    % One row per result: the rule's value, your value, and the computed flag.
    buildChecks = table( ...
        ["Base graph follows the rule (one-line form)"; "K / Zc for this graph (repeat of Stage 3)"; ...
         "N / Zc for this graph (repeat of Stage 3)"; "Segmenter's block length = data + CRC + fillers"; ...
         "CRC rejects the one-bit-wrong word (repeat of Stage 4)"], ...
        [string(2*ruleBG2 + 1*(~ruleBG2)); string(22*(myBGN == 1) + 10*(myBGN == 2)); string(66*(myBGN == 1) + 50*(myBGN == 2)); ...
         string(size(mySeg, 1)); "nonzero"], ...
        [string(myBGN); string(myK/myInfo.Zc); string(myN/myInfo.Zc); ...
         string(myA + myCRCLen + myFill); string(myErrBad)], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % Mechanism figure: where the bits of your code block and codeword go.
    myParts = [myA, myCRCLen, myFill, myN - myK];             % data, CRC, fillers, and the coded bits beyond K
    figure(Name = 'Track 04 Build it - my block', Color = 'w');
    bar(1:4, myParts);                                         % one bar per part, in bits
    xticks(1:4);
    xticklabels({'data A', 'CRC', 'fillers', 'N - K'});
    ylabel('bits');
    title(sprintf('A = %d, R = %.2f: BG%d, Z_c = %d, K = %d, N = %d', myA, myR, myBGN, myInfo.Zc, myK, myN));
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): 
% which part of the rule chose your graph, and how did Zc set K and N? Where 
% do the fillers come from, and why does the CRC still reject a word that the 
% LDPC code would accept?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. Keep myR, but make the 
% payload one bit longer, A = 1001. How many filler bits would its code block 
% hold? The check segments that block and does not print the count.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('myR','var')
    disp('Run Stage 1 first, then return here.')
else
    i1001  = nrDLSCHInfo(1001, myR);
    fill1001 = nnz(nrCodeBlockSegmentLDPC(nrCRCEncode(zeros(1001,1), i1001.CRC), i1001.BGN) == -1);   % second route: the segmenter
    okInterp = myAnswer == fill1001;
    interpHint = "";
    if ~okInterp
        interpHint = "does one more bit change Zc here, or only B?";
    end
    interpCheck = table("Fillers for A = 1001", okInterp, interpHint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    interpCheck
end
%% Build it — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Clear the check scratch: the different-route values, flags, and check
% tables. Your own my... results stay, so you can look at them while you
% do the exercises below; listText stays in case you rerun a check.
clear okStage1 stage1Checks oracleTerm1 oracleTerm2 oracleTerm3 oracleBGN okStage2 stage2Checks ...
      okPrediction3 stage3aCheck stage3Prediction oracleCrcd oracleFill okStage3 stage3Checks ...
      oracleErrGood oracleWhere okStage4 stage4Checks ruleBG2 mySeg buildFlags buildChecks myParts ...
      myAnswer i1001 fill1001 okInterp interpHint interpCheck
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them. 
% Each exercise has a check: type your numbers into its myE variable and run 
% that section. The check works the values out by a second route (the toolbox, 
% or the rule from a different starting point), shows Pass or Fail with a pointer 
% for each entry, and never prints the value. Write the reasons on the Your 
% answer lines; the script does not grade them.
%% E1 — New values (B1)
% Use the rule, not the toolbox, for three blocks: A = 3824 at R = 0.67, A 
% = 3824 at R = 0.68, and A = 3825 at R = 0.30. Which base graph does each 
% use? Type the three graph numbers into myE1, and for each one name the part 
% of the rule that decides it.
% 
% Your answer:
myE1 = NaN;   % [BGN for (3824, 0.67), BGN for (3824, 0.68), BGN for (3825, 0.30)]
if any(isnan(myE1)) || numel(myE1) ~= 3
    disp('Type three numbers into myE1, then run this section again.')
else
    e1Ref = [nrDLSCHInfo(3824, 0.67).BGN, nrDLSCHInfo(3824, 0.68).BGN, nrDLSCHInfo(3825, 0.30).BGN];   % second route: the toolbox
    okE1  = myE1(:) == e1Ref(:);
    e1Hint = ["both limits of the middle part are 'at or below'"; "the rate limit of the middle part"; ...
              "the payload limit of the middle part, then the rate-only part"];
    e1Hint(okE1) = "";
    e1Check = table(["A 3824, R 0.67"; "A 3824, R 0.68"; "A 3825, R 0.30"], okE1, e1Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e1Check
end
%% E2 — Diagnosis (B1 and B2)
% A classmate expects nrLDPCEncode to turn a block of A = 600 data bits at 
% R = 0.5 into A/R = 1200 coded bits. Pick the base graph by the rule, then 
% find Zc with the Zc rule in Key relationships. Work out by hand N and the 
% number of filler bits, and K/N. Type the three numbers into myE2 as [N, 
% fillers, K/N]. How far is K/N from the 0.5 the classmate asked for, and 
% which later step brings the rate back to 0.5?
% 
% Your answer:
myE2 = NaN;   % [N, filler bits, K/N]
if any(isnan(myE2)) || numel(myE2) ~= 3
    disp('Type three numbers into myE2, then run this section again.')
else
    e2Info = nrDLSCHInfo(600, 0.5);                           % second route: the toolbox and the segmenter
    e2Fill = nnz(nrCodeBlockSegmentLDPC(nrCRCEncode(zeros(600,1), e2Info.CRC), e2Info.BGN) == -1);
    e2Ref  = [e2Info.N, e2Fill, e2Info.K/e2Info.N];
    okE2   = abs(myE2(:) - e2Ref(:)) <= max(0.01*abs(e2Ref(:)), 1e-9);
    e2Hint = ["N from Zc for this graph"; "K minus data and CRC"; "K and N share Zc"];
    e2Hint(okE2) = "";
    e2Check = table(["N"; "Filler bits"; "K / N"], okE2, e2Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e2Check
end
%% E3 — New values (B2, Key ideas)
% At R = 0.5, does a payload of A = 8424 bits split into more than one code 
% block? What about A = 8425? Work out A plus its CRC for each, compare with 
% the BG1 limit, and type the number of code blocks for each into myE3 as [C 
% for 8424, C for 8425]. Say why one extra payload bit changes the count.
% 
% Your answer:
myE3 = NaN;   % [code blocks for A = 8424, code blocks for A = 8425]
if any(isnan(myE3)) || numel(myE3) ~= 2
    disp('Type two numbers into myE3, then run this section again.')
else
    e3Ref = [size(nrCodeBlockSegmentLDPC(nrCRCEncode(zeros(8424,1), '24A'), 1), 2), ...
             size(nrCodeBlockSegmentLDPC(nrCRCEncode(zeros(8425,1), '24A'), 1), 2)];   % second route: count the segmenter's columns (BG1, 24-bit CRC)
    okE3  = myE3(:) == e3Ref(:);
    e3Hint = ["A + 24 against the BG1 limit"; "A + 24 against the BG1 limit"];
    e3Hint(okE3) = "";
    e3Check = table(["C for A = 8424"; "C for A = 8425"], okE3, e3Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e3Check
end
%% E4 — Diagnosis (B3, Common mistakes)
% A classmate passes the coded bits themselves, 0s and 1s, to nrLDPCDecode 
% as if they were LLRs. For a coded bit that is 1, which bit (0 or 1) does 
% the decoder lean towards? Type it into myE4. Then say what the decoder believes 
% about a bit it receives as 0, and why that is exactly wrong for the 1s.
% 
% Your answer:
myE4 = NaN;   % the bit the decoder leans towards for a coded 1 passed as an LLR
if isnan(myE4) || numel(myE4) ~= 1
    disp('Type one number into myE4, then run this section again.')
else
    e4Ref = double(1 < 0);                                    % second route: a positive LLR leans to 0, a negative one to 1
    okE4  = myE4 == e4Ref;
    e4Hint = "";
    if ~okE4
        e4Hint = "the sign of the LLR is the guess: + means 0";
    end
    e4Check = table("Lean for a coded 1 passed as an LLR", okE4, e4Hint, VariableNames = {'Check', 'Pass', 'LookAt'});
    e4Check
end
%% E5 — New values and explanation (B3)
% At an SNR of 4 dB per coded bit, what is σ²? What LLR does a received sample 
% y = 0.5 give, and what does a sample y = −0.2 give at 8 dB? Type the three 
% numbers into myE5 as [σ² at 4 dB, LLR for 0.5 at 4 dB, LLR for −0.2 at 8 
% dB]. Say for each which bit the decoder leans towards and how strongly, compared 
% with y = 0.5 at 0 dB.
% 
% Your answer:
myE5 = NaN;   % [sigma^2 at 4 dB, LLR(y = 0.5, 4 dB), LLR(y = -0.2, 8 dB)]
if any(isnan(myE5)) || numel(myE5) ~= 3
    disp('Type three numbers into myE5, then run this section again.')
else
    e5s4  = exp(-0.4*log(10));  e5s8 = exp(-0.8*log(10));   % second route: exp and log instead of 10^(-x/10)
    e5Ref = [e5s4, 2*0.5/e5s4, 2*(-0.2)/e5s8];
    okE5  = abs(myE5(:) - e5Ref(:)) <= 0.01*abs(e5Ref(:));    % within 1 %
    e5Hint = ["unit-power BPSK: sigma^2 = 1 / SNR (linear)"; "2y / sigma^2"; "2y / sigma^2 at the other SNR"];
    e5Hint(okE5) = "";
    e5Check = table(["sigma^2 at 4 dB"; "LLR, y = 0.5, 4 dB"; "LLR, y = -0.2, 8 dB"], okE5, e5Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e5Check
end
%% E6 — New values and explanation (B4)
% A random wrong word gets past an L-bit CRC with a chance of about one in 
% 2^L. Out of one million random wrong words, about how many would a 16-bit 
% CRC miss, and how many would a 24-bit CRC miss? Type both into myE6. NR uses 
% the 16-bit CRC only for small payloads (A ≤ 3824). Using the CRC overhead 
% as a share of a small block, say why the shorter CRC is used there and the 
% longer one only on large blocks.
% 
% Your answer:
myE6 = NaN;   % [misses per million, 16-bit CRC; misses per million, 24-bit CRC]
if any(isnan(myE6)) || numel(myE6) ~= 2
    disp('Type two numbers into myE6, then run this section again.')
else
    e6Ref = 1e6 * pow2([-16 -24]);                            % second route: pow2
    okE6  = abs(myE6(:) - e6Ref(:)) <= 0.01*abs(e6Ref(:));    % within 1 %
    e6Hint = ["one million over 2^16"; "one million over 2^24"];
    e6Hint(okE6) = "";
    e6Check = table(["16-bit CRC misses per million"; "24-bit CRC misses per million"], okE6, e6Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e6Check
end
%% Exercise cleanup
clear myE1 e1Ref okE1 e1Hint e1Check myE2 e2Info e2Fill e2Ref okE2 e2Hint e2Check ...
      myE3 e3Ref okE3 e3Hint e3Check myE4 e4Ref okE4 e4Hint e4Check ...
      myE5 e5s4 e5s8 e5Ref okE5 e5Hint e5Check myE6 e6Ref okE6 e6Hint e6Check
%% Recap — Every Check Agrees (album track 04)
% An LDPC code is a sparse set of parity checks. NR lifts one of two base graphs 
% by Zc, picks the graph from the payload and the rate by an exact rule, and 
% decodes by trading soft beliefs until every check is met. The CRC guards 
% against a valid but wrong answer.
% Key relationships
% BG2 if A ≤ 292, or A ≤ 3824 and R ≤ 0.67, or R ≤ 0.25; otherwise BG1. Zc 
% is the smallest lifting size with K_b Z_c ≥ B.
% 
% $$\text{BG1: } K = 22Z_c,\ N = 66Z_c \qquad \text{BG2: } K = 10Z_c,\ N = 50Z_c 
% \qquad \mathrm{LLR} = \ln\frac{p(y\mid b=0)}{p(y\mid b=1)} = \frac{2y}{\sigma^2}$$
% What this means in practice
% • nrDLSCHInfo gives the plan for a block: its base graph, CRC, number of 
% code blocks C, Zc, K, and N.
% 
% • The CRC is attached before segmentation, so a payload just under one code 
% block's size can still split.
% 
% • Fillers pad each code block to K; they are known zeros and are never counted 
% as data.
% 
% • The decoder needs LLRs; higher SNR tends to mean fewer iterations and fewer 
% errors. In B3's one seeded run the block came back clean at 0 dB, which is 
% one run, not a guarantee.
% 
% • Passing every LDPC check is not proof: the CRC is the outer check.
% 
% • You picked the graph for a new block by the rule, worked out its K, N, 
% and fillers, encoded it, and caught a one-bit-wrong word with the CRC.
% 
% • Next in the album: track05 (Say It Again).
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
% • <= && || ~:
% 
% • nrDLSCHInfo:
% 
% • randi:
% 
% • nrCRCEncode and nrCRCDecode:
% 
% • nrCodeBlockSegmentLDPC:
% 
% • nrLDPCEncode:
% 
% • size(x, 1) and nnz:
% 
% • x(n) = v:
% What I missed, and where to reread it
% 
%% Review — retrieval
% Still keeping the Recap collapsed: from album track 03 (Find Me in the Noise, 
% track03/track03_find_me_in_the_noise_demo), how many bits long is the BCH 
% codeword that carries the MIB? Type the number into myAnswer and run this 
% section. Then, in one line, say what the CRC on the decoded MIB tells the 
% phone, and what it would do if the CRC failed. The check asks nrBCH and does 
% not print its value.
% 
% Why:
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    okReview = myAnswer == numel(nrBCH(zeros(24,1), 0, 0, 8, 0, 0));   % second route: encode a zero MIB (SFN 0, half-frame 0, Lmax 8, k_SSB 0, PCI 0)
    reviewCheck = table("BCH codeword bits", okReview, ...
        VariableNames = {'Check', 'Pass'});
    reviewCheck
end
