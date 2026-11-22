
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChickenRoadPage extends StatefulWidget {
  const ChickenRoadPage({super.key});

  @override
  State<ChickenRoadPage> createState() => _ChickenRoadPageState();
}

class _ChickenRoadPageState extends State<ChickenRoadPage> {
  final supabase = Supabase.instance.client;
  final stakeController = TextEditingController(text: '1.00');

  static const gold = Color(0xFFFFC928);
  static const background = Color(0xFF10131B);
  static const surface = Color(0xFF1B202B);

  String? roundId;
  int currentStep = 0;
  double stake = 0;
  double multiplier = 1;
  double payout = 0;

  bool loading = false;
  bool gameOver = false;
  String status = 'لم تبدأ الجولة بعد';

  @override
  void initState() {
    super.initState();
    loadActiveRound();
  }

  @override
  void dispose() {
    stakeController.dispose();
    super.dispose();
  }

  double numberValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> responseMap(dynamic value) {
    return Map<String, dynamic>.from(value as Map);
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadActiveRound() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final result = await supabase
          .from('chicken_road_rounds')
          .select(
            'id, stake, current_step, multiplier, potential_return, status',
          )
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (result == null || !mounted) return;

      setState(() {
        roundId = result['id'].toString();
        stake = numberValue(result['stake']);
        currentStep = (result['current_step'] as num).toInt();
        multiplier = numberValue(result['multiplier']);
        payout = numberValue(result['potential_return']);
        status = 'لديك جولة نشطة';
        gameOver = false;
        stakeController.text = stake.toStringAsFixed(2);
      });
    } catch (e) {
      showMessage('تعذر استعادة الجولة: $e');
    }
  }

  Future<void> startGame() async {
    if (loading || roundId != null) return;

    final amount = double.tryParse(
      stakeController.text.trim().replaceAll(',', '.'),
    );

    if (amount == null || amount < 0.10 || amount > 1000) {
      showMessage('أدخل مبلغاً من 0.10 إلى 1000 دينار');
      return;
    }

    if ((amount * 100).roundToDouble() != amount * 100) {
      showMessage('المبلغ يجب أن يحتوي على منزلتين عشريتين كحد أقصى');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_chicken_road_start',
        params: {'p_stake': amount},
      );

      final data = responseMap(result);

      if (!mounted) return;

      setState(() {
        roundId = data['round_id'].toString();
        stake = numberValue(data['stake']);
        currentStep = 0;
        multiplier = 1;
        payout = stake;
        gameOver = false;
        status = 'الجولة بدأت';
      });

      showMessage('تم بدء الجولة وخصم الرهان');
    } catch (e) {
      showMessage('تعذر بدء اللعبة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> playStep() async {
    final id = roundId;
    if (loading || id == null || gameOver) return;

    if (currentStep >= 20) return;

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_chicken_road_step',
        params: {'p_round_id': id},
      );

      final data = responseMap(result);
      final resultStatus = data['status']?.toString();

      if (!mounted) return;

      setState(() {
        currentStep = (data['step'] as num?)?.toInt() ?? currentStep;
        multiplier = numberValue(data['multiplier']);
        payout = numberValue(data['payout']);

        if (resultStatus == 'lost') {
          gameOver = true;
          roundId = null;
          status = 'خسرت الجولة';
        } else if (resultStatus == 'completed') {
          gameOver = true;
          roundId = null;
          status = 'أكملت جميع الخطوات!';
        } else {
          status = 'خطوة ناجحة! يمكنك السحب أو المتابعة';
        }
      });

      if (resultStatus == 'lost') {
        showMessage('انتهت الجولة. حظاً أوفر في المرة القادمة');
      } else if (resultStatus == 'completed') {
        showMessage('مبروك! تم إكمال اللعبة وإضافة الأرباح للمحفظة');
      } else {
        showMessage('نجحت الخطوة $currentStep');
      }
    } catch (e) {
      showMessage('تعذر تنفيذ الخطوة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> cashOut() async {
    final id = roundId;
    if (loading || id == null || currentStep < 1) return;

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_chicken_road_cashout',
        params: {'p_round_id': id},
      );

      final data = responseMap(result);
      final paid = numberValue(data['payout']);

      if (!mounted) return;

      setState(() {
        payout = paid;
        multiplier = numberValue(data['multiplier']);
        currentStep = (data['step'] as num?)?.toInt() ?? currentStep;
        roundId = null;
        gameOver = true;
        status = 'تم سحب الأرباح';
      });

      showMessage('تم سحب ${paid.toStringAsFixed(2)} دينار إلى محفظتك');
    } catch (e) {
      showMessage('تعذر سحب الأرباح: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void newGame() {
    setState(() {
      roundId = null;
      currentStep = 0;
      stake = 0;
      multiplier = 1;
      payout = 0;
      gameOver = false;
      status = 'لم تبدأ الجولة بعد';
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = roundId != null && !gameOver;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        title: const Text(
          'Chicken Road',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.route,
                  color: gold,
                  size: 65,
                ),
                const SizedBox(height: 10),
                const Text(
                  'طريق الدجاجة',
                  style: TextStyle(
                    color: gold,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '20 خطوة • مخاطرة متوسطة',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: stakeController,
                  enabled: !active && !loading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'مبلغ الرهان بالدينار الأردني',
                    suffixText: 'JOD',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: infoBox(
                        'الخطوة',
                        '$currentStep / 20',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: infoBox(
                        'المضاعف',
                        '${multiplier.toStringAsFixed(2)}x',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                infoBox(
                  'الأرباح المحتملة',
                  '${payout.toStringAsFixed(2)} دينار',
                  wide: true,
                ),
                const SizedBox(height: 16),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!active && !gameOver)
            actionButton(
              'ابدأ اللعبة',
              Icons.play_arrow,
              startGame,
            ),
          if (active) ...[
            actionButton(
              'الخطوة التالية',
              Icons.directions_walk,
              playStep,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading || currentStep < 1 ? null : cashOut,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('اسحب الأرباح الآن'),
              style: OutlinedButton.styleFrom(
                foregroundColor: gold,
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: gold),
              ),
            ),
          ],
          if (gameOver)
            actionButton(
              'جولة جديدة',
              Icons.refresh,
              newGame,
            ),
          if (loading) ...[
            const SizedBox(height: 18),
            const Center(
              child: CircularProgressIndicator(color: gold),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'كل خطوة ناجحة ترفع المضاعف. يمكنك سحب الأرباح بعد أي خطوة ناجحة، أو متابعة اللعب حتى الخطوة 20.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget infoBox(String title, String value, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: gold,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton(
    String label,
    IconData icon,
    VoidCallback action,
  ) {
    return ElevatedButton.icon(
      onPressed: loading ? null : action,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 54),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
