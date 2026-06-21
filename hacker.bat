@echo off
setlocal enabledelayedexpansion

REM =====================================================================
REM  HACKER WinDBG Launcher  v4
REM  Matrix Green Theme  ::  Auto x86/x64  ::  mona3 Integration
REM
REM  Usage:
REM    hacker.bat                         auto x64, open empty
REM    hacker.bat /32                     force x86 WinDBG
REM    hacker.bat /64                     force x64 WinDBG (default)
REM    hacker.bat /preview                WinDBG Preview (windbgx.exe)
REM    hacker.bat -pn notepad.exe         attach by process name
REM    hacker.bat -p 1234                 attach by PID
REM    hacker.bat /32 -pn target.exe      x86 attach by name
REM    hacker.bat -z crash.dmp            open dump  (then type: analyze)
REM    hacker.bat -z crash.dmp /32        open 32-bit dump
REM    hacker.bat -k com:port=COM1,baud=115200   kernel debug
REM    hacker.bat -premote npipe:pipe=dbg        remote debug
REM
REM  Environment variables (set before launch):
REM    SYMBOL_LOCAL=C:\MyProj\bin         prepend local .pdb folder
REM    SRC_PATH=C:\MyProj\src             enable source stepping
REM =====================================================================

title H4CK3R :: WinDBG

REM --- Enable ANSI VT100 colors ---
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "GRN=!ESC![38;2;0;184;0m"
set "BRT=!ESC![38;2;0;224;0m"
set "CYN=!ESC![38;2;0;204;204m"
set "YLW=!ESC![38;2;255;204;0m"
set "RED=!ESC![38;2;255;51;51m"
set "DIM=!ESC![38;2;0;80;0m"
set "RST=!ESC![0m"

cls

echo !GRN!
echo  =========================================================================
echo    __  __     _     __  _  _  ____  ____     __    __  __ ____   ____
echo   ^|  \/  ^|   / \   ^|__^^|  \^| ^| ^|  _ \^| __ ^)   ^/ ^^\ ^\ / /^|  _ \ / ___^|
echo   ^| ^|\/^| ^|  / _ \  ^|  ^^^| ^|\  ^| ^|_^| ^| __/   / __ \ V / ^|^| ^|_^| ^| ^|  _
echo   ^|_^|  ^|_^| /_/ \_\ ^|__^^^|_^| \_^|\____/^|_^|    /_/  \_^|_^|  ^|____/ \____^|
echo
echo     W i n D B G   ::   M A T R I X   H A C K E R   T H E M E   v 4
echo  =========================================================================
echo !RST!

REM -----------------------------------------------------------------------
REM  Parse flags: /32  /64  /preview  (strip from WinDBG args)
REM -----------------------------------------------------------------------
set "ARCH=64"
set "PREVIEW_MODE=0"
set "EXTRA_ARGS="

:parse_args
if "%~1"=="" goto :done_parse
if /i "%~1"=="/32"      ( set "ARCH=32"      & shift & goto :parse_args )
if /i "%~1"=="/64"      ( set "ARCH=64"      & shift & goto :parse_args )
if /i "%~1"=="/preview" ( set "PREVIEW_MODE=1" & shift & goto :parse_args )
if defined EXTRA_ARGS (
    set "EXTRA_ARGS=!EXTRA_ARGS! %~1"
) else (
    set "EXTRA_ARGS=%~1"
)
shift
goto :parse_args
:done_parse

REM -----------------------------------------------------------------------
REM  Script directory
REM -----------------------------------------------------------------------
set "DIR=%~dp0"

REM -----------------------------------------------------------------------
REM  WinDBG Preview mode  (/preview)
REM  Preview does not support -WF / -hd / -c — launch with symbols only
REM -----------------------------------------------------------------------
if "!PREVIEW_MODE!"=="1" (
    set "WINDBG_PREVIEW="
    if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\WinDbgX.exe" (
        set "WINDBG_PREVIEW=%LOCALAPPDATA%\Microsoft\WindowsApps\WinDbgX.exe"
    )
    for /d %%d in ("%ProgramFiles%\WindowsApps\Microsoft.WinDbg_*") do (
        if exist "%%d\DbgX.Shell.exe" set "WINDBG_PREVIEW=%%d\DbgX.Shell.exe"
    )
    if not defined WINDBG_PREVIEW (
        echo !RED! [X] WinDBG Preview not found. Install from Microsoft Store.!RST!
        pause
        exit /b 1
    )
    echo !CYN! [+] Mode     :!RST! WinDBG Preview
    echo !CYN! [+] Preview  :!RST! !WINDBG_PREVIEW!
    if not defined _NT_SYMBOL_PATH (
        set "_NT_SYMBOL_PATH=srv*C:\Symbols*https://msdl.microsoft.com/download/symbols"
    )
    if defined SYMBOL_LOCAL set "_NT_SYMBOL_PATH=!SYMBOL_LOCAL!;!_NT_SYMBOL_PATH!"
    echo !CYN! [+] Symbols  :!RST! !_NT_SYMBOL_PATH!
    echo !GRN!
    echo  [+] Launching WinDBG Preview...
    echo !RST!
    "!WINDBG_PREVIEW!" -y "!_NT_SYMBOL_PATH!" !EXTRA_ARGS!
    exit /b
)

