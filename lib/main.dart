
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MeroPlay());

const gold = Color(0xFFFFC400);
const bg = Color(0xFF101113);
const panel = Color(0xFF222326);

class MeroPlay extends StatelessWidget {
  const MeroPlay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MERO PLAY',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: gold),
      ),
      home: const MainPage(),
    );
  }
}

class WalletRequest {
  WalletRequest(this.type, this.amount);
  final String type;
  final double amount;
  bool processed = false;
  bool accepted = false;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int tab = 0;
  double points = 500;
  final requests = <WalletRequest>[];

  void sendRequest(String type, double amount) {
    setState(() => requests.add(WalletRequest(type, amount)));
  }

  void accept(WalletRequest r) {
    if (r.processed) return;

    setState(() {
      if (r.type == 'إزالة نقاط' && r.amount > points) {
        r.processed = true;
        r.accepted = false;
        return;
      }

      r.processed = true;
      r.accepted = true;

      if (r.type == 'إضافة نقاط') {
        points += r.amount;
      } else {
        points -= r.amount;
      }
    });
  }

  void reject(WalletRequest r) {
    if (r.processed) return;
    setState(() {
      r.processed = true;
      r.accepted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        points: points,
        goWallet: () => setState(() => tab = 3),
        goGames: () => setState(() => tab = 2),
      ),
      const SportsPage(),
      const GamesPage(),
      WalletPage(points: points, requests: requests, onSend: sendRequest),
      AdminPage(requests: requests, onAccept: accept, onReject: reject),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'MERO PLAY',
          style: TextStyle(color: gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: IndexedStack(
        index: tab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        selectedIndex: tab,
        indicatorColor: gold.withOpacity(.2),
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.sports_soccer), label: 'رياضة'),
          NavigationDestination(icon: Icon(Icons.games), label: 'الألعاب'),
          NavigationDestination(icon: Icon(Icons.wallet), label: 'المحفظة'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings), label: 'إدارة'),
        ],
      ),
    );
  }
}

// الرئيسية
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.points,
    required this.goWallet,
    required this.goGames,
  });

  final double points;
  final VoidCallback goWallet, goGames;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF604900), bg],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stars, color: gold, size: 45),
                Text(
                  'MERO PLAY',
                  style: TextStyle(
                    color: gold,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('ألعاب ترفيهية • نقاط افتراضية'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Box(
          child: Column(
            children: [
              const Text('رصيدك التجريبي'),
              Text(
                '${points.toStringAsFixed(2)} نقطة',
                style: const TextStyle(
                  color: gold,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton(
                onPressed: goWallet,
                child: const Text('المحفظة'),
              ),
            ],
          ),
        ),
        const Heading('الألعاب المميزة'),
        GameTile(
          'Sky Run',
          'لعبة طيران',
          Icons.flight,
          () => openGame(context, const SkyGame()),
        ),
        GameTile(
          'Kamikaze Grid',
          'لعبة الخانات والمراحل',
          Icons.grid_4x4,
          () => openGame(context, const GridGame()),
        ),
        GameTile(
          'Mines Puzzle',
          'تحدي شبكة',
          Icons.warning_amber_rounded,
          () => openGame(context, const MinesGame()),
        ),
        GameTile(
          'Lucky Wheel',
          'عجلة عشوائية',
          Icons.casino,
          () => openGame(context, const WheelGame()),
        ),
        GameTile(
          'High / Low',
          'توقع البطاقات',
          Icons.style,
          () => openGame(context, const HighLowGame()),
        ),
        FilledButton(
          onPressed: goGames,
          child: const Text('عرض جميع الألعاب'),
        ),
      ],
    );
  }
}

void openGame(BuildContext c, Widget game) {
  Navigator.push(c, MaterialPageRoute(builder: (_) => game));
}

// الألعاب
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Heading('الألعاب'),
          GameTile(
            'Sky Run',
            'تحدي طيران',
            Icons.flight,
            () => openGame(context, const SkyGame()),
          ),
          GameTile(
            'Kamikaze Grid',
            'مراحل وخانات',
            Icons.grid_4x4,
            () => openGame(context, const GridGame()),
          ),
          GameTile(
            'Mines Puzzle',
            'لوحة 5 × 5',
            Icons.warning_amber_rounded,
            () => openGame(context, const MinesGame()),
          ),
          GameTile(
            'Lucky Wheel',
            'عجلة',
            Icons.casino,
            () => openGame(context, const WheelGame()),
          ),
          GameTile(
            'High / Low',
            'بطاقات',
            Icons.style,
            () => openGame(context, const HighLowGame()),
          ),
        ],
      );
}

