import os
from PIL import Image

src_img_path = r"D:\PROJECT GMN\nihao\assets\images\app_icon.jpg"
res_dir = r"D:\PROJECT GMN\nihao\android\app\src\main\res"

sizes = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192)
}

img = Image.open(src_img_path)

for folder, size in sizes.items():
    folder_path = os.path.join(res_dir, folder)
    os.makedirs(folder_path, exist_ok=True)
    out_file = os.path.join(folder_path, "ic_launcher.png")
    
    resized = img.resize(size, Image.Resampling.LANCZOS)
    resized.save(out_file, "PNG")
    print(f"Generated {out_file} ({size[0]}x{size[1]})")

print("All Android launcher icons generated successfully!")
