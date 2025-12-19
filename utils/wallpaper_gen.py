#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.numpy python3Packages.scipy python3Packages.pillow

import numpy as np
from scipy.spatial import Voronoi
from PIL import Image, ImageDraw
import random
import sys

# --- Configuration ---
WIDTH = 3840
HEIGHT = 2160
NUM_SEEDS = 2500  # Higher number = smaller tiles
RELAXATION_STEPS = 10  # Number of Lloyd's iterations for uniformity
PADDING = 4  # Thickness of the gap between tiles
DARKEN_FACTOR = 0.55  # 1.0 is original, 0.0 is black

# Solarized Colors provided
PALETTE_HEX = [
    "#b58900", "#cb4b16", "#dc322f", "#d33682",
    "#6c71c4", "#268bd2", "#2aa198", "#859900"
]
BACKGROUND_COLOR = "#002b36"

def hex_to_rgb(hex_code):
    hex_code = hex_code.lstrip('#')
    return tuple(int(hex_code[i:i+2], 16) for i in (0, 2, 4))

def darken_color(rgb, factor):
    return tuple(int(c * factor) for c in rgb)

def generate_points(width, height, count):
    # Generate points in a buffer zone larger than the image to avoid edge artifacts
    buffer = 200
    x = np.random.uniform(-buffer, width + buffer, count)
    y = np.random.uniform(-buffer, height + buffer, count)
    return np.column_stack((x, y))

def relax_points(points):
    """
    Apply Lloyd's algorithm approximation.
    Computes Voronoi, then moves points to the centroid of their region.
    """
    vor = Voronoi(points)
    new_points = []
    for i, region_index in enumerate(vor.point_region):
        region = vor.regions[region_index]
        if -1 in region or not region:
            new_points.append(points[i])
            continue
        
        vertices = vor.vertices[region]
        centroid = vertices.mean(axis=0)
        new_points.append(centroid)
    return np.array(new_points)

def main():
    print("Initializing...")
    
    # Prepare colors
    colors = [darken_color(hex_to_rgb(c), DARKEN_FACTOR) for c in PALETTE_HEX]
    bg_rgb = hex_to_rgb(BACKGROUND_COLOR)

    # Generate Seeds
    print(f"Generating {NUM_SEEDS} seed points...")
    points = generate_points(WIDTH, HEIGHT, NUM_SEEDS)

    # Relax points (Lloyd's Algorithm)
    print(f"Performing {RELAXATION_STEPS} relaxation steps for uniform tile size...")
    for i in range(RELAXATION_STEPS):
        points = relax_points(points)

    # Generate final Voronoi diagram
    print("Computing final tessellation...")
    vor = Voronoi(points)

    # Draw Image
    print("Rendering image...")
    img = Image.new("RGB", (WIDTH, HEIGHT), bg_rgb)
    draw = ImageDraw.Draw(img)

    for region_index in vor.point_region:
        region = vor.regions[region_index]
        
        # Skip regions that are infinite (contain -1) or empty
        if -1 in region or len(region) == 0:
            continue

        polygon = [tuple(vor.vertices[i]) for i in region]
        
        # Check if polygon is roughly within bounds (optimization)
        poly_arr = np.array(polygon)
        if (np.all(poly_arr[:, 0] < -100) or np.all(poly_arr[:, 0] > WIDTH + 100) or
            np.all(poly_arr[:, 1] < -100) or np.all(poly_arr[:, 1] > HEIGHT + 100)):
            continue

        fill_col = random.choice(colors)
        
        # Draw the filled polygon. 
        # The outline argument creates the padding by drawing the background color over the edge.
        draw.polygon(polygon, fill=fill_col, outline=bg_rgb, width=PADDING)

    output_filename = "voronoi_tiling.png"
    img.save(output_filename)
    print(f"Done. Image saved to {output_filename}")

if __name__ == "__main__":
    main()
