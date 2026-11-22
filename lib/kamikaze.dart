
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KamikazePage extends StatefulWidget {
  const KamikazePage({super.key});

  @override
  State<KamikazePage> createState() => _KamikazePageState();
}

class _KamikazePageState extends State<KamikazePage> {
  final supabase = Supabase.instance.client;
  final stakeController = TextEditingController(text: '1.00');

  static const Color background = Color(0xFF10131B);
  static const Color surface = Color(0xFF1B202B);
  static const Color gold = Color(0xFFFFC928);
  static const Color blue = Color(0xFF0878E8);
  static const Color red = Color(0xFFE53935);

  static const List<double> multipliers = [
    1.2, 1.4, 1.6, 2.0,
    2.5, 3.0, 3.5, 4.0,
    5.0, 6.0, 8.0, 10.0,
  ];

  String? roundId;
  int currentStep = 0;
  int? lastSelectedColumn;
  int? bombColumn;

  double stake = 0;
  double multiplier = 1;
  double payout = 0;

  bool loading = false;
  bool gameOver = false;
  bool won = false;

  String message = 'أدخل مبلغ الرهان وابدأ اللعبة';

  // الأعمدة التي اختارها اللاعب خلال الجولة الحالية.
  final Map<int, int> selectedColumns = {};

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

  String? getRoundId(Map<String, dynamic> data) {
    final value = data['round_id'] ?? data['id'];
    return value?.toString();
  }

  void showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> loadActiveRound() async {
    try {
      final result = await supabase.rpc('mero_kamikaze_active');

      if (result == null || !mounted) return;

      final data = responseMap(result);
      final id = getRoundId(data);

      if (id == null || data['status']?.toString() != 'active') {
        return;
      }

      setState(() {
        roundId = id;
        stake = number(data['stake']);
        currentStep = number(
          data['current_step'] ?? data['step'],
        ).toInt();

        multiplier = number(
          data['multiplier'],
          currentStep > 0 ? multipliers[currentStep - 1] : 1,
        );

        payout = number(
          data['potential_return'] ?? data['payout'],
          stake * multiplier,
        );

        lastSelectedColumn = null;
        gameOver = false;
        won = false;
        message = 'لديك جولة مستمرة. أكمل اللعب أو اسحب أرباحك.';
      });
    } catch (e) {
      if (mounted) {
        showMessage('تعذر تحميل الجولة السابقة: $e');
      }
    }
  }

