// ============================================================
// TEK DOSYA: main.dart
// Yeni ak covers: Bölüm seç -> 3'lü resim ekranı (dokunarak oku+kaydet,
// mikrofon yok) -> arka planda modele gönder -> "Aferin" ekranı (Devam Et)
// -> son 3'lüde final sonuç ekranı.
// Retry YOK (sonuç olduğu gibi kabul edilir, alıştırmalar modülü sonra).
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

// ============================================================
// Sunucu Ayarı
// ============================================================

class Config {
  static const String apiIp = "184.174.34.219:8008";
  static const String apiUrl = "http://$apiIp/predict";
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
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HomePage
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/resimler/parrot.png',
              width: 180,
              height: 180,
              errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 150, color: Colors.green),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BolumSecPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(220, 100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 8,
              ),
              child: const Text(
                'Başla!',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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

    setState(() {
      bolumStars = stars;
      bolumCompleted = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = AppWords.bolumler.length;
    if (bolumStars.length != count) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text('Bölümler'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: count,
        itemBuilder: (context, i) {
          final isLocked = i > 0 && !bolumCompleted[i - 1];
          final wordCount = AppWords.bolumler[i].length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isLocked
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BolumPlayPage(bolumIndex: i)),
                  ).then((_) => _loadData());
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey.shade300 : Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLocked ? Icons.lock : Icons.play_arrow,
                          color: isLocked ? Colors.grey : Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bölüm ${i + 1}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text('$wordCount kelime', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(3, (s) => Icon(
                          s < bolumStars[i] ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 22,
                        )),
                      ),
                    ],
                  ),
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

class _BolumPlayPageState extends State<BolumPlayPage> {
  late List<Map<String, String>> words; // bölümdeki tüm kelimeler (9 ya da 5)
  late List<List<Map<String, String>>> triplets; // 3'erli (son parça 2 olabilir)
  late List<int> tripletOffsets; // her tripletin flat listedeki başlangıç indeksi

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

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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

    await _tts.speak(word); // awaitSpeakCompletion(true) sayesinde bitene kadar bekler
    if (!mounted) return;
    await _startRecording(globalIndex, localIndex);
  }

  Future<void> _startRecording(int globalIndex, int localIndex) async {
    if (!await _audioRecorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
        if (!mounted) return;

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

        _checkTripletDone();
      }
    });
  }

  // ------------------------------------------------------------
  // Ses dosyasını arka planda modele gönder (bekletmeden)
  // ------------------------------------------------------------
  void _uploadInBackground(int globalIndex, String path) {
    final future = _sendToApi(path).then((result) {
      apiResults[globalIndex] = result;
    });
    pendingUploads.add(future);
  }

  Future<Map<String, dynamic>> _sendToApi(String filePath) async {
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

  void _checkTripletDone() {
    if (completedTap.every((c) => c)) {
      setState(() => stage = _Stage.encourage);
      _confettiController.play();
      _playEncourageSound();
    }
  }

  Future<void> _playEncourageSound() async {
    // Var olan bir ses dosyası varsa çalınır; yoksa sessizce geçilir.
    try {
      await _audioPlayer.play(AssetSource('sesler/dogru.m4a'));
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // "Devam Et" — analiz bitmiş olsun olmasın ilerler.
  // Son triplet ise, final ekrana geçmeden önce bekleyen analizleri bekler.
  // ------------------------------------------------------------
  Future<void> _onDevamEt() async {
    if (tripletIndex < triplets.length - 1) {
      setState(() {
        tripletIndex++;
        stage = _Stage.playing;
        completedTap = List.filled(currentTripletWords.length, false);
      });
    } else {
      // Son triplet: sonuç ekranına geçmeden bekleyen yüklemeleri bekle
      setState(() => stage = _Stage.final_); // hemen geçiş yap, altta bekleme göstergesi olacak
      await Future.wait(pendingUploads);
      if (!mounted) return;
      setState(() {}); // sonuçlar geldiyse ekranı yenile
      await _saveBolumResult();
    }
  }

  Future<void> _saveBolumResult() async {
    final prefs = await SharedPreferences.getInstance();

    int totalStars = 0;
    for (final res in apiResults) {
      if (res != null && res['error'] != true && res['is_pathological'] == false) {
        totalStars += 3;
      }
    }
    final avgStars = words.isEmpty ? 0 : (totalStars / words.length).round();

    await prefs.setInt('bolum${widget.bolumIndex}_stars', avgStars);
    await prefs.setBool('bolum${widget.bolumIndex}_completed', true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case _Stage.playing:
        return _buildTripletView();
      case _Stage.encourage:
        return _buildEncourageView();
      case _Stage.final_:
        return _buildFinalView();
    }
  }

  // ------------------------------------------------------------
  // Ekran: 3 (ya da 2) resim, dokunarak oku+kaydet
  // ------------------------------------------------------------
  Widget _buildTripletView() {
    final tw = currentTripletWords;

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: Text('Bölüm ${widget.bolumIndex + 1}'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${tripletIndex + 1} / ${triplets.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bir resme dokun ve kelimeyi oku!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: tw.length >= 3
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _imageCard(0),
                          _imageCard(1),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _imageCard(2),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(tw.length, (i) => _imageCard(i)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
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
        width: 140,
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isThisRecording
                      ? Colors.red
                      : (isDone ? Colors.green : Colors.grey.shade300),
                  width: isThisRecording ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  tw[localIndex]['image']!,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.image, size: 50),
                ),
              ),
            ),
            if (isDone)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
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
      backgroundColor: Colors.lightBlue.shade50,
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
                const Text('Aferin!', style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 12),
                const Text('Muhteşemsin, devam et!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _onDevamEt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(200, 65),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Devam Et', style: TextStyle(fontSize: 24, color: Colors.white)),
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
      backgroundColor: Colors.lightGreen.shade100,
      appBar: AppBar(
        title: const Text('Bölüm Sonucu'),
        backgroundColor: Colors.green,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: stillWaiting
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 20),
            Text('Sonuçlar hazırlanıyor...', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Harika, Tamamladın!',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green),
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
                final bool isPathological = res != null && res['is_pathological'] == true;
                final double accuracy = isError
                    ? 0
                    : (1 - ((res['pathology_probability'] ?? 1.0) as num)) * 100;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isError ? Colors.grey : (isPathological ? Colors.red : Colors.green),
                      child: Icon(
                        isError ? Icons.warning : (isPathological ? Icons.close : Icons.check),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(word?.toUpperCase() ?? "RESİM", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text(isError ? "Analiz edilemedi" : (isPathological ? "Hatalı Telaffuz" : "Harika Telaffuz!")),
                    trailing: isError
                        ? null
                        : Text(
                      "%${accuracy.toStringAsFixed(0)}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: isPathological ? Colors.red : Colors.green),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Bölümlere Dön", style: TextStyle(fontSize: 22, color: Colors.white)),
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
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.green,
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
                    activeThumbColor: Colors.green,
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
                activeColor: Colors.green,
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