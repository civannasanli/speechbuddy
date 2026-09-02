// ============================================================
// TERAPİ MODÜLÜ
//
// Değerlendirme modülü (Kelimeler/Alıştırmalar) çocuğun telaffuzunu ÖLÇER;
// bu modül sesi ÇALIŞTIRIR. Akış:
//   ses seç -> ses üretim yönergesi (dinlenmeden geçilemez) -> 4 aşama
//   (heceler, kelimeler, kelime grupları, cümleler)
//
// Materyal lib/terapi_data.dart içinde (PDF'lerden üretilir, elle düzenlenmez).
// Bir TerapiEkran = bir PDF sayfası = bir ekran dolusu kart.
//
// Değerlendirme yalnız KELİMELER aşamasında yapılır: model 1-2 sn'lik tek
// kelime klipleriyle eğitildi, hece/öbek/cümlede geçerli değil. O aşamalarda
// kayıt alınır ve saklanır ama doğru/yanlış iddiası yoktur.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'terapi_data.dart';

/// Aşamaya göre, her öğe için art arda alınacak kayıt sayısı. Çocuk her
/// deneme için karta yeniden dokunur; hata sonrası tekrar değil, sabit
/// tekrar sayısıdır. Hecede tek kayıt yeterli: ses üretimi tek seferde
/// görülüyor, tekrar çocuğu yoruyor.
const Map<TerapiAsama, int> kTerapiDeneme = {
  TerapiAsama.heceler: 1,
  TerapiAsama.kelimeler: 3,
  TerapiAsama.kelimeGruplari: 3,
  TerapiAsama.cumleler: 3,
};

/// Aşamaya göre kayıt tavanı. Varsayılan (2.5 sn) tek kelimeye göre ayarlı;
/// öbek ve cümle bunu aşar, kayıt ortadan kesilirdi.
const Map<TerapiAsama, Duration> kTerapiKayitSuresi = {
  TerapiAsama.heceler: Duration(milliseconds: 2500),
  TerapiAsama.kelimeler: Duration(milliseconds: 2500),
  TerapiAsama.kelimeGruplari: Duration(milliseconds: 4000),
  TerapiAsama.cumleler: Duration(milliseconds: 7000),
};

/// Terapi ses efektleri. Sfx sınıfındaki sabitler assets/sesler/ altında
/// bulunmayan dosyalara işaret ediyor; buradakiler gerçek dosyalar.
class TerapiSfx {
  static const String dogru = 'sesler/dogru.m4a';
  static const String notr = 'sesler/yanlis.mp3';
  static const String bitti = 'sesler/tamamlandi.mp3';
}

String terapiAsamaAdi(TerapiAsama a) => switch (a) {
  TerapiAsama.heceler => 'Heceler',
  TerapiAsama.kelimeler => 'Kelimeler',
  TerapiAsama.kelimeGruplari => 'Kelime Grupları',
  TerapiAsama.cumleler => 'Cümleler',
};

// ============================================================
// Geri bildirim havuzları
//
// Taslakta ısrarla belirtilen kural: mesajlar tekdüze olmamalı. Havuzdan
// rastgele seçilir ve aynı mesaj arka arkaya iki kez verilmez.
// ============================================================

class GeriBildirim {
  static const List<String> dogruHavuz = [
    'Harika gidiyorsun!',
    'Süpersin!',
    'Çok iyi söyledin!',
    'İşte böyle!',
    'Sesin harika çıkıyor!',
    'Mükemmel iş çıkardın!',
  ];

  static const List<String> hataliHavuz = [
    'Tekrar deneyelim mi?',
    'Daha dikkatli olalım, bir daha dinle.',
    'Hadi birlikte bir daha söyleyelim!',
    'Çok yaklaştın, hadi tekrar!',
    'Bir kez daha deneyebilirsin.',
    'Dikkatlice dinle ve benim gibi yap.',
  ];

  /// Denemeler ARASINDA kullanılır. Hatalı havuzu buraya konamaz: o mesajlar
  /// ('Daha dikkatli olalım') çocuğun yanlış yaptığını ima eder, oysa üç kayıt
  /// bitip model cevap verene kadar doğru mu yanlış mı bilinmiyor.
  static const List<String> tekrarHavuz = [
    'Bir kez daha söyleyelim!',
    'Hadi birlikte bir daha!',
    'Devam et, bir tane daha!',
    'Güzel, şimdi tekrar söyle.',
  ];

  /// Ses hiç yakalanamadığında. Deneme hakkı yakmaz, o yüzden havuzlardan ayrı.
  static const String duyamadim = 'Seni duyamadım, tekrar dener misin?';

  static final Random _random = Random();
  static String? _sonDogru;
  static String? _sonHatali;
  static String? _sonTekrar;

  static String _sec(List<String> havuz, String? sonuncu) {
    final secenekler = havuz.length > 1
        ? havuz.where((m) => m != sonuncu).toList()
        : havuz;
    return secenekler[_random.nextInt(secenekler.length)];
  }

  static String dogruMesaj() => _sonDogru = _sec(dogruHavuz, _sonDogru);
  static String hataliMesaj() => _sonHatali = _sec(hataliHavuz, _sonHatali);
  static String tekrarMesaj() => _sonTekrar = _sec(tekrarHavuz, _sonTekrar);
}

// ============================================================
// Kalıcı durum
// ============================================================

class TerapiIlerleme {
  static String _key(String harf) => 'terapi_ilerleme_$harf';

  /// Tamamlanan ekran sayısı — yarıda bırakılan ses buradan devam eder.
  static Future<int> oku(String harf) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(harf)) ?? 0;
  }

  static Future<void> yaz(String harf, int ekranIndeksi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(harf), ekranIndeksi);
  }

  static Future<Map<String, int>> hepsi() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final s in kTerapiSesleri) s.harf: prefs.getInt(_key(s.harf)) ?? 0,
    };
  }
}

/// 3 denemenin hiçbirinde doğru üretilemeyen ifadeler —
/// "çalışılmaya devam edilecekler" listesi.
class TerapiChecklist {
  static const _key = 'terapi_checklist';

  static Future<void> ekle({
    required String harf,
    required String metin,
    String? gorsel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    // Aynı ifade tekrar düşerse eskisini güncelle, listeyi şişirme.
    raw.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['harf'] == harf && m['metin'] == metin;
      } catch (_) {
        return false;
      }
    });
    raw.add(
      jsonEncode({
        'harf': harf,
        'metin': metin,
        'gorsel': gorsel,
        'tarih': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList(_key, raw);
  }

  static Future<void> cikar({
    required String harf,
    required String metin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['harf'] == harf && m['metin'] == metin;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, raw);
  }

  static Future<List<Map<String, dynamic>>> oku() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final out = <Map<String, dynamic>>[];
    for (final s in raw) {
      try {
        out.add(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        // Bozuk kayıt atlanır.
      }
    }
    return out;
  }
}
