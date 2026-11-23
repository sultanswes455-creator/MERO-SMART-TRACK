
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
  final destination = TextEditingController();
  final senderName = TextEditingController();
  final senderPhone = TextEditingController();

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
    if (!mounted) return;
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

    if (value == null ||
        value < 1 ||
        value > 200 ||
        (value * 100).round() != value * 100) {
      notify('أدخل مبلغاً من 1 إلى 200 دينار وبحد أقصى منزلتين عشريتين');
      return;
    }

    if (kind == 'deposit') {
      if (senderName.text.trim().isEmpty) {
        notify('أدخل اسم صاحب الحوالة');
        return;
      }
      if (senderPhone.text.trim().isEmpty) {
        notify('أدخل رقم الهاتف الذي أُرسلت منه الحوالة');
        return;
      }
    } else if (destination.text.trim().isEmpty) {
      notify('أدخل رقم محفظتك لاستلام السحب');
      return;
    }

    setState(() => loading = true);

    try {
      final fils = (value * 1000).round();

      final senderDetails = kind == 'deposit'
          ? 'اسم المرسل: ${senderName.text.trim()} | رقم المرسل: ${senderPhone.text.trim()}'
          : '';

      await walletDb.rpc(
        'mero_create_wallet_request',
        params: {
          'p_kind': kind,
          'p_amount_fils': fils,
          'p_method': method,
          'p_payment_reference': senderDetails,
          'p_destination': kind == 'withdrawal'
              ? destination.text.trim()
              : '',
          'p_proof_path': null,
        },
      );

      amount.clear();
      senderName.clear();
      senderPhone.clear();
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
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    destination.dispose();
    senderName.dispose();
    senderPhone.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    );
  }

  Widget limitsCard() {
    return Card(
      color: const Color(0xFF1B202B),
      child: Padding(
        padding: const EdgeInsets.all(15),
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
                Text('1 JOD', style: TextStyle(
                  color: Color(0xFFFFC928),
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الحد الأقصى'),
                Text('200 JOD', style: TextStyle(
                  color: Color(0xFFFFC928),
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget depositWalletDetails() {
    return Card(
      color: const Color(0xFF1B202B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات محفظة الإيداع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 14),
            const Text('اسم صاحب المحفظة'),
            const SizedBox(height: 5),
            const Text(
              walletOwnerName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text('رقم المحفظة'),
            const SizedBox(height: 5),
            Row(
              children: [
                const Expanded(
                  child: SelectableText(
                    walletOwnerNumber,
                    style: TextStyle(
                      color: Color(0xFFFFC928),
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: copyNumber,
                  tooltip: 'نسخ الرقم',
                  icon: const Icon(
                    Icons.copy,
                    color: Color(0xFFFFC928),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'حوّل المبلغ إلى المحفظة أعلاه، ثم أدخل بيانات الشخص الذي أرسل الحوالة.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
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
            setState(() => kind = value.first);
          },
        ),
        const SizedBox(height: 18),
        limitsCard(),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          value: method,
          decoration: fieldDecoration('طريقة التحويل'),
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
            if (value != null) setState(() => method = value);
          },
        ),
        const SizedBox(height: 16),
        if (kind == 'deposit') ...[
          depositWalletDetails(),
          const SizedBox(height: 14),
          TextField(
            controller: senderName,
            decoration: fieldDecoration(
              'اسم الشخص الذي أرسل الحوالة',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: senderPhone,
            keyboardType: TextInputType.phone,
            decoration: fieldDecoration(
              'رقم الهاتف الذي أُرسلت منه الحوالة',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'تم حذف خانة الرقم المرجعي للحوالة.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'رفع صورة الإيصال يحتاج إعداد Storage في Supabase.',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
            ),
          ),
        ] else ...[
          TextField(
            controller: destination,
            keyboardType: TextInputType.phone,
            decoration: fieldDecoration(
              'رقم محفظتك لاستلام السحب',
              hint: 'رقم Orange Money أو CliQ',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم حجز المبلغ عند إرسال الطلب، ويُنفذ التحويل يدوياً بعد المراجعة.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: fieldDecoration(
            'المبلغ بالدينار الأردني',
            hint: 'من 1 إلى 200 JOD',
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
                      ? 'تأكيد الإيداع'
                      : 'تأكيد طلب السحب',
            ),
          ),
        ),
      ],
    );
  }
}
