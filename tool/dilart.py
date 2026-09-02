# -*- coding: utf-8 -*-
"""DİLART terapi PDF'lerini yapısal olarak okur.

Sayfa düzeni her seste aynı: kapak, yönerge, 4 hece sayfası, BAŞTA/ORTADA/SONDA
kelime sayfaları, kelime grupları, cümleler. Bir PDF sayfası = uygulamada bir ekran.
"""
import pymupdf, re, os

LABELS = {"BAŞTA", "ORTADA", "SONDA", "KELİME GRUPLARI", "CÜMLELER"}
BEKLENEN = {"hece": 4, "BAŞTA": 3, "ORTADA": 3, "SONDA": 3, "grup": 2, "cumle": 1}


def norm(t):
    return re.sub(r"\s+", " ", t).strip()


def _satirlar(page):
    """(etiket, [(bbox, metin, punto)]) — etiket satırı ayıklanmış hâlde."""
    etiket, sat = None, []
    for b in page.get_text("dict")["blocks"]:
        if b["type"] != 0:
            continue
        for l in b["lines"]:
            t = norm("".join(s["text"] for s in l["spans"]))
            if not t:
                continue
            if t in LABELS and l["bbox"][1] < page.rect.height * 0.25:
                etiket = t
                continue
            punto = max(s["size"] for s in l["spans"])
            sat.append((l["bbox"], t, punto))
    return etiket, sat


def _tur(page, etiket, sat):
    if not sat and not etiket:
        return "bos"
    if any("MOBİL UYGULAMA" in t for _, t, _ in sat):
        return "kapak"
    if etiket == "KELİME GRUPLARI":
        return "grup"
    if etiket == "CÜMLELER":
        return "cumle"
    if etiket in ("BAŞTA", "ORTADA", "SONDA"):
        return etiket
    return "hece" if max(p for _, _, p in sat) > 120 else "yonerge"


def _birlesim(bboxlar):
    return (min(b[0] for b in bboxlar), min(b[1] for b in bboxlar),
            max(b[2] for b in bboxlar), max(b[3] for b in bboxlar))


def _ogeler(page, tur, sat):
    """[(metin, bbox)] — bbox öğeye ait satırların birleşim kutusu."""
    if tur == "yonerge":
        s = sorted(sat, key=lambda x: x[0][1])
        return [(norm(" ".join(t for _, t, _ in s)), _birlesim([b for b, _, _ in s]))]

    if tur == "cumle":
        # Resmin içindeki metinler (araba plakası vb.) de satır olarak gelir;
        # cümle her zaman sayfanın en büyük puntolu satırıdır.
        enb = max(p for _, _, p in sat)
        s = [x for x in sat if x[2] >= enb - 1]
        return [(norm(" ".join(t for _, t, _ in s)), _birlesim([b for b, _, _ in s]))]

    if tur == "grup":
        # Her öbek iki kelime. PyMuPDF bazen ikisini tek blok yapıyor, o yüzden
        # blok yapısına güvenmeyip sayfa ortasından ikiye ayırıyoruz.
        orta = page.rect.width / 2
        sol = sorted([s for s in sat if (s[0][0] + s[0][2]) / 2 < orta], key=lambda x: x[0][0])
        sag = sorted([s for s in sat if (s[0][0] + s[0][2]) / 2 >= orta], key=lambda x: x[0][0])
        return [(norm(" ".join(t for _, t, _ in g)), _birlesim([b for b, _, _ in g]))
                for g in (sol, sag) if g]

    # hece: bir satırda iki hece olabiliyor ('mo mu'), gerçek boşluk karakteri.
    # kelime: her satır tek kelime.
    out = []
    for bb, t, _ in sorted(sat, key=lambda x: x[0][0]):
        parcalar = t.split() if tur == "hece" else [t]
        if len(parcalar) == 1:
            out.append((parcalar[0], bb))
        else:
            # Satırı parça sayısına göre yatayda eşit böl (yalnız hecede olur).
            g = (bb[2] - bb[0]) / len(parcalar)
            for i, pz in enumerate(parcalar):
                out.append((pz, (bb[0] + i * g, bb[1], bb[0] + (i + 1) * g, bb[3])))
    return out


def sayfalar(path):
    """PDF'i [(sayfa_no, tur, [ogeler])] olarak döndürür."""
    d = pymupdf.open(path)
    for pno in range(d.page_count):
        p = d[pno]
        et, sat = _satirlar(p)
        tur = _tur(p, et, sat)
        if tur in ("kapak", "bos"):
            continue
        yield pno, tur, [t for t, _ in _ogeler(p, tur, sat)]
    d.close()
