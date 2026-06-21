# WinDBG Hacker Theme

A Matrix-green WinDBG theme with an auto-launching batch script, structured init script, and a binary patcher that converts the stock dark workspace into a hacker-aesthetic color scheme.

![WinDBG Hacker Theme](windbg.png)

---

## Features

- **Pure black background** with P39 phosphor CRT-green text — easy on the eyes, no eye-burn
- **Color-coded output**: teal for addresses, amber/gold for values, red for errors
- **Auto-detect WinDBG** on any drive (x64 by default, `/32` flag for x86)
- **Auto symbol download** via Microsoft public symbol server into `C:\Symbols`
- **Rich init script** — callstack aliases, dashboard panel, auto-display on every break event
- **Structure-aware patcher** — only modifies real color entries in the `.wew` binary, no false positives

---

## Requirements

- Windows 10 / 11
- WinDBG (WDK 10 or later) — installed anywhere on C:, D:, or E:
- Python 3 (only needed to regenerate `hacker.wew` if you delete it)

---

## Quick Start

```bat
hacker.bat
```

That's it. The script:
1. Detects WinDBG automatically
2. Generates `hacker.wew` from `dark.wew` on first run (requires Python)
3. Sets Microsoft symbol server path
4. Loads the init script with all aliases
5. Opens WinDBG with the hacker theme applied

---

## Usage

```
hacker.bat [/32 | /64] [windbg arguments...]
```

| Command | Description |
|---|---|
| `hacker.bat` | Open WinDBG x64, empty session |
| `hacker.bat /32` | Open WinDBG x86 |
| `hacker.bat -pn notepad.exe` | Attach to process by name |
| `hacker.bat -p 1234` | Attach to process by PID |
| `hacker.bat -z crash.dmp` | Open a crash dump |
| `hacker.bat -z crash.dmp /32` | Open a 32-bit crash dump |
| `hacker.bat -k com:port=COM1,baud=115200` | Kernel debugging over serial |
| `hacker.bat -premote npipe:pipe=dbg` | Remote debugging |

### Custom symbol path

Set `SYMBOL_LOCAL` before launching to prepend a local `.pdb` folder:

```bat
set SYMBOL_LOCAL=C:\MyProject\bin
hacker.bat -pn myapp.exe
```

### Source stepping

```bat
set SRC_PATH=C:\MyProject\src
hacker.bat -pn myapp.exe
```

---

## WinDBG Commands (from init script)

Once WinDBG is open, type any alias directly in the command window.

### Dashboard

| Command | Description |
|---|---|
| `dash` | Full panel view: registers + call stack + disassembly + stack memory + threads + modules |
| `ctx` | Alias for `dash` |

### Call Stack

| Command | Description |
|---|---|
| `stk` | Numbered frames — `kn 30` |
| `stkf` | With parameters — `kP 25` |
| `stkv` | With frame locals — `kv 25` |
| `stkc` | Compact one-liner per frame — `kc 40` |
| `stka` | All threads call stack |
| `stkm` | Raw stack memory — `dps rsp L40` |

### Registers

| Command | Description |
|---|---|
| `regs` | All registers |
| `regs32` | x86 registers (eax, ebx, ..., efl) |
| `regs64` | x64 registers (rax, rbx, ..., rflags) |

### Disassembly

| Command | Description |
|---|---|
| `da` | Disassemble forward from `rip` — 20 instructions |
| `dab` | Disassemble backward from `rip` — 10 instructions |
| `daf` | Disassemble entire current function |

### Exception / SEH

| Command | Description |
|---|---|
| `xcpt` | Show exception record |
| `xcptctx` | Exception record + context record + registers |
| `seh` | Walk SEH chain — `!exchain` |
| `xcptall` | All of the above combined |

### Process / Thread

| Command | Description |
|---|---|
| `threads` | List all threads |
| `thall` | Call stack for every thread |
| `peb` | Display PEB |
| `teb` | Display TEB |

### Modules / Symbols

| Command | Description |
|---|---|
| `mods` | List loaded modules |
| `modsv` | Verbose module list with paths and versions |
| `sym` | Symbol lookup — `x` (e.g. `sym ntdll!*Alloc*`) |
| `reload` | Force reload symbols — `.reload /f` |

### Heap

| Command | Description |
|---|---|
| `heaps` | Heap summary |
| `heapv` | Verbose heap — all allocations |
| `heapl` | Heap leak detection |

### PE Header

| Command | Description |
|---|---|
| `pehdr` | PE flags and headers — `!dh -f` |
| `iat` | Import address table |
| `eat` | Export address table |

### Exploit / Reverse Engineering

| Command | Description |
|---|---|
| `rop32` | Search for RET gadgets (32-bit) |
| `rop64` | Search for RET gadgets (64-bit) |
| `cookie` | Read stack canary value from PEB |
| `safeseh` | Check SafeSEH status — `!safeseh` |
| `vainfo` | Virtual memory info — `!address` |
| `prot` | Page protection — `!vprot` |
| `chain` | Dereference pointer — `? poi(addr)` |

### Auto-display on Break Events

The init script attaches handlers that automatically print registers + call stack + disassembly whenever these events fire:

| Event | Trigger |
|---|---|
| `ibp` | Initial break on attach or launch |
| `av` | Access violation (+ fault address info) |
| `ii` | Illegal instruction |
| `sov` | Stack overflow (+ raw stack memory) |
| `bpe` | Any breakpoint hit |

---

## Regenerating the Theme

If you delete `hacker.wew` it will be recreated automatically on next launch. To regenerate manually:

```bat
python patch_theme.py
```

Or specify custom input/output:

```bat
python patch_theme.py dark.wew my_theme.wew
```

The patcher scans the `.wew` binary using the WDWS color-entry header signature (`02 00 10 00 04 00`) so it only modifies real color slots — no false positives on other binary data.

### Color palette

| Role | Color |
|---|---|
| Background | `#000000` pure black |
| Primary text | `#00B800` P39 phosphor green |
| Highlight text | `#00E000` bright green |
| Addresses / pointers | `#00CCCC` teal |
| Values / numbers | `#FF9900` amber · `#FFCC00` gold |
| Errors | `#FF3333` red |
| Panel accent | `#004000` dim green |

---

## Saving a Custom Window Layout

WinDBG classic does not support opening windows (Registers, Call Stack, Locals, etc.) via commands. To save a layout:

1. Launch `hacker.bat`
2. Open the windows you want via the **View** menu
3. Arrange them how you like
4. Go to **File → Save Workspace**

WinDBG writes the layout back into `hacker.wew`. Next launch will restore it automatically via `-WF hacker.wew`.

---

## Files

| File | Description |
|---|---|
| `hacker.bat` | Launcher — auto-detect WinDBG, set symbols, load theme + init |
| `hacker.wew` | Patched workspace file (colors + layout) |
| `hacker.reg` | Registry import alternative for colors |
| `hacker_init.wds` | WinDBG init script — aliases, event handlers, banner |
| `patch_theme.py` | Generates `hacker.wew` / `hacker.reg` from `dark.wew` / `dark.reg` |
| `dark.wew` | Original dark theme (source, unmodified) |
