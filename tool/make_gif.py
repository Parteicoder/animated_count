"""Assemble build/demo_frames/*.png into doc/demo.gif (Pillow)."""
import glob
from PIL import Image

files = sorted(glob.glob("build/demo_frames/f*.png"))
frames = [Image.open(f).convert("RGB").quantize(colors=32, dither=Image.Dither.NONE) for f in files]
frames[0].save("doc/demo.gif", save_all=True, append_images=frames[1:], duration=50, loop=0, optimize=True)
print(len(frames), "frames")
