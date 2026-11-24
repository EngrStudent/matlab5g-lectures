# Track 12 "How Far" — lecture notes

Companion to [`track12_demo.m`](track12_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / terms.** D2 neighbours: T11 "One in Ten" before, T13 "Signals from Orbit" after. *Hyperbola*: the set of points with a fixed range difference to two foci. *DOP* (dilution of precision): how geometry scales a range error into a position error.

## Cold open (plan S1)

ANI: Light moves about thirty centimetres every nanosecond. Measure time well enough, and you've measured distance. Today we use 5G signals from three base stations to locate a phone, and see the one thing that can fool every method.

## B1. One PRS per base station

**Key idea.** Positioning reference signals are known sequences from each base station, placed on a comb so several cells can share a slot. Different NPRSID values give different sequences on the same comb pattern; that is how the phone tells tower 1 from tower 2.

**Math.**

Three $\texttt{nrPRSConfig}$ objects, NPRSID $=0,1,2$, same CombSize / NumPRSSymbols / NumRB. The occupancy plot shows positions, not the sequence values.

**Lyric** (certified spelling):

> L7: The positioning reference signal, P R S, comes down from several base stations.
> L8: Each one gets its own sequence identity, anywhere from zero to four thousand ninety-five,
> L11: The comb size is two, four, six, or twelve, the spacing in each symbol,
> L14: N R PRS makes the symbols, and N R PRS Indices places them on the grid.
> L62: Open the toolbox. Make N R PRS Config for three base stations, each with its own identity.

**What the output or plot shows.** Printed RE counts for the three IDs, one occupancy image (the comb positions are the same for all three here), and the normalised sequence correlation: ≈ 1 for an ID with itself, small between IDs. That is how the phone tells the towers apart.

**Check your understanding.** If every tower uses the same NPRSID, what can the phone no longer do?

**Answer.** It can no longer tell the towers apart from the sequence. The comb is shared; the identity is in NPRSID.

## B2. Delay, sum, estimate: with fractional delays

**Key idea.** A time-delay estimate from a known PRS is a range. The UE sits at (200, 150) m and the towers at (0,0), (500,0), (0,500) m, so the true ranges are 250.00, 335.41 and 403.11 m. At 30.72 MHz one sample is about 9.76 m, so those delays are fractional (25.62, 34.37, 41.31 samples). A frequency-domain phase ramp realises a fractional delay; nrTimingEstimate itself returns a whole-sample offset. The parabolic sub-sample fit is the plan's method, not a MathWorks page (VERIFY), and a 1 m fix may need upsampling because c/fs is already about 10 m.

*Technique 1 — fractional delay:* a delay τ is a linear phase $e^{-j2\pi f\tau}$ in frequency, so multiply the FFT by that ramp (wrapping the upper half to negative frequencies) and inverse-FFT. *Technique 2 — sub-sample peak:* fit a parabola through the peak sample and its two neighbours; the vertex offset is $\delta = \tfrac12\,(a-c)/(a-2b+c)$.

**Math.**

$$d_i=\lVert p_{\mathrm{UE}}-p_i\rVert,\qquad \tau_i=d_i/c,\qquad n_i=\tau_i f_s.$$
With $c=299792458\,\mathrm{m/s}$ and $f_s=30.72\,\mathrm{MHz}$, $c/f_s=9.7589\,\mathrm{m}$ (the plan's $2.998\times 10^8$ gives $9.76\,\mathrm{m}$).
$d=(250.00,\,335.41,\,403.11)\,\mathrm{m}$, $\tau=(833.9,\,1118.8,\,1344.6)\,\mathrm{ns}$, $n=(25.62,\,34.37,\,41.31)$ samples.

**Lyric** (certified spelling):

> L2: Light moves about thirty centimetres every nanosecond.
> L13: Wider means sharper timing.
> L63: Delay each waveform by its distance over the speed of light, and add them.
> L64: Use N R Timing Estimate against each one's symbols to find its arrival.

**What the output or plot shows.** Printed ranges, delays and sample delays, then each tower's integer nrTimingEstimate offset and the refined (parabolic) offset next to the true value. The sample rate is read from nrOFDMInfo so the 30.72 MHz assumption is checked, not hard-wired blindly.

**Check your understanding.** Why can't a whole-sample timing peak, by itself, give a 1 m range at this sample rate?

**Answer.** One sample is already about 9.76 m. You need a fractional delay (a sub-sample fit, or upsampling) to get down to a metre.

## B3. Hyperbolas cross at the fix (DL-TDOA)

**Key idea.** DL-TDOA assumes the towers are time-synchronized. A TDOA is not a range, it is a range difference, which is a hyperbola with foci at the two towers. Two differences (85.41 m and 153.11 m here) give two hyperbolas that cross at the phone. A 10 ns sync error is 2.998 m of range-difference error; the 2-D error then scales with the geometry. Circles would be trilateration from ranges, not TDOA. The 1 m threshold is a demo choice, not a 3GPP number.

**Math.**

$$\Delta d_{21}=d_2-d_1=85.41\,\mathrm{m},\qquad \Delta d_{31}=d_3-d_1=153.11\,\mathrm{m}.$$
$$10\,\mathrm{ns}\times c=2.9979\,\mathrm{m}\approx 3\,\mathrm{m}$$ of range-difference error.

**Lyric** (certified spelling):

> L43: Downlink time difference of arrival uses no round trip at all.
> L45: Each difference puts the phone on a hyperbola, and the hyperbolas cross at the fix.
> L46: The phone's clock drops out, but the base stations must agree on time.
> L47: Ten nanoseconds of disagreement is about three metres of error.
> L65: Turn the time differences into hyperbolas and see where they cross.

**What the output or plot shows.** Printed range differences and the 10 ns figure, a grid-search fix next to (200, 150), a printed (not asserted) caution if the error exceeds 1 m, an edge warning if the solver hits its search box (now centred on the tower centroid, ±350 m, so a moved UE is still found), and a contour plot of the two hyperbolas with the towers, the UE and the fix.

**Check your understanding.** A 10 ns sync error is 'about three metres.' Is that the 2-D position error?

**Answer.** Not necessarily. It is a range-difference error. The 2-D error depends on the geometry (dilution of precision).

**Animation cue A2** (lines L45). Each TDOA is a hyperbola; two cross at the fix — Three towers and two hyperbola branches drawn as the range differences grow (85.41 m, 153.11 m). Their crossing pins the phone at (200, 150).

## B4. Round trips, angles and the blocked path

**Key idea.** A two-way time is a range, not a difference: the same path is travelled twice, and the sum $T_{\mathrm{gNB}}(\mathrm{Rx}-\mathrm{Tx}) + T_{\mathrm{UE}}(\mathrm{Rx}-\mathrm{Tx}) = (2d/c + w) + (-w) = 2d/c$ cancels both clock offsets and the turnaround. Angles (AoA/AoD) are spoken only. A blocked (NLOS) path adds length that does not cancel: set `nlosExtra = 30` (both legs) and the range grows by 30 m. d = c*(sum)/2 is a teaching identity; opened 38.305 pages describe forming RTTs but do not write this equation (VERIFY).

**Math.**

Clock offsets $a$ (gNB) and $b$ (UE) and a turnaround $w$ cancel in the form
$$(t_{\mathrm{Rx}}^{\mathrm{gNB}}-t_{\mathrm{Tx}}^{\mathrm{gNB}})-(t_{\mathrm{Tx}}^{\mathrm{UE}}-t_{\mathrm{Rx}}^{\mathrm{UE}})=2d/c,$$
so $d=c\cdot(\text{that sum})/2$. The demo asserts this identity and prints 2d/c next to it.

**Lyric** (certified spelling):

> L28: In multi round trip time, each side measures on its own clock.
> L31: Add those two differences, and the waiting time and the clock offsets drop out.
> L33: Here's the invariant: no shared clock is needed,
> L48: Now the counterexample: block the direct path.
> L51: More bandwidth won't fix a path that isn't there.

**What the output or plot shows.** Printed 2d/c, the sum gNB(Rx-Tx) + UE(Rx-Tx) (asserted = 2d/c), the sign-slip version off by 2w (the Common mistake), d-hat vs the LOS range, and the NLOS range growth. Offsets a, b and w are nonzero on purpose.

**Check your understanding.** You add the same clock bias to every timestamp at one end and the RTT range barely moves. Why?

**Answer.** A common clock offset cancels in the (Rx-Tx) combination. An NLOS extra length would not cancel: it really did travel farther.

**Animation cue A1** (lines L28–L34). Each side subtracts its own two readings, so clock offsets and the turnaround cancel; the sum is 2d/c — Two clocks, gNB and UE, deliberately set to different times. A pulse goes out, waits, and comes back. Each side's Rx−Tx bracket is drawn on its own clock. The brackets slide together, the offsets cancel visibly, and the remaining span is labelled 2d/c.

**Animation cue A3** (lines L48 / L51). With the direct path blocked, the first arrival is a reflection; range comes out too long, and more bandwidth won't fix it — A direct ray fades out and a reflected ray takes over. The range circle grows past the phone. A "bandwidth" slider sharpens the pulse but leaves the circle where it is.


## Recap (plan S7)

ANI: Time is distance at thirty centimetres per nanosecond. Each base station gets its own P R S identity. Arrival-time differences put the phone on hyperbolas. Round trips cancel both clocks, and beams give angles. The timing estimator works in whole samples, so sub-sample accuracy needs care. And a blocked direct path makes every range too long. Place three base stations, delay, estimate, and solve.

Script closing print: range from delay; TDOA → hyperbolas; RTT cancels clocks; NLOS pulls range long.
