
import 'package:flutter/material.dart';

void main() {
  runApp(const MeroBetApp());
}

const Color gold = Color(0xFFFFC928);
const Color background = Color(0xFF10131B);
const Color surface = Color(0xFF1B202B);
const Color muted = Color(0xFF9299A8);

class MeroBetApp extends StatelessWidget {
  const MeroBetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MERO BET',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class Match {
  final String sport;
  final String league;
  final String home;
  final String away;
  final String time;
  final List<String> odds;

  const Match({
    required this.sport,
    required this.league,
    required this.home,
    required this.away,
    required this.time,
    required this.odds,
  });
}

const List<Match> matches = [
  Match(
    sport: 'كرة القدم',
    league: 'الدوري الإنجليزي',
    home: 'مانشستر سيتي',
    away: 'ليفربول',
    time: 'اليوم - 20:00',
    odds: ['1.85', '3.40', '2.10'],
  ),
  Match(
    sport: 'كرة القدم',
    league: 'الدوري الإسباني',
    home: 'ريال مدريد',
    away: 'برشلونة',
    time: 'اليوم - 22:00',
    odds: ['2.05', '3.20', '1.90'],
  ),
  Match(
    sport: 'كرة السلة',
    league: 'NBA',
    home: 'Lakers',
    away: 'Warriors',
    time: 'غداً - 03:00',
    odds: ['1.75', '2.05', ''],
  ),
  Match(
    sport: 'التنس',
    league: 'بطولة دولية',
    home: 'Player A',
    away: 'Player B',
    time: 'غداً - 17:00',
    odds: ['1.65', '2.20', ''],
  ),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedPage = 0;
  int selectedSport = 0;
  double demoBalance = 0;
  final List<Map<String, String>> betSlip = [];
  final List<String> requests = [];

  final sports = ['الكل', 'كرة القدم', 'كرة السلة', 'التنس'];

  void addSelection(Match match, String selection, String odd) {
    setState(() {
      betSlip.removeWhere((item) => item['match'] == '${match.home} - ${match.away}');
      betSlip.add({
        'match': '${match.home} - ${match.away}',
        'selection': selection,
        'odd': odd,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة الاختيار إلى قسيمة الرهان التجريبية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      sportsPage(),
      gamesPage(),
      walletPage(),
      profilePage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: surface,
          title: const Text(
            'MERO BET',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => showMessage('الإشعارات'),
              icon: const Icon(Icons.notifications_none),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: pages[selectedPage],
        bottomNavigationBar: NavigationBar(
          backgroundColor: surface,
          indicatorColor: gold.withOpacity(0.18),
          selectedIndex: selectedPage,
          onDestinationSelected: (index) {
            setState(() => selectedPage = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: gold),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_soccer),
              label: 'الرياضة',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports),
              label: 'الألعاب',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'المحفظة',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF343044), Color(0xFF171D2A)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحباً بك في', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 5),
              Text(
                'MERO BET',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: gold,
                ),
              ),
              SizedBox(height: 8),
              Text('منصتك الرياضية والترفيهية'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        sectionTitle('الرياضات'),
        const SizedBox(height: 10),
        sportsSelector(),
        const SizedBox(height: 20),
        sectionTitle('المباريات المتاحة'),
        const SizedBox(height: 10),
        ...matches.take(3).map(matchCard),
        const SizedBox(height: 15),
        sectionTitle('ألعاب المنصة'),
        const SizedBox(height: 10),
        gamesGrid(),
        const SizedBox(height: 20),
        sectionTitle('قسيمة الاختيارات'),
        betSlipWidget(),
      ],
    );
  }

  Widget sportsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        sectionTitle('المباريات والرياضات'),
        const SizedBox(height: 15),
        sportsSelector(),
        const SizedBox(height: 15),
        ...matches
            .where((m) =>
                selectedSport == 0 || m.sport == sports[selectedSport])
            .map(matchCard),
      ],
    );
  }

  Widget sportsSelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = selectedSport == index;
          return ChoiceChip(
            label: Text(sports[index]),
            selected: active,
            selectedColor: gold,
            labelStyle: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (_) => setState(() => selectedSport = index),
          );
        },
      ),
    );
  }

  Widget matchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_soccer, color: gold, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  match.league,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
              Text(match.time,
                  style: const TextStyle(color: gold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.home,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Text('VS',
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  match.away,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: oddButton(match, 'فوز ${match.home}', match.odds[0])),
              const SizedBox(width: 7),
              Expanded(child: oddButton(match, 'تعادل', match.odds[1])),
              if (match.odds[2].isNotEmpty) ...[
                const SizedBox(width: 7),
                Expanded(child: oddButton(match, 'فوز ${match.away}', match.odds[2])),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'بيانات وأسعار تجريبية وليست احتمالات مباشرة.',
            style: TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget oddButton(Match match, String selection, String odd) {
    return InkWell(
      onTap: () => addSelection(match, selection, odd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(selection,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: muted)),
            const SizedBox(height: 5),
            Text(odd,
                style: const TextStyle(
                    color: gold, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget gamesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        sectionTitle('ألعاب MERO BET'),
        const SizedBox(height: 8),
        const Text(
          'ألعاب ترفيهية تجريبية. لا تتضمن إيداعاً أو جوائز مالية.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 15),
        gamesGrid(),
      ],
    );
  }

  Widget gamesGrid() {
    final games = [
      ['عجلة الحظ', Icons.casino],
      ['تحدي الأرقام', Icons.numbers],
      ['اختبار السرعة', Icons.speed],
      ['الذاكرة', Icons.psychology],
      ['تخمين اللون', Icons.palette],
      ['لعبة التركيز', Icons.center_focus_strong],
      ['اختيار الصندوق', Icons.inventory_2],
      ['تحدي الحساب', Icons.calculate],
      ['لعبة الحروف', Icons.abc],
      ['اختبار الحظ', Icons.stars],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => showGame(games[index][0] as String),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(games[index][1] as IconData, color: gold, size: 30),
                const SizedBox(height: 8),
                Text(
                  games[index][0] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showGame(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: Text(name),
        content: const Text(
          'هذه نسخة أولية من اللعبة. يمكن إضافة آلية اللعب الكاملة في مرحلة تطوير الألعاب.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: gold)),
          ),
        ],
      ),
    );
  }

  Widget walletPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        sectionTitle('المحفظة'),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('الرصيد التجريبي',
                  style: TextStyle(color: muted)),
              const SizedBox(height: 10),
              Text(
                '${demoBalance.toStringAsFixed(2)} JOD',
                style: const TextStyle(
                  color: gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        actionTile('طلب إيداع', Icons.add_circle_outline, depositDialog),
        actionTile('طلب سحب', Icons.remove_circle_outline, withdrawDialog),
        const SizedBox(height: 20),
        sectionTitle('طلبات المحفظة'),
        const SizedBox(height: 10),
        if (requests.isEmpty)
          const Text('لا توجد طلبات حتى الآن.',
              style: TextStyle(color: muted)),
        ...requests.map(
          (request) => ListTile(
            leading: const Icon(Icons.receipt_long, color: gold),
            title: Text(request),
            subtitle: const Text('قيد المراجعة - طلب تجريبي'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'هذه واجهة تجريبية فقط. لا يتم تنفيذ التحويلات أو اعتماد الأرصدة فعلياً.',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }

  void depositDialog() {
    requestDialog('طلب إيداع', true);
  }

  void withdrawDialog() {
    requestDialog('طلب سحب', false);
  }

  void requestDialog(String title, bool isDeposit) {
    final amount = TextEditingController();
    final reference = TextEditingController();
    String method = 'Orange Money';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          backgroundColor: surface,
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                  items: ['Orange Money', 'CliQ']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => refresh(() => method = v ?? method),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ بالدينار الأردني',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reference,
                  decoration: InputDecoration(
                    labelText: isDeposit
                        ? 'رقم مرجع التحويل'
                        : 'رقم المحفظة أو الهاتف',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final value = double.tryParse(amount.text);
                if (value == null || value <= 0 || reference.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  requests.add(
                    '$title: ${value.toStringAsFixed(2)} JOD - $method',
                  );
                });
                Navigator.pop(dialogContext);
                showMessage('تم تسجيل الطلب التجريبي');
              },
              child: const Text('إرسال الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget profilePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: surface,
          child: Icon(Icons.person, color: gold, size: 45),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            'حساب المستخدم',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        actionTile('المعلومات الشخصية', Icons.person_outline,
            () => showMessage('تسجيل الحساب يحتاج إلى إعداد الخادم')),
        actionTile('سجل النشاطات', Icons.history,
            () => showMessage('لا توجد نشاطات محفوظة')),
        actionTile('الشروط والأحكام', Icons.description_outlined,
            () => showMessage('سيتم إضافة الشروط والأحكام')),
        actionTile('الدعم الفني', Icons.support_agent,
            () => showMessage('الدعم الفني')),
        actionTile('لوحة الإدارة', Icons.admin_panel_settings,
            () => showMessage('لوحة الإدارة تحتاج إلى تسجيل دخول آمن للمالك')),
      ],
    );
  }

  Widget betSlipWidget() {
    if (betSlip.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(15),
        child: Text('لم تختر أي مباراة بعد.',
            style: TextStyle(color: muted)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ...betSlip.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['match'] ?? ''),
              subtitle: Text(item['selection'] ?? ''),
              trailing: Text(
                item['odd'] ?? '',
                style: const TextStyle(color: gold),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(() => betSlip.clear()),
            child: const Text('مسح القسيمة'),
          ),
          const Text(
            'القسيمة للعرض التجريبي فقط ولا تنفذ رهانات حقيقية.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget actionTile(String title, IconData icon, VoidCallback action) {
    return Card(
      color: surface,
      child: ListTile(
        leading: Icon(icon, color: gold),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left, color: muted),
        onTap: action,
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
