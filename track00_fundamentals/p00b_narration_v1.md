# P00b "Map of the Link": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,005 (914 narration plus 91 read-aloud self-check questions). **Est. read time:** 6.7 min at 150 wpm, or about 7.7 min with about 10 s of silence at each of the 6 self-check pauses.
- **Budget (TIME_BUDGETS_v2, P00B):** min 7, typical 8, max 9 min. Just under typical. Spoken-only.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `pedagogue/ARCHITECTURE_PASS.md` P00_SPEC (objectives 7–13, the P00b beat table) and its unblock map; `pedagogue/TIME_BUDGETS_v2.md`; DECISIONS D1/D7. There is no `lecture/p00/` source, demo, DFMEA or lyrics.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
There is no DFMEA, so the self-checks sit at the commit points: SSB first (B1), code rate 0.5 and the CRC guarantee (B2), LLR 1.6 (B3), about 2 coherent slots and TA 20 µs (B4).

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A phone icon, then four steps: find, listen, get data, report.

ANI: A phone wakes up. It has to find a cell, listen for instructions, receive data, and report back what it hears. Each step uses a different signal in the same grid. This lecture is the map: who sits where, how the bits are protected, and how fast the channel changes underneath them.

## S2 Concept: three questions (target 45 s)
[Screen] Three headings: where, how protected, how fast.

ANI: Three questions organize the rest of the album. Where does each signal sit on the grid? How is a block of bits protected before it's sent? And how quickly do time, distance, and motion change the channel? This lecture gives each idea a name, a one-line meaning, and the lecture that teaches it properly. Labels first, mechanisms later.

## S3 Beat B1: the channel map (target 95 s)
[Screen] Animation A1: one labeled downlink slot, then an uplink slot.

ANI: Here's one downlink slot, labels only. The synchronization signal block, S S B, is what a phone finds first: it carries the cell's identity and timing. Lecture 03.

The control channel, P D C C H, tells each phone where its data is. It sits in a control region called a CORESET, and each message is addressed to a phone by an identifier called an R N T I. The album names these; lecture 15 shows them in a full configuration.

The shared data channel, P D S C H, carries the data, with its demodulation reference signal, D M R S, mixed in so the receiver can measure the channel. Lectures 05 and 07.

The channel state information reference signal, C S I R S, lets the phone measure the channel and report back. On the uplink, the sounding reference signal, S R S, lets the base station measure the channel from the phone. Both are lecture 10.

[PAUSE — self-check] Which signal does a phone read first, and why that one?

ANI: The S S B. Until it has found it, the phone knows neither the cell nor the timing, so it can't read anything else.

## S4 Beat B2: the coding chain (target 95 s)
[Screen] Animation A2: the chain, with a circular buffer and four start points.

ANI: Before a block is sent, five steps protect it. First a C R C, a cyclic redundancy check, which lets the receiver detect errors. Then a channel code adds structured redundancy: a polar code for broadcast and control, an L D P C code for data. Then rate matching picks exactly E bits to fit the grid, reading from a circular buffer. The starting point in that buffer is the redundancy version, R V. Then scrambling mixes the bits with a known sequence, so neighboring cells' interference looks like noise. Then modulation onto the grid.

The code rate R is the information bits K over the sent bits E.

[PAUSE — self-check] K is one thousand bits and E is two thousand. What's the code rate?

ANI: One thousand over two thousand: one half.

[PAUSE — self-check] A twenty-four bit C R C passes. Is the block guaranteed correct?

ANI: No. For random errors, a twenty-four bit C R C misses about one in two to the twenty-four, roughly one in seventeen million. It detects errors; it never corrects them. Lecture 04 teaches the C R C and L D P C. Lecture 05 uses redundancy versions. The polar code stays a black box in this album.

## S5 Beat B3: soft bits (target 70 s)
[Screen] Animation A3: a number line with an LLR moving along it.

ANI: A hard decision says zero or one. A soft decision also says how sure. The log-likelihood ratio, L L R, is the log of the probability the bit is zero over the probability it's one. Its sign is the guess, and its size is the confidence. In this album, positive means zero. The decoder needs a noise variance, n Var, to scale those numbers.

For B P S K in Gaussian noise, the L L R is two times the received value over the noise variance.

[PAUSE — self-check] Received value point four, noise variance point five. Compute the L L R, and say what the decoder guesses.

ANI: Two times point four over point five is one point six. Positive, so it guesses zero, with modest confidence. Lectures 03, 04 and 07 all use soft bits.

## S6 Beat B4: time, distance, and change (target 95 s)
[Screen] A moving car, a delay profile, a TDD frame and an FDD pair, a tower and a phone at a distance.

ANI: Four rules. Doppler shift is speed times carrier frequency over the speed of light. Coherence time, how long the channel stays about the same, is roughly zero point four two three over the Doppler shift. Other conventions exist; this album uses that one.

Coherence bandwidth, how far in frequency the channel stays about the same, is roughly one over five times the root mean square delay spread. Again, a convention.

Time division duplex, T D D, sends both directions on the same frequency at different times, so the channel measured one way applies the other way. That's reciprocity. Frequency division duplex, F D D, uses two different frequencies, so it doesn't get reciprocity for free. Lecture 10.

Timing advance makes a phone transmit early, by the round trip time, two times the distance over the speed of light, so its signal arrives on time.

[PAUSE — self-check] A phone moves at one hundred twenty kilometers an hour on a three point five gigahertz carrier. About how many thirty kilohertz slots stay coherent?

ANI: One hundred twenty kilometers an hour is about thirty-three point three meters a second. Times three point five billion over three hundred million gives a Doppler shift of about three hundred eighty-nine hertz. Point four two three over that is about one point one milliseconds. A thirty kilohertz slot is half a millisecond, so about two slots. Lecture 06.

[PAUSE — self-check] What timing advance does a phone three kilometers away need?

ANI: Two times three thousand meters over three hundred million meters a second: twenty microseconds. Lecture 13 needs this at satellite distances.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Five things to keep. The map: S S B first, then control in a CORESET, data with its D M R S, and C S I R S and S R S for measuring. The chain: C R C, channel code, rate matching with a redundancy version, scrambling, modulation, and code rate is K over E. A soft bit's sign is the guess and its size is the confidence. Coherence time is about point four two three over Doppler, and coherence bandwidth is about one over five times the delay spread. Timing advance is the round trip, two d over c. Next, lecture 01: the numerology that shapes the grid.

---
## Notes for Showrunner
- Objectives 7–13 are covered.
- B1 has 6 labels, over the load cap; per P00_SPEC they stay labels only.
- The coherence time (0.423/f_D) and coherence bandwidth (1/(5·τ_rms)) conventions are stated as conventions.
- I took the lecture pointers from ARCHITECTURE_PASS after the renumber: PDCCH/CORESET → 15, CSI-RS/SRS/TDD → 10, TA → 13. Please check them against the map.
