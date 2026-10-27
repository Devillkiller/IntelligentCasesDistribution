@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM CONFIGURATION
REM ============================================================

set "ORG=TaskDistributionDEJun7"
set "RUNS=10"

if not "%~1"=="" (
    set "RUNS=%~1"
)

set "BASE_DIR=%~dp0"
set "POLL_ATTEMPTS=90"
set "POLL_SECONDS=2"

set "LEFTOVER_FILE=%TEMP%\task_distribution_leftover_cases.csv"
set "VERIFY_FILE=%TEMP%\task_distribution_verify.json"
set "RESULT_FILE=%TEMP%\task_distribution_result.json"
set "RESULT_VARS_FILE=%TEMP%\task_distribution_result_vars.bat"
set "JOB_FILE=%TEMP%\task_distribution_job.csv"
set "CANDIDATE_FILE=%TEMP%\task_distribution_candidates.csv"
set "LOAD_FILE=%TEMP%\task_distribution_load.json"

set "SUMMARY_FILE=%BASE_DIR%test-summary.txt"
set "DETAIL_FILE=%BASE_DIR%test-results.csv"

REM ============================================================
REM CHECK SALESFORCE CLI
REM ============================================================

where sf >nul 2>&1

if errorlevel 1 (
    echo.
    echo [ERROR] Salesforce CLI was not found.
    echo Make sure the sf command is available in CMD.
    echo.
    pause
    exit /b 1
)

REM ============================================================
REM CLEAN TEMP FILES
REM ============================================================

for %%T in (
    "%LEFTOVER_FILE%"
    "%VERIFY_FILE%"
    "%RESULT_FILE%"
    "%RESULT_VARS_FILE%"
    "%JOB_FILE%"
    "%CANDIDATE_FILE%"
    "%LOAD_FILE%"
) do (
    if exist %%T (
        del /q %%T >nul 2>&1
    )
)

if exist "%SUMMARY_FILE%" (
    del /q "%SUMMARY_FILE%" >nul 2>&1
)

if exist "%DETAIL_FILE%" (
    del /q "%DETAIL_FILE%" >nul 2>&1
)

REM ============================================================
REM INITIALIZE OUTPUT FILES
REM ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "Set-Content -LiteralPath $env:DETAIL_FILE -Value 'Test,Run,Id,Subject,Description,ExpectedOwnerName,ActualOwnerName,AssignmentDurationSeconds,Result' -Encoding UTF8;" ^
    "$lines = @(" ^
        "'============================================================'," ^
        "'TASK DISTRIBUTION TEST SUMMARY'," ^
        "'Org: ' + $env:ORG," ^
        "'Runs per scenario: ' + $env:RUNS," ^
        "'============================================================'," ^
        "''" ^
    ");" ^
    "Set-Content -LiteralPath $env:SUMMARY_FILE -Value $lines -Encoding UTF8"

if errorlevel 1 (
    echo [ERROR] Unable to initialize result files.
    pause
    exit /b 1
)

REM ============================================================
REM START
REM ============================================================

echo.
echo ============================================================
echo Task Distribution Test Runner
echo Org: %ORG%
echo Runs per scenario: %RUNS%
echo ============================================================
echo.

REM ============================================================
REM VERIFY CANDIDATE DATASET
REM ============================================================

echo Verifying candidate dataset...

call sf data query ^
    --query "SELECT Name FROM User WHERE IsActive = TRUE AND UserRole.Name = 'Task Distribution Customer Support' ORDER BY Name" ^
    --target-org "%ORG%" ^
    --result-format csv ^
    --output-file "%CANDIDATE_FILE%" >nul 2>&1

if errorlevel 1 (
    echo [ERROR] Unable to query candidate users.
    pause
    exit /b 1
)

set "CANDIDATE_COUNT=0"

for /f "usebackq skip=1 delims=" %%R in ("%CANDIDATE_FILE%") do (
    set /a CANDIDATE_COUNT+=1
)

if not "!CANDIDATE_COUNT!"=="6" (
    echo.
    echo [ERROR] Expected exactly 6 active test candidates.
    echo Found: !CANDIDATE_COUNT!
    echo.
    type "%CANDIDATE_FILE%"
    echo.
    pause
    exit /b 1
)

for %%N in (
    "Apex Dev Specialist"
    "Admin Dev Specialist"
    "Dev Admin Specialist"
    "LWC Dev Specialist"
    "Security Admin Specialist"
    "Service Admin Specialist"
) do (
    findstr /C:%%N "%CANDIDATE_FILE%" >nul 2>&1

    if errorlevel 1 (
        echo [ERROR] Expected candidate %%~N was not found.
        pause
        exit /b 1
    )
)

