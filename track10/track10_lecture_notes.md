# Track 10 "Sound It Out" — lecture notes

Companion to [`track10_demo.m`](track10_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / terms.** In D2 order this track follows T09 (Steer the Beam) and precedes T11. *TDD*: uplink and downlink take turns on the same carrier. *FDD*: two carriers, used at the same time. *CSI*: the channel report (CQI, PMI, rank) the phone sends; T09 previewed it, this track supplies the reference signals behind it. *Coherence time / bandwidth*: defined in T06 B4 (time or frequency span over which the channel stays about the same).

## Cold open (plan S1)

ANI: A base station with many antennas wants to aim at your phone. To aim, it needs the channel. There are two ways to get it: listen to the phone going up, or ask the phone to measure coming down. Today we do both and check when they agree.

*Problem first:* to aim 64 antennas the gNB needs H. Who measures it?

## B1. Sounding up: the SRS

**Key idea.** The phone sounds the uplink with a known SRS so the base station can estimate the uplink channel. The sequence lives on a comb in frequency (every 2nd or 4th subcarrier, typically), which is why a picture of SRS looks striped rather than solid. It is not the same sequence as a PDSCH DM-RS, even if the cell identity is the same.

**Math.**

Comb-2 SRS occupies every other subcarrier on the configured symbol (here the last symbol of the slot, a common placement). The occupied-RE count should be about half of a fully filled symbol.

**Lyric** (certified spelling):

> L7: A sounding reference signal, S R S, goes up from the phone.
> L10: N R SRS Config holds the shape. The number of ports is one, two, four, or eight.
> L11: The comb, K T C, puts the signal on every second, fourth, or eighth subcarrier,
> L13: It can fill one, two, four, or more symbols of the slot, and by default it sits on the last one.
> L14: N R SRS makes the symbols, and N R SRS Indices says where they go.

**What the output or plot shows.** Printed RE count for a comb-2 SRS on a 52-RB grid.

**Check your understanding.** If you place a 'sounding' signal on every subcarrier, is it still an SRS comb?

**Answer.** No. The comb is the point: several users or ports can interleave in frequency.

**Animation cue A2** (lines L11–L12). Comb KTC: SRS on every KTC-th subcarrier; phones share symbols on different comb offsets — One symbol column of subcarriers. Phone 1 fills teeth 0, 2, 4…; phone 2 slides into 1, 3, 5… (KTC = 2). Then KTC = 4 with four phones. The comb-offset mechanism is labelled "from knowledge" in notes only (T10 SV S4).

## B2. Measuring down: the CSI-RS

**Key idea.** The downlink measurement is a CSI-RS, a different known signal sent by the base station so the phone can report CSI. It is not the SRS run backwards: different sequence, different placement rules, same idea of a sparse known grid.

**Math.**

A documented single-port CSI-RS row occupies a sparse set of REs; the count is printed and will jump if you change the row or the density.

**Lyric** (certified spelling):

> L53: That downlink measurement rides on the channel state information reference signal, C S I R S.
> L54: N R CSI RS Config sets it up.
> L55: A non zero power resource carries symbols the phone can measure.
> L57: The row number, one through eighteen, picks the pattern from the spec table,
> L59: N R CSI RS makes the symbols, and N R CSI RS Indices places them.

**What the output or plot shows.** Printed CSI-RS RE count and row number.

**Check your understanding.** Can one reference-signal configuration do both the uplink sounding and the downlink measurement?

**Answer.** No. SRS sounds up; CSI-RS measures down. They have different objects, sequences and placement rules.

## B3. Reciprocity: transpose and compare

**Key idea.** In TDD the uplink and downlink share the same frequencies, so the physical channel from phone to base is the plain transpose of the channel the other way: $H_{\mathrm{ul}}=H_{\mathrm{dl}}^{\mathsf{T}}$ (transpose, not conjugate).¹ nrTDLChannel, and also nrCDLChannel (API_VERIFY T10), document swapTransmitAndReceive and NormalizeChannelOutputs. This demo keeps a TDL, as the plan does, and swaps the ends. FDD (different carriers) does not get this for free.

**Math.**

After $\texttt{swapTransmitAndReceive}$, the path-gain tensor ends swap, and a teaching residual $\|H_{\mathrm{fwd}}^{\mathsf{T}}-H_{\mathrm{swap}}\|$ is printed for the same object and seed.

**Lyric** (certified spelling):

> L28: Here's the invariant. The air between two antennas is reciprocal:
> L30: the path from A to B matches the path from B to A.
> L32: So the base station can turn the S R S channel around, transpose it,
> L63: Open the toolbox. Build one channel matrix for a T D D link.
> L64: Estimate it going up from an S R S, and coming down from a C S I R S.
> L65: Transpose the first and compare it to the second.

**What the output or plot shows.** Printed path-gain sizes before and after the swap, and a relative residual when the shapes match.

¹ Toolbox path-gain tensors order dimensions differently from the textbook matrix; the demo sums paths and transposes the resulting 4×2 / 2×4 matrices.

**Check your understanding.** You compare an uplink sounding at one carrier with a downlink estimate at another. Why might they disagree even with perfect radios?

**Answer.** That is FDD: the two directions are different frequencies, so reciprocity of the physical channel is not automatic.

**Animation cue A1** (lines L28–L32). Same frequency, within coherence time: H(B→A) = H(A→B)ᵀ — A 4×2 matrix of arrows from base-station antennas to phone antennas. The arrows reverse direction and the matrix flips about its diagonal into its transpose. Each entry keeps its colour (value).

## B4. Break it with radios, then calibrate

**Key idea.** Real radios sit on both ends of the sounding path, and each node's transmit chain differs from its own receive chain. That difference, not the air, makes H_ul and H_dl^T disagree. A teaching calibration divides those known (or estimated) complex gains back out. This calibration model is a textbook teaching model (plain matrix algebra, no toolbox API).

**Math.**

$$H_{\mathrm{dl}}=\mathrm{diag}(r_{\mathrm{UE}})\,H\,\mathrm{diag}(t_{\mathrm{gNB}}),\qquad H_{\mathrm{ul}}=\mathrm{diag}(r_{\mathrm{gNB}})\,H^{\mathsf{T}}\,\mathrm{diag}(t_{\mathrm{UE}}).$$
$H_{\mathrm{dl}}^{\mathsf{T}}=\mathrm{diag}(t_{\mathrm{gNB}})H^{\mathsf{T}}\mathrm{diag}(r_{\mathrm{UE}})\ne H_{\mathrm{ul}}$ unless $t=r$ on each node. (A model with the *same* gains on both ends is reciprocal by construction and cannot show the break.) Dividing all four chains back out restores $H_{\mathrm{dl}}^{\mathsf{T}}=H_{\mathrm{ul}}$; correcting only the gNB ratio leaves the UE mismatch.

**Lyric** (certified spelling):

> L34: But the radios aren't the air. Each transmit chain and receive chain
> L35: adds its own gain and phase, so you calibrate those away first.
> L66: Then give each radio its own small gain and phase, and compare again.

**What the output or plot shows.** Three residuals: raw ≈ 0.204, gNB-side only ≈ 0.629, both ends ≈ 2e-16 (Python on the box). Asserts: raw > 1e-3 and both-ends < 1e-12.

**Check your understanding.** The uplink and downlink estimates disagree. Is the air necessarily to blame?

**Answer.** Not necessarily. A fixed radio imbalance on either end is enough. Calibrate the radios before you blame the channel.

**Animation cue A3** (lines L46–L48). FDD: UL and DL bands further apart than the coherence bandwidth fade independently — A frequency-selective \


## Recap (plan S7)

ANI: S R S goes up on a comb, so the base station can measure the uplink. C S I R S comes down so the phone can measure and report. In T D D, the air is reciprocal, so the transposed uplink channel matches the downlink once the radios are calibrated. In F D D, it doesn't, so the phone reports. Build one channel, estimate it both ways, and add a little radio mismatch.

Script closing print: "SRS up, CSI-RS down; TDD → transpose; radios break it; calibrate."
