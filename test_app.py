"""app.py の出力が "Hello, World!" であることを確認するテスト。"""
import subprocess
import sys

result = subprocess.run(
    [sys.executable, "app.py"], capture_output=True, text=True, check=True
)
output = result.stdout.strip()

assert output == "Hello, World!", f"unexpected output: {output!r}"
print(f"PASS: {output}")
