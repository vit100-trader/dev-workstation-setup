@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: Dealertrack Developer Workstation Setup
:: Run as Administrator
:: ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Run this script as Administrator.
    pause
    exit /b 1
)

set "REPO_DIR=%~dp0"
set "APPCMD=%windir%\system32\inetsrv\appcmd.exe"
set "ERRORS=0"
set "STEP=0"

echo.
echo ============================================================
echo  Dealertrack Developer Workstation Setup
echo ============================================================
echo.

:: ----------------------------------------------------------
:: 1. Check winget availability
:: ----------------------------------------------------------
set /a STEP+=1
echo [%STEP%] Checking winget...
where winget >nul 2>&1
if !errorlevel! neq 0 (
    echo       WARNING: winget not found. Git, Git LFS, and AWS VPN Client must be installed manually.
    set "HAS_WINGET=0"
) else (
    echo       OK
    set "HAS_WINGET=1"
)

:: ----------------------------------------------------------
:: 2. Create directory structure
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Creating directories...
if not exist "C:\dtnsourcecode" mkdir "C:\dtnsourcecode"
if not exist "C:\tools" mkdir "C:\tools"
echo       C:\dtnsourcecode - OK
echo       C:\tools - OK

:: ----------------------------------------------------------
:: 3. Add C:\tools to system PATH if not already there
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Checking C:\tools in system PATH...
echo %PATH% | findstr /I /C:"C:\tools" >nul 2>&1
if !errorlevel! neq 0 (
    echo       Adding C:\tools to system PATH...
    setx /M PATH "%PATH%;C:\tools" >nul 2>&1
    if !errorlevel! neq 0 (
        echo ERROR: Failed to update PATH
        set /a ERRORS+=1
    ) else (
        echo       OK (restart your terminal to pick it up)
    )
) else (
    echo       Already in PATH.
)

:: ----------------------------------------------------------
:: 4. Install Git (if missing)
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Checking Git...
where git >nul 2>&1
if !errorlevel! neq 0 (
    if "!HAS_WINGET!"=="1" (
        echo       Installing Git...
        winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    ) else (
        echo       ERROR: Git not found. Install from https://git-scm.com/downloads
        set /a ERRORS+=1
    )
) else (
    echo       Already installed.
)

:: ----------------------------------------------------------
:: 5. Install Git LFS (if missing)
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Checking Git LFS...
git lfs version >nul 2>&1
if !errorlevel! neq 0 (
    if "!HAS_WINGET!"=="1" (
        echo       Installing Git LFS...
        winget install --id GitHub.GitLFS -e --accept-source-agreements --accept-package-agreements
    ) else (
        echo       ERROR: Git LFS not found. Install from https://git-lfs.com
        set /a ERRORS+=1
    )
) else (
    echo       Already installed.
)
git lfs install >nul 2>&1

:: ----------------------------------------------------------
:: 6. Clone all repos referenced by IIS sites config
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Cloning repos to C:\dtnsourcecode...
where git >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: git not found in PATH. Install Git for Windows first.
    set /a ERRORS+=1
    goto :skip_clone
)

set "GH_ORG=https://github.com/tdr-dealertrack"
set "SRC=C:\dtnsourcecode"
set "CLONE_OK=0"
set "CLONE_SKIP=0"
set "CLONE_FAIL=0"

