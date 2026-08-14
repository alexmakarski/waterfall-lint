# Waterfall-lint QA brief: {{CLIENT}} {{REPORT-SET}} pass {{N}}

You are reviewing a marketing-intelligence report that an agency ({{AGENCY}}) intends to send to a skeptical prospective client: {{READER-DESCRIPTION: who they are, their vertical, their competitors, their evidentiary bar}}.

Assume the reader applies a higher evidentiary and compliance bar than a general marketer, and will try to falsify the report from its own pages before trusting the sender. The report's own appendix and receipts are ground truth: a claim the report's own data contradicts is the highest-severity defect class.

## Accepted warts (do NOT re-flag)

The following findings were already reviewed and consciously accepted by the operator. Re-flagging them wastes a pass. If you believe an accepted wart is more severe than its acceptance note implies, say so in one line under "Wart escalations" instead of listing it as a defect.

{{WART-LEDGER: paste warts.md content verbatim, or "None yet."}}

## Already refuted by receipts (do NOT re-flag)

Different from an accepted wart: these are not real defects. A previous critic reported each one, and the raw source data showed the report was right and the critic was wrong. The reasoning that produces them is plausible, which is why they recur. If you think a refutation is itself wrong, say so in one line and name the receipt you would check, but do not list it as a defect.

{{REFUTED-LEDGER: one line per refuted finding: the claim, and the receipt that refutes it. Or "None yet."}}

## Prior passes

You are seeing only the counts below, never the earlier critiques themselves. The artifact was regenerated after each pass, so an earlier critique describes text that no longer exists, and quoting it would produce findings against a page nobody can read.

{{PRIOR-SUMMARY: one line per prior pass: critic, N confirmed defects, N refuted. Or "This is pass 1."}}

## Your job, for THE ONE REPORT provided below

1. THE CREDIBILITY BREAK: identify the single statement or presentation most likely to make this reader distrust the report. An overclaim, a claim the report's own data contradicts, a causal assertion the method cannot support, or a classification artifact visible on the page. Quote it exactly.
2. KEEP OR CUT: would you include this report in a first outreach package to this prospect? Answer with the single word KEEP or the single word CUT, then a one-sentence justification: does it earn the call, or does it read as automated padding?
3. Additional falsifiable defects, each with an exact quote and a BLOCKER / SHOULD / NICE tag, in descending severity. Common classes to check, none of them mandatory to find: internal arithmetic that does not reconcile; metrics used without definition; risk or negative language attributed to the brand that the quoted source aims at the category or a different entity; tautological wins (brand-name queries "won" against competitors who were never candidates); causal language on correlational method; absolute claims the report's own tables contradict; counts that differ between hero, body, and appendix.
4. Wart escalations (optional, one line each): accepted warts you believe are underweighted.

Do not pad: if the report is clean beyond the credibility break, say so.

Be specific and adversarial. Quote exactly. Do not invent content that is not in the text. Findings you report will be fact-checked against the raw receipts before any fix ships; a finding refuted by receipts costs credibility, so when unsure whether the page or your inference is wrong, report the uncertainty explicitly.

The report text follows.
