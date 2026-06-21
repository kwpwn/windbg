# WinDBG Hacker Theme

A Matrix-green WinDBG theme with an auto-launching batch script, mona3 integration, structured init script, and a binary patcher that converts the stock dark workspace into a hacker-aesthetic color scheme.

![WinDBG Hacker Theme](windbg.png)

---

## Features

- **Pure black background** with P39 phosphor CRT-green text — easy on the eyes
- **Color-coded output**: teal for addresses, amber/gold for values, red for errors
- **Auto-detect WinDBG** on any drive — x64 by default, `/32` for x86, `/preview` for WinDBG Preview
- **Auto symbol download** via Microsoft public symbol server into `C:\Symbols`
- **mona3 integration** — drop `mona.py` in this folder and it loads automatically via pykd
- **Full init script** — callstack aliases, crash analysis, kernel debug, dashboard panel, auto-display on every break event
- **Structure-aware patcher** — only modifies real color entries in the `.wew` binary

---

## Requirements

- Windows 10 / 11
- WinDBG classic (WDK 10 or later) — installed anywhere on C:, D:, or E:
- Python 3 — to generate `hacker.wew` and `mona_cfg.wds`

---

## Quick Start

```bat
hacker.bat
```

The script auto-detects WinDBG, generates the theme on first run, sets the symbol server, and opens WinDBG with the hacker theme.

---

## Usage

```
hacker.bat [/32 | /64 | /preview] [windbg arguments...]
```

| Command | Description |
|---|---|
| `hacker.bat` | Open WinDBG x64 |
| `hacker.bat /32` | Open WinDBG x86 |
| `hacker.bat /preview` | Open WinDBG Preview (windbgx.exe, no theme) |
| `hacker.bat -pn notepad.exe` | Attach by process name |
| `hacker.bat -p 1234` | Attach by PID |
| `hacker.bat /32 -pn target.exe` | x86 attach by name |
| `hacker.bat -z crash.dmp` | Open crash dump (then type: `analyze`) |
| `hacker.bat -z crash.dmp /32` | Open 32-bit crash dump |
| `hacker.bat -k com:port=COM1,baud=115200` | Kernel debug over serial |
| `hacker.bat -premote npipe:pipe=dbg` | Remote debug |

### Custom symbol / source path

```bat
set SYMBOL_LOCAL=C:\MyProject\bin
set SRC_PATH=C:\MyProject\src
hacker.bat -pn myapp.exe
```

---

## mona3 Integration

