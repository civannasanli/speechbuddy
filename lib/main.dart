// ============================================================
// TEK DOSYA: main.dart
// Yeni ak covers: Bölüm seç -> 3'lü resim ekranı (dokunarak oku+kaydet,
// mikrofon yok) -> arka planda modele gönder -> "Aferin" ekranı (Devam Et)
// -> son 3'lüde final sonuç ekranı.
// Retry YOK (sonuç olduğu gibi kabul edilir, alıştırmalar modülü sonra).
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// Sunucu Ayarı
// ============================================================

class Config {
  static const String apiIp = "184.174.34.219:8008";
  static const String apiUrl = "http://$apiIp/predict";
}

// ============================================================
// Kayıt eşikleri
//
// Model 1–2 sn'lik tek kelime klipleriyle eğitildi. Sabit süreli kayıtta
// kelimenin ardından uzun sessizlik kalıyor ve HuBERT çıktısı zaman
// ekseninde ortalandığı için hedef sinyal seyreliyor. Bu yüzden kayıt
// sabit süreyle değil, konuşma bitince sonlanır.
// ============================================================

/// Konuşma başlangıç eşiğinin varsayılanı (dBFS).
/// Çalışan değer: [AppSettings.speechStartDb]
const double kDefaultSpeechStartDb = -20.0;

/// Konuşma bitiş eşiğinin varsayılanı. Başlangıçtan kasıtlı olarak daha
/// düşük (histerezis) — kelime ortasındaki kısa duraklamada kesmesin.
/// Çalışan değer: [AppSettings.speechEndDb]
const double kDefaultSpeechEndDb = -38.0;

/// Konuşma bittikten sonra kaydın devam edeceği sürenin varsayılanı (ms).
/// Çalışan değer: [AppSettings.trailingSilenceMs]
const int kDefaultTrailingSilenceMs = 450;

/// Hiç konuşma gelmezse bu süre sonunda vazgeç.
const Duration kNoSpeechTimeout = Duration(milliseconds: 2500);

/// Konuşma başladıktan sonraki tavan (uzun cümle / gürültü koruması).
const Duration kMaxSpeechDuration = Duration(milliseconds: 2500);

/// Bundan kısa "konuşma" tık sesi sayılır.
const Duration kMinSpeechDuration = Duration(milliseconds: 250);

/// UI ilerleme çubuğu tam ölçeği (kayıt genelde daha erken biter).
const Duration kProgressFullScale = Duration(milliseconds: 3000);

/// Klip dolgusunun varsayılanı (ms). Ayarlar ekranından değiştirilebilir;
/// çalışan değer için [AppSettings.clipPadMs] kullanılır.
const int kDefaultClipPadMs = 150;

// ============================================================
// Uygulama ayarları
//
// Tek kaynak: hem Kelimeler hem Alıştırmalar aynı değerleri okur.
// İkisi de aynı API ucuna gittiği için preprocessing'in birebir aynı
// olması şart — ayrı ayrı sabit tutulursa iki modülün sonuçları
// kıyaslanamaz hale gelir.
// ============================================================

class AppSettings {
  /// Kayıt konuşmaya kırpıldıktan sonra iki yana eklenen sessizlik (ms).
  ///
  /// DİKKAT: başlangıç eşiği yüksekse (-20 gibi) sürtünmeli sesler
  /// (/s/, /ş/, /f/) eşiği geçmeyebilir; o durumda konuşma başlangıcı
  /// ünlüden itibaren işaretlenir ve baştaki sürtünme dolgunun içinde
  /// kalır. "sabun, şapka, salıncak" gibi kelimelerde bu değer çok
  /// düşükse kelimenin başı kırpılır. Şüphedeyseniz 300 ms deneyin.
  static int clipPadMs = kDefaultClipPadMs;

  /// Gönderimden önce dalga formunu tepe değerine göre ölçekle.
  ///
  /// Not: HuBERT'in feature extractor'ı zaten klip başına sıfır ortalama /
  /// birim varyans normalizasyonu yapıyor (`do_normalize: true`), yani bu
  /// büyük ölçüde gereksiz. Yine de kayıt seviyesi çok düşük olan
  /// cihazlarda kırpma eşiklerinin davranışını değiştirebilir.
  static bool normalizeAudio = false;

  /// Konuşmanın başladığını kabul ettiğimiz eşik (dBFS).
  ///
  /// Yüksek değer (-20) gürültülü ortamda iyi ama sürtünmeli sesleri
  /// kaçırır. Düşük değer (-36) sessiz konuşan çocuğu yakalar ama zemin
  /// gürültüsüyle tetiklenebilir.
  static double speechStartDb = kDefaultSpeechStartDb;

  /// Konuşmanın bittiğini kabul ettiğimiz eşik (dBFS).
  ///
  /// Başlangıçtan HER ZAMAN düşük olmalı. Bu histerezis, kelime
  /// ortasındaki kısa sessizliklerde (patlamalı ses öncesi kapanma)
  /// kaydın erken kesilmesini engeller.
  static double speechEndDb = kDefaultSpeechEndDb;

  /// Konuşma bittikten sonra kaydın devam edeceği süre (ms).
  static int trailingSilenceMs = kDefaultTrailingSilenceMs;

  static bool soundEnabled = true;
  static double ttsSpeed = 0.4;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    clipPadMs = prefs.getInt('clipPadMs') ?? kDefaultClipPadMs;
    normalizeAudio = prefs.getBool('normalizeAudio') ?? false;
    speechStartDb = prefs.getDouble('speechStartDb') ?? kDefaultSpeechStartDb;
    speechEndDb = prefs.getDouble('speechEndDb') ?? kDefaultSpeechEndDb;
    trailingSilenceMs =
        prefs.getInt('trailingSilenceMs') ?? kDefaultTrailingSilenceMs;
    soundEnabled = prefs.getBool('soundEnabled') ?? true;
    ttsSpeed = prefs.getDouble('ttsSpeed') ?? 0.4;
    enforceHysteresis();
  }

  /// Bitiş eşiği başlangıcın altında kalmalı; değilse kayıt kelimeyi
  /// ortasından böler. En az 4 dB fark zorlanır.
  static void enforceHysteresis() {
    if (speechEndDb > speechStartDb - 4.0) {
      speechEndDb = speechStartDb - 4.0;
    }
    if (speechEndDb < -60.0) speechEndDb = -60.0;
  }

  static Future<void> setClipPadMs(int v) async {
    clipPadMs = v.clamp(0, 1000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clipPadMs', clipPadMs);
  }

  static Future<void> setNormalizeAudio(bool v) async {
    normalizeAudio = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('normalizeAudio', v);
  }

  static Future<void> setSpeechStartDb(double v) async {
    speechStartDb = v.clamp(-50.0, -5.0);
    enforceHysteresis();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speechStartDb', speechStartDb);
    await prefs.setDouble('speechEndDb', speechEndDb);
  }

  static Future<void> setSpeechEndDb(double v) async {
    speechEndDb = v.clamp(-60.0, -8.0);
    enforceHysteresis();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speechEndDb', speechEndDb);
  }

  static Future<void> setTrailingSilenceMs(int v) async {
    trailingSilenceMs = v.clamp(150, 1200);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trailingSilenceMs', trailingSilenceMs);
  }

  static Future<void> setSoundEnabled(bool v) async {
    soundEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', v);
  }

  static Future<void> setTtsSpeed(double v) async {
    ttsSpeed = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ttsSpeed', v);
  }

  /// Kayıt işleme ayarlarını fabrika değerlerine döndürür.
  static Future<void> resetRecording() async {
    clipPadMs = kDefaultClipPadMs;
    normalizeAudio = false;
    speechStartDb = kDefaultSpeechStartDb;
    speechEndDb = kDefaultSpeechEndDb;
    trailingSilenceMs = kDefaultTrailingSilenceMs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clipPadMs', clipPadMs);
    await prefs.setBool('normalizeAudio', normalizeAudio);
    await prefs.setDouble('speechStartDb', speechStartDb);
    await prefs.setDouble('speechEndDb', speechEndDb);
    await prefs.setInt('trailingSilenceMs', trailingSilenceMs);
  }
}

// Ses dosyasını modele gönderir — hem BolumPlayPage hem AlistirmalarPage kullanır.
/// Çocuk cevabı beklerken kullanılan zaman aşımı. Arka plan gönderiminde
/// 15 saniye sorun değildi; artık ekranda bekleyen bir çocuk var ve bu
/// süre boyunca hiçbir şey olmuyor. Cevap gelmezse deneme hakkı yakmadan
/// "tekrar deneyelim" deniyor.
const Duration kBeklerkenTimeout = Duration(seconds: 6);

Future<Map<String, dynamic>> sendPronunciationToApi(
  String filePath, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  try {
    final uri = Uri.parse(Config.apiUrl);
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {"error": true, "message": "API Hatası: ${response.statusCode}"};
  } on TimeoutException {
    return {"error": true, "message": "Sunucu yanıt vermedi"};
  } catch (e) {
    return {"error": true, "message": "Bağlantı koptu!"};
  }
}

// ============================================================
// Akıllı kayıt: sesle sonlanan, değişken uzunluklu
// ============================================================

enum RecordOutcome {
  ok, // konuşma yakalandı, dosya hazır
  noSpeech, // hiç ses gelmedi
  tooShort, // tık sesi / çok kısa
  failed, // izin yok veya kayıt hatası
}

class SmartRecordResult {
  final RecordOutcome outcome;
  final String? path;
  final int speechMs;
  final int totalMs;

  /// Kayıt boyunca görülen en yüksek dBFS — eşik kalibrasyonu için.
  final double peakDb;

  const SmartRecordResult(
      this.outcome, {
        this.path,
        this.speechMs = 0,
        this.totalMs = 0,
        this.peakDb = -160.0,
      });

  bool get isOk => outcome == RecordOutcome.ok && path != null;

  @override
  String toString() =>
      'KAYIT ${outcome.name} speech=${speechMs}ms total=${totalMs}ms '
          'peak=${peakDb.toStringAsFixed(1)}dB '
          '(start=${AppSettings.speechStartDb} end=${AppSettings.speechEndDb} '
          'pad=${AppSettings.clipPadMs}ms)';
}

