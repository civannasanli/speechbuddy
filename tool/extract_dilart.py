# -*- coding: utf-8 -*-
"""DİLART terapi materyallerini PDF'lerden çıkarır.

Üretilenler:
  assets/terapi/<ses>/<ad>.webp   — kart görselleri (sayfa bölgesi render edilerek)
  lib/terapi_data.dart            — materyal kataloğu
  tool/extract_report.md          — doğrulama raporu

Görseller gömülü XObject olarak değil, sayfa bölgesi render edilerek çıkarılır:
materyalde çizimlerin bir kısmı vektör (ör. B-P s7 'bot'), gömülü resim olarak
çıkarılamaz. Render ayrıca hedef sesin renkli vurgusunu da korur.
"""
import pymupdf, os, re, sys, glob, io, json
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dilart import sayfalar, _satirlar, _tur, _ogeler, norm

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PDF_DIR = os.path.join(ROOT, "drivelinkiiçindekiler")
ASSET_DIR = os.path.join(ROOT, "assets", "terapi")
DPI = 110          # render çözünürlüğü
UZUN_KENAR = 512   # kaydedilen görselin uzun kenarı

TR = {"ş": "s", "Ş": "S", "ç": "c", "Ç": "C", "ğ": "g", "Ğ": "G",
      "ı": "i", "İ": "I", "ö": "o", "Ö": "O", "ü": "u", "Ü": "U", "â": "a"}
# Ses klasörü adları — Ş/S ve Ç/C çakışmasın diye ayrı tablo.
SES_SLUG = {"B": "b", "P": "p", "M": "m", "N": "n", "D": "d", "T": "t",
            "K": "k", "G": "g", "F": "f", "V": "v", "S": "s", "Z": "z",
            "Ş": "sh", "J": "j", "C": "c", "Ç": "ch", "H": "h",
            "Y": "y", "L": "l", "R": "r"}


def slug(t):
    t = "".join(TR.get(c, c) for c in t)
    t = re.sub(r"[^A-Za-z0-9]+", "_", t).strip("_").lower()
    return t or "x"


def pdf_sesleri(path):
    """'1) DİLART B-P GÜNCEL.pdf' -> ['B', 'P']"""
    ad = os.path.basename(path)
    m = re.search(r"DİLART\s+(.+?)\s+GÜNCEL", ad)
    return [h for h in m.group(1).split("-") if h]


def sutunlar(page, ogeler):
    """Öğelerin yatay sınırları: komşu ÖĞE merkezlerinin orta noktası.

    Sınırı satır merkezinden hesaplamak yanlış: bir kelime grubu iki satırdan
    (iki kelimeden) oluşuyor, satır sayılırsa sayfa 2 yerine 4'e bölünüp
    kartlar ortadan kesiliyor.
    """
    if len(ogeler) == 1:
        return [(0.0, page.rect.width)]
    merkez = [(b[0] + b[2]) / 2 for _, b in ogeler]
    sinir = [0.0] + [(merkez[i] + merkez[i + 1]) / 2 for i in range(len(merkez) - 1)] + [page.rect.width]
    return list(zip(sinir[:-1], sinir[1:]))


def basliksiz_ust(page):
    """Başlık şeridinin altı — kart bölgesi buradan başlar."""
    for b in page.get_text("dict")["blocks"]:
        if b["type"] != 0:
            continue
        for l in b["lines"]:
            t = norm("".join(s["text"] for s in l["spans"]))
            if t in {"BAŞTA", "ORTADA", "SONDA", "KELİME GRUPLARI", "CÜMLELER"} \
               and l["bbox"][1] < page.rect.height * 0.25:
                return l["bbox"][3] + 4
    return 0.0


def kirp_kaydet(pix, hedef):
    """Beyaz kenarları kırp, uzun kenarı ölçekle, webp yaz. (genişlik, yükseklik, bayt)"""
    im = Image.open(io.BytesIO(pix.tobytes("png"))).convert("RGB")
    gri = im.convert("L")
    maske = gri.point(lambda v: 0 if v > 245 else 255)
    kutu = maske.getbbox()
    if kutu:
        im = im.crop(kutu)
    if max(im.size) > UZUN_KENAR:
        o = UZUN_KENAR / max(im.size)
        im = im.resize((max(1, round(im.width * o)), max(1, round(im.height * o))), Image.LANCZOS)
    os.makedirs(os.path.dirname(hedef), exist_ok=True)
    im.save(hedef, "WEBP", quality=88, method=6)
    return im.width, im.height, os.path.getsize(hedef)


