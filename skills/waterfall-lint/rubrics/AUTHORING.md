# Writing a waterfall-lint rubric

A rubric is a brief template: the file the operator copies, fills, and hands to every critic in a run. Write one per ARTIFACT CLASS plus AUDIENCE, never per document. If two document types share a reader and an evidentiary bar, they share a rubric; the per-run differences live in the placeholder fields and the receipts, not in a new file.

The three shipped rubrics (client-report, paper, site-launch) are the reference implementations. Copy the closest one and edit. Every rubric must keep these blocks, because the loop depends on them:

1. **Reader framing, first paragraph.** Who reads the artifact and what it costs when a defect reaches them. This is the single highest-leverage sentence in the file: critics calibrate severity to the reader you describe, not to an abstract quality bar. Name the reader's evidentiary bar explicitly ("will falsify the report from its own pages before trusting the sender").

2. **Accepted warts block** with the `{{WART-LEDGER}}` placeholder. Instruct critics not to re-flag, and give them the escape valve: a one-line "wart escalation" if they believe an accepted wart is underweighted. Without the valve, critics either violate the instruction or silently swallow a real severity signal.

3. **Already-refuted block** with the `{{REFUTED-LEDGER}}` placeholder. Keep it separate from warts and say why: warts are real defects the operator accepted; refutations are findings that were never real. The reasoning that produces a refuted finding is plausible, which is exactly why it recurs across critics and needs its own do-not-flag list.

4. **Prior-passes block** with the `{{PRIOR-SUMMARY}}` placeholder. Counts only, never critique text. State the reason in the rubric itself so critics understand the constraint instead of working around it: the artifact was regenerated after each pass, so an earlier critique describes text that no longer exists.

5. **A forced first finding.** Ask for THE single worst defect by name (the credibility break, the desk-reject trigger, the bounce trigger) before the general defect list. Forcing a ranked first pick prevents the flat, unprioritized laundry list.

6. **A one-word verdict.** KEEP/CUT, Submit/Hold, Launch/Hold. Not because the loop uses it to decide (receipts decide), but because forcing a verdict keeps the critic honest about severity: a critic who lists ten BLOCKERs and says KEEP has mislabeled something.

7. **Defect classes to check, none mandatory to find.** List the failure modes this artifact class is prone to. The "none mandatory" clause matters: without it, critics invent findings to fill the categories. Close with the anti-padding line: "if the artifact is clean beyond X, say so."

8. **Exact-quote discipline.** Every finding carries an exact quote from the artifact; a finding that cannot be quoted may not be reported. This is what makes the fact-check gate mechanical.

9. **The fact-check warning.** Tell critics their findings will be verified against receipts before any fix, and that a refuted finding costs them credibility. Ask for explicit uncertainty ("when unsure whether the page or your inference is wrong, report the uncertainty") instead of confident guesses.

Things that do NOT belong in a rubric:

- Facts about a specific document or run (put them in the placeholder fields).
- Semantic style rules you intend to lint later (semantic qualities cannot be linted; see the class-fix caution in SKILL.md).
- Output-format structure beyond what the loop parses (defect + tag + quote). Elaborate section scaffolding produces padded critiques.
