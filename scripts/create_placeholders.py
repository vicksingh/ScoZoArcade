#!/usr/bin/env python3
"""
Create placeholder images for Shootout assets.
These serve as fallbacks until real art is added.
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "--quiet"])
    from PIL import Image, ImageDraw, ImageFont


# Asset definitions: (name, color, label)
ASSETS = [
    ("court", (139, 90, 43), "COURT"),  # Wood brown
    ("ball", (255, 255, 255), "BALL"),  # White
    ("selection-ring", (0, 255, 255), "RING"),  # Cyan
    ("gs-idle", (0, 128, 128), "GS"),  # Teal
    ("gs-shuffle", (0, 128, 128), "GS"),
    ("gs-pass", (0, 128, 128), "GS"),
    ("gs-shoot", (0, 128, 128), "GS"),
    ("ga-idle", (0, 128, 128), "GA"),
    ("ga-shuffle", (0, 128, 128), "GA"),
    ("ga-pass", (0, 128, 128), "GA"),
    ("ga-shoot", (0, 128, 128), "GA"),
    ("gd-idle", (255, 0, 128), "GD"),  # Magenta
    ("gd-shuffle", (255, 0, 128), "GD"),
    ("gd-defend", (255, 0, 128), "GD"),
    ("gk-idle", (255, 0, 128), "GK"),
    ("gk-shuffle", (255, 0, 128), "GK"),
    ("gk-defend", (255, 0, 128), "GK"),
]


def create_placeholder(name: str, color: tuple, label: str, size: tuple = (256, 256)) -> Image.Image:
    """Create a simple placeholder image with a label."""
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw a rounded rectangle
    margin = 10
    draw.rounded_rectangle(
        [margin, margin, size[0] - margin, size[1] - margin],
        radius=20,
        fill=color + (200,),  # Semi-transparent
        outline=(255, 255, 255, 255),
        width=3
    )
    
    # Draw label text
    text = f"{label}\n{name}"
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
    except:
        font = ImageFont.load_default()
    
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size[0] - text_width) // 2
    y = (size[1] - text_height) // 2
    
    draw.text((x, y), text, fill=(255, 255, 255, 255), font=font, align='center')
    
    return img


def main():
    script_dir = Path(__file__).parent
    workspace_dir = script_dir.parent
    assets_dir = workspace_dir / "Scozo Play" / "Assets.xcassets"
    
    print(f"Creating placeholders in: {assets_dir}")
    
    for name, color, label in ASSETS:
        imageset_dir = assets_dir / f"{name}.imageset"
        
        if not imageset_dir.exists():
            print(f"  Skipping {name} - imageset not found")
            continue
        
        output_path = imageset_dir / f"{name}.png"
        
        # Use larger size for court
        size = (512, 384) if name == "court" else (256, 256)
        
        img = create_placeholder(name, color, label, size)
        img.save(output_path, 'PNG')
        print(f"  Created {name}.png")
    
    print("\nPlaceholders created. Replace with real art as needed.")


if __name__ == "__main__":
    main()