echo [SUCCESS] Controlled candidate dataset is present.
echo.

REM ============================================================
REM CHECK FOR LEFTOVER AUTOMATED TEST CASES
REM ============================================================

echo Checking for Cases left from previous automated runs...

call sf data query ^
    --query "SELECT Id FROM Case WHERE Subject LIKE 'AUTO-ST-%%'" ^
    --target-org "%ORG%" ^
    --json > "%VERIFY_FILE%" 2>nul

if errorlevel 1 (
    echo [ERROR] Unable to check for automated test Cases.
    pause
    exit /b 1
)

set "CASE_COUNT="

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$data = Get-Content -Raw -LiteralPath $env:VERIFY_FILE | ConvertFrom-Json;" ^
    "Set-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set CASE_COUNT=' + [string]$data.result.totalSize) -Encoding ASCII"

if errorlevel 1 (
    echo [ERROR] Unable to parse automated test Case query result.
    pause
    exit /b 1
)

call "%RESULT_VARS_FILE%"

if not defined CASE_COUNT (
    set "CASE_COUNT=0"
)

if !CASE_COUNT! GTR 0 (

    echo Found !CASE_COUNT! leftover automated test Cases.
    echo Retrieving Case Ids...

    call sf data query ^
        --query "SELECT Id FROM Case WHERE Subject LIKE 'AUTO-ST-%%'" ^
        --target-org "%ORG%" ^
        --result-format csv ^
        --output-file "%LEFTOVER_FILE%" >nul 2>&1

    if errorlevel 1 (
        echo [ERROR] Unable to retrieve leftover automated test Cases.
        pause
        exit /b 1
    )

    echo Deleting leftover automated test Cases...

    for /f "usebackq skip=1 delims=" %%C in ("%LEFTOVER_FILE%") do (

        set "LEFTOVER_CASE_ID=%%~C"

        if defined LEFTOVER_CASE_ID (

            call sf data delete record ^
                --sobject Case ^
                --record-id "!LEFTOVER_CASE_ID!" ^
                --target-org "%ORG%" >nul 2>&1

            if errorlevel 1 (
                echo.
                echo [ERROR] Unable to delete leftover Case !LEFTOVER_CASE_ID!.
                echo.
                pause
                exit /b 1
            )
        )
    )

    echo [SUCCESS] Leftover automated test Cases were removed.

) else (

    echo [SUCCESS] No leftover automated test Cases were found.
)

if exist "%LEFTOVER_FILE%" (
    del /q "%LEFTOVER_FILE%" >nul 2>&1
)

if exist "%VERIFY_FILE%" (
    del /q "%VERIFY_FILE%" >nul 2>&1
)

if exist "%RESULT_VARS_FILE%" (
    del /q "%RESULT_VARS_FILE%" >nul 2>&1
)

echo.

REM ============================================================
REM VERIFY INITIAL CANDIDATE LOAD
REM ============================================================

echo Verifying initial candidate load...

call sf data query ^
    --query "SELECT Id FROM Case WHERE IsClosed = FALSE AND Owner.UserRole.Name = 'Task Distribution Customer Support'" ^
    --target-org "%ORG%" ^
    --json > "%LOAD_FILE%" 2>nul

if errorlevel 1 (
    echo [ERROR] Unable to verify initial candidate load.
    pause
    exit /b 1
)

set "OPEN_CASE_COUNT="

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$data = Get-Content -Raw -LiteralPath $env:LOAD_FILE | ConvertFrom-Json;" ^
    "Set-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set OPEN_CASE_COUNT=' + [string]$data.result.totalSize) -Encoding ASCII"

if errorlevel 1 (
    echo [ERROR] Unable to parse initial candidate load result.
    pause
    exit /b 1
)

call "%RESULT_VARS_FILE%"

if not defined OPEN_CASE_COUNT (
    set "OPEN_CASE_COUNT=0"
)

