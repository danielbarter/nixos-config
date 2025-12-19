#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.numpy python3Packages.scipy python3Packages.pillow

import numpy as np
from scipy.spatial import Voronoi
from PIL import Image, ImageDraw
import random

# --- Configuration ---
WIDTH = 3840
HEIGHT = 2160
NUM_SEEDS = 600
RELAXATION_ITERATIONS = 5
PADDING_WIDTH = 6  # Spacing between tiles
OUTPUT_FILENAME = "dracula_voronoi_tiling.png"

# Dracula-inspired dark grayscale palette
# Background (Margins)
COLOR_BG = "#15161A"  # Very dark, almost black for contrast

# 5 Tile Colors (Dark Grayscale with Dracula tint)
TILE_PALETTE = [
    "#282a36",  # Dracula Background
    "#343746",  # Offset 1
    "#44475a",  # Dracula Current Line
    "#52576e",  # Offset 2
    "#6272a4",  # Dracula Comment (Bluish Grey)
]

def generate_voronoi_diagram(width, height, num_seeds):
    """
    Generates a Voronoi diagram with Lloyd's relaxation for uniformity.
    """
    # Create a buffer area to ensure edge tiles are closed
    # We generate points in a coordinate system slightly larger than the image
    buffer_x = width * 0.2
    buffer_y = height * 0.2
    
    # Initialize random seeds
    points = np.random.rand(num_seeds, 2)
    points[:, 0] = points[:, 0] * (width + 2 * buffer_x) - buffer_x
    points[:, 1] = points[:, 1] * (height + 2 * buffer_y) - buffer_y

    # Lloyd's Relaxation: Iteratively move points to the centroid of their region
    # This regularizes the cell sizes, making them "roughly the same size"
    # while maintaining a non-periodic, organic structure.
    for _ in range(RELAXATION_ITERATIONS):
        vor = Voronoi(points)
        new_points = []
        for i, region_index in enumerate(vor.point_region):
            region = vor.regions[region_index]
            if -1 in region or len(region) == 0:
                new_points.append(points[i])
                continue
            
            # Get vertices for this region
            polygon = [vor.vertices[i] for i in region]
            poly_arr = np.array(polygon)
            
            # Calculate centroid
            centroid = np.mean(poly_arr, axis=0)
            new_points.append(centroid)
        points = np.array(new_points)

    # Final Voronoi computation
    return Voronoi(points)

def draw_tiling(vor, width, height):
    """
    Draws the Voronoi regions onto a PIL image.
    """
    # Create image with background color (this serves as the margin)
    img = Image.new("RGB", (width, height), COLOR_BG)
    draw = ImageDraw.Draw(img)

    for region_index in vor.point_region:
        region = vor.regions[region_index]
        
        # Skip incomplete regions (usually at the infinite boundary)
        if -1 in region or len(region) == 0:
            continue
        
        polygon = [tuple(vor.vertices[i]) for i in region]
        
        # Check if polygon is roughly within bounds to avoid drawing useless off-screen geometry
        # (Simple bounding box check)
        poly_arr = np.array(polygon)
        if (np.all(poly_arr[:, 0] < -500) or np.all(poly_arr[:, 0] > width + 500) or
            np.all(poly_arr[:, 1] < -500) or np.all(poly_arr[:, 1] > height + 500)):
            continue

        # Pick a random color from the palette
        fill_color = random.choice(TILE_PALETTE)
        
        # Draw the polygon.
        # We simulate padding by drawing the polygon filled, and then drawing a 
        # thick outline in the background color.
        
        # 1. Draw the actual colored tile
        draw.polygon(polygon, fill=fill_color)
        
        # 2. Draw the stroke (margin) in background color
        draw.line(polygon + [polygon[0]], fill=COLOR_BG, width=PADDING_WIDTH)

    return img

def main():
    print("Generating geometry...")
    vor = generate_voronoi_diagram(WIDTH, HEIGHT, NUM_SEEDS)
    
    print("Rendering image...")
    image = draw_tiling(vor, WIDTH, HEIGHT)
    
    print(f"Saving to {OUTPUT_FILENAME}...")
    image.save(OUTPUT_FILENAME)
    print("Done.")

if __name__ == "__main__":
    main()
