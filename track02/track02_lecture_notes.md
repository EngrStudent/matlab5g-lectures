# Track 02 "Copy the Tail" — lecture notes

Companion to [`track02_demo.m`](track02_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Assumes:** the DFT, circular convolution (stated in B2, not proved) and RMS. *ICI* (inter-carrier interference) is energy from one subcarrier leaking onto its neighbours once the tones stop being orthogonal; a CFO causes it (B4).

## Cold open (plan S1)

ANI: Last time we built a grid. Now send it through the air. The phone hears the tower directly, and a few microseconds later it hears the same signal off a building. Echoes smear one symbol into the next. Today's question: what trick turns that mess back into one number per tone?

## B1. Grid to IFFT to prefix

**Key idea.** *The problem first:* multipath echoes make the channel frequency-selective. The cyclic prefix is what lets the receiver undo that with one complex divide per tone (B2), instead of a long time-domain equalizer. *Mechanism:* OFDM's IFFT plants K occupied tones into an Nfft-bin grid, then the cyclic prefix copies the tail of each body to the front. That copy is what later turns a linear multipath channel into one complex tap per subcarrier. For a 52-RB, 15 kHz carrier the default Nfft is 1024, K = 624, and fs = 15.36 MHz.

**Math.**

$$\text{occupancy }=(12\cdot N_{\mathrm{RB}})/N_{\mathrm{FFT}}\le 85\%,\quad f_s=N_{\mathrm{FFT}}\cdot\mathrm{SCS}.$$
With no windowing, the prefix equals the last CP-length samples of the body. Ordinary / long CP sample counts at $N_{\mathrm{FFT}}=1024$ are 72 and 80 (144 and 160 scaled by 1024/2048). A 10 ms frame is 153600 samples.

**Lyric** (certified spelling):

> L11: Fifteen kilohertz, fifty-two blocks: the default FFT is ten twenty-four,
> L12: so six hundred twenty-four bins carry tones and four hundred sit quiet.
> L13: Take the FFT of one symbol and count the bins that light up.
> L71: Run N R OFDM Modulate with the windowing at zero,
> L72: and check the prefix equals the tail, sample for sample.

**What the output or plot shows.** Asserts: one frame is 10 ms of samples; the CP equals the tail; exactly 624 of 1024 bins carry energy; a clean demodulation with CyclicPrefixFraction = 1 is a numerical identity. A plot overlays the tail under the prefix.

**Check your understanding.** Is the cyclic prefix a run of zeros in front of the symbol?

**Answer.** No. It is a copy of the tail of the useful symbol. That is what makes the convolution circular.

## B2. Echoes inside the prefix: one tap per tone

**Key idea.** If every echo falls inside the prefix, linear convolution becomes circular on the body, and a circular convolution is a pointwise product in frequency. The channel is then one complex number H(k) per subcarrier, constant across symbols, and a single pilot symbol equalizes the whole frame. Move one echo past the prefix (120 samples here) and that identity breaks: leftover ISI and ICI show up as EVM.

**Math.**

$$y[n]=h[n]*x[n]\ \xrightarrow{\text{CP holds}}\ Y(k)=H(k)X(k).$$
Inside-CP echoes (0, 17, 51 samples) equalize to essentially 0 EVM. A 120-sample echo, longer than even the long CP, leaves EVM > 1% after the same one-tap equalizer.

**Lyric** (certified spelling):

> L30: But when every echo is shorter than the prefix,
> L33: That's circular, and after the FFT it's just a multiply.
> L73: Put two echoes inside the prefix, and one tap wipes them out.
> L74: Push one past, and watch it bloom.

**What the output or plot shows.** Printed EVM after one-tap EQ: near zero when every echo is inside the CP, and a clearly nonzero EVM (asserted > 1%) when the last echo is past the CP. It also prints the broken-case EVM split into long-CP and normal-CP symbols. Plots: |H(k)|, and a scattered constellation for the broken case.

*Try (corrected):* set `lastEcho = 72` (exactly a normal CP: clean everywhere), then `80` (past the normal CP, inside the long CP). Predict: at 80 the long-CP symbols (0 and 7 of each subframe) stay clean, and the normal-CP symbols break. The inside-CP `dly` assert stays as it is; the B2 break assert fires only when `lastEcho` exceeds the long CP.

**Check your understanding.** If the channel is time-invariant and every echo is inside the CP, do you need a new H(k) on every symbol?

**Answer.** No. One complex tap per subcarrier, learned from a single pilot symbol, equalizes the frame.

**Animation cue A1** (lines L30–L33). If every echo is shorter than the CP, the kept window sees only its own symbol, cyclically shifted, so linear convolution becomes circular and the FFT turns it into Y = H·X per tone — A symbol drawn on a ring. The tail copies to the front, an echo slides in, and its overflow lands on the copy. The kept window wraps around the ring, then unrolls into one multiply per tone.

**Animation cue A2** (lines L37–L39). An echo past the CP (120 > 80 samples) drags the previous symbol into the window: ISI and ICI — The same timeline with the echo arrow crossing the symbol boundary. The previous symbol tints in, and the per-tone dots smear into clouds.

## B3. Windowing trade

**Key idea.** Time-domain windowing (WOLA) tapers the symbol edges so the out-of-band sidebands fall, at the cost of prefix samples: a clean FFT window must start W samples early, leaving only CP minus W of echo margin. Windowing is documented on the NR pages for nrOFDMModulate / nrOFDMInfo (not only on LTE). Two tools, two defaults: nrDLCarrierConfig.WindowingPercent defaults to 0, while nrOFDMModulate's default Windowing is the 3GPP-safe maximum. **Main path: echo margin = CP − W.** The script now prints a compact trade table (W, CP − W, OOB dB, echo EVM) beside the PSD. The evmF1 / evmEarly columns and the long-CP exclusion are optional detail. Set `strictWOLA = true` to make a wrong prediction stop the script.

**Math.**

$$\text{echo margin}=\mathrm{CP}-W.$$
Out-of-band power should fall as W grows. An echo at d that used to fit in the prefix becomes residual ISI once $d>\mathrm{CP}-W$.

**Lyric** (certified spelling):

> L50: Hard edges on every symbol splash the spectrum out the sides.
> L53: But the taper spends samples of the prefix.
> L56: Two tools, two defaults: the generator's windowing starts at zero,
> L57: and the modulator's takes the most taper the EVM test can spare.

**What the output or plot shows.** A printout of OOB dB and three EVMs for each W in the list, plus a sideband PSD plot. The last W should show lower OOB than W = 0. Predictions about exact taper placement are printed; they become asserts only if you set strictWOLA = true after you have run it.

**Check your understanding.** You window for a prettier spectrum, and an echo that used to fit in the prefix now errors. What did you spend?

**Answer.** W samples of the cyclic prefix. The remaining delay-spread margin is CP minus W.

## B4. EVM by hand

**Key idea.** EVM is the RMS error vector as a percentage of the RMS reference. When SNR is defined on the time samples, only K of Nfft bins carry the signal, so the per-subcarrier SNR is larger by Nfft/K. A carrier-frequency offset of a fraction eps of the SCS leaves a sinc gain on the wanted tone plus leakage from the neighbours, which a single common-phase rotation cannot undo. That leakage is ICI. *Predict first:* write down the EVM at 25 dB before the script prints it.

**Math.**

$$\mathrm{EVM}=100\sqrt{\sum|Y-X|^2/\sum|X|^2}.$$
Time-domain SNR convention (this demo):
$$\mathrm{EVM}\approx 100\sqrt{K/(N_{\mathrm{FFT}}\cdot\mathrm{SNR})}.$$
At 25 dB, K = 624, Nfft = 1024, this is about 4.39%. (If SNR were defined per RE, the formula would be $100/\sqrt{\mathrm{SNR}}$.)
For a CFO $\varepsilon=0.05$ of the SCS, after removing a common phase per symbol,
$$s=\sin(\pi\varepsilon)/(\pi\varepsilon),\qquad \mathrm{EVM}\approx 100\sqrt{(1-s^2)+(1-s)^2}\approx 9.06\%,$$
next to the 8% 38.104 64-QAM BS limit.

**Lyric** (certified spelling):

> L60: The error vector is what you received minus what you sent.
> L61: EVM is the root mean square of the error
> L62: over the root mean square of the reference, in percent.
> L64: On a full grid, an offset of five percent of the spacing leaks about nine percent EVM,
> L66: That's past the base station limit for sixty-four QAM, which is eight.

**What the output or plot shows.** Measured vs predicted noise EVM at 25 dB (about 4.39%), an optional comm.EVM cross-check, and CFO EVM after the common-phase fix (about 9.06% vs the sinc model).

**Check your understanding.** Why is EVM = 100/sqrt(SNR) the wrong prediction in this beat?

**Answer.** Because snrdB is the time-domain SNR over the full sample rate. Only K of Nfft bins carry the signal, so the per-subcarrier SNR is SNR*Nfft/K, and EVM is about 100*sqrt(K/(Nfft*SNR)).

**Animation cue A3** (lines L64). CFO of eps = 0.05 → EVM = 100·sqrt((1 − s²) + (1 − s)²) = 9.06 % — A row of sinc spectra on the subcarrier grid. Each shifts by 5 % of a spacing, so the nulls miss the neighbours. A bar grows to 9.06 % and crosses an 8 % line.

## B5. The full path: generator to grid

*Preview only:* SSB is taught in T03 and PDSCH in T05. PDCCH (downlink control) and BWP (a configured block of RBs) are not covered in the album; read them as "things that occupy REs."

**Key idea.** nrWaveformGenerator is the whole slot machine: a carrier config with PDSCH, PDCCH and (here disabled) SSB, written to a waveform and to the generator's own ResourceGridInCarrier. Demodulating that waveform with the same Nfft and SampleRate must land back on that grid wherever an RE was occupied. This path sets WindowingPercent = 0 so the round trip is an identity.

**Math.**

Occupied-RE EVM after demodulation should be numerically zero when WindowingPercent = 0 and SSB is off. A 10-subframe waveform is 10 ms of samples at the generator's SampleRate.

**Lyric** (certified spelling):

> L75: Then run N R Waveform Generator end to end, demodulate,
> L76: and match the grid it says it sent.
> L77: Count the samples: a frame is always ten milliseconds of them.

**What the output or plot shows.** Printed Nfft, sample rate, windowing, grid size, and a near-zero EVM on occupied REs, asserted under 1e-6.

**Check your understanding.** You leave SSB enabled and the occupied-RE set no longer matches a handmade PDSCH-only grid. Who is right?

**Answer.** The generator. Compare against ResourceGridInCarrier, which already includes every signal the config asked for.


## Recap (plan S8)

ANI: Four things to keep. The prefix is a copy of the tail. If every echo fits inside it, the channel is one complex tap per tone. Windowing spends prefix, so the echo margin is CP minus W. And with time-domain SNR, EVM is about a hundred times the square root of K over Nfft times SNR. Where they come back: one-tap equalization in T07, delay spread in T06, and the EVM budget in T14 and T15.
