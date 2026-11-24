%% track02_copy_the_tail_demo
%% Copy the Tail (album track 02): the cyclic prefix, one tap per tone, windowing, and EVM
% This demonstration turns a grid of numbers into an OFDM waveform and shows 
% why every OFDM symbol carries a copy of its own tail in front.
% 
% The IFFT turns one column of the grid into one block of time samples. The 
% cyclic prefix (CP) copies the last few samples of that block to the front. 
% Because of that copy, echoes shorter than the prefix become one complex gain 
% on each subcarrier, which the receiver removes with one divide per tone.
%% Guiding question
% Why does copying the tail of each OFDM symbol to its front let a receiver 
% undo the echoes with one divide per subcarrier?
% This demonstration
% 1. B1 — Fill a 15 kHz, 52-RB grid, OFDM-modulate it with no windowing, and 
% check that each prefix equals its symbol's tail and that 624 of 1024 FFT bins 
% carry tones.
% 
% 2. B2 — Pass the waveform through echoes that fit inside the prefix and equalize 
% it with one tap per subcarrier; then push one echo past the prefix and watch 
% it break.
% 
% 3. B3 — Turn on windowing and measure the trade: lower sidebands against 
% a smaller echo margin.
% 
% 4. B4 — Measure EVM by hand: first with noise added to the time samples, 
% then with a carrier frequency offset of 5 % of the spacing.
% 
% 5. B5 — Run the full path: nrDLCarrierConfig, nrWaveformGenerator, demodulate, 
% and land back on the generator's own grid.
% 
% 6. Build it — Configure a carrier yourself, read its FFT size and guard bins, 
% and check one prefix against its tail.
% Key relationships
% The toolbox picks the default FFT size as the smallest power of two (at least 
% 128) that keeps the occupied tones at or below 85 % of the bins:
% 
% $$N_{\mathrm{FFT}} = \min\{2^n \ge 128 : 12\,N_{\mathrm{RB}} \le 0.85\cdot 
% 2^n\},\qquad f_s = N_{\mathrm{FFT}}\cdot\Delta f$$
% 
% Every echo that arrives within the prefix leaves one complex gain per subcarrier:
% 
% $$Y_\ell(k) = H(k)\,X_\ell(k)\quad\text{when every delay}\le N_{\mathrm{CP}}$$
% 
% Windowing over W samples leaves an echo margin of about
% 
% $$\text{margin} \approx N_{\mathrm{CP}} - W$$
% 
% With noise added to the time samples at a signal-to-noise ratio SNR (a power 
% ratio, not dB), only K of the N_FFT bins carry signal, so
% 
% $$\mathrm{EVM} \approx 100\sqrt{\frac{K}{N_{\mathrm{FFT}}\cdot\mathrm{SNR}}}\ \%$$
% Key ideas to remember
% • The IFFT is wider than the carrier: K = 12 × NSizeGrid tones sit in N_FFT 
% bins, and the empty bins on either side are the guard. The toolbox picks N_FFT; 
% you do not set it to K.
% 
% • The cyclic prefix is a copy of the last N_CP samples of the symbol body, 
% placed in front. It is not zeros.
% 
% • When every echo is shorter than the prefix, the channel acts on the body 
% as a circular convolution, so after the FFT it is one complex gain per subcarrier, 
% the same in every symbol while the channel holds still. One known symbol is 
% enough to learn it.
% 
% • Push an echo past the prefix and the symbol before bleeds in: tones leak 
% into each other, and no single divide fixes it.
% 
% • Windowing rounds the symbol edges and lowers the sidebands, but it spends 
% prefix samples: the echo margin left is about N_CP − W. The generator's windowing 
% starts at zero; the modulator's default is not zero.
% 
% • EVM is the RMS error over the RMS reference, in percent. Noise added to 
% the time samples lands on every bin, not only the K that carry tones.
% 
% • A carrier frequency offset leaks each tone into its neighbours; removing 
% the common phase does not undo that leak, and an offset of 5 % of the spacing 
% is already past the 8 % limit for 64-QAM.
% Prerequisites
% • The resource grid, RBs, the 14-symbol slot, μ, nrCarrierConfig, nrResourceGrid, 
% and nrOFDMInfo (album track 01 Two to the Mu, track01/track01_two_to_the_mu_demo).
% 
% • One IFFT per OFDM symbol, the sample rate, and the cyclic prefix as a copied 
% tail (track 00 Fundamentals, track00_fundamentals/p00a_ofdm_and_cp_demo).
% 
% • The DFT, RMS (root mean square), and complex numbers as a gain and a twist. 
% Circular convolution is stated in B2 and shown by its one-tap check, not proved.
% Words used in this demo
% • Subcarrier (tone): one narrow frequency channel, one row of the grid. Subcarrier 
% spacing (SCS, Δf): the distance between neighbouring subcarriers, in kHz.
% 
% • RB (resource block): 12 neighbouring subcarriers. K: the number of occupied 
% subcarriers, 12 × NSizeGrid.
% 
% • FFT size (N_FFT, Nfft): the number of points in each IFFT; bin: one of 
% those points. Guard bins: the bins with no tone, N_FFT − K of them.
% 
% • Sample rate (f_s): samples sent each second, in Hz.
% 
% • Cyclic prefix (CP, N_CP): the copied tail in front of each symbol, counted 
% in samples. Body: the N_FFT samples after the prefix.
% 
% • Waveform: the stream of complex time samples the transmitter sends.
% 
% • Echo, tap, equalizer, windowing, EVM, SNR, CFO, ICI, and the channel names 
% in B5 are defined in the beat where they first appear, under New words.
% Key code terms to remember
% Each entry gives the purpose, the inputs, and the outputs. Commands you write 
% yourself (in the Build it, the Try its, and the exercises) get their own entry; 
% small helpers are grouped into families. Commands used in only one beat are 
% listed at the start of that beat.
% 
% Commands you write
% • x(i:j), x(list), and end — Purpose: read the entries from position i to 
% position j, or at a list of positions; inside the brackets, end means the 
% last position. Inputs: an array and positions. Outputs: those entries.
% 
% • f(Name = value, ...) — Purpose: give a function named inputs. Inputs: input 
% names and values. Outputs: what the function returns.
% 
% • s.Name and s.Name(n) — Purpose: read one property of an object or field 
% of a structure, or entry n of it. Inputs: the object and the name. Outputs: 
% its value.
% 
% • carrier = nrCarrierConfig(Name = value, ...) — Purpose: describe one carrier. 
% Inputs: SubcarrierSpacing (kHz), NSizeGrid (RBs), and others. Outputs: a carrier 
% object.
% 
% • info = nrOFDMInfo(carrier) — Purpose: report the OFDM settings the toolbox 
% picks. Inputs: a carrier. Outputs: a structure with Nfft, SampleRate (Hz), 
% CyclicPrefixLengths and SymbolLengths (samples, one per symbol of a 1 ms subframe), 
% and Windowing (samples).
% 
% • grid = nrResourceGrid(carrier) — Purpose: make an empty one-slot grid. Inputs: 
% a carrier. Outputs: a K × 14 array of zeros.
% 
% • wave = nrOFDMModulate(carrier, grid, Windowing = W) — Purpose: turn a grid 
% into time samples, one IFFT and one prefix per symbol. Inputs: a carrier, a 
% grid, and the windowing length W in samples (0 = none). Outputs: a column of 
% complex samples (and, as a second output, the OFDM information).
% 
% • max(abs(a − b)) — Purpose: the largest difference between two arrays of 
% the same size; 0 means they are identical. Inputs: two arrays. Outputs: one 
% number.
% 
% Commands you read in the given code
% • grid = nrOFDMDemodulate(carrier, wave, CyclicPrefixFraction = 1) — Purpose: 
% undo nrOFDMModulate: drop each prefix and take one FFT per symbol. Inputs: a 
% carrier, a waveform, and where in the prefix the FFT window starts (1 = at 
% its end). Outputs: a K × L grid. Used in every beat.
% 
% • evmPct(ref, rx) — Purpose: the EVM helper defined in Staging. Inputs: the 
% reference and the received values. Outputs: EVM in percent.
% 
% Families you read in the given code
% • Punctuation: ; ... % %% — Purpose: hide the echo; continue a line; start 
% a comment; start a section. Inputs: a statement or text. Outputs: none shown.
% 
% • Indexing and ranges: x(n), x(n) = v, a:b, x(:), x.', G(:, cols), G(rows, 
% :) — Purpose: read or write entries, count a range, reshape to a column or 
% row, pick columns or rows. Inputs: an array and positions. Outputs: the entries 
% or the changed array.
% 
% • Compare and combine: == ~= < > <= >=, && || & | ~, .* ./ .^ — Purpose: compare 
% values; and, or, not; multiply, divide, and power entry by entry. Inputs: numbers 
% or arrays. Outputs: true/false or numbers, entry by entry.
% 
% • Control flow: for ... end, if ... else ... end — Purpose: repeat a block 
% for each value of a list; run one block or the other. Inputs: a list or a 
% true/false test. Outputs: whatever the blocks store.
% 
% • Built-in helpers: zeros, false, numel, nnz, size, sum, mean, all, any, max, 
% abs, conj, sqrt, exp, angle, real, imag, round, ceil, floor, log2, log10, sin, pi, 
% unique, find, repmat, randi, isequal, exist, isnan, NaN, [] — Purpose: make 
% filled arrays, count, add, average, test, round, take powers and logs, and 
% look things up. Inputs: numbers, arrays, or names. Outputs: numbers or true/false 
% (NaN means "no number yet").
% 
% • Complex numbers: 1j, abs, angle, exp(1j*θ) — Purpose: the imaginary unit; 
% the size and the angle of a complex number; a unit-size twist by θ radians. 
% Inputs: numbers. Outputs: numbers.
% 
% • Text: 'text', "text", "a" + "b", string, strjoin, compose, sprintf, and 
% f = @(v) ... — Purpose: write and join text, turn numbers into text, fill 
% a format, and make a one-line helper such as listText or evmPct. Inputs: text, 
% numbers, a format. Outputs: text, or a function.
% 
% • Tables, checks, and housekeeping: table(..., VariableNames = {...}), assert(test, 
% message), fprintf, disp, clear, close all, rng — Purpose: show columns side 
% by side, stop with a hint when a check fails, print a banner or note, remove 
% variables or figures, repeat random values. Inputs: columns, a test and message, 
% text, names, a seed. Outputs: a shown table or line; an error if a check fails.
% Requirements
% Requires the 5G Toolbox; the optional comm.EVM cross-check in B4 also needs 
% the Communications Toolbox and is skipped without it. Teaching demo, not 
% production code; not affiliated with or endorsed by MathWorks.
%% Staging for script

clear; close all;   % empty workspace and no open figures, so every run starts from the same state
rng(2026);          % fixed random seed (any whole number works; 2026 is the album year), so the random QPSK data and the B4 noise repeat on every run

