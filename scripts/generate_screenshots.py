#!/usr/bin/env python3
"""Generate App Store screenshots for Wood Identifier (WoodSnap)."""

import os
import math
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = "/Users/chadnewbry/dev/WoodIdentifier/screenshots"

DEVICES = {
    "iPhone_6.9": (1320, 2868),
    "iPhone_6.7": (1290, 2796),
    "iPhone_6.5": (1284, 2778),
    "iPhone_5.5": (1242, 2208),
}

SCREENSHOTS = [
    {"id": "01_identify", "caption": "Snap. Identify.\nInstantly.", "bg_color": (42, 32, 24), "accent": (196, 142, 72), "scene": "camera_scan"},
    {"id": "02_database", "caption": "200+ Wood Species\nDatabase", "bg_color": (245, 237, 224), "accent": (139, 90, 43), "scene": "database_grid"},
    {"id": "03_details", "caption": "Know Every\nDetail", "bg_color": (56, 40, 28), "accent": (214, 170, 105), "scene": "detail_card"},
    {"id": "04_compare", "caption": "Compare\nSide by Side", "bg_color": (238, 228, 212), "accent": (120, 76, 38), "scene": "compare_mode"},
    {"id": "05_history", "caption": "Track Your\nScans", "bg_color": (48, 36, 26), "accent": (186, 132, 62), "scene": "history_view"},
    {"id": "06_offline", "caption": "Works Offline\nToo", "bg_color": (235, 225, 210), "accent": (100, 65, 30), "scene": "offline_mode"},
]

def s(val, w, ref=1320):
    return int(val * w / ref)

def font(size):
    return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)

def font_r(size):
    try: return ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", size)
    except: return font(size)

def rrect(draw, xy, r, **kw):
    draw.rounded_rectangle(xy, radius=r, **kw)

def wood_grain(draw, x, y, w, h, base, seed=0):
    import random
    rng = random.Random(seed)
    r, g, b = base
    for i in range(0, h, 3):
        v = rng.randint(-15, 15)
        c = (max(0,min(255,r+v)), max(0,min(255,g+v)), max(0,min(255,b+v)))
        draw.line([(x, y+i), (x+w, y+i)], fill=c, width=2)
    for _ in range(rng.randint(0, 2)):
        cx, cy = rng.randint(x+20, x+w-20), rng.randint(y+20, y+h-20)
        kr = rng.randint(8, 25)
        draw.ellipse([cx-kr, cy-kr, cx+kr, cy+kr], fill=(max(0,r-30), max(0,g-30), max(0,b-30)))

def phone_frame(draw, w, h):
    pw, ph = int(w*0.62), int(h*0.50)
    px, py = (w-pw)//2, int(h*0.38)
    r = s(40, w)
    rrect(draw, [px+8,py+8,px+pw+8,py+ph+8], r, fill=(0,0,0,60))
    rrect(draw, [px,py,px+pw,py+ph], r, fill=(20,20,20))
    inset = s(8, w)
    return [px+inset, py+inset, px+pw-inset, py+ph-inset]

def caption(draw, w, h, text, dark):
    fs = s(88, w)
    f = font_r(fs)
    color = (255,255,255) if dark else (42,32,24)
    y0 = s(120, w)
    lh = fs + s(16, w)
    for i, line in enumerate(text.split("\n")):
        bb = draw.textbbox((0,0), line, font=f)
        tx = (w - (bb[2]-bb[0]))//2
        ty = y0 + i*lh
        draw.text((tx+3, ty+3), line, font=f, fill=(0,0,0,80))
        draw.text((tx, ty), line, font=f, fill=color)

