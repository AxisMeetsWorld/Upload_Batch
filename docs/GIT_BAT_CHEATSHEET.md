# Git + Windows .bat Cheat Sheet

A compact reference for common Git commands, core concepts, and Windows batch (.bat) patterns for automating repository tasks, stamping builds, and safely pushing changes.

---

## Quick concepts (what Git actually stores)
- Blob — file contents (immutable).
- Tree — directory that points to blobs and subtrees.
- Commit — points to a tree, has zero or more parents, metadata, and a message. Identified by a hash (SHA).
- Ref — named pointer to a commit (branches: `refs/heads/*`, remotes: `refs/remotes/*`).
- HEAD — symbolic ref to the currently checked-out ref (usually a branch). If HEAD points directly at a commit SHA, you're in "detached HEAD" state.

Useful commands:
- `git rev-parse HEAD` — full commit SHA
- `git rev-parse --short HEAD` — short SHA
- `git describe --tags --always --dirty` — tag+distance or SHA, with `-dirty` if uncommitted changes

---

## Fundamental Git commands (short)
- Clone: `git clone <url>`
- Status: `git status`
- Stage: `git add <path>`
- Commit: `git commit -m "message"`
- Amend last commit: `git commit --amend`
- Branch list: `git branch`
- Create + switch branch: `git checkout -b <name>` or `git switch -c <name>`
- Switch branch: `git checkout <branch>` or `git switch <branch>`
- Fetch remote refs: `git fetch origin`
- Pull (fetch + merge): `git pull`
- Pull with rebase: `git pull --rebase origin main`
- Push: `git push origin <branch>`
- Set upstream on first push: `git push --set-upstream origin <branch>`
- Safe force push after rebase: `git push --force-with-lease origin <branch>`
- View history: `git log --oneline --graph --decorate --all`
- Show commit: `git show <sha>`
- Undo local working changes: `git restore <file>`
- Unstage file: `git restore --staged <file>`
- Hard reset (dangerous): `git reset --hard <sha>`
- Revert commit (safe for shared history): `git revert <sha>`
- Recover recent HEAD moves: `git reflog`
- Large files: `git lfs install` + `git lfs track "*.bin"`

---

## Windows .bat basics
- Variables: `set MYVAR=hello` then `echo %MYVAR%`
- In a `.bat`, `FOR` loop variables use `%%` (e.g., `%%I`); on command line use single `%I`.
- Enable delayed expansion (useful inside loops/blocks):
  - `setlocal enabledelayedexpansion`
  - Use `!VAR!` to access the value at execution time
- Quote paths with spaces: `"C:\path with spaces\file.txt"`
- Check last command status: `%ERRORLEVEL%` (0 = success)
- Exit a script with a code: `exit /b 1`

Common patterns:
- Silent header: `@echo off`
- Show commands for debugging: `@echo on`
- Keep environment local: `setlocal` / `endlocal`

---

## Capture Git output into a variable (batch)
Get short commit hash into `%GITHASH%`:
```batch
@echo off
for /f "delims=" %%H in ('git rev-parse --short HEAD 2^>nul') do set GITHASH=%%H
echo Commit short hash: %GITHASH%
```
Notes: `2^>nul` escapes redirection inside the `FOR` command in a `.bat`.

Detect dirty working tree and append `-dirty`:
```batch
@echo off
set DIRTY=
for /f "delims=" %%S in ('git status --porcelain') do set DIRTY=-dirty
for /f "delims=" %%H in ('git rev-parse --short HEAD 2^>nul') do set GITHASH=%%H
if "%GITHASH%"=="" set GITHASH=unknown
echo %GITHASH%%DIRTY%
```

---

## Ready-to-use .bat snippets

