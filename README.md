import 'package:flutter/material.dart';

void main() {
  runApp(const RoyalJackpotApp());
}

class RoyalJackpotApp extends StatelessWidget {
  const RoyalJackpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ROYAL JACKPOT',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090909),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFFFD700),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;

  final pages = const [
    HomeContent(),
    Center(child: Text('الرياضة')),
    Center(child: Text('المباريات المباشرة')),
    Center(child: Text('الألعاب الترفيهية')),
    Center(child: Text('حسابي')),
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
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: pages[page],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF171717),
        indicatorColor: const Color(0xFF66521B),
        selectedIndex: page,
        onDestinationSelected: (value) {
          setState(() => page = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'الرياضة',
          ),
          NavigationDestination(
            icon: Icon(Icons.live_tv),
            label: 'مباشر',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino),
            label: 'الألعاب',
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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 25),
        const Icon(
          Icons.emoji_events,
          color: Color(0xFFD4AF37),
          size: 85,
        ),
        const SizedBox(height: 15),
        const Text(
          'مرحباً بك في ROYAL JACKPOT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'منصتك الرياضية والترفيهية',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 35),
        feature(Icons.sports_soccer, 'الرياضة والمباريات'),
        feature(Icons.live_tv, 'المباريات المباشرة'),
        feature(Icons.casino, 'ألعاب ترفيهية بنقاط افتراضية'),
        feature(Icons.person, 'حساب المستخدم'),
      ],
    );
  }

  Widget feature(IconData icon, String title) {
    return Card(
      color: const Color(0xFF1B1B1B),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFD4AF37),
          size: 16,
        ),
      ),
    );
  }
}
