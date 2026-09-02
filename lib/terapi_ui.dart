// ============================================================
// TERAPİ MODÜLÜ — ekranlar
//
// Akış: ses seç -> ses üretim yönergesi (dinlenmeden geçilemez) ->
//       ekranlar sırayla (heceler, kelimeler, kelime grupları, cümleler)
//
// Her kart için aşamaya göre belirlenen sayıda kayıt alınır (bkz.
// [kTerapiDeneme]); çocuk her deneme için
// karta yeniden dokunur. Kayıtlar modele beklenmeden gönderilir, sonuç
// BAŞTA/ORTADA/SONDA bölümü bitince toplu gösterilir.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'main.dart';
import 'terapi.dart';
import 'terapi_data.dart';

// ============================================================
// Ses seçimi — 20 sesin ızgarası
// ============================================================

class TerapiSesSecimPage extends StatefulWidget {
  const TerapiSesSecimPage({super.key});

  @override
  State<TerapiSesSecimPage> createState() => _TerapiSesSecimPageState();
}

class _TerapiSesSecimPageState extends State<TerapiSesSecimPage> {
  Map<String, int> _ilerleme = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final m = await TerapiIlerleme.hepsi();
    if (!mounted) return;
    setState(() => _ilerleme = m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Terapi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl),
            tooltip: 'Çalışılacaklar',
            onPressed: () => Navigator.push(
              context,
              SlideFadeRoute(builder: (_) => const TerapiChecklistPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Çalışmak istediğin sesi seç',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: kTerapiSesleri.length,
              itemBuilder: (context, i) {
                final ses = kTerapiSesleri[i];
                final biten = _ilerleme[ses.harf] ?? 0;
                return _SesKarti(
                  ses: ses,
                  oran: biten / ses.ekranlar.length,
                  onTap: () => Navigator.push(
                    context,
                    SlideFadeRoute(builder: (_) => TerapiYonergePage(ses: ses)),
                  ).then((_) => _yukle()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SesKarti extends StatelessWidget {
  final TerapiSes ses;
  final double oran;
  final VoidCallback onTap;
  const _SesKarti({required this.ses, required this.oran, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bitti = oran >= 1.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                ses.harf,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (bitti)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
            if (oran > 0 && !bitti)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: oran,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Ses üretim yönergesi
//
// Taslak: "Sistem, bu komut dinlenmeden bir sonraki aşamaya geçişe izin
// vermemelidir." Başla butonu TTS konuşmayı bitirene kadar pasif kalır.
// ============================================================

class TerapiYonergePage extends StatefulWidget {
  final TerapiSes ses;
  const TerapiYonergePage({super.key, required this.ses});

  @override
  State<TerapiYonergePage> createState() => _TerapiYonergePageState();
}

class _TerapiYonergePageState extends State<TerapiYonergePage> {
  final FlutterTts _tts = FlutterTts();
  bool _dinlendi = false;
  bool _okunuyor = false;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  Future<void> _basla() async {
    await AppSettings.load();
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(
      AppSettings.soundEnabled ? AppSettings.ttsSpeed : 0.0,
    );
    await _tts.setVolume(AppSettings.soundEnabled ? 1.0 : 0.0);
    await _tts.awaitSpeakCompletion(true);
    await _oku();
  }

  Future<void> _oku() async {
    if (_okunuyor) return;
    setState(() => _okunuyor = true);
    await _tts.speak(widget.ses.yonerge);
    if (!mounted) return;
    setState(() {
      _okunuyor = false;
      _dinlendi = true;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('${widget.ses.harf} sesi'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    widget.ses.yonergeGorsel,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _okunuyor ? Icons.volume_up : Icons.record_voice_over,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.ses.yonerge,
                        style: const TextStyle(fontSize: 17, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _okunuyor ? null : _oku,
                      icon: const Icon(Icons.replay),
                      label: const Text('Tekrar dinle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: _dinlendi ? 'Başla' : 'Dinle...',
                      width: double.infinity,
                      height: 54,
                      fontSize: 20,
                      onPressed: _dinlendi
                          ? () => Navigator.pushReplacement(
                              context,
                              SlideFadeRoute(
                                builder: (_) => TerapiOyunPage(ses: widget.ses),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Oyun ekranı
// ============================================================

/// Bir kelimenin bölüm sonu değerlendirmesi. Üç denemenin sonuçları burada
/// birikir; biri bile doğruysa kelime doğru sayılır.
class _KelimeSonuc {
  final String metin;
  final String? gorsel;
  final List<Map<String, dynamic>> sonuclar = [];

  _KelimeSonuc(this.metin, this.gorsel);

  bool get analizEdilemedi =>
      sonuclar.isEmpty || sonuclar.every((r) => r['error'] == true);

  bool get dogru =>
      sonuclar.any((r) => r['error'] != true && r['is_pathological'] != true);
}

enum _Faz { oynuyor, sonuc, bitti }

class TerapiOyunPage extends StatefulWidget {
  final TerapiSes ses;
  const TerapiOyunPage({super.key, required this.ses});

  @override
  State<TerapiOyunPage> createState() => _TerapiOyunPageState();
}

class _TerapiOyunPageState extends State<TerapiOyunPage> {
  int _ekranIndeksi = 0;
  _Faz _faz = _Faz.oynuyor;
  bool _yukleniyor = true;

  /// Ekrandaki her kart için tamamlanan kayıt sayısı.
  List<int> _deneme = [];

  int? _kayitYapilan;
  double _kayitIlerleme = 0;
  String? _mesaj;
  Timer? _mesajTimer;

  /// Dokunma kilidi. `_kayitYapilan` yetmiyor: TTS kelimeyi okurken henüz
  /// kayıt başlamadığı için ikinci dokunuş ikinci bir kayıt açıyordu ve
  /// aynı AudioRecorder üzerinde çakışıyordu.
  bool _busy = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  late final SmartRecorder _smart = SmartRecorder(_audioRecorder);
  final FlutterTts _tts = FlutterTts();

  /// Modele gönderilip cevabı beklenen istekler. Akış beklemez; bölüm
  /// sonunda toplanır.
  final List<Future<void>> _pending = [];

  /// Aktif BAŞTA/ORTADA/SONDA bölümünde biriken kelimeler.
  final List<_KelimeSonuc> _bolum = [];
  bool _sonucBekleniyor = false;

  List<TerapiEkran> get _ekranlar => widget.ses.ekranlar;
  TerapiEkran get _ekran => _ekranlar[_ekranIndeksi];

  /// Bu ekranın kartları kaç kez kaydedilecek. Hecede 1, diğerlerinde 3.
  int get _hedefDeneme => kTerapiDeneme[_ekran.asama]!;

  @override
  void initState() {
    super.initState();
    _hazirla();
  }

  Future<void> _hazirla() async {
    await AppSettings.load();
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(
      AppSettings.soundEnabled ? AppSettings.ttsSpeed : 0.0,
    );
    await _tts.setVolume(AppSettings.soundEnabled ? 1.0 : 0.0);
    await _tts.awaitSpeakCompletion(true);

    final kayitli = await TerapiIlerleme.oku(widget.ses.harf);
    if (!mounted) return;
    setState(() {
      // Ses bir kez bitirildiyse baştan başlar.
      _ekranIndeksi = kayitli >= _ekranlar.length ? 0 : kayitli;
      _deneme = List.filled(_ekran.ogeler.length, 0);
      _yukleniyor = false;
    });
  }

  @override
  void dispose() {
    _mesajTimer?.cancel();
    _tts.stop();
    _smart.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _mesajGoster(String m) {
    if (!mounted) return;
    setState(() => _mesaj = m);
    _mesajTimer?.cancel();
    _mesajTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _mesaj = null);
    });
  }

  // ------------------------------------------------------------
  // Karta dokunma: ifadeyi seslendir, sonra bir kayıt al.
  // Her deneme ayrı dokunuşla başlar.
  // ------------------------------------------------------------
  Future<void> _onTap(int i) async {
    if (_busy || _faz != _Faz.oynuyor || _yukleniyor) return;
    if (_deneme[i] >= _hedefDeneme) return;

    _busy = true;
    try {
      final oge = _ekran.ogeler[i];
      await _tts.speak(oge.metin);
      if (!mounted) return;
      await _kaydet(i, oge);
    } finally {
      if (mounted) _busy = false;
    }
  }

  Future<void> _kaydet(int i, TerapiOge oge) async {
    final dir = await getTemporaryDirectory();
    final yol =
        '${dir.path}/terapi_${DateTime.now().millisecondsSinceEpoch}.wav';

    setState(() {
      _kayitYapilan = i;
      _kayitIlerleme = 0;
    });

    final rec = await _smart.record(
      path: yol,
      maxSpeech: kTerapiKayitSuresi[_ekran.asama],
      onProgress: (p) {
        if (mounted) setState(() => _kayitIlerleme = p);
      },
    );
    if (!mounted) return;

    setState(() {
      _kayitYapilan = null;
      _kayitIlerleme = 0;
    });

    if (!rec.isOk) {
      // Ses yakalanamadı: deneme hakkı YANMAZ, çocuk aynı karta yeniden dokunur.
      if (rec.outcome == RecordOutcome.noSpeech ||
          rec.outcome == RecordOutcome.tooShort) {
        unawaited(Sfx.play(TerapiSfx.notr, volume: 0.6));
        _mesajGoster(GeriBildirim.duyamadim);
      }
      return;
    }

    setState(() => _deneme[i]++);

    // Yalnız kelimeler aşaması modele gider: model 1-2 sn'lik tek kelime
    // klipleriyle eğitildi, hece/öbek/cümlede sonucu anlamlı değil.
    if (_ekran.asama == TerapiAsama.kelimeler) {
      _modeleGonder(oge, rec.path!);
    }

    if (_deneme[i] >= _hedefDeneme) {
      unawaited(Sfx.play(TerapiSfx.dogru));
      // Bu bir doğruluk iddiası değil: çocuk tekrarları tamamladığı için
      // teşvik ediliyor. Gerçek değerlendirme bölüm sonu ekranında.
      _mesajGoster(GeriBildirim.dogruMesaj());
    } else {
      _mesajGoster(GeriBildirim.tekrarMesaj());
    }

    if (_deneme.every((d) => d >= _hedefDeneme)) {
      await _ekranBitti();
    }
  }

  void _modeleGonder(TerapiOge oge, String yol) {
    _KelimeSonuc? kayit;
    for (final k in _bolum) {
      if (k.metin == oge.metin) {
        kayit = k;
        break;
      }
    }
    if (kayit == null) {
      kayit = _KelimeSonuc(oge.metin, oge.gorsel);
      _bolum.add(kayit);
    }
    final hedef = kayit;

    _pending.add(
      sendPronunciationToApi(yol).then((r) async {
        hedef.sonuclar.add(r);
        if (r['error'] != true) {
          // Sonuç gelir gelmez geçmişe yazılıyor: çocuk akışı yarıda bıraksa
          // da kelime Veli Paneli'ne ve Alıştırmalar'a giriyor.
          await WordHistoryService.recordResult(
            word: oge.metin,
            isPathological: r['is_pathological'] == true,
          );
        }
      }),
    );
  }

  // ------------------------------------------------------------
  // Ekran bitti: bölüm sınırındaysak sonuç ekranı, değilse sonraki ekran.
  // ------------------------------------------------------------
  Future<void> _ekranBitti() async {
    await TerapiIlerleme.yaz(widget.ses.harf, _ekranIndeksi + 1);

    final sonraki = _ekranIndeksi + 1 < _ekranlar.length
        ? _ekranlar[_ekranIndeksi + 1]
        : null;
    final bolumBitti =
        _ekran.asama == TerapiAsama.kelimeler &&
        (sonraki == null ||
            sonraki.asama != TerapiAsama.kelimeler ||
            sonraki.konum != _ekran.konum);

    if (bolumBitti) {
      await _sonucGoster();
    } else {
      _ilerle();
    }
  }

  Future<void> _sonucGoster() async {
    setState(() {
      _faz = _Faz.sonuc;
      _sonucBekleniyor = true;
    });
    unawaited(Sfx.play(TerapiSfx.bitti));

    await Future.wait(_pending);
    _pending.clear();

    // 3 denemede de doğru üretilemeyen kelimeler çalışma listesine girer;
    // doğru üretilenler listeden çıkar.
    for (final k in _bolum) {
      if (k.analizEdilemedi) continue;
      if (k.dogru) {
        await TerapiChecklist.cikar(harf: widget.ses.harf, metin: k.metin);
      } else {
        await TerapiChecklist.ekle(
          harf: widget.ses.harf,
          metin: k.metin,
          gorsel: k.gorsel,
        );
      }
    }

    if (!mounted) return;
    setState(() => _sonucBekleniyor = false);
  }

  void _ilerle() {
    _bolum.clear();
    if (_ekranIndeksi + 1 >= _ekranlar.length) {
      setState(() => _faz = _Faz.bitti);
      return;
    }
    setState(() {
      _ekranIndeksi++;
      _deneme = List.filled(_ekran.ogeler.length, 0);
      _faz = _Faz.oynuyor;
      _mesaj = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('${widget.ses.harf} sesi'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (_faz) {
          _Faz.oynuyor => _oynamaGovdesi(),
          _Faz.sonuc => _sonucGovdesi(),
          _Faz.bitti => _bitisGovdesi(),
        },
      ),
    );
  }

  // ---------------- oynama ----------------

  Widget _oynamaGovdesi() {
    final asamaSira = TerapiAsama.values.indexOf(_ekran.asama) + 1;
    final ayniAsama = _ekranlar
        .where((e) => e.asama == _ekran.asama)
        .toList(growable: false);
    final sira = ayniAsama.indexOf(_ekran) + 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Aşama $asamaSira/4 · ${terapiAsamaAdi(_ekran.asama)}'
                  '${_ekran.konum == null ? '' : ' · ${_ekran.konum}'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('$sira / ${ayniAsama.length}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_ekranIndeksi + 1) / _ekranlar.length,
              minHeight: 7,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, c) {
                final n = _ekran.ogeler.length;
                // En fazla iki sütun: üç kart tek sıraya dizilince kartlar
                // ince-uzun kalıyor, görsel tepede küçücük duruyordu.
                // Tek kalan kart Wrap ile ortalanıyor.
                final sutun = n == 1 ? 1 : 2;
                final satir = (n / sutun).ceil();
                const bosluk = 12.0;
                final w = (c.maxWidth - bosluk * (sutun - 1)) / sutun;
                final h = (c.maxHeight - bosluk * (satir - 1)) / satir;
                // Kartlar kare: görseller kare, dikdörtgen kartta alt yarı
                // boş kalıyordu.
                final kenar = w < h ? w : h;
                return Center(
                  child: Wrap(
                    spacing: bosluk,
                    runSpacing: bosluk,
                    alignment: WrapAlignment.center,
                    children: [
                      for (int i = 0; i < n; i++)
                        SizedBox(width: kenar, height: kenar, child: _kart(i)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _mesajSeridi(),
      ],
    );
  }

  Widget _kart(int i) {
    final oge = _ekran.ogeler[i];
    final d = _deneme[i];
    final tamam = d >= _hedefDeneme;
    final kaydediliyor = _kayitYapilan == i;

    final Color cerceve = kaydediliyor
        ? AppColors.secondary
        : tamam
        ? Colors.green
        : AppColors.surfaceLight;

    return GestureDetector(
      onTap: () => _onTap(i),
      child: AnimatedOpacity(
        opacity: tamam ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cerceve, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
                child: oge.gorsel == null
                    // Hecelerde görsel yok — büyük metin kartı.
                    ? Center(
                        child: FittedBox(
                          child: Text(
                            oge.metin,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : Image.asset(
                        oge.gorsel!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tamam ? Colors.green : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$d/$_hedefDeneme',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (kaydediliyor)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _kayitIlerleme,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              if (tamam)
                const Positioned(
                  left: 8,
                  bottom: 6,
                  child: Icon(Icons.check_circle, color: Colors.green, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mesajSeridi() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _mesaj == null
          ? const SizedBox(height: 74)
          : Container(
              key: ValueKey(_mesaj),
              height: 74,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset('assets/maskot/maskot.png', height: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _mesaj!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------- bölüm sonucu ----------------

  Widget _sonucGovdesi() {
    if (_sonucBekleniyor) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'Kayıtların inceleniyor...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final dogruSayi = _bolum.where((k) => k.dogru).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            '${_ekran.konum} bölümü bitti — $dogruSayi / ${_bolum.length} doğru',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bolum.length,
            itemBuilder: (context, i) {
              final k = _bolum[i];
              final hata = k.analizEdilemedi;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: k.gorsel == null
                      ? null
                      : SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.asset(k.gorsel!, fit: BoxFit.contain),
                        ),
                  title: Text(
                    k.metin,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  // Taslaktaki iki mesaj havuzu burada kullanılıyor: doğruluk
                  // ancak üç denemenin sonucu geldiğinde biliniyor.
                  subtitle: Text(
                    hata
                        ? 'Analiz edilemedi'
                        : (k.dogru
                              ? GeriBildirim.dogruMesaj()
                              : GeriBildirim.hataliMesaj()),
                  ),
                  trailing: Icon(
                    hata
                        ? Icons.help_outline
                        : (k.dogru ? Icons.check_circle : Icons.cancel),
                    color: hata
                        ? Colors.grey
                        : (k.dogru ? Colors.green : Colors.red),
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: 'Devam',
            width: double.infinity,
            height: 58,
            fontSize: 22,
            onPressed: _ilerle,
          ),
        ),
      ],
    );
  }

  // ---------------- ses bitti ----------------

  Widget _bitisGovdesi() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/maskot/maskot.png', height: 140),
            const SizedBox(height: 20),
            Text(
              '${widget.ses.harf} sesini bitirdin!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Harika bir çalışma oldu.',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Çalışılacaklar',
              width: double.infinity,
              height: 54,
              fontSize: 20,
              onPressed: () => Navigator.push(
                context,
                SlideFadeRoute(builder: (_) => const TerapiChecklistPage()),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ses listesine dön'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Çalışılacaklar listesi
//
// Taslak: "3 denemede de yapılamayıp kırmızı yanan görseller Checklist
// listesine eklenebilir."
// ============================================================

class TerapiChecklistPage extends StatefulWidget {
  const TerapiChecklistPage({super.key});

  @override
  State<TerapiChecklistPage> createState() => _TerapiChecklistPageState();
}

class _TerapiChecklistPageState extends State<TerapiChecklistPage> {
  List<Map<String, dynamic>>? _liste;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final l = await TerapiChecklist.oku();
    if (!mounted) return;
    l.sort((a, b) => (b['tarih'] as String).compareTo(a['tarih'] as String));
    setState(() => _liste = l);
  }

  @override
  Widget build(BuildContext context) {
    final liste = _liste;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Çalışılacaklar'),
        centerTitle: true,
      ),
      body: liste == null
          ? const Center(child: CircularProgressIndicator())
          : liste.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Henüz çalışılacak bir ifade yok.\n'
                  'Üç denemede de doğru üretilemeyen kelimeler burada birikir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: liste.length,
              itemBuilder: (context, i) {
                final m = liste[i];
                final gorsel = m['gorsel'] as String?;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: gorsel == null
                        ? const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, color: Colors.white),
                          )
                        : SizedBox(
                            width: 48,
                            height: 48,
                            child: Image.asset(gorsel, fit: BoxFit.contain),
                          ),
                    title: Text(
                      m['metin'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Text('${m['harf']} sesi'),
                  ),
                );
              },
            ),
    );
  }
}
