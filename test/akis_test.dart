// Değerlendirme akışının veri tarafı: kelime listesi, etap bölümlenmesi
// ve görsel dosyalarının gerçekten yerinde olması.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled3/main.dart';

void main() {
  test('24 kelime var ve hepsi benzersiz', () {
    expect(AppWords.hepsi.length, 24);
    final kelimeler = AppWords.hepsi.map((w) => w['word']).toSet();
    expect(kelimeler.length, 24);
  });

  test('etaplar toplamı kelime sayısına eşit', () {
    final toplam = AppWords.etaplar.reduce((a, b) => a + b);
    expect(toplam, AppWords.hepsi.length);
  });

  test('mola noktaları 9 ve 18, bitiş kutlama sayılmıyor', () {
    expect(AppWords.molaNoktalari, {9, 18});
    expect(AppWords.molaNoktalari.contains(24), isFalse);
  });

  test('üçerli bölünme tam çıkıyor: 8 ekran, hepsi 3 kelime', () {
    final triplets = chunkList(AppWords.hepsi, 3);
    expect(triplets.length, 8);
    for (final t in triplets) {
      expect(t.length, 3);
    }
  });

  test('mola noktaları üçlü sınırlarına denk geliyor', () {
    // Kutlama ancak bir üçlü bittiğinde çıkabilir; 9 ve 18 üçün katı olmalı.
    for (final nokta in AppWords.molaNoktalari) {
      expect(nokta % 3, 0, reason: '$nokta bir üçlü sınırına denk gelmiyor');
    }
  });

  test('her kelimenin görseli diskte mevcut', () {
    for (final w in AppWords.hepsi) {
      final yol = w['image']!;
      expect(File(yol).existsSync(), isTrue, reason: '$yol bulunamadı');
    }
  });

  test('imageForWord listedeki her kelimeyi buluyor, olmayana null dönüyor', () {
    for (final w in AppWords.hepsi) {
      expect(AppWords.imageForWord(w['word']!), w['image']);
    }
    expect(AppWords.imageForWord('bulunmayankelime'), isNull);
  });

  test('deneme hakkı 3', () {
    expect(kMaxDeneme, 3);
  });

  test('geri bildirim havuzları hocaların tablosuyla birebir', () {
    expect(GeriBildirim.dogruHavuz, [
      'Harika gidiyorsun!',
      'Süpersin!',
      'Çok iyi söyledin!',
      'İşte böyle!',
      'Sesin harika çıkıyor!',
      'Mükemmel iş çıkardın!',
    ]);
    expect(GeriBildirim.hataliHavuz, [
      'Tekrar deneyelim mi?',
      'Daha dikkatli olalım, bir daha dinle.',
      'Hadi birlikte bir daha söyleyelim!',
      'Çok yaklaştın, hadi tekrar!',
      'Bir kez daha deneyebilirsin.',
      'Dikkatlice dinle ve benim gibi yap.',
    ]);
    expect(GeriBildirim.pesEt, 'Sonra bakalım!');
  });

  test('aynı mesaj art arda iki kez gelmiyor', () {
    String? once;
    for (int i = 0; i < 300; i++) {
      final m = GeriBildirim.dogruMesaj();
      expect(GeriBildirim.dogruHavuz, contains(m));
      expect(m, isNot(once), reason: 'aynı övgü art arda tekrarlandı');
      once = m;
    }
    once = null;
    for (int i = 0; i < 300; i++) {
      final m = GeriBildirim.hataliMesaj();
      expect(GeriBildirim.hataliHavuz, contains(m));
      expect(m, isNot(once), reason: 'aynı hata mesajı art arda tekrarlandı');
      once = m;
    }
  });

  test('havuzdaki tüm mesajlar zamanla çıkıyor', () {
    final gorulen = <String>{};
    for (int i = 0; i < 500; i++) {
      gorulen.add(GeriBildirim.dogruMesaj());
    }
    expect(gorulen.length, GeriBildirim.dogruHavuz.length);
  });

  // Bu test bir hatayı yakalamak için var: Sfx sınıfı uzun süre
  // projede olmayan dosyaları (yildiz.wav, alkis.wav, bitti.wav,
  // tekrar.wav) çalmaya çalıştı. Hata catch içinde yutulduğu için
  // hiç ses çıkmadığı fark edilmemişti.
  test('her ses efekti diskte gerçekten var', () {
    for (final asset in [Sfx.dogru, Sfx.yanlis, Sfx.tamamlandi]) {
      final yol = 'assets/$asset';
      expect(File(yol).existsSync(), isTrue, reason: '$yol bulunamadı');
    }
  });
}
