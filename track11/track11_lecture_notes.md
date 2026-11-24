# Track 11 "One in Ten" — lecture notes

Companion to [`track11_demo.m`](track11_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs.** HARQ and redundancy versions (T05), LDPC (T04), channel estimation and equalization (T07) — all earlier in D2 order. D2 neighbours: T10 "Sound It Out" before, T12 "How Far" after.

## Cold open (plan S1)

ANI: Every piece we've built goes into one loop today. Data enters at the transmitter, a channel and noise get in the way, and at the end we count how many blocks made it. That count, swept over noise levels, is how 5G links are judged.

*Hook:* "one in ten" is the CQI BLER target in TS 38.214 §5.2.2.1, and it describes a single (first) transmission.

## B1. One slot, end to end

**Key idea.** Before drawing a waterfall, one quiet slot must go through PDSCH, the air (here just AWGN), the equalizer and the LDPC decoder and come back with blkerr = false. That is the 'the plumbing works' check Track 15 will raise to an invariant. Starting the SNR loop first can make a wiring bug look like a poor MCS.

**Math.**

One slot at 20 dB, QPSK, 24 PRBs, target rate 0.48: $\texttt{blkerr}$ must be false and the bits must match.

**Lyric** (certified spelling):

> L7: Start with a transport block. N R DLSCH adds the checks, codes it, and rate matches it.
> L8: N R PDSCH scrambles it, modulates it, and maps it onto layers.
> L10: N R OFDM Modulate turns the grid into a waveform.
> L16: N R Timing Estimate finds where the slot starts, and N R OFDM Demodulate gives back the grid.
> L19: and N R DLSCH Decoder checks the CRC.
> L63: Open the toolbox. Build the loop once, for one slot, and check that one block passes.

**What the output or plot shows.** Printed TBS and blkerr, with an assert that the high-SNR slot passes.

**Check your understanding.** The first mid-SNR point in a waterfall is 100% BLER. What should you check before you blame the MCS?

**Answer.** Whether a single high-SNR slot already passes. If that fails, the plumbing is broken and the waterfall is meaningless.

## B2. The SNR loop: BLER and throughput

**Key idea.** There are two BLERs. The *first-transmission* BLER (RV 0 alone) is what the CQI "one in ten" target describes. The *residual* BLER is the fraction still failing after all the HARQ attempts you allowed; it sits to the left of the first-transmission curve. Throughput is passed information bits per slot *used* (retransmissions count), so it rises to a plateau set by the TBS. Predict the first-transmission 0.1 crossing before the loop prints it. *Try (corrected):* set `rvSeq = 0` and the after-HARQ curve slides right onto the first-transmission curve. The RV sequence used here is the conventional 0, 2, 3, 1 from knowledge and the MathWorks examples, not a mandated NR spec order (VERIFY; 38.212 defines k0 per rv_id). This preliminary loop is short (20 slots per point) on purpose: it will not meet the '100 errors' statistical rule of thumb.

**Math.**

RV teaching order: $0,2,3,1$. A failed first attempt that a later RV saves is not a block error.
Throughput plateaus near the TBS (bits per slot) at high SNR. BLER is drawn on a log axis with a line at $0.1$.

**Lyric** (certified spelling):

> L29: Block error rate is the number of blocks that failed their CRC, divided by the number sent.
> L30: Plot it against the signal to noise ratio, and it's flat near one,
> L31: then drops like a waterfall, often only a few decibels wide.
> L32: Throughput counts the bits that arrived in blocks that passed.
> L33: Here's the invariant: throughput can never be more than the block size
> L66: Plot block error rate on a log scale, and draw a line at one in ten.

**What the output or plot shows.** A printed SNR / first-tx BLER / after-HARQ BLER / throughput table, the first-tx 0.1 crossing, a log-scale plot of both BLER curves with yline(0.1) labelled "CQI target (1st tx)", and a throughput plot with a TBS reference line. Assert: after-HARQ BLER ≤ first-tx BLER at every point. The loop is short; treat the curve as a shape, not a 100-error measurement.

**Check your understanding.** A first RV fails and a later RV of the same block passes. Do you count a block error?

**Answer.** No. BLER is after the HARQ attempts you allowed, not after the first try.

## B3. Why one in ten

**Key idea.** 'One in ten' is not a lyric convenience. TS 38.214 §5.2.2.1 sets a BLER target of 0.1 for CQI tables 1 and 2 (and table4-r17); table 3 is a high-reliability table at 1e-5. The lyric's 'low latency' wording stays as certified; speech can say 'high reliability' for table 3 (T11 SV S1). nrCQITables (R2024a) is a glimpse of those four tables. A 20-slot demo is not 100 errors of evidence.

**Math.**

Rule of thumb: about 100 errors per plotted point.
At BLER $0.1$: $100/0.1=1000$ blocks. At BLER $10^{-3}$: $100/10^{-3}=100000$ blocks (the sung 'about a hundred thousand').

**Lyric** (certified spelling):

> L35: And here's why one in ten: the phone picks the highest channel quality index
> L36: whose block error probability wouldn't go past one in ten,
> L37: for three of the four C Q I tables. The low latency table aims for one in a hundred thousand.

**What the output or plot shows.** Printed block-count arithmetic, plus the nrCQITables property names (or a skip message). The lyric itself is not rewritten.

**Check your understanding.** This preliminary demo runs 20 slots per SNR point. At a true BLER of 0.1, about how many errors is that, and is it enough?

**Answer.** About two errors. It is enough to see a shape, not enough to treat a 0.1 crossing as a 100-error measurement.

**Animation cue A1** (lines L55–L57). ~100 errors per point: at BLER 0.1 that is 100 / 0.1 = 1,000 blocks; at 1e-3 it is 100 / 1e-3 = 100,000 blocks — Two jars filling with blocks, with red ones as errors. The 0.1 jar reaches 100 red at 1,000 blocks. The 1e-3 jar needs 100,000. A counter shows the ratio.

## B4. Perfect vs practical, same seeds

**Key idea.** A perfect channel estimate is a lower bound. A practical estimate (DM-RS, interpolation) usually needs a little more SNR to cross the same 0.1 line — the waterfall 'slides right.' Finite samples can invert a single point, so the demo prints the interpolated 0.1 crossings (no assert), not a point-by-point comparison, and only compares them when both curves actually cross in this short loop (VERIFY: the slide and the runtime are run results).

**Math.**

Same noise seeds, two receivers: a known identity channel (H = 1, known noise variance) versus a noisy DM-RS estimate. Crossing: linear interpolation on a log-BLER axis.

**Lyric** (certified spelling):

> L47: So why not skip the estimation and use the true channel? Here's the counterexample.
> L48: N R Perfect Channel Estimate hands the receiver the exact channel.
> L50: Switch to the real estimator, and the waterfall slides to the right,
> L51: because now noise lives in the channel estimate too.
> L52: Perfect knowledge is a bound, not a result.
> L58: Use the same random seeds to compare two receivers, so the difference isn't luck.

**What the output or plot shows.** Printed crossings when they exist, a caution if the short loop inverts them, and two waterfalls on one axes.

**Check your understanding.** Why does the plan refuse to assert 'practical BLER is worse' at every SNR point?

**Answer.** A short run can invert a single point by chance. The teaching claim is about the interpolated 0.1 crossing, not every sample.

**Animation cue A2** (lines L33–L34). Throughput ≤ TBS × new blocks sent — A bar for "TBS × new blocks" as a ceiling. A throughput bar rises under it as SNR increases and stops at the ceiling, never past it.


## Recap (plan S7, corrected for the BLER definition)

ANI: One loop ties it all together: transport block, coding, modulation, OFDM, channel, noise, and the whole receiver. Block error rate falls in a waterfall, and throughput can't beat block size times new blocks. CQI aims at about one in ten for most tables. Count enough errors, reuse your seeds, and treat perfect channel knowledge as a bound. Build one slot, then sweep the noise.

Lecture note (spoken aside, not a lyric change): the CQI one-in-ten is read on the first transmission; HARQ lowers what is left after that. Script closing print: one slot first; first-tx BLER vs after HARQ; 0.1 = CQI target; ~100 errors per point; perfect H is a bound.
