#!/bin/sh
# Public smoke check: a clean checkout installs the Markdown-only skill.
#
#   scripts/e2e-clean.sh              # test the committed tree (HEAD)
#   scripts/e2e-clean.sh <ref>        # test another commit/tag
#   scripts/e2e-clean.sh --worktree   # test the current files, including uncommitted ones
#
# It extracts a fresh copy, installs the skill with the installer, checks
# the installed SKILL.md, its description, the 12 KB/10 KB limits and relative links,
# and enforces the Markdown-only rule. It needs no device and no network.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO=$(dirname -- "$SCRIPT_DIR")
MODE=archive
REF=HEAD

case "${1:-}" in
    --worktree) MODE=worktree; shift ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

sh scripts/install-skill.sh --skills-dir "$WORK/skills" > "$WORK/install.log" || { cat "$WORK/install.log"; fail "install"; }
cat "$WORK/install.log"

SKILL="$WORK/skills/reproduce"
[ -f "$SKILL/SKILL.md" ] || fail "installed copy has no SKILL.md"
grep -q '^name: reproduce$' "$SKILL/SKILL.md" || fail "installed SKILL.md has no name: reproduce"

DESC=$(sed -n 's/^description: //p' "$SKILL/SKILL.md" | head -n 1)
[ -n "$DESC" ] || fail "installed SKILL.md has no description"
DESC_SIZE=$(printf '%s' "$DESC" | wc -c | tr -d ' ')
[ "$DESC_SIZE" -lt 1024 ] || fail "SKILL.md description is $DESC_SIZE bytes; keep it under 1024"

NOT_MD=$(find "$SKILL" -type f ! -name '*.md' ! -name '.DS_Store' ! -name '.gitkeep' | wc -l | tr -d ' ')
if [ "$NOT_MD" != "0" ]; then
    find "$SKILL" -type f ! -name '*.md' ! -name '.DS_Store' ! -name '.gitkeep'
    fail "$NOT_MD non-Markdown files in the installed skill; the skill must stay Markdown-only"
fi

# Size limits: SKILL.md under 12 KB; every reference under 10 KB.
SKILL_SIZE=$(wc -c < "$SKILL/SKILL.md" | tr -d ' ')
[ "$SKILL_SIZE" -lt 12288 ] || fail "SKILL.md is $SKILL_SIZE bytes; keep it under 12 KB"

BIG=$WORK/big-references
: > "$BIG"
for f in $(find "$SKILL" -name '*.md' ! -name 'SKILL.md'); do
    SIZE=$(wc -c < "$f" | tr -d ' ')
    [ "$SIZE" -lt 10240 ] || printf '%s %s\n' "$SIZE" "$f" >> "$BIG"
done
if [ -s "$BIG" ]; then cat "$BIG"; fail "references over 10 KB"; fi

# No absolute home path and no TODO marker in the product.
if grep -rn -e '/Users/' -e '/home/' -e 'TODO' -e 'FIXME' "$SKILL" > "$WORK/forbidden"; then
    cat "$WORK/forbidden"; fail "absolute path or TODO marker in the skill"
fi

# Relative Markdown links resolve.
BADLINKS=$WORK/bad-links
: > "$BADLINKS"
for f in $(find . -name '*.md'); do
    DIR=$(dirname "$f")
    grep -o '](\([^)]*\))' "$f" | sed 's/^](//; s/)$//' | while IFS= read -r TARGET; do
        case "$TARGET" in
            http*|mailto:*|'#'*|*'<'*|*' '*|"") continue ;;
        esac
        PATH_ONLY=${TARGET%%#*}
        [ -e "$DIR/$PATH_ONLY" ] || printf '%s -> %s\n' "$f" "$TARGET" >> "$BADLINKS"
    done
done
if [ -s "$BADLINKS" ]; then cat "$BADLINKS"; fail "relative links do not resolve"; fi

printf 'PASS: clean %s installs; SKILL.md and description present; sizes, links and Markdown-only rules pass (no Go, no device, no network)\n' "$LABEL"
