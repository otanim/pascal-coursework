#!/usr/bin/env python3
"""Convert Pascal sources between UTF-8 and the AK Yerevan Armenian DOS encoding.

usage: akconv.py encode SRC DST   UTF-8 source -> DOS copy the compiler reads
       akconv.py decode SRC DST   DOS copy -> UTF-8

The encoding is the one FONT.COM ("EGA/VGA Auxiliary Font V.4.0/06-90, AK Yerevan") draws
and ARMFONT.INC carries: bytes $80-$AF and $E0-$FB are the Armenian letters as
capital/small pairs, $FC is the question mark (՞) and $FD the emphasis mark (՛).
Encoding stops at any character the DOS font cannot show, such as the ligature և
(write եւ instead).
"""
import sys

CAPITALS = 'ԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖ'
SMALL = 'աբգդեզէըթժիլխծկհձղճմյնշոչպջռսվտրցւփքօֆ'
LETTERS = [c for capital, small in zip(CAPITALS, SMALL) for c in (capital, small)]
CODES = list(range(0x80, 0xB0)) + list(range(0xE0, 0xFC))

TO_UNICODE = dict(zip(CODES, LETTERS))
TO_UNICODE[0xFC] = '՞'
TO_UNICODE[0xFD] = '՛'
TO_DOS = {u: b for b, u in TO_UNICODE.items()}


def decode(data):
    out = []
    for n, b in enumerate(data):
        if b < 0x80:
            out.append(chr(b))
        elif b in TO_UNICODE:
            out.append(TO_UNICODE[b])
        else:
            raise ValueError(f'byte {n}: {b:#04x} is not an AK Yerevan character')
    return ''.join(out)


def encode(text):
    out = bytearray()
    for n, ch in enumerate(text):
        if ord(ch) < 0x80:
            out.append(ord(ch))
        elif ch in TO_DOS:
            out.append(TO_DOS[ch])
        else:
            line = text.count('\n', 0, n) + 1
            raise ValueError(f'line {line}: {ch!r} (U+{ord(ch):04X}) is not in the DOS font')
    return bytes(out)


def main(args):
    if len(args) != 3 or args[0] not in ('encode', 'decode'):
        sys.exit(__doc__)
    mode, src, dst = args
    try:
        if mode == 'encode':
            with open(src, encoding='utf-8', newline='') as f:
                data = encode(f.read())
            with open(dst, 'wb') as f:
                f.write(data)
        else:
            with open(src, 'rb') as f:
                text = decode(f.read())
            with open(dst, 'w', encoding='utf-8', newline='') as f:
                f.write(text)
    except ValueError as e:
        sys.exit(f'{src}: {e}')


if __name__ == '__main__':
    main(sys.argv[1:])
