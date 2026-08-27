#!/usr/bin/env python3
"""Bloomsort uygulama ikonu üretici.

`CLAUDE.md`: elle çizilmiş asset yok. İkon da kod: alacakaranlık gradyanı
üzerinde açılan bir çiçek, paletin kendi renkleriyle.

App Store 1024×1024 ikonu **alfa kanalı taşımaz ve köşe yuvarlatması yoktur**
(lansman checklist'i Faz 8), o yüzden çıktı opak RGB.

    python3 Tools/icon/make_icon.py App/Resources/Assets.xcassets
"""
import math
import struct
import sys
import zlib
from pathlib import Path

# docs/ui-spec.md §1.1 ve §1.2
DUSK_DEEP = (0x0A, 0x14, 0x18)
DUSK = (0x10, 0x1E, 0x24)
MOSS = (0x1D, 0x3A, 0x36)
POLLEN = (0xF5, 0xC2, 0x4B)
POLLEN_DEEP = (0xC9, 0x9A, 0x2E)
PETAL_COUNT = 6


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def render(size):
    """RGB piksel satırları döner."""
    cx = cy = size / 2
    radius = size * 0.30
    core = size * 0.085
    rows = []
    for y in range(size):
        row = bytearray()
        # Dikey gradyan: üstte dusk, altta dusk-deep.
        background = lerp(DUSK, DUSK_DEEP, y / (size - 1))
        for x in range(size):
            dx, dy = x - cx, y - cy
            distance = math.hypot(dx, dy)
            colour = background

            # Zeminde hafif yaprak damarı dokusu (%6 opaklık).
            if distance < size * 0.46:
                veins = 0.5 + 0.5 * math.sin(math.atan2(dy, dx) * 8 + distance * 0.05)
                colour = lerp(colour, MOSS, 0.06 * veins)

            # Altı yapraklı çiçek: her yaprak bir kardioid benzeri lob.
            angle = math.atan2(dy, dx)
            lobe = abs(math.cos(angle * PETAL_COUNT / 2))
            petal_edge = radius * (0.45 + 0.55 * lobe)
            if distance <= petal_edge:
                depth = distance / max(petal_edge, 1e-6)
                colour = lerp(POLLEN, POLLEN_DEEP, depth * 0.75)
                # Yaprak kenarında yumuşak geçiş.
                if petal_edge - distance < size * 0.006:
                    colour = lerp(colour, background, 0.45)

            # Ortadaki polen çekirdeği.
            if distance <= core:
                colour = lerp(POLLEN, (255, 255, 255), 0.35 * (1 - distance / core))

            row += bytes(colour)
        rows.append(bytes(row))
    return rows


def write_png(path, size, rows):
    raw = b"".join(b"\x00" + row for row in rows)

    def chunk(tag, data):
        payload = tag + data
        return (struct.pack(">I", len(data)) + payload
                + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF))

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)  # 8 bit, truecolour
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", header)
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    path.write_bytes(png)


CONTENTS = """{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""

LAUNCH_COLOUR = """{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0x24", "green" : "0x1E", "red" : "0x10" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""

ROOT_CONTENTS = """{
  "info" : { "author" : "xcode", "version" : 1 }
}
"""


def main():
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "App/Resources/Assets.xcassets")
    icon_set = target / "AppIcon.appiconset"
    colour_set = target / "LaunchBackground.colorset"
    icon_set.mkdir(parents=True, exist_ok=True)
    colour_set.mkdir(parents=True, exist_ok=True)

    size = 1024
    write_png(icon_set / "icon-1024.png", size, render(size))
    (icon_set / "Contents.json").write_text(CONTENTS)
    (colour_set / "Contents.json").write_text(LAUNCH_COLOUR)
    (target / "Contents.json").write_text(ROOT_CONTENTS)
    print(f"{icon_set / 'icon-1024.png'} yazıldı ({size}×{size}, alfa yok)")


if __name__ == "__main__":
    main()
