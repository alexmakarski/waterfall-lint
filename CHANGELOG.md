# Changelog

## 1.0.0 (2026-08-14)

First public release. Extracted from an internal skill (lineage: internal v1.7.0) that ran production QA on client-facing intelligence reports, working papers, and site launches through July-August 2026.

Differences from the internal lineage:

- Internal run names, client names, and operator-specific policy removed; the measured lessons (contamination numbers, defect-count sequences, the extractor-skipped-SVG incident) are kept with genericized provenance.
- Rubrics shipped: `client-report` (renamed from an internal report brand), `paper`, `site-launch`, plus `rubrics/AUTHORING.md`. Two internal product-specific rubrics were not ported.
- Scripts default to `--mode qa` (the only mode this skill ships) instead of `architecture`.
- The `gauntlet-critic` least-privilege agent definition now ships in `agents/` instead of being assumed present.
