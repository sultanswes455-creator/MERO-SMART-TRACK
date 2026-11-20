
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const RoyalJackpotApp());
}

const gold = Color(0xFFD4AF37);
const black = Color(0xFF090909);

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
      home: const MainPage(),
    );
  }
}

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
        backgroundColor: Colors.black,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.emoji_events, color: gold, size: 90),
          SizedBox(height: 20),
          Text(
            'مرحباً بك في ROYAL JACKPOT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gold,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'عالم الألعاب والترفيه',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 25),
          Text(
            'انتقل إلى قسم السلوتات وابدأ اللعب',
            style: TextStyle(color: Colors.white),
          ),
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

      if (reward == 100) {
        message = '🎉 JACKPOT! ربحت 100 نقطة!';
      } else if (reward == 20) {
        message = 'مبروك! ربحت 20 نقطة!';
      } else {
        message = 'حاول مرة أخرى!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 10),
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
              const Text(
                'رصيد النقاط',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 5),
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
                    height: 105,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: gold, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: Text(
                        symbol,
                        key: ValueKey(symbol),
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: gold,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
          'ثلاثة رموز متطابقة = 100 نقطة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        const Text(
          'رمزان متطابقان = 20 نقطة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        const Text(
          'اللعبة تجريبية بالنقاط الافتراضية فقط.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
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
