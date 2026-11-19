# verify-md-skip

GitHub Actions で「md だけの変更」のときにテストを省く2つの方法を比べるための検証用リポジトリです。

| ワークフロー | 方法 | md だけのコミットのとき |
|---|---|---|
| `test (paths-ignore)` | `paths-ignore` でワークフローごとスキップ | 起動しない（結果が残らない） |
| `test (shell)` | shell で判定し、テストのジョブを `if:` でスキップ | 起動し、結果は success（test は skipped） |

テストはどちらもダミー（`echo` するだけ）です。

## 検証手順

main に直接 push して確認します。

### 1. md だけを変更する

```bash
echo "- md only" >> README.md
git commit -am "docs: md only"
git push
```

期待する結果：

- `test (paths-ignore)` … 起動しない
- `test (shell)` … success（`changes` は success、`test` は skipped）

### 2. md 以外も変更する

```bash
echo "print('hello')" > app.py
git add app.py
git commit -m "feat: add app.py"
git push
```

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
