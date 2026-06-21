#!/usr/bin/env python3
"""
WinDBG Hacker Theme Generator  (structure-aware edition)
Converts dark.wew / dark.reg to Matrix Green hacker palette.

The WDWS workspace binary embeds color entries with this exact header:
    [ID_LO] [ID_HI]  02 00  10 00  04 00  [R] [G] [B] 00  00 00 00 00
Only bytes at those offsets are patched — no false positives on binary data.

Usage:
    python patch_theme.py                      # dark.wew -> hacker.wew (same dir)
    python patch_theme.py in.wew out.wew
    python patch_theme.py in.reg  out.reg
"""

import sys
import os

# ---------------------------------------------------------------------------
# HACKER COLOR PALETTE  (R, G, B)  →  (R, G, B)
#
# Design goals:
#   • Pure black background (nền đen)
#   • Softer terminal green — not blinding (P39 phosphor CRT style)
#   • High contrast for important elements (addresses, errors, changed regs)
# ---------------------------------------------------------------------------

COLOR_MAP = {
    # ── Backgrounds → PURE BLACK ─────────────────────────────────────────────
    (0x19, 0x19, 0x19): (0x00, 0x00, 0x00),  # dark bg       → #000000 pure black
    (0x52, 0x54, 0x58): (0x00, 0x40, 0x00),  # panel color   → #004000 dim green panel

    # ── Primary text → SOFT TERMINAL GREEN ───────────────────────────────────
    # CRT P39 phosphor green sits around #00B800. Not blinding, very readable.
    (0xCF, 0xCE, 0x9A): (0x00, 0xB8, 0x00),  # main text     → #00B800 CRT green
    (0xF8, 0xF8, 0xF8): (0x00, 0xE0, 0x00),  # highlight     → #00E000 brighter green
    (0x6F, 0x6D, 0x7E): (0x00, 0x88, 0x00),  # secondary     → #008800 medium green
    (0x75, 0xA6, 0x87): (0x00, 0x77, 0x00),  # tertiary      → #007700 dim green
    (0x00, 0xFF, 0x80): (0x00, 0xB8, 0x00),  # spring green  → #00B800

    # ── Addresses / Pointers → SOFTER CYAN ───────────────────────────────────
    (0x33, 0x99, 0xFF): (0x00, 0xCC, 0xCC),  # blue          → #00CCCC teal
    (0xAF, 0xC4, 0xDB): (0x00, 0xAA, 0xBB),  # light blue    → #00AABB
    (0x75, 0x87, 0xA6): (0x00, 0x99, 0xAA),  # blue-gray     → #0099AA

    # ── Values / Numbers → AMBER / GOLD ──────────────────────────────────────
    (0xCF, 0x69, 0x4B): (0xFF, 0x99, 0x00),  # salmon        → #FF9900 amber
    (0xCD, 0xA8, 0x69): (0xFF, 0xCC, 0x00),  # gold          → #FFCC00 gold
    (0xD2, 0xD2, 0x3A): (0xFF, 0xCC, 0x00),  # yellow-green  → #FFCC00
    (0xFF, 0xFF, 0x00): (0xFF, 0xCC, 0x00),  # yellow        → #FFCC00 gold

    # ── Errors / Alerts → RED ────────────────────────────────────────────────
    (0x80, 0x31, 0x3A): (0xFF, 0x33, 0x33),  # dark red      → #FF3333
    (0xE6, 0x1E, 0x3C): (0xFF, 0x00, 0x55),  # crimson       → #FF0055
}

# Black entries in color slots are structurally ambiguous (FG or BG).
# Odd-numbered color IDs are backgrounds  → keep pure black
# Even-numbered color IDs may be foreground → use dim green so text stays readable
# (Only affects IDs 0x0000 which is workspace BG-ish; all others mapped above)
BLACK_EVEN_ID = (0x00, 0x30, 0x00)  # #003000 — barely visible as FG, invisible as BG
BLACK_ODD_ID  = (0x00, 0x00, 0x00)  # #000000 — pure black (confirmed backgrounds)


# ---------------------------------------------------------------------------
# WDWS structure-aware scanner
# Each color entry has header:  [ID_LO][ID_HI] 02 00 10 00 04 00
# followed by:                  [R][G][B] 00  00 00 00 00
# ---------------------------------------------------------------------------

