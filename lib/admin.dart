import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ: ${snapshot.error}'),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Center(
                  child: Text('لا توجد مباريات'),
                );
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
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${event['home_name']} × ${event['away_name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '${event['league']} • ${event['status']}',
                          ),
                          Text('الموعد: ${event['starts_at']}'),
                          OutlinedButton.icon(
                            onPressed: () => addMarket(id),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة سوق'),
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
      future: db
          .from('markets')
          .select()
          .eq('event_id', eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return Column(
          children: snapshot.data!.map((market) {
            final id = market['id'].toString();

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
                    onPressed: () => addSelection(id),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة اختيار ومعامل'),
                  ),
                  selectionsForMarket(id),
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
      future: db
          .from('selections')
          .select()
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
                  '${selection['label']} | '
                  '${selection['odds']} | $result',
                ),
                if (result == 'pending')
                  Wrap(
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

  // ---------------- طلبات المحفظة ----------------

  Future<void> viewProof(String path) async {
    try {
      final signedUrl = await db.storage
          .from('wallet-proofs')
          .createSignedUrl(path, 600);

      if (!mounted) return;

      final isPdf = path.toLowerCase().endsWith('.pdf');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('إيصال التحويل'),
          content: SizedBox(
            width: double.maxFinite,
            child: isPdf
                ? SelectableText(
                    'إيصال PDF. انسخ الرابط وافتحه:\n$signedUrl',
                  )
                : InteractiveViewer(
                    child: Image.network(
                      signedUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        return const Text(
                          'تعذر عرض صورة الإيصال',
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            if (isPdf)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: signedUrl),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  message('تم نسخ رابط الإيصال');
                },
                child: const Text('نسخ الرابط'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      message('تعذر فتح الإيصال: $e');
    }
  }

  Future<void> reviewRequest(String id, bool approve) async {
    try {
      await db.rpc(
        'mero_review_wallet_request',
        params: {
          'p_request_id': id,
          'p_approve': approve,
        },
      );

      message(
        approve
            ? 'تمت الموافقة على الطلب'
            : 'تم رفض الطلب',
      );

      refresh();
    } catch (e) {
      message('تعذر معالجة الطلب: $e');
    }
  }

  Widget requestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db
          .from('wallet_requests')
          .select(
            '*, profiles!wallet_requests_user_id_fkey(display_name)',
          )
          .eq('status', 'pending')
          .order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'خطأ في الطلبات: ${snapshot.error}',
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Text('لا توجد طلبات معلقة'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final id = request['id'].toString();

            // المبلغ مخزن بالفلس: 1000 فلس = 1 دينار
            final amountFils =
                (request['amount_fils'] as num?)?.toDouble() ?? 0;
            final amount = amountFils / 1000;

            final deposit = request['kind'] == 'deposit';
            final profile = request['profiles'];
            final playerName =
                profile is Map ? profile['display_name'] : null;

            // اسم العمود الصحيح في قاعدة البيانات
            final method =
                (request['method'] ?? '-').toString();

            final senderDetails =
                (request['payment_reference'] ?? '').toString();

            final destination =
                (request['destination'] ?? '').toString();

            final proofPath =
                (request['proof_path'] ?? '').toString();

            return Card(
              color: adminSurface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      deposit ? 'طلب إيداع' : 'طلب سحب',
                      style: const TextStyle(
                        color: adminGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اللاعب: ${playerName ?? request['user_id']}',
                    ),
                    Text(
                      'المبلغ: ${amount.toStringAsFixed(3)} د.أ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('طريقة التحويل: $method'),
                    if (senderDetails.isNotEmpty)
                      Text('بيانات المرسل: $senderDetails'),
                    if (destination.isNotEmpty)
                      Text('وجهة السحب: $destination'),
                    if (proofPath.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => viewProof(proofPath),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text(
                          'عرض إيصال التحويل',
                        ),
                      ),
                    ] else if (deposit) ...[
                      const Text(
                        'لم يرفق اللاعب إيصالاً',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                    Text('التاريخ: ${request['created_at']}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                reviewRequest(id, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('موافقة'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                reviewRequest(id, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
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

  // ---------------- إدارة المستخدمين ----------------

  Future<void> adjustBalance(
    String userId,
    String playerName,
  ) async {
    final amount = TextEditingController();
    final note = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل رصيد $playerName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(
                amount,
                'المبلغ: موجب للإضافة وسالب للخصم',
                keyboard: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              field(note, 'سبب التعديل'),
              const Text(
                'مثال: 10 للإضافة أو -5 للخصم',
                style: TextStyle(color: Colors.grey),
              ),
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
            child: const Text('تأكيد التعديل'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final value = double.tryParse(amount.text.trim());

    if (value == null ||
        value == 0 ||
        note.text.trim().length < 3) {
      message('أدخل مبلغاً صحيحاً وسبباً للتعديل');
      return;
    }

    try {
      await db.rpc(
        'mero_admin_adjust_balance',
        params: {
          'p_user_id': userId,
          'p_amount': value,
          'p_note': note.text.trim(),
        },
      );

      message('تم تعديل الرصيد وتسجيل العملية');
      refresh();
    } catch (e) {
      message('تعذر تعديل الرصيد: $e');
    }
  }

  Widget usersTab() {
    return FutureBuilder<List<dynamic>>(
      future: db.rpc('mero_admin_users'),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'تعذر تحميل المستخدمين: ${snapshot.error}',
              ),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text('لا يوجد مستخدمون'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user =
                Map<String, dynamic>.from(users[index]);

            final id = user['user_id'].toString();
            final name =
                (user['display_name'] ?? 'بدون اسم').toString();

            final balance =
                (user['balance'] as num?)?.toDouble() ?? 0;

            final count = user['bets_count'] ?? 0;

            return Card(
              color: adminSurface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: adminGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      'معرّف المستخدم: $id',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text('نوع الحساب: ${user['user_role']}'),
                    Text(
                      'الرصيد: ${balance.toStringAsFixed(3)} د.أ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('عدد الرهانات: $count'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => adjustBalance(id, name),
                      icon: const Icon(
                        Icons.account_balance_wallet,
                      ),
                      label: const Text('إضافة رصيد أو خصمه'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminGold,
                        foregroundColor: Colors.black,
                      ),
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

  // ---------------- متابعة الرهانات ----------------

  Future<void> settleBet(String id) async {
    try {
      final result = await db.rpc(
        'mero_settle_bet',
        params: {'p_bet_id': id},
      );

      message('تمت تسوية القسيمة. مبلغ الإرجاع: $result');
      refresh();
    } catch (e) {
      message('تعذرت التسوية: $e');
    }
  }

  Widget betItems(String betId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db
          .from('bet_items')
          .select('*, selections(label, odds, result)')
          .eq('bet_id', betId),
      builder: (context, snapshot) {
        if (