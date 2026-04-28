#!/usr/bin/env python3
"""
MoveMatch AI — 1024×1024 主图标：绿色渐变底 + 居中白色「M」字标（易辨认、不抽象）。
在 macOS 上用 Arial Rounded；其它环境可改为自备 .ttf 路径。无字体时用手绘圆角 M 作后备。
"""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
SUPER = 2

# 常见系统字体（优先圆角、偏运动类 App）
_FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/Library/Fonts/Arial.ttf",
]


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in _FONT_CANDIDATES:
        if os.path.isfile(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def _draw_m_fallback(draw: ImageDraw.ImageDraw, cx: int, cy: int, scale: float) -> None:
    """无矢量字体时：用粗白线画简化的 M。"""
    s = scale
    w = int(52 * s)
    white = (255, 255, 255)
    x0, y0 = cx - 200 * s, cy + 180 * s
    x1, y1 = cx - 200 * s, cy - 220 * s
    x2, y2 = cx - 20 * s, cy + 120 * s
    x3, y3 = cx, cy - 200 * s
    x4, y4 = cx + 20 * s, cy + 120 * s
    x5, y5 = cx + 200 * s, cy - 220 * s
    x6, y6 = cx + 200 * s, cy + 180 * s
    draw.line([(x0, y0), (x1, y1), (x2, y2)], fill=white, width=w, joint="curve")
    draw.line([(x3, y3), (x4, y4)], fill=white, width=int(w * 0.9), joint="curve")
    draw.line([(x5, y5), (x6, y6)], fill=white, width=w, joint="curve")


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(
        root,
        "MoveMatch AI",
        "Assets.xcassets",
        "AppIcon.appiconset",
        "AppIcon-1024.png",
    )

    S = SIZE * SUPER

    # 绿色渐变铺满
    c0 = (50, 230, 150)
    c1 = (4, 105, 62)
    img = Image.new("RGB", (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2.0 * (S - 1))
            t = max(0.0, min(1.0, t))
            px[x, y] = (
                int(lerp(c0[0], c1[0], t)),
                int(lerp(c0[1], c1[1], t)),
                int(lerp(c0[2], c1[2], t)),
            )

    # 不再叠椭圆高光，避免出现「中间一块圆斑」；只保留纯粹斜向绿渐变底

    draw = ImageDraw.Draw(img)
    font = _load_font(int(560 * SUPER))
    ch = "M"
    if hasattr(font, "getbbox"):
        l, t, r, b = font.getbbox(ch)
    else:
        l, t, r, b = draw.textbbox((0, 0), ch, font=font)
    tw, th = r - l, b - t

    # 默认字体极小时启用后备
    if tw < 100 * SUPER:
        _draw_m_fallback(draw, S // 2, S // 2, float(SUPER))
    else:
        # 字稍向左上微移，在圆角方标里视觉更居中
        x = (S - tw) // 2 - l - int(8 * SUPER)
        y = (S - th) // 2 - t - int(18 * SUPER)
        green_edge = (0, 90, 52)
        draw.text(
            (x, y),
            ch,
            font=font,
            fill=(255, 255, 255),
            stroke_width=int(10 * SUPER),
            stroke_fill=green_edge,
        )

    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    img.save(out, "PNG", optimize=True)
    print(out, "OK", SIZE, flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(e, file=sys.stderr)
        sys.exit(1)
