
Future<void> loadVendors() async {
  setState(() {
    loadingVendors = true;
    errorMessage = null;
  });

  try {
    final data = await callFunction({'action': 'vendors'});

    if (data is! Map || data['success'] != true) {
      throw Exception('استجابة شركات الألعاب غير ناجحة: $data');
    }

    final list = data['message'];

    if (list is! List) {
      throw Exception('قائمة الشركات غير صحيحة: $data');
    }

    final loaded = list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (!mounted) return;

    setState(() {
      vendors = loaded;
      loadingVendors = false;
    });

    if (loaded.isNotEmpty) {
      final firstCode = loaded.first['vendorCode']?.toString();

      if (firstCode != null && firstCode.isNotEmpty) {
        await selectVendor(firstCode);
      }
    } else {
      setState(() {
        errorMessage = 'لم ترجع شركة الألعاب أي نتائج.';
      });
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      loadingVendors = false;
      errorMessage = 'تفاصيل الخطأ: $e';
    });
  }
}
