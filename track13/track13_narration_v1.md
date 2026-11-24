# Track 13 "Signals from Orbit": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,587 (1,487 narration plus 100 read-aloud self-check questions). **Est. read time:** 10.6 min at 150 wpm. With about 10 s of silence at each of the 5 self-check pauses, the total is about 11.4 min.
- **Budget (TIME_BUDGETS_v2, "Signals from Orbit" row):** min 7, typical 12, max 18 min. Read time is 1.4 min under typical; with pauses, 0.6 min under. Above the floor and below the ceiling. Length comes from the worked examples, the critical self-checks and the term definitions, not padding.
- **Path:** `track13/track13_narration_v1.md`. Sources were taken from the Track 13 lecture materials, whose files carry the title "Signals from Orbit" (RENUMBER_MAP 13 = old T12).
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T13_DFMEA.md; K = 5)
| DFMEA | Where handled |
|---|---|
| F6 transfer (336) | S5: the fixed estimator (complex ratio rx./wave, DC probe at row K/2+1); pause on why the probe sits at DC |
| F5 representation (240) | S3: 477 ms at nadir vs 541 ms worst case at 10 degrees, reconciled in one line; pause |
| F3 ordering (210) | S4 defines transmit-side pre-compensation; S5 calls the demo's step "receiver correction"; pause on the difference |
| F8 assessment (210) | S6: predict the HARQ process count before `showAnswer` is set to true |
| F2 prereq gap (125) | S2 glossary: service link, feeder link, gateway, transparent, regenerative, timing advance; S4: GNSS, ephemeris; pause |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A tower crossed out, a satellite drawn above it.

ANI: So far the cell has been on a tower. Now it's served from orbit, by a satellite hundreds or thousands of kilometers up. The physics doesn't change, but the numbers get huge. Today we measure how huge, and see how a phone keeps up.

## S2 Concept: words for a link through space (target 80 s)
[Screen] A phone, a satellite, and a ground station, with the two links labelled.

ANI: A non terrestrial network, or N T N, puts part of the radio link in space. Here are the words we need. The service link runs between the phone and the satellite. The feeder link runs between the satellite and a gateway, a ground station connected to the network.

The satellite's payload comes in two kinds. A transparent payload, sometimes called a bent pipe, just relays the waveform, so the signal travels phone to satellite to gateway. A regenerative payload decodes on board, so the link ends at the satellite.

And timing advance means the phone transmits early by the round trip, so its uplink lands on the base station's slot grid. In lecture twelve we turned time into distance. Here, distance turns into a lot of time.

[PAUSE — self-check] In one sentence each: what is the feeder link, and what does a regenerative payload do differently from a transparent one?

ANI: The feeder link joins the satellite to the gateway on the ground. A regenerative payload decodes the signal on the satellite, while a transparent one only relays it.

## S3 Code beat B1: round trips from geometry (target 140 s)
[Screen] Demo section B1, the printed round trips for GEO and LEO.

ANI: "A geostationary satellite sits thirty-five thousand seven hundred eighty-six kilometres up." G E O for short. A low earth orbit satellite, L E O, in the demo is at six hundred kilometers.

In the code, d G E O is thirty-five thousand seven hundred eighty-six kilometers, d L E O is six hundred, and the function r t t is legs times d over c. A transparent path covers the distance four times: phone up, down to the gateway, and the same back. A regenerative path covers it twice.

Worked example, for the first learning goal. Four times thirty-five million seven hundred eighty-six thousand meters, over the speed of light, is about four hundred seventy-seven point five milliseconds. Regenerative is half that, two hundred thirty-eight point seven. For L E O, four d over c is about eight milliseconds, and two d over c is about four point zero zero, which the script asserts.

Now, the song says something different: "and the worst round trip is about five hundred forty milliseconds, over half a second." Both numbers are right. Four hundred seventy-seven is at nadir, with the satellite straight overhead at its altitude. Five hundred forty-one is the worst case, at ten degrees elevation, where the slant range grows to about forty thousand five hundred eighty-one kilometers. That pairing is the one T R 38.821 uses. In the same way, a L E O at six hundred kilometers seen at ten degrees is about one thousand nine hundred thirty kilometers away, and the transparent worst case grows to about twenty-five point eight milliseconds.

