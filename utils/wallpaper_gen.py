#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p "python3.withPackages (ps: with ps; [ numpy scipy pillow ])"

import numpy as np
from scipy.spatial import Voronoi
from PIL import Image, ImageDraw
import random

# Configuration
WIDTH = 3840
HEIGHT = 2160
NUM_TILES_X = 40  # Adjust for tile density
BG_COLOR = "#002b36"
PADDING_WIDTH = 6 # Thickness of the gap between tiles

TILE_COLORS = [
    "#b58900",
    "#cb4b16",
    "#dc322f",
    "#d33682",
    "#6c71c4",
    "#268bd2",
    "#2aa198",
    "#859900"
]

def generate_voronoi_art():
    # 1. Generate seed points
    # We generate points on a grid to ensure "roughly same size"
    # then apply heavy jitter to create "many different shapes" (non-periodic)
    # We extend the grid beyond image bounds to ensure edge tiles are closed
    
    aspect_ratio = WIDTH / HEIGHT
    num_tiles_y = int(NUM_TILES_X / aspect_ratio)
    
    # Buffer to ensure the diagram covers the edges cleanly
    buffer_x = WIDTH * 0.2
    buffer_y = HEIGHT * 0.2
    
    x_coords = np.linspace(-buffer_x, WIDTH + buffer_x, NUM_TILES_X)
    y_coords = np.linspace(-buffer_y, HEIGHT + buffer_y, num_tiles_y)
    
    xx, yy = np.meshgrid(x_coords, y_coords)
    points = np.c_[xx.ravel(), yy.ravel()]
    
    # Add randomness (jitter) to the points
    # The jitter amount controls how irregular the shapes are
    spacing_x = WIDTH / NUM_TILES_X
    jitter_amount = spacing_x * 0.45 
    noise = (np.random.rand(len(points), 2) - 0.5) * 2 * jitter_amount
    points += noise

    # 2. Compute Voronoi Diagram
    vor = Voronoi(points)

    # 3. Render Image
    im = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(im)

    # Iterate through regions
    # vor.point_region maps point indices to region indices
    for i, region_index in enumerate(vor.point_region):
        region = vor.regions[region_index]
        
        # -1 indicates a region that goes to infinity (we ignore these, 
        # but our buffer ensures they are off-screen anyway)
        if -1 in region or len(region) == 0:
            continue
            
        # Get vertices for this region
        polygon_points = [vor.vertices[v] for v in region]
        
        # Convert to list of tuples for PIL
        poly_tuples = [tuple(p) for p in polygon_points]
        
        # Pick a random color
        fill_col = random.choice(TILE_COLORS)
        
        # Draw the polygon
        # The 'outline' acts as the padding between tiles
        draw.polygon(poly_tuples, fill=fill_col, outline=BG_COLOR, width=PADDING_WIDTH)

    # 4. Save
    filename = "solarized_voronoi.png"
    im.save(filename, format="PNG")
    print(f"Image generated successfully: {filename}")

if __name__ == "__main__":
    generate_voronoi_art()
