  // ---------------- طلبات المحفظة ----------------

  Future<void> viewProof(String path) async {
    try {
      final signedUrl = await db.storage
          .from('wallet-proofs')
          .createSignedUrl(path, 600);

      if (!mounted) return;
      final isPdf = path.toLowerCase().endsWith('.pdf');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('إيصال التحويل'),
          content: SizedBox(
            width: double.maxFinite,
            child: isPdf
                ? SelectableText(
                    'إيصال PDF. انسخ الرابط وافتحه:\n$signedUrl',
                  )
                : InteractiveViewer(
                    child: Image.network(
                      signedUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stack) =>
                          const Text('تعذر عرض صورة الإيصال'),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      message('تعذر فتح الإيصال: $e');
    }
  }

  Future<void> reviewRequest(String id, bool approve) async {
    try {
      await db.rpc(
        'mero_review_wallet_request',
        params: {
          'p_request_id': id,
          'p_approve': approve,
          'p_note': approve
              ? 'تمت مراجعة الإيصال والموافقة'
              : 'تم رفض الطلب بعد المراجعة',
        },
      );

      message(
        approve
            ? 'تمت الموافقة على الطلب وإضافة الرصيد'
            : 'تم رفض الطلب',
      );
      refresh();
    } catch (e) {
      message('تعذر معالجة الطلب: $e');
    }
  }

  Widget requestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db
          .from('wallet_requests')
          .select(
            '*, profiles!wallet_requests_user_id_fkey(display_name)',
          )
          .eq('status', 'pending')
          .order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('خطأ في الطلبات: ${snapshot.error}'),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Text('لا توجد طلبات معلقة'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final id = request['id'].toString();

            final fils =
                (request['amount_fils'] as num?)?.toDouble() ?? 0;
            final amount = fils / 1000;

            final deposit = request['kind'] == 'deposit';
            final profile = request['profiles'];
            final playerName =
                profile is Map ? profile['display_name'] : null;

            final method =
                (request['method'] ?? '-').toString();

            final senderDetails =
                (request['payment_reference'] ?? '').toString();

            final destination =
                (request['destination'] ?? '').toString();

            final proofPath =
                (request['proof_path'] ?? '').toString();

            return Card(
              color: adminSurface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      deposit ? 'طلب إيداع' : 'طلب سحب',
                      style: const TextStyle(
                        color: adminGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'اللاعب: ${playerName ?? request['user_id']}',
                    ),

                    Text(
                      'المبلغ: ${amount.toStringAsFixed(3)} د.أ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text('طريقة التحويل: $method'),

                    if (senderDetails.isNotEmpty)
                      Text('بيانات المرسل: $senderDetails'),

                    if (destination.isNotEmpty)
                      Text('وجهة السحب: $destination'),

                    if (proofPath.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => viewProof(proofPath),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text(
                          'عرض إيصال التحويل',
                        ),
                      ),
                    ] else if (deposit) ...[
                      const Text(
                        'لم يرفق اللاعب إيصالاً',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],

                    Text('التاريخ: ${request['created_at']}'),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                reviewRequest(id, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('موافقة'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                reviewRequest(id, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('رفض'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
