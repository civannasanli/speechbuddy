// ============================================================
// TEK DOSYA: main.dart
// Yeni ak covers: Bölüm seç -> 3'lü resim ekranı (dokunarak oku+kaydet,
// mikrofon yok) -> arka planda modele gönder -> "Aferin" ekranı (Devam Et)
// -> son 3'lüde final sonuç ekranı.
// Retry YOK (sonuç olduğu gibi kabul edilir, alıştırmalar modülü sonra).
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

// Kayıt sırasında bu dBFS değerini hiç geçmezse "çocuk konuşmadı" kabul
// edilir — kayıt modele hiç gönderilmez, tekrar denemesi istenir.
// Not: mikrofon/ortam gürültüsüne göre ayar gerekebilir.
const double kSilenceThresholdDb = -35.0;

// Ses dosyasını modele gönderir — hem BolumPlayPage hem AlistirmalarPage kullanır.
Future<Map<String, dynamic>> sendPronunciationToApi(String filePath) async {
  try {
    final uri = Uri.parse(Config.apiUrl);
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {"error": true, "message": "API Hatası: ${response.statusCode}"};
    }
  } catch (e) {
    return {"error": true, "message": "Bağlantı koptu!"};
  }
}

// ============================================================
// Renk Paleti — canlı turuncu/pembe tema
// ============================================================

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

  static final Random _random = Random();

  static String pickRandom() => assets[_random.nextInt(assets.length)];
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
// 50 kelime, 6 bölüme bölünmüş (5x9 + 1x5).
// Eski dosya yollarıyla (yaş klasörleri) birebir aynı, sadece gruplama değişti.
// ============================================================

class AppWords {
  // Tüm 50 kelime, orijinal sıradaki hali (3-4 -> 4-5 -> 5-6 yaş verisi birleştirildi)
  static const List<Map<String, String>> _hepsi = [
    {'image': 'assets/3-4/kedi.png', 'word': 'kedi'},
    {'image': 'assets/3-4/top.png', 'word': 'top'},
    {'image': 'assets/3-4/anahtar.png', 'word': 'anahtar'},
    {'image': 'assets/3-4/güneş.png', 'word': 'güneş'},
    {'image': 'assets/3-4/limon.png', 'word': 'limon'},
    {'image': 'assets/3-4/bardak.png', 'word': 'bardak'},
    {'image': 'assets/3-4/nine.png', 'word': 'nine'},
    {'image': 'assets/3-4/elma.png', 'word': 'elma'},
    {'image': 'assets/3-4/yılan.png', 'word': 'yılan'},
    {'image': 'assets/3-4/havuç.png', 'word': 'havuç'},
    {'image': 'assets/3-4/dede.png', 'word': 'dede'},
    {'image': 'assets/3-4/toka.png', 'word': 'toka'},
    {'image': 'assets/3-4/masa.png', 'word': 'masa'},
    {'image': 'assets/3-4/balık.png', 'word': 'balık'},
    {'image': 'assets/3-4/peynir.png', 'word': 'peynir'},
    {'image': 'assets/3-4/gaga.png', 'word': 'gaga'},
    {'image': 'assets/3-4/kulak.png', 'word': 'kulak'},
    {'image': 'assets/3-4/bebek.png', 'word': 'bebek'},
    {'image': 'assets/3-4/nar.png', 'word': 'nar'},
    {'image': 'assets/3-4/ayakkabı.png', 'word': 'ayakkabı'},
    {'image': 'assets/3-4/dis.png', 'word': 'diş'},
    {'image': 'assets/3-4/dondurma.png', 'word': 'dondurma'},
    {'image': 'assets/3-4/yatak.png', 'word': 'yatak'},
    {'image': 'assets/3-4/bayrak.png', 'word': 'bayrak'},
    {'image': 'assets/4-5/ruj.png', 'word': 'ruj'},
    {'image': 'assets/4-5/bisiklet.png', 'word': 'bisiklet'},
    {'image': 'assets/4-5/tavsan.png', 'word': 'tavşan'},
    {'image': 'assets/4-5/oje.png', 'word': 'oje'},
    {'image': 'assets/4-5/defter.png', 'word': 'defter'},
    {'image': 'assets/4-5/zil.png', 'word': 'zil'},
    {'image': 'assets/4-5/cep.png', 'word': 'cep'},
    {'image': 'assets/4-5/sabun.png', 'word': 'sabun'},
    {'image': 'assets/4-5/kasik.png', 'word': 'kaşık'},
    {'image': 'assets/4-5/vazo.png', 'word': 'vazo'},
    {'image': 'assets/4-5/cicek.png', 'word': 'çiçek'},
    {'image': 'assets/4-5/jilet.png', 'word': 'jilet'},
    {'image': 'assets/4-5/cocuk.png', 'word': 'çocuk'},
    {'image': 'assets/4-5/salıncak.png', 'word': 'salıncak'},
    {'image': 'assets/4-5/fare.png', 'word': 'fare'},
    {'image': 'assets/4-5/uzum.png', 'word': 'üzüm'},
    {'image': 'assets/4-5/sapka.png', 'word': 'şapka'},
    {'image': 'assets/4-5/fırca.png', 'word': 'fırça'},
    {'image': 'assets/4-5/telefon.png', 'word': 'telefon'},
    {'image': 'assets/5-6/park.png', 'word': 'park'},
    {'image': 'assets/5-6/tarak.png', 'word': 'tarak'},
    {'image': 'assets/5-6/agac.png', 'word': 'ağaç'},
    {'image': 'assets/5-6/resim.png', 'word': 'resim'},
    {'image': 'assets/5-6/ari.png', 'word': 'arı'},
    {'image': 'assets/5-6/dügme.png', 'word': 'düğme'},
    {'image': 'assets/5-6/araba.png', 'word': 'araba'},
  ];

