#!/usr/bin/env bash
# 検証シナリオ用のブランチを作るスクリプト。
# main に初期コミットがある状態で実行する。push と PR 作成は VERIFY.md の手順で行う。
#
# 使い方: bash scripts/make-scenarios.sh
set -euo pipefail

if [[ -n "$(git status --porcelain)" ]]; then
  echo "作業ツリーに未コミットの変更があります。先にコミットしてください。" >&2
  exit 1
fi

git switch -q main

make_branch() {
  local branch=$1 message=$2
  shift 2
  git switch -q -c "$branch" main
  "$@"
  git add -A
  git commit -q -m "$message"
  echo "created: $branch"
  git switch -q main
}

# --- s8: ベースが先に進んだ PR（main を進める前に分岐させておく）---
make_branch s8-base-advanced "docs: md only (base will advance)" \
  bash -c 'echo "- base advanced scenario" >> README.md'

# main を1コミット進める（コードの変更）。
# 二点 diff だとこの変更まで拾ってしまい、三点 diff / マージコミット比較なら拾わないことを確認する。
echo "# util added on main" > src/util.sh
git add -A
git commit -q -m "chore: advance main with a code change"
echo "advanced: main"

# --- 以降は進んだ main から分岐 ---
make_branch s1-md-root "docs: update README" \
  bash -c 'echo "- md root" >> README.md'

make_branch s2-md-subdir "docs: update docs/guide/usage.md" \
  bash -c 'echo "- md subdir" >> docs/guide/usage.md'

make_branch s3-docs-non-md "docs: update docs/diagram.txt" \
  bash -c 'echo "- docs non-md" >> docs/diagram.txt'

make_branch s4-code-only "feat: change code comment" \
  bash -c 'echo "# code only" >> src/app.sh'

make_branch s5-md-and-code "feat: change code and README" \
  bash -c 'echo "- md and code" >> README.md; echo "# md and code" >> src/app.sh'

make_branch s6-test-fail "feat: break the test" \
  bash -c 'sed -i "s/echo \"hello\"/echo \"bye\"/" src/app.sh'

# [skip ci] はコミットメッセージで指定する（変更内容はコード）
make_branch s7-skip-ci "feat: change code [skip ci]" \
  bash -c 'echo "# skip ci" >> src/app.sh'

echo
git branch --list 's*'
