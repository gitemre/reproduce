#!/bin/sh
# Install the reproduce skill into an agent's skills folder. The skill is the
# product.
#
#   scripts/install-skill.sh                     # ~/.claude/skills and ~/.agents/skills
#   scripts/install-skill.sh --agent claude      # one agent
#   scripts/install-skill.sh --project           # ./.claude/skills and ./.agents/skills
#   scripts/install-skill.sh --skills-dir PATH   # PATH/reproduce
#   scripts/install-skill.sh --uninstall ...     # remove the installed copy
#
# The default also refreshes an existing copy in ~/.gemini/config/skills and
# ~/.config/opencode/skills. The copy replaces an older one atomically. Run it
# again after every update.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(dirname -- "$SCRIPT_DIR")
SOURCE="$REPO_ROOT/skills/reproduce"

usage() {
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
    printf 'install-skill: %s\n' "$*" >&2
    exit 1
}

[ -f "$SOURCE/SKILL.md" ] || die "cannot find $SOURCE/SKILL.md; run this from a checkout"

mode=default
agent=
skills_dir=
project=0
uninstall=0

while [ $# -gt 0 ]; do
    case "$1" in
        --agent)
            [ $# -ge 2 ] && [ -n "$2" ] || die "--agent needs a name"
            agent=$2
            shift 2
            ;;
        --agent=*)
            [ -n "${1#*=}" ] || die "--agent needs a name"
            agent=${1#*=}
            shift
            ;;
        --skills-dir)
            [ $# -ge 2 ] && [ -n "$2" ] || die "--skills-dir needs a path"
            skills_dir=$2
            shift 2
            ;;
        --skills-dir=*)
            [ -n "${1#*=}" ] || die "--skills-dir needs a path"
            skills_dir=${1#*=}
            shift
            ;;
        --project)
            project=1
            shift
            ;;
        --uninstall)
            uninstall=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1 (see --help)"
            ;;
    esac
done

chosen=0
[ -n "$agent" ] && chosen=$((chosen + 1))
[ -n "$skills_dir" ] && chosen=$((chosen + 1))
[ "$project" -eq 1 ] && chosen=$((chosen + 1))
[ "$chosen" -le 1 ] || die "choose one of --agent, --skills-dir or --project"

staging=
backup=

cleanup() {
    [ -z "$staging" ] || rm -rf "$staging"
    [ -z "$backup" ] || rm -rf "$backup"
}
trap cleanup EXIT INT TERM

install_to() {
    parent=$1
    [ -n "$parent" ] || die "empty target folder"
    grep -q '^name: reproduce$' "$SOURCE/SKILL.md" || die "source SKILL.md has no name: reproduce"
    mkdir -p "$parent" || die "cannot create $parent"
    dest="$parent/reproduce"
    staging="$parent/.reproduce-install.$$"
    backup="$parent/.reproduce-backup.$$"
    rm -rf "$staging" "$backup"
    cp -R "$SOURCE" "$staging" || die "cannot copy the skill to $staging"

    # Move the old copy aside first; if the new one cannot be moved in, restore it.
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "$backup" || die "cannot move the old copy aside: $dest"
    fi
    if ! mv "$staging" "$dest"; then
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            mv "$backup" "$dest" || true
        fi
        die "cannot move the skill to $dest"
    fi
    staging=
    rm -rf "$backup"
    backup=
    [ -f "$dest/SKILL.md" ] || die "the installed copy has no SKILL.md: $dest"
    printf 'installed %s\n' "$dest"
}

remove_from() {
    parent=$1
    [ -n "$parent" ] || die "empty target folder"
    dest="$parent/reproduce"
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        printf 'not installed: %s\n' "$dest"
        return 0
    fi
    if [ -e "$dest" ] && [ "$(cd -- "$parent" && pwd -P)" = "$(cd -- "$SOURCE/.." && pwd -P)" ]; then
        die "refusing to remove the source copy: $dest"
    fi
    [ -f "$dest/SKILL.md" ] || die "refusing to remove $dest: no SKILL.md"
    grep -q '^name: reproduce$' "$dest/SKILL.md" || die "refusing to remove $dest: not the reproduce skill"
    rm -rf "$dest"
    printf 'removed %s\n' "$dest"
}

if [ "$uninstall" -eq 1 ]; then
    if [ -n "$skills_dir" ]; then
        [ "$skills_dir" != "/" ] || die "refusing to remove from /"
        remove_from "$skills_dir"
    elif [ "$project" -eq 1 ]; then
        remove_from "$PWD/.claude/skills"
        remove_from "$PWD/.agents/skills"
    elif [ -n "$agent" ]; then
        [ -n "${HOME:-}" ] || die "HOME is not set"
        case "$agent" in
            claude) target="$HOME/.claude/skills" ;;
            codex|opencode|gemini|cursor|copilot) target="$HOME/.agents/skills" ;;
            antigravity) target="$HOME/.gemini/config/skills" ;;
            *) die "unknown agent: $agent (claude, codex, opencode, gemini, antigravity, cursor, copilot)" ;;
        esac
        remove_from "$target"
    else
        [ -n "${HOME:-}" ] || die "HOME is not set; use --skills-dir"
        remove_from "$HOME/.claude/skills"
        remove_from "$HOME/.agents/skills"
        for extra in "$HOME/.gemini/config/skills" "$HOME/.config/opencode/skills"; do
            if [ -e "$extra/reproduce" ] || [ -L "$extra/reproduce" ]; then
                remove_from "$extra"
            fi
        done
    fi
    exit 0
fi

if [ -n "$skills_dir" ]; then
    [ "$skills_dir" != "/" ] || die "refusing to install into /"
    install_to "$skills_dir"
elif [ "$project" -eq 1 ]; then
    install_to "$PWD/.claude/skills"
    install_to "$PWD/.agents/skills"
elif [ -n "$agent" ]; then
    [ -n "${HOME:-}" ] || die "HOME is not set"
    case "$agent" in
        claude) target="$HOME/.claude/skills" ;;
        codex|opencode|gemini|cursor|copilot) target="$HOME/.agents/skills" ;;
        antigravity) target="$HOME/.gemini/config/skills" ;;
        *) die "unknown agent: $agent (claude, codex, opencode, gemini, antigravity, cursor, copilot)" ;;
    esac
    install_to "$target"
else
    [ -n "${HOME:-}" ] || die "HOME is not set; use --skills-dir"
    install_to "$HOME/.claude/skills"
    install_to "$HOME/.agents/skills"
    for extra in "$HOME/.gemini/config/skills" "$HOME/.config/opencode/skills"; do
        if [ -d "$extra/reproduce" ]; then
            install_to "$extra"
        fi
    done
fi
