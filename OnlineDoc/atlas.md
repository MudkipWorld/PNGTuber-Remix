# Why you should NOT use huge images for PNGTuber body parts

> This is a **simple explanation**, not deep engine tech.

## What actually happens to your images

Your PNGs are **not used one by one**.

The engine (Godot, Unity, etc.): 
Takes all your body part images
- (head, eyes, mouth, arms, etc.)  
- **Glues them together** into big images called *texture atlases*  
- Sends those atlases to the GPU

## Example: 8 same-size images

You have **8 images**, each **1000×1000 px**.

The engine packs them like this:

:black_large_square::black_large_square::black_large_square:  
:black_large_square::black_large_square::black_large_square:  
:black_large_square::black_large_square::white_large_square:  

This becomes **one big image**, about **3000×3000 px**, uploaded to the GPU.
Each body part just points to its own spot inside that image.

## What happens when ONE image is a different size

Example:
- 7 images are **1000×1000**
- 1 image is **4000×4000** (for example: a mouth or eye)

Packing now looks more like this:

:black_large_square::black_large_square::black_large_square::black_large_square:  
:black_large_square::black_large_square::black_large_square::white_large_square:  
:black_large_square::black_large_square::white_large_square::white_large_square:  
:black_large_square::black_large_square::white_large_square::white_large_square:  

The atlas must grow to fit the **largest image**.
One oversized image can **blow up the entire atlas**.

## Why this is bad for PNGTubers

### Wasted memory
Most body parts don’t fill their images.
A mouth uses a tiny area
The rest is transparent
**Transparent pixels still use VRAM**

### Bigger atlases = worse performance
Large atlases mean
More GPU memory usage
More cache pressure
Higher chance of stutters or lag

### Zooming down does NOT fix it
The image looks small on screen
You scale it down in the app

The GPU still processes the **original full resolution**.
A tiny 4K mouth is still a 4K texture.

## What you SHOULD do instead

### Use the smallest size that still looks good
If a part:
 Is shown at 200×200 on screen  
 Don’t make it 4096×4096

Good sizes (if possible):
 128×128
 256×256
 512×512
 1024×1024 (only for large parts)

### Keep sizes consistent
Use **a few standard sizes**, not random ones.
> **One oversized image can make *all* your images expensive.**

This helps for efficient packing, smaller atlases and better performance
