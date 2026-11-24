# Track 05 "Say It Again": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,663 (1,486 narration plus 177 read-aloud self-check questions). **Est. read time:** 11.1 min at 150 wpm, or about 12.3 min with about 10 s of silence at each of the 7 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 05):** min 7, typical 12, max 18 min. About at typical.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track05/track05_lyrics_prelim.md` (certified box, formerly T04), `lecture/track05/` demo_plan, demo.m, lecture_notes; `pedagogue/T05_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F1: starts from the failure (S2).
- F2: rate matching/RV and soft bits are defined (S2, S5).
- F3: the per-AdditionalPosition NREPerPRB/TBS prediction (S7).
- F4: the 3-step B3 skeleton (S5).
- F5: the SNR scan, assert, and warning, plus why-RV2 and Try pauses (S5).
- F6: the MCS 9/10 Try (S4).
- F8: the TBS estimate commit (S3), and the 'raise MCS on retx' pause (S6).

---
## S1 Cold open (target 30 s)
[Screen] Ani at the desk.

ANI: In lecture 04, a block arrived, the decoder worked hard, and the C R C said no. Today: what the sender does next. It doesn't start over. It sends the same block again, coded a little differently, and the receiver combines both tries. By the end you'll watch that combination rescue a block that failed on its own.

## S2 Concept: the transport block's path (target 140 s)
[Screen] A chain diagram: CRC, LDPC, rate match, scramble, modulate, map.

ANI: Start with the failure, because it explains everything else. A block that fails must be resent unchanged, so we need to know exactly what a block is and how big it is.

"A transport block is a bag of bits handed down from above." "First it gets a check: twenty-four bits of CRC if the block is long," "sixteen if it's short." The cut-off is three thousand eight hundred twenty-four bits. Then L D P C coding from lecture 04. Then rate matching: picking or repeating bits from the coded word's circular buffer, so the output is exactly the number of bits the grid can carry. A redundancy version is a starting point in that buffer. Then scrambling, then modulation onto the grid.

The downlink carries the result on the physical downlink shared channel, P D S C H. The uplink uses the uplink shared channel, P U S C H, and can switch on transform precoding to keep its peaks low.

Two jobs, often confused. Link adaptation chooses how hard to push: the modulation and code rate. H A R Q, hybrid automatic repeat request, resends the same block when it fails. Different jobs, different beats.

[PAUSE — self-check] Trace the chain from memory, in order, before the diagram finishes building.

ANI: C R C, L D P C coding, rate matching, scrambling, modulation, then mapping onto the shared channel. That's the first learning goal.

## S3 Code beat B1: size the block (target 130 s)
[Screen] Demo section B1.

ANI: "Ask N R TBS how big a block can be." "Give it the modulation, the layers, the resource blocks," "the resource elements per block, and the target code rate."

We don't guess the resource elements. The demo sets up twenty-four resource blocks, Q P S K, one layer, on symbols two to thirteen, and N R PDSCH Indices reports N R E Per P R B: how many resource elements per block are left for data. The demodulation reference signal has already taken its share. We'll see that cost directly in the last beat.

The transport block size isn't simply a table lookup. The specification computes an intermediate number of information bits from those inputs, quantizes it, and uses a table only for small sizes.

[PAUSE — self-check] Twelve symbols of twelve subcarriers, minus one full symbol of reference signal, leaves one hundred thirty-two resource elements per block. Estimate the block size: twenty-four blocks, Q P S K at two bits, rate point four eight. Write it down.

ANI: Worked example, for the second learning goal. Twenty-four times one hundred thirty-two is three thousand one hundred sixty-eight resource elements. Times two bits is six thousand three hundred thirty-six coded bits; that's G, what the rate matcher will emit. Times point four eight is about three thousand forty-one. N R TBS should land within a few percent of that, around three thousand one hundred. It's under three thousand eight hundred twenty-four, so the C R C is sixteen bits.

A common mistake: passing the bandwidth part size as the number of resource blocks instead of the allocation, or using twelve times fourteen and ignoring the reference signal.

## S4 Code beat B2: the MCS table (target 110 s)
[Screen] Demo section B2 table display.

ANI: "Pick the M C S index, and the table hands you two things:" "how many bits ride on each symbol, and what share of the bits is message." M C S is the modulation and coding scheme. Bits per symbol is called Q m. The share of message bits is the target code rate.

The demo loads N R PDSCH MCS Tables, takes the sixty-four Q A M table, and reads two rows. Index four is Q P S K at a rate of about point three. Index sixteen is sixteen Q A M at about point six four. Feed each into N R TBS on the same allocation, and the script asserts the higher row gives the larger block. Choosing the row is link adaptation, not retransmission.

[PAUSE — self-check] The Try line changes the rows to indices nine and ten, where Q P S K becomes sixteen Q A M. The modulation doubles. Does the block size double too? Check Q m times rate for both rows before you answer.