for %%R in (
    DRS.CreditOnline
    DRS.FinanceDriver
    DRS.LeadManagement
    DRS.Mobile.Login
    DRS.PaymentDriver
    DTN.AMN
    DTN.Cascading
    DTN.CBEServices
    DTN.CommonGateway
    DTN.CommonObjects
    DTN.Connectivity
    DTN.Core.Base
    DTN.CreditBureau
    DTN.CrossSell
    DTN.DealerAdmin
    DTN.ExternalComm.AFS
    DTN.ExternalComm.AMC
    DTN.ExternalComm.ATB
    DTN.ExternalComm.Base
    DTN.ExternalComm.BMO
    DTN.ExternalComm.BMW
    DTN.ExternalComm.BNC
    DTN.ExternalComm.BNS
    DTN.ExternalComm.CarProof
    DTN.ExternalComm.Desjardins
    DTN.ExternalComm.DsoluAdjudicate
    DTN.ExternalComm.Equifax
    DTN.ExternalComm.Flinx
    DTN.ExternalComm.GMAC
    DTN.ExternalComm.GMF
    DTN.ExternalComm.HYN
    DTN.ExternalComm.NCL
    DTN.ExternalComm.NLC
    DTN.ExternalComm.POR
    DTN.ExternalComm.Prolender
    DTN.ExternalComm.RBC
    DTN.ExternalComm.TD
    DTN.ExternalComm.TDC
    DTN.ExternalComm.TLC
    DTN.ExternalComm.Transunion
    DTN.ExternalComm.Tricor
    DTN.ExternalComm.VFC
    DTN.ExternalCommDMS
    DTN.LenderAdmin
    DTN.Payout
    DTN.ProgramManagement
    DTN.ReferenceLib
    DTN.ReportingService
    DTN.SiteAdmin
    DTN.Status
) do (
    if not exist "!SRC!\%%R" (
        <nul set /p="       Cloning %%R... "
        git clone "!GH_ORG!/%%R.git" "!SRC!\%%R" >nul 2>&1
        if !errorlevel! neq 0 (
            echo FAIL
            set /a CLONE_FAIL+=1
        ) else (
            echo OK
            set /a CLONE_OK+=1
        )
    ) else (
        set /a CLONE_SKIP+=1
    )
)
echo       Cloned: !CLONE_OK!  Skipped (exist): !CLONE_SKIP!  Failed: !CLONE_FAIL!
if !CLONE_FAIL! gtr 0 (
    echo       WARNING: Some repos failed. Check your GitHub access.
    set /a ERRORS+=!CLONE_FAIL!
)
:skip_clone

:: ----------------------------------------------------------
:: 7. Enable IIS
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Enabling IIS features (this may take 5-10 minutes, do not close the window)...
dism /online /enable-feature /featurename:IIS-WebServer /featurename:IIS-WebServerRole /featurename:IIS-CommonHttpFeatures /featurename:IIS-StaticContent /featurename:IIS-DefaultDocument /featurename:IIS-DirectoryBrowsing /featurename:IIS-HttpErrors /featurename:IIS-ISAPIExtensions /featurename:IIS-ISAPIFilter /featurename:IIS-NetFxExtensibility /featurename:IIS-NetFxExtensibility45 /featurename:IIS-ASPNET /featurename:IIS-ASPNET45 /featurename:IIS-ASP /featurename:IIS-CGI /featurename:IIS-ServerSideIncludes /featurename:IIS-ManagementConsole /featurename:IIS-ManagementService /featurename:IIS-RequestFiltering /featurename:IIS-HttpCompressionStatic /featurename:IIS-HttpCompressionDynamic /featurename:IIS-WindowsAuthentication /featurename:IIS-BasicAuthentication /featurename:IIS-Metabase /featurename:IIS-WMICompatibility /featurename:IIS-LegacyScripts /featurename:IIS-IIS6ManagementCompatibility /featurename:WAS-WindowsActivationService /featurename:WAS-ProcessModel /featurename:WAS-NetFxEnvironment /featurename:WAS-ConfigurationAPI /featurename:MSMQ-Container /featurename:MSMQ-Server /featurename:MSMQ-HTTP /featurename:MSMQ-Multicast /all /norestart
if !errorlevel! neq 0 (
    echo WARNING: Some IIS features may already be enabled or unavailable. Check manually if needed.
) else (
    echo       IIS enabled.
)