[mona](https://github.com/corelan/mona) is the industry-standard exploit development plugin for WinDBG.

### Setup

1. **Install pykd** — the Python bridge for WinDBG:
   - Download from [pykd releases](https://githubfast.com/corelan/mona) or `pip install pykd`
   - Place `pykd.dll` in the WDK `winext` folder, or ensure `.load pykd` resolves it

2. **Drop `mona.py`** into this folder (same directory as `hacker.bat`):
   ```
   windbg-theme\
   ├── hacker.bat
   ├── mona.py        ← put it here
   └── ...
   ```

3. **Launch normally** — `hacker.bat` auto-detects `mona.py`, generates `mona_cfg.wds`, and loads pykd + mona on startup.

### mona Commands

| Alias | Command | Description |
|---|---|---|
| `mona <cmd>` | `!py mona.py <cmd>` | Run any mona command |
| `monarop` | `!py mona.py rop` | Find ROP gadgets in all modules |
| `monapat <len>` | `!py mona.py pattern_create <len>` | Create cyclic pattern |
| `monaoff <val>` | `!py mona.py pattern_offset <val>` | Find offset in pattern |
| `monafind <args>` | `!py mona.py find <args>` | Find bytes/strings/pointers |
| `monaseh` | `!py mona.py seh` | Analyze SEH chain |
| `monasug` | `!py mona.py suggest` | Suggest ROP chains (ASLR/DEP bypass) |
| `monamod` | `!py mona.py modules` | Module info (ASLR/SafeSEH/NX/RELRO) |
| `monaheap` | `!py mona.py heap` | Heap analysis |
| `monajop` | `!py mona.py jop` | JOP gadget search |
| `monacmp` | `!py mona.py compare` | Compare memory vs file |
| `monainfo` | `!py mona.py info` | Info about address/module |

Full mona help: type `mona -h` in WinDBG.

---

## WinDBG Commands (init script)

All aliases are loaded automatically at startup.

### Dashboard

| Command | Description |
|---|---|
| `dash` / `ctx` | Full panel: registers + call stack + disasm + stack mem + threads + modules |

### Crash Dump Analysis

| Command | Description |
|---|---|
| `analyze` | `!analyze -v` — automatic crash analysis (use after opening a dump) |
| `analyzeq` | `!analyze` — quick analysis |
| `analyzedmp` | Full report: analyze + stack + memory map + modules |

### Call Stack

| Command | Description |
|---|---|
| `stk` | Numbered frames — `kn 30` |
| `stkf` | With parameters — `kP 25` |
| `stkv` | With frame locals — `kv 25` |
| `stkc` | Compact one-liner — `kc 40` |
| `stka` | All threads call stack |
| `stkm` | Raw stack memory — `dps rsp L40` |

### Registers

| Command | Description |
|---|---|
| `regs` | All registers |
| `regs32` | x86 registers |
| `regs64` | x64 registers |

### Disassembly

| Command | Description |
|---|---|
| `da` | Disassemble forward 20 instructions |
| `dab` | Disassemble backward 10 instructions |
| `daf <addr>` | Disassemble full function (compact) |
| `dafn <addr>` | Disassemble full function (verbose) |

### Exception / SEH

| Command | Description |
|---|---|
| `xcpt` | Exception record |
| `xcptctx` | Exception record + context + registers |
| `seh` | Walk SEH chain |
| `xcptall` | All of the above |

### Process / Thread

| Command | Description |
|---|---|
| `threads` | List threads |
| `thall` | All threads call stack |
| `peb` / `teb` | Display PEB / TEB |
| `handles` | List handles |
| `token` | Process token info |
| `cmdline` | Process command line |

### Module / Symbol

| Command | Description |
|---|---|
| `mods` / `modsv` | Module list (brief / verbose) |
| `sym <pattern>` | Symbol lookup (e.g. `sym ntdll!*Alloc*`) |
| `reload` | Force reload symbols |

### Memory

| Command | Description |
|---|---|
| `memmap` | Memory layout summary — `!address -summary` |
| `vainfo <addr>` | Virtual address info |
| `prot <addr>` | Page protection |

### Heap

| Command | Description |
|---|---|
| `heaps` | Heap summary |
| `heapv` | All allocations |
| `heapl` | Leak detection |

### PE Header

| Command | Description |
|---|---|
| `pehdr <mod>` | PE flags and headers |
| `iat <mod>` | Import address table |
| `eat <mod>` | Export address table |

### Exploit / Reverse Engineering

| Command | Description |
|---|---|
| `cookie` | Find `__security_cookie` in all modules |
| `safeseh` | SafeSEH check — `!safeseh` |
| `rop32` | Search RET gadgets (32-bit address space) |
| `rop64` | Search RET gadgets (64-bit address space) |
| `pat <start> L<len> <bytes>` | Generic byte search |
| `chain <addr>` | Dereference pointer |

### Kernel Debugging

Use with `hacker.bat -k ...` for kernel debug sessions.

| Command | Description |
|---|---|
| `kprocs` | List all processes — `!process 0 0` |
| `kproc <addr>` | Full process info |
| `kthread` | Current kernel thread |
| `krunning` | Running threads per CPU |
| `drvobj <name>` | Driver object |
| `devobj <addr>` | Device object |
| `irp <addr>` | IRP inspection |
| `kobj <addr>` | Kernel object |
| `pool <addr>` | Pool allocation |
| `pte <addr>` | Page table entry |
| `pcr` | Processor control region |
| `locks` | Deadlock detection |
| `cs` | Critical sections holding locks |
| `eproc <addr>` | `dt nt!_EPROCESS` |
| `ethread <addr>` | `dt nt!_ETHREAD` |
| `kmods` | Kernel modules only |
| `irql` | Current IRQL |

### Logging

| Command | Description |
|---|---|
| `logon` | Start logging to `C:\windbg_log.txt` |
| `logadd` | Append to existing log |
| `logoff` | Stop logging |

### Auto-display on Break Events

| Event | Trigger |
|---|---|
| `ibp` | Initial break — registers + stack + disasm |
| `av` | Access violation — exception + regs + stack + fault address |
| `dz` | Divide by zero — regs + stack |
| `gp` | General protection fault — regs + stack + disasm |
| `ii` | Illegal instruction — regs + stack + disasm |
| `sov` | Stack overflow — regs + stack + raw stack memory |
| `eh` | Unhandled C++ exception — exception record + stack |

---

## Regenerating the Theme

Deleted `hacker.wew`? It recreates automatically on next launch. Manual regeneration:

```bat
python patch_theme.py
```

Custom input/output:

```bat
python patch_theme.py dark.wew my_theme.wew
```

### Color Palette

| Role | Color |
|---|---|
| Background | `#000000` pure black |
| Primary text | `#00B800` P39 phosphor green |
| Highlight | `#00E000` bright green |
| Addresses / pointers | `#00CCCC` teal |
| Values / numbers | `#FF9900` amber · `#FFCC00` gold |
| Errors | `#FF3333` red |
| Panel accent | `#004000` dim green |

---

## Saving a Custom Window Layout

WinDBG classic does not open windows programmatically. To save a layout:

1. Launch `hacker.bat`
2. Open windows via **View** menu (Registers, Call Stack, Locals, etc.)
3. Arrange them
4. **File → Save Workspace**

WinDBG writes the layout back into `hacker.wew`. Next launch restores it via `-WF hacker.wew`.

---

## Files

| File | Description |
|---|---|
| `hacker.bat` | Launcher — auto-detect WinDBG, set symbols, load theme + mona |
| `hacker.wew` | Patched workspace (colors + layout) |
| `hacker.reg` | Registry import alternative for colors |
| `hacker_init.wds` | WinDBG init script — all aliases and event handlers |
| `patch_theme.py` | Generates `hacker.wew`, `hacker.reg`, and `mona_cfg.wds` |
| `session_init.wds` | Auto-generated — chains `hacker_init.wds` + `mona_cfg.wds` |
| `mona_cfg.wds` | Auto-generated when `mona.py` is present — pykd loader + mona aliases |
| `dark.wew` | Original dark theme (source, unmodified) |
| `mona.py` | **(not included)** — copy here from mona3 repo to enable mona |