% listText turns a list of numbers into one line of text, for example
% [1 2 4] becomes "1 2 4", so one row of a check table can show a whole list.
% It is kept to the end of the file because every check table uses it.
listText = @(v) strjoin(string(v(:).'), " ");

% evmPct is the EVM by hand: the root-mean-square (RMS) error between the
% received values rx and the reference ref, over the RMS of the reference,
% in percent. ref(:) and rx(:) turn any grid into one column first. It is
% kept through B5, because every beat measures EVM, and cleared after it.
evmPct = @(ref, rx) 100*sqrt(sum(abs(rx(:)-ref(:)).^2) / sum(abs(ref(:)).^2));
%% B1 — Grid to IFFT to prefix
% New words
% • Occupied bins: the K FFT bins that carry a tone. Guard bins: the N_FFT − 
% K empty bins on either side.
% 
% • Long and normal prefix: the first symbol of each 0.5 ms half-subframe has 
% a slightly longer prefix than the others; nrOFDMInfo lists one length per symbol.
% 
% • Windowing: a smooth taper on the symbol edges (B3). B1 turns it off with 
% Windowing = 0, so the prefix is an exact copy.
% 
% Beat-only commands (B1)
% • fft(x) — Purpose: the discrete Fourier transform, the inverse of one OFDM 
% IFFT. Inputs: N_FFT time samples. Outputs: N_FFT complex bins.
% 
% • Figure family: figure(Name = ...), plot, hold on, xline, xlabel, ylabel, 
% legend, grid on, title — Purpose: open a figure, draw lines, keep drawing on 
% the same axes, mark a position, and label the plot. Inputs: data and text. 
% Outputs: a figure. Used in B1 to B3 and in Build it.
% Why it matters
% Echoes make the radio channel a linear filter that smears each symbol into 
% the next. The prefix is what lets the receiver undo that with one complex 
% divide per tone (B2) instead of a long time-domain equalizer.
% 
% OFDM places K tones into an N_FFT-bin IFFT, and the cyclic prefix copies the 
% tail of each body to the front. The default N_FFT is the smallest power of 
% two that keeps the tones at or below 85 % of the bins, and the sample rate 
% is N_FFT × Δf. For the 15 kHz, 52-RB carrier the song sings about, that gives 
% 1024 bins with 624 tones, and 400 bins sit quiet.
% What to look for
% • In the carrier table, read K, Nfft, and GuardBins, then the two prefix lengths 
% in samples and in μs.
% 
% • In the waveform table, read the two CP copy errors: how big are they next 
% to the size of the samples?
% 
% • Count the active bins and compare with K. In the figure, check that the 
% dashed tail sits exactly on the prefix.
% Common mistakes
% Do not think of the prefix as zeros: it is the end of the body, copied.
% 
% Do not set N_FFT = K. K = 624 is not a power of two, and the toolbox would 
% not pick it.
% Try it (personal exploration)
% Use the FFT-size rule in Key relationships to predict the default N_FFT for 
% a 15 kHz carrier that is 106 RBs wide. Type that number into myPrediction 
% in the first code line below before you run this section. After the tables, 
% a given one-row table shows your prediction beside the toolbox's answer for 
% the Try carrier.
% 
% The Try carrier is built separately from tryNSizeGrid, so the main carrier 
% stays at 52 RBs and every later beat still runs. You may change tryNSizeGrid 
% to 25 or any other width and predict again.

% Try it: type your prediction here (a number of FFT bins) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so
tryNSizeGrid = 106;   % Try-it carrier width in RBs at 15 kHz; only the one-row Try table uses it

% B1 — Grid to IFFT to prefix
fprintf("B1 — Grid to IFFT to prefix\n");   % banner title only; every number below goes into a table

% Build the carrier the song sings about and read back what the toolbox
% derives from it. These numbers are read, not typed, so the checks below
% test the toolbox's own choices.
carrier = nrCarrierConfig( ...
    SubcarrierSpacing = 15, ...   % subcarrier spacing in kHz (μ = 0)
    NSizeGrid         = 52, ...   % grid width in RBs: 52 RB is the 10 MHz carrier at 15 kHz
    NStartGrid        = 0);       % grid starts at common RB 0; the start does not change any count here
ofdm   = nrOFDMInfo(carrier);                                 % Nfft, SampleRate, prefix lengths, default Windowing
K      = 12*carrier.NSizeGrid;                                % occupied subcarriers: 12 per RB
Lframe = carrier.SymbolsPerSlot*carrier.SlotsPerFrame;        % OFDM symbols in one 10 ms frame
Nfft   = ofdm.Nfft;                                           % FFT size the toolbox picked, in bins
fs     = ofdm.SampleRate;                                     % sample rate in Hz
cpLong = ofdm.CyclicPrefixLengths(1);                         % long prefix (first symbol of each half-subframe), samples
cpNorm = ofdm.CyclicPrefixLengths(2);                         % normal prefix (every other symbol), samples

% The lyric sings "624 of 1024 bins" for this carrier with the default FFT
% size. The test is stored first so the check table reports it.
% Second route for both numbers: K is counted as the rows of an empty grid,
% and the FFT size is tested against the rule itself: a power of two, at
% least 128, with K at or below 85 % of it, and half of it too small.
Kgrid      = size(nrResourceGrid(carrier), 1);                % occupied subcarriers, counted as grid rows
nfftIsRule = (Nfft >= 128) && (2^round(log2(Nfft)) == Nfft) && (Kgrid <= 0.85*Nfft) && ...
             (Nfft == 128 || Kgrid > 0.85*Nfft/2);              % 0.85: the 85 % limit; Nfft/2 would not hold K
okSungBins = nfftIsRule && (Nfft == 1024) && (Kgrid == 624);  % the sung values: 1024 bins, 624 tones
assert(okSungBins, ...
    'Sung claim: 624 of 1024 bins. Look first at the nrCarrierConfig lines: 15 kHz and NSizeGrid = 52, with no Nfft given to nrOFDMInfo.');

% The default sample rate is the FFT size times the spacing. Second route:
% count the samples in one 1 ms subframe (every prefix plus every body, from
% SymbolLengths) and scale to one second, without reading SampleRate.
okSampleRate = sum(ofdm.SymbolLengths)*1e3 == Nfft*carrier.SubcarrierSpacing*1e3;   % ×1e3: per 1 ms to per second; 1e3: kHz to Hz
assert(okSampleRate, ...
    'The samples per second are not Nfft times the spacing. Common mistake: the spacing is in kHz; multiply by 1e3 for Hz.');

% Fill one 10 ms frame with random QPSK, one slot at a time, so the
% waveform below is a whole frame of known data. Each pass makes one empty
% slot grid and fills every RE; the slots are joined side by side.
txGrid = [];
for ns = 0:carrier.SlotsPerFrame-1
    carrier.NSlot = ns;                                       % slot number in the frame, so each grid belongs to its own slot
    g = nrResourceGrid(carrier);                              % K × 14 zeros (album track 01)
    g(:) = ((1-2*randi([0 1],K,carrier.SymbolsPerSlot)) + ...
          1j*(1-2*randi([0 1],K,carrier.SymbolsPerSlot)))/sqrt(2);   % random QPSK: each part is +1 or -1, and 1/sqrt(2) makes the power 1
    txGrid = [txGrid g];                                      %#ok<AGROW> one slot added on the right
end
carrier.NSlot = 0;                                            % back to slot 0, so the modulator starts the frame at its first slot

% The carrier in one row: what the toolbox picked, in samples and in time.
b1Carrier = table(carrier.SubcarrierSpacing, carrier.NSizeGrid, K, Nfft, Nfft-K, ...
    fs/1e6, cpLong, cpNorm, cpLong/fs*1e6, cpNorm/fs*1e6, ...
    VariableNames = {'SCS_kHz', 'NSizeGrid', 'K', 'Nfft', 'GuardBins', ...
                     'fs_MHz', 'CPlong', 'CPnormal', 'CPlong_us', 'CPnormal_us'});
b1Carrier

% OFDM-modulate the whole frame with windowing off, so each prefix is an
% exact copy. modInfo reports what the modulator actually used.
[wave0, modInfo] = nrOFDMModulate(carrier, txGrid, Windowing = 0);   % Windowing = 0 samples: no taper

% A frame always lasts 10 ms, so it holds fs × 10 ms samples, prefixes included.
okFrameLength = size(wave0,1) == round(fs*10e-3);             % 10e-3 s = one 10 ms frame
assert(okFrameLength, ...
    'The waveform is not 10 ms long. Look first at txGrid: it should hold all 140 symbols, one slot added per pass of the loop.');
okWindowingOff = modInfo.Windowing == 0;
assert(okWindowingOff, ...
    'The modulator used windowing. Look first at the nrOFDMModulate line: it needs Windowing = 0.');

% Symbol 0: its long prefix followed by its body. The prefix is the first
% cpLong samples; the tail is the last cpLong samples of the body.
sym0     = wave0(1:cpLong+Nfft);                              % prefix + body of symbol 0
cpPart   = sym0(1:cpLong);
tailPart = sym0(end-cpLong+1:end);
cpError0 = max(abs(cpPart - tailPart));
okCopy0  = cpError0 <= 1e-12*max(abs(sym0));                  % 1e-12 of the largest sample: rounding only
assert(okCopy0, ...
    'Symbol 0''s prefix is not a copy of its tail. Common mistake: comparing the prefix with the start of the body instead of its end.');

% Symbol 1 starts after symbol 0's prefix and body, and has a normal prefix.
s1Start  = cpLong + Nfft;                                     % samples before symbol 1
sym1     = wave0(s1Start+1 : s1Start+cpNorm+Nfft);
cpError1 = max(abs(sym1(1:cpNorm) - sym1(end-cpNorm+1:end)));
okCopy1  = cpError1 <= 1e-12*max(abs(sym1));                  % 1e-12 of the largest sample: rounding only
assert(okCopy1, ...
    'Symbol 1''s prefix is not a copy of its tail. Look first at s1Start: symbol 1 begins after the long prefix and one body.');

% Take the FFT of symbol 0's body only (no prefix) and count the bins with
% energy. Bins below a millionth of the largest are counted as empty.
B          = abs(fft(sym0(cpLong+1:end)));
activeBins = sum(B > 1e-6*max(B));                            % 1e-6: far above rounding, far below any tone
okBins     = activeBins == K;
assert(okBins, ...
    'The number of active bins is not K. Look first at the fft line: it must take the body only, sym0(cpLong+1:end), not the prefix.');

% Demodulate with the FFT window at the end of each prefix: pure body, so a
% clean waveform comes back exactly.
rxGridA = nrOFDMDemodulate(carrier, wave0, CyclicPrefixFraction = 1);   % 1 = FFT window starts at the end of the prefix
okDemodSize = isequal(size(rxGridA), size(txGrid));
assert(okDemodSize, ...
    'The demodulated grid has the wrong size. Look first at the carrier passed to nrOFDMDemodulate: it must be the one used to modulate.');
roundTripError = max(abs(rxGridA(:) - txGrid(:)));
okRoundTrip = roundTripError < 1e-9;                          % 1e-9: rounding only, for unit-power QPSK
assert(okRoundTrip, ...
    'The clean round trip is not exact. Look first at CyclicPrefixFraction: with 1 the window holds the body only.');

% The waveform in one row: length, the two copy errors, and the bins.
b1Waveform = table(size(wave0,1), 1e3*size(wave0,1)/fs, cpError0, cpError1, ...
    activeBins, Nfft-activeBins, evmPct(txGrid, rxGridA), ...
    VariableNames = {'FrameSamples', 'Frame_ms', 'CPCopyError0', 'CPCopyError1', ...
                     'ActiveBins', 'GuardBins', 'RoundTripEVM_pct'});
b1Waveform

% Mechanism figure: symbol 0 sample by sample, with the tail of the body
% drawn again under the prefix it was copied into.
figure(Name = 'Track 02 B1 - one OFDM symbol, the prefix is a copy of the tail', Color = 'w');
plot(0:numel(sym0)-1, real(sym0));
hold on;
plot(0:cpLong-1, real(tailPart), '--');                       % tail drawn under the prefix
xline(cpLong-0.5, '-k', 'end of CP');                         % -0.5 puts the line between the last prefix sample and the first body sample
xlabel('sample');
ylabel('real part');
grid on;
legend('symbol 0: CP + body', 'tail of the body, shifted under the CP');
title('The prefix is the last CP-length samples, copied to the front');

% Put your Try-it prediction beside the toolbox's FFT size for the Try
% carrier. The Try carrier is separate, so the main carrier is unchanged.
tryInfo = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = tryNSizeGrid));   % 15 kHz, tryNSizeGrid RBs
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b1Prediction = table(myPrediction, tryNSizeGrid, tryInfo.Nfft, predictionNote, ...
    VariableNames = {'MyPrediction', 'TryNSizeGrid', 'TryNfft', 'Note'});
b1Prediction
%% B1 — After the run
% Read the carrier table first: K is 12 per RB, Nfft is the next power of two 
% that keeps K at or below 85 % of the bins, and GuardBins is what is left. 
% The long prefix is a few samples longer than the normal one, and both last 
% only a few μs. In the waveform table, both copy errors are at rounding level, 
% so each prefix is its symbol's tail sample for sample, and the active bins 
% equal K. The round trip comes back exactly. In the figure, the dashed tail 
% lies on top of the prefix. Compare the Try carrier's Nfft with your prediction.
%% B1 — Assertion checks

