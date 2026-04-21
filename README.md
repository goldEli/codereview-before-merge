# code-review-before-merge

在合并前切换好主仓库与可选的 `libs` 子仓库分支，并用 **Claude** 或 **Codex** 按固定英文提示词做代码审核（输出要求含英文报告及中文翻译）。

## 前置条件

- 在 **git 仓库内**执行（脚本用 `git rev-parse --show-toplevel` 定位根目录）。
- 已安装 `claude` 或 `codex`，且可在 `PATH` 中直接调用。
- 可选：仓库根下存在 **`libs/`** 且为独立 git 仓库时，脚本会按参数切换 `libs` 分支。

## 用法

```text
./code-review.sh [-libs] [-codex] [-s <source-branch>] [-t <target-branch>] [<branch>]
```

查看内置说明：

```bash
./code-review.sh -h
```

## 参数说明

| 选项 | 说明 |
|------|------|
| **`-s <branch>`** | 指定当前要审核的分支名（写入提示词中的 `BRANCH`）。与位置参数 `<branch>` **二选一**，不可同时使用。 |
| **`<branch>`** | 与 `-s` 等价含义，二选一。 |
| **`-t <branch>`** | 提示词里的合并目标分支，默认 **`main`**。 |
| **`-libs`** | 打开后：提示词包含「主仓 + 同名的 `libs` 分支合入目标分支」；且 **`libs` 会 `git switch` 到与主仓相同的分支**。未传时：提示词为「不考虑 libs」；**`libs` 会 `git switch` 到 `main`**（若 `libs` 为 git 目录）。 |
| **`-codex`** | 使用 **`codex`** 执行；默认使用 **`claude`**。 |

## 执行流程（调用 AI 之前）

1. 进入主仓库根目录，执行 **`git switch <BRANCH>`**（`BRANCH` 来自 `-s` 或位置参数）。
2. 若存在 **`libs/`** 且为 git 仓库：  
   - 有 **`-libs`**：`git -C libs switch <BRANCH>`  
   - 无 **`-libs`**：`git -C libs switch main`
3. 回到主仓库根目录，执行 **`claude` / `codex`**，传入拼接后的英文提示词（末尾要求英文报告 + 中文翻译并存）。

## 示例

```bash
# 当前审核分支 feature/foo，目标 main，不考虑 libs，用 Claude
./code-review.sh -s feature/foo

# 同上，但把 libs 切到同名分支并纳入提示词
./code-review.sh -libs -s feature/foo

# 目标分支为 develop，改用 Codex
./code-review.sh -s feature/foo -t develop -codex

# 位置参数写法
./code-review.sh feature/foo -libs
```

首次使用请赋予脚本可执行权限：

```bash
chmod +x ./code-review.sh
```
