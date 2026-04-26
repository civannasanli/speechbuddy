import 'package:flutter/material.dart';

class FinishPage extends StatelessWidget {
  final List<int> results;
  const FinishPage({super.key,required this.results});

  @override
  Widget build(BuildContext context) {
    // Yıldız hesaplama
    int starsFor(int result) {
      if (result == 1) return 3;
      if (result == 2) return 2;
      if (result == 3) return 1;
      return 0;
    }
    return Scaffold(
      backgroundColor: Colors.lightGreen.shade100,
      body: Center(
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
            ...List.generate(results.length, (i) {
              int stars = starsFor(results[i]);
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
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(220, 70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Ana Sayfaya Dön',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}