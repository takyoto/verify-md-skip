#!/usr/bin/env bash
# pathspec の :(exclude) の挙動を手元で確認するスクリプト。
# 一時ディレクトリに使い捨てのリポジトリを作り、変更ファイルの組み合わせごとに
#   git diff --quiet BASE...HEAD -- . ':(exclude)*.md' ':(exclude)docs/**'
# の結果（テストを走らせるか）を表示する。
#
# 使い方: bash scripts/check-pathspec.sh
set -euo pipefail

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

git init -q -b main
git config user.name "check"
git config user.email "check@example.com"
git config core.autocrlf false
mkdir -p src docs/guide sub/deep
echo a > src/app.sh
echo a > README.md
echo a > docs/guide/usage.md
echo a > docs/diagram.txt
echo a > sub/deep/notes.md
echo a > sub/deep/LOUD.MD
git add -A
git commit -q -m init

check() {
  local label=$1; shift
  git switch -q -c "case-$RANDOM" main
  for f in "$@"; do echo b >> "$f"; done
  git commit -q -am "$label"
  local result
  if git diff --quiet main...HEAD -- . ':(exclude)*.md' ':(exclude)docs/**'; then
    result="skip  (code=false)"
  else
    result="run   (code=true)"
  fi
  printf '%-40s -> %s\n' "$label [$*]" "$result"
  git switch -q main
}

echo "git: $(git --version)"
echo
check "ルートの md だけ"            README.md
check "サブディレクトリの md だけ"  sub/deep/notes.md
check "大文字拡張子 .MD だけ"       sub/deep/LOUD.MD
check "docs/ 配下の md だけ"        docs/guide/usage.md
check "docs/ 配下の md 以外だけ"    docs/diagram.txt
check "コードだけ"                  src/app.sh
check "md とコード"                 README.md src/app.sh

echo
echo "--- 大文字小文字を無視する :(icase,exclude) の場合 ---"
git switch -q -c case-icase main
echo b >> sub/deep/LOUD.MD
git commit -q -am "icase"
if git diff --quiet main...HEAD -- . ':(icase,exclude)*.md' ':(exclude)docs/**'; then
  echo "大文字拡張子 .MD だけ [sub/deep/LOUD.MD] -> skip  (code=false)"
else
  echo "大文字拡張子 .MD だけ [sub/deep/LOUD.MD] -> run   (code=true)"
fi
git switch -q main