  Future<void> startGame() async {
    if (loading) return;

    final amount = double.tryParse(stakeController.text.trim());

    if (amount == null ||
        amount < 0.20 ||
        amount > 435.11 ||
        amount * 100 != (amount * 100).roundToDouble()) {
      showMessage('الرهان يجب أن يكون بين 0.20 و435.11 دينار وبحد أقصى منزلتين عشريتين');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_kamikaze_start',
        params: {'p_stake': amount},
      );

      final data = responseMap(result);
      final id = getRoundId(data);

      if (id == null) {
        throw Exception(data['message'] ?? 'لم يتم إنشاء الجولة');
      }

      if (!mounted) return;

      setState(() {
        roundId = id;
        stake = number(data['stake'], amount);
        currentStep = 0;
        multiplier = 1;
        payout = 0;
        lastSelectedColumn = null;
        bombColumn = null;
        selectedColumns.clear();
        gameOver = false;
        won = false;
        message = 'اختر مربعاً من الصف الأول. انتبه للانفجار!';
      });
    } catch (e) {
      showMessage('تعذر بدء اللعبة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseSquare(int column) async {
    if (loading || roundId == null || gameOver) return;
    if (currentStep >= 12) return;

    setState(() => loading = true);

    try {
      final result = await supabase.rpc(
        'mero_kamikaze_step',
        params: {
          'p_round_id': roundId,
          'p_column': column,
        },
      );

      final data = responseMap(result);
      final status = data['status']?.toString();

      if (!mounted) return;

      setState(() {
        if (status == 'lost' || data['success'] == false) {
          bombColumn = number(
            data['bomb_column'],
            column.toDouble(),
          ).toInt();

          gameOver = true;
          won = false;
          payout = 0;
          message = 'انفجار! خسرت الجولة.';
          return;
        }

        final oldStep = currentStep;
        selectedColumns[oldStep] = column;
        lastSelectedColumn = column;

        currentStep = number(
          data['step'],
          (oldStep + 1).toDouble(),
        ).toInt();

        multiplier = number(
          data['multiplier'],
          multipliers[(currentStep - 1).clamp(0, 11)],
        );

        payout = number(
          data['payout'],
          stake * multiplier,
        );

        if (status == 'completed' || currentStep >= 12) {
          gameOver = true;
          won = true;
          message = 'مبروك! وصلت الطائرة إلى نهاية المسار!';
        } else {
          message = 'نجوت! اختر مربعاً من الصف التالي.';
        }
      });
    } catch (e) {
      showMessage('حدث خطأ أثناء اختيار المربع: $e');
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
        'mero_kamikaze_cashout',
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
            'تم سحب الأرباح بنجاح: ${payout.toStringAsFixed(2)} د.أ';
      });
    } catch (e) {
      showMessage('تعذر سحب الأرباح: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void resetGame() {
    setState(() {
      roundId = null;
      currentStep = 0;
      lastSelectedColumn = null;
      bombColumn = null;
      stake = 0;
      multiplier = 1;
      payout = 0;
      selectedColumns.clear();
      gameOver = false;
      won = false;
      message = 'أدخل مبلغ الرهان وابدأ اللعبة';
    });
  }

  Widget infoBox(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 4,
        ),
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

  Widget plane() {
    return const Icon(
      Icons.flight,
      color: red,
      size: 27,
    );
  }

  Widget squareContent(int row, int column) {
    final selected = selectedColumns[row] == column;
    final isCurrentRow = row == currentStep;
    final isBomb = gameOver &&
        !won &&
        row == currentStep &&
        bombColumn == column;

    if (isBomb) {
      return const Icon(
        Icons.local_fire_department,
        color: Colors.white,
        size: 29,
      );
    }

    if (selected) {
      return plane();
    }

    if (isCurrentRow && !gameOver && roundId != null) {
      return const Icon(
        Icons.add,
        color: Colors.white70,
        size: 23,
      );
    }

    if (row < currentStep) {
      return const Icon(
        Icons.check,
        color: Colors.white,
        size: 20,
      );
    }

    return const SizedBox.shrink();
  }

  Widget gameBoard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF151C29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gold.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight, color: red, size: 22),
              SizedBox(width: 8),
              Text(
                'KAMIKAZE',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (int row = 11; row >= 0; row--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${row + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: row < currentStep
                            ? gold
                            : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (int column = 1; column <= 5; column++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1.18,
                          child: GestureDetector(
                            onTap: !loading &&
                                    !gameOver &&
                                    roundId != null &&
                                    row == currentStep
                                ? () => chooseSquare(column)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 220,
                              ),
                              decoration: BoxDecoration(
                                color: squareContentIsSelected(row, column)
                                    ? const Color(0xFF174A75)
                                    : blue,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: squareContentIsSelected(row, column)
                                      ? gold
                                      : Colors.white24,
                                  width: squareContentIsSelected(row, column)
                                      ? 2
                                      : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: blue.withOpacity(0.25),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: squareContent(row, column),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight, color: red, size: 18),
              SizedBox(width: 5),
              Text(
                'الطائرة',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(width: 20),
              Icon(Icons.local_fire_department,
                  color: Colors.white, size: 18),
              SizedBox(width: 5),
              Text(
                'الانفجار',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool squareContentIsSelected(int row, int column) {
    return selectedColumns[row] == column ||
        (gameOver &&
            !won &&
            row == currentStep &&
            bombColumn == column);
  }

  Widget multiplierStrip() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 7,
      children: [
        for (int i = 0; i < multipliers.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: i < currentStep
                  ? const Color(0xFF176B42)
                  : surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == currentStep && !gameOver
                    ? gold
                    : Colors.white12,
              ),
            ),
            child: Text(
              'x${multipliers[i] == multipliers[i].roundToDouble() ? multipliers[i].toStringAsFixed(0) : multipliers[i].toString()}',
              style: TextStyle(
                color: i < currentStep ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget actionButton({
    required String label,
    required VoidCallback? onPressed,
    Color color = gold,
    Color textColor = Colors.black,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
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
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
          centerTitle: true,
          title: const Text(
            'KAMIKAZE',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF183C61),
                      Color(0xFF172D43),
                      surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: gold.withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.flight,
                      color: red,
                      size: 58,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'KAMIKAZE',
                      style: TextStyle(
                        color: gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'اختر المربع الآمن واصعد بالطائرة!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '12 صفاً • 5 مربعات في كل صف',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  infoBox('الصف', '$currentStep / 12'),
                  infoBox('المضاعف', 'x${multiplier.toStringAsFixed(2)}'),
                  infoBox('الربح', '${payout.toStringAsFixed(2)} د.أ'),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'مضاعفات اللعبة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gold,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              multiplierStrip(),

              const SizedBox(height: 18),

              gameBoard(),

              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gameOver
                      ? (won ? Colors.greenAccent : Colors.redAccent)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

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
                      'مبلغ الرهان بالدينار الأردني',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      controller: stakeController,
                      enabled: !active && !loading,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'د.أ ',
                        border: OutlineInputBorder(),
                        hintText: '0.20 - 435.11',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الحد الأدنى 0.20 د.أ • الحد الأقصى 435.11 د.أ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (roundId == null)
                actionButton(
                  label: 'ابدأ اللعبة',
                  onPressed: startGame,
                ),

              if (active) ...[
                actionButton(
                  label: 'اختيار مربع من الصف التالي',
                  onPressed: currentStep < 12
                      ? () => showMessage('اضغط أحد المربعات الزرقاء في اللوحة')
                      : null,
                  color: blue,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 10),
                actionButton(
                  label: 'اسحب أرباحك الآن',
                  onPressed: currentStep >= 1 ? cashOut : null,
                  color: const Color(0xFF1E9B61),
                  textColor: Colors.white,
                ),
              ],

              if (gameOver) ...[
                actionButton(
                  label: won ? 'جولة جديدة' : 'العب مرة أخرى',
                  onPressed: resetGame,
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