// توقع رياضي ترفيهي
class SportsPage extends StatefulWidget {
  const SportsPage({super.key});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> {
  int? choice;
  bool saved = false;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Heading('توقع رياضي ترفيهي'),
          const Box(
            child: Text(
              'مباراة افتراضية\nالفريق A  ×  الفريق B',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
          const Text('اختر توقعًا:'),
          ...['فوز الفريق A', 'تعادل', 'فوز الفريق B']
              .asMap()
              .entries
              .map(
                (e) => RadioListTile<int>(
                  value: e.key,
                  groupValue: choice,
                  onChanged: saved ? null : (v) => setState(() => choice = v),
                  title: Text(e.value),
                ),
              ),
          FilledButton(
            onPressed: choice == null || saved
                ? null
                : () => setState(() => saved = true),
            child: const Text('حفظ التوقع'),
          ),
          if (saved)
            const Box(child: Text('تم حفظ توقعك الترفيهي.')),
        ],
      );
}

// المحفظة التجريبية
class WalletPage extends StatelessWidget {
  const WalletPage({
    super.key,
    required this.points,
    required this.requests,
    required this.onSend,
  });

  final double points;
  final List<WalletRequest> requests;
  final void Function(String, double) onSend;

  Future<void> showRequest(BuildContext context, String type) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: Text(type, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('نقاط تجريبية فقط'),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الكمية',
                suffixText: 'نقاط',
              ),
            ),
            const Text('من 10 إلى 200 نقطة'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);

              if (value == null ||
                  !value.isFinite ||
                  value < 10 ||
                  value > 200 ||
                  (type == 'إزالة نقاط' && value > points)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الكمية غير صالحة')),
                );
                return;
              }

              onSend(type, value);
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Box(
            child: Column(
              children: [
                const Text('رصيد نقاط تجريبي'),
                Text(
                  '${points.toStringAsFixed(2)} نقطة',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('غير قابل للتحويل إلى أموال'),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => showRequest(context, 'إضافة نقاط'),
                  child: const Text('إضافة نقاط'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showRequest(context, 'إزالة نقاط'),
                  child: const Text('إزالة نقاط'),
                ),
              ),
            ],
          ),
          const Heading('طلبات المحفظة'),
          if (requests.isEmpty) const Text('لا توجد طلبات'),
          ...requests.reversed.map(
            (r) => ListTile(
              title: Text('${r.type} • ${r.amount}'),
              subtitle: Text(
                r.processed
                    ? (r.accepted ? 'مقبول' : 'مرفوض')
                    : 'قيد المراجعة',
              ),
              leading: Icon(
                Icons.circle,
                color: r.processed
                    ? (r.accepted ? Colors.green : Colors.red)
                    : gold,
              ),
            ),
          ),
        ],
      );
}

