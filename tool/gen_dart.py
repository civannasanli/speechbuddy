# -*- coding: utf-8 -*-
"""tool/terapi.json -> lib/terapi_data.dart (elle düzenlenmez, üretilir)."""
import json, os, sys
sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = json.load(open(os.path.join(ROOT, "tool", "terapi.json"), encoding="utf-8"))


def q(s):
    return "'" + s.replace("\\", r"\\").replace("'", r"\'").replace("$", r"\$") + "'"


L = []
L.append("// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.")
L.append("// Kaynak: drivelinkiiçindekiler/*.pdf,  üretici: tool/extract_dilart.py + tool/gen_dart.py")
L.append("//")
L.append("// Her TerapiEkran bir PDF sayfasına karşılık gelir; sayfadaki öğe sayısı")
L.append("// doğrudan ekranda gösterilecek kart sayısıdır (hece 4, kelime 3, grup 2, cümle 1).")
L.append("")
L.append("enum TerapiAsama { heceler, kelimeler, kelimeGruplari, cumleler }")
L.append("")
L.append("class TerapiOge {")
L.append("  final String metin;")
L.append("  /// Hecelerde görsel yok — kart büyük metin olarak çizilir.")
L.append("  final String? gorsel;")
L.append("  const TerapiOge(this.metin, this.gorsel);")
L.append("}")
L.append("")
L.append("class TerapiEkran {")
L.append("  final TerapiAsama asama;")
L.append("  /// BAŞTA / ORTADA / SONDA — yalnız kelimeler aşamasında dolu.")
L.append("  /// Bölüm sonu sonuç ekranı bu değer değiştiğinde çıkar.")
L.append("  final String? konum;")
L.append("  final List<TerapiOge> ogeler;")
L.append("  const TerapiEkran(this.asama, this.konum, this.ogeler);")
L.append("}")
L.append("")
L.append("class TerapiSes {")
L.append("  final String harf;")
L.append("  final String yonerge;")
L.append("  final String yonergeGorsel;")
L.append("  final List<TerapiEkran> ekranlar;")
L.append("  const TerapiSes(this.harf, this.yonerge, this.yonergeGorsel, this.ekranlar);")
L.append("}")
L.append("")

ASAMA = {"heceler": "TerapiAsama.heceler", "kelimeler": "TerapiAsama.kelimeler",
         "kelimeGruplari": "TerapiAsama.kelimeGruplari", "cumleler": "TerapiAsama.cumleler"}

L.append("const List<TerapiSes> kTerapiSesleri = [")
for s in d["sesler"]:
    L.append(f"  TerapiSes({q(s['harf'])}, {q(s['yonerge'])}, {q(s['gorsel'])}, [")
    for e in s["ekranlar"]:
        konum = q(e["konum"]) if e["konum"] else "null"
        L.append(f"    TerapiEkran({ASAMA[e['asama']]}, {konum}, [")
        for o in e["ogeler"]:
            g = q(o["gorsel"]) if o["gorsel"] else "null"
            L.append(f"      TerapiOge({q(o['metin'])}, {g}),")
        L.append("    ]),")
    L.append("  ]),")
L.append("];")
L.append("")

out = os.path.join(ROOT, "lib", "terapi_data.dart")
open(out, "w", encoding="utf-8", newline="\n").write("\n".join(L))
print("yazıldı:", out, os.path.getsize(out) // 1024, "KB")