[PAUSE — self-check] The code prints four hundred seventy-seven milliseconds, and the song says five forty. Which one is wrong?

ANI: Neither. Four seventy-seven uses the altitude, straight overhead. Five forty-one uses the longest slant path at the coverage edge. Always say which geometry you mean.

The script uses the exact speed of light, two nine nine seven nine two four five eight meters per second. Three times ten to the eight is about point zero seven percent high, which is a third of a millisecond at G E O. Try d equals twelve hundred kilometers: four d over c doubles to about sixteen milliseconds.

## S4 Code beat B2: speed and Doppler (target 120 s)
[Screen] Demo section B2, the cosine curve crossing zero at ninety degrees.

ANI: Close means fast. A L E O satellite moves about seven and a half kilometers every second. The Doppler shift is the speed over c, times the carrier frequency, times the cosine of the angle from the velocity vector.

Worked example, for the second learning goal. Seven thousand five hundred over the speed of light, times two gigahertz, is about fifty kilohertz. That's the maximum. At forty-five degrees from the velocity vector, it's about thirty-five point four kilohertz. Overhead, at ninety degrees, it crosses zero, and then the sign flips as the satellite moves away. On the ground, phones see Doppler in the hundreds of hertz. Here it's tens of kilohertz, more than the fifteen kilohertz subcarrier spacing itself. Try a three point five gigahertz carrier: the maximum becomes about eighty-seven point six kilohertz.

So how does the phone keep up? "Here's how the phone keeps up. It knows its own position from satellite navigation. It knows where the satellite is from the published orbit data, the ephemeris." Satellite navigation, G N S S, is the global navigation satellite system receiver in the phone. The ephemeris is the published orbit data. "From those two, it computes the distance and how fast that distance is changing. The distance sets how early to transmit. The rate sets how far to shift the frequency."

That's pre-compensation, and it happens on transmit, before anything is measured. The phone applies the opposite of the shift it predicts. What's left is the small part the geometry couldn't predict. The phone corrects only its own service link this way. Today's code makes no G N S S call; this part is spoken only.

## S5 Code beat B3: the N T N channel and a receiver correction (target 150 s)
[Screen] Demo section B3. Hold before the measured shift prints.

ANI: "Work out the big common shift from the altitude, the elevation, the carrier frequency, and the speed, put it in the satellite Doppler shift property, and the object adds it." In the code, the carrier is fifteen kilohertz with fifty-two resource blocks, and N R OFDM Info gives a sample rate f s of fifteen point three six megahertz. The applied shift is plus twenty kilohertz, a mid-pass L E O value.

The probe is one subcarrier, set to one on all fourteen symbols. k D C is fifty-two times twelve over two, plus one, which is row three hundred thirteen: the subcarrier at zero hertz.

[PAUSE — self-check] Why put the probe at zero hertz and not on the first row of the grid?

ANI: A probe at zero hertz makes a constant waveform, so any phase ramp in the output is the Doppler alone. Row one sits at minus four point six eight megahertz, and the estimator would measure that tone instead of the shift.

ANI: N R TDL Channel uses the delay profile N T N T D L A, with the Satellite Doppler Shift property set to the applied value. That property needs release twenty twenty-four a and an N T N profile. A plain T D L profile, from lecture six, doesn't include satellite Doppler. If the path isn't available, the script falls back to multiplying by a tone and says so.

The estimator, est F, divides r x by the complex wave, then measures the average phase step from one sample to the next. Gain and delay drop out for a constant probe.

Worked example, for the fifth learning goal. At twenty kilohertz and fifteen point three six megahertz, the phase step per sample is two pi times twenty thousand over fifteen point three six million, about zero point zero zero eight two radians. That's far below pi, so nothing wraps. Expect measured plus twenty kilohertz, asserted within one percent. Then r x Fix multiplies by the opposite ramp, and the residual prints near zero hertz.

Note the name. The code calls this a receiver correction: it measures, then removes. A phone in orbit service pre-compensates on transmit, from geometry, before anything is measured. The mathematics is the same opposite ramp, but the place and the information are different.