/// WAV dosyasını konuşma bölgesine kırpar ve iki yana [padMs] sessizlik koyar.
///
/// Neden: model 1–2 sn'lik tek kelime klipleriyle eğitildi ve HuBERT çıktısı
/// zaman ekseninde ortalanıyor. Çocuk geç başlarsa baştaki uzun sessizlik,
/// erken keserse sondaki eksiklik embedding'i kaydırır. Bu fonksiyon klibi
/// "250ms sessizlik + konuşma + 250ms sessizlik" biçimine sabitler, böylece
/// modele giden girdi çocuğun tepki süresinden bağımsız hale gelir.
///
/// 16-bit PCM bekler; başka formatta dosyaya dokunmadan döner.
Future<void> trimAndPadWav(
    String path, {
      required int speechStartMs,
      required int speechEndMs,
      int padMs = kDefaultClipPadMs,
      bool normalize = false,
    }) async {
  try {
    final file = File(path);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return;

    String tag(int o) => String.fromCharCodes(bytes.sublist(o, o + 4));
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') return;

    final bd = ByteData.sublistView(bytes);

    int pos = 12;
    int sampleRate = 16000;
    int channels = 1;
    int bits = 16;
    int dataOffset = -1;
    int dataSize = 0;

    while (pos + 8 <= bytes.length) {
      final id = tag(pos);
      final size = bd.getUint32(pos + 4, Endian.little);
      final body = pos + 8;
      if (id == 'fmt ' && body + 16 <= bytes.length) {
        channels = bd.getUint16(body + 2, Endian.little);
        sampleRate = bd.getUint32(body + 4, Endian.little);
        bits = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataOffset = body;
        dataSize = size;
        break;
      }
      pos = body + size + (size.isOdd ? 1 : 0);
    }

    if (dataOffset < 0 || bits != 16 || channels < 1) return;

    final frameBytes = channels * (bits ~/ 8);
    final available = min(dataSize, bytes.length - dataOffset);
    if (available <= 0) return;

    int msToBytes(int ms) => ((ms * sampleRate) ~/ 1000) * frameBytes;

    final wantStart = msToBytes(speechStartMs) - msToBytes(padMs);
    final wantEnd = msToBytes(speechEndMs) + msToBytes(padMs);

    // Dosyada olmayan kısımlar sessizlikle tamamlanır.
    final headPad = wantStart < 0 ? -wantStart : 0;
    final tailPad = wantEnd > available ? wantEnd - available : 0;

    final cutStart = wantStart.clamp(0, available);
    final cutEnd = wantEnd.clamp(cutStart, available);
    if (cutEnd <= cutStart && headPad == 0 && tailPad == 0) return;

    var core = bytes.sublist(dataOffset + cutStart, dataOffset + cutEnd);

    // Tepe normalizasyonu — yalnızca konuşma bölgesine uygulanır,
    // dolgu sessizliği zaten sıfır.
    if (normalize && core.length >= 2) {
      final cd = ByteData.sublistView(core);
      int peak = 0;
      for (int i = 0; i + 1 < core.length; i += 2) {
        final v = cd.getInt16(i, Endian.little).abs();
        if (v > peak) peak = v;
      }
      // Çok sessiz kayıtta gürültüyü şişirmemek için alt sınır.
      if (peak > 500) {
        final gain = (32767 * 0.95) / peak;
        if (gain > 1.02 || gain < 0.98) {
          final scaled = Uint8List(core.length);
          final sd = ByteData.sublistView(scaled);
          for (int i = 0; i + 1 < core.length; i += 2) {
            final v = (cd.getInt16(i, Endian.little) * gain).round();
            sd.setInt16(i, v.clamp(-32768, 32767), Endian.little);
          }
          core = scaled;
        }
      }
    }

    final newDataSize = headPad + core.length + tailPad;

    final header = Uint8List.fromList(bytes.sublist(0, dataOffset));
    final hd = ByteData.sublistView(header);
    hd.setUint32(4, dataOffset - 8 + newDataSize, Endian.little);
    hd.setUint32(dataOffset - 4, newDataSize, Endian.little);

    final out = BytesBuilder();
    out.add(header);
    if (headPad > 0) out.add(Uint8List(headPad));
    out.add(core);
    if (tailPad > 0) out.add(Uint8List(tailPad));

    await file.writeAsBytes(out.takeBytes(), flush: true);
  } catch (e) {
    // Kırpma başarısızsa orijinal dosya bozulmadan kalır — gönderim sürer.
    debugPrint('WAV kırpma atlandı: $e');
  }
}

/// Çocuk konuşmayı bitirince duran kayıt.
class SmartRecorder {
  final AudioRecorder _recorder;

  SmartRecorder(this._recorder);

  StreamSubscription<Amplitude>? _sub;
  Timer? _uiTimer;
  Completer<SmartRecordResult>? _completer;
  bool _closing = false;

  /// Konuşmanın kayıt içindeki başlangıç/bitiş anları (ms).
  /// Kaydı kırpıp iki yana sabit sessizlik koymak için kullanılır.
  int? _speechStartMs;
  int? _speechEndMs;

  /// Kayıt boyunca görülen en yüksek dBFS. Eşik ayarlarken tek işe
  /// yarayan sayı bu: "noSpeech" alıyorsanız tepe değeri başlangıç
  /// eşiğinin altında kalmış demektir.
  double _peakDb = -160.0;

  Future<SmartRecordResult> record({
    required String path,
    void Function(double progress)? onProgress,
  }) async {
    if (!await _recorder.hasPermission()) {
      return const SmartRecordResult(RecordOutcome.failed);
    }

    try {
      await _recorder.start(
        const RecordConfig(
          // WAV kayıpsız. AAC 4–8 kHz bandını buduyor, /s/ ve /ş/
          // sürtünmelerinin enerjisi tam orada.
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (_) {
      return const SmartRecordResult(RecordOutcome.failed);
    }

    _closing = false;
    final completer = Completer<SmartRecordResult>();
    _completer = completer;

    final startedAt = DateTime.now();
    DateTime? speechStart;
    DateTime? lastVoiced;
    int frame = 0;
    _speechStartMs = null;
    _speechEndMs = null;
    _peakDb = -160.0;

    if (onProgress != null) {
      _uiTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
        onProgress(
          (elapsed / kProgressFullScale.inMilliseconds).clamp(0.0, 1.0),
        );
      });
    }

    _sub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      // İlk frame mikrofon açılış patlaması — yoksay.
      frame++;
      if (frame <= 1) return;
      if (_closing) return;

      final now = DateTime.now();
      final db = amp.current;
      if (db > _peakDb) _peakDb = db;

      // Faz 1: konuşmanın başlamasını bekle
      if (speechStart == null) {
        if (db > AppSettings.speechStartDb) {
          speechStart = now;
          lastVoiced = now;
          _speechStartMs = now.difference(startedAt).inMilliseconds;
          // Konuşma tek frame sürerse _speechEndMs null kalmasın,
          // yoksa kırpma sessizce atlanır.
          _speechEndMs = _speechStartMs;
        } else if (now.difference(startedAt) > kNoSpeechTimeout) {
          _finish(RecordOutcome.noSpeech, startedAt, null);
        }
        return;
      }

      // Faz 2: konuşmanın bitmesini bekle
      if (db > AppSettings.speechEndDb) {
        lastVoiced = now;
        _speechEndMs = now.difference(startedAt).inMilliseconds;
      }

      final speechMs = now.difference(speechStart!).inMilliseconds;
      final silentFor = now.difference(lastVoiced!);

      if (silentFor.inMilliseconds >= AppSettings.trailingSilenceMs) {
        _finish(
          speechMs < kMinSpeechDuration.inMilliseconds
              ? RecordOutcome.tooShort
              : RecordOutcome.ok,
          startedAt,
          speechStart,
        );
      } else if (speechMs >= kMaxSpeechDuration.inMilliseconds) {
        _finish(RecordOutcome.ok, startedAt, speechStart);
      }
    });

    return completer.future;
  }

  Future<void> _finish(
      RecordOutcome outcome,
      DateTime startedAt,
      DateTime? speechStart,
      ) async {
    if (_closing) return;
    _closing = true;

    _uiTimer?.cancel();
    _uiTimer = null;
    await _sub?.cancel();
    _sub = null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }

    // Konuşma yakalandıysa klibi normalize et:
    // 250ms sessizlik + konuşma + 250ms sessizlik.
    if (path != null &&
        outcome == RecordOutcome.ok &&
        _speechStartMs != null &&
        _speechEndMs != null) {
      await trimAndPadWav(
        path,
        speechStartMs: _speechStartMs!,
        speechEndMs: _speechEndMs!,
        padMs: AppSettings.clipPadMs,
        normalize: AppSettings.normalizeAudio,
      );
    }

    final now = DateTime.now();
    final result = SmartRecordResult(
      path == null ? RecordOutcome.failed : outcome,
      path: path,
      speechMs: speechStart == null
          ? 0
          : now.difference(speechStart).inMilliseconds,
      totalMs: now.difference(startedAt).inMilliseconds,
      peakDb: _peakDb,
    );
    // Eşik ayarlamak için gereken tek çıktı.
    debugPrint(result.toString());

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(result);
    }
    _completer = null;
  }

  Future<void> cancel() async {
    if (_closing) return;
    _closing = true;
    _uiTimer?.cancel();
    await _sub?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(
        SmartRecordResult(RecordOutcome.failed, peakDb: _peakDb),
      );
    }
    _completer = null;
  }

  void dispose() {
    _uiTimer?.cancel();
    _sub?.cancel();
  }
}

// ============================================================
// Ses efektleri
//
// pubspec.yaml -> flutter -> assets altına `assets/sesler/` ekli olmalı.
// Gerekli dosyalar:
//   assets/sesler/yildiz.wav   kelime kaydedilince (kısa "ding")
//   assets/sesler/alkis.wav    3'lü bitince
//   assets/sesler/bitti.wav    bölüm sonu fanfar
//   assets/sesler/tekrar.wav   ses yakalanamadı — NÖTR olmalı
//
// Ses çalmıyorsa sırayla kontrol et:
//   1. pubspec.yaml -> flutter: -> assets: altında `- assets/sesler/` var mı
//   2. Dosya adları birebir aynı mı (büyük/küçük harf dahil)
//   3. `flutter clean && flutter pub get` — asset manifest bayatlar
//   4. Konsolda "SFX çalınamadı" satırı sebebi yazar
//
// Ücretsiz kaynak: mixkit.co/free-sound-effects/game/ ya da freesound.org
// Arama: "success chime", "level complete", "sparkle".
//
// DİKKAT — tekrar.wav için hata/buzzer sesi KULLANMA. Bu tetikleyici
// telaffuzun yanlış olmasıyla değil, mikrofonun sesi yakalayamamasıyla
// ilgili. Sert bir "yanlış" sesi duyan çocuk telaffuzunun kötü olduğunu
// sanar. Nötr seç: yumuşak "pop", hafif zil, iki notalık kısa motif.
// Arama: "soft pop", "gentle notification", "bubble".
// ============================================================

class Sfx {
  // DİKKAT: buradaki adlar assets/sesler/ altında GERÇEKTEN bulunan
  // dosyalar olmalı. Eskiden yildiz.wav / alkis.wav / bitti.wav /
  // tekrar.wav çalınmaya çalışılıyordu; dördü de projede yok, bu yüzden
  // uygulama açıldığından beri tek bir efekt sesi çıkmamıştı (hata
  // aşağıdaki catch içinde sessizce yutuluyor).
  static const String dogru = 'sesler/dogru.m4a';
  static const String yanlis = 'sesler/yanlis.mp3';
  static const String tamamlandi = 'sesler/tamamlandi.mp3';

  /// Efektler kısa ve üst üste binebiliyor; havuzdan boş player alınır.
  /// Tek player paylaşılırsa yeni efekt öncekini kesiyor.
  static final List<AudioPlayer> _pool = [];
  static const int _poolSize = 4;
  static int _next = 0;

  static AudioPlayer _take() {
    if (_pool.length < _poolSize) {
      final p = AudioPlayer();
      // Efekt sesi zil/alarm kanalına düşmesin, medya olarak çalsın.
      p.setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
      return p;
    }
    final p = _pool[_next % _poolSize];
    _next++;
    return p;
  }

  static Future<void> play(String asset, {double volume = 0.9}) async {
    try {
      final player = _take();
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    } catch (e) {
      // Sessizce yut ama sebebi logla — dosya adı/pubspec hatalarını
      // görmeden "ses çalmıyor" diye uğraşmak zaman kaybı.
      debugPrint('SFX çalınamadı ($asset): $e');
    }
  }

  static Future<void> disposeAll() async {
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
  }
}

/// Kayıt tamamlandı onayı — çubuğun yerini alır.
Widget _doneTick(double size) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.6, end: 1.0),
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.62),
    ),
  );
}

// ============================================================
// Renk Paleti — canlı turuncu/pembe tema
// ============================================================

