import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class FinishPage extends StatefulWidget {
  final List<int> results;final String category;
  const FinishPage({super.key, required this.results,required this.category});

  @override
  State<FinishPage> createState() => _FinishPageState();
}

class _FinishPageState extends State<FinishPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  int starsFor(int result) {
    if (result == 1) return 3;
    if (result == 2) return 3;
    if (result == 3) return 2;
    if (result == 4) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.play(AssetSource('sesler/tamamlandi.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen.shade100,
      body: SingleChildScrollView(
        child: ConstrainedBox(constraints: BoxConstraints(minHeight: 
        MediaQuery.of(context).size.height,),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tebrikler!',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tüm resimler bitti.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(widget.results.length, (i) {
              int stars = starsFor(widget.results[i]);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Resim ${i + 1}: ',
                    style: const TextStyle(fontSize: 22),
                  ),
                  ...List.generate(3, (s) => Icon(
                    s < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  )),
                ],
              );
            }),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(220, 70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Bölümlere Dön',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}