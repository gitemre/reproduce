#!/bin/sh
# Public smoke check: a clean checkout installs the Markdown-only skill.
#
#   scripts/e2e-clean.sh              # test the committed tree (HEAD)
#   scripts/e2e-clean.sh <ref>        # test another commit/tag
#   scripts/e2e-clean.sh --worktree   # test the current files, including uncommitted ones
#
# It extracts a fresh copy, installs the skill with the binary-free installer,
# checks the installed SKILL.md, and enforces the no-code rule: the skill ships
# no Python or Swift source. It needs no Go, no device, no network and no
# maintainer benchmark. The full benchmark and unit tests live in the private
# reproduce-dev repository.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO=$(dirname -- "$SCRIPT_DIR")
MODE=archive
REF=HEAD

case "${1:-}" in
    --worktree) MODE=worktree; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
[ $# -eq 0 ] || REF=$1

TMP=${TMPDIR:-/tmp}
WORK=$(mktemp -d "$TMP/reproduce-e2e.XXXXXX")
trap 'rm -rf "$WORK"' EXIT INT TERM
SRC="$WORK/src"
mkdir -p "$SRC"

if [ "$MODE" = worktree ]; then
    tar -C "$REPO" --exclude=.git --exclude=__pycache__ --exclude=.reproduce -cf - . | tar -x -C "$SRC"
    LABEL="worktree"
else
    git -C "$REPO" archive "$REF" | tar -x -C "$SRC"
    LABEL="$REF"
fi

cd "$SRC"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

GO=$(find . -name '*.go' -not -path './.git/*' | wc -l | tr -d ' ')
[ "$GO" = "0" ] || fail "$GO Go files in the clean copy"

sh scripts/install-skill.sh --skills-dir "$WORK/skills" > "$WORK/install.log" || { cat "$WORK/install.log"; fail "install"; }
cat "$WORK/install.log"

SKILL="$WORK/skills/reproduce"
[ -f "$SKILL/SKILL.md" ] || fail "installed copy has no SKILL.md"
grep -q '^name: reproduce$' "$SKILL/SKILL.md" || fail "installed SKILL.md has no name: reproduce"

CODE=$(find "$SKILL" \( -name '*.py' -o -name '*.swift' -o -name '*.kt' \) | wc -l | tr -d ' ')
[ "$CODE" = "0" ] || fail "$CODE code files in the installed skill; the skill must stay Markdown-only"

printf 'PASS: clean %s installs; SKILL.md present; no bundled code (no Go, no device, no network)\n' "$LABEL"
