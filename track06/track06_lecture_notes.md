# Track 06 "Taps in Time" — lecture notes

Companion to [`track06_demo.m`](track06_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / order.** In D2 order this track follows T05 "Say It Again" and comes *before* T07 "Learn the Channel", so it is the first track that builds an `nrTDLChannel`.

## Cold open (plan S1)

ANI: One signal leaves the tower. It reaches you many times, off buildings, off hills, off the road. Every copy is late, and every one has its own strength. Today we model that with a short list of taps, and test one assumption most people get wrong.

## B1. Build the channel, scale the delays

**Key idea.** A TDL is a list of delays and average powers. The tabulated TDL-A delays are normalized; multiplying by DelaySpread stretches the same shape in time. Twice the delay spread is twice the echo length, which is exactly the prefix-margin question from Track 2. Average path gains stay put when you scale DelaySpread. A named profile's delays and powers are read from `info(ch).PathDelays` / `info(ch).AveragePathGains`; the `PathDelays` / `AveragePathGains` *properties* apply only to `'Custom'` profiles. Units: DelaySpread is in seconds; convert a CP length in samples with samples = seconds × fs before comparing.

**Math.**

$$\tau_k(\mathrm{DS})=\tau_k^{\mathrm{norm}}\cdot\mathrm{DS}.$$

**Lyric** (certified spelling):

> L12: In N R TDL Channel, set the delay profile to T D L A, then choose the delay spread.
> L15: The table lists the delays in units of the delay spread.
> L19: Multiply every normalized delay by the delay spread,
> L20: and the shape stays the same, only the time stretches.
> L60: Make an N R TDL Channel with T D L A and a delay spread of three hundred nanoseconds.

**What the output or plot shows.** Printed first and last delays (ns and samples) at 30 ns and 300 ns, with an assert that d/DS is identical for both (TDL-A's first delay is 0, so the v1 ratio divided by zero).

**Check your understanding.** If you double DelaySpread, what happens to the average path powers, and what happens to the last delay?

**Answer.** The powers stay the same; the last delay doubles. You stretched the profile in time, you did not remix its powers.

**Animation cue A1** (lines L19–L20). Real delay = normalized delay × DelaySpread; shape unchanged — A tap stem plot on a normalized axis. A time ruler slides under it and stretches from 30 ns to 300 ns, the stems ride along, and the heights don't change. Tap 2 and tap 23 delays are labelled (B1 values).

## B2. The counterexample: first is not loudest

**Key idea.** TDL-A's first tabulated tap is -13.4 dB and the second is 0 dB, so 'the earliest path is the strongest path' is false for this profile. A peak-search that always locks onto tap 1 would lock onto a weak arrival. The claim is about the tabulated averages, not one faded realisation (a single path-gain draw can still put the instantaneous peak on another tap).

**Math.**

TDL-A: $\mathrm{AveragePathGains}(1)=-13.4\,\mathrm{dB}$, $\mathrm{AveragePathGains}(2)=0\,\mathrm{dB}$. The second tap is the strongest on the table.

**Lyric** (certified spelling):

> L26: You'd think the first arrival is always the loudest. Look at T D L A.
> L27: Its first tap sits at delay zero, thirteen point four decibels down.
> L28: The second tap, a little later, is the strongest of them all, at zero decibels.
> L61: Plot the average power of every tap.
> L62: Find the strongest tap. Is it the first? Now switch to T D L D and look again.

**What the output or plot shows.** A printed first-four gain list, asserts on -13.4 dB and 0 dB, and a stem plot of the average profile.

**Check your understanding.** Why is it a mistake to assert, on one call of the path gains, that tap 2 is loudest?

**Answer.** Because that is one faded draw. The teaching claim is about AveragePathGains, the tabulated means.

**Animation cue A2** (lines L26–L28). TDL-A: tap 1 at 0 delay is −13.4 dB; tap 2 at 0.3819 is 0 dB — Arrivals drop in as stems in time order. The first is short, the second the tallest. A "loudest" marker jumps from stem 1 to stem 2.

## B3. Doppler: fading in time

**Key idea.** The maximum Doppler shift is v / lambda = v * f_c / c. At 3 GHz, lambda is 0.1 m, so v = 30 m/s (a car) is 300 Hz. The toolbox default MaximumDopplerShift = 5 Hz is only 0.5 m/s, a stroll, not a drive. That number sets how fast the path gains move, not the delay profile. *Model:* each tap is a random complex gain whose average power is the tabulated value; Doppler sets how fast it wanders. *Coherence time* $T_c\approx 0.423/f_D$: about 1.4 ms (≈ 20 OFDM symbols at 15 kHz) at 300 Hz, about 85 ms at 5 Hz.

**Math.**

$$\lambda=c/f_c,\qquad f_D=v/\lambda=v f_c/c.$$
At $f_c=3\,\mathrm{GHz}$, $\lambda=0.09993\,\mathrm{m}\approx 0.1\,\mathrm{m}$, so $v=30\,\mathrm{m/s}$ gives $f_D=300.2\,\mathrm{Hz}\approx 300\,\mathrm{Hz}$.
A 5 Hz default would be $v=5\lambda\approx 0.50\,\mathrm{m/s}$.

**Lyric** (certified spelling):

> L43: The fastest it can swing is set by the maximum Doppler shift: speed over wavelength.
> L44: At three gigahertz the wavelength is about ten centimeters,
> L45: so thirty meters a second gives about three hundred hertz.
> L63: Double the Doppler and watch the fading speed up.

**What the output or plot shows.** Printed lambda, f_D, T_c, and the equivalent speed of the 5 Hz default, asserts on the 0.1 m / 300 Hz teaching values, and a 10 ms plot of the strongest tap's |path gain| at 5 Hz (nearly flat) vs 300 Hz (fades within a few ms).

**Check your understanding.** Is a 5 Hz maximum Doppler a reasonable stand-in for a car at 3 GHz?

**Answer.** No. A car at 30 m/s is about 300 Hz. Five hertz is a walking speed.

**Animation cue A3** (lines L43–L45). f_D = v/λ; λ = 0.1 m at 3 GHz; 30 m/s → 300 Hz — A wavefront spacing of 10 cm with a phone moving at 30 m/s, crossing 300 wavefronts per second. The counter ticks.

## B4. Shortcuts and what the estimator must track

**Key idea.** TDL-A/B/C are compact, repeatable stand-ins for a measured profile. They hide angle structure (that is Track 8) and they do not excuse an estimator from tracking whatever time variation you asked for. At 300 Hz (T_c ≈ 1.4 ms) an estimate is stale within about a slot; at 5 Hz it lasts many slots.

**Math.**

The three knobs this lecture treats as 'the channel you told the estimator to face' are DelayProfile, DelaySpread and MaximumDopplerShift.

**Lyric** (certified spelling):

> L51: The test specs add shortcuts: T D L A thirty, T D L B one hundred, T D L C three hundred.
> L52: They're valid delay profiles in the toolbox too.
> L55: Wide delay spread makes the channel change from tone to tone.
> L56: Fast Doppler makes it change from symbol to symbol.

**What the output or plot shows.** A one-line print of those three knobs at the 300 Hz setting, and the reuse error of an estimate taken on symbol 2 and reused on symbol 13, at 5 Hz and at 300 Hz.

**Exercise (no answer given).** What is f_D at 3.5 GHz and 120 km/h, and roughly how many 30 kHz-SCS slots fit in one coherence time?

**Check your understanding.** What is the difference between delay spread and Doppler, in one sentence each?

**Answer.** Delay spread is the echo length in time (a prefix-margin question). Doppler is how fast those taps fade (a pilot-reuse question).


## Recap (plan S7)

ANI: A TDL model is a list of taps, each with a delay and a power. Multiply the normalized delays by the delay spread. The first arrival isn't always the strongest, and T D L A proves it. Doppler is speed over wavelength. For line-of-sight profiles, the K factor says how much the direct path stands out. Build the channel, find the strongest tap, and double the Doppler.

Script closing print: the three knobs (profile, DelaySpread, MaximumDopplerShift), one line each, plus the T_c rule.