// لوحة إدارة الطلبات
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final List<WalletRequest> requests;
  final void Function(WalletRequest) onAccept, onReject;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Heading('لوحة الإدارة التجريبية'),
          const Text('هذه لوحة محلية تجريبية وليست محمية'),
          if (requests.where((r) => !r.processed).isEmpty)
            const Box(child: Text('لا توجد طلبات معلقة')),
          ...requests.where((r) => !r.processed).map(
            (r) => Box(
              child: Column(
                children: [
                  Text(r.type),
                  Text('${r.amount} نقطة'),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => onAccept(r),
                          child: const Text('قبول'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onReject(r),
                          child: const Text('رفض'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

// لعبة Sky Run
class SkyGame extends StatefulWidget {
  const SkyGame({super.key});

  @override
  State<SkyGame> createState() => _SkyGameState();
}

class _SkyGameState extends State<SkyGame> {
  int score = 0;
  bool running = false;

  @override
  Widget build(BuildContext context) => GameScreen('Sky Run', [
        const Icon(Icons.flight, color: gold, size: 85),
        Text(
          'النقاط: $score',
          style: const TextStyle(color: gold, fontSize: 30),
        ),
        Text(running ? 'الجولة بدأت' : 'ابدأ اللعب'),
        FilledButton(
          onPressed: () => setState(() => running = !running),
          child: Text(running ? 'إيقاف' : 'ابدأ'),
        ),
        if (running)
          FilledButton(
            onPressed: () => setState(() => score += Random().nextInt(10) + 1),
            child: const Text('اجمع نقاط'),
          ),
        TextButton(
          onPressed: () => setState(() {
            score = 0;
            running = false;
          }),
          child: const Text('إعادة'),
        ),
      ]);
}

// لعبة Kamikaze Grid
class GridGame extends StatefulWidget {
  const GridGame({super.key});

  @override
  State<GridGame> createState() => _GridGameState();
}

class _GridGameState extends State<GridGame> {
  final safe = <int>{};
  final opened = <int>{};
  int level = 1, score = 0;
  bool lost = false;

  void resetBoard() {
    final cells = List.generate(25, (i) => i)..shuffle();
    safe
      ..clear()
      ..addAll(cells.take(18));
    opened.clear();
    lost = false;
  }

  @override
  void initState() {
    super.initState();
    resetBoard();
  }

  @override
  Widget build(BuildContext context) => GameScreen('Kamikaze Grid', [
        Text(
          'المستوى $level • النقاط $score',
          style: const TextStyle(color: gold),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 25,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemBuilder: (context, i) => InkWell(
            onTap: lost || opened.contains(i)
                ? null
                : () => setState(() {
                      opened.add(i);
                      if (safe.contains(i)) {
                        score += 5 * level;
                        if (opened.length >= 5) {
                          level++;
                          resetBoard();
                        }
                      } else {
                        lost = true;
                      }
                    }),
            child: Container(
              decoration: BoxDecoration(
                color: opened.contains(i)
                    ? (safe.contains(i) ? Colors.green : Colors.red)
                    : panel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                opened.contains(i)
                    ? (safe.contains(i) ? Icons.star : Icons.close)
                    : Icons.help_outline,
                color: gold,
              ),
            ),
          ),
        ),
        Text(lost ? 'انتهى المستوى' : 'اختر الخانات'),
        FilledButton(
          onPressed: () => setState(() {
            level = 1;
            score = 0;
            resetBoard();
          }),
          child: const Text('إعادة اللعب'),
        ),
      ]);
}

// لعبة Mines Puzzle
class MinesGame extends StatefulWidget {
  const MinesGame({super.key});

  @override
  State<MinesGame> createState() => _MinesGameState();
}

class _MinesGameState extends State<MinesGame> {
  final bombs = <int>{2, 7, 14, 18, 23};
  final opened = <int>{};
  int score = 0;
  bool over = false;

  void newGame() {
    opened.clear();
    score = 0;
    over = false;
  }

  @override
  Widget build(BuildContext context) => GameScreen('Mines Puzzle', [
        Text('النقاط: $score', style: const TextStyle(color: gold)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 25,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemBuilder: (context, i) => InkWell(
            onTap: over || opened.contains(i)
                ? null
                : () => setState(() {
                      opened.add(i);
                      if (bombs.contains(i)) {
                        over = true;
                      } else {
                        score += 2;
                      }
                    }),
            child: Container(
              decoration: BoxDecoration(
                color: opened.contains(i)
                    ? (bombs.contains(i) ? Colors.red : Colors.green)
                    : panel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                opened.contains(i)
                    ? (bombs.contains(i)
                        ? Icons.warning_amber_rounded
                        : Icons.check)
                    : Icons.question_mark,
                color: gold,
              ),
            ),
          ),
        ),
        Text(over ? 'انتهت الجولة' : 'افتح الخانات'),
        FilledButton(
          onPressed: () => setState(newGame),
          child: const Text('لعبة جديدة'),
        ),
      ]);
}

// عجلة الحظ
class WheelGame extends StatefulWidget {
  const WheelGame({super.key});

  @override
  State<WheelGame> createState() => _WheelGameState();
}

class _WheelGameState extends State<WheelGame> {
  String result = 'دور العجلة';
  final options = [
    '2 نقطة',
    '5 نقاط',
    '10 نقاط',
    'حاول مرة أخرى',
    '15 نقطة',
  ];

  @override
  Widget build(BuildContext context) => GameScreen('Lucky Wheel', [
        const Icon(Icons.casino, color: gold, size: 100),
        Text(result, style: const TextStyle(color: gold, fontSize: 25)),
        FilledButton(
          onPressed: () =>
              setState(() => result = options[Random().nextInt(options.length)]),
          child: const Text('دور'),
        ),
      ]);
}

// لعبة High / Low
class HighLowGame extends StatefulWidget {
  const HighLowGame({super.key});

  @override
  State<HighLowGame> createState() => _HighLowGameState();
}

class _HighLowGameState extends State<HighLowGame> {
  int value = Random().nextInt(13) + 1;
  int score = 0;
  String message = '';

  void guess(bool higher) {
    final next = Random().nextInt(13) + 1;
    final correct = higher ? next > value : next < value;

    setState(() {
      message = next == value
          ? 'تعادل'
          : (correct ? 'صحيح!' : 'خطأ');

      if (correct) score += 5;
      value = next;
    });
  }

  @override
  Widget build(BuildContext context) => GameScreen('High / Low', [
        Text('النقاط: $score', style: const TextStyle(color: gold)),
        Box(
          child: Text(
            'بطاقتك: $value',
            style: const TextStyle(fontSize: 30),
          ),
        ),
        Text(message),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => guess(true),
                child: const Text('أعلى'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => guess(false),
                child: const Text('أقل'),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => setState(() {
            value = Random().nextInt(13) + 1;
            score = 0;
            message = '';
          }),
          child: const Text('إعادة'),
        ),
      ]);
}

// مكونات عامة
class GameScreen extends StatelessWidget {
  const GameScreen(this.title, this.children, {super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      );
}

class Box extends StatelessWidget {
  const Box({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: const TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class GameTile extends StatelessWidget {
  const GameTile(this.title, this.subtitle, this.icon, this.onTap, {super.key});

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Box(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: gold, size: 30),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right, color: gold),
        ),
      );
}
