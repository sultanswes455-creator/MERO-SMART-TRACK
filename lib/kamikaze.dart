
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

  static const Color background = Color(0xFF171A20);
  static const Color surface = Color(0xFF242A35);
  static const Color gold = Color(0xFFFFC928);
  static const Color blue = Color(0xFF087D9D);
  static const Color green = Color(0xFF176B42);
  static const Color red = Color(0xFFE53935);

  static const List<double> multipliers = [
    1.2, 1.4, 1.6, 2.0,
    2.5, 3.0, 3.5, 4.0,
    5.0, 6.0, 8.0, 10.0,
  ];

  String? roundId;
  int currentStep = 0;
  int? bombColumn;

  double stake = 0;
  double multiplier = 1;
  double payout = 0;

  bool loading = false;
  bool gameOver = false;
  bool won = false;

  String message = 'أدخل مبلغ الرهان وابدأ اللعبة';

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
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('استجابة غير صحيحة من الخادم');
  }

  String? getRoundId(Map<String, dynamic> data) {
    return (data['round_id'] ?? data['id'])?.toString();
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
          currentStep > 0 ? multipliers[(currentStep - 1).clamp(0, 11)] : 1,
        );

        payout = number(
          data['potential_return'] ?? data['payout'],
          stake * multiplier,
        );

        gameOver = false;
        won = false;
        message = 'لديك جولة مستمرة. أكمل اللعب أو اجمع أرباحك.';
      });
    } catch (e) {
      if (mounted) showMessage('تعذر تحميل الجولة السابقة: $e');
    }
  }

  Future<void> startGame() async {
    if (loading) return;

    final amount = double.tryParse(stakeController.text.trim());

    if (amount == null ||
        amount < 0.20 ||
        amount > 435.11 ||
        amount * 100 != (amount * 100).roundToDouble()) {
      showMessage('الرهان بين 0.20 و435.11 دينار وبحد أقصى منزلتين عشريتين');
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
        bombColumn = null;
        selectedColumns.clear();
        gameOver = false;
        won = false;
        message = 'اختر مربعاً آمناً من الصف الأول.';
      });
    } catch (e) {
      showMessage('تعذر بدء اللعبة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseSquare(int column) async {
    if (loading || roundId == null || gameOver || currentStep >= 12) return;

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
          message = 'انفجار! انتهت الجولة.';
          return;
        }

        final oldStep = currentStep;
        selectedColumns[oldStep] = column;

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
          message = 'مبروك! وصلت إلى نهاية المسار.';
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
    if (loading || roundId == null || currentStep < 1 || gameOver) return;

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
        message = 'تم جمع الأرباح: ${payout.toStringAsFixed(3)} JOD';
      });
    } catch (e) {
      showMessage('تعذر جمع الأرباح: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void resetGame() {
    setState(() {
      roundId = null;
      currentStep = 0;
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

  void showHowToPlay() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: surface,
          title: const Text(
            'كيفية اللعب',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'ساعد الطيار الياباني على تدمير بارجة العدو!\n\n'
              'ضع الرهان قبل بداية اللعبة. الحد الأدنى 0.20 JOD والحد الأقصى 435.11 JOD.\n\n'
              'تظهر شبكة بها 12 صفاً و5 مربعات في كل صف. تطلق سفينة العدو طلقة واحدة في كل صف.\n\n'
              'اختر مربعاً آمناً للانتقال إلى المستوى التالي وزيادة المكاسب.\n\n'
              'إذا اخترت مربع الطلقة تنتهي اللعبة وتخسر الرهان.\n\n'
              'يمكنك جمع أرباحك بعد النجاة من أي صف.',
              style: TextStyle(color: Colors.white, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق', style: TextStyle(color: gold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget multiplierLabel(int row) {
    final value = multipliers[row];
    final reached = row < currentStep;

    return Container(
      width: 53,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: reached ? green : const Color(0xFF18344B),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: row == currentStep && !gameOver ? gold : Colors.white54,
        ),
      ),
      child: Text(
        'x${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString()}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget squareContent(int row, int column) {
    final selected = selectedColumns[row] == column;
    final isBomb = gameOver &&
        !won &&
        row == currentStep &&
        bombColumn == column;

    if (isBomb) {
      return const Icon(
        Icons.local_fire_department,
        color: Colors.white,
        size: 27,
      );
    }

    if (selected) {
      return const Icon(Icons.flight, color: red, size: 25);
    }

    if (row == currentStep && !gameOver && roundId != null) {
      return const Icon(Icons.add, color: Colors.white70, size: 20);
    }

    if (row < currentStep) {
      return const Icon(Icons.check, color: Colors.white, size: 18);
    }

    return const SizedBox.shrink();
  }

  bool isSelected(int row, int column) {
    return selectedColumns[row] == column ||
        (gameOver &&
            !won &&
            row == currentStep &&
            bombColumn == column);
  }

  Widget gameBoard() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF075E7C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        children: [
          for (int row = 11; row >= 0; row--)
            SizedBox(
              height: 46,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    multiplierLabel(row),
                    Expanded(
                      child: Row(
                        children: [
                          for (int column = 1; column <= 5; column++)
                            Expanded(
                              child: GestureDetector(
                                onTap: !loading &&
                                        !gameOver &&
                                        roundId != null &&
                                        row == currentStep
                                    ? () => chooseSquare(column)
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: isSelected(row, column)
                                        ? const Color(0xFF174A75)
                                        : blue,
                                    border: Border.all(
                                      color: isSelected(row, column)
                                          ? gold
                                          : Colors.white70,
                                      width: isSelected(row, column) ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: squareContent(row, column),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget infoBox(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: gold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton({
    required String label,
    required VoidCallback? onPressed,
    Color color = gold,
    Color textColor = Colors.black,
  }) {
    return SizedBox(
      height: 51,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
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
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF245E62),
          centerTitle: true,
          title: const Text(
            'KAMIKAZE',
            style: TextStyle(
              color: red,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: showHowToPlay,
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF075B58),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'الأرباح الحالية',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'JOD ${payout.toStringAsFixed(3)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              const Center(
                child: Text(
                  'KAMIKAZE',
                  style: TextStyle(
                    color: red,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ضع رهان',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stakeController,
                      enabled: !active && !loading,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 19),
                      decoration: const InputDecoration(
                        prefixText: 'JOD ',
                        prefixStyle: TextStyle(color: gold),
                        hintText: '0.20 - 435.11',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'الحد الأدنى 0.20 JOD • الحد الأقصى 435.11 JOD',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (roundId == null)
                actionButton(
                  label: 'العب',
                  onPressed: startGame,
                  color: green,
                  textColor: Colors.white,
                ),
              if (active)
                actionButton(
                  label: 'اجمع',
                  onPressed: currentStep >= 1 ? cashOut : null,
                  color: green,
                  textColor: Colors.white,
                ),
              if (gameOver)
                actionButton(
                  label: won ? 'جولة جديدة' : 'العب مرة أخرى',
                  onPressed: resetGame,
                  color: green,
                  textColor: Colors.white,
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: showHowToPlay,
                icon: const Icon(Icons.help_outline),
                label: const Text('كيفية اللعب'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  infoBox('الصف', '$currentStep / 12'),
                  infoBox('المضاعف', 'x${multiplier.toStringAsFixed(2)}'),
                  infoBox('الربح', '${payout.toStringAsFixed(3)} د.أ'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
