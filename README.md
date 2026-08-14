# Waterfall Lint

A Claude Code skill that scrubs a finished artifact until AI critics run dry. Critics from different model families review the artifact one at a time; every finding is fact-checked against ground truth before any fix ships; confirmed defects are fixed at class level (a validator, lint, or test, not just the one instance); and the loop stops after two consecutive passes find nothing new.

For artifacts where shipping a defect costs credibility with a real reader: a client-facing report, a working paper about to be submitted, a marketing site going live.

Sibling of [critic-gauntlet](https://github.com/alexmakarski/critic-gauntlet). The split is verdict versus scrub: the gauntlet runs critics in parallel and delivers a one-shot independent judgment (ship / don't ship); waterfall-lint runs them sequentially with fixes between passes and removes every findable defect. If you need to decide whether a thing should ship at all, use the gauntlet. If you are going to fix everything findable anyway, use this.

## The problem it solves

One review pass by one model gives you one model's blind spots, once. Running five models in parallel on an artifact you intend to fix is wasteful in a subtler way: they all find the same top defects, you pay five critics for one pass's worth of signal, and after you fix, nobody has reviewed the fixed version.

The waterfall fixes both:

1. **Sequential passes over a changing artifact.** Each critic reads the current state, including every verified fix so far. Its attention goes to the residue, not to re-finding the defect the last critic already caught. In the production runs that shaped this skill, confirmed-defect counts across three passes went 20, then 8, then 33: the third critic read with a different lens and found in bulk what the first two were blind to. A parallel run would have bought none of that.
2. **Receipts decide, not votes.** Every finding is verified against ground truth (the raw data, the cited source, the rendered page) before any fix. Critics are confidently wrong often enough that this gate is the whole safety story: on one real run, a critic asserted the same false claim two passes running, and the first "fix" made the artifact worse by obeying it.
3. **Class-level fixes.** A confirmed defect is fixed twice: the instance, and then the class, as a deterministic validator, lint, or test wherever one can be expressed. Later artifacts arrive cleaner, passes go dry sooner, and the loop cheapens itself toward a plain validator suite.
4. **Ledgers instead of shared context.** Accepted warts (real defects the operator chose to live with) and refuted findings (claims the receipts disproved) travel to every later critic as one-line ledgers inside the brief. Nothing else crosses a pass boundary: a prior critique describes text that no longer exists, and feeding it forward measurably contaminates the next critic. On one measured pass, 5 of a critic's 14 findings quoted the previous draft instead of the artifact in front of it.

## How it works

You put the artifact (as the reader sees it) and a filled brief template in a work folder. Then, per pass:

1. Run mechanical checks first (pass 0): tests, validators, link crawls, reference checks. Critics are never paid to find a missing meta description.
2. One critic reads brief + artifact and returns falsifiable defects, each with an exact quote and a BLOCKER / SHOULD / NICE tag.
3. Every finding is fact-checked against receipts: CONFIRMED (fix it), REFUTED (log the receipt, add to the refuted ledger), or WART-CANDIDATE (queue for the human; the loop never accepts a wart on its own).
4. Confirmed defects get fixed at class level, the fix is verified, the artifact snapshot is refreshed.
5. The next critic gets the updated artifact and the updated ledgers.

Stop after two consecutive dry passes, with one honesty clause: dryness measures the critic you just ran, not the artifact, so don't stop while an unrun critic still offers a lens the run hasn't seen. Full protocol in [SKILL.md](skills/waterfall-lint/SKILL.md); a worked run in [the example](skills/waterfall-lint/examples/worked-example.md).

## The roster

| Critic | Requires | Lens |
| --- | --- | --- |
| Codex CLI | `codex` CLI installed + authed | Specification bugs. Strongest single finder in the runs that shaped this skill; runs first. |
| DeepSeek | `DEEPSEEK_API_KEY` | Arithmetic reconciliation, misattribution. Found confirmed defects after three Codex passes went quiet. |
| Claude subagent | Claude Code only | Operational nuance, cross-document contradiction. No API key needed. |
| Grok | `XAI_API_KEY` | Privacy / policy / jurisdictional angles. Higher noise. |
| Gemini | `GEMINI_API_KEY` | Distribution blind spots. Highest noise. |

Only the Claude subagent needs no extra setup. Run the subset you have credentials for; the stopping rule usually ends the loop before the roster is exhausted anyway. Lens diversity is what matters: two critics from different families beat three from the same one.

All critics run least-privilege. The Claude critic is a dedicated agent (ships in [agents/gauntlet-critic.md](agents/gauntlet-critic.md)) holding only `Read, Grep, Glob, Write`: no shell, no git, no external services. Codex runs `--sandbox read-only`. This is a hard rule inherited from a real incident in which full-toolbelt critics edited documents, pushed commits, and filed tickets nobody asked for. A critic that "helpfully" fixes the artifact mid-loop also destroys the thing the next pass is supposed to measure.

## Install

**As a plugin (recommended).** Inside Claude Code:

```
/plugin marketplace add alexmakarski/waterfall-lint
/plugin install waterfall-lint@waterfall-lint
```

**Manual.** Clone and run the installer, which copies the skill and the critic agent into your Claude Code directories:

```bash
git clone https://github.com/alexmakarski/waterfall-lint.git
cd waterfall-lint && ./install-waterfall-lint.sh
```

Either way it is available to Claude Code as the `waterfall-lint` skill.

## Setup

The baseline (Claude subagent only) needs nothing. Optional critics:

**Codex CLI:** install and authenticate the [`codex` CLI](https://github.com/openai/codex). The skill calls `codex exec --sandbox read-only`.

**Grok:** [xAI API key](https://x.ai/api), `export XAI_API_KEY=...`

**Gemini:** [Google AI Studio API key](https://ai.google.dev/), `export GEMINI_API_KEY=...`

**DeepSeek:** [Fireworks API key](https://fireworks.ai) (default endpoint) or a first-party key, `export DEEPSEEK_API_KEY=...`

Data-sovereignty note: the DeepSeek default endpoint is Fireworks, a US host serving the open weights, so the forgot-to-configure failure mode is an error, not silent egress. DeepSeek's first-party API is PRC-hosted; opt into it with `DEEPSEEK_BASE_URL=https://api.deepseek.com/v1` and `DEEPSEEK_MODEL=deepseek-v4-pro`. Any OpenAI-compatible endpoint works, including self-hosted vLLM, and each critique records which endpoint produced it.

The helper scripts resolve keys from the environment first, then a `.env` file in the skill folder or your home directory, then common shell rc files. See [.env.example](skills/waterfall-lint/.env.example). Other dependencies: `bash`, `curl`, [`jq`](https://jqlang.github.io/jq/).

Model pins sit at the top of each script and can be overridden per run (`GROK_MODEL=...`, `GEMINI_MODEL=...`, `DEEPSEEK_MODEL=...`). Update them when providers ship newer flagships.

## What goes to third-party APIs

The Grok, Gemini, and DeepSeek critics send the brief and the artifact text to their vendors. Text already written to be shown to its reader is fine; never send raw source data containing anything the artifact itself would not disclose. For research artifacts, the paper rubric's binding rule: external API critics see only the anonymized paper and its stated public sources.

## Rubrics

A rubric is a brief template per artifact class plus audience, not per document. Shipped:

- **client-report**: client-facing intelligence and analytics reports; reader is a skeptical operator who will falsify the report from its own pages.
- **paper**: working papers pre-submission; reader is a referee looking for a reason to desk-reject.
- **site-launch**: a public marketing site going live; readers are a skeptical buyer and a lawyer for any company the site names.

Writing your own: [rubrics/AUTHORING.md](skills/waterfall-lint/rubrics/AUTHORING.md).

## When to use it, and when not to

**Use it on** finished artifacts headed for a real reader whose trust you cannot re-earn cheaply, when you are going to fix everything findable anyway.

**Do not use it on** proposals, architectures, or strategies (that is a verdict, use [critic-gauntlet](https://github.com/alexmakarski/critic-gauntlet)), on drafts still finding their shape (the fixes will be overwritten), or on low-stakes artifacts (the fix-and-verify cycle per pass is the real cost, and it is a human cost).

## Cost

API critics run cents per pass; Codex and Claude are covered by their subscriptions. The real cost is your fix-and-verify cycle between passes: a full run with real fixes is a working session or an overnight loop.

## License

MIT. See [LICENSE](LICENSE).