// ============================================================
// Geri Bildirim — hocaların hazırladığı mesaj havuzu.
// Tekdüze olmasın diye her seferinde rastgele seçiliyor; art arda
// aynı mesajın gelmemesi için bir önceki seçim havuzdan eleniyor.
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

  /// Üçüncü deneme de tutmayınca. Havuzda değil — bu mesaj "tekrar dene"
  /// demiyor, kelimeyi geçtiğimizi söylüyor.
  static const String pesEt = 'Sonra bakalım!';

  /// Ses hiç yakalanamadığında. Deneme hakkı yakmaz, o yüzden hata
  /// havuzundan ayrı tutuluyor.
  static const String duyamadim = 'Seni duyamadım, tekrar dener misin?';

  static final Random _random = Random();
  static String? _sonDogru;
  static String? _sonHatali;

  static String _sec(List<String> havuz, String? sonuncu) {
    final secenekler = havuz.length > 1
        ? havuz.where((m) => m != sonuncu).toList()
        : havuz;
    return secenekler[_random.nextInt(secenekler.length)];
  }

  static String dogruMesaj() {
    final m = _sec(dogruHavuz, _sonDogru);
    _sonDogru = m;
    return m;
  }

  static String hataliMesaj() {
    final m = _sec(hataliHavuz, _sonHatali);
    _sonHatali = m;
    return m;
  }
}

/// Kelime başına verilen deneme hakkı.
const int kMaxDeneme = 3;

class AppColors {
  static const Color primary = Color(0xFFFF7A3D); // canlı turuncu
  static const Color primaryDark = Color(0xFFE8611F);
  static const Color secondary = Color(0xFFFF4D8D); // canlı pembe
  static const Color background = Color(0xFFFFF1E6); // sıcak krem
  static const Color surfaceLight = Color(
    0xFFFFDCC2,
  ); // açık turuncu (kilitli/kart zemini)
}

// ============================================================
// Köşe Hayvanları — ekranların köşesinde rastgele beliren
// balon tutan hayvan illüstrasyonları. Yeni hayvan eklemek için
// sadece assets/hayvanlar/ altına PNG at ve listeye ekle;
// yeni ekran eklenirse aynı pickRandom() fonksiyonu kullanılır,
// hiçbir yerde ekran/hayvan eşleşmesi hardcode edilmez.
// ============================================================

class CornerAnimals {
  static const List<String> assets = [
    'assets/hayvanlar/fil.png',
    'assets/hayvanlar/maymun.png',
    'assets/hayvanlar/rakun.png',
    'assets/hayvanlar/ayi.png',
    'assets/hayvanlar/tavsan.png',
    'assets/hayvanlar/fil2.png',
    'assets/hayvanlar/ayi2.png',
    'assets/hayvanlar/kopek.png',
    'assets/hayvanlar/civciv.png',
    'assets/hayvanlar/tavsan2.png',
  ];

  /// Mola ekranında "Yeni arkadaş: ..." yazısı için görünen adlar.
  static const Map<String, String> adlar = {
    'assets/hayvanlar/fil.png': 'Fil',
    'assets/hayvanlar/maymun.png': 'Maymun',
    'assets/hayvanlar/rakun.png': 'Rakun',
    'assets/hayvanlar/ayi.png': 'Ayı',
    'assets/hayvanlar/tavsan.png': 'Tavşan',
    'assets/hayvanlar/fil2.png': 'Fil',
    'assets/hayvanlar/ayi2.png': 'Ayı',
    'assets/hayvanlar/kopek.png': 'Köpek',
    'assets/hayvanlar/civciv.png': 'Civciv',
    'assets/hayvanlar/tavsan2.png': 'Tavşan',
  };

  static final Random _random = Random();

  static String pickRandom() => assets[_random.nextInt(assets.length)];

  /// Mola ödülü: henüz kazanılmamış ilk hayvan; hepsi kazanıldıysa rastgele.
  static String pickReward(Set<String> kazanilanlar) => assets.firstWhere(
        (a) => !kazanilanlar.contains(a),
    orElse: pickRandom,
  );
}

// ============================================================
// Gün Serisi (Streak) — bölüm menüsü her açıldığında güncellenir.
// Aynı gün tekrar açılırsa sayaç değişmez, bir gün atlanırsa sıfırlanır.
// ============================================================

class StreakService {
  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<int> touchAndGetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    final lastKey = prefs.getString('streak_last_date');
    int streak = prefs.getInt('streak_count') ?? 0;

    if (lastKey == todayKey) {
      // bugün zaten sayıldı, değiştirme
    } else if (lastKey != null) {
      final last = DateTime.parse(lastKey);
      final today = DateTime.parse(todayKey);
      streak = today.difference(last).inDays == 1 ? streak + 1 : 1;
    } else {
      streak = 1;
    }

    await prefs.setInt('streak_count', streak);
    await prefs.setString('streak_last_date', todayKey);
    return streak;
  }
}

// ============================================================
// Hayvan Koleksiyonu — çocuğun bugüne kadar köşede gördüğü
// (rastgele gelen) hayvanların kalıcı kaydı. "Rozetler" ekranında
// koleksiyon tamamlanma durumunu göstermek için kullanılıyor.
// ============================================================

class AnimalCollectionService {
  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('animals_collected') ?? []).toSet();
  }

  static Future<void> recordSeen(String assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList('animals_collected') ?? []).toSet();
    if (current.add(assetPath)) {
      await prefs.setStringList('animals_collected', current.toList());
    }
  }
}

// ============================================================
// Kelime Geçmişi — Veli/Terapist Paneli için kalıcı kayıt.
// Her bölüm bitişinde denenen kelimelerin sonucu (doğru/yanlış,
// tarih) burada birikiyor; panel bunu kelime bazında özetliyor.
// ============================================================

class WordHistoryService {
  static const _key = 'kelime_gecmisi';

  static Future<void> recordResult({
    required String word,
    required bool isPathological,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(
      jsonEncode({
        'word': word,
        'isPathological': isPathological,
        'date': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList(_key, raw);
  }

  static Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList(growable: false);
  }

  // Kelime -> {deneme, dogru, sonTarih, sonSonucDogruMu}
  static Future<List<WordStat>> aggregate() async {
    final history = await loadHistory();
    final Map<String, WordStat> byWord = {};
    for (final entry in history) {
      final word = entry['word'] as String;
      final isPathological = entry['isPathological'] as bool;
      final date = DateTime.parse(entry['date'] as String);
      final stat = byWord.putIfAbsent(word, () => WordStat(word: word));
      stat.attempts++;
      if (!isPathological) stat.correct++;
      if (stat.lastDate == null || date.isAfter(stat.lastDate!)) {
        stat.lastDate = date;
        stat.lastCorrect = !isPathological;
      }
    }
    final list = byWord.values.toList();
    list.sort((a, b) => a.successRate.compareTo(b.successRate));
    return list;
  }
}

class WordStat {
  final String word;
  int attempts = 0;
  int correct = 0;
  DateTime? lastDate;
  bool lastCorrect = true;

  WordStat({required this.word});

  double get successRate => attempts == 0 ? 1.0 : correct / attempts;
}

// ============================================================
// GradientButton — ana çağrı-eylem butonları için ortak görsel:
// gradient dolgu + yumuşak renkli gölge. Basılınca hafifçe küçülür.
// ============================================================

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double fontSize;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 220,
    this.height = 70,
    this.fontSize = 26,
    this.colors = const [AppColors.primary, AppColors.secondary],
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.colors.last.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PopStar — bölüm kartlarındaki yıldızlar sırayla "pop" ile belirir.
// ============================================================

class PopStar extends StatefulWidget {
  final bool filled;
  final Duration delay;
  final double size;

  const PopStar({
    super.key,
    required this.filled,
    required this.delay,
    this.size = 22,
  });

  @override
  State<PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<PopStar> {
  double _scale = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _scale = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 380),
      curve: Curves.elasticOut,
      child: Icon(
        widget.filled ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: widget.size,
      ),
    );
  }
}

// ============================================================
// Ortak sayfa geçişi — hafif kayma + solma. Uygulamadaki her
// Navigator.push burayı kullanır, tek yerden ayarlanır.
// ============================================================

class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  SlideFadeRoute({required WidgetBuilder builder})
      : super(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) =>
        builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ============================================================
// main() ve MyApp
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ayarlar ilk kayıttan önce hazır olmalı — iki modül de aynı
  // preprocessing değerlerini kullanacak.
  await AppSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Okuma Prototipi',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.baloo2TextTheme(),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HomePage
// ============================================================

// Kedi konuşma balonuyla merhaba diyor, buton yok — animasyon bitince
// (ya da 4sn içinde bir şeyler ters giderse güvenlik zamanlayıcısıyla)
// otomatik olarak menüye geçiyor.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _safetyTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goToMenu();
    });
    _safetyTimer = Timer(const Duration(seconds: 4), _goToMenu);
  }

  void _goToMenu() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      SlideFadeRoute(builder: (context) => const MenuPage()),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SpeechBubble(text: 'Merhaba! Hazır mısın?'),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              height: 260,
              child: Lottie.asset(
                'assets/lottie/waving_kitty.lottie',
                controller: _controller,
                repeat: false,
                errorBuilder: (c, e, s) => Image.asset(
                  'assets/maskot/maskot.png',
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.pets,
                    size: 150,
                    color: AppColors.primary,
                  ),
                ),
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  _controller.forward();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Basit konuşma balonu — beyaz kutu + 45 derece döndürülmüş küçük kare kuyruk.
class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Veri: AppWords
// Değerlendirme modülü — 24 kelime, DİLART görsel setinin sırasıyla.
// Bölüm YOK: tek kesintisiz akış. Kutlama durakları etaplar[] ile
// belirleniyor; etaplar toplamı hepsi.length'e eşit olmalı.
// ============================================================

class AppWords {
  static const List<Map<String, String>> hepsi = [
    {'image': 'assets/dilart/peynir.png', 'word': 'peynir'},
    {'image': 'assets/dilart/elma.png', 'word': 'elma'},
    {'image': 'assets/dilart/bardak.png', 'word': 'bardak'},
    {'image': 'assets/dilart/yatak.png', 'word': 'yatak'},
    {'image': 'assets/dilart/dondurma.png', 'word': 'dondurma'},
    {'image': 'assets/dilart/ayakkabi.png', 'word': 'ayakkabı'},
    {'image': 'assets/dilart/bayrak.png', 'word': 'bayrak'},
    {'image': 'assets/dilart/gunes.png', 'word': 'güneş'},
    {'image': 'assets/dilart/havuc.png', 'word': 'havuç'},
    {'image': 'assets/dilart/anahtar.png', 'word': 'anahtar'},
    {'image': 'assets/dilart/limon.png', 'word': 'limon'},
    {'image': 'assets/dilart/bisiklet.png', 'word': 'bisiklet'},
    {'image': 'assets/dilart/sabun.png', 'word': 'sabun'},
    {'image': 'assets/dilart/uzum.png', 'word': 'üzüm'},
    {'image': 'assets/dilart/sapka.png', 'word': 'şapka'},
    {'image': 'assets/dilart/kasik.png', 'word': 'kaşık'},
    {'image': 'assets/dilart/cocuk.png', 'word': 'çocuk'},
    {'image': 'assets/dilart/yilan.png', 'word': 'yılan'},
    {'image': 'assets/dilart/salincak.png', 'word': 'salıncak'},
    {'image': 'assets/dilart/vazo.png', 'word': 'vazo'},
    {'image': 'assets/dilart/firca.png', 'word': 'fırça'},
    {'image': 'assets/dilart/telefon.png', 'word': 'telefon'},
    {'image': 'assets/dilart/jilet.png', 'word': 'jilet'},
    {'image': 'assets/dilart/ruj.png', 'word': 'ruj'},
  ];

  /// Kutlama duraklarının uzunlukları: 9 + 9 + 6 = 24.
  static const List<int> etaplar = [9, 9, 6];

  /// Kutlama ekranının çıkacağı kümülatif kelime sayıları: {9, 18}.
  /// Son etabın bitişinde kutlama değil, bitiş ekranı gelir.
  static final Set<int> molaNoktalari = () {
    final noktalar = <int>{};
    int toplam = 0;
    for (int i = 0; i < etaplar.length - 1; i++) {
      toplam += etaplar[i];
      noktalar.add(toplam);
    }
    return noktalar;
  }();

  /// Alıştırmalar modülü — kelimeden görsel yolu bulur.
  static String? imageForWord(String word) {
    for (final w in hepsi) {
      if (w['word'] == word) return w['image'];
    }
    return null;
  }
}

