# verify-md-skip

GitHub Actions で「md だけの変更」のときにテストを省く3つの方法を比べるための検証用リポジトリです。

| ワークフロー | 方法 | md だけのコミットのとき |
|---|---|---|
| `test (paths-ignore)` | `paths-ignore` でワークフローごとスキップ | 起動しない（結果が残らない） |
| `test (shell)` | shell で判定し、テストのジョブを `if:` でスキップ | 起動し、結果は success（test は skipped） |
| `test (shell in runner)` | 各 OS のランナーの中で shell で判定し、テストのステップを `if:` でスキップ | 起動し、結果は success（4台のランナーが起動する） |

テストはいずれも `ubuntu-latest` / `windows-latest` × Python 3.13 / 3.14 の4パターンのマトリクスで、中身は `app.py` の出力が `Hello, World!` であることを `test_app.py` で確認するだけです。

## 検証手順

ワークフローは **main 向けのプルリクエスト** と **main へのマージ（push）** で起動します。ブランチを作って PR を出し、マージするまでの両方で結果を確認します。

### 1. md だけを変更する

```bash
git switch -c md-only main
echo "- md only" >> README.md
git commit -am "docs: md only"
git push -u origin md-only
```

GitHub で main 向けの PR を作成し、結果を確認してからマージします。

期待する結果（PR のときも、マージ後の main でも同じ）：

- `test (paths-ignore)` … 起動しない
- `test (shell)` … success（`changes` は success、`test` は skipped）
- `test (shell in runner)` … success（4台が起動し、テストのステップだけスキップ）

### 2. md 以外も変更する

テストが通るように、出力を変えないコードの変更（コメントの追加）にします。

```bash
git switch main && git pull
git switch -c code-change
echo "# code change" >> app.py
git commit -am "chore: add a comment to app.py"
git push -u origin code-change
```

同様に PR を作成し、マージします。

期待する結果：

- `test (paths-ignore)` … success（テスト4台）
- `test (shell)` … success（`changes` のあとにテスト4台）
- `test (shell in runner)` … success（テスト4台）

## 結果の確認

ブラウザなら Actions タブで確認できます。

GitHub CLI があれば、最新コミットに対する各ワークフローの結果を確認できます（リリース側でテストの成否を確認するときと同じ方法です）。

```bash
sha=$(git rev-parse HEAD)
gh run list --commit "$sha" --json workflowName,conclusion
```

md だけのコミットでは、`test (paths-ignore)` の結果が一覧に出てきません。

test向けに更新。
