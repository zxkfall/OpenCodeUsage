#!/usr/bin/env python3
"""Generate AppIcon.icns for OpenCode Usage widget."""

from PIL import Image, ImageDraw, ImageFont
import math
import os
import shutil
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
WIDGET_DIR = os.path.join(SCRIPT_DIR, "..")
ICONSET = os.path.join(SCRIPT_DIR, "AppIcon.iconset")
ICNS_OUT = os.path.join(SCRIPT_DIR, "AppIcon.icns")

SIZES = [16, 32, 128, 256, 512]
SCALES = [1, 2]


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = size // 2
    margin = size * 0.12

    # Apple icon grid: inner rect at ~90% with ~20% corner radius
    outer = margin
    inner = size - margin
    cr = size * 0.22

    # Background rounded square
    draw.rounded_rectangle(
        [outer, outer, inner, inner],
        radius=cr,
        fill=(28, 28, 30, 255),  # dark macOS-style
    )

    # Accent gradient (orange) - three horizontal bars simulating usage gauge
    bar_area_top = size * 0.28
    bar_area_bottom = size * 0.72
    bar_left = size * 0.30
    bar_right = size * 0.76
    bar_count = 5
    bar_gap = size * 0.03
    bar_w = (bar_right - bar_left) / bar_count - bar_gap * 4 / bar_count if bar_count > 1 else bar_right - bar_left
    bar_h_max = bar_area_bottom - bar_area_top

    # Draw 5 bars of decreasing height (like a signal/usage meter)
    fill_levels = [0.85, 0.65, 0.50, 0.30, 0.15]
    for i, level in enumerate(fill_levels):
        bx = bar_left + i * (bar_right - bar_left) / bar_count
        by = bar_area_bottom - bar_h_max * level
        bw = bar_w * 0.7
        bh = bar_h_max * level
        bar_color = (242 if level > 0.6 else 200, 163 if level > 0.4 else 147, 60)
        draw.rounded_rectangle(
            [bx, by, bx + bw, bar_area_bottom],
            radius=size * 0.025,
            fill=bar_color,
        )

    # "Go" badge at top
    badge_size = size * 0.26
    badge_x = size * 0.37
    badge_y = size * 0.08
    draw.rounded_rectangle(
        [badge_x, badge_y, badge_x + badge_size, badge_y + badge_size],
        radius=size * 0.13,
        fill=(255, 159, 10),  # orange
    )

    # Draw "Go" text
    try:
        font_size = int(size * 0.14)
        font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Bold.otf", font_size)
        go_text = "Go"
        bbox = draw.textbbox((0, 0), go_text, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        tx = badge_x + badge_size / 2 - tw / 2
        ty = badge_y + badge_size / 2 - th / 2
        draw.text((tx, ty), go_text, fill=(255, 255, 255), font=font)
    except Exception:
        pass

    return img


def generate():
    if os.path.exists(ICONSET):
        shutil.rmtree(ICONSET)
    os.makedirs(ICONSET)

    for size in SIZES:
        for scale in SCALES:
            pixel_size = size * scale
            fn = f"icon_{size}x{size}"
            if scale == 2:
                fn += "@2x"
            fn += ".png"
            path = os.path.join(ICONSET, fn)
            img = draw_icon(pixel_size)
            img.save(path)

    subprocess.run(["iconutil", "-c", "icns", ICONSET, "-o", ICNS_OUT], check=True)

    # Copy to widget/App for the project
    dest = os.path.join(WIDGET_DIR, "App", "AppIcon.icns")
    shutil.copy(ICNS_OUT, dest)

    shutil.rmtree(ICONSET)
    os.remove(ICNS_OUT)

    print(f"Generated: {dest}")


if __name__ == "__main__":
    generate()
