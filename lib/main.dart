
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const RoyalJackpotApp());
}

const gold = Color(0xFFD4AF37);
const black = Color(0xFF080808);

class RoyalJackpotApp extends StatelessWidget {
  const RoyalJackpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ROYAL JACKPOT',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: black,
        colorScheme: const ColorScheme.dark(primary: gold),
      ),
      home: const SplashScreen(),
    );
  }
}

// شاشة البداية والكرات الذهبية المتحركة
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(340, 340),
                  painter: SpherePainter(controller.value),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  'ROYAL JACKPOT',
                  style: TextStyle(
                    color: gold,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'THE GOLDEN EXPERIENCE',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 3,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    color: gold,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'جاري التحميل...',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 65),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpherePainter extends CustomPainter {
  final double phase;
  SpherePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final angles = [
      phase * 2 * pi,
      phase * 2 * pi + 2.1,
      phase * 2 * pi + 4.2,
    ];

    final radii = [55.0, 40.0, 30.0];

    for (int i = 0; i < 3; i++) {
      final a = angles[i];
      final depth = 0.72 + 0.28 * ((sin(a) + 1) / 2);

      final position = Offset(
        center.dx + cos(a) * 95,
        center.dy + sin(a) * 55,
      );

      final radius = radii[i] * depth;

      canvas.drawCircle(
        position.translate(5, radius * 0.7),
        radius,
        Paint()
          ..color = Colors.black
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );

      final paint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [
            Color(0xFFFFF5C2),
            Color(0xFFFFD65A),
            Color(0xFFD49A19),
            Color(0xFF754600),
            Color(0xFF241500),
          ],
        ).createShader(
          Rect.fromCircle(center: position, radius: radius),
        );

      canvas.drawCircle(position, radius, paint);

      canvas.drawCircle(
        position.translate(-radius * 0.3, -radius * 0.4),
        radius * 0.18,
        Paint()..color = Colors.white.withOpacity(0.65),
      );

      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFFFE7A0).withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpherePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

// الشاشة الرئيسية
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selected = 0;

  final pages = const [
    HomeScreen(),
    SlotsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: black,
        centerTitle: true,
        title: const Text(
          'ROYAL JACKPOT',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: pages[selected],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF191919),
        indicatorColor: const Color(0xFF66521B),
        selectedIndex: selected,
        onDestinationSelected: (i) {
          setState(() => selected = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino),
            label: 'السلوتات',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF4B370D), Color(0xFF17120A)],
            ),
            border: Border.all(color: gold),
          ),
          child: const Column(
            children: [
              Icon(Icons.emoji_events, color: gold, size: 75),
              SizedBox(height: 15),
              Text(
                'ROYAL JACKPOT',
                style: TextStyle(
                  color: gold,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'مرحباً بك في عالم الألعاب والترفيه',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'الأقسام الرئيسية',
          style: TextStyle(color: gold, fontSize: 21),
        ),
        const SizedBox(height: 15),
        category(Icons.casino, 'ألعاب السلوتس'),
        category(Icons.stars, 'الألعاب المميزة'),
        category(Icons.person, 'حساب المستخدم'),
        const SizedBox(height: 20),
        const Text(
          'جميع الألعاب تجريبية بالنقاط الافتراضية فقط.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }

  Widget category(IconData icon, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 30),
          const SizedBox(width: 15),
          Text(name, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: gold, size: 16),
        ],
      ),
    );
  }
}

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final random = Random();
  final symbols = ['💎', '🍒', '7️⃣', '⭐', '🍀', '🔔'];

  List<String> reels = ['💎', '🍒', '⭐'];
  int points = 1000;
  bool spinning = false;
  String message = 'حظاً سعيداً!';

  Future<void> spin() async {
    if (spinning) return;

    if (points < 10) {
      setState(() => message = 'لا توجد نقاط كافية!');
      return;
    }

    setState(() {
      spinning = true;
      points -= 10;
      message = 'تدور البكرات...';
    });

    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;

      setState(() {
        reels = List.generate(
          3,
          (_) => symbols[random.nextInt(symbols.length)],
        );
      });
    }

    int reward = 0;

    if (reels[0] == reels[1] && reels[1] == reels[2]) {
      reward = 100;
    } else if (reels[0] == reels[1] ||
        reels[1] == reels[2] ||
        reels[0] == reels[2]) {
      reward = 20;
    }

    setState(() {
      points += reward;
      spinning = false;
      message = reward == 100
          ? '🎉 JACKPOT! ربحت 100 نقطة!'
          : reward == 20
              ? 'مبروك! ربحت 20 نقطة!'
              : 'حاول مرة أخرى!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'ROYAL SLOTS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: gold,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            border: Border.all(color: gold, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text('رصيد النقاط'),
              Text(
                '$points',
                style: const TextStyle(
                  color: gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: reels.map((symbol) {
                  return Container(
                    width: 85,
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: gold, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      symbol,
                      style: const TextStyle(fontSize: 40),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: gold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: spinning ? null : spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    spinning ? 'SPINNING...' : '🎰 SPIN',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ثلاثة رموز متطابقة = 100 نقطة\nرمزان متطابقان = 20 نقطة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 2),
        ),
      ],
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, color: gold, size: 85),
          SizedBox(height: 15),
          Text(
            'حساب المستخدم',
            style: TextStyle(color: gold, fontSize: 24),
          ),
          SizedBox(height: 10),
          Text(
            'مرحباً بك في ROYAL JACKPOT',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          Text(
            'حساب تجريبي',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
