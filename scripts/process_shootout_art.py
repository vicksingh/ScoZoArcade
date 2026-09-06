#!/usr/bin/env python3
"""
Process ScoZo Shootout art pack images.
Removes chroma green backgrounds and copies to Assets.xcassets structure.

Usage:
    python3 process_shootout_art.py [source_dir]

If source_dir is not provided, defaults to ../scozo-shootout-art/

The source directory should contain PNG files named:
    court.png, ball.png, selection-ring.png,
    gs-idle.png, gs-shuffle.png, gs-pass.png, gs-shoot.png,
    ga-idle.png, ga-shuffle.png, ga-pass.png, ga-shoot.png,
    gd-idle.png, gd-shuffle.png, gd-defend.png,
    gk-idle.png, gk-shuffle.png, gk-defend.png

All images except 'court' will have green (#00FF00) backgrounds removed.
"""

import os
import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Installing Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "--quiet"])
    from PIL import Image


# Asset names expected by ShootoutAssets.swift
ASSETS = [
    ("court", False),  # (name, needs_green_removal)
    ("ball", True),
    ("selection-ring", True),
    ("gs-idle", True),
    ("gs-shuffle", True),
    ("gs-pass", True),
    ("gs-shoot", True),
    ("ga-idle", True),
    ("ga-shuffle", True),
    ("ga-pass", True),
    ("ga-shoot", True),
    ("gd-idle", True),
    ("gd-shuffle", True),
    ("gd-defend", True),
    ("gk-idle", True),
    ("gk-shuffle", True),
    ("gk-defend", True),
]


def remove_green_screen(image: Image.Image) -> Image.Image:
    """Remove chroma green (#00FF00) background from image."""
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    pixels = image.load()
    width, height = image.size
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            
            # Detect green screen: high green, low red/blue
            # Using multiple thresholds for better edge handling
            is_green = (
                g > 180 and  # Strong green
                g > r * 1.4 and  # Green significantly higher than red
                g > b * 1.4 and  # Green significantly higher than blue
                r < 150 and  # Red is low
                b < 150  # Blue is low
            )
            
            if is_green:
                # Make fully transparent
                pixels[x, y] = (0, 0, 0, 0)
            else:
                # Check for green fringe on edges - blend to reduce halos
                green_ratio = g / max(r + b + 1, 1)
                if green_ratio > 1.5 and g > 100:
                    # Reduce green cast
                    new_g = min(g, max(r, b))
                    pixels[x, y] = (r, new_g, b, a)
    
    return image


def create_imageset(assets_dir: Path, name: str, image_path: Path, remove_green: bool):
    """Create an imageset folder with the processed image."""
    imageset_dir = assets_dir / f"{name}.imageset"
    imageset_dir.mkdir(parents=True, exist_ok=True)
    
    # Load and process image
    img = Image.open(image_path)
    
    if remove_green:
        img = remove_green_screen(img)
    else:
        # Ensure RGBA for consistency
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
    
    # Save processed image
    output_path = imageset_dir / f"{name}.png"
    img.save(output_path, 'PNG')
    
    # Create Contents.json
    contents = {
        "images": [
            {
                "filename": f"{name}.png",
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = imageset_dir / "Contents.json"
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"  Created {name}.imageset")
    return True


def main():
    # Determine paths
    script_dir = Path(__file__).parent
    workspace_dir = script_dir.parent
    
    # Allow source dir override via command line
    if len(sys.argv) > 1:
        source_dir = Path(sys.argv[1])
    else:
        source_dir = workspace_dir / "scozo-shootout-art"
    
    assets_dir = workspace_dir / "Scozo Play" / "Assets.xcassets"
    
    if not source_dir.exists():
        print(f"ERROR: Source directory not found: {source_dir}")
        print("\nUsage: python3 process_shootout_art.py [source_dir]")
        print("\nExpected images in source directory:")
        for name, _ in ASSETS:
            print(f"  - {name}.png")
        sys.exit(1)
    
    if not assets_dir.exists():
        print(f"ERROR: Assets directory not found: {assets_dir}")
        sys.exit(1)
    
    print(f"Source: {source_dir}")
    print(f"Target: {assets_dir}")
    print()
    
    success_count = 0
    missing = []
    
    for name, needs_green_removal in ASSETS:
        source_file = source_dir / f"{name}.png"
        
        if not source_file.exists():
            missing.append(name)
            continue
        
        try:
            create_imageset(assets_dir, name, source_file, needs_green_removal)
            success_count += 1
        except Exception as e:
            print(f"  ERROR processing {name}: {e}")
    
    print()
    print(f"Processed: {success_count}/{len(ASSETS)} assets")
    
    if missing:
        print(f"\nMissing source images:")
        for name in missing:
            print(f"  - {name}.png")
        return 1
    
    print("\nAll assets processed successfully!")
    print("The textures should now load in Xcode Simulator.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
