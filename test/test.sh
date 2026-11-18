#!/usr/bin/env bash
# 検証用のダミーテスト。src/app.sh が "hello" を出力すれば成功。
set -euo pipefail
actual=$(bash src/app.sh)
if [[ "$actual" != "hello" ]]; then
  echo "FAIL: expected 'hello' but got '$actual'"
  exit 1
fi
echo "PASS"
