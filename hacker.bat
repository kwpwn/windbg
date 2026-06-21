@echo off
setlocal enabledelayedexpansion

REM =====================================================================
REM  HACKER WinDBG Launcher  v3
REM  Matrix Green Theme  ::  Auto x86/x64 Detection
REM
REM  Usage:
REM    hacker.bat                         auto-detect arch, open empty
REM    hacker.bat /32                     force x86 WinDBG
REM    hacker.bat /64                     force x64 WinDBG
REM    hacker.bat -pn notepad.exe         attach by process name
REM    hacker.bat -p 1234                 attach by PID
REM    hacker.bat -z crash.dmp            open dump file
REM    hacker.bat -z crash.dmp /32        open 32-bit dump
REM    hacker.bat -k com:port=COM1,baud=115200   kernel debug
REM    hacker.bat -premote npipe:pipe=dbg        remote debug
REM =====================================================================

title H4CK3R :: WinDBG

REM --- Enable ANSI VT100 colors (Windows 10 v1511+) ---
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "GRN=!ESC![38;2;0;184;0m"
set "BRT=!ESC![38;2;0;224;0m"
set "CYN=!ESC![38;2;0;204;204m"
set "YLW=!ESC![38;2;255;204;0m"
set "RED=!ESC![38;2;255;51;51m"
set "DIM=!ESC![38;2;0;80;0m"
set "WHT=!ESC![97m"
set "RST=!ESC![0m"

cls

echo !GRN!
echo  =========================================================================
echo    __  __     _     __  _  _  ____  ____     __    __  __ ____   ____
echo   ^|  \/  ^|   / \   ^|__^^|  \^| ^| ^|  _ \^| __ ^)   ^/ ^^\ ^\ / /^|  _ \ / ___^|
echo   ^| ^|\/^| ^|  / _ \  ^|  ^^^| ^|\  ^| ^|_^| ^| __/   / __ \ V / ^|^| ^|_^| ^| ^|  _
echo   ^|_^|  ^|_^| /_/ \_\ ^|__^^^|_^| \_^|\____/^|_^|    /_/  \_^|_^|  ^|____/ \____^|
echo
echo     W i n D B G   ::   M A T R I X   H A C K E R   T H E M E   v 3
echo  =========================================================================
echo !RST!

REM -----------------------------------------------------------------------
REM  Parse /32 or /64 flag (strip from args passed to WinDBG)
REM -----------------------------------------------------------------------
set "ARCH=64"
set "EXTRA_ARGS="

:parse_args
if "%~1"=="" goto :done_parse
if /i "%~1"=="/32" (
    set "ARCH=32"
    shift
    goto :parse_args
)
if /i "%~1"=="/64" (
    set "ARCH=64"
    shift
    goto :parse_args
)
REM  Accumulate remaining args to pass to WinDBG
if defined EXTRA_ARGS (
    set "EXTRA_ARGS=!EXTRA_ARGS! %~1"
) else (
    set "EXTRA_ARGS=%~1"
)
shift
goto :parse_args
:done_parse

REM -----------------------------------------------------------------------
REM  Auto-detect WinDBG x64 paths (latest SDK first)
REM -----------------------------------------------------------------------
set "WINDBG64="
set "WINDBG32="

REM  WDK/SDK 10  (most common — installed via VS workload or standalone SDK)
if exist "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe" (
    set "WINDBG64=C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe"
    set "WINDBG32=C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\windbg.exe"
)
if exist "C:\Program Files\Windows Kits\10\Debuggers\x64\windbg.exe" (
    set "WINDBG64=C:\Program Files\Windows Kits\10\Debuggers\x64\windbg.exe"
    set "WINDBG32=C:\Program Files\Windows Kits\10\Debuggers\x86\windbg.exe"
)

REM  WDK 8.1
if not defined WINDBG64 (
    if exist "C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x64\windbg.exe" (
        set "WINDBG64=C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x64\windbg.exe"
        set "WINDBG32=C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x86\windbg.exe"
    )
)

