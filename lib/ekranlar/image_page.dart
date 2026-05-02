import 'package:flutter/material.dart';
import 'finish_page.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'yildizliekran.dart';
class ImagePage extends StatefulWidget {
  final String category;
  const ImagePage({super.key, required this.category});

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
  List<String> answers = [];
  List<String> imagePaths = [ ];
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadCategory();
  }
  void _loadCategory() {
    switch (widget.category) {
      case '3-4':
        imagePaths = ['assets/3-4/anahtar.png',
            'assets/3-4/ayakkabı.png',
            'assets/3-4/bardak.png',
            'assets/3-4/bayrak.png',
            'assets/3-4/bebek.png',
            'assets/3-4/dede.png',
            'assets/3-4/dis.png',
            'assets/3-4/dondurma.png',
            'assets/3-4/elma.png',
            'assets/3-4/gaga.png',
            'assets/3-4/güneş.png',
            'assets/3-4/havuç.png',
            'assets/3-4/kedi.png',
            'assets/3-4/kulak.png',
            'assets/3-4/limon.png',
            'assets/3-4/masa.png',
            'assets/3-4/nar.png',
            'assets/3-4/nine.png',
            'assets/3-4/peynir.png',
            'assets/3-4/toka.ğng',
            'assets/3-4/top.png',
            'assets/3-4/yatak.png',
            'assets/3-4/yılan.png'];
        answers = ['anahtar',
            'ayakkabı',
            'bardak',
            'bayrak',
            'bebek',
            'dede',
            'diş',
            'dondurma',
            'elma',
            'gaga',
            'güneş',
            'havuç',
            'kedi',
            'kulak',
            'limon',
            'masa',
            'nar',
            'nine',
            'peynir',
            'toka',
            'top',
            'yatak',
            'yılan',
        ];
        break;
      case '4-5':
        imagePaths = ['assets/4-5/bisiklet.png',
            'assets/4-5/cep.png',
            'assets/4-5/cicek.png',
            'assets/4-5/cocuk.png',
            'assets/4-5/defter.png',
            'assets/4-5/fare.png',
            'assets/4-5/fırca.png',
            'assets/4-5/jilet.png',
            'assets/4-5/kasik.png',
            'assets/4-5/oje.png',
            'assets/4-5/ruj.png',
            'assets/4-5/sabun.png',
            'assets/4-5/salıncak.png',
            'assets/4-5/sapka.png',
            'assets/4-5/tavsan.png',
            'assets/4-5/telefon.png',
            'assets/4-5/uzum.png',
            'assets/4-5/vazo.png',
            'assets/4-5/zil.png'];
        answers = ['bisiklet',
            'cep',
            'çiçek',
            'çocuk',
            'defter',
            'fare',
            'fırça',
            'jilet',
            'kaşık',
            'oje',
            'ruj',
            'sabun',
            'salıncak',
            'şapka',
            'tavşan',
            'telefon',
            'üzüm',
            'vazo',
            'zil'];
        break;
      case '5-6':
        imagePaths = ['assets/5-6/agac.png',
            'assets/5-6/araba.png',
            'assets/5-6/ari.png',
            'assets/5-6/dügme.png',
            'assets/5-6/park.png',
            'assets/5-6/resim.png',
            'assets/5-6/tarak.png'];
        answers = ['ağaç',
            'araba',
            'arı',
            'düğme',
            'park',
            'resim',
            'tarak'
            ];
        break;
    }
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
      showYildizliEkran(attemptCount +1);
    } else {
      attemptCount++;
      if (attemptCount >= 3) {
        results.add(-1);
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
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}