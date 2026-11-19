# verify-md-skip

GitHub Actions で「md だけの変更」のときにテストを省く2つの方法を比べるための検証用リポジトリです。

| ワークフロー | 方法 | md だけのコミットのとき |
|---|---|---|
| `test (paths-ignore)` | `paths-ignore` でワークフローごとスキップ | 起動しない（結果が残らない） |
| `test (shell)` | shell で判定し、テストのジョブを `if:` でスキップ | 起動し、結果は success（test は skipped） |

テストはどちらもダミー（`echo` するだけ）です。

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

### 2. md 以外も変更する

```bash
git switch main && git pull
git switch -c add-code
echo "print('hello')" > app.py
git add app.py
git commit -m "feat: add app.py"
git push -u origin add-code
```

同様に PR を作成し、マージします。

期待する結果：

- `test (paths-ignore)` … success
- `test (shell)` … success（`test` も実行される）

## 結果の確認

ブラウザなら Actions タブで確認できます。

GitHub CLI があれば、最新コミットに対する各ワークフローの結果を確認できます（リリース側でテストの成否を確認するときと同じ方法です）。

```bash
sha=$(git rev-parse HEAD)
gh run list --commit "$sha" --json workflowName,conclusion
```

md だけのコミットでは、`test (paths-ignore)` の結果が一覧に出てきません。