REM  WDK 8.0
if not defined WINDBG64 (
    if exist "C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x64\windbg.exe" (
        set "WINDBG64=C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x64\windbg.exe"
        set "WINDBG32=C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x86\windbg.exe"
    )
)

REM  WinDDK 7.x (legacy)
if not defined WINDBG64 (
    if exist "C:\WinDDK\7600.16385.1\Debuggers\windbg.exe" (
        set "WINDBG64=C:\WinDDK\7600.16385.1\Debuggers\windbg.exe"
        set "WINDBG32=C:\WinDDK\7600.16385.1\Debuggers\windbg.exe"
    )
)

REM  E: drive WDK (non-default install location)
if not defined WINDBG64 (
    if exist "E:\Windows Kits\10\Debuggers\x64\windbg.exe" (
        set "WINDBG64=E:\Windows Kits\10\Debuggers\x64\windbg.exe"
        set "WINDBG32=E:\Windows Kits\10\Debuggers\x86\windbg.exe"
    )
)

REM  D: drive WDK
if not defined WINDBG64 (
    if exist "D:\Windows Kits\10\Debuggers\x64\windbg.exe" (
        set "WINDBG64=D:\Windows Kits\10\Debuggers\x64\windbg.exe"
        set "WINDBG32=D:\Windows Kits\10\Debuggers\x86\windbg.exe"
    )
)

REM  Custom install locations
if not defined WINDBG64 (
    if exist "C:\Debuggers\x64\windbg.exe" (
        set "WINDBG64=C:\Debuggers\x64\windbg.exe"
        set "WINDBG32=C:\Debuggers\x86\windbg.exe"
    )
    if exist "C:\Debuggers\windbg.exe" (
        set "WINDBG64=C:\Debuggers\windbg.exe"
        set "WINDBG32=C:\Debuggers\windbg.exe"
    )
)

REM -----------------------------------------------------------------------
REM  Select x86 or x64 based on /32 /64 flag
REM -----------------------------------------------------------------------
if "!ARCH!"=="32" (
    if defined WINDBG32 (
        if exist "!WINDBG32!" (
            set "WINDBG=!WINDBG32!"
        ) else (
            echo !YLW! [*] x86 WinDBG not found at expected path — trying PATH!RST!
            set "WINDBG=windbg.exe"
        )
    ) else (
        echo !YLW! [*] No WinDBG found — trying PATH!RST!
        set "WINDBG=windbg.exe"
    )
) else (
    if defined WINDBG64 (
        set "WINDBG=!WINDBG64!"
    ) else (
        echo !YLW! [*] WinDBG not found in standard paths — trying PATH!RST!
        set "WINDBG=windbg.exe"
    )
)

echo !CYN! [+] Arch     :!RST! x!ARCH!
echo !CYN! [+] WinDBG   :!RST! !WINDBG!

REM -----------------------------------------------------------------------
REM  Script directory and theme file
REM -----------------------------------------------------------------------
set "DIR=%~dp0"
set "THEME=!DIR!hacker.wew"

REM -----------------------------------------------------------------------
REM  Generate hacker.wew on first run using patch_theme.py
REM -----------------------------------------------------------------------
if not exist "!THEME!" (
    echo !YLW! [*] hacker.wew not found — generating from dark.wew ...!RST!
    if exist "!DIR!patch_theme.py" (
        python "!DIR!patch_theme.py" "!DIR!dark.wew" "!THEME!"
        if errorlevel 1 (
            echo !RED! [X] Theme generation failed. Falling back to dark.wew!RST!
            set "THEME=!DIR!dark.wew"
        ) else (
            echo !BRT! [+] hacker.wew created!RST!
        )
    ) else (
        echo !YLW! [*] patch_theme.py not found — using dark.wew!RST!
        set "THEME=!DIR!dark.wew"
    )
)

