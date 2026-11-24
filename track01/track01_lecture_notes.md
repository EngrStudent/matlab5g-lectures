# Track 01 "Two to the Mu" — lecture notes

Companion to [`track01_demo.m`](track01_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs.** D2 order: P00a "Grid and Waveform" → P00b "Map of the Link" → T01. OFDM, Nfft, sample rate and CP-in-samples come from P00a and are taught in depth in T02; this track works in durations, and the sample-count material is an optional aside. *Resource block (RB)* = 12 subcarriers. *BWP* (bandwidth part): a block of the carrier's RBs a UE is configured to use; named in B4's preview only and not taught in the album.

## Cold open (plan S1)

ANI: Draw a grid. Time runs left to right, frequency climbs the page, and one square is one tone for one symbol. 5G calls that square a resource element. Today's question is simple: what happens to this grid when you double the spacing between tones?

## B1. Numerology sweep: read the toolbox back

**Key idea.** Numerology is a power of two on a 15 kHz grid. Doubling mu doubles the subcarrier spacing and packs twice as many slots into the same 1 ms subframe, so the radio-frame clock itself never moves. The demo reads those counts back from nrCarrierConfig instead of taking the lyric's word for it. *Why care:* a larger SCS buys shorter slots (latency) and Doppler / phase-noise tolerance (FR2); a smaller SCS buys a longer cyclic prefix for long echoes. *Try (corrected):* add a mu = 5 row by editing `muList`, `cpList` and `nrbList` (the SCS is computed from `muList`).

**Math.**

$$\mathrm{SCS}(\mu)=15\,\mathrm{kHz}\times 2^{\mu},\qquad N_{\mathrm{slot}}^{\mathrm{sf}}=2^{\mu},\qquad N_{\mathrm{slot}}^{\mathrm{frame}}=10\cdot 2^{\mu}.$$
A normal-CP slot has 14 OFDM symbols; extended CP (12 symbols) is used in this sweep only at 60 kHz ($\mu=2$).

**Lyric** (certified spelling):

> L15: Don't take my word for it. Build an N R Carrier Config,
> L16: set the spacing to thirty, read Slots Per Subframe back.
> L17: It tells you two. Did you guess two?
> L24: Fifteen kilohertz times two to the mu,
> L26: Two to the mu slots in every millisecond,

**What the output or plot shows.** A table of mu = 0 to 4 (plus one extended-CP row at 60 kHz): SCS, symbols/slot, slots/subframe, slots/frame, and the grid size 12*NSizeGrid by SymbolsPerSlot. At 30 kHz the slots-per-subframe entry is 2. Equations in the notes and any plot titles use the Greek mu.

**Check your understanding.** If you set SubcarrierSpacing to 30, what should SlotsPerSubframe be, and why?

**Answer.** 2, because $\mu=1$ and slots per subframe equal $2^{\mu}$.

## B2. Timing: symbol, prefix and slot

**Key idea.** The useful symbol lasts Tu = 1/SCS, so it shrinks as mu grows, but a subframe is built to sum to exactly 1 ms. The cyclic prefix is a fixed time (4.6875 us ordinary, at normal CP), not a fixed sample count: printed CyclicPrefixLengths scale with the toolbox default Nfft. *Optional aside (P00a material):* symbol 0 of each 0.5 ms half-subframe takes 16 extra Ts (the 16-sample fix-up on the 2048-unit clock).

**Math.**

$$T_u=1/\mathrm{SCS},\qquad T_u(\mu=0)=66.\overline{6}\,\mu\mathrm{s}.$$
Ordinary CP time is $144/30.72\,\mathrm{MHz}=4.6875\,\mu\mathrm{s}$. One symbol plus prefix is $71.354\,\mu\mathrm{s}$.
$$7\times(2048+144)=15344=15360-16,$$
so the first prefix of the half-subframe carries the extra 16. Sample counts scale as $144\cdot N_{\mathrm{FFT}}/2048$ (ordinary) and $16\cdot N_{\mathrm{FFT}}\cdot 2^{\mu}/2048$ (extra). The ordinary term does not carry a $1/2^{\mu}$ factor.
Distance scale (animation A3), using $c=3\times 10^8\,\mathrm{m/s}$ and $4.6875\,\mu\mathrm{s}$:
$$4.6875\,\mu\mathrm{s}\times c=1406.25\,\mathrm{m};$$
$$\text{at }120\,\mathrm{kHz},\ \mathrm{CP}=4.6875/8=0.5859375\,\mu\mathrm{s},\ \times c=175.78125\,\mathrm{m}.$$

**Lyric** (certified spelling):

> L36: so the useful symbol lasts one over the spacing.
> L37: Sixty-six point seven microseconds at fifteen,
> L42: four point six nine microseconds at fifteen,
> L46: Symbol plus prefix, seventy-one point four, fourteen of them fill the millisecond.
> L47: Seven symbols come sixteen samples short, so symbol zero takes the sixteen.

**What the output or plot shows.** A timing table: Nfft, sample rate, Tu, ordinary CP, and slot duration 1 ms / 2^mu for each row. At mu = 0 the note explains why printed sample counts on a wide default-Nfft carrier are not the 144/160 reference counts. The asserts compare times, not raw counts.

**Check your understanding.** Why can a 270-RB, 15 kHz carrier print CP lengths of 320 and 288 instead of 160 and 144?

**Answer.** Because those 160/144 counts are for Nfft = 2048 only. Default Nfft is the smallest power of 2 with occupancy at most 85%, which is larger than 2048 on a 270-RB carrier, and the sample counts scale with Nfft/2048. The durations still match.

**Animation cue A2** (lines L46–L47). 7 × (2048 + 144) = 15344 = 15360 − 16, so symbol 0 of each half subframe takes the 16 — A sample-count timeline of one 0.5 ms half subframe. Seven blocks of 144 + 2048 fall 16 samples short of the 15360 mark. The 16 then slide into the first block's prefix.

**Animation cue A3** (lines L72–L73). CP × c: 4.69 us × 3e8 m/s ≈ 1406 m; at 120 kHz, CP = 4.69/8 ≈ 0.586 us, × c ≈ 176 m — An echo pulse racing a prefix bar. At 15 kHz the bar is long and the echo fits. At 120 kHz the bar is 8× shorter, the same echo overruns it, and it bleeds into the next symbol. The distance is labeled.

## B3. Same box, new shape

**Key idea.** A resource element is one subcarrier for one OFDM symbol. In a fixed 1 ms by B Hz box, raising mu makes each subcarrier twice as wide (half as many of them) and packs twice as many symbols into the millisecond, so the RE count does not depend on mu. The two to the mu cancels. Equations use the Greek mu; any lyric caption keeps the certified spelling "mu".

**Math.**

$$\text{RE count in }1\,\mathrm{ms}\times B=14\cdot B/(15\,\mathrm{kHz}),\quad\text{independent of }\mu.$$
For $B=2.88\,\mathrm{MHz}$: $14\cdot 2.88\times 10^6/(15\times 10^3)=2688$. Shapes: $192/2^{\mu}$ subcarriers by $14\cdot 2^{\mu}$ symbols (16, 8, 4, 2, 1 RB).

**Lyric** (certified spelling):

> L50: Now hold a box, one millisecond wide, B hertz tall.
> L51: Count the squares: bandwidth over spacing,
> L52: times fourteen, times two to the mu.
> L53: The two to the mu cancels out.
> L54: The box doesn't grow. It only changes shape.

**What the output or plot shows.** Five checkerboard grids of equal area, titled with mu = 0 to 4, each asserting 2688 REs. Only the (K, L) shape changes. White lines mark slot boundaries. The μ = 4 (240 kHz) tile is labelled "SSB-only; shown for the math": 240 kHz is not a data numerology.

**Check your understanding.** Does a higher numerology give more resource elements in the same bandwidth and the same millisecond?

**Answer.** No. It only reshapes the grid. The product is 14*B/15 kHz at every mu.

**Animation cue A1** (lines L54 (with L53)). RE count in a 1 ms × B box = (B/SCS)·(14·2^mu) = 14·B/15 kHz, independent of mu — One rectangle of fixed area. Its grid lines re-tile from 16 RB × 14 symbols to 1 RB × 224 symbols as mu steps 0 → 4. A counter stays at 2688 throughout. The caption reads "mu", in words.

## B4. A real frame, counted

**Key idea.** A frame is 10 ms of this grid after the IFFT and the cyclic prefix, so the sample count is SampleRate times 10 ms. For 51 RB at 30 kHz the documented default Nfft is 1024 (occupancy 12*51/1024 <= 85%) and SampleRate = Nfft*SCS = 30.72 MHz, which is 307200 samples. The picture is that same grid, with PDSCH and DM-RS labelled in a 24-PRB BWP. *Preview only:* PDSCH (the shared data channel) is taught in T05 and DM-RS (its pilots) in T07; read the setup as "something occupies these REs".

**Math.**

$$N_{\mathrm{FFT}}=1024,\quad f_s=N_{\mathrm{FFT}}\cdot\mathrm{SCS}=30.72\,\mathrm{MHz},$$
$$N_{\mathrm{samples}}=f_s\times 10\,\mathrm{ms}=307200.$$
A common mistake is to set $N_{\mathrm{FFT}}=12\cdot N_{\mathrm{SizeGrid}}=612$, which is not a power of 2 and is not the default.

**Lyric** (certified spelling):

> L84: N R Resource Grid of carrier hands you zeros,
> L85: twelve N tall, fourteen wide.
> L86: Map the shared channel. Map its reference signal.
> L87: Run one frame. Count the samples. Ten milliseconds, exactly.

**What the output or plot shows.** Printed slot and symbol counts, Nfft = 1024, 307200 samples, and a labelled image of one 10 ms frame (PDSCH, DM-RS, slot and subframe lines, BWP edges). The Nfft = 1024 / 307200 check is now a printed comparison with a release hint (warning), not a hard stop; the 10 ms assert remains.

**Check your understanding.** If you raise NSizeGrid until default Nfft jumps from 1024 to 2048, what happens to the frame sample count at the same 30 kHz SCS?

**Answer.** It doubles, to 2048 * 30 kHz * 10 ms = 614400 samples.


## Recap (plan S9)

ANI: Three things to keep. Spacing is fifteen kilohertz times two to the mu. The slot is fourteen symbols, so it lasts one millisecond over two to the mu. And a fixed box of time and bandwidth holds the same number of squares at every mu. Short slots buy latency, and a long prefix buys reach. Open the demo, change one number, and predict the table before it prints.

Script closing print: SCS = 15·2^μ; the 1 ms subframe never moves; same box, same RE count; frame samples = Nfft·SCS·10 ms.