def scene_camera_scan(draw, sc, w, h, acc):
    sx0,sy0,sx1,sy1 = sc; sw,sh = sx1-sx0, sy1-sy0
    rrect(draw, sc, s(32,w), fill=(15,12,8))
    gy = sy0+s(20,w); gh = int(sh*0.55)
    wood_grain(draw, sx0+s(10,w), gy, sw-s(20,w), gh, (165,110,55), 42)
    # scan line
    draw.line([(sx0+s(20,w), gy+gh//2), (sx1-s(20,w), gy+gh//2)], fill=(100,200,255), width=s(4,w))
    # corners
    bl = s(40,w); bw = s(4,w)
    for cx,cy in [(sx0+s(30,w),gy+s(10,w)),(sx1-s(30,w)-bl,gy+s(10,w)),
                  (sx0+s(30,w),gy+gh-s(10,w)-bl),(sx1-s(30,w)-bl,gy+gh-s(10,w)-bl)]:
        draw.line([(cx,cy),(cx+bl,cy)], fill=(255,255,255,200), width=bw)
        draw.line([(cx,cy),(cx,cy+bl)], fill=(255,255,255,200), width=bw)
    # result sheet
    sy = gy+gh+s(20,w)
    rrect(draw, [sx0+s(15,w),sy,sx1-s(15,w),sy1-s(15,w)], s(20,w), fill=(255,255,255))
    draw.text((sx0+s(35,w),sy+s(15,w)), "Red Oak", font=font(s(32,w)), fill=(42,32,24))
    draw.text((sx0+s(35,w),sy+s(55,w)), "94% match", font=font(s(24,w)), fill=acc)
    # bar
    by = sy+s(90,w); bx0=sx0+s(35,w); bx1=sx1-s(35,w)
    rrect(draw, [bx0,by,bx1,by+s(12,w)], s(6,w), fill=(230,225,215))
    rrect(draw, [bx0,by,bx0+int((bx1-bx0)*0.94),by+s(12,w)], s(6,w), fill=acc)

def scene_database_grid(draw, sc, w, h, acc):
    sx0,sy0,sx1,sy1 = sc; sw = sx1-sx0
    rrect(draw, sc, s(32,w), fill=(250,244,234))
    # search
    sby = sy0+s(15,w)
    rrect(draw, [sx0+s(20,w),sby,sx1-s(20,w),sby+s(45,w)], s(12,w), fill=(235,228,218))
    draw.text((sx0+s(40,w),sby+s(12,w)), "🔍  Search species...", font=font(s(20,w)), fill=(150,130,110))
    # chips
    cy = sby+s(60,w); cx = sx0+s(20,w)
    for i,ch in enumerate(["All","Hardwood","Softwood","Exotic"]):
        cw = s(90+len(ch)*5,w)
        rrect(draw,[cx,cy,cx+cw,cy+s(32,w)],s(16,w),fill=acc if i==0 else (225,218,208))
        draw.text((cx+s(12,w),cy+s(6,w)),ch,font=font(s(18,w)),fill=(255,255,255) if i==0 else (100,75,50))
        cx += cw+s(10,w)
    # grid
    gy = cy+s(50,w); gap=s(12,w); cw=(sw-s(40,w)-gap)//2; ch_=s(130,w)
    woods = [("Red Oak",(178,120,60)),("Walnut",(85,55,30)),("Cherry",(160,85,50)),("Maple",(210,180,140)),
             ("Mahogany",(120,50,30)),("Pine",(220,195,150)),("Teak",(150,110,50)),("Ash",(200,175,140))]
    for idx,(nm,col) in enumerate(woods):
        c,r = idx%2, idx//2
        x = sx0+s(20,w)+c*(cw+gap); y = gy+r*(ch_+gap)
        if y+ch_ > sy1-s(10,w): break
        rrect(draw,[x,y,x+cw,y+ch_],s(12,w),fill=(255,255,255))
        wood_grain(draw,x+s(8,w),y+s(8,w),cw-s(16,w),ch_-s(45,w),col,idx*7)
        draw.text((x+s(12,w),y+ch_-s(30,w)),nm,font=font(s(16,w)),fill=(60,40,25))

def scene_detail_card(draw, sc, w, h, acc):
    sx0,sy0,sx1,sy1 = sc; sw,sh = sx1-sx0, sy1-sy0
    rrect(draw, sc, s(32,w), fill=(250,244,234))
    hh = int(sh*0.30)
    wood_grain(draw, sx0+s(8,w), sy0+s(8,w), sw-s(16,w), hh, (130,70,40), 99)
    ty = sy0+hh-s(60,w)
    draw.text((sx0+s(25,w),ty), "Black Walnut", font=font(s(36,w)), fill=(255,255,255))
    draw.text((sx0+s(25,w),ty+s(40,w)), "Juglans nigra", font=font(s(20,w)), fill=(220,210,195))
    py = sy0+hh+s(20,w)
    for i,(p,v,pct) in enumerate([("Janka Hardness","1,010 lbf",0.58),("Density","38 lbs/ft³",0.55),
        ("Workability","Excellent",0.85),("Price Range","$8-14/bf",0.65),("Durability","Very Good",0.78)]):
        y = py+i*s(55,w)
        draw.text((sx0+s(25,w),y),p,font=font(s(18,w)),fill=(130,110,85))
        draw.text((sx0+s(25,w),y+s(22,w)),v,font=font(s(20,w)),fill=(50,35,20))
        bx0,bx1,by = sx0+s(25,w), sx1-s(25,w), y+s(46,w)
        rrect(draw,[bx0,by,bx1,by+s(6,w)],s(3,w),fill=(230,225,215))
        rrect(draw,[bx0,by,bx0+int((bx1-bx0)*pct),by+s(6,w)],s(3,w),fill=acc)

def scene_compare_mode(draw, sc, w, h, acc):
    sx0,sy0,sx1,sy1 = sc; sw,sh = sx1-sx0, sy1-sy0
    rrect(draw, sc, s(32,w), fill=(250,244,234))
    hw = (sw-s(30,w))//2
    for side,(nm,col,xst) in enumerate([("Red Oak",(178,120,60),sx0+s(10,w)),("White Oak",(195,160,100),sx0+s(20,w)+hw)]):
        samh = int(sh*0.28)
        wood_grain(draw,xst,sy0+s(10,w),hw,samh,col,side*33)
        rrect(draw,[xst,sy0+s(10,w),xst+hw,sy0+s(10,w)+samh],s(10,w),outline=(200,190,175),width=2)
        draw.text((xst+s(10,w),sy0+samh+s(18,w)),nm,font=font(s(22,w)),fill=(50,35,20))
        for i,(p,v) in enumerate([("Hardness",0.73 if side==0 else 0.81),("Density",0.60 if side==0 else 0.65),
            ("Price",0.45 if side==0 else 0.60),("Durability",0.65 if side==0 else 0.80)]):
            py = sy0+samh+s(55,w)+i*s(45,w)
            draw.text((xst+s(10,w),py),p,font=font(s(14,w)),fill=(130,110,85))
            bw_=hw-s(20,w); by=py+s(20,w)
            rrect(draw,[xst+s(10,w),by,xst+s(10,w)+bw_,by+s(10,w)],s(5,w),fill=(230,225,215))
            rrect(draw,[xst+s(10,w),by,xst+s(10,w)+int(bw_*v),by+s(10,w)],s(5,w),fill=acc if side==0 else (160,120,60))
    vx,vy = sx0+sw//2, sy0+int(sh*0.15)
    draw.ellipse([vx-s(18,w),vy-s(18,w),vx+s(18,w),vy+s(18,w)],fill=acc)
    draw.text((vx-s(10,w),vy-s(12,w)),"VS",font=font(s(16,w)),fill=(255,255,255))

def scene_history_view(draw, sc, w, h, acc):
    sx0,sy0,sx1,sy1 = sc; sw = sx1-sx0
    rrect(draw, sc, s(32,w), fill=(250,244,234))
    by = sy0+s(15,w)
    rrect(draw,[sx0+s(15,w),by,sx1-s(15,w),by+s(70,w)],s(14,w),fill=acc)
    stw = (sw-s(30,w))//3
    for i,(n,l) in enumerate([("47","Scans"),("23","Species"),("12","Favorites")]):
        sx = sx0+s(15,w)+i*stw
        draw.text((sx+stw//2-s(12,w),by+s(10,w)),n,font=font(s(28,w)),fill=(255,255,255))
        draw.text((sx+stw//2-s(20,w),by+s(45,w)),l,font=font(s(14,w)),fill=(255,240,210))
    ly = by+s(90,w)
    for i,(nm,dt,cf,col) in enumerate([("Red Oak","Today, 2:34 PM","94%",(178,120,60)),
        ("Black Walnut","Today, 11:20 AM","89%",(85,55,30)),("Cherry","Yesterday","91%",(160,85,50)),
        ("White Pine","Yesterday","87%",(220,195,150)),("Maple","Mar 1","96%",(210,180,140))]):
        iy = ly+i*s(72,w)
        if iy+s(65,w) > sy1: break
        rrect(draw,[sx0+s(15,w),iy,sx1-s(15,w),iy+s(65,w)],s(10,w),fill=(255,255,255))
        wood_grain(draw,sx0+s(25,w),iy+s(8,w),s(50,w),s(50,w),col,i*13)
        draw.text((sx0+s(90,w),iy+s(12,w)),nm,font=font(s(22,w)),fill=(50,35,20))
        draw.text((sx0+s(90,w),iy+s(38,w)),dt,font=font(s(16,w)),fill=(150,130,110))
        draw.text((sx1-s(80,w),iy+s(20,w)),cf,font=font(s(22,w)),fill=acc)

def scene_offline_mode(draw, sc, w, h, acc):
    sx0,sy0,sx1,sy1 = sc; sw,sh = sx1-sx0, sy1-sy0
    rrect(draw, sc, s(32,w), fill=(15,12,8))
    gy = sy0+s(20,w); gh = int(sh*0.55)
    wood_grain(draw,sx0+s(10,w),gy,sw-s(20,w),gh,(145,95,50),77)
    # badge
    bw,bh = s(180,w),s(40,w); bx=sx0+(sw-bw)//2; byy=gy+s(15,w)
    rrect(draw,[bx,byy,bx+bw,byy+bh],s(20,w),fill=(60,60,60))
    draw.text((bx+s(15,w),byy+s(10,w)),"Offline Mode",font=font(s(18,w)),fill=(255,255,255))
    # coreml
    my = gy+gh+s(20,w)
    rrect(draw,[sx0+s(15,w),my,sx1-s(15,w),my+s(70,w)],s(14,w),fill=(255,255,255))
    draw.text((sx0+s(30,w),my+s(12,w)),"CoreML On-Device",font=font(s(22,w)),fill=(50,35,20))
    draw.text((sx0+s(30,w),my+s(40,w)),"No internet required",font=font(s(16,w)),fill=(130,110,85))
    ry = my+s(85,w)
    if ry+s(60,w) < sy1:
        rrect(draw,[sx0+s(15,w),ry,sx1-s(15,w),ry+s(60,w)],s(14,w),fill=(255,255,255))
        draw.text((sx0+s(30,w),ry+s(10,w)),"White Oak — 88% match",font=font(s(22,w)),fill=acc)
        draw.text((sx0+s(30,w),ry+s(38,w)),"Identified offline",font=font(s(14,w)),fill=(150,140,120))

SCENES = {"camera_scan":scene_camera_scan,"database_grid":scene_database_grid,"detail_card":scene_detail_card,
          "compare_mode":scene_compare_mode,"history_view":scene_history_view,"offline_mode":scene_offline_mode}

def generate(spec, dev, size):
    w,h = size
    img = Image.new("RGB",(w,h),spec["bg_color"])
    draw = ImageDraw.Draw(img,"RGBA")
    dark = sum(spec["bg_color"]) < 400
    for y in range(h):
        a = int(30*(y/h))
        draw.line([(0,y),(w,y)], fill=(0,0,0,a) if dark else (255,255,255,a))
    sc = phone_frame(draw,w,h)
    SCENES[spec["scene"]](draw,sc,w,h,spec["accent"])
    caption(draw,w,h,spec["caption"],dark)
    d = os.path.join(OUTPUT_DIR,dev)
    os.makedirs(d,exist_ok=True)
    p = os.path.join(d,f"{spec['id']}.png")
    img.save(p,"PNG")
    return p

def main():
    os.makedirs(OUTPUT_DIR,exist_ok=True)
    t = 0
    for dev,size in DEVICES.items():
        for spec in SCREENSHOTS:
            p = generate(spec,dev,size)
            print(f"  ✓ {p}")
            t += 1
    print(f"\n✅ Generated {t} screenshots in {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