echo !CYN! [+] Theme    :!RST! !THEME!

REM -----------------------------------------------------------------------
REM  Symbol path
REM  Priority: env var already set  >  default MS symbol server
REM  Local cache: C:\Symbols  (created automatically by symchk/WinDBG)
REM -----------------------------------------------------------------------
if not defined _NT_SYMBOL_PATH (
    set "_NT_SYMBOL_PATH=srv*C:\Symbols*https://msdl.microsoft.com/download/symbols"
)
REM  Also add any local .pdb folders if SYMBOL_LOCAL is set
if defined SYMBOL_LOCAL (
    set "_NT_SYMBOL_PATH=!SYMBOL_LOCAL!;!_NT_SYMBOL_PATH!"
)

echo !CYN! [+] Symbols  :!RST! !_NT_SYMBOL_PATH!

REM -----------------------------------------------------------------------
REM  Source path (optional — set SRC_PATH env to enable source stepping)
REM -----------------------------------------------------------------------
set "SRC_FLAG="
if defined SRC_PATH (
    set "SRC_FLAG=-srcpath "!SRC_PATH!""
    echo !CYN! [+] Sources  :!RST! !SRC_PATH!
)

REM -----------------------------------------------------------------------
REM  Init script (hacker_init.wds) — auto-loaded on startup
REM -----------------------------------------------------------------------
set "INIT_SCRIPT=!DIR!hacker_init.wds"
if exist "!INIT_SCRIPT!" (
    echo !CYN! [+] Init     :!RST! !INIT_SCRIPT!
    set "INIT_CMD=$<\"!INIT_SCRIPT!\""
) else (
    echo !YLW! [*] Init script not found — skipping!RST!
    set "INIT_CMD=.echo [H4CK3R] No init script found"
)

REM -----------------------------------------------------------------------
REM  Optional extensions  (uncomment to auto-load)
REM -----------------------------------------------------------------------

REM  pykd (Python scripting in WinDBG)
REM set "PYKD_64=C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\winext\pykd.dll"
REM set "PYKD_32=C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\winext\pykd.dll"
REM if "!ARCH!"=="64" (
REM     if exist "!PYKD_64!" set "INIT_CMD=.load \"!PYKD_64!\"; !INIT_CMD!"
REM ) else (
REM     if exist "!PYKD_32!" set "INIT_CMD=.load \"!PYKD_32!\"; !INIT_CMD!"
REM )

REM  MEX (Microsoft Extension for productivity)
REM set "MEX=C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\winext\mex.dll"
REM if exist "!MEX!" set "INIT_CMD=.load \"!MEX!\"; !INIT_CMD!"

REM -----------------------------------------------------------------------
REM  Explicit symbol path flag (supplements env var, ensures WinDBG picks it up)
REM -----------------------------------------------------------------------
set "SYM_FLAG=-y "!_NT_SYMBOL_PATH!""

REM -----------------------------------------------------------------------
REM  Final WinDBG command line
REM
REM    -hd          hide debugger from IsDebuggerPresent
REM    -WF <file>   load workspace (colors + window layout)
REM    -Q           suppress workspace save/restore dialog
REM    -y <syms>    symbol search path
REM    -c <cmd>     run command on first break (loads init script)
REM    -srcpath     source file search path (if SRC_PATH set)
REM -----------------------------------------------------------------------
set "WINDBG_FLAGS=-hd -Q -WF "!THEME!" !SYM_FLAG! !SRC_FLAG! -c "!INIT_CMD!""

echo !GRN!
echo  [+] Breach initiated. Happy hunting, hacker.
echo !RST!
echo !DIM! x!ARCH! :: "!WINDBG!" -hd -Q -WF [theme] -y [syms] -c [init] !EXTRA_ARGS!!RST!
echo.

"!WINDBG!" !WINDBG_FLAGS! !EXTRA_ARGS!
