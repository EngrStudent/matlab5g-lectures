# Track 08 "Clusters and Angles" — lecture notes

Companion to [`track08_demo.m`](track08_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / terms.** D2 order: T07 "Learn the Channel" before, T09 "Steer the Beam" after; the TDL picture is T06. *Rank* = the number of usable parallel streams (layers), i.e. non-negligible singular values of H. *SVD*: H = UΣVᴴ; the singular values in Σ are the stream gains. *Steering vector* (preview of T09): $a_n=e^{-j\pi n\sin\theta}$ on a half-wavelength array. *AoA/AoD, ZoA/ZoD*: azimuth/zenith of arrival/departure.

## Cold open (plan S1, D2-adjusted)

ANI: In Taps in Time, every echo had a time and a loudness. Now every echo has a direction too. Once echoes have directions, an antenna array can tell them apart. Today we find out when that gives you extra streams, and when it doesn't.

*Question to hold:* why can a 2×2 array still carry only one stream?

## B1. Clusters and the channel object

**Key idea.** A CDL is not one delay tap. It is a handful of clusters, each a bundle of rays with delays, powers and angles. CDL-A/B/C/D/E are the tabulated shapes; nrCDLChannel is how the toolbox draws them. This is the geometric picture TDL (Track 6) left out. CDL-D is a LOS profile with a strong first cluster that TDL-A never had.

**Math.**

A cluster is many rays. Path delays and average path gains on the object are the cluster-level picture the demo prints first.

**Lyric** (certified spelling):

> L7: A clustered delay line model, C D L, is a list of clusters.
> L8: Each cluster has a delay, a power, and four angles:
> L11: Inside each cluster, twenty rays fan out around those mean angles.
> L13: and the toolbox calls them up with N R CDL Channel.
> L67: Open the toolbox. Make N R CDL Channel with C D L C.

**What the output or plot shows.** Printed profile, delay spread, antenna counts, cluster count and the strongest cluster (read from `info(ch)`; the `PathDelays` property applies to Custom profiles only), plus a delay–AoA scatter of the clusters with marker size ∝ power.

**Check your understanding.** Is one CDL cluster the same thing as one ray?

**Answer.** No. A cluster is a bundle of rays that share a rough delay and a rough angle, with a spread around both.

**Animation cue A1** (lines L8–L11). Each cluster has a delay, a power and AoD/ZoD/AoA/ZoA; 20 rays fan out around the mean angles — A base station and a phone. Clusters appear as fans of 20 rays, each fan's brightness set by its power, and each arriving at its own delay tick on a timeline below.

## B2. The arrays live on the channel

**Key idea.** In the 5G Toolbox CDL, the transmit and receive arrays are properties of the channel, not a separate array object you pass later. Changing the element count changes the MIMO size of every path gain the channel will draw. A ULA built in the Phased Array Toolbox (Track 9) is not picked up automatically.

**Math.**

After setting Size on both arrays, NumTransmitAntennas and NumReceiveAntennas, and size(pathGains) after one sample, should follow the array.

**Lyric** (certified spelling):

> L58: In the toolbox, the arrays live on the channel, not on the carrier.
> L59: Transmit Antenna Array and Receive Antenna Array take a size of five numbers:
> L60: rows, columns, polarizations, then panel rows and panel columns.
> L61: The default is two by two, with two polarizations, on one panel, so eight elements.
> L63: like N R Rectangular Panel Array from the Phased Array System Toolbox.

**What the output or plot shows.** Printed antenna counts and the path-gain tensor size.

*Legend.* `Size = [M N P Mg Ng]`: M rows × N columns of elements, P polarizations (1 or 2), Mg × Ng panels. Path gains: time × path × Tx × Rx. T09 builds arrays with the Phased Array toolbox; those do not plug in here.

**Check your understanding.** You built a ULA with phased.ULA and ran nrCDLChannel. Why might the path gains ignore your ULA?

**Answer.** Because the CDL arrays live on the channel object. The Phased Array ULA is a different object unless you have wired them together yourself.

## B3. Polarization: XPR as a power ratio

**Key idea.** Cross-polarisation power ratio (XPR) is the power that stays in the intended polarisation versus the power that leaks into the other. It is a finite dB number, not infinite isolation. A smaller XPR means more leakage between polarisations and a less diagonal two-pol channel. Dual polarisation is not two independent channels for free.

**Math.**

XPR is a power ratio, usually quoted in dB: $\mathrm{XPR}=10\log_{10}(P_{\parallel}/P_{\perp})$.

**Lyric** (certified spelling):

> L31: By default the transmit array is slanted plus and minus forty-five degrees.
> L33: The cross polarization ratio, X P R, says how much weaker that leak is.
> L34: In N R CDL Channel the default is ten decibels,
> L35: the cluster value for C D L A, so the leak carries about a tenth of the power.
> L37: so the cross path is weaker, but never zero.

**What the output or plot shows.** A dual-polarised single element on each end (Size [1 1 2 1 1], V/H polarization angles [0 90]); the table XPR from `info(chP).XPR` beside the measured co/cross power ratio of the path gains. (With the default ±45° slants co and cross average to equal power, so V/H is used.) Try: CDL-C (7 dB) vs CDL-A (10 dB).

**Check your understanding.** If XPR is 0 dB, what does that say about the two polarisations?

**Answer.** Equal power in the intended polarisation and the leak. They are anything but isolated.

## B4. Correlation and the rank trap

**Key idea.** A large array does not guarantee a high-rank channel. If every cluster arrives from a narrow angle spread, the spatial covariance is nearly rank-1 and extra antennas buy almost no extra streams. A 2-by-2 label is not a promise that two layers will always pass.

**Math.**

A single steering direction $a$ gives the teaching channel $H=aa^{H}$, whose singular values are $\{\lVert a\rVert^2,0\}$.
A CDL-A 2x2 snapshot is printed next to that rank-1 reference so you can see whether the second singular value is still useful.

**Lyric** (certified spelling):

> L48: So more antennas always mean more streams? Here's the counterexample.
> L49: Pack eight elements close together, and let every cluster arrive from nearly one angle.
> L51: The columns of the channel matrix line up, and the matrix is close to rank one.
> L68: Turn on angle scaling and set the angle spreads small.
> L70: Measure the correlation between two neighbouring elements.
> L71: Now set the angle spreads wide and measure again.

**What the output or plot shows.** Printed SVD of the teaching rank-1 matrix (second value near zero, asserted), a one-shot CDL-A 2×2 narrowband snapshot (paths summed, delays ignored), and one line comparing s2/s1 for the toy and the draw. Predict the CDL-A s2/s1 first. Try (named property): `AngleScaling = true`, `AngleSpreads = [1 1 1 1]`.

**Check your understanding.** You have a 2-by-2 array. Why might you still be limited to one useful stream?

**Answer.** If the angle spread is tiny, H is nearly an outer product (rank 1). The second singular value collapses, and the second layer has almost no gain.

**Animation cue A2** (lines L50). Across a small array, a plane wave from angle θ gives a fixed phase step Δφ = 2π·d·sin θ / λ between neighbours — A plane wave sweeping a row of elements, with phase dials turning in equal steps. With a narrow spread the dials stay locked (rho ≈ 1). With a wide spread, many waves add, the dials wander, and rho drops.

**Animation cue A3** (lines L51–L52). Aligned columns → near rank one: beam gain, not independent streams — Column vectors of H drawn as arrows. They collapse onto one line for the narrow spread and fan apart for the wide one, and a singular-value bar chart morphs alongside.


## Recap (plan S7)

ANI: A C D L channel is clusters of rays with delays, powers and angles. The arrays belong to the channel object, with a five-number size. X P R is a finite power ratio, ten decibels by default. Narrow angle spread on a tight array means high correlation and near rank one. Wide spread breaks the correlation. Make a C D L C channel, measure two neighbours, and widen the spread.

Script closing print: cluster ≠ ray; arrays live on the channel; XPR is finite; narrow spread → rank 1.
