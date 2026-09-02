# -*- coding: utf-8 -*-
import sys, glob, os
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(__file__))
from dilart import sayfalar, BEKLENEN
PDF_DIR = os.path.join(os.path.dirname(__file__), "..", "drivelinkiiçindekiler")
toplam = {}
for path in sorted(glob.glob(os.path.join(PDF_DIR, "*.pdf"))):
    print(f"\n########## {os.path.basename(path)}")
    for pno, tur, og in sayfalar(path):
        toplam[tur] = toplam.get(tur, 0) + len(og)
        exp = BEKLENEN.get(tur)
        flag = f"  <<< BEKLENEN {exp}, BULUNAN {len(og)}" if exp and len(og) != exp else ""
        print(f"  s{pno+1:3d} {tur:8s} {og}{flag}")
print("\n===== TOPLAM =====")
for k, v in sorted(toplam.items()): print(f"  {k:8s} {v}")