ENTRY_HEADER = bytes([0x02, 0x00, 0x10, 0x00, 0x04, 0x00])

def find_color_entries(data: bytearray):
    """Return list of (color_byte_offset, color_id, r, g, b) for every WDWS color entry."""
    entries = []
    for i in range(len(data) - 12):
        if data[i + 2: i + 8] == ENTRY_HEADER:
            cid = (data[i + 1] << 8) | data[i]
            r, g, b, a = data[i + 8], data[i + 9], data[i + 10], data[i + 11]
            if a == 0x00:
                entries.append((i + 8, cid, r, g, b))   # i+8 = offset of R byte
    return entries


# ---------------------------------------------------------------------------
# .wew binary patcher
# ---------------------------------------------------------------------------

def patch_wew(src: str, dst: str) -> int:
    with open(src, 'rb') as f:
        data = bytearray(f.read())

    entries = find_color_entries(data)
    replaced = 0

    for color_off, cid, r, g, b in entries:
        if (r, g, b) in COLOR_MAP:
            nr, ng, nb = COLOR_MAP[(r, g, b)]
        elif r == 0 and g == 0 and b == 0:
            # Black in a color slot — odd IDs are backgrounds (keep black),
            # even IDs may be foreground text (use dim green to stay visible)
            nr, ng, nb = BLACK_ODD_ID if (cid % 2 == 1) else BLACK_EVEN_ID
        else:
            continue

        if (nr, ng, nb) != (r, g, b):
            data[color_off    ] = nr
            data[color_off + 1] = ng
            data[color_off + 2] = nb
            replaced += 1

    with open(dst, 'wb') as f:
        f.write(bytes(data))
    return replaced


# ---------------------------------------------------------------------------
# .reg patcher  (UTF-16 LE, text-based hex: values)
# ---------------------------------------------------------------------------

def patch_reg(src: str, dst: str) -> int:
    with open(src, 'rb') as f:
        raw = f.read()

    bom = b''
    if raw[:2] == b'\xff\xfe':
        bom = b'\xff\xfe'
        text = raw[2:].decode('utf-16-le')
    else:
        text = raw.decode('utf-16-le', errors='replace')

    replaced = 0
    full_map = dict(COLOR_MAP)
    full_map[(0x00, 0x00, 0x00)] = BLACK_EVEN_ID   # in .reg can't tell FG/BG parity — use dim green (safe)

    for (old_r, old_g, old_b), (new_r, new_g, new_b) in full_map.items():
        if (old_r, old_g, old_b) == (new_r, new_g, new_b):
            continue
        for fmt in ('{:02X},{:02X},{:02X},00', '{:02x},{:02x},{:02x},00'):
            old_hex = fmt.format(old_r, old_g, old_b)
            new_hex = '{:02X},{:02X},{:02X},00'.format(new_r, new_g, new_b)
            if old_hex in text:
                text = text.replace(old_hex, new_hex)
                replaced += 1

    with open(dst, 'wb') as f:
        f.write(bom + text.encode('utf-16-le'))
    return replaced


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    if len(sys.argv) == 3:
        src, dst = sys.argv[1], sys.argv[2]
    elif len(sys.argv) == 1:
        src = os.path.join(script_dir, 'dark.wew')
        dst = os.path.join(script_dir, 'hacker.wew')
    else:
        print('Usage: patch_theme.py [input.wew|input.reg] [output.wew|output.reg]')
        sys.exit(1)

    if not os.path.exists(src):
        print(f'[X] File not found: {src}')
        sys.exit(1)

    ext = os.path.splitext(src)[1].lower()
    print(f'[*] Input  : {src}')
    print(f'[*] Output : {dst}')

    if ext == '.wew':
        n = patch_wew(src, dst)
        print(f'[+] Patched {n} color entries in .wew  (structure-aware)')

        reg_src = os.path.join(script_dir, 'dark.reg')
        reg_dst = os.path.join(script_dir, 'hacker.reg')
        if os.path.exists(reg_src):
            n2 = patch_reg(reg_src, reg_dst)
            print(f'[+] Also generated hacker.reg ({n2} replacements)')

    elif ext == '.reg':
        n = patch_reg(src, dst)
        print(f'[+] Patched {n} color entries in .reg')
    else:
        print(f'[X] Unsupported file type: {ext}')
        sys.exit(1)

    print('[+] Done. Launch via hacker.bat')


if __name__ == '__main__':
    main()
