import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_page.dart';
import 'fotolarCevaplar.dart';

class SectionPage extends StatefulWidget {
  final String category;
  const SectionPage({super.key, required this.category});

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  List<int> sectionStars = []; // her bölümün yıldızı
  List<int> sectionProgress = []; // her bölümün kaç resim yapıldığı
  List<bool> sectionCompleted = []; // her bölüm tamamlandı mı

  @override
  void initState() {
    super.initState();
    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    final prefs = await SharedPreferences.getInstance();
    final sectionCount = fotograflarCevaplar.imagePaths[widget.category]!.length;

    List<int> stars = [];
    List<int> progress = [];
    List<bool> completed = [];

    for (int i = 0; i < sectionCount; i++) {
      stars.add(prefs.getInt('${widget.category}_section${i}_stars') ?? 0);
      progress.add(prefs.getInt('${widget.category}_section${i}_progress') ?? 0);
      completed.add(prefs.getBool('${widget.category}_section${i}_completed') ?? false);
    }

    setState(() {
      sectionStars = stars;
      sectionProgress = progress;
      sectionCompleted = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionCount = fotograflarCevaplar.imagePaths[widget.category]!.length;
    if (sectionStars.length != sectionCount) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: Text('${widget.category} Yaş'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(sectionCount, (i) {
            final isLocked = i > 0 && !sectionCompleted[i - 1];
            final totalImages = fotograflarCevaplar.imagePaths[widget.category]![i].length;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: isLocked ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImagePage(
                        category: widget.category,
                        section: i,
                      ),
                    ),
                  ).then((_) => _loadSectionData());
                },
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isLocked ? '🔒 Bölüm ${i + 1}' : 'Bölüm ${i + 1}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${sectionProgress[i].clamp(0, totalImages)} / $totalImages',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (s) => Icon(
                          s < sectionStars[i] ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}