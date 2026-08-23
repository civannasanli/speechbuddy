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
}
