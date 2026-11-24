# Track 11 "One in Ten": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,570 (1,473 narration plus 97 read-aloud self-check questions). **Est. read time:** 10.5 min at 150 wpm. With about 10 s of silence at each of the 5 self-check pauses, the total is about 11.3 min.
- **Budget (TIME_BUDGETS_v2, "One in Ten" row):** min 7, typical 11, max 16 min. Read time is 0.5 min under typical; with pauses, 0.3 min over. Above the floor and below the ceiling. Length comes from the worked examples, the critical self-checks and the term definitions, not padding.
- **Path:** `track11/track11_narration_v1.md`. Sources were taken from the Track 11 lecture materials, whose files carry the title "One in Ten" (RENUMBER_MAP 11 = old T14).
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T11_DFMEA.md; K = 5)
| DFMEA | Where handled |
|---|---|
| F3 ordering (392) | S4: two BLERs defined, first transmission vs after HARQ; 0.1 attached to first transmission only; pause |
| F5 representation (252) | S4: throughput per slot actually used; S6: B4 prints, never asserts, the crossing; pause on the throughput bound |
| F6 transfer (175) | S4: the Try is rvSeq = 0, and the after-HARQ curve slides right; pause predicts it |
| F8 assessment (150) | S4: predict the first-transmission 0.1 crossing before the loop prints it |
| F4 load (140) | S6: one sentence on the two receivers; pause on "what is the only difference" |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A long chain of boxes drawn left to right.

ANI: Every piece we've built goes into one loop today. Data enters at the transmitter, a channel and noise get in the way, and at the end we count how many blocks made it. That count, swept over noise levels, is how 5G links are judged. And one in ten is the target the standard sets for choosing a data rate.

## S2 Concept: the whole chain (target 70 s)
[Screen] The chain labelled: transport block, coding, modulation, grid, waveform, noise, receiver, CRC.

ANI: This lecture uses pieces from earlier ones: low density parity check coding from lecture four, H A R Q retransmissions from lecture five, and channel estimation from lecture seven. As a reminder, H A R Q, hybrid automatic repeat request, means a failed block is sent again with different coded bits, and the receiver combines the attempts. Each attempt uses a redundancy version, or R V.

The song lists the transmit side in order: "Start with a transport block. N R DLSCH adds the checks, codes it, and rate matches it." A transport block is the chunk of data handed down for one slot. Its size in bits is the T B S. The receiver runs the chain backward and ends with a C R C check, which gives a simple pass or fail for each block.

## S3 Code beat B1: one slot, end to end (target 120 s)
[Screen] Demo section B1, the printed TBS and blkerr.

ANI: Before any sweep, one quiet slot has to pass. The carrier is fifteen kilohertz with fifty-two resource blocks. The shared data channel, P D S C H, uses P R B Set zero to twenty-three, Q P S K, symbols two through thirteen, and one layer. N R PDSCH Indices returns the indices and an info structure, and N R TBS sizes the block from the modulation, the layer count, the number of resource blocks, the resource elements per block, and a target code rate t c r of zero point four eight.

Worked example, for the first learning goal. Twelve symbols times twelve subcarriers is one hundred forty-four resource elements per block. The demodulation reference signal, D M R S, takes one full symbol, twelve, which leaves one hundred thirty-two. Times twenty-four blocks is three thousand one hundred sixty-eight resource elements. Q P S K carries two bits each, so the coded capacity G is six thousand three hundred thirty-six bits. Times the code rate zero point four eight, that's about three thousand forty bits of information, and the spec's size table rounds up to a T B S of three thousand one hundred four.

N R DLSCH encodes the block, N R PDSCH maps it, N R OFDM Modulate makes the waveform, and the script adds noise at twenty decibels. N R OFDM Demodulate, N R PDSCH Decode and N R DLSCH Decoder run it back. The assert requires blkerr to be false and the bits to match. If a wiring bug hides here, it would later look like a bad modulation choice. The final lecture, fifteen, turns this one-slot pass into an invariant.

## S4 Code beat B2: the S N R loop, two B L E Rs, and throughput (target 190 s)
[Screen] Demo section B2. Hold on the loop before it prints.

ANI: Now the loop. "Block error rate is the number of blocks that failed their CRC, divided by the number sent." B L E R for short. But there are two of them, and they answer different questions.

The first-transmission B L E R asks: did R V zero alone decode? The residual B L E R asks: is the block still failing after every H A R Q attempt you allowed? The demo tries up to four attempts, r v Seq zero, two, three, one. That's a conventional teaching order, not one the spec mandates. The residual can never be higher than the first-transmission B L E R, and the script asserts that.

Here's the title. "And here's why one in ten: the phone picks the highest channel quality index whose block error probability wouldn't go past one in ten," That target, from the spec's C Q I rules, is defined for a single transmission. So read the first-transmission curve against the zero point one line. The after-H A R Q curve sits to its left. The third C Q I table is the exception: it's a high reliability table that aims at one in a hundred thousand.

[PAUSE — self-check] Your residual B L E R crosses zero point one at four decibels. Is that the operating point the C Q I target describes?

ANI: No. The C Q I target describes the first transmission. Find where the first-transmission curve crosses zero point one, which will be at a higher S N R.

ANI: Throughput counts passed bits per slot actually used. n Tx goes up on every attempt, so retransmissions cost throughput. "Here's the invariant: throughput can never be more than the block size times the number of new blocks you sent." Per slot, throughput can't exceed the T B S, so the curve plateaus at three thousand one hundred four bits.

