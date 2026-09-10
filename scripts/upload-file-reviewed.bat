@echo off
:: Reviewed upload script for AxisMeetsWorld/Upload_Batch (for review only)
:: File: scripts/upload-file-reviewed.bat
:: This script is a safer, commented variant of the original "Upload file to GitHub.bat".
:: It is added to the git-cheat-sheet branch for review — it does not modify main.

setlocal enabledelayedexpansion

:: ---------- INPUT: accept args or prompt ----------
:: Usage: upload-file-reviewed.bat [filename] [branch] [commit-message]
if "%~1"=="" (
  set /p filename=Enter filename (e.g. file.txt): 
) else set filename=%~1

if "%~2"=="" (
  set /p branch=Enter branch (default: main): 
) else set branch=%~2
if "%branch%"=="" set branch=main

if "%~3"=="" (
  set /p cmsg=Enter commit message: 
) else set cmsg=%~3

:: ---------- DETERMINE REMOTE (prefer origin) ----------
:: If this folder has a .git directory, prefer remote name 'origin'. Otherwise ask for remote.
if exist ".git" (
  set remote_target=origin
) else (
  set /p remote_target=No .git found — enter remote URL or remote name: 
)

:: ---------- SAFETY CHECKS ----------
:: Ensure filename provided and file exists before staging
if "%filename%"=="" (
  echo ERROR: No filename provided.
  exit /b 1
)

if not exist "%filename%" (
  echo ERROR: File not found: "%filename%"
  exit /b 1
)

:: Show summary and require a key press to proceed (review step)
echo.
echo ABOUT TO UPLOAD
echo -----------------
echo File:    "%filename%"
echo Branch:  %branch%
echo Remote:  %remote_target%
echo Message: %cmsg%
echo.
echo Press any key to continue, or close this window to abort.
pause >nul

:: ---------- STAGE & COMMIT ----------
echo Staging "%filename%"...
git add "%filename%"if %ERRORLEVEL% neq 0 (
  echo ERROR: git add failed
  exit /b 1
)

echo Committing...
git commit -m "%cmsg%"if %ERRORLEVEL% neq 0 (
  :: If commit failed with nothing to commit, we continue — nothing new to push.
  echo Note: git commit did not create a new commit (nothing to commit or commit failed).
) else (
  echo Commit created.
)

:: ---------- SYNCHRONIZE WITH REMOTE ----------
:: Fetch first to update remote tracking refs safely
echo Fetching remote "%remote_target%"...
git fetch "%remote_target%"if %ERRORLEVEL% neq 0 (
  echo ERROR: git fetch failed
  exit /b 1
)

echo Attempting to update local branch from remote (rebase)...
git pull --rebase "%remote_target%" "%branch%"if %ERRORLEVEL% neq 0 (
  echo ERROR: git pull --rebase failed. Resolve conflicts and try again.
  exit /b 1
)

:: ---------- PUSH ----------
echo Pushing to "%remote_target%" "%branch%"...
git push "%remote_target%" "%branch%"if %ERRORLEVEL% neq 0 (
  echo ERROR: git push failed
  exit /b 1
)

echo Upload complete.
endlocal
pause >nul