// Bir listeyi 'size' büyüklüğünde parçalara böler (son parça küçük olabilir)
List<List<T>> chunkList<T>(List<T> list, int size) {
  final List<List<T>> result = [];
  for (int i = 0; i < list.length; i += size) {
    final end = (i + size > list.length) ? list.length : i + size;
    result.add(list.sublist(i, end));
  }
  return result;
}

// ============================================================
// MenuPage — karşılama ekranından sonraki ana hub. Üstte Veli
// Paneli + Ayarlar, ortada "Bölümler"/"Alıştırmalar" YATAY
// KAYDIRILABİLİR kartlar (buton değil, PageView).
// ============================================================

class _MenuCardData {
  final String title;
  final String subtitle;
  final String lottieAsset;
  final List<Color> colors;
  final VoidCallback onTap;
  const _MenuCardData({
    required this.title,
    required this.subtitle,
    required this.lottieAsset,
    required this.colors,
    required this.onTap,
  });
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _current = 0;

  /// Rozetler ekranı için: seri, akıştaki ilerleme ve sonuç.
  int _streak = 0;
  int _ilerleme = 0;
  int _yildiz = 0;
  bool _tamamlandi = false;

  @override
  void initState() {
    super.initState();
    _loadDurum();
  }

  /// Gün serisi eskiden bölüm listesi açılırken sayılıyordu; bölüm listesi
  /// kalktığı için artık menü açılışında sayılıyor.
  Future<void> _loadDurum() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = await StreakService.touchAndGetStreak();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _ilerleme = prefs.getInt('akis_tamamlanan') ?? 0;
      _yildiz = prefs.getInt('akis_yildiz') ?? 0;
      _tamamlandi = prefs.getBool('akis_tamamlandi') ?? false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_MenuCardData>[
      _MenuCardData(
        title: 'Kelimeler',
        subtitle: _ilerleme > 0 && !_tamamlandi
            ? '${_ilerleme + 1}. kelimeden devam et'
            : '${AppWords.hepsi.length} kelime, tek seferde',
        lottieAsset: 'assets/lottie/cute_cat_works.lottie',
        colors: const [AppColors.primary, AppColors.secondary],
        onTap: () => Navigator.push(
          context,
          SlideFadeRoute(builder: (context) => const BolumPlayPage()),
        ).then((_) => _loadDurum()),
      ),
      _MenuCardData(
        title: 'Alıştırmalar',
        subtitle: 'Zorlandığın kelimeleri tekrar et',
        lottieAsset: 'assets/lottie/reading_cat.lottie',
        colors: const [AppColors.secondary, AppColors.primary],
        onTap: () => Navigator.push(
          context,
          SlideFadeRoute(builder: (context) => const AlistirmalarPage()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Menü'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.white),
            tooltip: 'Rozetlerim',
            onPressed: () => Navigator.push(
              context,
              SlideFadeRoute(
                builder: (context) => RozetlerPage(
                  ilerleme: _ilerleme,
                  yildiz: _yildiz,
                  tamamlandi: _tamamlandi,
                  streak: _streak,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.insights, color: Colors.white),
            tooltip: 'Veli / Terapist Paneli',
            onPressed: () => Navigator.push(
              context,
              SlideFadeRoute(builder: (context) => const VeliPanelPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Ayarlar',
            onPressed: () => Navigator.push(
              context,
              SlideFadeRoute(builder: (context) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                height: 460,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: cards.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, i) {
                    final c = cards[i];
                    return AnimatedScale(
                      scale: i == _current ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Center(
                          child: GestureDetector(
                            onTap: c.onTap,
                            child: Container(
                              width: 280,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: c.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.colors.last.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 190,
                                    height: 190,
                                    child: Lottie.asset(
                                      c.lottieAsset,
                                      repeat: true,
                                      errorBuilder: (ctx, e, s) =>
                                      const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    c.title,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      c.subtitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              cards.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _current ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _current
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================
// VeliPanelPage — kelime bazlı geçmiş özeti. En çok zorlanılan
// (başarı oranı düşük) kelimeler üstte gösterilir, veli/terapist
// çocuğun hangi seslerde zorlandığını zaman içinde görebilir.
// ============================================================

class VeliPanelPage extends StatefulWidget {
  const VeliPanelPage({super.key});

  @override
  State<VeliPanelPage> createState() => _VeliPanelPageState();
}

class _VeliPanelPageState extends State<VeliPanelPage> {
  List<WordStat>? stats;

  @override
  void initState() {
    super.initState();
    WordHistoryService.aggregate().then((s) {
      if (!mounted) return;
      setState(() => stats = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Veli / Terapist Paneli'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: stats == null
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : stats!.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Henüz bir bölüm tamamlanmadı — çocuğun ilk pratiğinden sonra kelime bazlı sonuçlar burada birikecek.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: stats!.length,
              itemBuilder: (context, i) {
                final s = stats![i];
                final pct = (s.successRate * 100).round();
                final zayif = s.successRate < 0.6;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: zayif
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        child: Icon(
                          zayif ? Icons.priority_high : Icons.check,
                          color: zayif ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        s.word.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${s.attempts} deneme • Son sonuç: ${s.lastCorrect ? "doğru" : "yanlış"}',
                      ),
                      trailing: Text(
                        '%$pct',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: zayif ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (stats!.any((s) => s.successRate < 0.6))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GradientButton(
                label: 'Zayıf Kelimeleri Alıştır',
                width: double.infinity,
                height: 60,
                fontSize: 18,
                onPressed: () {
                  final weak = stats!
                      .where((s) => s.successRate < 0.6)
                      .toList();
                  Navigator.push(
                    context,
                    SlideFadeRoute(
                      builder: (context) =>
                          AlistirmalarPage(weakWords: weak),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// AlistirmalarPage — zayıf kelimeleri tek tek tekrar ettirir.
// Bölüm akışından bağımsız, sıra/yıldız kaydı yapmaz; her sonucu
// WordHistoryService'e yazar (Veli Paneli otomatik güncellenir).
// ============================================================

class AlistirmalarPage extends StatefulWidget {
  // null verilirse (ör. menüden doğrudan girildiğinde) zayıf kelimeler
  // WordHistoryService'ten kendisi yüklenir — VeliPanelPage'e bağımlı değil.
  final List<WordStat>? weakWords;
  const AlistirmalarPage({super.key, this.weakWords});

  @override
  State<AlistirmalarPage> createState() => _AlistirmalarPageState();
}

class _AlistirmalarPageState extends State<AlistirmalarPage> {
  List<Map<String, String>>? queue;
  int index = 0;
  bool isRecording = false;
  double recordProgress = 0.0;
  bool finished = false;
  final List<Map<String, dynamic>> results = [];

  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();
  late final SmartRecorder _smart = SmartRecorder(_audioRecorder);

  /// Bu kelimede harcanan deneme (0..kMaxDeneme). Ses yakalanamayan ve
  /// sunucuya ulaşılamayan denemeler sayılmaz.
  int _deneme = 0;

  /// Model cevabı bekleniyor — çocuk bu sırada dokunamıyor.
  bool _modelBekliyor = false;

  /// Üst üste kaç kez sunucuya ulaşılamadı (bkz. _degerlendir).
  int _baglantiHatasi = 0;

  /// Ekranda duran geri bildirim. [_mesajDogru] null ise nötr (pes etme).
  String? _mesaj;
  bool? _mesajDogru;
  Timer? _mesajTimer;

  bool showRetryHint = false;
  Timer? _retryHintTimer;

  /// Kayıt başarıyla bitince çubuk yerine kısa süre yeşil tik gösterilir.
  /// (Zamanlayıcı yok — tik ve ilerleme _startRecording içinde tek akışta
  /// yönetiliyor, ayrı timer ile yarışıyordu.)
  bool showDoneTick = false;

  /// Dokunma kilidi. `isRecording` yetmiyor: TTS kelimeyi okurken henüz
  /// false olduğu için ikinci dokunuş ikinci bir TTS + kayıt başlatıyordu
  /// ve aynı AudioRecorder üzerinde iki kayıt çakışıyordu.
  bool _busy = false;

  /// Ölçüm: istek süreleri ve özet ekranındaki bekleme.
  final List<int> _uploadMs = [];
  int? _finalWaitMs;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _initTts();
  }

  Future<void> _loadQueue() async {
    List<WordStat> weak = widget.weakWords ?? [];
    if (widget.weakWords == null) {
      final stats = await WordHistoryService.aggregate();
      weak = stats.where((s) => s.successRate < 0.6).toList();
    }
    if (!mounted) return;
    setState(() {
      queue = weak
          .map(
            (s) => {
          'word': s.word,
          'image': AppWords.imageForWord(s.word) ?? '',
        },
      )
          .where((w) => w['image']!.isNotEmpty)
          .toList();
    });
  }

  Future<void> _initTts() async {
    // Ayarlar ekranından dönülmüş olabilir; güncel değerleri al.
    await AppSettings.load();
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(
      AppSettings.soundEnabled ? AppSettings.ttsSpeed : 0.0,
    );
    await _tts.setVolume(AppSettings.soundEnabled ? 1.0 : 0.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _onTap() async {
    if (_busy || isRecording || _modelBekliyor || finished || queue == null) {
      return;
    }
    _busy = true;
    try {
      final word = queue![index]['word']!;
      await _tts.speak(word);
      if (!mounted) return;
      await _startRecording(word);
    } finally {
      if (mounted) _busy = false;
    }
  }

  Future<void> _startRecording(String word) async {
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/alistir_${DateTime.now().millisecondsSinceEpoch}.wav';

    setState(() {
      isRecording = true;
      recordProgress = 0.0;
    });

    final rec = await _smart.record(
      path: filePath,
      onProgress: (p) {
        if (mounted) setState(() => recordProgress = p);
      },
    );

    if (!mounted) return;

    if (!rec.isOk) {
      setState(() {
        isRecording = false;
        recordProgress = 0.0;
      });
      if (rec.outcome == RecordOutcome.noSpeech ||
          rec.outcome == RecordOutcome.tooShort) {
        _showRetry();
      }
      return;
    }

    // Değerlendirme modülüyle aynı: çocuk model cevabını bekliyor,
    // doğru/yanlış bilgisi olmadan deneme hakkı işletilemez.
    setState(() {
      recordProgress = 1.0;
      isRecording = false;
      _modelBekliyor = true;
    });

    final t0 = DateTime.now();
    final result = await sendPronunciationToApi(
      rec.path!,
      timeout: kBeklerkenTimeout,
    );
    if (!mounted) return;
    _uploadMs.add(DateTime.now().difference(t0).inMilliseconds);
    setState(() => _modelBekliyor = false);

    await _degerlendir(word, result);
  }

  // ------------------------------------------------------------
  // Üç deneme: doğruysa geç, yanlışsa hak kaldıysa tekrar, bittiyse bırak.
  // ------------------------------------------------------------
  Future<void> _degerlendir(String word, Map<String, dynamic> result) async {
    final hata = result['error'] == true;

    // Sunucuya ulaşılamadı — çocuğun hatası değil, hak yanmıyor. Ama sunucu
    // kapalıysa çocuk aynı resimde kilitlenir; üst üste kMaxDeneme hatadan
    // sonra kelime geçilir ve geçmişe hiçbir şey yazılmaz.
    if (hata) {
      _baglantiHatasi++;
      if (_baglantiHatasi < kMaxDeneme) {
        await _mesajGoster(GeriBildirim.hataliMesaj(), dogru: false);
        _kaydiTemizle();
        return;
      }
      _baglantiHatasi = 0;
      await _mesajGoster(GeriBildirim.pesEt, dogru: null);
      _kaydiTemizle();
      _sonrakiKelime();
      return;
    }

    _baglantiHatasi = 0;
    final hataliTelaffuz = result['is_pathological'] == true;
    _deneme++;

    if (!hataliTelaffuz) {
      unawaited(Sfx.play(Sfx.dogru));
      await _sonucuKaydet(word, result, dogru: true);
      await _mesajGoster(GeriBildirim.dogruMesaj(), dogru: true);
      _kaydiTemizle();
      _sonrakiKelime();
      return;
    }

    unawaited(Sfx.play(Sfx.yanlis, volume: 0.7));

    if (_deneme < kMaxDeneme) {
      await _mesajGoster(GeriBildirim.hataliMesaj(), dogru: false);
      _kaydiTemizle();
      return;
    }

    await _sonucuKaydet(word, result, dogru: false);
    await _mesajGoster(GeriBildirim.pesEt, dogru: null);
    _kaydiTemizle();
    _sonrakiKelime();
  }

  /// Geçmişe ve özet listesine SADECE son sonuç yazılır.
  Future<void> _sonucuKaydet(
    String word,
    Map<String, dynamic> result, {
    required bool dogru,
  }) async {
    await WordHistoryService.recordResult(
      word: word,
      isPathological: !dogru,
    );
    if (!mounted) return;
    setState(() {
      results.add({
        'word': word,
        'correct': dogru,
        'error': false,
        'pending': false,
        'deneme': _deneme,
      });
    });
  }

  Future<void> _mesajGoster(String mesaj, {required bool? dogru}) async {
    if (!mounted) return;
    setState(() {
      _mesaj = mesaj;
      _mesajDogru = dogru;
    });
    await _tts.speak(mesaj);
    if (!mounted) return;
    _mesajTimer?.cancel();
    _mesajTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _mesaj = null);
    });
  }

  /// Geri bildirim bandı — yer her zaman ayrılıyor ki resim zıplamasın.
  Widget _geriBildirimBandi() {
    final mesaj = _mesaj;
    final dogru = _mesajDogru;
    final Color renk = dogru == null
        ? const Color(0xFFC2185B)
        : (dogru ? Colors.green.shade700 : const Color(0xFFB84A22));

    return SizedBox(
      height: 54,
      child: AnimatedOpacity(
        opacity: mesaj == null ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: mesaj == null
            ? const SizedBox.shrink()
            : Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: renk, width: 2),
          ),
          child: Text(
            mesaj,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: renk,
            ),
          ),
        ),
      ),
    );
  }

  /// Harcanan deneme hakkı — çocuk sayı okuyamıyor, üç nokta okuyor.
  Widget _denemeNoktalari(int deneme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kMaxDeneme, (i) {
        final harcandi = i < deneme;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: harcandi
                ? const Color(0xFFE8623A)
                : AppColors.surfaceLight,
          ),
        );
      }),
    );
  }

  void _kaydiTemizle() {
    if (!mounted) return;
    setState(() {
      showDoneTick = false;
      isRecording = false;
      recordProgress = 0.0;
    });
  }

  /// Sonraki kelimeye geçerken deneme sayacı sıfırlanır.
  void _sonrakiKelime() {
    _deneme = 0;
    _advance();
  }

  /// Ses yakalanamadı: nötr efekt + görsel ipucu.
  /// Efekt tek başına yetmez — okuma bilmeyen yaştaki çocuk sadece bir
  /// "pop" duyunca ne yapacağını bilemez, o yüzden ikon da gösteriliyor.
  void _showRetry() {
    unawaited(Sfx.play(Sfx.yanlis, volume: 0.5));
    if (!mounted) return;
    setState(() => showRetryHint = true);
    _retryHintTimer?.cancel();
    _retryHintTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => showRetryHint = false);
    });
  }

  void _advance() {
    if (!mounted || queue == null) return;
    if (index < queue!.length - 1) {
      setState(() => index++);
    } else {
      // Artık bekleyen analiz yok: her kelimenin sonucu, o kelime
      // bitmeden önce geldi. Özet ekranı anında dolu açılıyor.
      setState(() {
        finished = true;
        _finalWaitMs = 0;
      });
      unawaited(Sfx.play(Sfx.tamamlandi));
    }
  }

  @override
  void dispose() {
    _retryHintTimer?.cancel();
    _mesajTimer?.cancel();
    _smart.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (queue == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Alıştır'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (queue!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Alıştır'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Şu an alıştırılacak kelime yok — harika gidiyorsun!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    if (finished) return _buildSummary();

    final w = queue![index];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alıştır'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${index + 1} / ${queue!.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _modelBekliyor
                  ? 'Dinliyorum...'
                  : 'Resme dokun ve kelimeyi tekrar oku!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _geriBildirimBandi(),
            const SizedBox(height: 8),
            _denemeNoktalari(_deneme),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _onTap,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            w['image']!,
                            fit: BoxFit.cover,
                            // errorBuilder yoksa eksik asset kırmızı hata
                            // kutusu olarak çıkıyordu.
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.surfaceLight,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 56,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        if (isRecording)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: showDoneTick
                                    ? Colors.green
                                    : Colors.red,
                                width: 4,
                              ),
                            ),
                          ),
                        if (_modelBekliyor)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Lottie.asset(
                                'assets/lottie/cat_loader.lottie',
                                repeat: true,
                                errorBuilder: (c, e, s) =>
                                    const CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        if (isRecording)
                          Center(
                            child: showDoneTick
                                ? _doneTick(60)
                                : SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: recordProgress,
                                strokeWidth: 5,
                                valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                                backgroundColor: Colors.white70,
                              ),
                            ),
                          ),
                        _retryHintOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Text(
              w['word']!.toUpperCase(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// "Tekrar dene" ipucu — ses yakalanamadığında 1.8 sn görünür.
  Widget _retryHintOverlay() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: showRetryHint ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Tekrar dene!',
                style: GoogleFonts.baloo2(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final correctCount = results.where((r) => r['correct'] == true).length;
    final pendingCount = results.where((r) => r['pending'] == true).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alıştırma Bitti'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              pendingCount > 0
                  ? 'Sonuçlar geliyor...'
                  : '$correctCount / ${results.length} doğru!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final r = results[i];
                final pending = r['pending'] == true;
                final isError = r['error'] == true;
                final correct = r['correct'] == true;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: pending
                          ? AppColors.surfaceLight
                          : (isError
                          ? Colors.grey
                          : (correct ? Colors.green : Colors.red)),
                      child: pending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                          : Icon(
                        isError
                            ? Icons.warning
                            : (correct ? Icons.check : Icons.close),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      (r['word'] as String).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      pending
                          ? 'Analiz ediliyor...'
                          : (isError
                          ? 'Analiz edilemedi'
                          : (correct
                          ? 'Bu sefer doğru!'
                          : 'Hâlâ zorlanıyor')),
                    ),
                  ),
                );
              },
            ),
          ),
          _timingLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: GradientButton(
              label: 'Tamam',
              width: double.infinity,
              height: 60,
              fontSize: 22,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Ölçüm satırı — bkz. BolumPlayPage._timingLine açıklaması.
  Widget _timingLine() {
    if (_uploadMs.isEmpty && _finalWaitMs == null) {
      return const SizedBox.shrink();
    }
    final avg = _uploadMs.isEmpty
        ? 0
        : (_uploadMs.reduce((a, b) => a + b) / _uploadMs.length).round();
    final worst = _uploadMs.isEmpty
        ? 0
        : _uploadMs.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(
        'bekleme ${_finalWaitMs ?? 0} ms  •  '
            'istek ort ${avg} ms / en yavaş ${worst} ms  •  '
            'n=${_uploadMs.length}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    );
  }
}

// ============================================================
// RozetlerPage — kazanılan/kilitli rozetler. Tamamlanma/yıldız/
// seri rozetleri MenuPage'den gelen veriyle anında hesaplanır,
// hayvan koleksiyonu rozeti için kalıcı kayıt async yükleniyor.
// ============================================================

class _RozetTanimi {
  final String baslik;
  final String aciklama;
  final IconData icon;
  final bool kazanildi;
  const _RozetTanimi({
    required this.baslik,
    required this.aciklama,
    required this.icon,
    required this.kazanildi,
  });
}

class RozetlerPage extends StatefulWidget {
  /// Akışta bugüne kadar tamamlanan kelime sayısı (0–24).
  final int ilerleme;
  final int yildiz;
  final bool tamamlandi;
  final int streak;

  const RozetlerPage({
    super.key,
    required this.ilerleme,
    required this.yildiz,
    required this.tamamlandi,
    required this.streak,
  });

  @override
  State<RozetlerPage> createState() => _RozetlerPageState();
}

class _RozetlerPageState extends State<RozetlerPage> {
  int? collectedAnimalCount;

  @override
  void initState() {
    super.initState();
    AnimalCollectionService.load().then((set) {
      if (!mounted) return;
      setState(() => collectedAnimalCount = set.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ilkMola = widget.ilerleme >= AppWords.etaplar.first;
    final yildizUstasi = widget.yildiz >= 3;
    final tumKelimeler = widget.tamamlandi;
    final seri3 = widget.streak >= 3;
    final seri7 = widget.streak >= 7;
    final koleksiyonTam =
        collectedAnimalCount != null &&
            collectedAnimalCount! >= CornerAnimals.assets.length;

    final rozetler = <_RozetTanimi>[
      _RozetTanimi(
        baslik: 'İlk Adım',
        aciklama: 'İlk ${AppWords.etaplar.first} kelimeyi bitir',
        icon: Icons.flag,
        kazanildi: ilkMola,
      ),
      _RozetTanimi(
        baslik: 'Yıldız Ustası',
        aciklama: 'Değerlendirmeden 3 yıldız al',
        icon: Icons.star,
        kazanildi: yildizUstasi,
      ),
      _RozetTanimi(
        baslik: '3 Günlük Seri',
        aciklama: '3 gün üst üste pratik yap',
        icon: Icons.local_fire_department,
        kazanildi: seri3,
      ),
      _RozetTanimi(
        baslik: '7 Günlük Seri',
        aciklama: '7 gün üst üste pratik yap',
        icon: Icons.whatshot,
        kazanildi: seri7,
      ),
      _RozetTanimi(
        baslik: 'Hayvan Koleksiyoncusu',
        aciklama: 'Mola ekranlarında tüm hayvanları kazan',
        icon: Icons.pets,
        kazanildi: koleksiyonTam,
      ),
      _RozetTanimi(
        baslik: 'Şampiyon',
        aciklama: '${AppWords.hepsi.length} kelimenin hepsini bitir',
        icon: Icons.emoji_events,
        kazanildi: tumKelimeler,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rozetlerim'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: rozetler.length,
        itemBuilder: (context, i) {
          final r = rozetler[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              elevation: r.kazanildi ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: r.kazanildi
                            ? AppColors.surfaceLight
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        r.kazanildi ? r.icon : Icons.lock_outline,
                        color: r.kazanildi ? AppColors.primary : Colors.grey,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.baslik,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: r.kazanildi ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.aciklama,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r.kazanildi)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// BolumPlayPage — 24 kelimelik kesintisiz akışı yönetir:
// üçerli gösterim -> kayıt -> arka planda modele gönderim
// -> 9. ve 18. kelimede mola ekranı -> 24.'te bitiş ekranı.
// Bölüm seçimi yok; yarıda bırakılırsa kaldığı yerden devam eder.
// ============================================================

enum _Stage { loading, playing, encourage, final_ }

class BolumPlayPage extends StatefulWidget {
  const BolumPlayPage({super.key});

  @override
  State<BolumPlayPage> createState() => _BolumPlayPageState();
}

class _BolumPlayPageState extends State<BolumPlayPage>
    with TickerProviderStateMixin {
  late List<Map<String, String>> words; // akıştaki tüm kelimeler (24)
  late List<List<Map<String, String>>>
  triplets; // 3'erli (son parça 2 olabilir)
  late List<int>
  tripletOffsets; // her tripletin flat listedeki başlangıç indeksi

  int tripletIndex = 0;
  _Stage stage = _Stage.loading;

  /// Mola ekranında kazanılan hayvan ve o ana kadarki koleksiyon.
  String? _molaOdulu;
  Set<String> _kazanilanHayvanlar = {};

  /// Molaya girildiği andaki biten kelime sayısı. Geçiş animasyonu sırasında
  /// tripletIndex çoktan ilerlemiş oluyor; ekranın "9 kelime bitti" demeye
  /// devam etmesi için değer donduruluyor.
  int _molaBiten = 0;

  /// Geçiş animasyonunda arkada kalan ekran mola ekranı mıydı?
  bool _wipeMoladan = false;

  List<bool> completedTap = []; // mevcut triplet için, hangi resim kaydedildi
  List<String?> audioPaths = []; // global index -> ses dosya yolu
  List<Map<String, dynamic>?> apiResults = []; // global index -> model sonucu

  /// Kelime başına harcanan deneme (global index -> 0..kMaxDeneme).
  /// Ses yakalanamayan ve sunucuya ulaşılamayan denemeler sayılmaz.
  late List<int> denemeSayaci;

  bool isRecording = false;
  double recordProgress = 0.0;
  int? recordingGlobalIndex;

  /// Model cevabı bekleniyor — çocuk bu sırada hiçbir şeye dokunamıyor.
  bool _modelBekliyor = false;

  /// Üst üste kaç kez sunucuya ulaşılamadı. Bağlantı hatası deneme hakkı
  /// yakmaz, ama sunucu kapalıyken çocuğun aynı resimde kilitlenmemesi için
  /// bu sayaç kMaxDeneme'ye ulaşınca kelime geçilir.
  int _baglantiHatasi = 0;

  /// Ekranda duran geri bildirim. [_mesajDogru] null ise nötr (pes etme).
  String? _mesaj;
  bool? _mesajDogru;
  Timer? _mesajTimer;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();
  late final SmartRecorder _smart = SmartRecorder(_audioRecorder);
  late ConfettiController _confettiController;

  late AnimationController _transitionController;
  Duration? _transitionDuration;
  bool _isTransitioning = false;
  Timer? _encourageDelayTimer;

  bool showRetryHint = false;
  Timer? _retryHintTimer;

  /// Kayıt başarıyla bitince çubuk yerine kısa süre yeşil tik.
  bool showDoneTick = false;
  Timer? _doneTickTimer;

  /// Dokunma kilidi. `isRecording` yetmiyor: TTS kelimeyi okurken henüz
  /// false olduğu için ikinci resme dokunulunca ikinci bir kayıt
  /// başlıyordu ve aynı AudioRecorder üzerinde çakışıyordu.
  bool _busy = false;

  /// Ölçüm: her isteğin gidiş-dönüş süresi ve final ekranındaki bekleme.
  final List<int> _uploadMs = [];
  int? _finalWaitMs;

  late String _cornerAnimalAsset;

  @override
  void initState() {
    super.initState();
    words = AppWords.hepsi;
    triplets = chunkList(words, 3);

    tripletOffsets = [];
    int running = 0;
    for (final t in triplets) {
      tripletOffsets.add(running);
      running += t.length;
    }

    audioPaths = List.filled(words.length, null);
    apiResults = List.filled(words.length, null);
    denemeSayaci = List.filled(words.length, 0);
    completedTap = List.filled(triplets[0].length, false);
    _cornerAnimalAsset = CornerAnimals.pickRandom();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _transitionController = AnimationController(vsync: this);
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isTransitioning) {
        setState(() => _isTransitioning = false);
      }
    });
    _initTts();
    _kaldiginYerdenYukle();
  }

  // ------------------------------------------------------------
  // Yarıda bırakılan akışı geri yükler. Tamamlanan kelime sayısı ve
  // o kelimelerin model sonuçları kalıcı; çocuk kaldığı üçlüden devam
  // eder. Akış bitince bu kayıtlar silinir (bkz. _saveSonuc).
  // ------------------------------------------------------------
  Future<void> _kaldiginYerdenYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final kazanilanlar = await AnimalCollectionService.load();
    if (!mounted) return;

    final tamamlanan = (prefs.getInt('akis_tamamlanan') ?? 0).clamp(
      0,
      words.length,
    );
    final kayitli = prefs.getStringList('akis_sonuclar') ?? const [];

    for (int i = 0; i < kayitli.length && i < apiResults.length; i++) {
      if (kayitli[i].isEmpty) continue;
      try {
        apiResults[i] = jsonDecode(kayitli[i]) as Map<String, dynamic>;
      } catch (_) {
        // Bozuk kayıt: o kelime "analiz edilemedi" olarak görünür.
      }
    }

    // Tamamlanan kelime sayısı her zaman 3'ün katı — üçlü bitmeden kaydetmiyoruz.
    final baslangicTriplet = (tamamlanan ~/ 3).clamp(0, triplets.length - 1);

    setState(() {
      _kazanilanHayvanlar = kazanilanlar;
      tripletIndex = tamamlanan >= words.length ? 0 : baslangicTriplet;
      completedTap = List.filled(currentTripletWords.length, false);
      stage = _Stage.playing;
    });
  }

  Future<void> _initTts() async {
    // Ayarlar ekranından dönülmüş olabilir; güncel değerleri al.
    await AppSettings.load();
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(
      AppSettings.soundEnabled ? AppSettings.ttsSpeed : 0.0,
    );
    await _tts.setVolume(AppSettings.soundEnabled ? 1.0 : 0.0);
    await _tts.awaitSpeakCompletion(true); // konuşma bitene kadar bekle
  }

  List<Map<String, String>> get currentTripletWords => triplets[tripletIndex];

  // ------------------------------------------------------------
  // Resme dokununca: önce kelimeyi seslendir, sonra kaydı başlat
  // ------------------------------------------------------------
  Future<void> _onImageTap(int localIndex) async {
    if (_busy || isRecording || _modelBekliyor || completedTap[localIndex]) {
      return;
    }
    if (stage != _Stage.playing || _isTransitioning) return;

    _busy = true;
    try {
      final globalIndex = tripletOffsets[tripletIndex] + localIndex;
      final word = currentTripletWords[localIndex]['word']!;

      // awaitSpeakCompletion(true) sayesinde konuşma bitene kadar bekler
      await _tts.speak(word);
      if (!mounted) return;
      await _startRecording(globalIndex, localIndex);
    } finally {
      if (mounted) _busy = false;
    }
  }

  Future<void> _startRecording(int globalIndex, int localIndex) async {
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

    setState(() {
      isRecording = true;
      recordProgress = 0.0;
      recordingGlobalIndex = globalIndex;
    });

    final rec = await _smart.record(
      path: filePath,
      onProgress: (p) {
        if (mounted) setState(() => recordProgress = p);
      },
    );

    if (!mounted) return;

    if (!rec.isOk) {
      setState(() {
        isRecording = false;
        recordProgress = 0.0;
        recordingGlobalIndex = null;
      });
      if (rec.outcome == RecordOutcome.noSpeech ||
          rec.outcome == RecordOutcome.tooShort) {
        _showRetry();
      }
      return;
    }

    audioPaths[globalIndex] = rec.path;

    // Buradan itibaren çocuk model cevabını BEKLİYOR. Eskiden kayıt arka
    // planda gidiyordu ve ekran hemen ilerliyordu; üç deneme sistemi
    // doğru/yanlış bilgisini şimdi istediği için beklemek zorunlu.
    setState(() {
      recordProgress = 1.0;
      isRecording = false;
      _modelBekliyor = true;
    });

    final t0 = DateTime.now();
    final result = await sendPronunciationToApi(
      rec.path!,
      timeout: kBeklerkenTimeout,
    );
    if (!mounted) return;
    _uploadMs.add(DateTime.now().difference(t0).inMilliseconds);

    setState(() => _modelBekliyor = false);
    await _degerlendir(globalIndex, localIndex, result);
  }

  // ------------------------------------------------------------
  // Model cevabına göre karar: doğruysa geç, yanlışsa tekrar hakkı ver,
  // üçüncüde de olmazsa kelimeyi bırak.
  // ------------------------------------------------------------
  Future<void> _degerlendir(
    int globalIndex,
    int localIndex,
    Map<String, dynamic> result,
  ) async {
    final hata = result['error'] == true;

    // Sunucuya ulaşılamadı: bu çocuğun hatası değil, deneme hakkı yakmıyoruz.
    // Ama sunucu tamamen kapalıysa hak da yanmadığı için çocuk aynı resimde
    // sonsuza kadar takılır — üst üste kMaxDeneme hatadan sonra kelimeyi geç.
    if (hata) {
      _baglantiHatasi++;
      if (_baglantiHatasi < kMaxDeneme) {
        await _mesajGoster(GeriBildirim.hataliMesaj(), dogru: false);
        _kaydiTemizle();
        return;
      }
      // Sonuç bilinmiyor: geçmişe HİÇBİR ŞEY yazma, kelimeyi sadece geç.
      _baglantiHatasi = 0;
      setState(() => completedTap[localIndex] = true);
      await _mesajGoster(GeriBildirim.pesEt, dogru: null);
      _kaydiTemizle();
      if (mounted) _checkTripletDone();
      return;
    }

    _baglantiHatasi = 0;
    final hataliTelaffuz = result['is_pathological'] == true;
    denemeSayaci[globalIndex]++;

    if (!hataliTelaffuz) {
      apiResults[globalIndex] = result;
      unawaited(Sfx.play(Sfx.dogru));
      setState(() => completedTap[localIndex] = true);
      await _sonucuYaz(globalIndex, result);
      await _mesajGoster(GeriBildirim.dogruMesaj(), dogru: true);
      _kaydiTemizle();
      if (mounted) _checkTripletDone();
      return;
    }

    unawaited(Sfx.play(Sfx.yanlis, volume: 0.7));

    if (denemeSayaci[globalIndex] < kMaxDeneme) {
      // Hak kaldı: kelime açık kalıyor, çocuk resme tekrar dokunacak.
      await _mesajGoster(GeriBildirim.hataliMesaj(), dogru: false);
      _kaydiTemizle();
      return;
    }

    // Üç hak da bitti: sonucu yaz, kelimeyi geç.
    apiResults[globalIndex] = result;
    setState(() => completedTap[localIndex] = true);
    await _sonucuYaz(globalIndex, result);
    await _mesajGoster(GeriBildirim.pesEt, dogru: null);
    _kaydiTemizle();
    if (mounted) _checkTripletDone();
  }

  /// Geçmişe SADECE son sonuç yazılır — ara denemeler Veli Paneli'ndeki
  /// başarı oranını olduğundan kötü gösterirdi.
  Future<void> _sonucuYaz(
    int globalIndex,
    Map<String, dynamic> result,
  ) async {
    await WordHistoryService.recordResult(
      word: words[globalIndex]['word']!,
      isPathological: result['is_pathological'] == true,
    );
    await _sonuclariKaydet();
  }

  /// Mesajı ekranda göster ve sesli oku. Çocuk yazıyı okuyamıyor, o yüzden
  /// geri bildirim TTS olmadan yarım kalır.
  Future<void> _mesajGoster(String mesaj, {required bool? dogru}) async {
    if (!mounted) return;
    setState(() {
      _mesaj = mesaj;
      _mesajDogru = dogru;
    });
    await _tts.speak(mesaj);
    if (!mounted) return;
    _mesajTimer?.cancel();
    _mesajTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _mesaj = null);
    });
  }

  void _kaydiTemizle() {
    if (!mounted) return;
    setState(() {
      recordProgress = 0.0;
      recordingGlobalIndex = null;
      showDoneTick = false;
    });
  }

  /// Ses yakalanamadı: nötr efekt + görsel ipucu.
  void _showRetry() {
    unawaited(Sfx.play(Sfx.yanlis, volume: 0.5));
    if (!mounted) return;
    setState(() => showRetryHint = true);
    _retryHintTimer?.cancel();
    _retryHintTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => showRetryHint = false);
    });
  }

  /// "Tekrar dene" ipucu — ses yakalanamadığında 1.8 sn görünür.
  Widget _retryHintOverlay() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: showRetryHint ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mic_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tekrar dene!',
                  style: GoogleFonts.baloo2(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Eldeki model sonuçlarını diske yazar (sonuç geldikçe).
  Future<void> _sonuclariKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'akis_sonuclar',
      apiResults.map((r) => r == null ? '' : jsonEncode(r)).toList(),
    );
  }

  /// Kaç kelimenin bittiğini diske yazar. Üçlü değiştikten sonra çağrılır,
  /// böylece değer her zaman tamamlanmış üçlülerin kelime sayısıdır.
  Future<void> _ilerlemeyiKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('akis_tamamlanan', tripletOffsets[tripletIndex]);
  }

  /// Üçlü bitti: son kelime bir mola noktasına denk geliyorsa kutlama
  /// ekranı, değilse doğrudan sonraki üçlüye kedi geçişi.
  void _checkTripletDone() {
    if (!completedTap.every((c) => c)) return;

    final bitenKelime =
        tripletOffsets[tripletIndex] + currentTripletWords.length;
    final sonUclu = tripletIndex >= triplets.length - 1;
    final mola = AppWords.molaNoktalari.contains(bitenKelime);

    unawaited(Sfx.play(Sfx.tamamlandi));

    if (!mola && !sonUclu) {
      // Ara üçlüler: kutlama yok, doğrudan geçiş.
      _wipeMoladan = false;
      _startTransition();
      return;
    }

    if (mola) {
      final odul = CornerAnimals.pickReward(_kazanilanHayvanlar);
      unawaited(AnimalCollectionService.recordSeen(odul));
      setState(() {
        _molaOdulu = odul;
        _molaBiten = bitenKelime;
        _kazanilanHayvanlar = {..._kazanilanHayvanlar, odul};
        stage = _Stage.encourage;
      });
      _confettiController.play();
      _wipeMoladan = true;
      // Mola ekranı seyredilsin, sonra kendiliğinden devam etsin.
      _encourageDelayTimer?.cancel();
      _encourageDelayTimer = Timer(
        const Duration(milliseconds: 2600),
        _startTransition,
      );
      return;
    }

    // Son üçlü: doğrudan bitiş ekranına.
    _wipeMoladan = false;
    _startTransition();
  }

  // ------------------------------------------------------------
  // "Aferin!" ekranından sonra tıklama olmadan otomatik başlar:
  // hedef içerik (sonraki triplet ya da final) hemen state'e yazılır,
  // kedi geçiş animasyonu bu içeriği eskisinin üzerinden "açığa çıkarır".
  // Son triplet ise, bekleyen analizler arka planda beklenir.
  // ------------------------------------------------------------
  void _startTransition() {
    if (!mounted) return;

    if (tripletIndex < triplets.length - 1) {
      setState(() {
        tripletIndex++;
        completedTap = List.filled(currentTripletWords.length, false);
        stage = _Stage.playing;
        _isTransitioning = true;
        _cornerAnimalAsset = CornerAnimals.pickRandom();
      });
      unawaited(_ilerlemeyiKaydet());
    } else {
      setState(() {
        stage = _Stage.final_;
        _isTransitioning = true;
      });
      unawaited(Sfx.play(Sfx.tamamlandi));
      // Bekleyen gönderim kalmadı: her kelimenin sonucu, o kelime
      // bitmeden önce geldi. Sonuç ekranı anında dolu açılıyor.
      setState(() => _finalWaitMs = 0);
      unawaited(_saveSonuc());
    }

    _transitionController.reset();
    if (_transitionDuration != null) {
      _transitionController.forward();
    }
    // Süre henüz bilinmiyorsa (ilk oynatma), Lottie'nin onLoaded'ı forward'ı tetikler.
  }

  /// Akış bitti: yıldızı hesapla, tamamlandı işaretle, devam kaydını sil.
  /// Kelime geçmişi her kelime bitince zaten yazıldı (bkz. _sonucuYaz).
  Future<void> _saveSonuc() async {
    final prefs = await SharedPreferences.getInstance();

    int totalStars = 0;
    for (final res in apiResults) {
      if (res == null || res['error'] == true) continue;
      if (res['is_pathological'] != true) totalStars += 3;
    }
    final avgStars = words.isEmpty ? 0 : (totalStars / words.length).round();

    await prefs.setInt('akis_yildiz', avgStars);
    await prefs.setBool('akis_tamamlandi', true);
    await prefs.remove('akis_tamamlanan');
    await prefs.remove('akis_sonuclar');
  }

  @override
  void dispose() {
    _encourageDelayTimer?.cancel();
    _retryHintTimer?.cancel();
    _mesajTimer?.cancel();
    _doneTickTimer?.cancel();
    _smart.dispose();
    _confettiController.dispose();
    _transitionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget currentView = switch (stage) {
      _Stage.loading => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      _Stage.playing => _buildTripletView(),
      _Stage.encourage => _buildEncourageView(),
      _Stage.final_ => _buildFinalView(),
    };

    final Widget body = _isTransitioning
        ? _buildCatWipeTransition(newContent: currentView)
        : currentView;

    // "Tekrar dene" ipucu her şeyin üstünde.
    return Stack(children: [body, _retryHintOverlay()]);
  }

  // ------------------------------------------------------------
  // Geçiş: kedi aşağıdan yukarı süzülür, geçtiği yerde eski ekran
  // (Aferin!) yerini yeni ekrana bırakır. Fade YOK, sadece wipe.
  // ------------------------------------------------------------
  Widget _buildCatWipeTransition({required Widget newContent}) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, _) {
        final t = _transitionController.value;
        final size = MediaQuery.of(context).size;
        final catY = size.height * (1 - t); // ekranın altından üstüne
        const catSize = 340.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            newContent,
            ClipRect(
              clipper: _TopWipeClipper(catY),
              // Molalardan sonra kutlama ekranı silinerek açılıyor; ara
              // üçlülerde silinecek bir kutlama yok, düz zemin yeterli.
              child: _wipeMoladan
                  ? _buildEncourageView()
                  : const ColoredBox(
                color: AppColors.background,
                child: SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: (catY - catSize / 2).clamp(-catSize, size.height),
              child: Center(
                child: SizedBox(
                  width: catSize,
                  height: catSize,
                  child: Lottie.asset(
                    'assets/lottie/balon.lottie',
                    controller: _transitionController,
                    repeat: false,
                    onLoaded: (composition) {
                      if (_transitionDuration != null) return;
                      _transitionDuration = composition.duration;
                      _transitionController.duration = composition.duration;
                      if (_isTransitioning &&
                          !_transitionController.isAnimating) {
                        _transitionController.forward();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Ekran: 3 (ya da 2) resim, dokunarak oku+kaydet
  // ------------------------------------------------------------
  Widget _buildTripletView() {
    final tw = currentTripletWords;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelimeler'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  // Bölüm yok: sayaç toplam 24 kelime üzerinden ilerliyor.
                  '${tripletOffsets[tripletIndex] + 1}–'
                      '${tripletOffsets[tripletIndex] + tw.length}'
                      ' / ${words.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _modelBekliyor
                      ? 'Dinliyorum...'
                      : 'Bir resme dokun ve kelimeyi oku!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _geriBildirimBandi(),
                const SizedBox(height: 20),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: tw.length >= 3
                          ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [_imageCard(0), _imageCard(1)],
                          ),
                          const SizedBox(height: 24),
                          _imageCard(2),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          tw.length,
                              (i) => _imageCard(i),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                _cornerAnimalAsset,
                width: 220,
                height: 220,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Sabit boyutlu kare resim kartı (dokun -> oku + kaydet)
  // ------------------------------------------------------------
  Widget _imageCard(int localIndex) {
    final tw = currentTripletWords;
    final globalIndex = tripletOffsets[tripletIndex] + localIndex;
    final isDone = completedTap[localIndex];
    final isThisRecording = isRecording && recordingGlobalIndex == globalIndex;
    final isBekleyen = _modelBekliyor && recordingGlobalIndex == globalIndex;

    // Denenen kelime öne çıkar, diğer ikisi geri çekilir — üçlü düzen
    // korunuyor ama çocuğun odağı tek kelimede kalıyor.
    final aktif = isThisRecording || isBekleyen;
    final baskasiCalisiyor =
        (isRecording || _modelBekliyor) &&
        recordingGlobalIndex != globalIndex;
    final deneme = denemeSayaci[globalIndex];

    return GestureDetector(
      onTap: () => _onImageTap(localIndex),
      child: AnimatedScale(
        scale: aktif ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: baskasiCalisiyor ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _imageCardBody(
                localIndex: localIndex,
                tw: tw,
                isDone: isDone,
                isThisRecording: isThisRecording,
                isBekleyen: isBekleyen,
              ),
              const SizedBox(height: 6),
              _denemeNoktalari(
                deneme,
                dogruBitti: apiResults[globalIndex] != null &&
                    apiResults[globalIndex]!['is_pathological'] != true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Geri bildirim bandı. Yer her zaman ayrılıyor (mesaj yokken şeffaf) —
  /// yoksa mesaj gelip gidince resimler zıplıyor.
  Widget _geriBildirimBandi() {
    final mesaj = _mesaj;
    final dogru = _mesajDogru;

    final Color renk = dogru == null
        ? const Color(0xFFC2185B)
        : (dogru ? Colors.green.shade700 : const Color(0xFFB84A22));

    return SizedBox(
      height: 54,
      child: AnimatedOpacity(
        opacity: mesaj == null ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: mesaj == null
            ? const SizedBox.shrink()
            : Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: renk, width: 2),
          ),
          child: Text(
            mesaj,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: renk,
            ),
          ),
        ),
      ),
    );
  }

  /// Kalan deneme hakkı — çocuk sayı okuyamıyor, üç nokta okuyor.
  /// Doğru bilindiyse son harcanan nokta yeşil, değilse hepsi kırmızı.
  Widget _denemeNoktalari(int deneme, {required bool dogruBitti}) {
    final basarili = dogruBitti && deneme > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kMaxDeneme, (i) {
        final harcandi = i < deneme;
        final sonVeBasarili = basarili && i == deneme - 1;
        return Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: !harcandi
                ? AppColors.surfaceLight
                : (sonVeBasarili ? Colors.green : const Color(0xFFE8623A)),
          ),
        );
      }),
    );
  }

  Widget _imageCardBody({
    required int localIndex,
    required List<Map<String, String>> tw,
    required bool isDone,
    required bool isThisRecording,
    required bool isBekleyen,
  }) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                tw[localIndex]['image']!,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.image, size: 60),
              ),
            ),
            if (isThisRecording)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: showDoneTick ? Colors.green : Colors.red,
                    width: 4,
                  ),
                ),
              ),
            if (isDone && !isThisRecording)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 3),
                ),
              ),
            if (isDone)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            if (isThisRecording)
              Positioned.fill(
                child: Center(
                  child: showDoneTick
                      ? _doneTick(50)
                      : SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: recordProgress,
                      strokeWidth: 5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                      backgroundColor: Colors.white70,
                    ),
                  ),
                ),
              ),
            // Model cevabı beklenirken kart boş kalmasın — çocuk bir şeyin
            // olduğunu görmezse tekrar tekrar dokunmaya çalışıyor.
            if (isBekleyen)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: Lottie.asset(
                        'assets/lottie/cat_loader.lottie',
                        repeat: true,
                        errorBuilder: (c, e, s) =>
                            const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Ekran: mola kutlaması — 9. ve 18. kelimede. Çocuk bir hayvan
  // arkadaş kazanır, kalan yolu 9 · 9 · 6 çubuklarında görür.
  // Buton yok: 2,6 sn sonra kendiliğinden devam eder.
  // ------------------------------------------------------------
  Widget _buildEncourageView() {
    final biten = _molaBiten;
    final kalan = words.length - biten;
    final odul = _molaOdulu;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.2,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (odul != null) ...[
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 6),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        odul,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.pets,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Yeni arkadaş: ${CornerAnimals.adlar[odul] ?? 'Sürpriz'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const Text(
                    'Harikasın!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$biten kelime bitti, $kalan kelime kaldı',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _etapCubuklari(biten),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Etaplar (9 · 9 · 6) ayrı çubuklar olarak: çocuk kalan yolu görüyor.
  Widget _etapCubuklari(int biten) {
    int oncekiler = 0;
    final cubuklar = <Widget>[];

    for (int i = 0; i < AppWords.etaplar.length; i++) {
      final uzunluk = AppWords.etaplar[i];
      final dolu = ((biten - oncekiler) / uzunluk).clamp(0.0, 1.0);
      oncekiler += uzunluk;

      if (i > 0) cubuklar.add(const SizedBox(width: 8));
      cubuklar.add(
        Expanded(
          flex: uzunluk,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: dolu,
              minHeight: 14,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: cubuklar),
        const SizedBox(height: 8),
        Text(
          '$biten / ${words.length}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade300,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Ekran: Final sonuç — bölümdeki tüm kelimeler
  // ------------------------------------------------------------
  Widget _buildFinalView() {
    final stillWaiting = apiResults.any((r) => r == null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sonuç'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: stillWaiting
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/lottie/cat_loader.lottie',
                repeat: true,
                errorBuilder: (c, e, s) =>
                const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sonuçlar hazırlanıyor...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                const Text(
                  'Hepsi bu kadar!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aferin, ${words.length} kelimeyi bitirdin',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final res = apiResults[index];
                final word = words[index]['word'];

                final bool isError = res == null || res['error'] == true;
                final bool isPathological =
                    res != null && res['is_pathological'] == true;
                final double accuracy = isError
                    ? 0
                    : (1 -
                    ((res['pathology_probability'] ?? 1.0)
                    as num)) *
                    100;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isError
                          ? Colors.grey
                          : (isPathological ? Colors.red : Colors.green),
                      child: Icon(
                        isError
                            ? Icons.warning
                            : (isPathological
                            ? Icons.close
                            : Icons.check),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      word?.toUpperCase() ?? "RESİM",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Text(
                      isError
                          ? "Analiz edilemedi"
                          : (isPathological
                          ? "Hatalı Telaffuz"
                          : "Harika Telaffuz!"),
                    ),
                    trailing: isError
                        ? null
                        : Text(
                      "%${accuracy.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPathological
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _timingLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: GradientButton(
              label: 'Menüye Dön',
              width: double.infinity,
              height: 60,
              fontSize: 22,
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Ölçüm satırı — gecikme şikâyetlerini tahmin yerine sayıyla konuşmak için.
  ///
  /// "bekleme": final ekranı açıldıktan sonra sonuçların gelmesi için
  /// geçen süre. Kayıtlar oyun sırasında arka planda gönderildiği için
  /// bu değerin 0'a yakın olması beklenir — büyükse son kelimenin isteği
  /// hâlâ sürüyor demektir.
  ///
  /// "istek": her ses dosyasının gidiş-dönüş süresi (ortalama / en yavaş).
  /// Sunucu tarafı ölçümü ~200 ms; buradaki fark ağ ve dosya yüklemesidir.
  Widget _timingLine() {
    if (_uploadMs.isEmpty && _finalWaitMs == null) {
      return const SizedBox.shrink();
    }

    final avg = _uploadMs.isEmpty
        ? 0
        : (_uploadMs.reduce((a, b) => a + b) / _uploadMs.length).round();
    final worst = _uploadMs.isEmpty
        ? 0
        : _uploadMs.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(
        'bekleme ${_finalWaitMs ?? 0} ms  •  '
            'istek ort ${avg} ms / en yavaş ${worst} ms  •  '
            'n=${_uploadMs.length}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    );
  }
}

// ============================================================
// SettingsPage
// ============================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _padController;
  String? _padError;

  @override
  void initState() {
    super.initState();
    _padController = TextEditingController(
      text: AppSettings.clipPadMs.toString(),
    );
  }

  @override
  void dispose() {
    _padController.dispose();
    super.dispose();
  }

  Future<void> _applyPad(String raw) async {
    final v = int.tryParse(raw.trim());
    if (v == null) {
      setState(() => _padError = 'Sayı girin');
      return;
    }
    if (v < 0 || v > 1000) {
      setState(() => _padError = '0–1000 ms aralığında olmalı');
      return;
    }
    await AppSettings.setClipPadMs(v);
    if (!mounted) return;
    setState(() => _padError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dolgu $v ms olarak kaydedildi'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ---------------- Ses ----------------
          _baslik('Ses'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ses açık', style: TextStyle(fontSize: 20)),
              Switch(
                value: AppSettings.soundEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  await AppSettings.setSoundEnabled(val);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Konuşma Hızı', style: TextStyle(fontSize: 20)),
          Slider(
            value: AppSettings.ttsSpeed,
            min: 0.2,
            max: 1.0,
            divisions: 4,
            label: switch (AppSettings.ttsSpeed) {
              <= 0.2 => 'Çok Yavaş',
              <= 0.4 => 'Yavaş',
              <= 0.6 => 'Normal',
              <= 0.8 => 'Hızlı',
              _ => 'Çok Hızlı',
            },
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => AppSettings.ttsSpeed = val),
            onChangeEnd: (val) => AppSettings.setTtsSpeed(val),
          ),

          const SizedBox(height: 28),

          // ---------------- Kayıt işleme ----------------
          _baslik('Kayıt işleme'),
          const Text(
            'Bu ayarlar hem Kelimeler hem Alıştırmalar modülünde geçerlidir '
                '— ikisi de aynı API ucuna gittiği için preprocessing birebir '
                'aynı olmalı.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 18),

          const Text('Klip dolgusu (ms)', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          const Text(
            'Kayıt konuşma bölgesine kırpılır, iki yanına bu kadar '
                'sessizlik eklenir. Düşük değerde "sabun, şapka" gibi '
                'kelimelerin başındaki /s/ ve /ş/ kırpılabilir — bu seslerin '
                'enerjisi ünlülerden çok düşük olduğu için konuşma başlangıcı '
                'geç işaretlenir. Şüphedeyseniz 300 ms deneyin.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _padController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: 'ms',
                    errorText: _padError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _applyPad,
                ),
              ),
              const SizedBox(width: 12),
              GradientButton(
                label: 'Kaydet',
                width: 110,
                height: 48,
                fontSize: 16,
                onPressed: () => _applyPad(_padController.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [0, 150, 250, 300, 500]
                .map(
                  (v) => ActionChip(
                label: Text('$v'),
                backgroundColor: AppSettings.clipPadMs == v
                    ? AppColors.surfaceLight
                    : Colors.white,
                onPressed: () {
                  _padController.text = v.toString();
                  _applyPad(v.toString());
                },
              ),
            )
                .toList(),
          ),

          const SizedBox(height: 24),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: AppSettings.normalizeAudio,
            activeThumbColor: AppColors.primary,
            title: const Text(
              'Ses normalizasyonu',
              style: TextStyle(fontSize: 20),
            ),
            subtitle: const Text(
              'Gönderimden önce dalga formunu tepe değerine göre ölçekler. '
                  'Modelin kendi öznitelik çıkarıcısı zaten klip başına '
                  'normalizasyon yaptığı için etkisi genelde küçüktür; çok '
                  'kısık kaydeden cihazlarda denemeye değer.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onChanged: (val) async {
              await AppSettings.setNormalizeAudio(val);
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(height: 28),

          // ---------------- Eşikler ----------------
          _baslik('Ses algılama eşikleri'),
          const Text(
            'Kayıt sabit süreli değil: konuşma başlayınca kaydeder, bitince '
                'keser. Bu üç değer o kararı verir. Ayarlamadan önce konsolu '
                'açın — her kayıttan sonra "KAYIT ... peak=-XX.XdB" satırı '
                'yazılır, tek işe yarayan sayı odur.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Başlangıç eşiği', style: TextStyle(fontSize: 18)),
              Text(
                '${AppSettings.speechStartDb.toStringAsFixed(0)} dBFS',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const Text(
            'Sık "tekrar dene" alıyorsanız düşürün (peak değeri bu eşiğin '
                'altında kalıyordur). Sessizlikte kendiliğinden başlıyorsa '
                'yükseltin.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: AppSettings.speechStartDb,
            min: -50,
            max: -5,
            divisions: 45,
            activeColor: AppColors.primary,
            label: '${AppSettings.speechStartDb.toStringAsFixed(0)} dB',
            onChanged: (v) => setState(() {
              AppSettings.speechStartDb = v;
              AppSettings.enforceHysteresis();
            }),
            onChangeEnd: (v) async {
              await AppSettings.setSpeechStartDb(v);
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bitiş eşiği', style: TextStyle(fontSize: 18)),
              Text(
                '${AppSettings.speechEndDb.toStringAsFixed(0)} dBFS',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          Text(
            'Başlangıçtan en az 4 dB düşük tutulur (şu an '
                '${(AppSettings.speechStartDb - AppSettings.speechEndDb).toStringAsFixed(0)} dB '
                'fark). Bu boşluk olmazsa kelime ortasındaki kısa sessizlikte '
                'kayıt bölünür.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: AppSettings.speechEndDb,
            min: -60,
            max: -8,
            divisions: 52,
            activeColor: AppColors.primary,
            label: '${AppSettings.speechEndDb.toStringAsFixed(0)} dB',
            onChanged: (v) => setState(() {
              AppSettings.speechEndDb = v;
              AppSettings.enforceHysteresis();
            }),
            onChangeEnd: (v) async {
              await AppSettings.setSpeechEndDb(v);
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kesme sessizliği', style: TextStyle(fontSize: 18)),
              Text(
                '${AppSettings.trailingSilenceMs} ms',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const Text(
            'Konuşma bittikten sonra bu kadar sessizlik görülünce kayıt '
                'durur. Kelimeler yarım kalıyorsa artırın.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: AppSettings.trailingSilenceMs.toDouble(),
            min: 150,
            max: 1200,
            divisions: 21,
            activeColor: AppColors.primary,
            label: '${AppSettings.trailingSilenceMs} ms',
            onChanged: (v) =>
                setState(() => AppSettings.trailingSilenceMs = v.round()),
            onChangeEnd: (v) async {
              await AppSettings.setTrailingSilenceMs(v.round());
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: const Text('Kayıt ayarlarını sıfırla'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await AppSettings.resetRecording();
              if (!mounted) return;
              _padController.text = AppSettings.clipPadMs.toString();
              setState(() => _padError = null);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Varsayılanlara döndü'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _baslik('Sabitler'),
          _bilgiSatiri(
            'Maksimum konuşma',
            '${kMaxSpeechDuration.inMilliseconds} ms',
          ),
          _bilgiSatiri(
            'Konuşma yoksa vazgeç',
            '${kNoSpeechTimeout.inMilliseconds} ms',
          ),
          _bilgiSatiri('Örnekleme', '16 kHz mono WAV'),
          _bilgiSatiri('Sunucu', Config.apiIp),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _baslik(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      s,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
    ),
  );

  Widget _bilgiSatiri(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          v,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// Kedi geçişinde eski ekranı üstten alta doğru gösteren clipper —
// altta kalan kısım zaten yeni ekranı gösteriyor (kedi orada).
// ============================================================
class _TopWipeClipper extends CustomClipper<Rect> {
  final double visibleHeight;
  _TopWipeClipper(this.visibleHeight);

  @override
  Rect getClip(Size size) {
    final h = visibleHeight.clamp(0.0, size.height);
    return Rect.fromLTWH(0, 0, size.width, h);
  }

  @override
  bool shouldReclip(covariant _TopWipeClipper oldClipper) =>
      oldClipper.visibleHeight != visibleHeight;
}