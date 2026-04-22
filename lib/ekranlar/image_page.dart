import 'package:flutter/material.dart';
import 'finish_page.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  int currentIndex = 0;
  bool isListening = false;

  final List<String> imagePaths = [
    'assets/resimler/ayakkabi.png',
    'assets/resimler/bardak.png',
    'assets/resimler/limon.png',
  ];

  void toggleListening() {
    setState(() {
      isListening = !isListening;
    });
  }

  void nextImage() {
    if (currentIndex < imagePaths.length - 1) {
      setState(() {
        currentIndex++;
        isListening = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const FinishPage(),
        ),
      );
    }
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