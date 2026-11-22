
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
  bool loading = false;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
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

  Future<void> addEvent() async {
    final sport = TextEditingController(text: 'كرة القدم');
    final league = TextEditingController();
    final home = TextEditingController();
    final away = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().add(const Duration(days: 1))
          .toIso8601String().substring(0, 16),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مباراة'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field(sport, 'الرياضة'),
              _field(league, 'الدوري أو البطولة'),
              _field(home, 'الفريق الأول'),
              _field(away, 'الفريق الثاني'),
              _field(date, 'الموعد: 2026-11-23T20:30'),
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
            child: const Text('حفظ المباراة'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
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
      setState(() {});
    } catch (e) {
      message('تعذر إضافة المباراة: $e');
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> addMarket(String eventId) async {
    final name = TextEditingController(text: 'الفائز بالمباراة');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة سوق'),
        content: _field(name, 'اسم السوق'),
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
      setState(() {});
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
        title: const Text('إضافة اختيار ومعامل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(label, 'اسم الاختيار'),
            _field(odds, 'المعامل مثل 2.00'),
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
        value == null || value <= 1 || value > 1000) {
      message('تحقق من الاسم والمعامل؛ يجب أن يكون أكبر من 1');
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
      setState(() {});
    } catch (e) {
      message('خطأ: $e');
    }
  }

  Future<void> setResult(
      String selectionId, String result) async {
    try {
      await db.from('selections').update({
        'result': result,
        'is_active': false,
      }).eq('id', selectionId);
      message('تم حفظ النتيجة');
      setState(() {});
    } catch (e) {
      message('تعذر حفظ النتيجة: $e');
    }
  }

  Future<void> closeEvent(String eventId) async {
    try {
      await db.from('events').update({
        'status': 'finished',
      }).eq('id', eventId);
      message('تم إنهاء المباراة');
      setState(() {});
    } catch (e) {
      message('تعذر إنهاء المباراة: $e');
    }
  }

  Future<void> reviewRequest(
      String id, bool approve) async {
    try {
      await db.rpc(
        'mero_review_wallet_request',
        params: {
          'p_request_id': id,
          'p_approve': approve,
          'p_note': approve ? 'تمت الموافقة' : 'تم الرفض',
        },
      );
      message(approve ? 'تمت الموافقة على الطلب' : 'تم رفض الطلب');
      setState(() {});
    } catch (e) {
      message('تعذر معالجة الطلب: $e');
    }
  }

  Future<void> settleBet(String id) async {
    try {
      await db.rpc(
        'mero_settle_bet',
        params: {'p_bet_id': id},
      );
      message('تمت تسوية القسيمة');
      setState(() {});
    } catch (e) {
      message('تعذرت التسوية: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: adminSurface,
          child: TabBar(
            controller: tabs,
            labelColor: adminGold,
            tabs: const [
              Tab(icon: Icon(Icons.sports_soccer), text: 'المباريات'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'طلبات المحفظة'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              eventsTab(),
              requestsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget eventsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: addEvent,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مباراة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: adminGold,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: db.from('events').select().order('starts_at'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Center(child: Text('لا توجد مباريات'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final id = event['id'].toString();
                  return Card(
                    color: adminSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${event['home_name']} × ${event['away_name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text('${event['league']} • ${event['status']}'),
                          Text('الموعد: ${event['starts_at']}'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => addMarket(id),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة سوق للمباراة'),
                          ),
                          marketsForEvent(id),
                          if (event['status'] == 'upcoming' ||
                              event['status'] == 'live')
                            TextButton(
                              onPressed: () => closeEvent(id),
                              child: const Text('إنهاء المباراة'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget marketsForEvent(String eventId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.from('markets').select()
          .eq('event_id', eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!.map((market) {
            final marketId = market['id'].toString();
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    market['name'].toString(),
                    style: const TextStyle(color: adminGold),
                  ),
                  TextButton.icon(
                    onPressed: () => addSelection(marketId),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة اختيار ومعامل'),
                  ),
                  selectionsForMarket(marketId),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget selectionsForMarket(String marketId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.from('selections').select()
          .eq('market_id', marketId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!.map((selection) {
            final id = selection['id'].toString();
            final result = selection['result'].toString();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${selection['label']}  |  ${selection['odds']}  |  $result',
                ),
                if (result == 'pending')
                  Wrap(
                    alignment: WrapAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () => setResult(id, 'won'),
                        child: const Text('فائز'),
                      ),
                      TextButton(
                        onPressed: () => setResult(id, 'lost'),
                        child: const Text('خاسر'),
                      ),
                      TextButton(
                        onPressed: () => setResult(id, 'void'),
                        child: const Text('ملغى'),
                      ),
                    ],
                  ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget requestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.from('wallet_requests')
          .select('*, profiles(display_name)')
          .eq('status', 'pending')
          .order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في الطلبات: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('لا توجد طلبات معلقة'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final id = request['id'].toString();
            final amount =
                (request['amount_fils'] as num).toDouble() / 1000;
            final deposit = request['kind'] == 'deposit';
            final profile = request['profiles'];
            final playerName =
                profile is Map ? profile['display_name'] : null;

            return Card(
              color: adminSurface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      deposit ? 'طلب إيداع' : 'طلب سحب',
                      style: const TextStyle(
                        color: adminGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('اللاعب: ${playerName ?? request['user_id']}'),
                    Text('المبلغ: ${amount.toStringAsFixed(3)} د.أ'),
                    Text('الطريقة: ${request['method']}'),
                    if ((request['payment_reference'] ?? '').toString().isNotEmpty)
                      Text('مرجع الدفع: ${request['payment_reference']}'),
                    if ((request['destination'] ?? '').toString().isNotEmpty)
                      Text('وجهة التحويل: ${request['destination']}'),
                    Text('تاريخ الطلب: ${request['created_at']}'),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => reviewRequest(id, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('موافقة'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => reviewRequest(id, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('رفض'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
