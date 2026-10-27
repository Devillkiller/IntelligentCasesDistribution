@echo off
setlocal EnableExtensions

set "ORG=TaskDistributionDEJun7"
set "BASE_DIR=%~dp0"

where sf >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Salesforce CLI was not found.
    exit /b 1
)

echo.
echo ============================================================
echo Preparing test users
echo ============================================================
echo.

call sf apex run ^
    --file "%BASE_DIR%scripts\apex\seedUsers.apex" ^
    --target-org "%ORG%"

if errorlevel 1 (
    echo.
    echo [ERROR] User preparation failed.
    exit /b 1
)

echo.
echo ============================================================
echo Preparing test user skills
echo ============================================================
echo.

call sf apex run ^
    --file "%BASE_DIR%scripts\apex\seedUserSkills.apex" ^
    --target-org "%ORG%"

if errorlevel 1 (
    echo.
    echo [ERROR] User skill preparation failed.
    exit /b 1
)

echo.
echo [SUCCESS] Test dataset prepared successfully.
echo.

endlocal