if !OPEN_CASE_COUNT! GTR 0 (
    echo.
    echo [ERROR] Test candidates already own !OPEN_CASE_COUNT! open Cases.
    echo Each experimental run must start from the same initial load.
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Initial candidate load is zero.
echo.

REM ============================================================
REM RUN ST-1 THROUGH ST-6
REM ============================================================

for %%F in (
    scripts\apex\ST-1.apex
    scripts\apex\ST-2.apex
    scripts\apex\ST-3.apex
    scripts\apex\ST-4.apex
    scripts\apex\ST-5.apex
    scripts\apex\ST-6.apex
) do (

    set "TEST_NAME=%%~nF"
    set "CASE_SUBJECT=AUTO-!TEST_NAME!"
    set "EXPECTED_OWNER="

    if /I "!TEST_NAME!"=="ST-1" (
        set "EXPECTED_OWNER=Apex Dev Specialist"
    )

    if /I "!TEST_NAME!"=="ST-2" (
        set "EXPECTED_OWNER=Security Admin Specialist"
    )

    if /I "!TEST_NAME!"=="ST-3" (
        set "EXPECTED_OWNER=Service Admin Specialist"
    )

    if /I "!TEST_NAME!"=="ST-4" (
        set "EXPECTED_OWNER=LWC Dev Specialist"
    )

    if /I "!TEST_NAME!"=="ST-5" (
        set "EXPECTED_OWNER=Admin Dev Specialist"
    )

    if /I "!TEST_NAME!"=="ST-6" (
        set "EXPECTED_OWNER=Dev Admin Specialist"
    )

    if not exist "%BASE_DIR%%%F" (
        echo [ERROR] Apex file not found:
        echo %BASE_DIR%%%F
        pause
        exit /b 1
    )

    echo.
    echo ############################################################
    echo TEST SCENARIO: !TEST_NAME!
    echo EXPECTED OWNER: !EXPECTED_OWNER!
    echo ############################################################
    echo.

    for /L %%I in (1,1,%RUNS%) do (

        echo ============================================================
        echo !TEST_NAME! - RUN %%I of %RUNS%
        echo ============================================================

        REM ========================================================
        REM VERIFY CLEAN STATE BEFORE RUN
        REM ========================================================

        call sf data query ^
            --query "SELECT Id FROM Case WHERE Subject = '!CASE_SUBJECT!'" ^
            --target-org "%ORG%" ^
            --json > "%VERIFY_FILE%" 2>nul

        if errorlevel 1 (
            echo [ERROR] Unable to verify clean state before !TEST_NAME! run %%I.
            pause
            exit /b 1
        )

        set "REMAINING_COUNT="

        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$ErrorActionPreference = 'Stop';" ^
            "$data = Get-Content -Raw -LiteralPath $env:VERIFY_FILE | ConvertFrom-Json;" ^
            "Set-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set REMAINING_COUNT=' + [string]$data.result.totalSize) -Encoding ASCII"

        if errorlevel 1 (
            echo [ERROR] Unable to parse clean-state query result.
            pause
            exit /b 1
        )

        call "%RESULT_VARS_FILE%"

        if not defined REMAINING_COUNT (
            set "REMAINING_COUNT=0"
        )

        if !REMAINING_COUNT! GTR 0 (
            echo [ERROR] A previous !TEST_NAME! Case still exists.
            pause
            exit /b 1
        )

        REM ========================================================
        REM EXECUTE SCENARIO
        REM ========================================================

        call sf apex run ^
            --file "%BASE_DIR%%%F" ^
            --target-org "%ORG%"

        if errorlevel 1 (
            echo [ERROR] !TEST_NAME! failed during run %%I.
            pause
            exit /b 1
        )

        REM ========================================================
        REM LOCATE QUEUEABLE JOB
        REM ========================================================

        call sf data query ^
            --query "SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE ApexClass.Name = 'CaseAssignmentQueueable' ORDER BY CreatedDate DESC LIMIT 1" ^
            --target-org "%ORG%" ^
            --result-format csv ^
            --output-file "%JOB_FILE%" >nul 2>&1

        if errorlevel 1 (
            echo [ERROR] Unable to locate CaseAssignmentQueueable job.
            pause
            exit /b 1
        )

        set "JOB_ID="
        set "JOB_STATUS="
        set "JOB_ERRORS="

        for /f "usebackq skip=1 tokens=1-3 delims=," %%A in ("%JOB_FILE%") do (
            set "JOB_ID=%%~A"
            set "JOB_STATUS=%%~B"
            set "JOB_ERRORS=%%~C"
        )

        if not defined JOB_ID (
            echo [ERROR] Queueable job was not found after !TEST_NAME! run %%I.
            pause
            exit /b 1
        )

        REM ========================================================
        REM WAIT FOR QUEUEABLE
        REM ========================================================

        set "JOB_DONE="
        set "JOB_FAILED="

        for /L %%W in (1,1,%POLL_ATTEMPTS%) do (

            if not defined JOB_DONE (

                call sf data query ^
                    --query "SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = '!JOB_ID!'" ^
                    --target-org "%ORG%" ^
                    --result-format csv ^
                    --output-file "%JOB_FILE%" >nul 2>&1

                if errorlevel 1 (

                    echo [ERROR] Unable to query Queueable status.

                    set "JOB_FAILED=1"
                    set "JOB_DONE=1"

                ) else (

                    set "JOB_STATUS="
                    set "JOB_ERRORS="

                    for /f "usebackq skip=1 tokens=1-2 delims=," %%A in ("%JOB_FILE%") do (
                        set "JOB_STATUS=%%~A"
                        set "JOB_ERRORS=%%~B"
                    )

                    if /I "!JOB_STATUS!"=="Completed" (
                        set "JOB_DONE=1"
                    )

                    if /I "!JOB_STATUS!"=="Failed" (
                        set "JOB_FAILED=1"
                        set "JOB_DONE=1"
                    )

                    if /I "!JOB_STATUS!"=="Aborted" (
                        set "JOB_FAILED=1"
                        set "JOB_DONE=1"
                    )

                    if not defined JOB_DONE (
                        timeout /t %POLL_SECONDS% /nobreak >nul
                    )
                )
            )
        )

        if not defined JOB_DONE (
            echo [ERROR] Queueable did not reach a terminal state.
            pause
            exit /b 1
        )

        if defined JOB_FAILED (
            echo.
            echo [ERROR] Queueable !JOB_ID! finished unsuccessfully.
            echo Status: !JOB_STATUS!
            echo Errors: !JOB_ERRORS!
            echo.
            pause
            exit /b 1
        )

        REM ========================================================
        REM RETRIEVE CASE RESULT
        REM ========================================================

        call sf data query ^
            --query "SELECT Id, Subject, Description, Owner.Name, CreatedDate, LastModifiedDate FROM Case WHERE Subject = '!CASE_SUBJECT!' ORDER BY CreatedDate DESC LIMIT 1" ^
            --target-org "%ORG%" ^
            --json > "%RESULT_FILE%" 2>nul

        if errorlevel 1 (
            echo [ERROR] Unable to retrieve !TEST_NAME! result.
            pause
            exit /b 1
        )

        REM ========================================================
        REM PROCESS RESULT AND APPEND CSV
        REM ========================================================

        set "CSV_TEST=!TEST_NAME!"
        set "CSV_RUN=%%I"
        set "CSV_EXPECTED_OWNER=!EXPECTED_OWNER!"

        if exist "%RESULT_VARS_FILE%" (
            del /q "%RESULT_VARS_FILE%" >nul 2>&1
        )

        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$ErrorActionPreference = 'Stop';" ^
            "$data = Get-Content -Raw -LiteralPath $env:RESULT_FILE | ConvertFrom-Json;" ^
            "$record = @($data.result.records)[0];" ^
            "if ($null -eq $record) { throw 'No Case record returned.' };" ^
            "$caseId = ([string]$record.Id).Trim();" ^
            "$expectedOwner = ([string]$env:CSV_EXPECTED_OWNER).Trim();" ^
            "$actualOwner = ([string]$record.Owner.Name).Trim();" ^
            "$runResult = if ([string]::Equals($expectedOwner, $actualOwner, [System.StringComparison]::OrdinalIgnoreCase)) { 'PASS' } else { 'FAIL' };" ^
            "$created = [DateTimeOffset]::Parse([string]$record.CreatedDate);" ^
            "$modified = [DateTimeOffset]::Parse([string]$record.LastModifiedDate);" ^
            "$duration = [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:F3}', ($modified - $created).TotalSeconds);" ^
            "$row = [pscustomobject]@{" ^
                "Test = $env:CSV_TEST;" ^
                "Run = [int]$env:CSV_RUN;" ^
                "Id = $caseId;" ^
                "Subject = [string]$record.Subject;" ^
                "Description = [string]$record.Description;" ^
                "ExpectedOwnerName = $expectedOwner;" ^
                "ActualOwnerName = $actualOwner;" ^
                "AssignmentDurationSeconds = $duration;" ^
                "Result = $runResult" ^
            "};" ^
            "$csvLine = $row | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1;" ^
            "Add-Content -LiteralPath $env:DETAIL_FILE -Value $csvLine -Encoding UTF8;" ^
            "Set-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set CASE_ID=' + $caseId) -Encoding ASCII;" ^
            "Add-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set RUN_RESULT=' + $runResult) -Encoding ASCII;" ^
            "Add-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set ACTUAL_OWNER=' + $actualOwner) -Encoding ASCII"

        if errorlevel 1 (
            echo [ERROR] Unable to process !TEST_NAME! run %%I result.
            pause
            exit /b 1
        )

        call "%RESULT_VARS_FILE%"

        if not defined CASE_ID (
            echo [ERROR] Test Case Id was not returned.
            pause
            exit /b 1
        )

        if not defined RUN_RESULT (
            echo [ERROR] Test result was not returned.
            pause
            exit /b 1
        )

        if not defined ACTUAL_OWNER (
            echo [ERROR] Actual owner was not returned.
            pause
            exit /b 1
        )

        echo Expected owner: !EXPECTED_OWNER!
        echo Actual owner:   !ACTUAL_OWNER!
        echo Result:         !RUN_RESULT!

        REM ========================================================
        REM DELETE TEST CASE
        REM ========================================================

        call sf data delete record ^
            --sobject Case ^
            --record-id "!CASE_ID!" ^
            --target-org "%ORG%" >nul 2>&1

        if errorlevel 1 (
            echo.
            echo [ERROR] Delete failed after !TEST_NAME! run %%I.
            echo Case Id: !CASE_ID!
            echo.
            pause
            exit /b 1
        )

        REM ========================================================
        REM VERIFY CLEANUP
        REM ========================================================

        call sf data query ^
            --query "SELECT Id FROM Case WHERE Subject = '!CASE_SUBJECT!'" ^
            --target-org "%ORG%" ^
            --json > "%VERIFY_FILE%" 2>nul

        if errorlevel 1 (
            echo [ERROR] Unable to verify cleanup after !TEST_NAME! run %%I.
            pause
            exit /b 1
        )

        set "REMAINING_COUNT="

        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$ErrorActionPreference = 'Stop';" ^
            "$data = Get-Content -Raw -LiteralPath $env:VERIFY_FILE | ConvertFrom-Json;" ^
            "Set-Content -LiteralPath $env:RESULT_VARS_FILE -Value ('set REMAINING_COUNT=' + [string]$data.result.totalSize) -Encoding ASCII"

        if errorlevel 1 (
            echo [ERROR] Unable to parse cleanup query result.
            pause
            exit /b 1
        )

        call "%RESULT_VARS_FILE%"

        if not defined REMAINING_COUNT (
            set "REMAINING_COUNT=0"
        )

        if !REMAINING_COUNT! GTR 0 (
            echo [ERROR] Test Case remains after cleanup.
            pause
            exit /b 1
        )

        echo [SUCCESS] !TEST_NAME! run %%I completed and cleanup verified.
        echo.
    )
)

REM ============================================================
REM BUILD SUMMARY FROM DETAILED CSV
REM ============================================================

echo Building summary...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$rows = @(Import-Csv -LiteralPath $env:DETAIL_FILE);" ^
    "$tests = @('ST-1','ST-2','ST-3','ST-4','ST-5','ST-6');" ^
    "foreach ($test in $tests) {" ^
        "$testRows = @($rows | Where-Object { $_.Test -eq $test });" ^
        "if ($testRows.Count -eq 0) { continue };" ^
        "$expectedOwner = [string]$testRows[0].ExpectedOwnerName;" ^
        "$passCount = @($testRows | Where-Object { $_.Result -eq 'PASS' }).Count;" ^
        "$failCount = @($testRows | Where-Object { $_.Result -eq 'FAIL' }).Count;" ^
        "$summary = $test + ' - Expected: ' + $expectedOwner + ' - Correct: ' + $passCount + '/' + $testRows.Count + ' - Incorrect: ' + $failCount;" ^
        "Add-Content -LiteralPath $env:SUMMARY_FILE -Value $summary -Encoding UTF8;" ^
    "}"

if errorlevel 1 (
    echo [ERROR] Unable to build test summary.
    pause
    exit /b 1
)

REM ============================================================
REM FINAL RESULTS
REM ============================================================

echo.
echo ############################################################
echo ALL TEST SCENARIOS COMPLETED
echo ############################################################
echo.

type "%SUMMARY_FILE%"

echo.
echo Detailed per-run results:
echo %DETAIL_FILE%
echo.

REM ============================================================
REM CLEAN TEMP FILES
REM ============================================================

for %%T in (
    "%LEFTOVER_FILE%"
    "%VERIFY_FILE%"
    "%RESULT_FILE%"
    "%RESULT_VARS_FILE%"
    "%JOB_FILE%"
    "%CANDIDATE_FILE%"
    "%LOAD_FILE%"
) do (
    if exist %%T (
        del /q %%T >nul 2>&1
    )
)

pause
endlocal