:: ----------------------------------------------------------
:: 8. Import IIS app pools
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Importing IIS application pools...
if exist "%APPCMD%" (
    "%APPCMD%" add apppool /in < "%REPO_DIR%iis\apppools.xml"
    if !errorlevel! neq 0 (
        echo WARNING: Some app pools may already exist. That's fine.
    ) else (
        echo       OK
    )
) else (
    echo ERROR: appcmd.exe not found. IIS may not have installed correctly.
    set /a ERRORS+=1
)

:: ----------------------------------------------------------
:: 9. Import IIS sites
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Importing IIS sites...
if exist "%APPCMD%" (
    "%APPCMD%" delete site "Default Web Site" >nul 2>&1
    "%APPCMD%" add site /in < "%REPO_DIR%iis\sites.xml"
    if !errorlevel! neq 0 (
        echo WARNING: Some sites may already exist. That's fine.
    ) else (
        echo       OK
    )
) else (
    echo ERROR: appcmd.exe not found. Skipping.
    set /a ERRORS+=1
)

:: ----------------------------------------------------------
:: 10. Extract wwwroot
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Extracting wwwroot...
if exist "%REPO_DIR%wwwroot\wwwroot.zip" (
    if exist "C:\inetpub\wwwroot\DTCanada" (
        echo       C:\inetpub\wwwroot already has content. Skipping.
    ) else (
        echo       Extracting to C:\inetpub\ ^(this may take a few minutes^)...
        powershell -NoProfile -Command "$ProgressPreference='Continue'; Expand-Archive -Path '%REPO_DIR%wwwroot\wwwroot.zip' -DestinationPath 'C:\inetpub' -Force"
        if !errorlevel! neq 0 (
            echo ERROR: Failed to extract wwwroot.zip
            set /a ERRORS+=1
        ) else (
            echo       OK
        )
    )
) else (
    echo SKIP: wwwroot.zip not found. Pull it via Git LFS: git lfs pull
)

:: ----------------------------------------------------------
:: 11. machine.config files (backup + copy)
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Copying machine.config files...

set "NET20_32=%windir%\Microsoft.NET\Framework\v2.0.50727\CONFIG"
set "NET20_64=%windir%\Microsoft.NET\Framework64\v2.0.50727\CONFIG"
set "NET40_32=%windir%\Microsoft.NET\Framework\v4.0.30319\Config"

for %%F in (
    "%NET20_32%|machine.config_v2.0_net32|v2.0 32-bit"
    "%NET20_64%|machine.config_v2.0_net64|v2.0 64-bit"
    "%NET40_32%|machine.config_v4.0_net32|v4.0 32-bit"
) do (
    for /f "tokens=1,2,3 delims=|" %%A in (%%F) do (
        if exist "%%~A\machine.config" (
            copy /Y "%%~A\machine.config" "%%~A\machine.config.bak" >nul
        )
        copy /Y "%REPO_DIR%dotnet\%%B" "%%~A\machine.config" >nul
        if !errorlevel! neq 0 (
            echo       ERROR: %%C failed
            set /a ERRORS+=1
        ) else (
            echo       %%C - OK ^(backup saved as .bak^)
        )
    )
)

:: ----------------------------------------------------------
:: 12. Oracle tnsnames.ora
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Copying tnsnames.ora...
set "ORA_DIR=C:\Oracle\product\11.2.0\client_1\network\admin"
if exist "%ORA_DIR%" (
    copy /Y "%REPO_DIR%oracle\tnsnames.ora" "%ORA_DIR%\tnsnames.ora" >nul
    if !errorlevel! neq 0 (
        echo ERROR: Failed to copy tnsnames.ora
        set /a ERRORS+=1
    ) else (
        echo       OK
    )
) else (
    echo SKIP: Oracle client not installed yet. Run this script again after installing Oracle.
)