Worked example, for the second learning goal. Suppose that at one S N R, eighteen of twenty blocks pass and the loop used twenty-six slots. Throughput is eighteen times three thousand one hundred four, over twenty-six, about two thousand one hundred forty-nine bits per slot. Dividing by twenty would claim more than the link delivered.

[PAUSE — self-check] Why does the script divide passed bits by slots used, not by blocks sent?

ANI: A block can take up to four slots. Counting it once hides the cost of retransmission and overstates throughput at low S N R.

The S N R grid runs from zero to twelve decibels in steps of two, with twenty slots per point. After the loop, local Cross interpolates on a log B L E R axis to find where the first-transmission curve crosses zero point one.

Worked example, for the third learning goal. Say the first-transmission B L E R is zero point three at four decibels and zero point zero five at six. On a log axis, zero point one sits about sixty-one percent of the way between them, so the crossing is near five point two decibels. At a B L E R of zero point one, about nine blocks in ten finish in one slot.

[PAUSE — self-check] Before you run B2, write down the S N R where you expect the first-transmission curve to cross zero point one. Then compare it with the printed crossing.

ANI: Now the Try. Set r v Seq to zero, which means no retransmissions.

[PAUSE — self-check] With r v Seq at zero, which way does the after-H A R Q curve move?

ANI: It slides right, onto the first-transmission curve. With only one attempt, the two B L E Rs are the same thing.

## S5 Code beat B3: why one in ten, and how many blocks (target 90 s)
[Screen] Demo section B3, the printed block counts, and the nrCQITables glimpse.

ANI: B3 checks how much evidence the demo has. "and a common rule of thumb is around a hundred errors per point." It's a convention, not a law.

Worked example, for the fourth learning goal. At a B L E R of zero point one, a hundred errors needs a hundred over zero point one, a thousand blocks. "At one in a thousand, that means about a hundred thousand blocks." The demo runs twenty slots per point. At zero point one, that's about two errors, so the printed crossing shows the shape of the curve, not a measurement. Look at n Slots with that in mind.

Then the script calls N R C Q I Tables, available from release twenty twenty-four a, prints the property names, and displays the object. On an older release it prints a skip message, and the zero point one target still stands on the spec text.

## S6 Code beat B4: perfect versus practical (target 110 s)
[Screen] Demo section B4, two waterfalls on one axis.

ANI: The last beat asks a fair question. What if the receiver knew the channel exactly? The two receivers see the same noise. The perfect one uses the true channel, here H equals one, and the true noise variance. The practical one estimates the channel from noisy D M R S with N R Channel Estimate, then equalizes.

The only difference between the two is the estimator. Each S N R point and slot gets its own seed, one thousand times k plus s, and local Slot Pair runs both receivers on that same draw. B L E R here is after H A R Q for both, so compare the two curves with each other. Read the zero point one line as a reference, not as the C Q I operating point.

[PAUSE — self-check] Two receivers, same seed, same block. What is the only thing that differs between them?

ANI: The channel estimate. Noise now lives in the estimate as well as in the signal.

Worked example, for the fifth learning goal. The script prints both zero point one crossings from local Cross. If the practical crossing sits at or to the right of the perfect one, it says so. With only twenty slots, a short loop can invert the two. Then it prints that and skips the comparison. It never asserts a crossing, because twenty slots can't support one. The expected result is that the practical curve slides right, usually by a fraction of a decibel to a couple of decibels, depending on the estimator. Perfect knowledge is an upper bound on performance, not a result.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: One loop ties it all together, and one slot must pass before any sweep. The first-transmission B L E R is what the C Q I target aims at zero point one. H A R Q pushes the residual lower, and it costs slots, so count throughput per slot used. Aim for about a hundred errors per point, which is a thousand blocks at zero point one. And treat perfect channel knowledge as a bound. Next, in lecture twelve, we use the same signals to measure distance.

---
## Notes for Showrunner
- **Learning goals (5 of 5).** LG1: TBS 3104 (132 RE/PRB × 24 PRB = 3168 RE, G = 6336, Ninfo ≈ 3041 → 3040 → table 3104), computed by script from the 38.214 small-TBS rule. LG2: a hypothetical 18 of 20 blocks passing in 26 slots → 2149 bits/slot, labelled as an example in the speech. LG3: the log-axis crossing example (0.3 at 4 dB, 0.05 at 6 dB → 5.23 dB), the same rule `localCross` uses. LG4: 1000 and 100000 blocks (the demo prints these). LG5: B4's printed crossings, with no fixed number.
- **Assumptions to confirm on M's run.** The TBS value assumes `nrPDSCHConfig` defaults of one DM-RS symbol and two CDM groups without data (12 DM-RS REs per PRB). If your default differs, the printed TBS differs. The "fraction of a dB to a couple of dB" slide in S6 is a general expectation, not a demo number; cut it if you want no unsourced range.
- **B4 and F3.** The fixed demo's B4 compares the two receivers on after-HARQ BLER against a 0.1 line. The narration says so and calls that line a reference only, so it doesn't contradict the F3 fix in B2.
- **Lyric quotes.** All are verbatim and from the inventory's dry lines: L7, L29, L33–34, L35–36, L56 and L57. L37's "low latency" wording is not quoted; speech says "high reliability", per T11 SV S1. L52 (logged PG-13) and the hook are not quoted.
- **Terms.** U = 1 (first-transmission vs residual BLER) is defined in S4. HARQ, RV, TBS, CRC, PDSCH, DM-RS and BLER are glossed at first use.
- **Cross-references (new numbers).** Lecture four (LDPC), five (HARQ), seven (estimation), fifteen (invariant), and twelve next. These match the T11 DFMEA and the demo header.
