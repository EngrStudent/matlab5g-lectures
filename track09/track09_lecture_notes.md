# Track 09 "Steer the Beam" — lecture notes

Companion to [`track09_demo.m`](track09_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

## Cold open (plan S1)

ANI: Take many small antennas, each sending the same signal. Get the timing of each one right, and the copies add up in one direction and cancel in others. That's beamforming. Today we build the array, steer it, measure the gain, and break it on purpose.

*Problem first:* path loss at mid-band and mmWave is large; the 12 dB from 16 coherent elements is what closes the link.

## B1. Build the array and its steering vector

**Key idea.** A uniform linear array points a beam by applying a progressive phase across its elements. For half-wavelength spacing the steering vector toward angle theta is a phase ramp in sin(theta). phased.ULA and phased.SteeringVector are the documented way to build that vector. Broadside (0 deg) is the array normal, not end-fire.

**Math.**

$$a_n(\theta)=\exp\bigl(-j 2\pi n\,(d/\lambda)\sin\theta\bigr),\quad d=\lambda/2.$$
At $0^{\circ}$ the entries are equal in magnitude (and, up to a global phase, equal to one). At $30^{\circ}$ you should see a linear phase step.

**Lyric** (certified spelling):

> L7: Line up elements half a wavelength apart and call it a uniform linear array.
> L9: At half wavelength spacing, the phase step between neighbours is pi times sine theta.
> L10: Write those phases down, one per element, and you have the steering vector.
> L64: Open the toolbox. Build Phased dot U L A with sixteen elements at half a wavelength.
> L65: Ask Phased dot Steering Vector for the weights toward thirty degrees.

**What the output or plot shows.** Printed unique magnitudes at 0 deg (about 1) and the phase step in degrees at 30 deg.

**Check your understanding.** If you write exp(-j*2*pi*n*0.5*sin(theta)) with theta in degrees, what goes wrong?

**Answer.** sin() in MATLAB takes radians. You must convert, or use sind. A 30 deg steer written that way is almost a 30 radian steer.

**Animation cue A1** (lines L8–L9). A plane wave from θ reaches each element later; at d = λ/2 the phase step is π·sin θ — A wavefront tilted at θ sweeps a row of 16 dots, and each dot's phase dial lags the last by π·sin θ. At θ = 30° the dials step by 90°.

## B2. Pattern, gain and the power invariant

**Key idea.** If the transmitters share a fixed total power, split by unit-norm weights, the look-direction amplitude is $|w^H a|=\sqrt{N}$, so the power gain is 10*log10(N): 16 elements give 12.04 dB, 64 give 18.06 dB. The power is not created; it is taken from other directions. **One setup, stated once:** fixed total Tx power → 10 log10 N. If each element keeps its own full power, total power also grows by N and EIRP grows as N² (20 log10 N); that is a different setup, not an error. Receive-side framing (A2: signal ∝ N², noise ∝ N) gives the same 10 log10 N SNR gain.

**Math.**

$$G_{\mathrm{coh}}=10\log_{10} N.$$
$$10\log_{10}16=12.0412\,\mathrm{dB},\qquad 10\log_{10}64=18.0618\,\mathrm{dB}.$$

**Lyric** (certified spelling):

> L27: if every weight has magnitude one, the total power sent stays the same.
> L28: Steering doesn't make energy. It moves energy, toward one angle and away from the rest.
> L29: The gain comes from adding in phase: the signal power grows with N squared,
> L31: Sixty-four elements give ten log ten of sixty-four, about eighteen decibels.
> L66: Plot the pattern. One main lobe, leaning where you asked.

**What the output or plot shows.** The measured broadside pattern peak, asserted against 10*log10(N) (the hard-coded 18.06 print is gone, so the N = 64 Try is a real prediction), and a pattern plot.

**Check your understanding.** You forget to normalise the weights and a longer array looks like it has more than 10*log10(N) dB of 'gain.' What did you actually do?

**Answer.** You silently radiated more total power. The invariant is for a fixed total power (unit-norm weights).

**Animation cue A2** (lines L29–L30). Coherent sum: signal ∝ N², noise ∝ N, so SNR × N; 64 → 18.06 dB — Phasors adding head to tail into a long straight arrow (signal), beside a random walk of noise phasors with a short net arrow. A dB counter reads 10·log10(N) as N grows to 64.

## B3. The grating-lobe counterexample

**Key idea.** If the element spacing is larger than half a wavelength, the array factor aliases and a second lobe (a grating lobe) appears at a false angle. The beam can still look sharp, but it no longer has a unique pointing direction. Peak finding is done in base MATLAB, not with findpeaks, so the demo does not require the Signal Processing Toolbox.

**Math.**

Compare $d=0.5\lambda$ (one main lobe in $[-90,90]$) with $d=1.0\lambda$ (extra grating lobes). The demo counts local maxima within 8 dB of the peak and asserts the wider spacing has more of them.

**Lyric** (certified spelling):

> L41: Here's the counterexample. Set the spacing to a whole wavelength
> L42: and steer anywhere off broadside.
> L43: A second lobe appears, just as strong as the first, pointing somewhere you never meant.
> L45: Keep the spacing at half a wavelength, and only one main lobe can form.
> L67: Now set the spacing to one wavelength and plot again.

**What the output or plot shows.** Both arrays steered to 30° (matching A3). Printed lobe counts and angles: d = λ/2 → one lobe at 30°; d = λ → lobes at 30° and −30° (asserted: more lobes). Try: 0.75 λ → 2 lobes (−56.5°, 30°); 1.5 λ → 3 (−56.5°, −9.5°, 30°). (The v1 broadside steer put the d = λ lobes on the ±90° endpoints, which the peak finder excludes, so its assert failed.)

**Check your understanding.** You stretch a 16-element array to a wider spacing without adding elements, and the beam looks narrower. What did you risk?

**Answer.** Grating lobes: a second pointing direction that is just as strong, so the beam is no longer unique.

**Animation cue A3** (lines L41–L44). At d = λ, sin θg = sin θ0 − 1: a second full lobe at −30° — A polar pattern morphing as the spacing slides from λ/2 to λ. A second lobe grows at −30° to equal height. The equation is drawn beside it.

## B4. Hybrid weights and where CSI comes from

**Key idea.** A phone does not send a full N-element channel matrix every slot. Hybrid beamforming uses a few RF chains behind many elements, and the CSI the scheduler sees (CQI, a beam index, a PMI) is a compressed look at that array. nrCQITables (R2024a) is a glimpse of those reported CQI values; a CQI index is not a beam angle.

*Glossary (D4: this CSI half is sung and also given as a spoken aside).* **CSI** — the phone's channel report; its reference signal, CSI-RS, is taught in T10. **CQI** — channel quality index; its 0.1 BLER target is T11. **PMI** — index of a precoder (beam weights). **Beam index** — which of a set of beams was strongest. **RF chain** — one DAC/ADC and mixer path. **Hybrid** — a few RF chains behind many elements (digital × analogue weights).

**Math.**

A one-RF-chain analogue weight $w$ pointed at $0^{\circ}$ has on-boresight power $|w^{H}a(0)|^{2}=N$ for unit-norm $a$ with the same normalisation as B2, and a smaller value at $30^{\circ}$. CQI table names are printed if the function is present.

**Lyric** (certified spelling):

> L48: A big array can't afford a full radio chain behind every element.
> L52: O M P hyb weights, in the Phased Array System Toolbox,
> L53: works out the analog and the digital weights together, for the radio chains you have.
> L57: In the downlink, the phone measures the C S I R S and reports back:
> L58: a rank for how many layers, a precoder index for which beam,
> L60: That bundle is the C S I report. In the release we're using, the examples pick it

**What the output or plot shows.** Printed on-boresight vs 30 deg incident power, and the nrCQITables property names (or a skip message on an older release).

**Check your understanding.** Can a one-RF-chain hybrid beam still reach the full 10*log10(N) per layer if the analogue weight is pointed at the wrong angle?

**Answer.** No. That full gain is only in the steered direction. A mismatched steer gives up some, or most, of it.


## Recap (plan S6, hold to ≤ 45 s)

ANI: The steering vector is one phase per element. At half a wavelength, the step is pi times sine theta. Unit-magnitude weights move energy without making it, and coherent gain is ten log ten of N. Space the elements a full wavelength apart and a grating lobe appears. Hybrid beamforming shares a few radio chains across many elements, and the phone's channel report tells the base station where to aim. Build the array, steer it to thirty degrees, then widen the spacing.

Script closing print: a phase ramp steers; 10·log10 N under fixed power; d > λ/2 aliases; a mis-steer loses gain.