:: ----------------------------------------------------------
:: 13. Hosts file
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Updating hosts file...
set "HOSTS=%windir%\System32\drivers\etc\hosts"
findstr /C:"localhostcgw" "%HOSTS%" >nul 2>&1
if !errorlevel! neq 0 (
    echo. >> "%HOSTS%"
    type "%REPO_DIR%hosts\hosts-additions.txt" >> "%HOSTS%"
    echo       OK
) else (
    echo       Already configured.
)

:: ----------------------------------------------------------
:: 14. Download NuGet CLI
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Downloading nuget.exe to C:\tools...
del /Q /F "C:\tools\nuget.exe" 2>nul
curl -s -o "C:\tools\nuget.exe" https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
if exist "C:\tools\nuget.exe" (
    echo       OK
) else (
    echo       ERROR: Failed to download nuget.exe
    set /a ERRORS+=1
)

:: ----------------------------------------------------------
:: 15. Extract PDF Upload Tool
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Extracting PDF Upload Tool to C:\tools\PdfUploadTool...
if exist "C:\tools\PdfUploadTool\1.0.2.2" (
    echo       Already exists, skipping.
) else (
    powershell -NoProfile -Command "Expand-Archive -Path '%REPO_DIR%Tools\PdfUploadTool.zip' -DestinationPath 'C:\tools\PdfUploadTool' -Force" >nul 2>&1
    if exist "C:\tools\PdfUploadTool\1.0.2.2" (
        echo       OK
    ) else (
        echo       ERROR: Failed to extract PdfUploadTool.zip
        set /a ERRORS+=1
    )
)

:: ----------------------------------------------------------
:: 16. Extract Posting Tool
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Extracting Posting Tool to C:\tools\PostingTool...
powershell -NoProfile -Command "Expand-Archive -Path '%REPO_DIR%Tools\PostingTool.zip' -DestinationPath 'C:\tools\PostingTool' -Force" >nul 2>&1
if exist "C:\tools\PostingTool\XMLPostingTool.exe" (
    echo       OK
) else (
    echo       ERROR: Failed to extract PostingTool.zip
    set /a ERRORS+=1
)

:: ----------------------------------------------------------
:: 17. Install AWS VPN Client
:: ----------------------------------------------------------
set /a STEP+=1
echo.
echo [%STEP%] Checking AWS VPN Client...
if "!HAS_WINGET!"=="1" (
    winget list --id Amazon.AWSVPNClient >nul 2>&1
    if !errorlevel! neq 0 (
        echo       Installing AWS VPN Client...
        winget install --id Amazon.AWSVPNClient -e --accept-source-agreements --accept-package-agreements
    ) else (
        echo       Already installed.
    )
) else (
    echo       SKIP: Install AWS VPN Client manually from https://aws.amazon.com/vpn/client-vpn-download/
)

:: ----------------------------------------------------------
:: Summary
:: ----------------------------------------------------------
echo.
echo ============================================================
if %ERRORS% equ 0 (
    echo  Done. All automated steps completed.
) else (
    echo  Done with %ERRORS% error^(s^). Check output above.
)
echo ============================================================
echo.
echo  YOU STILL NEED TO DO THESE MANUALLY:
echo.
echo    1. machine.config — update ^<loginid^> with your username
echo.
echo    2. Configure JFrog NuGet source
echo       nuget.exe is already in C:\tools ^(downloaded by this script^).
echo       Sign in at https://traderca.jfrog.io with SAML SSO
echo       Generate API key, then run:
echo       nuget source add -Name "dtncan-nuget-local" ^
echo         -Source "https://traderca.jfrog.io/artifactory/api/nuget/v3/dtncan-nuget-local" ^
echo         -Username YOUR_EMAIL -Password YOUR_API_KEY
echo.
echo    3. VPN — import profiles from the self-service portal
echo       https://self-service.clientvpn.amazonaws.com/
echo.
echo    4. Build in Visual Studio
echo       Open DTN.Core.Base in Visual Studio as Admin and build.
echo       If that works, your setup is good.
echo.
pause