[PAUSE — self-check] Pre-compensation and receiver correction both apply an opposite frequency ramp. What's the real difference?

ANI: Pre-compensation happens at the transmitter, from G N S S and ephemeris, before measuring. Receiver correction happens after the signal arrives, from a measurement. Try flipping the sign in the correction: the residual doubles instead of vanishing.

## S6 Code beat B4: the H A R Q counterexample (target 120 s)
[Screen] Demo section B4, the frames-of-wait print, with the answer line still off.

ANI: Does the rest of the stack just work? Recall H A R Q from lecture five. Each H A R Q process sends a block and waits for its acknowledgement before sending again. Several processes take turns to keep the link busy.

Worked example, for the fourth learning goal. G E O transparent wait is four hundred seventy-seven point five milliseconds. At ten milliseconds per frame, that's about forty-seven point seven frames of waiting. L E O's eight milliseconds is under one frame.

[PAUSE — self-check] With one-millisecond slots and one slot per process, how many H A R Q processes would keep the G E O pipe busy? Work it out, then set show Answer to true.

ANI: Four hundred seventy-eight. N R allows at most sixteen, or thirty-two in the toolbox under release seventeen N T N. "With one millisecond slots and a round trip near five hundred forty milliseconds, thirty-two processes keep the link busy only about six percent of the time." Thirty-two over five hundred forty-one is about five point nine percent. With sixteen processes at four hundred seventy-seven, it's about three percent. That's why satellite links can skip some H A R Q feedback. The demo counts the geometry only and doesn't flip a feedback switch.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: A transparent round trip is four d over c, and a regenerative one is two d over c. G E O is about four hundred seventy-seven milliseconds at nadir and five hundred forty-one in the worst case. L E O Doppler reaches tens of kilohertz and flips sign overhead. The phone pre-compensates on transmit from G N S S and the ephemeris, and the receiver removes what's left. Long round trips stall stop-and-wait H A R Q. Next, in lecture fourteen, the radio hardware itself bends the signal.

---
## Notes for Showrunner
- **Learning goals (5 of 5).** LG1: 477.5 / 238.7 ms GEO and 8.01 / 4.00 ms LEO (the demo's nadir values), reconciled with 541.5 ms and LEO 25.8 ms worst case (10° slant ranges 40581 km and 1931.6 km, R = 6371 km). LG2: 50.0 kHz max, 35.4 kHz at 45°, 87.6 kHz at 3.5 GHz. LG3: pre-compensation explained (spoken only; there's no GNSS code). LG4: 47.7 frames and 478 processes; 32/541 ≈ 5.9% and 16/478 ≈ 3.3%. LG5: the 0.0082 rad/sample phase step and the 1% assert. All were checked in Python.
- **LG order.** The plan numbers HARQ as LG4 and the NTN channel as LG5. The narration takes them in demo beat order (B3 before B4) and labels each by its plan number.
- **Plan vs fixed demo.** The plan's LG1 leads with the worst-case values. The fixed demo prints nadir values and gives the worst case in a comment, so the narration follows the demo and reconciles the two (F5). The plan's FFT estimator is replaced in the demo by a lag-1 phase estimator on a DC probe; the narration follows the demo.
- **Unverified.** "Disable HARQ feedback" wording is a VERIFY item in the demo, so the narration says "can skip some feedback" (as the lyric does) and says the demo flips no switch. The GNSS/ephemeris pre-compensation wording is UNVERIFIED per the plan; it's spoken only. "32 in the toolbox / Rel-17 NTN" follows the demo's print text.
- **Lyric quotes.** All are verbatim and from the dry list: L7, L10, L28–31, L47–48 and L56–57. The hook, the outro, and the Breakdown's "pre-compensated by hand" line are not quoted. That last line describes a transmit-side shift, while the demo corrects at the receiver.
- **Terms (U = 5).** Transparent, regenerative, feeder link and service link (S2), and GNSS pre-compensation (S4), are defined at first use. Gateway, timing advance, ephemeris, NTN, GEO and LEO are also glossed.
- **Cross-references (new numbers).** Lecture five (HARQ), six (TDL), twelve (time to distance), and fourteen next.
