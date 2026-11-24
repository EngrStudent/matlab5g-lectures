# Track 03 "Find Me in the Noise": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,523 (1,406 narration plus 117 read-aloud self-check questions). **Est. read time:** 10.2 min at 150 wpm, or about 11.3 min with about 10 s of silence at each of the 7 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 03):** min 8, typical 14, max 21 min. About 2.7 min under typical. 6 LGs and 4 terms are each covered once; the rest of typical would be padding.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track03/track03_lyricbox.txt`, `lecture/track03/` demo_plan, demo.m (Try lines), lecture_notes; `pedagogue/T03_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F1: the 'phone knows nothing' hook (S2).
- F6: the B5 Period-5 prediction (S7); assert messages are named (S4).
- F2: polar/CRC/LLR are named, and there's a CRC-guarantee pause (S6).
- F3: the Lmax 8→4 switch is flagged (S3, S7) and the Lmax-4 ibar correction is stated (S6).
- F8: the PCI 397 commit (S4).
- F5: the correlation-curve pause (S4).
- F4: the SFN bit-order line is marked an aside (S6).

---
## S1 Cold open (target 30 s)
[Screen] Ani; a dark phone screen waking up.

ANI: "A phone wakes up in the dark." "It doesn't know the cell, the clock, or which beam points its way." All it knows is what to listen for. In this lecture we build the block it listens for, bury it in noise, and then recover the cell's name, its timing, and the beam that found us, the same way a phone does.

## S2 Concept: the synchronization block (target 130 s)
[Screen] Animation A2: the four-by-two-forty block assembling.

ANI: The phone's first problem is that it knows nothing: not the cell's identity, not where frames begin. So every cell repeats one small, fixed pattern called the synchronization signal block, or S S B. It's four symbols long and two hundred forty subcarriers tall.

Symbol zero holds the primary synchronization signal, P S S: one hundred twenty-seven tones in the middle. Symbol two holds the secondary synchronization signal, S S S, at the same width, with the broadcast channel on both edges. Symbols one and three are all broadcast channel, called P B C H, and every fourth tone of it is a reference signal, the P B C H D M R S.

Four terms we'll need, defined once here. The system frame number, or S F N, counts ten-millisecond frames from zero to one thousand twenty-three. The half-frame bit says whether a block sits in the first or second five milliseconds of its frame. K S S B is a small subcarrier offset that tells the phone how the block lines up with the carrier's resource blocks. And L max is the most blocks a burst can hold in this band: four, eight, or sixty-four.

## S3 Code beat B1: build one block by hand (target 150 s)
[Screen] Demo section B1 asserts, then the color map.

ANI: Here we build one block for cell three hundred ninety-seven, block index five, with L max set to eight. Section B5 later switches to L max four, and I'll flag it there. The script maps N R PSS, N R SSS, N R PBCH and N R PBCH DMRS into a two hundred forty by four array, and asserts every size: one hundred twenty-seven, one hundred twenty-seven, four hundred thirty-two, and one hundred forty-four.

Worked example, for the first learning goal. Count the broadcast channel's resource elements: two full symbols of two hundred forty, plus the two edges of symbol two, forty-eight each. That's four hundred eighty plus ninety-six, five hundred seventy-six. Of those, four hundred thirty-two carry data and one hundred forty-four are reference signal, one every fourth tone. The reference comb shifts with the cell: three hundred ninety-seven mod four is one, so it starts one tone in. The primary sync sits on rows fifty-seven to one hundred eighty-three, and one hundred eighty-three minus fifty-seven plus one is one hundred twenty-seven.

[PAUSE — self-check] Change the cell number and the block index. Which sizes change? Predict, then run.

ANI: None of them. The sizes are fixed by the block's layout. Only the sequence values and the reference comb's shift move.

## S4 Code beat B2: find the cell (target 170 s)
[Screen] Demo section B2: three correlation curves with the planted delay marked.

ANI: Now hide it. The script puts the block on symbols two to five of a fifteen kilohertz slot, delays it by three hundred thirty-three samples, and adds noise at ten decibels.

"There are only three primary sequences." "So slide across the samples and try all three." That's correlation: multiply the received samples against each candidate at every offset and add up. Where they match, you get a tall peak. On screen are the three correlation curves, with the true delay marked. The tallest peak tells us two things at once: where the block begins, and which of the three we heard. N R Timing Estimate finds the shift, and the script asserts it's exactly three hundred thirty-three.

[PAUSE — self-check] Look at the three curves. Which feature tells you the timing, and which tells you N I D two? Say both before you resume.

ANI: The peak's position along the samples is the timing. Which of the three curves holds the tallest peak is N I D two.

With timing known, demodulate and try all three hundred thirty-six secondary sequences. The best match is the group.

The cell's name, the physical cell identity or P C I, is "Three times the group, plus the one you heard first." The primary gives N I D two, from zero to two. The secondary gives N I D one, the group, from zero to three hundred thirty-five.