1) Minimal commit + push with error checking
```batch
@echo off
setlocal

cd /d "C:\path\to\repo"

REM Stage all changes
git add -A
if %ERRORLEVEL% neq 0 (
  echo git add failed
  exit /b 1
)

REM Skip commit if nothing staged
git diff --staged --quiet
if %ERRORLEVEL% equ 0 (
  echo Nothing staged to commit.
) else (
  git commit -m "Automated commit from batch"
  if %ERRORLEVEL% neq 0 (
    echo git commit failed
    exit /b 1
  )
)

REM Fetch then try to push
git fetch origin
if %ERRORLEVEL% neq 0 (
  echo git fetch failed
  exit /b 1
)

git push origin HEAD
if %ERRORLEVEL% neq 0 (
  echo Push failed (maybe non-fast-forward). Trying to rebase and push...
  git pull --rebase origin main
  if %ERRORLEVEL% neq 0 (
    echo Rebase failed, resolve conflicts manually
    exit /b 1
  )
  git push --force-with-lease origin HEAD
  if %ERRORLEVEL% neq 0 (
    echo Force push failed
    exit /b 1
  )
)

endlocal
echo Done.
```
Adjust `main` to your upstream branch name.

2) Stamp build artifact with commit hash
```batch
@echo off
setlocal

for /f "delims=" %%H in ('git rev-parse --short HEAD 2^>nul') do set GITHASH=%%H
set DIRTY=
for /f "delims=" %%S in ('git status --porcelain') do set DIRTY=-dirty

if "%GITHASH%"=="" set GITHASH=unknown

set BUILDNAME=MyApp-%GITHASH%%DIRTY%.zip
echo Creating build: %BUILDNAME%
REM Replace with your build/pack commands
REM powershell -Command "Compress-Archive -Path .\dist\* -DestinationPath .\build\%BUILDNAME%"

endlocal
```

3) Safe fetch-only check (what's incoming)
```batch
@echo off
setlocal

git fetch origin
if %ERRORLEVEL% neq 0 (
  echo git fetch failed
  exit /b 1
)

echo Incoming commits on origin/main:
git log --oneline main..origin/main

endlocal
```

---

## Error handling tips for batch scripts
- Always check `%ERRORLEVEL%` after commands that can fail.
- Use `||` and `&&` for short flows, e.g., `git commit -m "..." || (echo commit failed & exit /b 1)`
- Keep a dry-run mode (`--dry-run` flags or an environment variable) to avoid accidental pushes during testing.
- Log stdout/stderr to a file: `your-script.bat > run.log 2>&1`

---

## Authentication & common gotchas
- Use Git Credential Manager (Windows): `git config --global credential.helper manager-core`
- For CI (GitHub Actions) prefer `GITHUB_TOKEN` secret; do not embed PATs in scripts.
- Large files: use Git LFS (`git lfs install`, `git lfs track "<pattern>"`) — LFS does not give access control.
- Long paths on Windows: `git config --system core.longpaths true` (OS must support long paths).
- Filename case issues: Windows is case-insensitive; avoid only-case renames without proper handling.

---

## Automation ideas
- Use GitHub Actions `runs-on: windows-latest` to run `.bat` scripts on push/schedule/workflow_dispatch.
- Make the agent idempotent and add a `--dry-run` flag to the `.bat`.
- Prefer opening a PR with generated changes instead of force-pushing to shared branches.
- Capture logs and upload them as artifacts for diagnosis.

Example Actions step to run a `.bat`:
```yaml
- name: Run upload batch
  run: .\scripts\upload-files.bat
  shell: cmd
```

---

## Troubleshooting checklist
- If push fails: `git fetch origin && git log --oneline HEAD..origin/<branch>`
- If authentication fails: verify `gh auth status` or credential manager; try a manual clone/push.
- If a large push fails: check `git lfs env` and file sizes.
- If a secret was committed: assume compromise — rotate keys and use `git filter-repo` or BFG to purge (coordination required).

---

## Quick reference (one-liners)
- Short hash: `git rev-parse --short HEAD`
- Incoming commits: `git fetch origin && git log --oneline HEAD..origin/yourbranch`
- Undo working changes: `git restore .`
- Unstage all: `git restore --staged .`
- Recover lost HEAD: `git reflog`

---

## Resources
- Pro Git (free book): https://git-scm.com/book/en/v2
- Git documentation: https://git-scm.com/docs
- Git for Windows: https://gitforwindows.org
- GitHub Actions Windows runner docs: https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions
