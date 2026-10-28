# Referee protocol

The referee answers one question for one attempt: did an observation reproduce the target crash? It sees
evidence, not the attempt's story. [rules.md](rules.md) is the knowledge; this file is the contract.

## Independence and blindness

Use a fresh subagent that has not seen the run's analysis, test or hypothesis, and give it files, not a
summary. If only the current context can referee, follow the fallback in `SKILL.md`: write the evidence to
files, start a new step, read only those files, write `independence: single-context`, and do not revise
the verdict after reading the test source or the analysis. The report says the verdict is not
independently verified.

The referee reads:

- `crash.json`: the target evidence.
- `attempts/NN/observed.json`: the observations, written by the reader, never by the reproducer.
- `references/rules.md`: the rulebook, levels and tie-break.
- `attempts/NN/manifest.json`: context only (test path, test command, raw paths). It is not evidence.
- `raw/`: the raw test output, only to settle an ambiguous frame.

It does not read `analysis.json`, the test source, the reproducer's notes, `report.md`, `guide.md`, another
attempt's verdict, or a benchmark's expected answers. A note that says "this must be it" is not evidence.
A test path in the manifest does not make a test frame an app frame.

## What counts as evidence

`observed` means the skill ran the command and saw the crash. `supplied` means the crash came from a file
the skill was given: it is evidence of a crash, not of a device run, and the report says so. The target's
own crash is not an observation: drop an observation with the same event id, source path or logcat entry
as `crash.json` (R2). If every observation is dropped as the reported crash itself, the verdict is
`NOT_REPRODUCED`, not `NO_VERDICT`. A readable `observed.json` with an empty `observations` array is a
completed run that saw no crash: `NOT_REPRODUCED`, not `NO_VERDICT`. A missing or unreadable file is the
orchestrator's `NO_VERDICT`.

The verdict uses the crash group only: exception type and location. Breadcrumbs, logs, custom keys, tags,
contexts and device data never replace a missing type or frame. The one documented exception is R9: an
`NSError`'s domain and code may come from `custom_keys.error_domain` or its message.

## Procedure

1. Read the target's exception chain (outermost first), the root exception, its type, message, signal and
   frames (innermost first). Name the blame frame: the first `in_app` frame of the root exception, with the
   format fallbacks. Test frames are not app frames (R1).
2. Drop the reported crash itself (R2).
3. For each remaining observation, find the type match (R4, R6–R10) and the place match (R1, R3, R5, R13).
   R7 also requires the same message at the same bundle position, and R11 treats an obfuscated name as
   build-scoped.
4. Choose the best observation: most matching app frames in order, then exact over drifted, then message
   match. One matching observation is enough.
5. Set the level (R14) and apply the tie-break in `rules.md`. When rules conflict, the lower verdict wins.
6. Write `verdict/NN.json`. If no observation survives, `NOT_REPRODUCED` with the reason.
7. If the orchestrator says the file is malformed, redo it once; never replace the verdict with
   `NO_VERDICT`.

## Verdict file

One UTF-8 JSON object. Field names and types are in [schemas.md](schemas.md#verdictjson).

```json
{
  "schema": "reproduce/verdict@2",
  "status": "REPRODUCED",
  "level": "blame-frame",
  "independence": "subagent",
  "best": {
    "source": "attempts/01/observed.json",
    "matched_type": "java.lang.IllegalStateException",
    "location": "exact",
    "matched_frames": 1,
    "line_delta": 0,
    "message_match": true
  },
  "observations": [],
  "rules": ["R14"],
  "reasons": [
    "type matches: java.lang.IllegalStateException in both",
    "location matches: com.example.Feature.load (Feature.kt:42)"
  ]
}
```

- `status`: `REPRODUCED`, `PARTIAL` or `NOT_REPRODUCED`. The referee never writes `NO_VERDICT`.
- `level`: one of `blame-frame`, `call-path`, `system-frames`, `recursion`, `type-and-message`; empty for
  `PARTIAL` and `NOT_REPRODUCED`.
- `independence`: `subagent` or `single-context`.
- `best`: required for `REPRODUCED` and `PARTIAL`. `source` names the observation file. `matched_type` is
  the observed type that matched (empty when only the place matched). `location` is `exact`, `function`,
  `file-line`, `system`, `recursion` or `none`; `none` is for `type-and-message` and for a `PARTIAL` whose
  only match is the type (`level: ""`, no matched place). `matched_frames` counts app frames that match in
  order (test frames excluded).
  `line_delta` is observed line minus target line. `message_match` says whether app messages match after
  R10.
- `rules`: the rule IDs that decided, e.g. `["R3", "R14"]`. Non-empty for `REPRODUCED`.
- `reasons`: one non-empty line per deciding fact. Cite the type and the location for `REPRODUCED`; for
  `type-and-message`, cite the type and message.
- `observations`: optional per-observation detail; keep the same evidence.

For `PARTIAL`, `best` records the half that matched and the reasons say which half did not. For
`NOT_REPRODUCED`, `best` may be omitted when no observation was usable; otherwise record the closest
non-match. The verdict is a judgment: say what was compared, not what the test meant to do.

## Cite rule

A `REPRODUCED` verdict is malformed unless `reasons` names a matching exception type and a matching
location, and `best.matched_type` and `level` are non-empty. The exception is `type-and-message` (R12):
there is no stack, so the citation is the matching type and message, with `best.location: none` and
`best.message_match: true`. A location is a symbol and file (with line drift allowed by R3), a bundle
position (R7), a repeated cycle (R5, R13) or a system frame. "The stack looks the same" is not a citation.
A `PARTIAL` names the one half that matched (a type-only `PARTIAL` has `best.location: none` and no
matching place); a `NOT_REPRODUCED` says why no observation placed the crash.

## Conservative tie-break

`NOT_REPRODUCED` < `PARTIAL` < `REPRODUCED`. A wrong `REPRODUCED` is worse than a miss: when the evidence
is insufficient or two rules conflict, choose the lower verdict. Type and place both match for
`REPRODUCED`; exactly one matches for `PARTIAL`; neither for `NOT_REPRODUCED`. The caps in `rules.md`
apply: a generic build-tool wrapper with no matching place is `NOT_REPRODUCED` (R4); a place that is only
test code is at most `PARTIAL` (R1); a self-observation is not evidence (R2); the best observation decides
when several exist.

## Malformed verdicts

A verdict is malformed when the file is not one UTF-8 JSON object; `status` is missing or not one of the
three; the referee writes `NO_VERDICT`; a `REPRODUCED` has no level, no `best.matched_type`, no cited type
and location (except `type-and-message`: the citation is type + message, `best.location: none`,
`best.message_match: true`), or an empty `rules`; `reasons` is empty; or the verdict names an attempt or
case that is not in the input.

The orchestrator checks the file. On the first malformed verdict it asks the same referee once for a redo,
naming the defect and the exact file; the evidence does not change. If the second file is still malformed,
the orchestrator writes `NO_VERDICT` with `verdict stayed malformed` and the report says so. The
orchestrator never edits a verdict, upgrades it, softens it or writes a different status in its place.

## NO_VERDICT

`NO_VERDICT` belongs to the orchestrator, never to the referee. It is written only when no test ran, the
build failed before any test, `observed.json` is missing or unreadable, or the verdict stayed malformed
after one redo. The reason names which. A readable `observed.json` with an empty `observations` array is a
completed run that saw no crash: `NOT_REPRODUCED`, not `NO_VERDICT`. A self-observation is also a
`NOT_REPRODUCED` judgment.

## No self-grading

The reproducer may not write, edit or "clean" `observed.json` or the raw output. If the observed file
changed after the run, say so and decide from the raw output; if the raw output does not support the
observation, the observation is not evidence. The referee may read raw output, never edit it. The referee
does not ask the reproducer what happened: the files are the record.
