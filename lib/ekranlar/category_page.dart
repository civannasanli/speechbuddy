import 'package:flutter/material.dart';
import 'image_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text('Yaş Grubu Seç'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _categoryButton(context, '3-4 Yaş', '3-4'),
            const SizedBox(height: 20),
            _categoryButton(context, '4-5 Yaş', '4-5'),
            const SizedBox(height: 20),
            _categoryButton(context, '5-6 Yaş', '5-6'),
          ],
        ),
      ),
    );
  }

  Widget _categoryButton(BuildContext context, String label, String category) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePage(category: category),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: const Size(220, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}