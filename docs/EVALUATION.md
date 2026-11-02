# Evaluation

What the public repository checks, what the real runs show, and what stays private. The point is to make
the evidence behind the skill inspectable without publishing private case ids or expected answers.

## Public checks

[`scripts/e2e-clean.sh`](../scripts/e2e-clean.sh) extracts a clean copy, installs the skill into a temporary
skills directory and checks:

- `SKILL.md` exists, has `name: reproduce` and a non-empty `description` under 1,024 bytes;
- `SKILL.md` is under 12 KB and every reference under 10 KB;
- every relative Markdown link resolves;
- the installed skill contains only Markdown;
- no absolute home path, `TODO`, `FIXME` or private benchmark vocabulary.

[`.github/workflows/smoke.yml`](../.github/workflows/smoke.yml) runs that check on every push and pull
request. It is a structural gate: it does not run a model, a device or a crash report.

## Real-run evidence

The evaluation entry in [`CHANGELOG.md`](../CHANGELOG.md) records 19 real crash scenarios across four apps.
Each run has a run folder, a raw observation and a blind-referee verdict; all 19 returned `REPRODUCED`.
One iOS null-text case uses the Sentry report of the same bug because the Crashlytics event carries only
the React Native error-handler frame, not the JS throw frame; the run records that choice instead of
inventing the missing frame.

This is positive evidence that the workflow runs on real reports. It is not a false-positive rate, a
trigger-rate measurement or a model comparison; those need negative and adversarial cases.

## Referee benchmark (private)

The private `reproduce-dev` repository keeps a frozen 33-case referee benchmark, the schema/static checkers,
the scorer and the unit tests. They are maintainer material, not shipped with the skill.

A rulebook change is expected to come with a before/after benchmark run, and a change that claims a new
verdict must also carry the false positive it must reject ([CONTRIBUTING.md](../CONTRIBUTING.md)). The
public repository does not include the cases, ids or expected answers, and the public smoke check does not
run the benchmark.

## Negative cases the rulebook must reject

These are the cases the referee rules are built to stop. Each maps to a rule in
[`rules.md`](../skills/reproduce/references/rules.md):

- a test that throws the exception itself, not the app (R1);
- the reported crash used as its own observation (R2);
- a generic build-tool wrapper with no matching app place (R4);
- test-only frames counted as app frames (R1);
- another build's obfuscated names used to promote a verdict (R11);
- a stack overflow placed by depth or entry point instead of its repeated cycle (R5, R13).

## What is not public

- The 33 benchmark cases and their expected verdicts.
- The model-by-model trigger and workflow matrix.
- Device-run videos and run folders from private apps.

If you run the skill on an agent or model that is not covered above, record what you ran and what happened
in the pull request or in an issue. A reproducible failure is more useful than a compatibility claim.