REM -----------------------------------------------------------------------
REM  Auto-detect WinDBG classic  (x64 + x86, all common locations)
REM -----------------------------------------------------------------------
set "WINDBG64="
set "WINDBG32="

REM  C: standard SDK/WDK paths (latest first)
if exist "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe" (
    set "WINDBG64=C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe"
    set "WINDBG32=C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\windbg.exe"
)
if exist "C:\Program Files\Windows Kits\10\Debuggers\x64\windbg.exe" (
    set "WINDBG64=C:\Program Files\Windows Kits\10\Debuggers\x64\windbg.exe"
    set "WINDBG32=C:\Program Files\Windows Kits\10\Debuggers\x86\windbg.exe"
)
if not defined WINDBG64 (
    if exist "C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x64\windbg.exe" (
        set "WINDBG64=C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x64\windbg.exe"
        set "WINDBG32=C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x86\windbg.exe"
    )
)
if not defined WINDBG64 (
    if exist "C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x64\windbg.exe" (
        set "WINDBG64=C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x64\windbg.exe"
        set "WINDBG32=C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x86\windbg.exe"
    )
)
REM  E: drive (non-default install)
if not defined WINDBG64 (
    if exist "E:\Windows Kits\10\Debuggers\x64\windbg.exe" (
        set "WINDBG64=E:\Windows Kits\10\Debuggers\x64\windbg.exe"
        set "WINDBG32=E:\Windows Kits\10\Debuggers\x86\windbg.exe"
    )
)
REM  D: drive
if not defined WINDBG64 (
    if exist "D:\Windows Kits\10\Debuggers\x64\windbg.exe" (
        set "WINDBG64=D:\Windows Kits\10\Debuggers\x64\windbg.exe"
        set "WINDBG32=D:\Windows Kits\10\Debuggers\x86\windbg.exe"
    )
)
REM  WinDDK 7.x legacy
if not defined WINDBG64 (
    if exist "C:\WinDDK\7600.16385.1\Debuggers\windbg.exe" (
        set "WINDBG64=C:\WinDDK\7600.16385.1\Debuggers\windbg.exe"
        set "WINDBG32=C:\WinDDK\7600.16385.1\Debuggers\windbg.exe"
    )
)
REM  Custom locations
if not defined WINDBG64 (
    if exist "C:\Debuggers\x64\windbg.exe" (
        set "WINDBG64=C:\Debuggers\x64\windbg.exe"
        set "WINDBG32=C:\Debuggers\x86\windbg.exe"
    )
)

REM  Select arch
if "!ARCH!"=="32" (
    if defined WINDBG32 (
        if exist "!WINDBG32!" ( set "WINDBG=!WINDBG32!" ) else ( set "WINDBG=windbg.exe" )
    ) else ( set "WINDBG=windbg.exe" )
) else (
    if defined WINDBG64 ( set "WINDBG=!WINDBG64!" ) else ( set "WINDBG=windbg.exe" )
)

echo !CYN! [+] Arch     :!RST! x!ARCH!
echo !CYN! [+] WinDBG   :!RST! !WINDBG!

REM -----------------------------------------------------------------------
REM  Theme: generate hacker.wew from dark.wew on first run
REM -----------------------------------------------------------------------
set "THEME=!DIR!hacker.wew"
if not exist "!THEME!" (
    echo !YLW! [*] hacker.wew not found — generating...!RST!
    if exist "!DIR!patch_theme.py" (
        python "!DIR!patch_theme.py" "!DIR!dark.wew" "!THEME!"
        if errorlevel 1 (
            echo !RED! [X] Theme generation failed — falling back to dark.wew!RST!
            set "THEME=!DIR!dark.wew"
        ) else (
            echo !BRT! [+] hacker.wew generated!RST!
        )
    ) else (
        echo !YLW! [*] patch_theme.py not found — using dark.wew!RST!
        set "THEME=!DIR!dark.wew"
    )
)
echo !CYN! [+] Theme    :!RST! !THEME!

REM -----------------------------------------------------------------------
REM  Symbol path
REM -----------------------------------------------------------------------
if not defined _NT_SYMBOL_PATH (
    set "_NT_SYMBOL_PATH=srv*C:\Symbols*https://msdl.microsoft.com/download/symbols"
)
if defined SYMBOL_LOCAL (
    set "_NT_SYMBOL_PATH=!SYMBOL_LOCAL!;!_NT_SYMBOL_PATH!"
)
echo !CYN! [+] Symbols  :!RST! !_NT_SYMBOL_PATH!

