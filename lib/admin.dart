
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const adminGold = Color(0xFFFFC928);
const adminSurface = Color(0xFF1B202B);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  final db = Supabase.instance.client;
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Widget field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> refresh() async {
    if (mounted) setState(() {});
  }

  // ---------------- المباريات ----------------

  Future<void> addEvent() async {
    final sport = TextEditingController(text: 'كرة القدم');
    final league = TextEditingController();
    final home = TextEditingController();
    final away = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 16),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مباراة'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              field(sport, 'الرياضة'),
              field(league, 'الدوري أو البطولة'),
              field(home, 'الفريق الأول'),
              field(away, 'الفريق الثاني'),
              field(date, 'الموعد: 2026-11-23T20:30'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      if (home.text.trim().isEmpty ||
          away.text.trim().isEmpty ||
          league.text.trim().isEmpty) {
        message('أكمل بيانات المباراة');
        return;
      }

      final start = DateTime.parse(date.text.trim());

      await db.from('events').insert({
        'sport': sport.text.trim(),
        'league': league.text.trim(),
        'home_name': home.text.trim(),
        'away_name': away.text.trim(),
        'starts_at': start.toUtc().toIso8601String(),
        'status': 'upcoming',
      });

      message('تمت إضافة المباراة');
      refresh();
    } catch (e) {
      message('تعذر إضافة المباراة: $e');
    }
  }

  Future<void> addMarket(String eventId) async {
    final name = TextEditingController(text: 'الفائز بالمباراة');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة سوق'),
        content: field(name, 'اسم السوق'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (ok != true || name.text.trim().isEmpty) return;

    try {
      await db.from('markets').insert({
        'event_id': eventId,
        'name': name.text.trim(),
        'is_open': true,
      });
      message('تمت إضافة السوق');
      refresh();
    } catch (e) {
      message('خطأ: $e');
    }
  }

  Future<void> addSelection(String marketId) async {
    final label = TextEditingController();
    final odds = TextEditingController(text: '2.00');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة اختيار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(label, 'اسم الاختيار'),
            field(odds, 'المعامل'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final value = double.tryParse(odds.text.trim());

    if (label.text.trim().isEmpty ||
        value == null ||
        value <= 1 ||
        value > 1000) {
      message('تحقق من الاسم والمعامل');
      return;
    }

    try {
      await db.from('selections').insert({
        'market_id': marketId,
        'label': label.text.trim(),
        'odds': value,
        'is_active': true,
        'result': 'pending',
      });
      message('تمت إضافة الاختيار');
      refresh();
    } catch (e) {
      message('خطأ: $e');
    }
  }

  Future<void> setResult(String id, String result) async {
    try {
      await db.from('selections').update({
        'result': result,
        'is_active': false,
      }).eq('id', id);

      message('تم حفظ النتيجة');
      refresh();
    } catch (e) {
      message('تعذر حفظ النتيجة: $e');
    }
  }

  Future<void> closeEvent(String id) async {
    try {
      await db.from('events').update({
        'status': 'finished',
      }).eq('id', id);

      message('تم إنهاء المباراة');
      refresh();
    } catch (e) {
      message('تعذر إنهاء المباراة: $e');
    }
  }

  Widget eventsTab() {
    return Column(
      children: [
        Padding(
