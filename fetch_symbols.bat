@echo off
setlocal enabledelayedexpansion

REM =====================================================================
REM  fetch_symbols.bat  --  Bulk symbol downloader for WinDBG Hacker
REM
REM  Uses symchk.exe (bundled with Windows SDK / WinDBG) to pre-fetch
REM  PDB files for the most common Windows DLLs and EXEs.
REM  Symbols land in .\symbols\ (the repo's local cache).
REM
REM  Run ONCE after cloning to get offline symbol access, or again
REM  after a major Windows update to refresh symbols.
REM
REM  Usage:
REM    fetch_symbols.bat           download all categories
REM    fetch_symbols.bat /quick    core DLLs only  (faster)
REM    fetch_symbols.bat /kernel   include kernel binaries
REM    fetch_symbols.bat /wow64    include WoW64 (SysWOW64) binaries
REM =====================================================================

title HACKER :: Fetch Symbols

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
echo    FETCH SYMBOLS  ::  H4CK3R WinDBG   --  offline pre-cache
echo  =========================================================================
echo !RST!

set "DIR=%~dp0"
set "SYMDIR=!DIR!symbols"
set "SYMPATH=srv*!SYMDIR!*https://msdl.microsoft.com/download/symbols"
set "SYS32=C:\Windows\System32"
set "SYSWOW=C:\Windows\SysWOW64"
set "QUICK=0"
set "DO_KERNEL=0"
set "DO_WOW64=0"

:parse
if "%~1"=="" goto :done_parse
if /i "%~1"=="/quick"  ( set "QUICK=1"    & shift & goto :parse )
if /i "%~1"=="/kernel" ( set "DO_KERNEL=1" & shift & goto :parse )
if /i "%~1"=="/wow64"  ( set "DO_WOW64=1"  & shift & goto :parse )
shift
goto :parse
:done_parse

REM -----------------------------------------------------------------------
REM  Find symchk.exe  (same search order as hacker.bat for windbg.exe)
REM -----------------------------------------------------------------------
set "SYMCHK="
if exist "E:\Windows Kits\10\Debuggers\x64\symchk.exe" (
    set "SYMCHK=E:\Windows Kits\10\Debuggers\x64\symchk.exe"
)
if not defined SYMCHK (
    if exist "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\symchk.exe" (
        set "SYMCHK=C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\symchk.exe"
    )
)
if not defined SYMCHK (
    if exist "C:\Program Files\Windows Kits\10\Debuggers\x64\symchk.exe" (
        set "SYMCHK=C:\Program Files\Windows Kits\10\Debuggers\x64\symchk.exe"
    )
)
if not defined SYMCHK (
    if exist "D:\Windows Kits\10\Debuggers\x64\symchk.exe" (
        set "SYMCHK=D:\Windows Kits\10\Debuggers\x64\symchk.exe"
    )
)
if not defined SYMCHK (
    echo !RED! [X] symchk.exe not found.!RST!
    echo !YLW!     Install Windows SDK from: https://aka.ms/winsdk!RST!
    echo !YLW!     Or WinDBG Preview from the Microsoft Store.!RST!
    pause
    exit /b 1
)

echo !CYN! [+] symchk   :!RST! !SYMCHK!
echo !CYN! [+] symdir   :!RST! !SYMDIR!
echo !CYN! [+] server   :!RST! https://msdl.microsoft.com/download/symbols
echo.

if not exist "!SYMDIR!" mkdir "!SYMDIR!"

set "TOTAL=0"
set "OK=0"
set "FAIL=0"
set "SKIP=0"

REM -----------------------------------------------------------------------
REM  Helper macro: fetch one file
REM  Usage: call :fetch <path_to_binary>
REM -----------------------------------------------------------------------
goto :main

:fetch
set /a TOTAL+=1
set "_F=%~1"
if not exist "!_F!" (
    set /a SKIP+=1
    echo !DIM! [-] skip      : %~nx1!RST!
    exit /b 0
)
echo !CYN! [>] fetching  : %~nx1!RST!
"!SYMCHK!" "!_F!" /s "!SYMPATH!" /q >nul 2>&1
if errorlevel 1 (
    set /a FAIL+=1
    echo !YLW! [!] FAILED    : %~nx1!RST!
) else (
    set /a OK+=1
)
exit /b 0

:main

REM -----------------------------------------------------------------------
REM  Core user-mode DLLs  (always downloaded)
REM -----------------------------------------------------------------------
echo !GRN! [*] Core user-mode (x64)...!RST!
call :fetch "!SYS32!\ntdll.dll"
call :fetch "!SYS32!\kernel32.dll"
call :fetch "!SYS32!\kernelbase.dll"
call :fetch "!SYS32!\user32.dll"
call :fetch "!SYS32!\win32u.dll"
call :fetch "!SYS32!\gdi32.dll"
call :fetch "!SYS32!\gdi32full.dll"
call :fetch "!SYS32!\advapi32.dll"
call :fetch "!SYS32!\sechost.dll"
call :fetch "!SYS32!\msvcrt.dll"
call :fetch "!SYS32!\ucrtbase.dll"
call :fetch "!SYS32!\vcruntime140.dll"
call :fetch "!SYS32!\vcruntime140_1.dll"
call :fetch "!SYS32!\ws2_32.dll"
call :fetch "!SYS32!\mswsock.dll"
call :fetch "!SYS32!\rpcrt4.dll"

if "!QUICK!"=="1" goto :summary

REM -----------------------------------------------------------------------
REM  Extended user-mode  (shell, COM, crypto, security)
REM -----------------------------------------------------------------------
echo !GRN! [*] Extended user-mode (x64)...!RST!
call :fetch "!SYS32!\shell32.dll"
call :fetch "!SYS32!\shlwapi.dll"
call :fetch "!SYS32!\ole32.dll"
call :fetch "!SYS32!\combase.dll"
call :fetch "!SYS32!\oleaut32.dll"
call :fetch "!SYS32!\bcrypt.dll"
call :fetch "!SYS32!\bcryptprimitives.dll"
call :fetch "!SYS32!\crypt32.dll"
call :fetch "!SYS32!\wintrust.dll"
call :fetch "!SYS32!\ntmarta.dll"
call :fetch "!SYS32!\msvcp140.dll"
call :fetch "!SYS32!\msvcr120.dll"
call :fetch "!SYS32!\clbcatq.dll"
call :fetch "!SYS32!\comdlg32.dll"
call :fetch "!SYS32!\netapi32.dll"
call :fetch "!SYS32!\samcli.dll"
call :fetch "!SYS32!\lsasrv.dll"
call :fetch "!SYS32!\sspicli.dll"
call :fetch "!SYS32!\psapi.dll"
call :fetch "!SYS32!\dbghelp.dll"
call :fetch "!SYS32!\dbgeng.dll"
call :fetch "!SYS32!\symsrv.dll"
call :fetch "!SYS32!\wldap32.dll"
call :fetch "!SYS32!\wtsapi32.dll"
call :fetch "!SYS32!\iphlpapi.dll"
call :fetch "!SYS32!\dnsapi.dll"
call :fetch "!SYS32!\winhttp.dll"
call :fetch "!SYS32!\wininet.dll"
call :fetch "!SYS32!\urlmon.dll"
call :fetch "!SYS32!\mshtml.dll"

REM -----------------------------------------------------------------------
REM  WoW64 bridge DLLs  (32-bit emulation layer)
REM -----------------------------------------------------------------------
if "!DO_WOW64!"=="0" goto :skip_wow64
echo !GRN! [*] WoW64 (x86 emulation)...!RST!
call :fetch "!SYS32!\wow64.dll"
call :fetch "!SYS32!\wow64cpu.dll"
call :fetch "!SYS32!\wow64win.dll"
call :fetch "!SYS32!\wow64base.dll"

REM  32-bit user-mode from SysWOW64
call :fetch "!SYSWOW!\ntdll.dll"
call :fetch "!SYSWOW!\kernel32.dll"
call :fetch "!SYSWOW!\kernelbase.dll"
call :fetch "!SYSWOW!\user32.dll"
call :fetch "!SYSWOW!\advapi32.dll"
call :fetch "!SYSWOW!\sechost.dll"
call :fetch "!SYSWOW!\msvcrt.dll"
call :fetch "!SYSWOW!\ucrtbase.dll"
call :fetch "!SYSWOW!\vcruntime140.dll"
call :fetch "!SYSWOW!\ws2_32.dll"
call :fetch "!SYSWOW!\rpcrt4.dll"
call :fetch "!SYSWOW!\shell32.dll"
call :fetch "!SYSWOW!\ole32.dll"
call :fetch "!SYSWOW!\combase.dll"
call :fetch "!SYSWOW!\crypt32.dll"
call :fetch "!SYSWOW!\bcrypt.dll"
:skip_wow64

REM -----------------------------------------------------------------------
REM  Kernel binaries  (need kernel debugging or /kernel flag)
REM -----------------------------------------------------------------------
if "!DO_KERNEL!"=="0" goto :skip_kernel
echo !GRN! [*] Kernel binaries...!RST!
call :fetch "!SYS32!\ntoskrnl.exe"
call :fetch "!SYS32!\hal.dll"
call :fetch "!SYS32!\ci.dll"
call :fetch "!SYS32!\clfs.sys"
call :fetch "!SYS32!\drivers\tcpip.sys"
call :fetch "!SYS32!\drivers\ndis.sys"
call :fetch "!SYS32!\drivers\nt.sys"
:skip_kernel

:summary
echo.
echo !GRN!
echo  =========================================================================
echo   Symbol fetch complete
echo  =========================================================================
echo !RST!
echo !CYN!  Total  : !TOTAL!!RST!
echo !BRT!  OK     : !OK!!RST!
echo !YLW!  Failed : !FAIL!!RST!
echo !DIM!  Skipped: !SKIP!!RST!
echo.
echo !GRN! [+] Symbols cached in: !SYMDIR!!RST!
echo !GRN! [+] WinDBG will use them offline via hacker.bat!RST!
echo.
pause
