
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChickenRoadPage extends StatefulWidget {
  const ChickenRoadPage({super.key});

  @override
  State<ChickenRoadPage> createState() => _ChickenRoadPageState();
}

class _ChickenRoadPageState extends State<ChickenRoadPage> {
  final db = Supabase.instance.client;
  final stakeController = TextEditingController(text: '0.10');

  static const gold = Color(0xFFFFC928);
  static const bg = Color(0xFF10151B);
  static const panel = Color(0xFF202A2B);

  static const double minStake = 0.10;
  static const double maxStake = 435.00;

  String? roundId;
  int step = 0;
  double stake = 0;
  double multiplier = 1;
  double payout = 0;

  bool loading = false;
  bool gameOver = false;
  bool won = false;

  String message = 'أدخل مبلغ الرهان وابدأ اللعب';

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

  double numValue(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> mapValue(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    throw Exception('استجابة غير صحيحة من الخادم');
  }

  void notify(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void setStake(double amount) {
    if (loading || roundId != null) return;
    stakeController.text = amount.toStringAsFixed(2);
  }

  Future<void> loadActiveRound() async {
    final user = db.auth.currentUser;
    if (user == null) return;

    try {
      final result = await db
          .from('chicken_road_rounds')
          .select('id, stake, current_step, multiplier, potential_return, status')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (result == null || !mounted) return;

      setState(() {
        roundId = result['id'].toString();
        stake = numValue(result['stake']);
        stakeController.text = stake.toStringAsFixed(2);
        step = numValue(result['current_step']).toInt();
        multiplier = numValue(result['multiplier'], 1);
        payout = numValue(
          result['potential_return'],
          stake * multiplier,
        );
        gameOver = false;
        won = false;
        message = 'لديك جولة مستمرة، أكمل اللعب أو اجمع أرباحك.';
      });
    } catch (e) {
      notify('تعذر تحميل الجولة: $e');
    }
  }

  Future<void> startGame() async {
    if (loading || roundId != null) return;

    final text = stakeController.text.trim();
    final amount = double.tryParse(text);

    final validFormat = RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text);

    if (amount == null ||
        !validFormat ||
        amount < minStake ||
        amount > maxStake) {
      notify('الرهان يجب أن يكون بين 0.10 و435.00 دينار، وبحد أقصى منزلتين عشريتين');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await db.rpc(
        'mero_chicken_road_start',
        params: {'p_stake': amount},
      );

      final data = mapValue(result);
      if (data['round_id'] == null) {
        throw Exception('لم يتم إنشاء الجولة');
      }

      if (!mounted) return;
      setState(() {
        roundId = data['round_id'].toString();
        stake = numValue(data['stake'], amount);
        step = 0;
        multiplier = 1;
        payout = stake;
        gameOver = false;
        won = false;
        message = 'الدجاجة جاهزة! اضغط اقفز.';
      });
    } catch (e) {
      notify('تعذر بدء اللعبة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> playStep() async {
    if (loading || roundId == null || gameOver) return;

    setState(() => loading = true);

    try {
      final result = await db.rpc(
        'mero_chicken_road_step',
        params: {'p_round_id': roundId},
      );

      final data = mapValue(result);
      final status = data['status']?.toString();

      if (!mounted) return;

      setState(() {
        step = numValue(data['step'], step.toDouble()).toInt();

        if (status == 'lost' || data['success'] == false) {
          gameOver = true;
          won = false;
          payout = 0;
          message = '🔥 احترقت الدجاجة! انتهت الجولة.';
        } else if (status == 'completed') {
          gameOver = true;
          won = true;
          multiplier = numValue(data['multiplier'], multiplier);
          payout = numValue(data['payout'], payout);
          message = '🏆 وصلت إلى نهاية الطريق!';
        } else {
          multiplier = numValue(data['multiplier'], multiplier);
          payout = numValue(data['payout'], stake * multiplier);
          message = 'قفزة ناجحة! وصلت إلى الخطوة $step.';
        }
      });
    } catch (e) {
      notify('خطأ أثناء القفز: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> cashOut() async {
    if (loading || roundId == null || step < 1 || gameOver) return;

    setState(() => loading = true);

    try {
      final result = await db.rpc(
        'mero_chicken_road_cashout',
        params: {'p_round_id': roundId},
      );

      final data = mapValue(result);
      if (!mounted) return;

      setState(() {
        multiplier = numValue(data['multiplier'], multiplier);
        payout = numValue(data['payout'], payout);
        gameOver = true;
        won = true;
        message = 'تم جمع الأرباح بنجاح!';
      });
    } catch (e) {
      notify('تعذر جمع الأرباح: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void resetGame() {
    setState(() {
      roundId = null;
      step = 0;
      stake = 0;
      multiplier = 1;
      payout = 0;
      gameOver = false;
      won = false;
      stakeController.text = '0.10';
      message = 'أدخل مبلغ الرهان وابدأ اللعب';
    });
  }

  Offset cellPosition(int number, double w, double h) {
    final index = (number - 1).clamp(0, 19);
    final row = index ~/ 5;
    final col = row.isEven ? index % 5 : 4 - (index % 5);
    return Offset(col * w, row * h);
  }

  Widget tile(int number) {
    final passed = number <= step;
    final next = number == step + 1 && roundId != null && !gameOver;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: passed
              ? const [Color(0xFFD9AA37), Color(0xFF8D651C)]
              : next
                  ? const [Color(0xFF43B96B), Color(0xFF176B37)]
                  : const [Color(0xFF526B50), Color(0xFF304936)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: next ? Colors.white : Colors.white24,
          width: next ? 2 : 1,
        ),
        boxShadow: [
          if (next)
            BoxShadow(
              color: Colors.green.withOpacity(0.45),
              blurRadius: 10,
            ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: passed ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget road() {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF183D29),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: gold, width: 1.5),
      ),
      child: AspectRatio(
        aspectRatio: 1.12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth / 5;
            final h = constraints.maxHeight / 4;
            final pos = cellPosition(step == 0 ? 1 : step, w, h);

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: RoadPainter()),
                ),
                for (int i = 1; i <= 20; i++)
                  Positioned(
                    left: cellPosition(i, w, h).dx + 3,
                    top: cellPosition(i, w, h).dy + 3,
                    width: w - 6,
                    height: h - 6,
                    child: tile(i),
                  ),
                if (!gameOver || won)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeInOut,
                    left: pos.dx,
                    top: pos.dy,
                    width: w,
                    height: h,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(step),
                        tween: Tween(begin: 0, end: math.pi),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, -math.sin(value) * 23),
                            child: child,
                          );
                        },
                        child: const Text(
                          '🐔',
                          style: TextStyle(
                            fontSize: 37,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(2, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (gameOver && !won)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    left: pos.dx,
                    top: pos.dy,
                    width: w,
                    height: h,
                    child: const Center(
                      child: Text(
                        '🔥',
                        style: TextStyle(
                          fontSize: 48,
                          shadows: [
                            Shadow(color: Colors.orange, blurRadius: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 2,
                  right: 3,
                  child: Text(
                    'FINISH 🏁',
                    style: TextStyle(
                      color: gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  left: 3,
                  child: Text(
                    'START',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget stat(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(
    String text,
    VoidCallback? action, {
    Color color = gold,
    Color textColor = Colors.black,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton(
        onPressed: loading ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget stakeQuickButton(String label, double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: (roundId == null && !loading)
            ? () => setStake(amount)
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: BorderSide(color: gold.withOpacity(0.55)),
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = roundId != null && !gameOver;
    final canEditStake = roundId == null && !loading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: panel,
          centerTitle: true,
          title: const Text(
            'CHICKEN ROAD',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(13),
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF225C35), Color(0xFF172D25)],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: gold.withOpacity(0.4)),
                ),
                child: const Column(
                  children: [
                    Text('🐔', style: TextStyle(fontSize: 54)),
                    SizedBox(height: 5),
                    Text(
                      'CHICKEN ROAD',
                      style: TextStyle(
                        color: gold,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'اقفز عبر الطريق واجمع أرباحك!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  stat('الخطوة', '$step / 20'),
                  stat('المضاعف', '${multiplier.toStringAsFixed(2)}x'),
                  stat('الأرباح', '${payout.toStringAsFixed(2)} د.أ'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'طريق الدجاجة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gold,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              road(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: gold.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'مبلغ الرهان بالدينار الأردني',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'الحد الأدنى 0.10 د.أ — الحد الأقصى 435.00 د.أ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stakeController,
                      enabled: canEditStake,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      style: const TextStyle(
                        color: gold,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.10',
                        hintStyle: const TextStyle(color: Colors.white38),
                        suffixText: 'د.أ',
                        suffixStyle: const TextStyle(color: gold),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(color: gold.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(color: gold.withOpacity(0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canEditStake
                                ? () => setStake(minStake)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34483A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('MIN 0.10'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canEditStake
                                ? () => setStake(maxStake)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34483A),
                              foregroundColor: gold,
                            ),
                            child: const Text('MAX 435'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        stakeQuickButton('1', 1),
                        const SizedBox(width: 5),
                        stakeQuickButton('2', 2),
                        const SizedBox(width: 5),
                        stakeQuickButton('5', 5),
                        const SizedBox(width: 5),
                        stakeQuickButton('10', 10),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        stakeQuickButton('25', 25),
                        const SizedBox(width: 5),
                        stakeQuickButton('50', 50),
                        const SizedBox(width: 5),
                        stakeQuickButton('100', 100),
                        const SizedBox(width: 5),
                        stakeQuickButton('200', 200),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (roundId == null)
                actionButton(
                  'ابدأ اللعبة',
                  startGame,
                  color: const Color(0xFF269653),
                  textColor: Colors.white,
                ),
              if (active) ...[
                actionButton(
                  '🐔 اقفز إلى الخطوة التالية',
                  playStep,
                  color: const Color(0xFF269653),
                  textColor: Colors.white,
                ),
                const SizedBox(height: 10),
                actionButton(
                  '💰 اجمع أرباحي الآن',
                  step >= 1 ? cashOut : null,
                ),
              ],
              if (gameOver)
                actionButton(
                  won ? 'جولة جديدة' : 'العب مرة أخرى',
                  resetGame,
                  color: const Color(0xFF269653),
                  textColor: Colors.white,
                ),
              const SizedBox(height: 15),
              const Text(
                'نتيجة الجولة والأرباح يتم احتسابها من الخادم.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF405B43)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      paint,
    );

    final line = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2;

    for (int i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) => false;
}
