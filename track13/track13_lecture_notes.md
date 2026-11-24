# Track 13 "Signals from Orbit" — lecture notes

Companion to [`track13_demo.m`](track13_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / terms.** HARQ processes come from T05. *Service link*: UE ↔ satellite. *Feeder link*: satellite ↔ gateway (the ground station that connects to the core). *Transparent* payload relays the waveform (bent pipe); *regenerative* payload decodes on board. *Timing advance*: the UE transmits early by the round trip so its uplink lands on the gNB's slot grid. *GNSS pre-compensation*: the UE uses its own GNSS position plus the satellite ephemeris to pre-shift timing and frequency on transmit.

## Cold open (plan S1)

ANI: So far the cell has been on a tower. Now it's served from orbit, by a satellite hundreds or thousands of kilometres up. The physics doesn't change, but the numbers get huge. Today we measure how huge, and see how a phone keeps up.

## B1. Round trips from geometry

**Key idea.** A bent-pipe (transparent) satellite relays the waveform, so the radio path is ground-space-ground-space-ground and the RTT is 4d/c. A regenerative payload terminates the link on the satellite, so the RTT to the payload is 2d/c. These are geometry, not a toolbox call: TR 38.821 uses this pairing, with c = 299792458 m/s. Using 3e8 would be a 0.07% error, which is not free at GEO ranges.

**Math.**

$$\mathrm{RTT}_{\mathrm{transparent}}=4d/c,\qquad \mathrm{RTT}_{\mathrm{regenerative}}=2d/c,\quad c=299792458\,\mathrm{m/s}.$$
GEO $d=35786\,\mathrm{km}$: $2d/c=238.74\,\mathrm{ms}$, $4d/c=477.48\,\mathrm{ms}$.
Two GEO numbers appear in this track: 477 ms at nadir (d = 35 786 km, used in the code) and 541 ms worst case at 10° elevation (slant range 40 581 km, TR 38.821, used in A1 and A3).
LEO $d=600\,\mathrm{km}$: $2d/c=4.003\,\mathrm{ms}$, $4d/c=8.006\,\mathrm{ms}$.

**Lyric** (certified spelling):

> L7: A geostationary satellite sits thirty-five thousand seven hundred eighty-six kilometres up.
> L8: At the edge of its coverage, the phone can be over forty thousand kilometres away.
> L10: and the worst round trip is about five hundred forty milliseconds, over half a second.
> L12: and the worst round trip is about two hundred seventy.
> L14: about twenty-six milliseconds worst case, transparent, and about thirteen regenerative.

**What the output or plot shows.** Printed GEO and LEO round trips in both pairings, with a tight assert on the LEO regenerative 4.00 ms figure.

**Check your understanding.** Someone quotes 2d/c as the RTT of a transparent GEO relay. What did they miss?

**Answer.** A transparent payload is a bent pipe. The service-link path is travelled twice in each direction, so the RTT is 4d/c, about 477 ms at this GEO height, not 239 ms.

**Animation cue A1** (lines L7–L10). Worst-case GEO RTT = 4d/c with d = 40581 km at 10° elevation — Earth with a GEO satellite. A UE and a gateway sit at the coverage edge. A pulse runs UE → satellite → gateway → satellite → UE, and a millisecond counter stops at 541.

## B2. Speed and Doppler

**Key idea.** A LEO satellite at 7.5 km/s and a 2 GHz carrier have a maximum line-of-sight Doppler of (v/c)*f_c, about 50 kHz, times the cosine of the angle off the velocity vector. The sign flips as the satellite passes overhead. Precompensation is applying the opposite shift, which only works if the shift is known. Terrestrial Doppler intuition (hundreds of hertz) is the wrong scale here.

**Math.**

$$f_{D,\max}=(v/c)f_c.$$
For $v=7.5\,\mathrm{km/s}$ and $f_c=2\,\mathrm{GHz}$: $f_{D,\max}=50.035\,\mathrm{kHz}$.
Along a pass, $f_D=f_{D,\max}\cos\alpha$, zero at overhead ($\alpha=90^{\circ}$), and the sign flips.

**Lyric** (certified spelling):

> L17: Close means fast. A low orbit satellite moves about seven and a half kilometres every second.
> L18: At a carrier near two gigahertz, that's a Doppler shift of tens of kilohertz.
> L56: Work out the big common shift from the altitude, the elevation, the carrier frequency, and the speed,

**What the output or plot shows.** Printed max Doppler, plus a plot of Doppler versus pass angle with a zero crossing at overhead.

**Check your understanding.** At the zenith of a LEO pass, is the Doppler at its maximum?

**Answer.** No. The radial speed is smallest overhead, so the Doppler crosses zero. The maximum is near the horizon, along the velocity vector.

**Animation cue A2** (lines L30–L33). Distance sets the timing advance; its rate sets the frequency pre-shift; whatever geometry predicts is removed before sending — A LEO pass overhead. A range curve d(t) sits above its slope, ḋ(t). Two dials, "send early by d/c" and "shift by −f·ḋ/c", track the curves. The residual trace below stays near zero.

## B3. NTN channel: add the shift, measure it, remove it

**Key idea.** R2024a's nrTDLChannel documents SatelliteDopplerShift as an NTN parameter. The property is enabled only for the NTN delay profiles, so the demo uses `NTN-TDL-A`. It applies a known shift, measures it as a phase ramp on a DC probe (one subcarrier at 0 Hz on all 14 symbols, so the complex ratio rx./wave is a clean ramp), then removes it at the receiver. That is a *receiver correction*, not pre-compensation: an NTN UE pre-compensates on transmit from GNSS and ephemeris, before anything is measured. If the property is missing on a run, the same experiment falls back to a base-MATLAB tone shift. GNSS-quality orbit knowledge is a lecture point, not a toolbox measurement (the S4 spoken line has no GNSS API call).

**Math.**

Applied $20\,\mathrm{kHz}$, then a one-lag phase estimator on $r=\mathrm{rx}/\mathrm{wave}$: $\hat{f}=\angle\big(\sum r_n^* r_{n+1}\big)\,f_s/(2\pi)$, then receiver correction $e^{-j2\pi\hat{f}t}$. Per-sample phase step at 20 kHz, 15.36 MS/s: 0.00818 rad (no wrap). Residual frequency after correction should be ≈ 0 Hz.

**Lyric** (certified spelling):

> L54: N R TDL Channel has non terrestrial profiles: N T N T D L A through N T N T D L D,
> L57: put it in the satellite Doppler shift property, and the object adds it.
> L60: Open the toolbox. Make N R TDL Channel with N T N T D L C.
> L61: Set a satellite Doppler shift for a low orbit pass and send a slot through.
> L62: Measure the frequency offset of what comes out.
> L63: Now shift the transmit signal the other way by the same amount, and send it again.

**What the output or plot shows.** Printed applied vs measured shift (asserted within 1 %), a fallback flag, and the residual frequency after the receiver correction. A skip message appears if SatelliteDopplerShift is not on this release.

**Check your understanding.** You apply the correction with the wrong sign. What happens to the residual Doppler?

**Answer.** It roughly doubles, instead of cancelling. The measured sign has to follow the applied shift before you use it.

## B4. The HARQ counterexample

**Key idea.** A GEO transparent RTT is about 477 ms, which is many 10 ms frames. A stop-and-wait HARQ process that waits for that ACK will sit idle for tens of frames. Disabling or extending HARQ is the standard NTN discussion point; this beat counts the occupancy, it does not flip a hidden 'HARQ off' flag in the toolbox. Wording that a toolbox flag disables HARQ feedback was not confirmed from a spec or MathWorks page this round (VERIFY).

**Math.**

GEO transparent wait $=477.48\,\mathrm{ms}=47.7$ frames of $10\,\mathrm{ms}$.
LEO transparent wait $=8.006\,\mathrm{ms}=0.80$ frames.
Processes needed to keep a 1 ms (15 kHz) GEO slot pipe busy: at least $\lceil 477.48\,\mathrm{ms}/1\,\mathrm{ms}\rceil=478$.

**Lyric** (certified spelling):

> L45: Back when we first sent blocks, HARQ had up to thirty-two processes in the toolbox.
> L46: Each one waits for its answer before it sends again.
> L47: With one millisecond slots and a round trip near five hundred forty milliseconds,
> L48: thirty-two processes keep the link busy only about six percent of the time.

**What the output or plot shows.** Printed waits in milliseconds and in 10 ms frames. The process count for a busy GEO pipe is behind `showAnswer = false`, so the Try is answered by the learner first. A3's "32 processes" is the toolbox/Rel-17 maximum; 478 is what a 1 ms GEO pipe would need, which is why NTN allows disabling HARQ feedback.

**Check your understanding.** You pack a GEO link with the same small number of HARQ processes you use on a terrestrial 1 ms slot. Where did the throughput go?

**Answer.** Each process is waiting almost half a second for an ACK, so the pipe sits mostly idle. You need many more processes, or a different HARQ plan, to keep the link busy.

**Animation cue A3** (lines L46–L48). 32 stop-and-wait processes over a 541 ms RTT: busy ≈ 5.9 % — A timeline. 32 one-millisecond blocks go out, then a long empty gap waits for the first answer. A busy fraction is labelled.


## Recap (plan S7)

ANI: Geostationary round trips run up to about five hundred forty milliseconds, and low orbit Doppler runs to tens of kilohertz. The phone uses its own position and the orbit data to pre-shift both timing and frequency, so only the unpredictable part remains. The toolbox models it with N T N profiles in N R TDL Channel and a satellite Doppler shift. And long round trips stall stop-and-wait HARQ. Set a shift, measure it, cancel it.

Script closing print: 4d/c transparent, 2d/c regenerative; tens of kHz of Doppler with a sign flip; HARQ needs many processes, or disabling.
