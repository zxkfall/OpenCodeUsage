#!/usr/bin/env python3
"""Generate README banner (docs/banner.png) for OpenCode Usage widget."""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_icon import draw_icon

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.join(SCRIPT_DIR, "..", "..")
DOCS_DIR = os.path.join(PROJECT_DIR, "docs")
BANNER_OUT = os.path.join(DOCS_DIR, "banner.png")

WIDTH, HEIGHT = 1280, 400

BG = (24, 24, 27, 255)       # dark macOS-style
ACCENT = (255, 159, 10)      # orange
TEXT_PRIMARY = (245, 245, 245, 255)
TEXT_SECONDARY = (160, 160, 168, 255)
BAR_BG = (60, 60, 68, 255)

FONT_TITLE = "/System/Library/Fonts/SF-Pro-Display-Bold.otf"
FONT_SUB = "/System/Library/Fonts/SF-Pro-Display-Regular.otf"
FONT_CJK = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"  # CJK-capable TTF for Chinese text


def rounded_bg(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def draw_usage_bars(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int):
    """Small orange signal bars to the left of the title."""
    n = 5
    gap = 4
    bar_w = (w - gap * (n - 1)) / n
    levels = [0.85, 0.65, 0.50, 0.30, 0.15]
    for i, level in enumerate(levels):
        bx = x + i * (bar_w + gap)
        bh = h * level
        by = y + (h - bh)
        draw.rounded_rectangle([bx, by, bx + bar_w, y + h], radius=2, fill=ACCENT)


def generate():
    img = Image.new("RGBA", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)

    # App icon on the left
    icon = draw_icon(256)
    icon = icon.resize((256, 256), Image.LANCZOS)
    img.paste(icon, (100, (HEIGHT - 256) // 2), icon)

    # Text block on the right
    text_x = 430
    text_y = 140

    # Signal bars above title
    bars_x, bars_y, bars_w, bars_h = text_x, text_y - 8, 64, 18
    draw_usage_bars(draw, bars_x, bars_y, bars_w, bars_h)

    try:
        title_font = ImageFont.truetype(FONT_TITLE, 64)
    except Exception:
        title_font = ImageFont.load_default()
    try:
        sub_font = ImageFont.truetype(FONT_CJK, 30)
    except Exception:
        sub_font = ImageFont.truetype(FONT_SUB, 30)
    try:
        small_font = ImageFont.truetype(FONT_SUB, 22)
    except Exception:
        small_font = ImageFont.load_default()

    # Title (English)
    draw.text((text_x + 80, text_y - 10), "OpenCode Go Usage", font=title_font, fill=TEXT_PRIMARY)

    # Chinese subtitle
    draw.text((text_x + 80, text_y + 78), "macOS 菜单栏用量监控 · 多账户 · WidgetKit 小组件",
              font=sub_font, fill=TEXT_SECONDARY)

    # English tagline
    draw.text((text_x + 80, text_y + 128), "Track OpenCode Go API usage from your menu bar",
              font=small_font, fill=(110, 110, 118, 255))

    # Rounded corners + save
    final = rounded_bg(img, 24)
    os.makedirs(DOCS_DIR, exist_ok=True)
    final.save(BANNER_OUT)

    print(f"Generated: {BANNER_OUT}")


if __name__ == "__main__":
    generate()
