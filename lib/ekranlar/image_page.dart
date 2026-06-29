import 'package:flutter/material.dart';
import 'finish_page.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'yildizliekran.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fotolarCevaplar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
class ImagePage extends StatefulWidget {
  final String category;
  final int section;
  const ImagePage({super.key, required this.category,required this.section});

  @override
  State<ImagePage> createState() => _ImagePageState();
}
//fotoğraflar ve istenen sonuçlar
class _ImagePageState extends State<ImagePage> with TickerProviderStateMixin {
  int currentIndex = 0;
  bool isListening = false;
  bool showRetry = false;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  int attemptCount = 0;
  List<int> results = [];
  List<String> answers = [];
  List<String> imagePaths = [];
  List<String> wrongAnswers=[];
  List<String> completelyWrong = [];
  Map<String, int> wordResults = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    _loadCategory(); // önce category yükle
    _initSpeech();
    _initTts().then((_) async {
      await _loadProgress(); // progress yükle
      _speakWord(); // sonra konuş
    });
  }
  void _loadCategory() {
    imagePaths = List<String>.from(
        fotograflarCevaplar.imagePaths[widget.category]?[widget.section] ?? []
    );
    answers = List<String>.from(
        fotograflarCevaplar.answers[widget.category]?[widget.section] ?? []
    );
  }
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category', widget.category);
    await prefs.setInt('currentIndex', currentIndex);
    await prefs.setInt('attemptCount', attemptCount);
    await prefs.setStringList('results', results.map((e) => e.toString()).toList());
    await prefs.setStringList('completelyWrong', completelyWrong);
    final wordResultsEncoded = wordResults.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('wordResults', wordResultsEncoded);
    await prefs.setInt('section', widget.section);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategory = prefs.getString('category');
    if (savedCategory != widget.category) return; // farklı kategoriyse yükleme
    final savedSection = prefs.getInt('section');
    if (savedCategory != widget.category || savedSection != widget.section) return;

    setState(() {
      currentIndex = prefs.getInt('currentIndex') ?? 0;
      attemptCount = prefs.getInt('attemptCount') ?? 0;
      results = (prefs.getStringList('results') ?? []).map((e) => int.parse(e)).toList();
      completelyWrong = prefs.getStringList('completelyWrong') ?? [];
      final wordResultsList = prefs.getStringList('wordResults') ?? [];
      wordResults = {
        for (var e in wordResultsList)
          e.split(':')[0]: int.parse(e.split(':')[1])
      };
    });
  }
  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('category');
    await prefs.remove('currentIndex');
    await prefs.remove('attemptCount');
    await prefs.remove('results');
    await prefs.remove('completelyWrong');
    await prefs.remove('wordResults');
  }
  Future<void> _saveSectionResult() async {
    final prefs = await SharedPreferences.getInstance();

    int totalStars = 0;
    for (int r in results) {
      if (r == 1 || r == 2) totalStars += 3;
      else if (r == 3) totalStars += 2;
      else if (r == 4) totalStars += 1;
    }

    int avgStars = results.isEmpty ? 0 : (totalStars / results.length).round();

    await prefs.setInt('${widget.category}_section${widget.section}_stars', avgStars);
    await prefs.setInt('${widget.category}_section${widget.section}_progress', imagePaths.length);
    await prefs.setBool('${widget.category}_section${widget.section}_completed', true);
  }
  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => print('Hata: $error'),
      onStatus: (status) => print('Durum: $status'),
    );
    setState(() {});
  }
  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    final ttsSpeed = prefs.getDouble('ttsSpeed') ?? 0.4;
    final soundEnabled = prefs.getBool('soundEnabled') ?? true;

    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(soundEnabled ? ttsSpeed : 0.0);
    await _tts.setVolume(soundEnabled ? 1.0 : 0.0);
  }
  Future<void> _speakWord() async {
    if (answers.isEmpty) return;
    await _tts.speak(answers[currentIndex]);
  }
//mikrofon ve text to speech
  void toggleListening() async {
    if (!_speechEnabled) return;

    if (isListening) {
      await _speech.stop();
      setState(() => isListening = false);
    } else {
      setState(() => isListening = true);
      _speech.listen(
        localeId: 'tr_TR',
        onResult: (result) {
          if (result.finalResult) {
            String spoken = result.recognizedWords;
            print('Çocuk dedi: $spoken'); // test için
            checkAnswer(spoken);
            setState(() => isListening = false);
          }
        },
      );
    }
  }
  //text to speech fonksiyonuyla kontrol
  void checkAnswer(String spoken) {
    if (spoken.toLowerCase().contains(answers[currentIndex])) {
      _playCorrect();
      setState(() => showRetry = false);
      results.add(attemptCount + 1);
      wordResults[answers[currentIndex]] = attemptCount + 1;
      showYildizliEkran(attemptCount +1);
      _playCorrect();
    } else {
      attemptCount++;
      setState(() => showRetry = true);
      _playWrong();
      if (attemptCount >= 4) {
        results.add(-1);
        wordResults[answers[currentIndex]] = -1;
        wrongAnswers.add(imagePaths[currentIndex]);
        setState(() => showRetry = false);


        showYildizliEkran(-1);
      }
    }
  }
  void showYildizliEkran(int result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StarPage(
          result: result,
          onNext: () {
            Navigator.pop(context); // star page'i kapat
            nextImage(); // sonraki resme geç
          },
        ),
      ),
    );
  }
  //kaç doğru var
  void nextImage() async {
    if (currentIndex < imagePaths.length - 1) {
      setState(() {
        currentIndex++;
        isListening = false;
        attemptCount = 0;
      });
      Future.delayed(const Duration(milliseconds: 500), () => _speakWord());
      _saveProgress();
    } else {
      await _clearProgress();
      await _saveSectionResult();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FinishPage(results: results, category: widget.category),//son sayfaya yollama
        ),
      );
    }
  }
  Future<void> _playCorrect() async {
    await _audioPlayer.play(AssetSource('sesler/dogru.m4a'));
  }

  Future<void> _playWrong() async {
    await _audioPlayer.play(AssetSource('sesler/yanlis.mp3'));
  }
//görüntü ve güzellikler
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text('Resmi Oku'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Resme bak!',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Image.asset(
                  imagePaths[currentIndex],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${currentIndex + 1} / ${imagePaths.length}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isListening ? 'Dinleniyor...' : 'Mikrofona bas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isListening ? Colors.red : Colors.black87,
              ),
            ),
            if (showRetry)
              AnimatedOpacity(
                opacity: showRetry ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: const Text(
                  'Tekrar Dene!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _speakWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(180, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Tekrar Dinle',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: isListening ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isListening
                          ? Colors.red.withValues(alpha: 0.4)
                          : Colors.green.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}