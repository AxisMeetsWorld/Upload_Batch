@echo off
:: THIS LINE IS CRITICAL: It allows the variables inside the IF statement to work
setlocal enabledelayedexpansion

:: Ask for the filename, the message, and the branch, and get current folder
set /p filename="Enter filename (e.g. Trap_game_study.ipynb): "
set /p cmsg="Enter version description: "
set /p branch="Enter branch name (e.g. feature/Trap_Games): "
cd | clip
set current_path=%cd%

:: Navigate to the folder you need.
cd %current_path%

:: Note that the repository is specified in the hidden .git folder (if present) you will need to make sure you specify the full URL
:: THE IF/THEN LOGIC: Check for the .git folder
if exist ".git" (
    set remote_target=origin
) else (
    set /p full_url="Enter Full Repository URL: "
    set remote_target=!full_url!
)

::If there is no .git file, confirm the entries are correct
::>nul hides that text so you can provide your own custom "Confirm or Abort"
echo.
echo PLEASE CONFIRM BEFORE UPLOADING:
echo File: %filename%
echo Message: %cmsg%
echo Target: !remote_target! %branch%
echo ===================================================
echo Press any key to UPLOAD, or close this window to ABORT.
pause

echo Staging file...
git add "%filename%"

echo Committing the message you specified
git commit -m "%cmsg%"

:: Connect with the branch name in your repository. Note the GitHub "origin" command above fits the ".git" folder if specified
:: This is handled above so we can always use remote_target, and note becaue of the timing of the If statement above, we need to 
:: have quotes around the branch in case there are spaces here...
git pull !remote_target! "%branch%"

:: Now push to GitHub (the new file to the repository online) and note the need for quotes
echo Uploading to GitHub...
git push !remote_target! "%branch%"

echo Done
pause