[PAUSE — self-check] Cell three hundred ninety-seven. Write down N I D one and N I D two before the script prints them.

ANI: Worked example, for the second and third learning goals. Three hundred ninety-seven mod three is one, so N I D two is one. Three hundred ninety-seven divided by three, rounded down, is one hundred thirty-two, so N I D one is one hundred thirty-two. Check: three times one hundred thirty-two plus one is three hundred ninety-seven. The search ran three primary tries, then three hundred thirty-six secondary ones: three hundred thirty-nine tests, not one thousand and eight.

If an assert fails here, its message names the step: P S S timing, P S S identity, or S S S identity. Start your check there.

## S5 Code beat B3: three cells, one primary sequence (target 80 s)
[Screen] The isequal check, then the uniqueness count.

ANI: "Here's the trap: cells zero, three and six sing the same primary sequence." The primary only carries the cell number mod three, and zero, three and six all leave remainder zero. The demo proves it with one isequal call that returns true. Then it checks that every pair of group and primary maps to a different cell: three hundred thirty-six times three is one thousand and eight unique names.

[PAUSE — self-check] Name three other cells that share a primary sequence with cell three hundred ninety-seven.

ANI: Any cells that leave remainder one: for example one, four, and seven. That's the fourth learning goal. "Only the secondary pulls them apart."

## S6 Code beat B4: which beam found you (target 150 s)
[Screen] DM-RS correlations, then the decode printout.

ANI: This beat uses three ideas from the map-of-the-link lecture. A C R C is a checksum that detects errors but doesn't correct them. A log-likelihood ratio, or soft bit, carries a guess and a confidence. And the broadcast channel uses a polar code, which this album treats as a black box: data in, protected bits out. No lecture teaches the polar decoder.

[PAUSE — self-check] Before the decode runs: if the C R C passes, is the decoded block guaranteed correct?

ANI: No. It's very likely correct, but a C R C only detects errors, with a tiny miss rate.

ANI: With L max eight, the broadcast reference signal comes in eight versions. The script tries all eight, and "the one that matches gives the low three bits of the block index". Worked example, for the fifth learning goal. The block index is five, and five mod eight is five, so the best match is version five. With eight or fewer blocks, that's the beam that found you.

Then the script estimates the channel from the reference signal, decodes the broadcast channel and the master information block, checks the C R C, and compares every bit, plus the half-frame bit. The master information block also points to CORESET zero, the control region the phone reads next to find system information block one. The frame number's low bits print next to a prediction from the specification's bit order. Treat that line as an aside: your run settles the toolbox's convention.

One correction to remember. When L max is four, the reference signal carries two bits of the block index plus the half-frame bit, not just two bits.

## S7 Code beat B5, with animation A3: the burst (target 160 s)
[Screen] Animation A3, then the demo's symbol count.

ANI: "Blocks come in a burst, all inside half a frame, five milliseconds." Each block has its own index, and the network can aim a beam with each one. Patterns called Case A through Case G set where the blocks start, by spacing and band.

Here's the switch I flagged. This section uses Case A at fifteen kilohertz, below three gigahertz, where L max is four, not eight.

Case A starts blocks on symbols two and eight, plus fourteen times n, with n zero or one. That gives two, eight, sixteen and twenty-two. "A phone that knows nothing may assume the burst returns every twenty milliseconds."

The demo builds the burst with N R D L Carrier Config, all four blocks on and a twenty millisecond period, with the data and control channels switched off. N R Waveform Generator makes twenty subframes, and the script counts which symbols carry energy.

[PAUSE — self-check] In twenty milliseconds at fifteen kilohertz, how many symbols light up, and where?

ANI: Worked example, for the sixth learning goal. Four blocks of four symbols each is sixteen symbols lit, out of twenty times fourteen, two hundred eighty, all inside the first two milliseconds.

[PAUSE — self-check] The Try line sets the period to five milliseconds. Predict the new count in twenty milliseconds.

ANI: The burst now repeats four times, at zero, five, ten and fifteen milliseconds, so sixty-four symbols. The expected list is derived from the transmitted blocks and the period, so your edit is checked, not rejected.

## S8 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four steps to keep. Search the primary sync in time: that gives the timing and one of three. Search the secondary: that gives one of three hundred thirty-six groups. Three times the group, plus the one you heard first, is the cell, and only the secondary separates cells zero, three and six. The broadcast reference signal names the beam, and the master information block gives the frame number and where to look next. Build one, bury it, and find it yourself.

---
## Notes for Showrunner
- Beats follow the demo file order B1→B2→B3 (FIXES F3d: the file order is kept; B4 depends on B2), not plan S4/S5.
- The SFN LSB bit order stays UNVERIFIED (the run settles it).
- Lyric quotes are verbatim (L02, L03, L16, L17, L20, L33, L35, L43, L47, L52).
