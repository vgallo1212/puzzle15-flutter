# Genera los iconos de la PWA (mismo diseno que GameLogo en la app).
# Uso: python tool/make_icons.py
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "Poppins-Bold.ttf"
COLORS = ["#7C5CFF", "#5B8CFF", "#3CC6D0", "#FF7A90",
          "#FFB547", "#55D187", "#B067F0", "#FF8F5A"]
BG = "#2A1F4F"


def draw_icon(size, maskable=False):
    scale = 4  # se dibuja grande y se reduce para suavizar bordes
    s = size * scale
    img = Image.new("RGBA", (s, s), BG if maskable else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if not maskable:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 0.22, fill=BG)

    # En los maskable el contenido debe caber en el circulo seguro (80%).
    area = s * (0.56 if maskable else 0.74)
    start = (s - area) / 2
    gap = area * 0.06
    cell = (area - gap * 2) / 3
    font = ImageFont.truetype(str(FONT), int(cell * 0.55))

    for i in range(8):
        r, c = divmod(i, 3)
        x = start + c * (cell + gap)
        y = start + r * (cell + gap)
        d.rounded_rectangle([x, y, x + cell, y + cell], radius=cell * 0.22, fill=COLORS[i])
        d.text((x + cell / 2, y + cell / 2 + cell * 0.04), str(i + 1),
               font=font, fill="white", anchor="mm")
    return img.resize((size, size), Image.LANCZOS)


web = ROOT / "web"
draw_icon(192).save(web / "icons" / "Icon-192.png")
draw_icon(512).save(web / "icons" / "Icon-512.png")
draw_icon(192, maskable=True).save(web / "icons" / "Icon-maskable-192.png")
draw_icon(512, maskable=True).save(web / "icons" / "Icon-maskable-512.png")
draw_icon(180, maskable=True).save(web / "icons" / "apple-touch-icon.png")
draw_icon(64).save(web / "favicon.png")
print("Iconos listos")