% One row per assert in B1. Expected is the value the rule gives; Actual is
% what the toolbox or the waveform returned. Pass is computed from the
% stored flags. The asserts stop the run on a failure, so this table appears
% only when every check has passed, and shows the evidence.
b1Checks = table( ...
    ["Sung claim: K = 624 of Nfft = 1024 (K as grid rows; Nfft fits the 85 % rule)"; ...
     "Samples in 1 ms × 1000 = Nfft × SCS (Hz)"; ...
     "Frame samples = fs × 10 ms"; ...
     "Modulator windowing = 0"; ...
     "Symbol 0: max |CP − tail| at rounding level"; ...
     "Symbol 1: max |CP − tail| at rounding level"; ...
     "Active FFT bins = K"; ...
     "Demodulated grid size = transmitted grid size"; ...
     "Clean round trip: max error < 1e-9"], ...
    [listText([624 1024]); ...
     string(Nfft*carrier.SubcarrierSpacing*1e3); ...
     string(round(fs*10e-3)); ...
     "0"; ...
     "<= " + string(1e-12*max(abs(sym0))); ...
     "<= " + string(1e-12*max(abs(sym1))); ...
     string(K); ...
     listText(size(txGrid)); ...
     "< 1e-09"], ...
    [listText([Kgrid Nfft]); ...
     string(sum(ofdm.SymbolLengths)*1e3); ...
     string(size(wave0,1)); ...
     string(modInfo.Windowing); ...
     string(cpError0); ...
     string(cpError1); ...
     string(activeBins); ...
     listText(size(rxGridA)); ...
     string(roundTripError)], ...
    [okSungBins; okSampleRate; okFrameLength; okWindowingOff; ...
     okCopy0; okCopy1; okBins; okDemodSize; okRoundTrip], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b1Checks
%% B1 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep carrier, ofdm, K, Lframe, Nfft, fs, cpLong, cpNorm, txGrid, and wave0
% for the later beats, and listText and evmPct for every check. Everything
% else was used only to build, test, or show B1.
clear b1Carrier b1Waveform b1Checks b1Prediction predictionNote ...
      okSungBins okSampleRate okFrameLength okWindowingOff okCopy0 okCopy1 ...
      okBins okDemodSize okRoundTrip ...
      ns g modInfo sym0 cpPart tailPart cpError0 s1Start sym1 cpError1 Kgrid nfftIsRule ...
      B activeBins rxGridA roundTripError tryInfo tryNSizeGrid myPrediction
%% B2 — Echoes inside the prefix: one tap per tone, then break it
% New words
% • Echo (path): a delayed, weaker copy of the signal, for example off a building. 
% Delay spread: how far the last echo lags the first.
% 
% • Tap: one complex gain applied at one delay. A one-tap equalizer divides 
% each subcarrier by one complex number, H(k).
% 
% • Circular convolution: a filter that wraps the end of a block back onto its 
% start. After an FFT it becomes a plain multiply, bin by bin.
% 
% • ISI and ICI: inter-symbol interference (the symbol before bleeds into this 
% one) and inter-carrier interference (each tone leaks onto its neighbours).
% 
% Beat-only commands (B2)
% • y = filter(h, 1, x) — Purpose: pass the samples x through the echo taps 
% h, one delayed copy per tap. Inputs: the taps h (tap n+1 is the gain at a delay 
% of n samples), 1 (no feedback), and the samples x. Outputs: the filtered samples, 
% the same length as x.
% 
% • tiledlayout(r, c), nexttile, axis equal — Purpose: put several plots in 
% one figure; move to the next one; draw I and Q to the same scale. Inputs: 
% the rows and columns. Outputs: the figure layout.
% Why it matters
% When every echo falls inside the prefix, the FFT window sees only this symbol, 
% with its own tail wrapped back around. That is a circular convolution, and 
% after the FFT it is one complex gain and one twist per subcarrier, the same 
% in every symbol while the channel holds still. So one known symbol is enough 
% to learn H(k) and equalize the whole frame. The okOneTap check below is the 
% evidence for this beat; the wrap-around itself is stated, not proved.
% 
% Push one echo past the prefix and the symbol before bleeds in. The tones leak 
% into each other, and no single divide fixes it.
% What to look for
% • In the results table, read InsideCP_EVM: after the one-tap equalizer it 
% should be at rounding level.
% 
% • Then read BrokenEVM, and compare LongCP_EVM with NormalCP_EVM. Which group 
% of symbols does the late echo hurt?
% 
% • In the figure, the left panel is |H(k)|, one gain per subcarrier; the right 
% panel is the constellation after the broken channel.
% Common mistakes
% Do not assume "some prefix is enough": compare the last echo's delay with 
% the actual prefix length, in samples or μs.
% 
% Do not learn a new H(k) on every symbol when the channel does not change: 
% one known symbol is enough.
% Try it (personal exploration)
% In the Break it block below, the late echo is set by lastEcho (in samples). 
% Set lastEcho = 80 and predict how many of the frame's 140 symbols come out 
% clean (EVM below 1e-6 %) when H is learned from symbol 0. Type that number 
% into myPrediction before you run this section; the one-row table at the end 
% compares it with the measured count.
% 
% Also try lastEcho = 72 (exactly one normal prefix). Leave dly alone: its check 
% guards the clean case. Every check in this section tests a relationship, 
% so changing lastEcho does not stop the run.

% Try it: type your prediction here (a number of symbols) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B2 — Echoes inside the prefix
fprintf("B2 — Echoes inside the prefix: one tap per tone\n");   % banner title only

% A direct path plus two echoes, all inside the normal prefix. dly is in
% samples at fs; amp gives each path a gain and a twist.
dly = [0 17 51];                                              % path delays in samples: 0, about 1.1 μs, about 3.3 μs at 15.36 MHz
amp = [1 0.5*exp(1j*0.7) 0.25*exp(-1j*1.9)];                  % path gains: size 1, 0.5, 0.25, with twists of 0.7 and -1.9 rad

% The design itself: every echo must fit in the normal prefix.
okDesignInsideCP = max(dly) < cpNorm;
assert(okDesignInsideCP, ...
    'An echo in dly is not inside the prefix. Look first at dly: every delay must be below the normal prefix, cpNorm samples.');

% Build the taps (tap n+1 is the gain at delay n) and pass the waveform
% through them. filter is a linear convolution, as the air would apply.
h = zeros(max(dly)+1,1);  h(dly+1) = amp;                     % +1: tap 1 is delay 0
rxB = filter(h, 1, wave0);                                    % 1 = no feedback: a pure echo filter
rxGridB = nrOFDMDemodulate(carrier, rxB, CyclicPrefixFraction = 1);   % 1 = FFT window at the end of the prefix

% The channel seen on every RE: received over sent. If the echoes fit, it
% is one number per subcarrier, the same down every column.
Hall = rxGridB ./ txGrid;
hSpread = max(abs(Hall - Hall(:,2)), [], 'all');              % largest change of H from one symbol to another
okOneTap = hSpread < 1e-9;                                    % 1e-9: rounding only
assert(okOneTap, ...
    'H(k) changes from symbol to symbol. Look first at dly: an echo past the prefix makes H depend on the data.');

% Learn H from one known symbol (column 2) and divide every RE by it.
Hhat  = rxGridB(:,2) ./ txGrid(:,2);
eqB   = rxGridB ./ Hhat;                                      % one complex divide per RE
evmIn = evmPct(txGrid, eqB);
okEqualized = evmIn < 1e-6;                                   % 1e-6 %: rounding only
assert(okEqualized, ...
    'The one-tap equalizer did not clean the frame. Common mistake: dividing by H from a different channel than the one in rxB.');

% Break it on purpose: move the last echo past the prefix and learn H
% from symbol 0, a long-prefix symbol.
lastEcho = 120;                                               % Try: 80 (delay of the last echo in samples)
dlyX = [0 17 lastEcho];                                       % same first two paths, last one moved
hX = zeros(max(dlyX)+1,1);  hX(dlyX+1) = amp;                 % +1: tap 1 is delay 0
rxX = filter(hX, 1, wave0);                                   % 1 = no feedback: a pure echo filter
rxGridX = nrOFDMDemodulate(carrier, rxX, CyclicPrefixFraction = 1);   % 1 = FFT window at the end of the prefix
HhatX = rxGridX(:,1) ./ txGrid(:,1);                          % learn H from symbol 0
eqX   = rxGridX ./ HhatX;
evmOut = evmPct(txGrid, eqX);

% Split the frame by prefix length. ofdm.CyclicPrefixLengths covers one
% 1 ms subframe, so it is repeated to cover all Lframe symbols.
cpVecB = repmat(ofdm.CyclicPrefixLengths, 1, ceil(Lframe/numel(ofdm.CyclicPrefixLengths)));
isLong = cpVecB(1:Lframe) > cpNorm;                           % true for each long-prefix symbol
evmLongCP = evmPct(txGrid(:,isLong),  eqX(:,isLong));
evmNormCP = evmPct(txGrid(:,~isLong), eqX(:,~isLong));

% EVM of each symbol on its own (one column at a time), and how many are clean.
% The count includes symbol 0, the symbol H is learned from, which is clean
% by construction; the column name says so.
evmPerSymbol  = 100*sqrt(sum(abs(eqX - txGrid).^2, 1) ./ sum(abs(txGrid).^2, 1));   % sum over dimension 1: one EVM per column (symbol), %
nCleanSymbols = nnz(evmPerSymbol < 1e-6);                     % 1e-6 %: rounding only

% An echo past even the long prefix must leave visible damage. When the
% echo still fits the long prefix the test is true by design.
okBroken = (lastEcho <= cpLong) || (evmOut > 1);              % 1 %: far above rounding
assert(okBroken, ...
    'An echo past the prefix left no damage. Look first at lastEcho and dlyX: the late echo must use lastEcho.');

% The two experiments in one row.
b2Results = table(evmIn, lastEcho, lastEcho/fs*1e6, evmOut, evmLongCP, evmNormCP, nCleanSymbols, ...
    VariableNames = {'InsideCP_EVM_pct', 'LastEcho', 'LastEcho_us', 'BrokenEVM_pct', ...
                     'LongCP_EVM_pct', 'NormalCP_EVM_pct', 'CleanSymbols_IncludesSym0'});
b2Results

% Mechanism figure: the one tap per subcarrier, and the broken constellation.
figure(Name = 'Track 02 B2 - one tap per subcarrier, and breaking it', Color = 'w');
tiledlayout(1,2);
nexttile;
plot(abs(Hhat));
grid on;
xlabel('subcarrier k');
ylabel('|H(k)|');
title('Echoes inside the CP: one complex tap per subcarrier');
nexttile;
plot(real(eqX(:,2:20)), imag(eqX(:,2:20)), '.');              % symbols 1 to 19: enough points to see the spread
axis equal;
grid on;
xlabel('I');
ylabel('Q');
title(sprintf('Last echo at %d samples: EVM %.1f %%', lastEcho, evmOut));

% Put your Try-it prediction beside the measured count of clean symbols.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b2Prediction = table(myPrediction, lastEcho, nCleanSymbols, predictionNote, ...
    VariableNames = {'MyPrediction', 'LastEcho', 'CleanSymbols_IncludesSym0', 'Note'});
b2Prediction
%% B2 — After the run
% With every echo inside the prefix, InsideCP_EVM is at rounding level: one 
% complex divide per subcarrier, learned from one symbol, cleaned the whole 
% frame, and the left panel shows that gain changing across the band. When 
% lastEcho is past both prefixes, BrokenEVM is several percent and the 
% constellation is a cloud: the symbol before has bled in. CleanSymbols_IncludesSym0 
% counts symbol 0, the symbol H was learned from, which is always clean: a 
% count of 1 means no other symbol survived. Compare LongCP_EVM with NormalCP_EVM 
% for your Try value of lastEcho, and the CleanSymbols_IncludesSym0 count with 
% your prediction.
%% B2 — Assertion checks

% One row per assert in B2. Pass is computed from the stored flags.
b2Checks = table( ...
    ["Design: every echo delay < normal CP (samples)"; ...
     "One tap: max change of H across symbols < 1e-9"; ...
     "One-tap equalizer EVM < 1e-6 %"; ...
     "Echo past the long CP leaves EVM > 1 % (true by design when lastEcho <= long CP)"], ...
    ["< " + string(cpNorm); ...
     "< 1e-09"; ...
     "< 1e-06"; ...
     "> 1 if lastEcho > " + string(cpLong)], ...
    [string(max(dly)); ...
     string(hSpread); ...
     string(evmIn); ...
     "lastEcho " + string(lastEcho) + ", EVM " + string(evmOut)], ...
    [okDesignInsideCP; okOneTap; okEqualized; okBroken], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b2Checks
%% B2 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep the B1 names for the later beats. Everything made in B2 was used
% only to build, test, or show B2.
clear b2Results b2Checks b2Prediction predictionNote ...
      okDesignInsideCP okOneTap okEqualized okBroken ...
      dly amp h rxB rxGridB Hall hSpread Hhat eqB evmIn ...
      lastEcho dlyX hX rxX rxGridX HhatX eqX evmOut ...
      cpVecB isLong evmLongCP evmNormCP evmPerSymbol nCleanSymbols myPrediction
%% B3 — Windowing trade: sidebands against echo margin
% New words
% • Sidebands (out-of-band power, OOB): energy that splashes outside the carrier's 
% own band, onto its neighbours.
% 
% • Windowing (WOLA, window and overlap-add): rounding each symbol's edges with 
% a raised-cosine taper over W samples and overlapping each symbol with the next.
% 
% • Echo margin: how late an echo may arrive and still be removed by one tap. 
% With windowing it is about N_CP − W samples.
% 
% • PSD (power spectral density): how the power is spread over frequency, here 
% in dB relative to the in-band level.
% 
% Beat-only commands (B3)
% • fftshift(X) — Purpose: move the zero-frequency bin to the middle, so a spectrum 
% plots from −f_s/2 to +f_s/2. Inputs: FFT bins. Outputs: the same bins, reordered.
% 
% • cos — Purpose: the cosine, used here to make the Hann (raised-cosine) window 
% for the spectrum estimate. Inputs: angles in radians. Outputs: numbers.
% Why it matters
% Hard edges on every symbol splash the spectrum out the sides. Windowing rounds 
% them off, and the sidebands drop, which helps the neighbouring carrier. The 
% cost is paid in prefix samples: to dodge the taper, the receiver starts its 
% FFT window W samples early, and the echo margin left is about N_CP − W.
% 
% The two tools have two defaults. The generator's windowing (nrDLCarrierConfig, 
% B5) starts at zero; the modulator's default Windowing (nrOFDMModulate, read 
% from nrOFDMInfo) is the largest taper the EVM test can spare.
% What to look for
% • In the setup table, read the default Windowing in samples and in μs, next 
% to the normal prefix.
% 
% • In the trade table, read OOB_dB down the rows as W grows, then the Margin 
% column and the echo EVM column together.
% 
% • In the figure, compare the sidebands outside the dotted band edges.
% Common mistakes
% Do not window for a prettier spectrum and then forget that an echo that used 
% to fit in the prefix may now land in the taper.
% 
% Do not compare the long-prefix symbols with one H learned from a normal-prefix 
% symbol: this beat scores the normal-prefix symbols only, so one H fits every 
% symbol it scores.
% Try it (personal exploration)
% The echo in this beat arrives dTest samples late. Run this section once as 
% it is and read DefaultWindowing and the W values in its tables. Then set 
% dTest = 60 and, using margin ≈ N_CP − W, predict for how many of the W values 
% the echo EVM stays clean (below 1e-6 %). Type that number into myPrediction 
% and run the section again.
% 
% The WOLA margin rule is a model of where the taper sits, so this beat reports 
% it rather than asserting it. Set strictWOLA = true only when you want the 
% model's predictions to stop the run if they fail.
% 
% Main path: echo margin ≈ N_CP − W. Optional detail, for a second pass: the 
% EVM_atCPEnd and EVM_early columns.