def isle(path, rapor):
    harfler = pdf_sesleri(path)
    d = pymupdf.open(path)
    sesler, aktif = [], None
    kullanilan = set()

    for pno in range(d.page_count):
        p = d[pno]
        et, sat = _satirlar(p)
        tur = _tur(p, et, sat)
        if tur in ("kapak", "bos"):
            continue
        og = _ogeler(p, tur, sat)   # [(metin, bbox)]

        if tur == "yonerge":
            harf = harfler[len(sesler)] if len(sesler) < len(harfler) else "?"
            aktif = {"harf": harf, "slug": SES_SLUG.get(harf, slug(harf)),
                     "yonerge": og[0][0], "ekranlar": []}
            sesler.append(aktif)
            kullanilan = set()
            klasor = os.path.join(ASSET_DIR, aktif["slug"])
            w, h, b = kirp_kaydet(p.get_pixmap(dpi=DPI), os.path.join(klasor, "yonerge.webp"))
            aktif["gorsel"] = f"assets/terapi/{aktif['slug']}/yonerge.webp"
            rapor["gorsel"].append(b)
            continue

        if aktif is None:
            rapor["uyari"].append(f"{os.path.basename(path)} s{pno+1}: yönergesiz sayfa ({tur})")
            continue

        if tur == "hece":
            aktif["ekranlar"].append({"asama": "heceler", "konum": None,
                                      "ogeler": [{"metin": t, "gorsel": None} for t, _ in og]})
            continue

        ust = basliksiz_ust(p)
        kolon = sutunlar(p, og)
        ogeler = []
        for i, (metin, _bb) in enumerate(og):
            x0, x1 = kolon[i]
            pix = p.get_pixmap(dpi=DPI, clip=pymupdf.Rect(x0, ust, x1, p.rect.height))
            if tur == "cumle":
                ad = f"cumle{len([e for e in aktif['ekranlar'] if e['asama']=='cumleler']) + 1}"
            else:
                ad = slug(metin)
            n, temel = 1, ad
            while ad in kullanilan:
                n += 1
                ad = f"{temel}_{n}"
            kullanilan.add(ad)
            yol = os.path.join(ASSET_DIR, aktif["slug"], ad + ".webp")
            w, h, b = kirp_kaydet(pix, yol)
            rapor["gorsel"].append(b)
            if w < 60 or h < 60:
                rapor["uyari"].append(f"{aktif['harf']} '{metin}': görsel çok küçük ({w}x{h})")
            ogeler.append({"metin": metin, "gorsel": f"assets/terapi/{aktif['slug']}/{ad}.webp"})

        asama = {"BAŞTA": "kelimeler", "ORTADA": "kelimeler", "SONDA": "kelimeler",
                 "grup": "kelimeGruplari", "cumle": "cumleler"}[tur]
        konum = tur if tur in ("BAŞTA", "ORTADA", "SONDA") else None
        aktif["ekranlar"].append({"asama": asama, "konum": konum, "ogeler": ogeler})

    d.close()
    if len(sesler) != len(harfler):
        rapor["uyari"].append(f"{os.path.basename(path)}: {len(harfler)} ses bekleniyordu, {len(sesler)} bulundu")
    return sesler


if __name__ == "__main__":
    rapor = {"gorsel": [], "uyari": []}
    tum = []
    for path in sorted(glob.glob(os.path.join(PDF_DIR, "*.pdf")),
                       key=lambda p: int(re.match(r"(\d+)", os.path.basename(p)).group(1))):
        print("işleniyor:", os.path.basename(path), flush=True)
        tum.extend(isle(path, rapor))
    with open(os.path.join(ROOT, "tool", "terapi.json"), "w", encoding="utf-8") as f:
        json.dump({"sesler": tum, "uyari": rapor["uyari"],
                   "gorsel_sayisi": len(rapor["gorsel"]),
                   "gorsel_bayt": sum(rapor["gorsel"])}, f, ensure_ascii=False, indent=1)
    print(f"\nses={len(tum)} görsel={len(rapor['gorsel'])} "
          f"boyut={sum(rapor['gorsel'])/1e6:.1f} MB uyarı={len(rapor['uyari'])}")
    for u in rapor["uyari"][:20]:
        print("  !", u)
