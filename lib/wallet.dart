
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
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
  bool pickingFile = false;

  Uint8List? proofBytes;
  String? proofName;
  String? proofExtension;
  String? proofMimeType;

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

  Future<void> chooseProof() async {
    if (pickingFile || loading) return;

    setState(() => pickingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (file.size > 10 * 1024 * 1024) {
        notify('حجم الإيصال يجب ألا يتجاوز 10 ميغابايت');
        return;
      }

      if (file.bytes == null || file.bytes!.isEmpty) {
        notify('تعذر قراءة الملف، حاول اختيار الملف مرة أخرى');
        return;
      }

      final extension = file.extension?.toLowerCase() ?? '';

      const allowed = [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'pdf',
      ];

      if (!allowed.contains(extension)) {
        notify('نوع الملف غير مدعوم');
        return;
      }

      String mime;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mime = 'image/jpeg';
          break;
        case 'png':
          mime = 'image/png';
          break;
        case 'webp':
          mime = 'image/webp';
          break;
        case 'pdf':
          mime = 'application/pdf';
          break;
        default:
          mime = 'application/octet-stream';
      }

      if (!mounted) return;

      setState(() {
        proofBytes = file.bytes;
        proofName = file.name;
        proofExtension = extension;
        proofMimeType = mime;
      });

      notify('تم اختيار الإيصال بنجاح');
    } catch (e) {
      notify('تعذر اختيار الملف: $e');
    } finally {
      if (mounted) {
        setState(() => pickingFile = false);
      }
    }
  }

  void removeProof() {
    setState(() {
      proofBytes = null;
      proofName = null;
      proofExtension = null;
      proofMimeType = null;
    });
  }

  Future<String> uploadProof() async {
    final user = walletDb.auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (proofBytes == null ||
        proofExtension == null ||
        proofMimeType == null) {
      throw Exception('يرجى إرفاق إيصال التحويل');
    }

    final filePath =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$proofExtension';

    await walletDb.storage
        .from('wallet-proofs')
        .uploadBinary(
          filePath,
          proofBytes!,
          fileOptions: FileOptions(
            contentType: proofMimeType!,
            upsert: false,
          ),
        );

    return filePath;
  }

  Future<void> submit() async {
    final rawAmount = amount.text.trim();
    final value = double.tryParse(rawAmount);

    if (value == null ||
        !value.isFinite ||
        value < 1 ||
        value > 200 ||
        !RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(rawAmount)) {
      notify('أدخل مبلغاً من 1 إلى 200 دينار وبحد أقصى 3 منازل عشرية');
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

      if (proofBytes == null) {
        notify('يجب إرفاق صورة أو PDF لإيصال التحويل');
        return;
      }
    } else {
      if (destination.text.trim().isEmpty) {
        notify('أدخل رقم محفظتك لاستلام السحب');
        return;
      }
    }

    setState(() => loading = true);

    String? uploadedPath;

    try {
      final fils = (value * 1000).round();

      if (kind == 'deposit') {
        uploadedPath = await uploadProof();
      }

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
          'p_proof_path': uploadedPath,
        },
      );

      amount.clear();
      senderName.clear();
      senderPhone.clear();
      destination.clear();

      removeProof();

      notify(
        kind == 'deposit'
            ? 'تم إرسال طلب الإيداع والإيصال بنجاح. بانتظار مراجعة الإدارة.'
            : 'تم إرسال طلب السحب بنجاح. بانتظار مراجعة الإدارة.',
      );
    } on PostgrestException catch (e) {
      if (uploadedPath != null) {
        try {
          await walletDb.storage
              .from('wallet-proofs')
              .remove([uploadedPath]);
        } catch (_) {}
      }

      notify('تعذر إرسال الطلب: ${e.message}');
    } catch (e) {
      if (uploadedPath != null) {
        try {
          await walletDb.storage
              .from('wallet-proofs')
              .remove([uploadedPath]);
        } catch (_) {}
      }

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
    destination.dispose();
    senderName.dispose();
    senderPhone.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(
    String label, {
    String? hint,
  }) {
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 14),
            const Text('اسم صاحب المحفظة'),
            const SizedBox(height: 5),
            const Text(
              walletOwnerName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              'حوّل المبلغ إلى المحفظة أعلاه، ثم أدخل بيانات المرسل وأرفق إيصال التحويل.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget proofPicker() {
    return Card(
      color: const Color(0xFF1B202B),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إيصال التحويل',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (proofBytes == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: pickingFile || loading
                      ? null
                      : chooseProof,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    pickingFile
                        ? 'جارٍ اختيار الملف...'
                        : 'اختر صورة أو PDF للإيصال',
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFC928),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    if (proofExtension != 'pdf')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          proofBytes!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.image,
                              size: 65,
                            );
                          },
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Icon(
                          Icons.picture_as_pdf,
                          size: 60,
                          color: Colors.redAccent,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      proofName ?? 'الإيصال',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: loading
                                ? null
                                : chooseProof,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تغيير'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: loading
                                ? null
                                : removeProof,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('حذف'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'الصيغ المدعومة: JPG و PNG و WEBP و PDF. الحد الأقصى 10 ميغابايت.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
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
            setState(() {
              kind = value.first;
              removeProof();
            });
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
            if (value != null) {
              setState(() => method = value);
            }
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
          const SizedBox(height: 14),
          proofPicker(),
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
            onPressed: loading || pickingFile ? null : submit,
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
