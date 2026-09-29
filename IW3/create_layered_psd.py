#!/usr/bin/env python3
"""Write a native 16-bit/channel layered RGB PSD with depth on top at 100%."""
import sys, struct
import numpy as np
from PIL import Image

def u16(n): return struct.pack('>H', n)
def u32(n): return struct.pack('>I', n)
def s16(n): return struct.pack('>h', n)
def section(data): return u32(len(data)) + data

def layer(name, channels, width, height):
    # Photoshop layer records are stored topmost first.
    record = struct.pack('>iiii', 0, 0, height, width) + u16(4)
    payload = b''
    for channel_id, array in zip((0, 1, 2, -1), channels):
        raw = np.asarray(array, dtype='>u2').tobytes(order='C')
        record += s16(channel_id) + u32(len(raw) + 2)
        payload += u16(0) + raw  # Raw compression
    record += b'8BIMnorm' + bytes((255, 0, 0, 0))
    name_bytes = name.encode('ascii', 'replace')[:255]
    pascal = bytes((len(name_bytes),)) + name_bytes
    pascal += bytes((-len(pascal)) % 4)
    record += section(u32(0) + u32(0) + pascal)
    return record, payload

def main(photo_path, depth_path, output_path):
    rgb = np.asarray(Image.open(photo_path).convert('RGB'), dtype=np.uint16) * 257
    depth_image = Image.open(depth_path)
    depth = np.asarray(depth_image)
    if depth.ndim != 2 or depth.dtype != np.uint16:
        raise ValueError('IW3 depth must be a native 16-bit grayscale image; refusing lossy conversion')
    height, width = depth.shape
    if rgb.shape[:2] != (height, width):
        raise ValueError(f'Image sizes differ: photo {rgb.shape[:2]}, depth {depth.shape}')
    alpha = np.full((height, width), 65535, dtype=np.uint16)
    top, top_data = layer('Depth Map - 16-bit', (depth, depth, depth, alpha), width, height)
    bottom, bottom_data = layer('Original Photograph', (rgb[:,:,0], rgb[:,:,1], rgb[:,:,2], alpha), width, height)
    # Photoshop stores layer records in display order: top layer first.
    info = s16(2) + top + bottom + top_data + bottom_data
    layer_mask = section(section(info) + u32(0))
    header = b'8BPS' + u16(1) + bytes(6) + u16(3) + u32(height) + u32(width) + u16(16) + u16(3)
    with open(output_path, 'wb') as output:
        output.write(header + u32(0) + u32(0) + layer_mask + u16(0))
        for _ in range(3):
            output.write(np.asarray(depth, dtype='>u2').tobytes(order='C'))
    print(f'Created native 16-bit layered PSD: {output_path} ({width}x{height}); depth top 100%')

if __name__ == '__main__':
    if len(sys.argv) != 4:
        raise SystemExit('Usage: create_layered_psd.py photo depth16.png output.psd')
    main(*sys.argv[1:])
