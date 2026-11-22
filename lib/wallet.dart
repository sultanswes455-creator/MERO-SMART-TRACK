
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const walletOwnerName = 'عبدالله صويص';
const walletOwnerNumber = '0780764620';

final walletDb = Supabase.instance.client;

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final amount = TextEditingController();
  final reference = TextEditingController();
  final destination = TextEditingController();

  String method = 'Orange Money';
  String kind = 'deposit';
  bool loading = false;

  Future<double> getBalance() async {
    final result = await walletDb.rpc('mero_balance');
    if (result == null) return 0;
    if (result is num) return result.toDouble();
    return double.tryParse(result.toString()) ?? 0;
  }

  void notify(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> copyNumber() async {
    await Clipboard.setData(
      const ClipboardData(text: walletOwnerNumber),
    );
    notify('تم نسخ رقم المحفظة');
  }

  Future<void> submit() async {
    final value = double.tryParse(amount.text.trim());

    if (value == null || value <= 0) {
      notify('أدخل مبلغاً صحيحاً');
      return;
    }

    if (value < 1) {
      notify(
        kind == 'deposit'
            ? 'الحد الأدنى للإيداع هو 1 JOD'
            : 'الحد الأدنى للسحب هو 1 JOD',
      );
      return;
    }

    if (value > 200) {
      notify(
        kind == 'deposit'
            ? 'الحد الأقصى للإيداع هو 200 JOD'
            : 'الحد الأقصى للسحب هو 200 JOD',
      );
      return;
    }

    if (kind == 'withdrawal' &&
        destination.text.trim().isEmpty) {
      notify('أدخل رقم محفظتك لاستلام السحب');
      return;
    }

    if (kind == 'deposit' &&
        reference.text.trim().isEmpty) {
      notify('أدخل رقم مرجع الحوالة');
      return;
    }

    setState(() => loading = true);

    try {
      final fils = (value * 1000).round();

      await walletDb.rpc(
        'mero_create_wallet_request',
        params: {
          'p_kind': kind,
          'p_amount_fils': fils,
          'p_method': method,
          'p_payment_reference':
              kind == 'deposit'
                  ? reference.text.trim()
                  : '',
          'p_destination':
              kind == 'withdrawal'
                  ? destination.text.trim()
                  : '',
          'p_proof_path': null,
        },
      );

      amount.clear();
      reference.clear();
      destination.clear();

      if (mounted) {
        notify('تم إرسال الطلب بنجاح. بانتظار مراجعة الإدارة.');
        setState(() {});
      }
    } on PostgrestException catch (e) {
      notify('تعذر إرسال الطلب: ${e.message}');
    } catch (e) {
      notify('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    amount.dispose();
    reference.dispose();
    destination.dispose();
    super.dispose();
  }

  Widget limitsCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B202B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFC928).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind == 'deposit' ? 'حدود الإيداع' : 'حدود السحب',
            style: const TextStyle(
              color: Color(0xFFFFC928),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الحد الأدنى'),
              Text(
                '1 JOD',
                style: TextStyle(
                  color: Color(0xFFFFC928),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الحد الأقصى'),
              Text(
                '200 JOD',
                style: TextStyle(
                  color: Color(0xFFFFC928),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        FutureBuilder<double>(
          future: getBalance(),
          builder: (context, snapshot) {
            final jod = snapshot.data ?? 0.0;

            return Card(
              color: const Color(0xFF1B202B),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('رصيد محفظتك'),
                    const SizedBox(height: 8),
                    Text(
                      '${jod.toStringAsFixed(3)} د.أ',
                      style: const TextStyle(
                        color: Color(0xFFFFC928),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (snapshot.hasError)
                      const Text('تعذر تحميل الرصيد'),
                    if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'deposit',
              label: Text('إيداع'),
              icon: Icon(Icons.add_circle_outline),
            ),
            ButtonSegment(
              value: 'withdrawal',
              label: Text('سحب'),
              icon: Icon(Icons.money_outlined),
            ),
          ],
          selected: {kind},
          onSelectionChanged: (value) {
            setState(() {
              kind = value.first;
            });
          },
        ),

        const SizedBox(height: 18),

        limitsCard(),

        const SizedBox(height: 18),

        DropdownButtonFormField<String>(
          value: method,
          decoration: const InputDecoration(
            labelText: 'طريقة التحويل',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Orange Money',
              child: Text('Orange Money'),
            ),
            DropdownMenuItem(
              value: 'CliQ',
              child: Text('CliQ'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => method = value);
            }
          },
        ),

        const SizedBox(height: 16),

        if (kind == 'deposit') ...[
          Card(
            color: const Color(0xFF1B202B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات التحويل للإيداع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('اسم صاحب المحفظة: $walletOwnerName'),
                  const SizedBox(height: 8),
                  const SelectableText(
                    walletOwnerNumber,
                    style: TextStyle(
                      color: Color(0xFFFFC928),
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: copyNumber,
                      icon: const Icon(Icons.copy),
                      label: const Text('نسخ الرقم'),
                    ),
                  ),
                  const Text(
                    'حوّل المبلغ أولاً ثم أدخل رقم مرجع الحوالة.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reference,
            decoration: const InputDecoration(
              labelText: 'رقم مرجع الحوالة',
              border: OutlineInputBorder(),
            ),
          ),
        ] else ...[
          TextField(
            controller: destination,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم محفظتك لاستلام السحب',
              hintText: 'أدخل رقم Orange Money أو رقم CliQ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم حجز المبلغ عند إرسال الطلب، '
            'ويُنفذ التحويل يدوياً بعد المراجعة.',
            style: TextStyle(color: Colors.white70),
          ),
        ],

        const SizedBox(height: 14),

        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'المبلغ بالدينار الأردني',
            hintText: 'من 1 إلى 200 JOD',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : submit,
            child: Text(
              loading
                  ? 'يرجى الانتظار...'
                  : kind == 'deposit'
                      ? 'تأكيد طلب الإيداع'
                      : 'تأكيد طلب السحب',
            ),
          ),
        ),
      ],
    );
  }
}
