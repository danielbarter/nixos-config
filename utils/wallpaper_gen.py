#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.numpy python3Packages.scipy python3Packages.pillow

import numpy as np
from scipy.spatial import Voronoi
from PIL import Image, ImageDraw
import random

# --- CONFIGURATION ---
WIDTH = 3840
HEIGHT = 2160
SCALE_FACTOR = 2  # Render at 2x for anti-aliasing
NUM_SEEDS = 600   # Density of tiles
RELAXATION_STEPS = 5 # Higher = more uniform (hexagonal), Lower = more random
PADDING_RATIO = 0.85 # 1.0 = touching, < 1.0 = gaps

# Dracula-ish Grayscale Palette
# Background (Grout)
COLOR_BG = (20, 20, 30) 

# Tile Colors (Dark, Cool Grays)
TILE_PALETTE = [
    (40, 42, 54),   # Dracula Background
    (68, 71, 90),   # Current Line
    (50, 50, 60),   # Darker Variant
    (60, 62, 75),   # Mid Variant
    (30, 31, 40),   # Deep Variant
]

def generate_voronoi_seeds(width, height, num_points, steps):
    """
    Generates points and applies Lloyd's relaxation to regularize them.
    Simulates surface tension forces in foam.
    """
    # Generate points over a slightly larger area to ensure edges are covered
    # and to avoid edge effects from the Voronoi algorithm
    margin = 500
    points = np.random.rand(num_points, 2)
    points[:,0] = points[:,0] * (width + 2*margin) - margin
    points[:,1] = points[:,1] * (height + 2*margin) - margin

    for _ in range(steps):
        vor = Voronoi(points)
        new_points = []
        for i, region_index in enumerate(vor.point_region):
            region = vor.regions[region_index]
            if -1 in region or len(region) == 0:
                new_points.append(points[i])
                continue
            
            # Get vertices for this region
            polygon = [vor.vertices[i] for i in region]
            
            # Calculate centroid of the polygon
            poly_arr = np.array(polygon)
            centroid = np.mean(poly_arr, axis=0)
            new_points.append(centroid)
        points = np.array(new_points)
        
    return Voronoi(points)

def shrink_polygon(vertices, factor):
    """
    Shrinks a polygon towards its centroid to create padding.
    """
    arr = np.array(vertices)
    centroid = np.mean(arr, axis=0)
    return centroid + (arr - centroid) * factor

def main():
    # Setup high-res canvas
    rw, rh = WIDTH * SCALE_FACTOR, HEIGHT * SCALE_FACTOR
    img = Image.new("RGB", (rw, rh), COLOR_BG)
    draw = ImageDraw.Draw(img)

    print(f"Generating physics-inspired tiling ({WIDTH}x{HEIGHT})...")
    
    # Generate Tiling
    vor = generate_voronoi_seeds(rw, rh, NUM_SEEDS, RELAXATION_STEPS)

    # Draw Polygons
    for region_index in vor.point_region:
        region = vor.regions[region_index]
        if -1 in region or len(region) == 0:
            continue
            
        vertices = [vor.vertices[i] for i in region]
        
        # Check if polygon is roughly within bounds (optimization)
        v_arr = np.array(vertices)
        if np.all(v_arr[:,0] < -500) or np.all(v_arr[:,0] > rw + 500):
            continue
        if np.all(v_arr[:,1] < -500) or np.all(v_arr[:,1] > rh + 500):
            continue

        # Apply padding
        shrunk_vertices = shrink_polygon(vertices, PADDING_RATIO)
        
        # Convert to list of tuples for PIL
        poly_tuples = [tuple(v) for v in shrunk_vertices]
        
        # Pick color
        color = random.choice(TILE_PALETTE)
        
        # Draw
        draw.polygon(poly_tuples, fill=color)

    # Downsample for crisp edges (Lanczos filter)
    print("Resampling for anti-aliasing...")
    final_img = img.resize((WIDTH, HEIGHT), resample=Image.Resampling.LANCZOS)
    
    output_filename = "voronoi_dracula.png"
    final_img.save(output_filename)
    print(f"Done. Saved to {output_filename}")

if __name__ == "__main__":
    main()
