import 'package:flutter/material.dart';
import 'finish_page.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}
//fotoğraflar ve istenen sonuçlar
class _ImagePageState extends State<ImagePage> {
  int currentIndex = 0;
  bool isListening = false;
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  int attemptCount = 0;
  List<int> results = [];
  final List<String> answers = ['ayakkabı', 'bardak', 'limon'];
  final List<String> imagePaths = [
    'assets/resimler/ayakkabi.png',
    'assets/resimler/bardak.png',
    'assets/resimler/limon.png',
  ];
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => print('Hata: $error'),
      onStatus: (status) => print('Durum: $status'),
    );
    setState(() {});
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
      results.add(attemptCount + 1);
      nextImage();
    } else {
      attemptCount++;
      if (attemptCount >= 3) {
        results.add(-1);
        nextImage();
      }
    }
  }
  //kaç doğru var
  void nextImage() {
    if (currentIndex < imagePaths.length - 1) {
      setState(() {
        currentIndex++;
        isListening = false;
        attemptCount = 0;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FinishPage(results: results,),//son sayfaya yollama
        ),
      );
    }
  }
//görüntü ve güzellikler
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
            const SizedBox(height: 25),
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: nextImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(180, 65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                currentIndex == imagePaths.length - 1 ? 'Bitir' : 'Sonraki Resim',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
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