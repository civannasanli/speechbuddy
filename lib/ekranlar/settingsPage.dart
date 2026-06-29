import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              label: ttsSpeed == 0.2 ? 'Çok Yavaş' :
              ttsSpeed == 0.4 ? 'Yavaş' :
              ttsSpeed == 0.6 ? 'Normal' :
              ttsSpeed == 0.8 ? 'Hızlı' :
              ttsSpeed == 1.0 ? 'Çok Hızlı' : 'Normal',
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