  // 5 bölüm 9'ar kelime + son bölüm 5 kelime = 50
  static final List<List<Map<String, String>>> bolumler = () {
    final List<List<Map<String, String>>> result = [];
    int i = 0;
    for (int b = 0; b < 5; b++) {
      result.add(_hepsi.sublist(i, i + 9));
      i += 9;
    }
    result.add(_hepsi.sublist(i, i + 5)); // son bölüm: 5 kelime (3+2 ekran)
    return result;
  }();

  // Alıştırmalar modülü — kelimeden görsel yolu bulur.
  static String? imageForWord(String word) {
    for (final w in _hepsi) {
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_MenuCardData>[
      _MenuCardData(
        title: 'Bölümler',
        subtitle: 'Kelimeleri sırayla öğren',
        lottieAsset: 'assets/lottie/cute_cat_works.lottie',
        colors: const [AppColors.primary, AppColors.secondary],
        onTap: () => Navigator.push(
          context,
          SlideFadeRoute(builder: (context) => const BolumSecPage()),
        ),
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
// BolumSecPage — bölüm listesi (yaş seçimi YOK, direkt bölümler)
// ============================================================

class BolumSecPage extends StatefulWidget {
  const BolumSecPage({super.key});

  @override
  State<BolumSecPage> createState() => _BolumSecPageState();
}

class _BolumSecPageState extends State<BolumSecPage> {
  List<int> bolumStars = [];
  List<bool> bolumCompleted = [];
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final count = AppWords.bolumler.length;

    List<int> stars = [];
    List<bool> completed = [];
    for (int i = 0; i < count; i++) {
      stars.add(prefs.getInt('bolum${i}_stars') ?? 0);
      completed.add(prefs.getBool('bolum${i}_completed') ?? false);
    }
    final currentStreak = await StreakService.touchAndGetStreak();

    setState(() {
      bolumStars = stars;
      bolumCompleted = completed;
      streak = currentStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = AppWords.bolumler.length;
    if (bolumStars.length != count) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bölümler'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.white),
            tooltip: 'Rozetlerim',
            onPressed: () {
              Navigator.push(
                context,
                SlideFadeRoute(
                  builder: (context) => RozetlerPage(
                    bolumStars: bolumStars,
                    bolumCompleted: bolumCompleted,
                    streak: streak,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (streak > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      streak == 1
                          ? 'Bugün pratik yaptın, harika başlangıç!'
                          : '$streak gün üst üste pratik yapıyorsun!',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Lottie.asset(
                      'assets/lottie/cat_rocket.lottie',
                      repeat: true,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: count,
              itemBuilder: (context, i) {
                final isLocked = i > 0 && !bolumCompleted[i - 1];
                final wordCount = AppWords.bolumler[i].length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isLocked
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                SlideFadeRoute(
                                  builder: (context) =>
                                      BolumPlayPage(bolumIndex: i),
                                ),
                              ).then((_) => _loadData());
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? Colors.grey.shade300
                                    : AppColors.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLocked ? Icons.lock : Icons.play_arrow,
                                color: isLocked
                                    ? Colors.grey
                                    : AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bölüm ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$wordCount kelime',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                3,
                                (s) => PopStar(
                                  filled: s < bolumStars[i],
                                  delay: Duration(
                                    milliseconds: 100 * s + 60 * i,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double _maxAmplitude = -160.0;

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
    final prefs = await SharedPreferences.getInstance();
    final ttsSpeed = prefs.getDouble('ttsSpeed') ?? 0.4;
    final soundEnabled = prefs.getBool('soundEnabled') ?? true;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(soundEnabled ? ttsSpeed : 0.0);
    await _tts.setVolume(soundEnabled ? 1.0 : 0.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _onTap() async {
    if (isRecording || finished || queue == null) return;
    final word = queue![index]['word']!;
    await _tts.speak(word);
    if (!mounted) return;
    await _startRecording(word);
  }

  Future<void> _startRecording(String word) async {
    if (!await _audioRecorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/alistir_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000),
      path: filePath,
    );

    if (!mounted) return;
    setState(() {
      isRecording = true;
      recordProgress = 0.0;
    });

    _maxAmplitude = -160.0;
    _ampSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          if (amp.current > _maxAmplitude) _maxAmplitude = amp.current;
        });

    int ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) async {
      ticks++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => recordProgress = ticks / 100.0);

      if (ticks >= 100) {
        timer.cancel();
        final path = await _audioRecorder.stop();
        await _ampSub?.cancel();
        if (!mounted) return;
        setState(() => isRecording = false);

        final spoke = _maxAmplitude > kSilenceThresholdDb;

        if (!spoke) {
          // Çocuk konuşmadı — kayıt modele hiç gönderilmiyor, tekrar denesin.
          await _tts.speak('Seni duyamadım, tekrar dener misin?');
          return;
        }

        if (path != null) {
          final result = await sendPronunciationToApi(path);
          if (!mounted) return;
          final isError = result['error'] == true;
          final isPathological = !isError && result['is_pathological'] == true;
          await WordHistoryService.recordResult(
            word: word,
            isPathological: isPathological,
          );
          results.add({
            'word': word,
            'correct': !isError && !isPathological,
            'error': isError,
          });
        }

        _advance();
      }
    });
  }

  void _advance() {
    if (!mounted || queue == null) return;
    if (index < queue!.length - 1) {
      setState(() => index++);
    } else {
      setState(() => finished = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
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
            const Text(
              'Resme dokun ve kelimeyi tekrar oku!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
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
                          child: Image.asset(w['image']!, fit: BoxFit.cover),
                        ),
                        if (isRecording)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red, width: 4),
                            ),
                          ),
                        if (isRecording)
                          Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
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

  Widget _buildSummary() {
    final correctCount = results.where((r) => r['correct'] == true).length;
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
              '$correctCount / ${results.length} doğru!',
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
                final isError = r['error'] == true;
                final correct = r['correct'] == true;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isError
                          ? Colors.grey
                          : (correct ? Colors.green : Colors.red),
                      child: Icon(
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
                      isError
                          ? 'Analiz edilemedi'
                          : (correct ? 'Bu sefer doğru!' : 'Hâlâ zorlanıyor'),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
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
}

// ============================================================
// RozetlerPage — kazanılan/kilitli rozetler. Tamamlanma/yıldız/
// seri rozetleri BolumSecPage'den gelen veriyle anında hesaplanır,
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
  final List<int> bolumStars;
  final List<bool> bolumCompleted;
  final int streak;

  const RozetlerPage({
    super.key,
    required this.bolumStars,
    required this.bolumCompleted,
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
    final ilkAdim = widget.bolumCompleted.any((c) => c);
    final yildizUstasi = widget.bolumStars.any((s) => s >= 3);
    final tumBolumler =
        widget.bolumCompleted.isNotEmpty &&
        widget.bolumCompleted.every((c) => c);
    final seri3 = widget.streak >= 3;
    final seri7 = widget.streak >= 7;
    final koleksiyonTam =
        collectedAnimalCount != null &&
        collectedAnimalCount! >= CornerAnimals.assets.length;

    final rozetler = <_RozetTanimi>[
      _RozetTanimi(
        baslik: 'İlk Adım',
        aciklama: 'Bir bölümü tamamla',
        icon: Icons.flag,
        kazanildi: ilkAdim,
      ),
      _RozetTanimi(
        baslik: 'Yıldız Ustası',
        aciklama: 'Bir bölümde 3 yıldız al',
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
        aciklama: 'Ekranlarda çıkan tüm hayvanları gör',
        icon: Icons.pets,
        kazanildi: koleksiyonTam,
      ),
      _RozetTanimi(
        baslik: 'Bölüm Şampiyonu',
        aciklama: 'Tüm bölümleri tamamla',
        icon: Icons.emoji_events,
        kazanildi: tumBolumler,
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
// BolumPlayPage — bir bölümün tamamını yönetir:
// triplet gösterimi -> kayıt -> arka planda modele gönderim
// -> "Aferin" ekranı -> final sonuç ekranı
// ============================================================

enum _Stage { playing, encourage, final_ }

class BolumPlayPage extends StatefulWidget {
  final int bolumIndex;
  const BolumPlayPage({super.key, required this.bolumIndex});

  @override
  State<BolumPlayPage> createState() => _BolumPlayPageState();
}

class _BolumPlayPageState extends State<BolumPlayPage>
    with TickerProviderStateMixin {
  late List<Map<String, String>> words; // bölümdeki tüm kelimeler (9 ya da 5)
  late List<List<Map<String, String>>>
  triplets; // 3'erli (son parça 2 olabilir)
  late List<int>
  tripletOffsets; // her tripletin flat listedeki başlangıç indeksi

  int tripletIndex = 0;
  _Stage stage = _Stage.playing;

  List<bool> completedTap = []; // mevcut triplet için, hangi resim kaydedildi
  List<String?> audioPaths = []; // global index -> ses dosya yolu
  List<Map<String, dynamic>?> apiResults = []; // global index -> model sonucu
  final List<Future<void>> pendingUploads = [];

  bool isRecording = false;
  double recordProgress = 0.0;
  int? recordingGlobalIndex;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double _maxAmplitude = -160.0;

  late AnimationController _transitionController;
  Duration? _transitionDuration;
  bool _isTransitioning = false;
  Timer? _encourageDelayTimer;

  late String _cornerAnimalAsset;

  static const List<String> _encouragements = [
    'Harikasın!',
    'Çok iyi!',
    'Süpersin!',
    'Çok güzel okudun!',
    'Bravo!',
    'Aferin sana!',
  ];
  final Random _random = Random();

  Future<void> _speakEncouragement() async {
    final phrase = _encouragements[_random.nextInt(_encouragements.length)];
    try {
      await _tts.speak(phrase);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    words = AppWords.bolumler[widget.bolumIndex];
    triplets = chunkList(words, 3);

    tripletOffsets = [];
    int running = 0;
    for (final t in triplets) {
      tripletOffsets.add(running);
      running += t.length;
    }

    audioPaths = List.filled(words.length, null);
    apiResults = List.filled(words.length, null);
    completedTap = List.filled(triplets[0].length, false);
    _cornerAnimalAsset = CornerAnimals.pickRandom();
    AnimalCollectionService.recordSeen(_cornerAnimalAsset);

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
  }

  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    final ttsSpeed = prefs.getDouble('ttsSpeed') ?? 0.4;
    final soundEnabled = prefs.getBool('soundEnabled') ?? true;

    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(soundEnabled ? ttsSpeed : 0.0);
    await _tts.setVolume(soundEnabled ? 1.0 : 0.0);
    await _tts.awaitSpeakCompletion(true); // konuşma bitene kadar bekle
  }

  List<Map<String, String>> get currentTripletWords => triplets[tripletIndex];

  // ------------------------------------------------------------
  // Resme dokununca: önce kelimeyi seslendir, sonra kaydı başlat
  // ------------------------------------------------------------
  Future<void> _onImageTap(int localIndex) async {
    if (completedTap[localIndex] || isRecording) return;

    final globalIndex = tripletOffsets[tripletIndex] + localIndex;
    final word = currentTripletWords[localIndex]['word']!;

    await _tts.speak(
      word,
    ); // awaitSpeakCompletion(true) sayesinde bitene kadar bekler
    if (!mounted) return;
    await _startRecording(globalIndex, localIndex);
  }

  Future<void> _startRecording(int globalIndex, int localIndex) async {
    if (!await _audioRecorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000),
      path: filePath,
    );

    if (!mounted) return;
    setState(() {
      isRecording = true;
      recordProgress = 0.0;
      recordingGlobalIndex = globalIndex;
    });

    _maxAmplitude = -160.0;
    _ampSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          if (amp.current > _maxAmplitude) _maxAmplitude = amp.current;
        });

    int ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) async {
      ticks++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => recordProgress = ticks / 100.0);

      if (ticks >= 100) {
        timer.cancel();
        final path = await _audioRecorder.stop();
        await _ampSub?.cancel();
        if (!mounted) return;

        final spoke = _maxAmplitude > kSilenceThresholdDb;

        if (!spoke) {
          // Çocuk konuşmadı — kayıt modele hiç gönderilmiyor, tekrar denesin.
          setState(() {
            isRecording = false;
            recordProgress = 0.0;
            recordingGlobalIndex = null;
          });
          await _tts.speak('Seni duyamadım, tekrar dener misin?');
          return;
        }

        setState(() {
          isRecording = false;
          recordProgress = 0.0;
          recordingGlobalIndex = null;
          completedTap[localIndex] = true;
        });

        if (path != null) {
          audioPaths[globalIndex] = path;
          _uploadInBackground(globalIndex, path);
        }

        await _speakEncouragement();
        if (!mounted) return;

        _checkTripletDone();
      }
    });
  }

  // ------------------------------------------------------------
  // Ses dosyasını arka planda modele gönder (bekletmeden)
  // ------------------------------------------------------------
  void _uploadInBackground(int globalIndex, String path) {
    final future = sendPronunciationToApi(path).then((result) {
      apiResults[globalIndex] = result;
    });
    pendingUploads.add(future);
  }

  void _checkTripletDone() {
    if (completedTap.every((c) => c)) {
      setState(() => stage = _Stage.encourage);
      _confettiController.play();
      _playEncourageSound();
      // "Aferin!" ekranı bir süre görünsün, sonra kedi geçişi başlasın.
      _encourageDelayTimer?.cancel();
      _encourageDelayTimer = Timer(
        const Duration(milliseconds: 1400),
        _startTransition,
      );
    }
  }

  Future<void> _playEncourageSound() async {
    // Var olan bir ses dosyası varsa çalınır; yoksa sessizce geçilir.
    try {
      await _audioPlayer.play(AssetSource('sesler/dogru.m4a'));
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // "Aferin!" ekranından sonra tıklama olmadan otomatik başlar:
  // hedef içerik (sonraki triplet ya da final) hemen state'e yazılır,
  // kedi geçiş animasyonu bu içeriği eskisinin üzerinden "açığa çıkarır".
  // Son triplet ise, bekleyen analizler arka planda beklenir.
  // ------------------------------------------------------------
  void _startTransition() {
    if (!mounted || stage != _Stage.encourage) return;

    if (tripletIndex < triplets.length - 1) {
      setState(() {
        tripletIndex++;
        completedTap = List.filled(currentTripletWords.length, false);
        stage = _Stage.playing;
        _isTransitioning = true;
        _cornerAnimalAsset = CornerAnimals.pickRandom();
      });
      AnimalCollectionService.recordSeen(_cornerAnimalAsset);
    } else {
      setState(() {
        stage = _Stage.final_;
        _isTransitioning = true;
      });
      Future.wait(pendingUploads).then((_) async {
        if (!mounted) return;
        setState(() {});
        await _saveBolumResult();
      });
    }

    _transitionController.reset();
    if (_transitionDuration != null) {
      _transitionController.forward();
    }
    // Süre henüz bilinmiyorsa (ilk oynatma), Lottie'nin onLoaded'ı forward'ı tetikler.
  }

  Future<void> _saveBolumResult() async {
    final prefs = await SharedPreferences.getInstance();

    int totalStars = 0;
    for (int i = 0; i < apiResults.length; i++) {
      final res = apiResults[i];
      if (res == null || res['error'] == true) continue;
      final isPathological = res['is_pathological'] == true;
      if (!isPathological) totalStars += 3;
      await WordHistoryService.recordResult(
        word: words[i]['word']!,
        isPathological: isPathological,
      );
    }
    final avgStars = words.isEmpty ? 0 : (totalStars / words.length).round();

    await prefs.setInt('bolum${widget.bolumIndex}_stars', avgStars);
    await prefs.setBool('bolum${widget.bolumIndex}_completed', true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _encourageDelayTimer?.cancel();
    _ampSub?.cancel();
    _confettiController.dispose();
    _transitionController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget currentView = switch (stage) {
      _Stage.playing => _buildTripletView(),
      _Stage.encourage => _buildEncourageView(),
      _Stage.final_ => _buildFinalView(),
    };

    if (!_isTransitioning) return currentView;
    return _buildCatWipeTransition(newContent: currentView);
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
              child: _buildEncourageView(),
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
        title: Text('Bölüm ${widget.bolumIndex + 1}'),
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
                  '${tripletIndex + 1} / ${triplets.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bir resme dokun ve kelimeyi oku!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),
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

    return GestureDetector(
      onTap: () => _onImageTap(localIndex),
      child: SizedBox(
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
                  border: Border.all(color: Colors.red, width: 4),
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
                  child: SizedBox(
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
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Ekran: "Aferin, harikasın!" + Devam Et butonu
  // ------------------------------------------------------------
  Widget _buildEncourageView() {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Aferin!',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Muhteşemsin!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
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
        title: const Text('Bölüm Sonucu'),
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
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Harika, Tamamladın!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
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
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GradientButton(
                    label: 'Bölümlere Dön',
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
  bool soundEnabled = true;
  double ttsSpeed = 0.4;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      ttsSpeed = prefs.getDouble('ttsSpeed') ?? 0.4;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setDouble('ttsSpeed', ttsSpeed);
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ses', style: TextStyle(fontSize: 24)),
                  Switch(
                    value: soundEnabled,
                    onChanged: (val) {
                      setState(() => soundEnabled = val);
                      _saveSettings();
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Konuşma Hızı', style: TextStyle(fontSize: 24)),
              Slider(
                value: ttsSpeed,
                min: 0.2,
                max: 1.0,
                divisions: 4,
                label: ttsSpeed == 0.2
                    ? 'Çok Yavaş'
                    : ttsSpeed == 0.4
                    ? 'Yavaş'
                    : ttsSpeed == 0.6
                    ? 'Normal'
                    : ttsSpeed == 0.8
                    ? 'Hızlı'
                    : ttsSpeed == 1.0
                    ? 'Çok Hızlı'
                    : 'Normal',
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => ttsSpeed = val);
                },
                onChangeEnd: (val) {
                  _saveSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