ANI: Worked example, for the third learning goal. Index nine is Q P S K, two bits, at a rate of about point six six: two times point six six is about one point three three. Index ten is sixteen Q A M, four bits, at about point three three: also about one point three three. The block size barely moves. The table is built so the step is smooth.

## S5 Animation A1 and code beat B3: retransmission (target 190 s)
[Screen] Animation A1, then demo section B3, then animation A2.

ANI: Here's the main event, in three steps: encode at one redundancy version, add noise, decode into the same buffer.

"Every block gets an answer: an ACK for yes, a NACK for no." "On a NACK the sender sends the same block again," "but it starts reading the coded bits from a different place," "a redundancy version, zero through three."

"The receiver never throws the first try away." "N R DLSCH Decoder keeps a soft buffer for every HARQ process". It stores the soft bits, the L L R values from lecture 04, and adds the new try's soft bits on top. That's soft combining. A H A R Q process is one block in flight with its own buffer. "While one block waits for its answer, another process can send the next," "up to thirty-two processes in the toolbox."

In the demo, N R DLSCH loads one block. We code it at version zero, map it onto the shared channel, add noise, and decode. Then we code version two of the same block and decode again into the same process.

The script doesn't leave this to luck. It scans a short list of signal-to-noise ratios on a fixed noise seed, and keeps the first one where version zero fails alone and versions zero plus two pass together. Then it asserts that outcome. If no level in the list works, you get a warning telling you to widen the list.

[PAUSE — self-check] Why does version two help, if it carries the same information bits?

ANI: It starts at a different point in the buffer, so it brings coded bits the first try didn't send, plus a second look at the ones it did. Combined, the decoder has more evidence. That's the fifth learning goal.

[PAUSE — self-check] The Try line sets the signal-to-noise list to just four decibels, then just minus four. Predict what you'll see in each case.

ANI: At four decibels, the first try already passes, so there's nothing to rescue. At minus four, even the pair fails. Either way the script prints a warning instead of the assert.

## S6 Code beat B4: what never changes (target 110 s)
[Screen] Demo section B4 printout.

ANI: "Here's what stays fixed: the transport block size never changes on a retransmission." "Only the version changes."

The demo checks something you could get wrong. It codes versions zero and two, asks the encoder for the block it's holding, and asserts that the block still equals the original. It asserts the two coded words differ. And it asserts the combined decode returned the original block. Then it shows a real change: the same allocation at rate point three gives a different size. That's a new block, not a retransmission.

[PAUSE — self-check] A colleague raises the M C S on the retransmission to get more data through. What's wrong with that?

ANI: A retransmission can't change the block. A new M C S would mean a new size, so it can't be combined with the first try. That covers the fourth learning goal: an answer per block, versions zero to three, a buffer per process, and a size that stays fixed.

"So why not always pick the highest index?" "On a noisy channel, a high index" "fails again and again, and every NACK costs another transmission." "A lower index can land the first time and move more data in the end." The phone reports what the channel can carry with a channel quality report. This demo doesn't measure that trade-off; the block error curves in lecture 11 do.

## S7 Code beat B5: reference signals (target 100 s)
[Screen] Demo section B5 printout and slot maps.

ANI: "How does the receiver read the grid at all?" "Demodulation reference signals ride inside the allocation." The demodulation reference signal, D M R S, is a set of known symbols the receiver uses to measure the channel. "In mapping type A the first one sits on symbol two or three of the slot," and you can add up to three more for a fast-changing channel. N R PDSCH DMRS Config holds those choices.

The demo steps the additional-position setting from zero to three. For each one it prints the reference symbol set and, this time, recomputes N R E Per P R B and the block size.

[PAUSE — self-check] Each extra reference symbol takes twelve resource elements from every block. Starting from one hundred thirty-two, predict N R E Per P R B for one, two and three extra symbols.

ANI: One hundred twenty, one hundred eight, and ninety-six. The block size falls with them, from about three thousand one hundred toward about two thousand two hundred. More pilots buy a better channel estimate and cost data. Lecture 07 estimates the channel from these symbols. The Try line shortens the grant to four symbols: watch how many extra positions still fit.

## S8 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four things to keep. N R TBS sizes the block from modulation, layers, resource blocks, resource elements per block, and code rate. The M C S row sets bits per symbol and code rate, and choosing it is link adaptation. A retransmission is a new redundancy version of the same block: the size is locked, and the decoder soft-combines both tries in one H A R Q buffer. And reference signals reserve resource elements, so more of them means a smaller block. Run the demo, find the level where version zero fails, and watch version two rescue it.

---
## Notes for Showrunner
- The TBS ≈3104 and the AdditionalPosition 0–3 NREPerPRB values (132/120/108/96) come from FIXES static estimates and are spoken as 'about'.
- The MCS 4/9/10/16 rates come from TS 38.214 Table 5.1.3.1-1 from memory; check them against the printed rows.
- 'Up to thirty-two processes' is quoted from certified L40.
- Resolved (Showrunner, 2026-11-18): the demo header now names lecture 04 'Every Check Agrees', and the B2 empty-row fallback was replaced by an assert.
- None of these were changed by me.
