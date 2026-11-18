# 検証手順

## 0. 手元での確認（push 不要）

```bash
bash scripts/check-pathspec.sh
```

pathspec の `:(exclude)` がサブディレクトリや大文字拡張子にどう効くかを確認します。

## 1. public リポジトリを作って push

```bash
git add -A
git commit -m "init: verification workflows"
gh repo create verify-md-skip --public --source . --push
```

## 2. シナリオ用ブランチを作って push

> **ruleset を設定する前に実行してください。** スクリプトは main に直接コミットを1つ追加します（s8 用）。

```bash
bash scripts/make-scenarios.sh
git push origin main
for b in $(git branch --format='%(refname:short)' --list 's*'); do git push -u origin "$b"; done
```

## 3. ruleset（必須チェック）を設定

Settings → Rules → Rulesets → New branch ruleset

- Target: Default branch（main）
- 「Require status checks to pass」を ON にして、以下を追加
  - `01 test`
  - `02 test`
  - `03 test`
  - `04 test`
  - `05 test`
  - `06 test (ubuntu-latest, a)`  ← マトリクス展開後の名前
  - `07 ci-ok`
  - `08 test (ubuntu-latest, a)`

> チェック名は一度実行されないと候補に出てこないことがあります。先に s4（コードだけ）の PR を作って全ワークフローを1回走らせてから設定すると楽です。

## 4. PR を作成

```bash
for b in $(git branch --format='%(refname:short)' --list 's*'); do
  gh pr create --base main --head "$b" --title "$b" --body "verification: $b"
done
```

## 5. 確認すること

### シナリオと期待値

| ブランチ | 変更内容 | 01 | 02〜05 test | 06 | 07 ci-ok | 08 |
|---|---|---|---|---|---|---|
| s1-md-root | README.md | 起動しない → Pending? | skipped → 満たす? | ? | success? | 全6台起動 |
| s2-md-subdir | docs/guide/usage.md | 起動しない | skipped | ? | success | 全6台起動 |
| s3-docs-non-md | docs/diagram.txt | 起動しない | skipped | ? | success | 全6台起動 |
| s4-code-only | src/app.sh | 実行 | 実行 | 実行 | success | 実行 |
| s5-md-and-code | README.md + src/app.sh | 実行 | 実行 | 実行 | success | 実行 |
| s6-test-fail | src/app.sh（テスト失敗） | failure | failure | failure | **failure になるか** | failure |
| s7-skip-ci | コード + `[skip ci]` | 全部起動しない → Pending? | | | | |
| s8-base-advanced | README.md（ベースが先行） | 起動しない | **skipped になるか**（二点 diff だと src/util.sh を拾う） | | | |

### チェックリスト（記事の TODO に対応）

- [ ] s1: `01 test` が「Expected — Waiting for status to be reported」で止まる画面（スクショ）
- [ ] s1: `02 test` が skipped で、必須チェックを満たしてマージ可能になる画面（スクショ）
- [ ] s1: `06 test` がスキップされたとき、チェック名がどう表示されるか（`06 test` だけ？マトリクス展開される？）（スクショ）
- [ ] s1: `06 test (ubuntu-latest, a)` が Pending で止まるか
- [ ] s1: `07 ci-ok` が success でマージ可能になるか
- [ ] s1: `08` が md だけでも6台全部起動し、各ジョブの所要時間がどれくらいか（Actions の Usage / Summary）
- [ ] s2: サブディレクトリの md でも skip されるか
- [ ] s6: `07 ci-ok` が failure になり、マージがブロックされるか
- [ ] s7: `[skip ci]` で全ワークフローが起動せず Pending になるか
- [ ] s8: 03（fetch-depth: 2）のログで `HEAD^1` が取れているか、02 と判定が一致するか
- [ ] 04: `gh pr diff --name-only` が checkout なしで動くか
- [ ] 05: `predicate-quantifier: 'every'` の判定が 02 と一致するか

## 後片付け

```bash
gh repo delete verify-md-skip --yes
```
