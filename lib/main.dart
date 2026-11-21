
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const RoyalJackpot());
}

const gold = Color(0xFFFFC83D);
const dark = Color(0xFF090909);
const panel = Color(0xFF191919);

class RoyalJackpot extends StatelessWidget {
  const RoyalJackpot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ROYAL JACKPOT',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: dark,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: gold,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// شاشة البداية
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
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget ball(double size, double offset) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            sin(controller.value * pi * 2 + offset) * 15,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.4, -0.5),
                colors: [
                  Color(0xFFFFFFD0),
                  Color(0xFFFFD700),
                  Color(0xFFB87500),
                  Color(0xFF563000),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.5),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF302000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ROYAL',
              style: TextStyle(
                color: gold,
                fontSize: 43,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const Text(
              'JACKPOT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 65),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ball(75, 0),
                const SizedBox(width: 15),
                ball(105, 2),
                const SizedBox(width: 15),
                ball(75, 4),
              ],
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: gold),
            const SizedBox(height: 20),
            const Text(
              'WELCOME TO ROYAL JACKPOT',
              style: TextStyle(color: gold, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// تسجيل الدخول وإنشاء الحساب
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  bool createAccount = false;

  void enter() {
    if (nameController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainPage(username: nameController.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [dark, Color(0xFF342300)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.diamond, color: gold, size: 75),
                const SizedBox(height: 15),
                const Text(
                  'ROYAL JACKPOT',
                  style: TextStyle(
                    color: gold,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 35),
                Text(
                  createAccount ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: nameController,
                  textDirection: TextDirection.rtl,
                  decoration: inputDecoration('اسم المستخدم', Icons.person),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: inputDecoration('كلمة المرور', Icons.lock),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: enter,
                    child: Text(
                      createAccount ? 'إنشاء الحساب' : 'دخول',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => createAccount = !createAccount);
                  },
                  child: Text(
                    createAccount
                        ? 'لديك حساب؟ تسجيل الدخول'
                        : 'ليس لديك حساب؟ إنشاء حساب',
                    style: const TextStyle(color: gold),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'حساب تجريبي محلي: لا يتم حفظ البيانات على خادم.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: gold),
    filled: true,
    fillColor: panel,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: gold),
    ),
  );
}

// الصفحة الرئيسية
class MainPage extends StatefulWidget {
  final String username;

  const MainPage({super.key, required this.username});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  int points = 1000;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        username: widget.username,
        points: points,
        openSlots: () => setState(() => selectedIndex = 1),
        openAccount: () => setState(() => selectedIndex = 2),
      ),
      SlotsScreen(
        points: points,
        onPointsChanged: (value) => setState(() => points = value),
      ),
      AccountScreen(username: widget.username, points: points),
    ];

    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        backgroundColor: const Color(0xFF171717),
        selectedItemColor: gold,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'الألعاب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// الصفحة الرئيسية
class HomeScreen extends StatelessWidget {
  final String username;
  final int points;
  final VoidCallback openSlots;
  final VoidCallback openAccount;

  const HomeScreen({
    super.key,
    required this.username,
    required this.points,
    required this.openSlots,
    required this.openAccount,
  });

  Widget category(
    String title,
    IconData icon,
    VoidCallback action,
  ) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: gold, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ROYAL JACKPOT',
              style: TextStyle(
                color: gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: openAccount,
              icon: const Icon(Icons.person, color: gold, size: 30),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF755000), Color(0xFF241800)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهلاً بك $username',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 15),
              const Text('رصيدك التجريبي'),
              Text(
                '$points نقطة',
                style: const TextStyle(
                  color: gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'الأقسام الرئيسية',
          style: TextStyle(
            color: gold,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            category('ألعاب السلوتس', Icons.casino, openSlots),
            category('الألعاب المميزة', Icons.stars, openSlots),
            category('حساب المستخدم', Icons.person, openAccount),
            category('رصيد النقاط', Icons.account_balance_wallet, openAccount),
          ],
        ),
        const SizedBox(height: 25),
        const Text(
          'اكتشف ألعابنا',
          style: TextStyle(color: gold, fontSize: 20),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: openSlots,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFF29200C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, color: gold, size: 45),
                  SizedBox(height: 8),
                  Text(
                    'ROYAL SLOTS',
                    style: TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('اضغط للعب بالنقاط التجريبية'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// لعبة السلوتس
class SlotsScreen extends StatefulWidget {
  final int points;
  final ValueChanged<int> onPointsChanged;

  const SlotsScreen({
    super.key,
    required this.points,
    required this.onPointsChanged,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final random = Random();
  List<String> symbols = ['🍒', '🍋', '💎'];
  bool spinning = false;
  String message = 'اضغط على زر اللعب';

  void spin() async {
    if (spinning) return;

    if (widget.points < 10) {
      setState(() => message = 'رصيد النقاط غير كافٍ');
      return;
    }

    setState(() {
      spinning = true;
      message = 'حظاً سعيداً!';
      widget.onPointsChanged(widget.points - 10);
    });

    await Future.delayed(const Duration(milliseconds: 900));

    final result = List.generate(
      3,
      (_) => ['🍒', '🍋', '💎', '7️⃣', '⭐'][random.nextInt(5)],
    );

    int reward = 0;
    if (result[0] == result[1] && result[1] == result[2]) {
      reward = 100;
    } else if (result[0] == result[1] || result[1] == result[2]) {
      reward = 20;
    }

    setState(() {
      symbols = result;
      spinning = false;
      widget.onPointsChanged(widget.points + reward);
      message = reward > 0
          ? 'مبروك! ربحت $reward نقطة'
          : 'حاول مرة أخرى!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'ROYAL SLOTS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: gold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gold),
          ),
          child: Column(
            children: [
              const Text(
                'رصيدك',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '${widget.points} نقطة',
                style: const TextStyle(
                  color: gold,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF664400), Color(0xFF211600)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: symbols.map((symbol) {
              return Container(
                width: 75,
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold),
                ),
                child: Text(
                  symbol,
                  style: const TextStyle(fontSize: 37),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 25),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: gold,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: spinning ? null : spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
            ),
            child: Text(
              spinning ? 'جاري اللعب...' : 'العب الآن - 10 نقاط',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ثلاثة رموز متطابقة = 100 نقطة\nرمزان متطابقان = 20 نقطة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.8),
        ),
        const SizedBox(height: 20),
        const Text(
          'هذه لعبة ترفيهية تجريبية بنقاط افتراضية فقط، ولا تتضمن أموالاً حقيقية أو سحباً أو إيداعاً.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

// حساب المستخدم
class AccountScreen extends StatelessWidget {
  final String username;
  final int points;

  const AccountScreen({
    super.key,
    required this.username,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.account_circle, color: gold, size: 100),
        const SizedBox(height: 15),
        const Text(
          'حساب المستخدم',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: gold,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        accountRow(Icons.person, 'اسم المستخدم', username),
        accountRow(Icons.stars, 'النقاط التجريبية', '$points نقطة'),
        accountRow(Icons.verified_user, 'نوع الحساب', 'حساب تجريبي'),
        const SizedBox(height: 35),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(15),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
        ),
        const SizedBox(height: 25),
        const Text(
          'بيانات الحساب تجريبية ومحلية وليست مرتبطة بخادم أو نظام تسجيل حقيقي.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget accountRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold),
          const SizedBox(width: 15),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(color: gold)),
        ],
      ),
    );
  }
}
