
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrashPage extends StatefulWidget {
  const CrashPage({super.key});

  @override
  State<CrashPage> createState() => _CrashPageState();
}

class _CrashPageState extends State<CrashPage> {
  final supabase = Supabase.instance.client;
  final stakeController = TextEditingController(text: '1.00');

  static const gold = Color(0xFFFFC928);
  static const background = Color(0xFF171A20);
  static const surface = Color(0xFF242A35);
  static const green = Color(0xFF19B76A);
  static const red = Color(0xFFE53935);

  Timer? timer;

  String? roundId;
  String statusMessage = 'ضع رهانك وابدأ اللعب';

  double balance = 0;
  double stake = 0;
  double multiplier = 1;
  double payout = 0;

  bool loading = false;
  bool running = false;
  bool finished = false;
  bool crashed = false;

  @override
  void initState() {
    super.initState();
    refreshBalance();
    loadActiveRound();
  }

  @override
  void dispose() {
    timer?.cancel();
    stakeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> responseMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw Exception('استجابة غير صحيحة من الخادم');
  }

  double number(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> refreshBalance() async {
    try {
      final result = await supabase.rpc('mero_balance');

      if (!mounted) return;

      setState(() {
        // mero_balance ترجع المبلغ بالدينار مباشرة.
        balance = number(result);
      });
    } catch (e) {
      showMessage('تعذر تحديث رصيد المحفظة: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadActiveRound() async {
    try {
      final result = await supabase.rpc('mero_crash_active');

      if (result == null || !mounted) return;

      final data = responseMap(result);

      if (data['status']?.toString() != 'active') return;

      setState(() {
        roundId = (data['round_id'] ?? data['id']).toString();
        stake = number(data['stake']);
        multiplier = number(data['multiplier'], 1);
        payout = number(data['payout'], stake * multiplier);
        running = true;
        finished = false;
        crashed = false;
        statusMessage = 'لديك جولة مستمرة';
      });

      startPolling();
    } catch (e) {
      showMessage('تعذر تحميل الجولة: $e');
    }
  }

  Future<void> startGame() async {
    if (loading || running) return;

    final amount = double.tryParse(stakeController.text.trim());

    if (amount == null ||
        amount < 0.100 ||
        amount > 435.000 ||
        amount * 1000 != (amount * 1000).roundToDouble()) {
      showMessage('الرهان يجب أن يكون بين 0.100 و435.000 دينار');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_crash_start',
        params: {'p_stake': amount},
      );

      final data = responseMap(result);
      final id = data['round_id'] ?? data['id'];

      if (id == null) {
        throw Exception(data['message'] ?? 'لم يتم إنشاء الجولة');
      }

      if (!mounted) return;

      setState(() {
        roundId = id.toString();
        stake = number(data['stake'], amount);
        multiplier = 1;
        payout = stake;
        running = true;
        finished = false;
        crashed = false;
        statusMessage = 'الجولة بدأت! اسحب أرباحك قبل الانفجار';
      });

      await refreshBalance();
      startPolling();
    } catch (e) {
      showMessage('تعذر بدء اللعبة: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void startPolling() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => updateGame(),
    );
  }

  Future<void> updateGame() async {
    if (!running || roundId == null || loading) return;

    try {
      final result = await supabase.rpc(
        'mero_crash_state',
        params: {'p_round_id': roundId},
      );

      final data = responseMap(result);
      final newStatus = data['status']?.toString();

      if (!mounted) return;

      setState(() {
        multiplier = number(data['multiplier'], multiplier);
        payout = number(data['payout'], stake * multiplier);

        if (newStatus == 'crashed') {
          running = false;
          finished = true;
          crashed = true;
          payout = 0;
          statusMessage = 'انفجرت الجولة! انتهت اللعبة';
          timer?.cancel();
        } else if (newStatus == 'cashed_out' ||
            newStatus == 'completed') {
          running = false;
          finished = true;
          statusMessage = 'انتهت الجولة';
          timer?.cancel();
        }
      });

      if (finished) {
        await refreshBalance();
      }
    } catch (e) {
      // Keep the current display if a temporary request fails.
    }
  }

  Future<void> cashOut() async {
    if (loading || !running || roundId == null) return;

    timer?.cancel();
    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_crash_cashout',
        params: {'p_round_id': roundId},
      );

      final data = responseMap(result);

      if (!mounted) return;

      setState(() {
        multiplier = number(data['multiplier'], multiplier);
        payout = number(data['payout'], payout);
        running = false;
        finished = true;
        crashed = data['status']?.toString() == 'crashed';

        statusMessage = crashed
            ? 'انفجرت الجولة! لم يتم سحب الأرباح'
            : 'تم السحب بنجاح: ${payout.toStringAsFixed(3)} JOD';
      });

      await refreshBalance();
    } catch (e) {
      showMessage('تعذر سحب الأرباح: $e');

      if (running) {
        startPolling();
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void newGame() {
    timer?.cancel();

    setState(() {
      roundId = null;
      stake = 0;
      multiplier = 1;
      payout = 0;
      running = false;
      finished = false;
      crashed = false;
      statusMessage = 'ضع رهانك وابدأ اللعب';
    });
  }

  Widget infoBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: gold,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(String label, VoidCallback? action) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
      ),
    );
  }

  Widget crashDisplay() {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'CRASH',
            style: TextStyle(
              color: gold,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            crashed ? 'انفجار!' : 'x${multiplier.toStringAsFixed(2)}',
            style: TextStyle(
              color: crashed ? red : green,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            crashed
                ? 'انتهت الجولة'
                : running
                    ? 'المضاعف يرتفع'
                    : 'بانتظار الجولة القادمة',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: surface,
          foregroundColor: gold,
          centerTitle: true,
          title: const Text(
            'CRASH',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رصيد المحفظة',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${balance.toStringAsFixed(3)} JOD',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: refreshBalance,
                      icon: const Icon(Icons.refresh, color: gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              crashDisplay(),
              const SizedBox(height: 14),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  infoBox('الرهان', '${stake.toStringAsFixed(3)} د.أ'),
                  infoBox('المضاعف', 'x${multiplier.toStringAsFixed(2)}'),
                  infoBox('الأرباح', '${payout.toStringAsFixed(3)} د.أ'),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'مبلغ الرهان',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stakeController,
                      enabled: !running && !loading,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'JOD ',
                        prefixStyle: TextStyle(color: gold),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الحد الأدنى 0.100 د.أ - الحد الأقصى 435.000 د.أ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!running && !finished)
                actionButton('ابدأ اللعب', startGame),
              if (running)
                actionButton('اسحب الأرباح', cashOut),
              if (finished) ...[
                actionButton('جولة جديدة', newGame),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: refreshBalance,
                  child: const Text('تحديث رصيد المحفظة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
