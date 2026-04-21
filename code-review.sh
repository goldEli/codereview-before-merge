#!/usr/bin/env bash
set -euo pipefail

TARGET="main"
SOURCE=""
POS_BRANCH=""
WITH_LIBS=0
USE_CODEX=0

usage() {
  echo "Usage: $(basename "$0") [-libs] [-codex] [-s <source-branch>] [-t <target-branch>] [<branch>]" >&2
  echo "  默认：分支 <当前分支>，不考虑 libs，合入 <target> 分支前代码审核。" >&2
  echo "  传入 -libs：分支 <当前分支>，libs 同名分支合入 <target> 代码审核。" >&2
  echo "  当前分支用 -s 传入，或与位置参数 <branch> 二选一（不可同时指定）。" >&2
  echo "  合并目标分支默认为 main，可用 -t 指定。" >&2
  echo "  执行 claude/codex 前：主项目 git switch 到 <branch>；libs 为 git 仓库时，-libs 则 switch 到 <branch>，否则 switch 到 main；最后回到主项目目录。" >&2
  echo "  默认调用 claude；传入 -codex 则改为调用 codex。" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "$(basename "$0"): -s 需要非空参数" >&2
        usage
        exit 1
      fi
      SOURCE="$2"
      shift 2
      ;;
    -t)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "$(basename "$0"): -t 需要非空参数" >&2
        usage
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    -libs)
      WITH_LIBS=1
      shift
      ;;
    -codex)
      USE_CODEX=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "$(basename "$0"): 未知选项: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -n "$POS_BRANCH" ]]; then
        echo "$(basename "$0"): 只能指定一个位置参数分支名" >&2
        usage
        exit 1
      fi
      POS_BRANCH="$1"
      shift
      ;;
  esac
done

if [[ -n "$SOURCE" && -n "$POS_BRANCH" ]]; then
  echo "$(basename "$0"): 不能同时使用 -s 与位置参数指定当前分支" >&2
  usage
  exit 1
fi

BRANCH="${SOURCE:-$POS_BRANCH}"
if [[ -z "$BRANCH" ]]; then
  usage
  exit 1
fi

if [[ "$WITH_LIBS" -eq 1 ]]; then
  PROMPT="$(cat <<EOF
Pre-merge review: main repo on ${BRANCH}, merge target ${TARGET}. For libs/, review only the libs checkout on branch ${BRANCH} as its own repo—do not use the parent repo's submodule/gitlink pointer or recorded libs commit as the review baseline.

Read-only: do not edit or create files.

Output: full report in English, then a full Chinese translation—include both.
EOF
)"
else
  PROMPT="$(cat <<EOF
Pre-merge review: main repo on ${BRANCH}, merge into ${TARGET}; libs out of scope.

Read-only: do not edit or create files.

Output: full report in English, then a full Chinese translation—include both.
EOF
)"
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "$(basename "$0"): 当前目录不在 git 仓库内，无法切换分支" >&2
  exit 1
}

cd "$REPO_ROOT"

git switch "$BRANCH"

LIBS_PATH="$REPO_ROOT/libs"
if [[ -d "$LIBS_PATH" ]]; then
  if git -C "$LIBS_PATH" rev-parse --git-dir >/dev/null 2>&1; then
    if [[ "$WITH_LIBS" -eq 1 ]]; then
      git -C "$LIBS_PATH" switch "$BRANCH"
    else
      git -C "$LIBS_PATH" switch main
    fi
  else
    echo "$(basename "$0"): 警告: $LIBS_PATH 不是 git 仓库，已跳过 libs 分支切换" >&2
  fi
elif [[ "$WITH_LIBS" -eq 1 ]]; then
  echo "$(basename "$0"): 警告: 未找到 $LIBS_PATH，已跳过 libs 分支切换" >&2
fi

cd "$REPO_ROOT"

RUNNER="claude"
if [[ "$USE_CODEX" -eq 1 ]]; then
  RUNNER="codex"
fi
exec "$RUNNER" "$PROMPT"