% Try it: type your prediction here (a number of W values) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B3 — Windowing trade
fprintf("B3 — Windowing trade: sidebands against echo margin\n");   % banner title only

% The modulator's default windowing for this carrier, and three windowing
% lengths to compare: none, half the default, and the default.
wDef  = ofdm.Windowing;                                       % toolbox default windowing for this carrier, samples
Wlist = unique([0 round(wDef/2) wDef]);                       % windowing lengths to compare, samples

% Spectrum estimate set-up: the waveform is cut into Nseg-sample pieces,
% each multiplied by a Hann window, and the power of their FFTs averaged.
Nseg = 4096;                                                  % samples per spectrum segment (frequency step fs/Nseg = 3.75 kHz)
win  = 0.5 - 0.5*cos(2*pi*(0:Nseg-1).'/Nseg);                 % Hann window, by hand
fAxis = (-Nseg/2:Nseg/2-1).' * fs/Nseg;                       % frequency of each shifted bin, Hz
edge  = K*carrier.SubcarrierSpacing*1e3/2;                    % half the occupied bandwidth, Hz
oobMask = abs(fAxis) > edge + 0.5e6;                          % out of band: 0.5 MHz or more past the band edge
inMask  = abs(fAxis) < edge;                                  % in band

% Which symbols have a normal prefix? The long-prefix symbols are left out
% of this beat's EVM so that one H, learned from a normal-prefix symbol,
% fits every symbol scored here.
cpVec  = repmat(ofdm.CyclicPrefixLengths, 1, 10);             % 10 subframes: one prefix length per symbol of the frame
normIx = find(cpVec == cpNorm);

% The test echo: a direct path plus one echo dTest samples late, with gain 0.5 (a quarter of the power, −6 dB).
dTest = cpNorm - round(3*wDef/4);                             % Try: 60 (echo delay in samples)
hT = zeros(dTest+1,1);  hT([1 dTest+1]) = [1 0.5];            % gains: 1 on the direct path, 0.5 on the echo

% The WOLA placement behind the predictions: a raised-cosine taper of W
% samples, with the clean FFT window started W samples early, leaving
% N_CP - W samples of echo margin. The EVM experiment confirms or refutes it;
% strictWOLA turns the predictions into asserts.
strictWOLA = false;                                           % true: a failed WOLA prediction stops the run

% Reserve one entry per windowing length for each measured value and flag.
nW       = numel(Wlist);
oobdB    = zeros(nW,1);   % sidebands relative to in-band, dB
evmF1    = zeros(nW,1);   % no echo, FFT window at the end of the prefix, %
evmEarly = zeros(nW,1);   % no echo, FFT window started W samples early, %
evmEcho  = zeros(nW,1);   % echo at dTest, FFT window started W samples early, %
expectClean = false(nW,1);   % the margin model says the echo fits
okEarly  = false(nW,1);   % window started W early is clean
okEcho   = false(nW,1);   % echo EVM agrees with the margin model
psd      = zeros(Nseg,nW);   % one averaged spectrum per windowing length

% For each windowing length: modulate, measure the spectrum, then
% demodulate three ways and score the normal-prefix symbols.
for n = 1:nW
    W  = Wlist(n);
    wv = nrOFDMModulate(carrier, txGrid, Windowing = W);      % W samples of taper

    % Average the windowed power spectrum over every whole segment of the
    % frame. Each pass adds one segment's power.
    nS = floor(size(wv,1)/Nseg);
    P  = zeros(Nseg,1);
    for s = 0:nS-1
        seg = wv(s*Nseg+1:(s+1)*Nseg) .* win;
        P = P + abs(fftshift(fft(seg))).^2;
    end
    P = P/nS;
    psd(:,n) = P;
    oobdB(n) = 10*log10(mean(P(oobMask)) / mean(P(inMask)));

    % (1) No echo, FFT window at the end of the prefix: it reaches into
    % the tapered tail.
    r1 = nrOFDMDemodulate(carrier, wv, CyclicPrefixFraction = 1);   % 1 = window at the end of the prefix
    evmF1(n) = evmPct(txGrid(:,normIx), r1(:,normIx));

    % (2) No echo, FFT window started W samples early. fEarly is the
    % fraction of the normal prefix before the window starts.
    fEarly = (cpNorm - W)/cpNorm;
    r2 = nrOFDMDemodulate(carrier, wv, CyclicPrefixFraction = fEarly);
    H2 = r2(:,2)./txGrid(:,2);                                % one H from symbol 1, a normal-prefix symbol
    evmEarly(n) = evmPct(txGrid(:,normIx), r2(:,normIx)./H2);
    okEarly(n)  = evmEarly(n) < 1e-6;                         % 1e-6 %: rounding only
    assert(~strictWOLA || okEarly(n), ...
        'A window started W samples early is not clean. Look first at fEarly: it should be (cpNorm - W)/cpNorm. If it is, the WOLA model is wrong for this release; report it.');

    % (3) Echo at dTest samples, window started W samples early. The model
    % says it is clean when dTest fits in the margin N_CP - W.
    r3 = nrOFDMDemodulate(carrier, filter(hT,1,wv), CyclicPrefixFraction = fEarly);   % 1 in filter = no feedback
    H3 = r3(:,2)./txGrid(:,2);                                % one H from symbol 1
    evmEcho(n) = evmPct(txGrid(:,normIx), r3(:,normIx)./H3);
    expectClean(n) = dTest <= cpNorm - W;
    okEcho(n) = (expectClean(n) && evmEcho(n) < 1e-6) || ...  % inside the margin: rounding only
                (~expectClean(n) && evmEcho(n) > 0.1);        % past the margin: 0.1 % is far above rounding
    assert(~strictWOLA || okEcho(n), ...
        'The echo EVM disagrees with margin = CP - W. Look first at dTest and Wlist. If they are as given, the WOLA model is wrong for this release; report it.');
end

% Windowing must lower the sidebands: the largest W against no windowing.
okSidebands = oobdB(end) < oobdB(1);
assert(okSidebands, ...
    'Windowing did not lower the sidebands. Look first at the Windowing input in the loop: it must be W, not 0.');

% The set-up in one row, and the trade in one table, one row per W.
b3Setup = table(wDef, wDef/fs*1e6, cpNorm, dTest, strictWOLA, ...
    VariableNames = {'DefaultWindowing', 'DefaultWindowing_us', 'CPnormal', 'EchoAt', 'StrictWOLA'});
b3Setup
b3Trade = table(Wlist(:), cpNorm - Wlist(:), oobdB, evmF1, evmEarly, evmEcho, expectClean, ...
    VariableNames = {'W', 'Margin', 'OOB_dB', 'EVM_atCPEnd_pct', 'EVM_early_pct', ...
                     'EVM_echo_pct', 'ModelSaysClean'});
b3Trade

% Mechanism figure: the averaged spectrum for each W, with the band edges.
figure(Name = 'Track 02 B3 - windowing and the sidebands', Color = 'w');
plot(fAxis/1e6, 10*log10(psd ./ max(psd(:))));
grid on;
xline([-edge edge]/1e6, ':k');                                % occupied band edges
xlabel('frequency (MHz)');
ylabel('PSD (dB, normalized)');
legend("Windowing = " + string(Wlist), Location = 'south');
title('Windowing tames the sidebands; the cost is paid in CP samples');

% Put your Try-it prediction beside the measured count of clean W values.
nCleanW = nnz(evmEcho < 1e-6);                                % 1e-6 %: rounding only
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b3Prediction = table(myPrediction, dTest, nCleanW, predictionNote, ...
    VariableNames = {'MyPrediction', 'EchoAt', 'CleanW', 'Note'});
b3Prediction
%% B3 — After the run
% Read OOB_dB down the trade table: each larger W lowers the sidebands, and 
% the figure shows the skirts falling outside the band edges. Then read Margin 
% beside EVM_echo_pct: where the echo still fits the margin the EVM is at rounding 
% level, and where it does not, the EVM jumps. That jump is the delay-spread 
% cost of windowing. ModelSaysClean is the N_CP − W prediction; where it disagrees 
% with the EVM, the simple margin model and the toolbox's windowing placement 
% differ, and the measured EVM is the one to trust. Compare CleanW with your prediction.
%% B3 — Assertion checks

% One row per assert in B3. The two WOLA rows are asserted only when
% strictWOLA is true; their Pass is computed either way, so the table shows
% whether the model held in this run.
b3Checks = table( ...
    ["Window started W early is clean, every W (asserted only if strictWOLA)"; ...
     "Echo EVM follows margin = CP − W, every W (asserted only if strictWOLA)"; ...
     "Largest W lowers the sidebands (dB)"], ...
    ["< 1e-06 for W = " + listText(Wlist); ...
     "clean where ModelSaysClean: " + listText(expectClean); ...
     "< " + string(oobdB(1))], ...
    [listText(compose("%.2g", evmEarly)); ...
     listText(compose("%.2g", evmEcho)); ...
     string(oobdB(end))], ...
    [all(okEarly); all(okEcho); okSidebands], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b3Checks
%% B3 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Keep the B1 names for B4 and B5. Everything made in B3 was used only to
% build, test, or show B3.
clear b3Setup b3Trade b3Checks b3Prediction predictionNote ...
      okEarly okEcho okSidebands expectClean strictWOLA ...
      wDef Wlist Nseg win fAxis edge oobMask inMask cpVec normIx dTest hT ...
      nW oobdB evmF1 evmEarly evmEcho psd n W wv nS P s seg ...
      r1 fEarly r2 H2 r3 H3 nCleanW myPrediction
%% B4 — EVM by hand: noise, then a frequency offset
% New words
% • Error vector: what you received minus what you sent, on one RE. EVM (error 
% vector magnitude): the RMS of the error over the RMS of the reference, in percent.
% 
% • SNR (signal-to-noise ratio): signal power over noise power. Here it is a 
% time-domain SNR: measured on the time samples over the full sample rate. 
% In dB, SNR_dB = 10 log10(SNR).
% 
% • CFO (carrier frequency offset): the receiver's carrier is off by a fraction 
% ε of the subcarrier spacing. Common phase: the one rotation shared by every 
% tone of a symbol, which one twist per symbol removes.
% 
% • 64-QAM: a 64-point constellation. The base-station EVM limit for 64-QAM 
% in TS 38.104 is 8 %.
% 
% Beat-only commands (B4)
% • randn(size(x)) — Purpose: random numbers with a normal (Gaussian) spread, 
% mean 0 and power 1, the same size as x. Inputs: a size. Outputs: an array.
% 
% • comm.EVM — Purpose: the Communications Toolbox's EVM measurer, used only 
% as a cross-check. Inputs: the reference and the received values. Outputs: 
% RMS EVM in percent. Skipped if that toolbox is not installed.
% Why it matters
% For noise added to the time samples, the noise lands on every one of the 
% N_FFT bins, but only K of them carry signal. So the SNR on each subcarrier 
% is SNR × N_FFT/K, and EVM ≈ 100 √(K/(N_FFT·SNR)) %.
% 
% A CFO of a fraction ε of the spacing leaves a sinc gain on each wanted tone, 
% sin(πε)/(πε), and leaks the rest of the power onto the neighbours (ICI). One 
% common-phase twist per symbol removes the rotation, not the leak, so the EVM 
% model is 100 √((1 − sc²) + (1 − sc)²) %, with sc the sinc gain. Neither model 
% is derived here; the measurements in this beat are the evidence for both.
% What to look for
% • Type a prediction first; then, in the prediction table, compare EVM_measured 
% with EVM_model at the chosen SNR.
% 
% • Then read CFO_EVM next to CFO_model and the 64-QAM limit.
% Common mistakes
% Do not use EVM = 100/√SNR when the SNR was measured on the time samples. That 
% formula is for an SNR per resource element.
% 
% Do not compare a raw CFO constellation with a limit before removing the common 
% phase of each symbol.
% Try it (personal exploration)
% Use the EVM rule in Key relationships to predict the EVM, in percent, at 
% a time-domain SNR of 25 dB for this carrier (K and N_FFT are in B1's carrier 
% table). Type that number into myPrediction before you run this section; the 
% one-row table at the end compares it with the measured value.
% 
% Then, optionally, change snrdB or eps0 and predict again, or find the eps0 
% that puts the CFO model just under 8 %. Every check here compares the measurement 
% with its own model, so these changes do not stop the run.

% Try it: type your prediction here (an EVM in percent) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B4 — EVM by hand
fprintf("B4 — EVM by hand: noise, then a frequency offset\n");   % banner title only

% D1 noise. snrdB is the time-domain SNR over the full sample rate.
snrdB = 25;                                                   % time-domain SNR in dB
snr   = 10^(snrdB/10);                                        % the same SNR as a power ratio
Ps    = mean(abs(wave0).^2);                                  % average signal power per sample
noise = sqrt(Ps/snr/2) * (randn(size(wave0)) + 1j*randn(size(wave0)));   % /2: half the noise power in I, half in Q
rxN   = nrOFDMDemodulate(carrier, wave0 + noise, CyclicPrefixFraction = 1);   % 1 = FFT window at the end of the prefix
evmNoise = evmPct(txGrid, rxN);
evmPred  = 100*sqrt(K/(Nfft*snr));                            % the time-domain-SNR EVM rule, %
okNoiseModel = abs(evmNoise/evmPred - 1) < 0.05;              % within 5 % of the prediction: random noise is never exact
assert(okNoiseModel, ...
    'The noise EVM does not match 100*sqrt(K/(Nfft*SNR)). Common mistake: scaling the noise to an SNR per subcarrier instead of per time sample.');

% Optional cross-check with comm.EVM, if the Communications Toolbox is on
% the path. Its default normalization is the average reference power, the
% same as evmPct. Without it, the test is true and the table says skipped.
hasCommEVM = exist('comm.EVM','class') == 8;                  % 8 = a class exists on the path
if hasCommEVM
    evmObj = comm.EVM;
    rmsEVM = evmObj(txGrid(:), rxN(:));
    commEVMText = string(rmsEVM);
else
    rmsEVM = NaN;
    commEVMText = "skipped: comm.EVM not on the path";
end
okCommEVM = ~hasCommEVM || abs(rmsEVM - evmNoise) < 1e-6;     % 1e-6 percentage points: rounding only
assert(okCommEVM, ...
    'comm.EVM disagrees with the hand formula. Look first at the input order of evmObj(reference, received) for your release.');

% D2 carrier frequency offset of a fraction eps0 of the spacing: a common
% phase per symbol (fixable) plus leakage between tones (not fixable with
% one tap).
eps0 = 0.05;                                                  % CFO as a fraction of the subcarrier spacing (5 %)
fo   = eps0*carrier.SubcarrierSpacing*1e3;                    % the same offset in Hz
t    = (0:size(wave0,1)-1).'/fs;                              % time of each sample, s
rxC  = nrOFDMDemodulate(carrier, wave0 .* exp(1j*2*pi*fo*t), CyclicPrefixFraction = 1);   % 1 = FFT window at the end of the prefix
cpe  = angle(sum(conj(txGrid).*rxC, 1));                      % one common phase per symbol, rad
rxCc = rxC .* exp(-1j*cpe);                                   % undo each symbol's common phase
evmCFO = evmPct(txGrid, rxCc);
sc = sin(pi*eps0)/(pi*eps0);                                  % gain left on the wanted subcarrier (sinc)
evmCFOpred = 100*sqrt((1 - sc^2) + (1 - sc)^2);               % leakage + gain loss, %
okCFOModel = abs(evmCFO/evmCFOpred - 1) < 0.10;               % within 10 %: the model counts a full grid, this grid is 624 of 1024 bins
assert(okCFOModel, ...
    'The CFO EVM does not match the sinc-leakage model. Look first at cpe and rxCc: the common phase of each symbol must be removed first.');

% The noise numbers stay hidden until a prediction is typed, so a first run
% does not hand over the Try answer.
noiseShown = ~isnan(myPrediction);
hideText   = "hidden until you type a prediction";
if noiseShown
    noiseText = string(evmNoise);
else
    noiseText = hideText;
    commEVMText = hideText;
end

% Both experiments in one row, beside the 64-QAM limit. The noise model
% value is shown only in the prediction table below.
b4Results = table(snrdB, noiseText, commEVMText, fo, evmCFO, evmCFOpred, 8, ...   % 8 % = TS 38.104 base-station EVM limit for 64-QAM
    VariableNames = {'SNR_dB', 'EVM_measured_pct', 'commEVM_pct', ...
                     'CFO_Hz', 'CFO_EVM_pct', 'CFO_model_pct', 'Limit64QAM_pct'});
b4Results

% Put your Try-it prediction beside the measured noise EVM and the model.
if noiseShown
    b4Prediction = table(myPrediction, snrdB, evmNoise, evmPred, "Compare the three numbers", ...
        VariableNames = {'MyPrediction', 'SNR_dB', 'EVM_measured_pct', 'EVM_model_pct', 'Note'});
else
    b4Prediction = table(myPrediction, snrdB, "No prediction typed: set myPrediction at the top of this section and run it again", ...
        VariableNames = {'MyPrediction', 'SNR_dB', 'Note'});
end
b4Prediction
%% B4 — After the run
% Once you have typed a prediction, the prediction table shows the measured 
% noise EVM beside the model: they sit within a few percent, because the noise 
% was spread over all N_FFT bins and only K of them carry the signal. If comm.EVM 
% ran, it gives the same number as evmPct. The frequency offset, even with the 
% common phase removed, leaves an EVM close to the sinc-leakage model, and it 
% is past the 8 % limit for 64-QAM: a small offset is a large error.
%% B4 — Assertion checks

% One row per assert in B4. Pass is computed from the stored flags. The
% noise rows wait for a prediction, as above.
if noiseShown
    noiseExpected = [string(evmPred) + " ± 5 %"; string(evmNoise)];
else
    noiseExpected = [hideText; hideText];
end
b4Checks = table( ...
    ["Noise EVM within 5 % of 100·sqrt(K/(Nfft·SNR))"; ...
     "comm.EVM agrees with evmPct (skipped without the Communications Toolbox)"; ...
     "CFO EVM within 10 % of the sinc-leakage model"], ...
    [noiseExpected; string(evmCFOpred) + " ± 10 %"], ...
    [noiseText; commEVMText; string(evmCFO)], ...
    [okNoiseModel; okCommEVM; okCFOModel], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b4Checks
%% B4 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% B5 builds its own waveform, so only listText and evmPct are still needed
% after this beat. Everything else from B1 to B4 is cleared here.
clear b4Results b4Checks b4Prediction predictionNote noiseShown hideText noiseText noiseExpected ...
      okNoiseModel okCommEVM okCFOModel hasCommEVM evmObj rmsEVM commEVMText ...
      snrdB snr Ps noise rxN evmNoise evmPred ...
      eps0 fo t rxC cpe rxCc evmCFO sc evmCFOpred myPrediction ...
      carrier ofdm K Lframe Nfft fs cpLong cpNorm txGrid wave0
%% B5 — The full path: generator to grid
% New words (a preview: these channels are taught later, or not at all)
% • SSB (synchronization signal block): the block a phone searches for first 
% (album track 03, Find Me in the Noise). Disabled here.
% 
% • PDSCH (the downlink data channel, album track 05, Say It Again), PDCCH 
% (the downlink control channel, not covered in the album), and BWP (bandwidth 
% part: a configured block of the carrier's RBs, not covered). Read them as "things 
% that occupy REs".
% 
% • Occupied RE: an RE the generator filled; every other RE of its grid is zero.
% 
% Beat-only commands (B5)
% • cfg = nrDLCarrierConfig(Name = value, ...) — Purpose: describe a whole 
% downlink carrier: its band, bandwidth, length, and channels. Inputs: FrequencyRange, 
% ChannelBandwidth (MHz), NumSubframes, WindowingPercent, and others. Outputs: 
% a configuration object; its SSBurst property holds the SSB settings.
% 
% • [wave, info] = nrWaveformGenerator(cfg) — Purpose: build that whole carrier 
% as a waveform. Inputs: the configuration. Outputs: the samples, and info, 
% whose ResourceGrids(1) holds the OFDM Info (Nfft, SampleRate, Windowing) and 
% the grid it sent, ResourceGridInCarrier.
% 
% • nrOFDMDemodulate(..., Nfft = N, SampleRate = fs) — Purpose: demodulate with 
% the generator's own FFT size and rate. Inputs: as before, plus those two values. 
% Outputs: the grid.
% Why it matters
% nrWaveformGenerator runs the whole downlink at once: the carrier, its channels, 
% the OFDM modulation, and the grid it filled. Demodulating its waveform with 
% the same N_FFT and sample rate must land back on that grid wherever an RE 
% was occupied. That is the same round trip as B1, done by the toolbox's own 
% generator. Count the samples: a frame is always ten milliseconds of them. 
% A frame is 10 ms; this waveform is NumSubframes ms long (one subframe is 
% 1 ms), so it can be shorter or longer than one frame.
% What to look for
% • In the results table, read Nfft, fs_MHz, and Windowing: compare Windowing 
% with B3's default.
% 
% • Read the number of occupied REs and the round-trip EVM on them.
% Common mistakes
% Do not compare the demodulated grid with a handmade PDSCH-only grid: compare 
% it with the generator's own ResourceGridInCarrier.
% 
% Do not leave the SSB enabled and then wonder why extra REs appear.
% Try it (personal exploration)
% Set NumSubframes = 4 in the nrDLCarrierConfig line and predict how many samples 
% the waveform holds. Type that number into myPrediction before you run this 
% section; the one-row table at the end compares it with the waveform's length. 
% The length check uses NumSubframes, so it holds for any value.

% Try it: type your prediction here (a number of samples) before running this section.
myPrediction = NaN;   % your Try-it guess; NaN means "not typed yet", and the comparison table below says so

% B5 — The full path
fprintf("B5 — The full path: generator to grid\n");   % banner title only

% The generator's defaults give one 15 kHz, 52-RB carrier with one BWP, a
% PDCCH, and a PDSCH. Windowing is set to 0 so the round trip is exact.
cfg = nrDLCarrierConfig( ...
    FrequencyRange   = 'FR1', ...   % frequency range 1 (below about 7 GHz)
    ChannelBandwidth = 10, ...      % channel bandwidth in MHz: 52 RB at 15 kHz
    NumSubframes     = 10, ...      % waveform length in 1 ms subframes (Try: 4)
    WindowingPercent = 0);          % windowing as a percent of the FFT length: 0 = none, so the round trip is exact
cfg.SSBurst.Enable = false;         % no SSB, so the comparison is with what ResourceGridInCarrier holds
[waveE, infoE] = nrWaveformGenerator(cfg);
gi   = infoE.ResourceGrids(1).Info;                           % the generator's OFDM settings
refE = infoE.ResourceGrids(1).ResourceGridInCarrier;          % the grid it sent

% NumSubframes subframes of 1 ms each, prefixes included.
okGeneratorLength = size(waveE,1) == round(gi.SampleRate*cfg.NumSubframes*1e-3);   % 1e-3 s per subframe
assert(okGeneratorLength, ...
    'The generator waveform is not NumSubframes ms long. Look first at gi: read SampleRate from infoE.ResourceGrids(1).Info.');

% Demodulate with a carrier of the same spacing and width, and the
% generator's own FFT size and sample rate, then compare occupied REs only.
carE = nrCarrierConfig( ...
    SubcarrierSpacing = 15, ...      % kHz, as in the generator's default carrier
    NSizeGrid         = 52, ...      % RBs, as in the generator's default carrier
    NStartGrid        = 0, ...       % common RB 0; the demodulated grid size does not depend on it
    NCellID           = cfg.NCellID);   % the generator's cell ID
rxE  = nrOFDMDemodulate(carE, waveE, Nfft = gi.Nfft, SampleRate = gi.SampleRate, ...
                        CyclicPrefixFraction = 1);   % 1 = FFT window at the end of the prefix
used = abs(refE) > 0;                                         % occupied REs only
evmE = evmPct(refE(used), rxE(used));
okGeneratorRoundTrip = evmE < 1e-6;                           % 1e-6 %: rounding only
assert(okGeneratorRoundTrip, ...
    'The generator round trip is not exact. Look first at WindowingPercent (it must be 0) and at Nfft and SampleRate in the demodulator.');

% The generator's choices and the round trip in one row.
b5Results = table(gi.Nfft, gi.SampleRate/1e6, gi.Windowing, size(refE,1), size(refE,2), ...
    size(waveE,1), nnz(used), evmE, ...
    VariableNames = {'Nfft', 'fs_MHz', 'Windowing', 'GridRows', 'GridColumns', ...
                     'Samples', 'OccupiedREs', 'RoundTripEVM_pct'});
b5Results

% Put your Try-it prediction beside the waveform's length.
if isnan(myPrediction)
    predictionNote = "No prediction typed: set myPrediction at the top of this section and run it again";
else
    predictionNote = "Compare the two numbers";
end
b5Prediction = table(myPrediction, cfg.NumSubframes, size(waveE,1), predictionNote, ...
    VariableNames = {'MyPrediction', 'NumSubframes', 'Samples', 'Note'});
b5Prediction
%% B5 — After the run
% The generator picked the same N_FFT and sample rate as B1, with no windowing, 
% because WindowingPercent was set to 0; the modulator's default in B3 was not 
% zero: two tools, two defaults. Its grid has one row per subcarrier and one 
% column per symbol of the waveform, and on every occupied RE the demodulated 
% value matches what the generator sent, to rounding. Compare Samples with your 
% prediction.
%% B5 — Assertion checks

% One row per assert in B5. Pass is computed from the stored flags.
b5Checks = table( ...
    ["Generator samples = fs × NumSubframes × 1 ms"; ...
     "Generator round trip on occupied REs: EVM < 1e-6 %"], ...
    [string(round(gi.SampleRate*cfg.NumSubframes*1e-3)); ...
     "< 1e-06"], ...
    [string(size(waveE,1)); ...
     string(evmE)], ...
    [okGeneratorLength; okGeneratorRoundTrip], ...
    VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});

b5Checks
%% B5 — Cleanup

% If a later section says a variable is undefined, run the script from the top
% (Run All): every name cleared here is created again on the way down.

% Only listText is needed after this beat (for the Build it checks).
clear b5Results b5Checks b5Prediction predictionNote ...
      okGeneratorLength okGeneratorRoundTrip ...
      cfg waveE infoE gi refE carE rxE used evmE myPrediction evmPct
%% Build it — Configure a carrier, read its FFT size, and check one prefix
% Competency: given a spacing and a width in RBs, build the carrier, read the 
% FFT size and the guard bins the toolbox picks, OFDM-modulate one slot with 
% no windowing, and show that symbol 1's prefix is a copy of its tail.
% Problem
% You are given mySCS = 30 (kHz) and myNRB = 24 (RBs). Build that carrier and 
% read its OFDM information. Predict its FFT size before you read it. Work 
% out K and the guard bins, then modulate one slot of random QPSK with windowing 
% switched off. Cut symbol 1 (the second symbol, which has a normal prefix) 
% out of the waveform and test that its prefix is a copy of its tail.
% Allowed commands
% nrCarrierConfig with Name = value inputs; nrOFDMInfo and its fields; reading 
% a property with a dot (myCarrier.Name, myInfo.Name(n)); nrResourceGrid; nrOFDMModulate 
% with Windowing = W; indexing x(i:j) and x(list); max(abs(a − b)); arithmetic. 
% The line that fills the grid with QPSK, the tables, and the figure in the 
% check sections and Stage 5 are given. These are in Key code terms to remember.
% How to work
% Each stage is a code section with lines that start with %. Delete the % in 
% front of the code lines (not the comment lines), fill any ___ blank, and run 
% that section. Then run the check section under it. A check never gives the 
% answer; it tells you what to look at. When a check passes, it shows a small 
% table of what it tested: name, expected, actual, and pass.
%% Stage 1 — switch it on
% Delete the % in front of the two code lines, then run this section.
% Pass: the check below prints Stage 1 OK.

% mySCS = 30;   % subcarrier spacing in kHz: given for this exercise (μ = 1)
% myNRB = 24;   % grid width in RBs: given; no carrier above uses this width, so every answer is new
%% Stage 1 check (given)
if ~exist('mySCS','var') || ~exist('myNRB','var')
    disp('Stage 1 not done: delete the % in front of the two code lines above, then run that section.')
else
    % Both given values must still be in place before the later stages use them.
    okStage1 = (mySCS == 30) && (myNRB == 24);   % the two values Stage 1 gives
    assert(okStage1, ...
        'Stage 1 values changed. Look first at the two lines you uncommented: they should set mySCS = 30 and myNRB = 24.')
    stage1Checks = table("mySCS and myNRB as given", listText([30 24]), ...   % expected: the given 30 kHz and 24 RB
        listText([mySCS myNRB]), okStage1, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage1Checks
    disp('Stage 1 OK')
end
%% Stage 2 — name and shape: the carrier and its OFDM information
% Rename c to myCarrier, the name the checks expect, fill the blanks from Stage 
% 1, and uncomment both lines.
% Pass: Stage 2 OK.

% c = nrCarrierConfig(SubcarrierSpacing = ___, NSizeGrid = ___);
% myInfo = nrOFDMInfo(___);
%% Stage 2 check (given)
if ~exist('myCarrier','var') || ~exist('myInfo','var')
    disp('Stage 2 not done: rename c to myCarrier, fill the blanks, uncomment, and run.')
else
    % The carrier must have the given spacing and width, and myInfo must
    % belong to it: its sample rate divided by its FFT size is the spacing.
    okStage2 = [myCarrier.SubcarrierSpacing == mySCS; ...
                myCarrier.NSizeGrid == myNRB; ...
                myInfo.SampleRate/myInfo.Nfft == 1e3*myCarrier.SubcarrierSpacing];   % 1e3: kHz to Hz
    assert(okStage2(1), ...
        'The spacing does not match mySCS. Look first at SubcarrierSpacing in your nrCarrierConfig line.')
    assert(okStage2(2), ...
        'The grid width does not match myNRB. Look first at NSizeGrid in your nrCarrierConfig line.')
    assert(okStage2(3), ...
        'myInfo does not belong to myCarrier. Look first at what you passed to nrOFDMInfo.')
    stage2Checks = table( ...
        ["SubcarrierSpacing (kHz) = mySCS"; "NSizeGrid = myNRB"; "myInfo: SampleRate / Nfft = spacing (Hz)"], ...
        [string(mySCS); string(myNRB); string(1e3*myCarrier.SubcarrierSpacing)], ...
        [string(myCarrier.SubcarrierSpacing); string(myCarrier.NSizeGrid); string(myInfo.SampleRate/myInfo.Nfft)], ...
        okStage2, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage2Checks
    disp('Stage 2 OK')
end
%% Stage 3a — predict first: the FFT size
% Before you read anything from myInfo, type your prediction: what FFT size 
% will the toolbox pick for this carrier? Work it out from the FFT-size rule 
% in Key relationships. Run this section and the check under it before you 
% start Stage 3b: the check does not take a prediction once Stage 3b's names 
% exist.
% Pass: Stage 3a OK.

% myPrediction = ___;
%% Stage 3a check (given; compares your prediction with the toolbox and does not print the toolbox's value)
if ~exist('myPrediction','var') || ~isnumeric(myPrediction) || ~isscalar(myPrediction) || isnan(myPrediction)
    disp('Stage 3a not done: type one number into myPrediction, uncomment, and run.')
elseif ~exist('myCarrier','var')
    disp('Stage 3a needs Stage 2 first: make myCarrier, then return here.')
elseif exist('myK','var') || exist('myNfft','var') || exist('myGuard','var')
    disp('Stage 3a refused: Stage 3b names already exist, so this is no longer a prediction. Run "clear myK myNfft myGuard", then predict again.')
else
    okPrediction3 = myPrediction == nrOFDMInfo(myCarrier).Nfft;   % the toolbox's own FFT size, a route different from your rule
    stage3aCheck = table("Prediction = the toolbox's FFT size", okPrediction3, ...
        VariableNames = {'Check', 'Pass'});
    stage3aCheck
    if okPrediction3
        myLockedPrediction = myPrediction;   % recorded before Stage 3b
        disp('Stage 3a OK')
    else
        disp('Stage 3a not yet. Look first at K for this carrier, then at the smallest power of two, at least 128, that keeps K at or below 85 % of the bins. Change myPrediction and run again.')
    end
end
%% Stage 3b — read the FFT size and work out the guard bins
% Fill the blanks: the occupied subcarriers K of this carrier, the FFT size 
% the toolbox picked (read it from myInfo), and the guard bins.
% Pass: your locked prediction and the FFT size you read appear side by side, 
% and Stage 3 OK.

% myK = ___;
% myNfft = ___;
% myGuard = ___;
%% Stage 3b check (given; the check counts the grid rows and divides the sample rate, routes different from yours)
if ~exist('myLockedPrediction','var')
    disp('Stage 3b waits for Stage 3a: make your prediction there first and get Stage 3a OK.')
elseif ~exist('myK','var') || ~exist('myNfft','var') || ~exist('myGuard','var')
    disp('Stage 3b not done: fill the blanks, uncomment, and run.')
else
    % Your locked prediction beside what you read, in one row.
    stage3Prediction = table(myLockedPrediction, myNfft, ...
        VariableNames = {'MyPrediction', 'MyNfft'});
    stage3Prediction

    % Different routes: K is the number of rows nrResourceGrid makes, and
    % the FFT size is the sample rate over the spacing in Hz.
    oracleK    = size(nrResourceGrid(myCarrier), 1);
    oracleNfft = myInfo.SampleRate / (1e3*myCarrier.SubcarrierSpacing);   % 1e3: kHz to Hz

    % Four tests: one catches the common mistake (Nfft = K), three compare
    % your values with the different routes.
    okStage3 = [myNfft ~= myK; ...
                myK == oracleK; ...
                myNfft == oracleNfft; ...
                myGuard == oracleNfft - oracleK];
    assert(okStage3(1), ...
        'myNfft equals K. Common mistake: the FFT is wider than the carrier; read Nfft from myInfo.')
    assert(okStage3(2), ...
        'K is not the number of occupied subcarriers. Look first at myK: count the subcarriers of every RB of this carrier.')
    assert(okStage3(3), ...
        'myNfft is not the toolbox''s FFT size. Look first at the field you read from myInfo.')
    assert(okStage3(4), ...
        'The guard bins are off. Look first at what the guard bins are: the bins with no tone.')
    stage3Checks = table( ...
        ["Nfft is not K"; "K = rows of nrResourceGrid"; "Nfft = SampleRate / spacing (Hz)"; ...
         "Guard bins = Nfft − K"], ...
        ["not " + string(myK); string(oracleK); string(oracleNfft); string(oracleNfft - oracleK)], ...
        [string(myNfft); string(myK); string(myNfft); string(myGuard)], ...
        okStage3, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage3Checks
    disp('Stage 3 OK')
end
%% Stage 4 — one slot, and symbol 1's prefix against its tail
% The first two lines are given: they make one slot and fill it with random 
% QPSK. Fill the blanks: modulate with windowing off; read symbol 1's prefix 
% length from myInfo; work out, from myInfo too, how many samples come before 
% symbol 1. Then test the copy without cutting the tail with end: compare each 
% prefix sample with the sample of mySym1 a fixed number of positions later. 
% Work that offset out from what the prefix is a copy of, and store it in myOffset.
% Pass: Stage 4 OK.

% myGrid = nrResourceGrid(myCarrier);
% myGrid(:) = ((1-2*randi([0 1],size(myGrid))) + 1j*(1-2*randi([0 1],size(myGrid))))/sqrt(2);   % given: random QPSK
% myWave = nrOFDMModulate(myCarrier, myGrid, Windowing = ___);
% myCP = ___;
% myStart = ___;
% mySym1 = myWave(myStart+1 : myStart+myCP+myNfft);
% myOffset = ___;
% myCopyError = max(abs(mySym1(1:myCP) - mySym1((1:myCP) + myOffset)));
%% Stage 4 check (given; the check reads the symbol lengths, a different route from yours)
if ~exist('myCopyError','var') || ~exist('mySym1','var') || ~exist('myStart','var') || ~exist('myOffset','var')
    disp('Stage 4 not done: fill the blanks, uncomment, and run.')
else
    % Different route: SymbolLengths lists prefix + body for each symbol,
    % so symbol 0's length is the samples before symbol 1, symbol 1's
    % length minus the FFT size is its prefix, and what is left after the
    % prefix is the distance from a prefix sample to its source.
    oracleStart  = myInfo.SymbolLengths(1);
    oracleCP     = myInfo.SymbolLengths(2) - myInfo.Nfft;
    oracleOffset = myInfo.SymbolLengths(2) - oracleCP;

    % Six tests: the start, the prefix length, the piece's length, an offset
    % that is not zero, the offset itself, and the copy (within rounding).
    okStage4 = [myStart == oracleStart; ...
                myCP == oracleCP; ...
                numel(mySym1) == oracleCP + myInfo.Nfft; ...
                myOffset ~= 0; ...
                myOffset == oracleOffset; ...
                myCopyError <= 1e-12*max(abs(mySym1))];   % 1e-12 of the largest sample: rounding only
    assert(okStage4(1), ...
        'Symbol 1 does not start where you cut it. Look first at myStart: everything symbol 0 occupies comes before symbol 1.')
    assert(okStage4(2), ...
        'myCP is not symbol 1''s prefix. Look first at which entry of CyclicPrefixLengths you read: entry 1 is symbol 0.')
    assert(okStage4(3), ...
        'mySym1 has the wrong length. Look first at the range in the mySym1 line: one prefix plus one body.')
    assert(okStage4(4), ...
        'myOffset is 0, so the prefix is compared with itself and the test cannot fail. Look first at where the copied samples came from.')
    assert(okStage4(5), ...
        'myOffset does not reach the samples the prefix was copied from. Look first at where the tail of mySym1 starts, counted from its first sample.')
    assert(okStage4(6), ...
        'The prefix is not a copy of the tail. Look first at Windowing: it must be off.')
    stage4Checks = table( ...
        ["Symbol 1 starts after SymbolLengths(1) samples"; "Prefix = SymbolLengths(2) − Nfft"; ...
         "Piece = one prefix + one body"; "Offset is not 0"; "Offset reaches the tail"; ...
         "max |CP − tail| at rounding level"], ...
        [string(oracleStart); string(oracleCP); string(oracleCP + myInfo.Nfft); "not 0"; ...
         "SymbolLengths(2) − prefix"; "<= " + string(1e-12*max(abs(mySym1)))], ...
        [string(myStart); string(myCP); string(numel(mySym1)); string(myOffset); ...
         string(okStage4(5)); string(myCopyError)], ...
        okStage4, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    stage4Checks
    disp('Stage 4 OK')
end
%% Stage 5 — confirm it does what it should (given)
% Run the whole script from the top (Run All), then read this table and the 
% figure, and write your interpretation in the text cell after them.

if ~exist('myCopyError','var') || ~exist('oracleCP','var') || ~exist('myGuard','var')
    disp('Stage 5 needs Stages 1 to 4 first: finish them, then Run All.')
else
    % The FFT-size rule, worked out from K alone: the smallest power of two,
    % at least 128, with K at or below 85 % of the bins.
    ruleNfft = max(128, 2^ceil(log2(myK/0.85)));              % 128 = smallest default FFT; 0.85 = the 85 % occupancy limit

    % Guard bins by a route you did not use: count the empty bins in an FFT
    % of symbol 1's body.
    bodyBins     = abs(fft(mySym1(oracleCP+1:end)));
    guardFromFFT = numel(bodyBins) - nnz(bodyBins > 1e-6*max(bodyBins));   % 1e-6: far above rounding, far below any tone

    % The normal prefix by the numerology rule: 144 samples for every 2048
    % bins of FFT size.
    cpFromRule = 144*myNfft/2048;

    % Each flag is computed from your results, so the table cannot say Pass by itself.
    buildFlags = [myNfft == ruleNfft; ...
        myGuard == guardFromFFT; ...
        myCP == cpFromRule; ...
        myCopyError <= 1e-12*max(abs(mySym1))];               % rounding only

    % One row per result: the rule's value, your value, and the computed flag.
    buildChecks = table( ...
        ["Nfft = smallest power of 2 (>= 128) with K <= 85 % of it"; ...
         "Guard bins = empty bins in an FFT of symbol 1's body"; ...
         "Normal prefix = 144 × Nfft / 2048 samples"; ...
         "Symbol 1: prefix is a copy of the tail (repeat of Stage 4)"], ...
        [string(ruleNfft); string(guardFromFFT); string(cpFromRule); ...
         "<= " + string(1e-12*max(abs(mySym1)))], ...
        [string(myNfft); string(myGuard); string(myCP); string(myCopyError)], ...
        buildFlags, ...
        VariableNames = {'Check', 'Expected', 'Actual', 'Pass'});
    buildChecks

    % The prefix in time as well as in samples.
    myCPus = myCP/myInfo.SampleRate*1e6;                      % 1e6: s to μs
    buildTiming = table(myCP, myCPus, ...
        VariableNames = {'CP_samples', 'CP_us'});
    buildTiming

    % Mechanism figure: symbol 1 of your carrier, with the end of its body
    % drawn again under its prefix. The tail's positions come from the
    % check's own route: SymbolLengths(2) is symbol 1's prefix + body, and
    % its last oracleCP samples are the tail.
    tailIdx = myInfo.SymbolLengths(2) - oracleCP + (1:oracleCP);   % positions of the tail inside mySym1
    figure(Name = 'Track 02 Build it - my carrier, symbol 1', Color = 'w');
    plot(0:numel(mySym1)-1, real(mySym1));
    hold on;
    plot(0:oracleCP-1, real(mySym1(tailIdx)), '--');          % tail drawn under the prefix
    xline(myCP-0.5, '-k', 'end of CP');                       % -0.5: between the last prefix sample and the first body sample
    xlabel('sample');
    ylabel('real part');
    grid on;
    legend('symbol 1: CP + body', 'tail of the body, shifted under the CP');
    title(sprintf('My carrier: %d kHz, %d RB, Nfft = %d', mySCS, myNRB, myNfft));
end
%% Build it — Interpretation
% Write yours first, before you run the check below (one or two sentences): 
% why did the toolbox pick this FFT size for K occupied subcarriers, and how 
% many bins are guard? How long does symbol 1's prefix last in μs, and why 
% does the figure show that it is a copy of the tail?
%% Build it — Check your interpretation
% Type a number into myAnswer, then run this section. Keep myNRB but switch 
% the spacing to 15 kHz: by what factor does symbol 1's prefix duration, in 
% μs, change? (Type 2 for twice as long, 0.5 for half as long.) The check works 
% it out with nrOFDMInfo and does not print the value.
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
elseif ~exist('myInfo','var') || ~exist('myNRB','var')
    disp('Run Stages 1 to 4 first, then return here.')
else
    info15   = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = myNRB));   % same width at 15 kHz
    factorCP = (info15.CyclicPrefixLengths(2)/info15.SampleRate) / ...
               (myInfo.CyclicPrefixLengths(2)/myInfo.SampleRate);
    okInterp = abs(myAnswer - factorCP) < 0.01;
    interpHint = "";
    if ~okInterp
        interpHint = "the spacing sets the symbol duration; the prefix is a fixed share of each symbol";
    end
    interpCheck = table("Prefix duration factor, 30 kHz to 15 kHz", okInterp, interpHint, ...
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
      okPrediction3 stage3aCheck stage3Prediction oracleK oracleNfft okStage3 stage3Checks ...
      oracleStart oracleCP oracleOffset okStage4 stage4Checks ...
      ruleNfft bodyBins guardFromFFT cpFromRule buildFlags buildChecks myCPus buildTiming tailIdx ...
      myAnswer info15 factorCP okInterp interpHint interpCheck
%% Follow-on exercises
% These go one step past the beats above: new values, a diagnosis, or an explanation. 
% Copying a code block from above and changing one number will not answer them. 
% Each exercise has a check: type your numbers into its myE variable and run 
% that section. The check works the values out by a second route (the toolbox, 
% or the rule from a different starting point), shows Pass or Fail with a pointer 
% for each entry, and never prints the value. Write the reasons on the Your 
% answer lines; the script does not grade them.
%% E1 — New values (B1, the FFT-size rule)
% A carrier uses 60 kHz spacing, normal CP, and 66 RBs. Without building it, 
% work out K, the default N_FFT, the guard bins, and the sample rate. The normal 
% prefix is 144 × N_FFT/2048 samples; how long is it in μs? Type the five numbers 
% into myE1 as [K, N_FFT, guard bins, sample rate in Hz, prefix in μs]. Then 
% explain why the prefix lasts half as long as at 30 kHz with the same N_FFT.
% 
% Your answer:
myE1 = NaN;   % [K, N_FFT, guard bins, sample rate (Hz), prefix (μs)]
if any(isnan(myE1)) || numel(myE1) ~= 5
    disp('Type five numbers into myE1, then run this section again.')
else
    e1Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 60, NSizeGrid = 66));   % second route: the toolbox
    e1K    = size(nrResourceGrid(nrCarrierConfig(SubcarrierSpacing = 60, NSizeGrid = 66)), 1);
    e1Ref  = [e1K, e1Info.Nfft, e1Info.Nfft - e1K, e1Info.SampleRate, ...
              1e6*e1Info.CyclicPrefixLengths(2)/e1Info.SampleRate];
    okE1   = abs(myE1(:) - e1Ref(:)) <= max(0.01*abs(e1Ref(:)), 1e-9);   % within 1 %
    e1Hint = ["subcarriers per RB"; "the FFT-size rule"; "bins with no tone"; "N_FFT times the spacing"; ...
              "prefix samples over the sample rate"];
    e1Hint(okE1) = "";
    e1Check = table(["K"; "N_FFT"; "Guard bins"; "Sample rate (Hz)"; "Normal prefix (μs)"], okE1, e1Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e1Check
end
%% E2 — Transfer (B2)
% In B2, H was learned from symbol 1 and every symbol was divided by it. Suppose 
% H had been learned from symbol 0 instead, which has the long prefix, with 
% the same three paths (delays 0, 17, and 51 samples). How many of the frame's 
% 140 symbols would come out clean? Type that number into myE2. Then say what 
% would stop one known symbol from being enough if the phone were moving fast, 
% even with every echo inside the prefix.
% 
% Your answer:
myE2 = NaN;   % clean symbols when H is learned from symbol 0
if isnan(myE2) || numel(myE2) ~= 1
    disp('Type one number into myE2, then run this section again.')
else
    e2Car  = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);
    e2Info = nrOFDMInfo(e2Car);
    e2Ref  = e2Car.SymbolsPerSlot*e2Car.SlotsPerFrame * (51 < min(e2Info.CyclicPrefixLengths));   % every symbol, if the last echo fits the shorter prefix
    okE2   = myE2 == e2Ref;
    e2Hint = "";
    if ~okE2
        e2Hint = "does H(k) depend on the prefix length, or on the echoes?";
    end
    e2Check = table("Clean symbols, H from symbol 0", okE2, e2Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e2Check
end
%% E3 — New values (B3)
% A 15 kHz, 52-RB carrier (normal prefix 72 samples at 15.36 MHz) uses W = 
% 24 samples of windowing. An echo arrives 60 samples after the direct path. 
% How long is that delay in μs? Using margin ≈ N_CP − W, is it removed by one 
% tap (1 = yes, 0 = no)? What is the largest W that would still let this echo 
% through cleanly? Type the three numbers into myE3 as [delay in μs, 1 or 0, 
% largest W].
% 
% Your answer:
myE3 = NaN;   % [delay (μs), removed by one tap (1/0), largest W (samples)]
if any(isnan(myE3)) || numel(myE3) ~= 3
    disp('Type three numbers into myE3, then run this section again.')
else
    e3Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52));   % second route: the toolbox's clock and prefix
    e3CP   = e3Info.CyclicPrefixLengths(2);
    e3Ref  = [1e6*60/e3Info.SampleRate, double(60 <= e3CP - 24), e3CP - 60];
    okE3   = abs(myE3(:) - e3Ref(:)) <= max(0.01*abs(e3Ref(:)), 1e-9);
    e3Hint = ["samples over the sample rate"; "compare the delay with the margin"; "margin = delay"];
    e3Hint(okE3) = "";
    e3Check = table(["Delay (μs)"; "Removed by one tap"; "Largest clean W"], okE3, e3Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e3Check
end
%% E4 — New values and diagnosis (B4)
% For the B1 carrier (K = 624, N_FFT = 1024), what EVM does the time-domain 
% rule predict at an SNR of 20 dB? What time-domain SNR, in dB, puts the EVM 
% exactly at the 8 % limit? A classmate plugs numbers into the same time-domain 
% rule and gets exactly 10 % at 20 dB. What value must they have used for N_FFT? 
% Type the three numbers into myE4 as [EVM in %, SNR in dB, their N_FFT], and 
% say why their N_FFT is wrong here.
% 
% Your answer:
myE4 = NaN;   % [EVM at 20 dB (%), SNR for 8 % (dB), the classmate's N_FFT]
if any(isnan(myE4)) || numel(myE4) ~= 3
    disp('Type three numbers into myE4, then run this section again.')
else
    e4Car  = nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52);
    e4N    = nrOFDMInfo(e4Car).Nfft;                       % second route: the toolbox's FFT size
    e4K    = size(nrResourceGrid(e4Car), 1);               % and its occupied subcarriers
    e4Ref  = [100*sqrt(e4K/(e4N*10^(20/10))), 10*log10(e4K/(e4N*0.08^2)), e4K*(10/100)^-2/10^(20/10)];
    okE4   = abs(myE4(:) - e4Ref(:)) <= max(0.01*abs(e4Ref(:)), 1e-9);
    e4Hint = ["SNR as a power ratio first"; "solve the rule for SNR"; "solve the same rule for N_FFT"];
    e4Hint(okE4) = "";
    e4Check = table(["EVM at 20 dB (%)"; "SNR for 8 % (dB)"; "Classmate's N_FFT"], okE4, e4Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e4Check
end
%% E5 — New values and diagnosis (B4, the CFO model)
% Work out the CFO model's EVM for an offset of 2 % of the spacing (ε = 0.02). 
% Is it under the 8 % limit for 64-QAM? A classmate removes each symbol's common 
% phase using the angle measured on the symbol before it, not its own. The 
% offset turns the phase by 2π ε over every N_FFT samples of time. For the 
% B1 carrier, by how many radians is each normal-prefix symbol still rotated 
% after their correction? Type both numbers into myE5 as [EVM in %, radians], 
% and say what that leftover rotation does to the constellation.
% 
% Your answer:
myE5 = NaN;   % [CFO model EVM at ε = 0.02 (%), leftover rotation (rad)]
if any(isnan(myE5)) || numel(myE5) ~= 2
    disp('Type two numbers into myE5, then run this section again.')
else
    e5Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52));
    e5sc   = sin(pi*0.02)/(pi*0.02);
    e5Ref  = [100*sqrt((1 - e5sc^2) + (1 - e5sc)^2), 2*pi*0.02*e5Info.SymbolLengths(2)/e5Info.Nfft];   % one normal-prefix symbol lasts SymbolLengths(2) samples
    okE5   = abs(myE5(:) - e5Ref(:)) <= max(0.01*abs(e5Ref(:)), 1e-9);
    e5Hint = ["the sinc gain sc first"; "time from one FFT window to the next, in samples"];
    e5Hint(okE5) = "";
    e5Check = table(["CFO model EVM (%)"; "Leftover rotation (rad)"], okE5, e5Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e5Check
end
%% E6 — Diagnosis (B1, Key code terms: x(i:j))
% Someone checks the prefix of symbol 1 straight from the waveform, with these 
% two lines, and the check always passes, even when they modulate with the 
% default windowing:
% 
% cpPart = wave0(s1Start+1 : s1Start+cpNorm);   tailPart = wave0(s1Start+1 : s1Start+cpNorm);
% 
% Why can this check never fail? Work out, for the B1 carrier, the first and 
% last positions of wave0 that tailPart should read, and type them into myE6 
% as [first, last]. Then write that range built from s1Start, cpNorm, and Nfft 
% (not from sym1 or end), and say why the default windowing would then make 
% it fail.
% 
% Your answer:
myE6 = NaN;   % [first, last] positions of symbol 1's tail in wave0
if any(isnan(myE6)) || numel(myE6) ~= 2
    disp('Type two numbers into myE6, then run this section again.')
else
    e6Info = nrOFDMInfo(nrCarrierConfig(SubcarrierSpacing = 15, NSizeGrid = 52));
    e6End  = sum(e6Info.SymbolLengths(1:2));                 % second route: symbol 1 ends here
    e6Ref  = [e6End - (e6Info.SymbolLengths(2) - e6Info.Nfft) + 1, e6End];
    okE6   = myE6(:) == e6Ref(:);
    e6Hint = ["the tail ends where symbol 1 ends; count back one prefix"; "symbol 0 plus symbol 1, prefixes included"];
    e6Hint(okE6) = "";
    e6Check = table(["First position"; "Last position"], okE6, e6Hint, ...
        VariableNames = {'Check', 'Pass', 'LookAt'});
    e6Check
end
%% Exercise cleanup
clear myE1 e1Info e1K e1Ref okE1 e1Hint e1Check myE2 e2Car e2Info e2Ref okE2 e2Hint e2Check ...
      myE3 e3Info e3CP e3Ref okE3 e3Hint e3Check myE4 e4Car e4N e4K e4Ref okE4 e4Hint e4Check ...
      myE5 e5Info e5sc e5Ref okE5 e5Hint e5Check myE6 e6Info e6End e6Ref okE6 e6Hint e6Check
%% Recap — Copy the Tail (album track 02)
% Every OFDM symbol carries a copy of its own tail in front, and that copy 
% turns echoes into one complex gain per subcarrier.
% Key relationships
% The default FFT size is the smallest power of two (at least 128) that keeps 
% the occupied tones at or below 85 % of the bins, and the sample rate is N_FFT 
% × Δf:
% 
% $$N_{\mathrm{FFT}} = \min\{2^n \ge 128 : 12\,N_{\mathrm{RB}} \le 0.85\cdot 
% 2^n\},\qquad f_s = N_{\mathrm{FFT}}\cdot\Delta f$$
% 
% Echoes inside the prefix leave one gain per subcarrier, and windowing leaves 
% an echo margin of about N_CP − W:
% 
% $$Y_\ell(k) = H(k)\,X_\ell(k),\qquad \text{margin} \approx N_{\mathrm{CP}} 
% - W$$
% 
% Noise added to the time samples gives
% 
% $$\mathrm{EVM} \approx 100\sqrt{\frac{K}{N_{\mathrm{FFT}}\cdot\mathrm{SNR}}}\ 
% \%$$
% What this means in practice
% • The prefix is the end of the body, copied; with no windowing it matches 
% sample for sample, and a frame is always 10 ms of samples, prefixes included.
% 
% • Echoes shorter than the prefix need one complex tap per tone; the one-tap 
% equalizer is used again in album track 07 (Learn the Channel).
% 
% • An echo past the prefix breaks the one-tap model, and windowing shrinks 
% the margin to about N_CP − W; delay spread returns in album track 06 (Taps 
% in Time).
% 
% • With a time-domain SNR, EVM ≈ 100 √(K/(N_FFT·SNR)) %; EVM is used again 
% in album tracks 14 (Mirror Image) and 15 (End to End).
% 
% • A frequency offset leaks tones into each other, and removing the common 
% phase does not undo the leak.
% 
% • You built a carrier yourself, read its FFT size and guard bins, and showed 
% that one of its prefixes is a copy of its tail.
% 
% • Next in the album: track03 (Find Me in the Noise).
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
% • x(i:j), x(list), and end:
% 
% • f(Name = value, ...):
% 
% • s.Name and s.Name(n):
% 
% • nrCarrierConfig:
% 
% • nrOFDMInfo:
% 
% • nrResourceGrid:
% 
% • nrOFDMModulate:
% 
% • max(abs(a − b)):
% What I missed, and where to reread it
% 
%% Review — retrieval
% Still keeping the Recap collapsed: from album track 01 (Two to the Mu, 
% track01/track01_two_to_the_mu_demo), how many slots fit in one 1 ms subframe 
% at 30 kHz spacing? Type the number into myAnswer and run this section. Then, 
% in one line, say why it is not the same as at 15 kHz. The check asks 
% nrCarrierConfig and does not print its value.
% 
% Why:
myAnswer = NaN;
if isnan(myAnswer)
    disp('Type a number into myAnswer, then run this section again.')
else
    okReview = myAnswer == nrCarrierConfig(SubcarrierSpacing = 30).SlotsPerSubframe;   % second route: the toolbox
    reviewCheck = table("Slots per 1 ms subframe at 30 kHz", okReview, ...
        VariableNames = {'Check', 'Pass'});
    reviewCheck
end
