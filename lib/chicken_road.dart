
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

  static const Color gold = Color(0xFFFFC928);
  static const Color background = Color(0xFF10131B);
  static const Color surface = Color(0xFF1B202B);

  String? roundId;
  int currentStep = 0;

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

  double number(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> responseMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw Exception('استجابة غير صحيحة من الخادم');
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> loadActiveRound() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
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
        stake = number(result['stake']);
        currentStep = number(result['current_step']).toInt();
        multiplier = number(result['multiplier'], 1);
        payout = number(result['potential_return']);

        if (payout <= 0 && currentStep > 0) {
          payout = stake * multiplier;
        }

        gameOver = false;
        won = false;
        message = 'لديك جولة مستمرة. أكمل اللعب أو اسحب أرباحك.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          message = 'تعذر تحميل الجولة السابقة: $e';
        });
      }
    }
  }

  Future<void> startGame() async {
    if (loading) return;

    final amount = double.tryParse(stakeController.text.trim());

    if (amount == null || amount < 0.10 || amount > 1000) {
      showMessage('الرهان يجب أن يكون بين 0.10 و1000 دينار');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_chicken_road_start',
        params: {'p_stake': amount},
      );

      final data = responseMap(result);

      if (data['round_id'] == null) {
        throw Exception('لم يتم إنشاء الجولة');
      }

      if (!mounted) return;

      setState(() {
        roundId = data['round_id'].toString();
        stake = number(data['stake'], amount);
        currentStep = 0;
        multiplier = 1;
        payout = stake;
        gameOver = false;
        won = false;
        message = 'انطلقت الدجاجة! اعبر الخطوة الأولى.';
      });
    } catch (e) {
      showMessage('تعذر بدء اللعبة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> playStep() async {
    if (loading || roundId == null || gameOver) return;

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_chicken_road_step',
        params: {'p_round_id': roundId},
      );

      final data = responseMap(result);
      final status = data['status']?.toString();

      if (!mounted) return;

      setState(() {
        currentStep = number(
          data['step'],
          currentStep.toDouble(),
        ).toInt();

        if (status == 'lost' || data['success'] == false) {
          gameOver = true;
          won = false;
          payout = 0;
          message = 'احترق الطريق! خسرت الجولة. حظاً أوفر.';
        } else if (status == 'completed') {
          gameOver = true;
          won = true;
          multiplier = number(data['multiplier'], multiplier);
          payout = number(data['payout']);
          message = 'مبروك! وصلت الدجاجة إلى نهاية الطريق!';
        } else {
          multiplier = number(data['multiplier'], multiplier);
          payout = number(data['payout'], stake * multiplier);
          message = 'نجحت بالقفز! وصلت إلى الخطوة $currentStep.';
        }
      });
    } catch (e) {
      showMessage('حدث خطأ أثناء اللعب: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> cashOut() async {
    if (loading || roundId == null || currentStep < 1 || gameOver) {
      return;
    }

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_chicken_road_cashout',
        params: {'p_round_id': roundId},
      );

      final data = responseMap(result);

      if (!mounted) return;

      setState(() {
        multiplier = number(data['multiplier'], multiplier);
        payout = number(data['payout'], payout);
        gameOver = true;
        won = true;
        message =
            'تم السحب بنجاح! ربحت ${payout.toStringAsFixed(2)} دينار.';
      });
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
      won = false;
      message = 'أدخل مبلغ الرهان وابدأ اللعب';
    });
  }

  Widget infoBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // يحوّل رقم الخطوة إلى موقع على الطريق المتعرّج.
  Offset cellPosition(int step, double cellWidth, double cellHeight) {
    final index = (step - 1).clamp(0, 19);
    final row = index ~/ 5;
    final positionInRow = index % 5;

    final column = row.isEven ? positionInRow : 4 - positionInRow;

    return Offset(
      column * cellWidth,
      row * cellHeight,
    );
  }

  Widget roadBoard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF17251F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gold.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1.35,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 5;
            final cellHeight = constraints.maxHeight / 4;

            final chickenStep = currentStep == 0 ? 1 : currentStep;
            final position = cellPosition(
              chickenStep,
              cellWidth,
              cellHeight,
            );

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // أرضية الطريق
                Positioned.fill(
                  child: CustomPaint(
                    painter: RoadPainter(),
                  ),
                ),

                // خانات الطريق العشرون
                for (int i = 1; i <= 20; i++)
                  Positioned(
                    left: cellPosition(i, cellWidth, cellHeight).dx + 3,
                    top: cellPosition(i, cellWidth, cellHeight).dy + 3,
                    width: cellWidth - 6,
                    height: cellHeight - 6,
                    child: _roadTile(i),
                  ),

                // حركة الدجاجة بين الخانات
                if (!gameOver || won)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeInOut,
                    left: position.dx,
                    top: position.dy,
                    width: cellWidth,
                    height: cellHeight,
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: loading ? 1.12 : 1,
                        child: const Text(
                          '🐔',
                          style: TextStyle(fontSize: 35),
                        ),
                      ),
                    ),
                  ),

                // تأثير النار عند الخسارة
                if (gameOver && !won)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    left: position.dx,
                    top: position.dy,
                    width: cellWidth,
                    height: cellHeight,
                    child: const Center(
                      child: Text(
                        '🔥',
                        style: TextStyle(
                          fontSize: 43,
                          shadows: [
                            Shadow(
                              color: Colors.orange,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // نقطة البداية
                if (currentStep == 0 && roundId != null)
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Text(
                      'START',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // علامة النهاية
                Positioned(
                  top: 2,
                  right: 2,
                  child: Text(
                    'FINISH 🏁',
                    style: TextStyle(
                      color: gold.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _roadTile(int step) {
    final passed = step <= currentStep;
    final isNext = step == currentStep + 1 &&
        roundId != null &&
        !gameOver;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: passed
            ? const Color(0xFFB78A1D)
            : isNext
                ? const Color(0xFF276B42)
                : const Color(0xFF26352D),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isNext
              ? Colors.white
              : passed
                  ? gold
                  : Colors.white24,
          width: isNext ? 2 : 1,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 9,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: passed ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget actionButton({
    required String text,
    required VoidCallback? onPressed,
    Color color = gold,
    Color textColor = Colors.black,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = roundId != null && !gameOver;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: surface,
          title: const Text(
            'CHICKEN ROAD',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(15),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF174C31),
                      Color(0xFF172D25),
                      surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: gold.withOpacity(0.35),
                  ),
                ),
                child: const Column(
                  children: [
                    Text('🐔', style: TextStyle(fontSize: 55)),
                    SizedBox(height: 8),
                    Text(
                      'CHICKEN ROAD',
                      style: TextStyle(
                        color: gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'اقفز عبر الطريق واجمع أرباحك!',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '20 خطوة • مخاطرة متوسطة',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  infoBox('الخطوة', '$currentStep / 20'),
                  infoBox('المضاعف', '${multiplier.toStringAsFixed(2)}x'),
                  infoBox('الأرباح', '${payout.toStringAsFixed(2)} د.أ'),
                ],
              ),

              const SizedBox(height: 18),

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

              roadBoard(),

              const SizedBox(height: 10),

              Text(
                gameOver && !won
                    ? '🔥 انتهت الجولة بالخسارة'
                    : gameOver && won
                        ? '🏆 انتهت الجولة بالفوز'
                        : active
                            ? '🐔 الدجاجة وصلت إلى $currentStep من 20'
                            : 'ابدأ الجولة لتحريك الدجاجة',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مبلغ الرهان (دينار أردني)',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stakeController,
                      enabled: !active && !loading,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'مثال: 1.00',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              if (roundId == null)
                actionButton(
                  text: 'ابدأ اللعبة',
                  onPressed: startGame,
                ),

              if (active) ...[
                actionButton(
                  text: '🐔 اقفز إلى الخطوة التالية',
                  onPressed: playStep,
                  color: const Color(0xFF269653),
                  textColor: Colors.white,
                ),
                const SizedBox(height: 10),
                actionButton(
                  text: '💰 اسحب أرباحي الآن',
                  onPressed: currentStep >= 1 ? cashOut : null,
                  color: gold,
                ),
              ],

              if (gameOver) ...[
                actionButton(
                  text: won ? 'ابدأ جولة جديدة' : 'العب مرة أخرى',
                  onPressed: newGame,
                  color: gold,
                ),
              ],

              const SizedBox(height: 18),

              const Text(
                'يتم احتساب نتيجة اللعبة والأرباح والسحب من الخادم.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
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

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2;

    for (int i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) => false;
}
