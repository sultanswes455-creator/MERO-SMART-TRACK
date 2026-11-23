
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFFFC928);
const surface = Color(0xFF1B202B);

class BettingPage extends StatefulWidget {
  const BettingPage({super.key});

  @override
  State<BettingPage> createState() => _BettingPageState();
}

class _BettingPageState extends State<BettingPage> {
  final db = Supabase.instance.client;
  final stakeController = TextEditingController(text: '1.000');

  final Map<String, Map<String, dynamic>> slip = {};

  bool loading = false;

  int get stakeFils {
    final value = double.tryParse(
          stakeController.text.trim().replaceAll(',', '.'),
        ) ??
        0;

    if (!value.isFinite || value < 0) return 0;
    return (value * 1000).round();
  }

  double get stakeJod => stakeFils / 1000.0;

  double get totalOdds {
    return slip.values.fold<double>(
      1,
      (total, item) {
        final odds = (item['odds'] as num).toDouble();
        return total * odds;
      },
    );
  }

  double get potentialReturn => stakeJod * totalOdds;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void addSelection(
    Map<String, dynamic> selection,
    String eventId,
  ) {
    setState(() {
      slip.removeWhere(
        (key, value) => value['event_id'] == eventId,
      );

      slip[selection['id'].toString()] = {
        ...selection,
        'event_id': eventId,
      };
    });
  }

  Future<void> placeBet() async {
    if (loading) return;

    if (slip.isEmpty) {
      showMessage('اختر نتيجة أولاً');
      return;
    }

    if (stakeFils < 100) {
      showMessage('الحد الأدنى للرهان 0.100 دينار');
      return;
    }

    if (stakeFils > 100000000) {
      showMessage('المبلغ يتجاوز الحد الأقصى');
      return;
    }

    if (slip.length > 20) {
      showMessage('الحد الأقصى 20 اختياراً');
      return;
    }

    if (slip.values.any((item) {
      final odds = (item['odds'] as num?)?.toDouble() ?? 0;
      return !odds.isFinite || odds <= 1 || odds > 1000;
    })) {
      showMessage('يوجد معامل غير صالح');
      return;
    }

    setState(() => loading = true);

    try {
      await db.rpc(
        'mero_place_bet',
        params: {
          'p_selection_ids': slip.keys.toList(),
          'p_stake': stakeJod,
        },
      );

      if (!mounted) return;

      setState(() {
        slip.clear();
        stakeController.text = '1.000';
      });

      showMessage('تم تسجيل الرهان بنجاح');
    } on PostgrestException catch (e) {
      showMessage('تعذر تنفيذ الرهان: ${e.message}');
    } catch (e) {
      showMessage('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    stakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: eventsList()),
        slipPanel(),
      ],
    );
  }

  Widget eventsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db
          .from('events')
          .select()
          .inFilter('status', ['upcoming', 'live'])
          .order('starts_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'تعذر تحميل المباريات: ${snapshot.error}',
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return const Center(
            child: Text('لا توجد مباريات متاحة حالياً'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return eventCard(events[index]);
          },
        );
      },
    );
  }

  Widget eventCard(Map<String, dynamic> event) {
    final eventId = event['id'].toString();
    final status = event['status']?.toString() ?? '';

    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              event['league']?.toString() ??
                  event['sport']?.toString() ??
                  'مباراة',
              style: const TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${event['home_team']}  ×  ${event['away_team']}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status == 'live' ? 'مباشرة' : 'قادمة',
              style: TextStyle(
                color: status == 'live'
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            marketsList(eventId),
          ],
        ),
      ),
    );
  }

  Widget marketsList(String eventId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db
          .from('markets')
          .select()
          .eq('event_id', eventId)
          .eq('active', true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text(
            'خطأ في تحميل الأسواق: ${snapshot.error}',
          );
        }

        final markets = snapshot.data ?? [];

        if (markets.isEmpty) {
          return const Text('لا توجد أسواق متاحة');
        }

        return Column(
          children: markets.map((market) {
            return marketOptions(market, eventId);
          }).toList(),
        );
      },
    );
  }

  Widget marketOptions(
    Map<String, dynamic> market,
    String eventId,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db
          .from('selections')
          .select()
          .eq('market_id', market['id'].toString())
          .eq('active', true)
          .eq('result', 'pending'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text(
            'خطأ في تحميل الاختيارات: ${snapshot.error}',
          );
        }

        final options = snapshot.data ?? [];

        if (options.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              market['title']?.toString() ?? 'السوق',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: gold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final id = option['id'].toString();
                final selected = slip.containsKey(id);

                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? gold.withOpacity(0.2)
                        : null,
                    side: BorderSide(
                      color: selected ? gold : Colors.white24,
                    ),
                  ),
                  onPressed: loading
                      ? null
                      : () => addSelection(option, eventId),
                  child: Text(
                    '${option['name']}  ${option['odds']}',
                    style: TextStyle(
                      color: selected ? gold : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget slipPanel() {
    return Container(
      color: surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'قسيمة الرهان',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text('${slip.length} اختيارات'),
              IconButton(
                onPressed: slip.isEmpty || loading
                    ? null
                    : () => setState(() => slip.clear()),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          ...slip.entries.map((entry) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    entry.value['name'].toString(),
                  ),
                ),
                Text('× ${entry.value['odds']}'),
                IconButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            slip.remove(entry.key);
                          });
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            );
          }),
          TextField(
            controller: stakeController,
            enabled: !loading,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'مبلغ الرهان بالدينار',
              hintText: 'مثال: 1.000',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            'المعامل الإجمالي: '
            '${slip.isEmpty ? '—' : totalOdds.toStringAsFixed(3)}',
          ),
          Text(
            'العائد المحتمل: '
            '${potentialReturn.toStringAsFixed(3)} د.أ',
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: loading || slip.isEmpty
                ? null
                : placeBet,
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
            ),
            child: Text(
              loading ? 'يرجى الانتظار...' : 'تأكيد القسيمة',
            ),
          ),
        ],
      ),
    );
  }
}