REM -----------------------------------------------------------------------
REM  Source path (optional)
REM -----------------------------------------------------------------------
set "SRC_FLAG="
if defined SRC_PATH (
    set "SRC_FLAG=-srcpath "!SRC_PATH!""
    echo !CYN! [+] Sources  :!RST! !SRC_PATH!
)

REM -----------------------------------------------------------------------
REM  mona3 + pykd  (bundled in repo — no internet needed)
REM  mona.py and pykd/ are included. Python must be installed.
REM -----------------------------------------------------------------------
set "MONA_FOUND=0"
if not exist "!DIR!mona.py" (
    echo !DIM! [-] mona3    : mona.py not found!RST!
    goto :skip_mona
)

set "MONA_FOUND=1"
echo !BRT! [+] mona3    :!RST! !DIR!mona.py

REM  Check Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo !YLW! [*] pykd     : Python not found — install Python to use mona3!RST!
    set "MONA_FOUND=0"
    goto :skip_mona
)

REM  Detect Python bitness and minor version
for /f %%b in ('python -c "import struct;print(struct.calcsize(chr(80))*8)"') do set "PY_BITS=%%b"
for /f %%v in ('python -c "import sys;print(str(sys.version_info.major)+chr(46)+str(sys.version_info.minor))"') do set "PY_VER=%%v"

if not "!PY_BITS!"=="!ARCH!" (
    echo !YLW! [*] pykd     : Python is x!PY_BITS! but WinDBG is x!ARCH!!RST!
    echo !YLW!               Tip: use hacker.bat /!PY_BITS! to match your Python!RST!
    set "MONA_FOUND=0"
    goto :skip_mona
)

REM  Try bundled pykd first (pykd\x<arch>\<pyver>\pykd.pyd)
set "PYKD="
set "PYKD_DIR=!DIR!pykd\x!ARCH!"
if exist "!PYKD_DIR!\!PY_VER!\pykd.pyd" (
    set "PYKD=!PYKD_DIR!\!PY_VER!\pykd.pyd"
    echo !CYN! [+] pykd     :!RST! bundled !PY_VER! x!ARCH!
    REM  Add arch DLL dir to PATH so shared DLLs are found by pykd.pyd
    set "PATH=!PYKD_DIR!;!PATH!"
) else (
    REM  Bundled version not available — fall back to pip-installed
    echo !YLW! [*] pykd     : Python !PY_VER! not bundled — checking pip...!RST!
    for /f "delims=" %%p in ('python "!DIR!patch_theme.py" --find-pykd 2^>nul') do set "PYKD=%%p"
    if not defined PYKD (
        echo !YLW! [*] pykd     : not found — running pip install pykd...!RST!
        pip install pykd --quiet
        for /f "delims=" %%p in ('python "!DIR!patch_theme.py" --find-pykd 2^>nul') do set "PYKD=%%p"
    )
    if defined PYKD (
        echo !CYN! [+] pykd     :!RST! pip !PYKD!
    ) else (
        echo !RED! [X] pykd     : could not load pykd — mona3 disabled!RST!
        set "MONA_FOUND=0"
        goto :skip_mona
    )
)

python "!DIR!patch_theme.py" --gen-mona "!PYKD!" >nul 2>&1

:skip_mona

REM -----------------------------------------------------------------------
REM  Build session_init.wds  (chains hacker_init + mona_cfg if present)
REM  This is the master init file passed to WinDBG via -c
REM -----------------------------------------------------------------------
set "SESSION_WDS=!DIR!session_init.wds"
> "!SESSION_WDS!" (
    if exist "!DIR!hacker_init.wds" (
        echo $^<"!DIR!hacker_init.wds"
    ) else (
        echo .echo [H4CK3R] hacker_init.wds not found
    )
    if "!MONA_FOUND!"=="1" (
        if exist "!DIR!mona_cfg.wds" (
            echo $^<"!DIR!mona_cfg.wds"
        )
    )
)

set "INIT_CMD=$<\"!SESSION_WDS!\""
echo !CYN! [+] Init     :!RST! !SESSION_WDS!

REM -----------------------------------------------------------------------
REM  Launch WinDBG
REM    -hd      hide debugger from IsDebuggerPresent
REM    -WF      load workspace file (colors + window layout)
REM    -Q       suppress workspace save/restore dialog
REM    -y       symbol search path
REM    -srcpath source search path
REM    -c       run command on first break (loads init script)
REM -----------------------------------------------------------------------
echo !GRN!
echo  [+] Breach initiated. Happy hunting.
echo !RST!
echo !DIM! x!ARCH! :: "!WINDBG!" -hd -Q -WF [theme] -y [syms] -c [init] !EXTRA_ARGS!!RST!
echo.

"!WINDBG!" -hd -Q -WF "!THEME!" -y "!_NT_SYMBOL_PATH!" !SRC_FLAG! -c "!INIT_CMD!" !EXTRA_ARGS!
