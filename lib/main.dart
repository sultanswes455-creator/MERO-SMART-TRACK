
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const SnakApp());
}

class SnakApp extends StatelessWidget {
  const SnakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SNAK CHEATS',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF80),
        ),
      ),
      home: const SnakHome(),
    );
  }
}

class SnakHome extends StatefulWidget {
  const SnakHome({super.key});

  @override
  State<SnakHome> createState() => _SnakHomeState();
}

class _SnakHomeState extends State<SnakHome> {
  double power = 0.65;
  double angle = 45;
  double spin = 0;
  String result = 'اختر زاوية وقوة الضربة';

  final List<Color> ballColors = [
    Colors.yellow,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.brown,
    Colors.black,
    Colors.white,
  ];

  void calculate() {
    final radians = angle * math.pi / 180;
    final x = math.cos(radians) * power * 100;
    final y = math.sin(radians) * power * 100;

    setState(() {
      result =
          'اتجاه التدريب: ${x.toStringAsFixed(1)} / ${y.toStringAsFixed(1)}\n'
          'القوة: ${(power * 100).round()}%\n'
          'الدوران: ${spin.toStringAsFixed(0)}';
    });
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 18),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00FF80),
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget ball(Color color) {
    return Container(
      width: 29,
      height: 29,
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white, color, color.withOpacity(0.65)],
          stops: const [0.0, 0.35, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 7,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101713),
        title: const Text(
          'SNAK CHEATS',
          style: TextStyle(
            color: Color(0xFF00FF80),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF101713),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF00FF80),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    color: Color(0xFF00FF80),
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '8 BALL POOL TRAINING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أدوات مساعدة للتدريب وحساب الضربات',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),

            sectionTitle('🎱 الكرات'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF101713),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: ballColors.map((c) => ball(c)).toList(),
              ),
            ),

            sectionTitle('🎯 حساب الضربة'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101713),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('زاوية التصويب: ${angle.round()}°'),
                  Slider(
                    value: angle,
                    min: 0,
                    max: 360,
                    onChanged: (v) => setState(() => angle = v),
                  ),
                  const SizedBox(height: 8),
                  Text('قوة الضربة: ${(power * 100).round()}%'),
                  Slider(
                    value: power,
                    onChanged: (v) => setState(() => power = v),
                  ),
                  const SizedBox(height: 8),
                  Text('الدوران: ${spin.round()}'),
                  Slider(
                    value: spin,
                    min: -100,
                    max: 100,
                    onChanged: (v) => setState(() => spin = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('احسب الضربة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF80),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00FF80),
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            sectionTitle('⚙️ الأدوات'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101713),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.show_chart,
                        color: Color(0xFF00FF80)),
                    title: Text('مسارات التصويب'),
                    subtitle: Text('للتدريب على اتجاه الكرة'),
                  ),
                  Divider(color: Colors.white12),
                  ListTile(
                    leading: Icon(Icons.sports,
                        color: Color(0xFF00FF80)),
                    title: Text('حساب الزوايا'),
                    subtitle: Text('تجربة زوايا الضربات'),
                  ),
                  Divider(color: Colors.white12),
                  ListTile(
                    leading: Icon(Icons.layers,
                        color: Color(0xFF00FF80)),
                    title: Text('النافذة العائمة'),
                    subtitle: Text('تحتاج إعداد Android إضافيًا'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'نسخة تدريب أولية — لا تقرأ اللعبة تلقائيًا ولا تحقن كودًا فيها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
