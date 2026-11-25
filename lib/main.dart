import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'betting.dart';
import 'admin.dart';
import 'wallet.dart';

const supabaseUrl = 'https://gisiwcwellmuargvijuu.supabase.co';
const supabasePublishableKey =
    'sb_publishable_LFnn8cN7azC0Rl7RTbI_fQ_lVw8zRlc';

const gold = Color(0xFFFFC928);
const background = Color(0xFF10131B);
const surface = Color(0xFF1B202B);

final supabase = Supabase.instance.client;

final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD-QUbpzkj0ni99fBbCjx1KwcV26vKEYJA',
      appId: '1:799380638264:android:c96d0758c241c2a50074cd',
      messagingSenderId: '799380638264',
      projectId: 'mero-bet',
      storageBucket: 'mero-bet.firebasestorage.app',
    ),
  );
}

Future<void> initializePushNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    Future<void> registerToken(String? token) async {
      final user = supabase.auth.currentUser;

      if (token == null || token.isEmpty || user == null) {
        return;
      }

      try {
        await supabase.rpc(
          'mero_register_push_token',
          params: {
            'p_token': token,
            'p_platform': 'android',
          },
        );
      } catch (error) {
        debugPrint('Push token registration failed: $error');
      }
    }

    await registerToken(await messaging.getToken());

    messaging.onTokenRefresh.listen(registerToken);

    FirebaseMessaging.onMessage.listen((message) {
      final body = message.notification?.body ??
          message.data['body']?.toString();

      if (body != null && body.isNotEmpty) {
        appMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(body)),
        );
      }
    });
  } catch (error) {
    debugPrint('Push notification setup failed: $error');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD-QUbpzkj0ni99fBbCjx1KwcV26vKEYJA',
      appId: '1:799380638264:android:c96d0758c241c2a50074cd',
      messagingSenderId: '799380638264',
      projectId: 'mero-bet',
      storageBucket: 'mero-bet.firebasestorage.app',
    ),
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const MeroBetApp());
}

class MeroBetApp extends StatelessWidget {
  const MeroBetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: appMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MERO BET',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) {
          return const MainScreen();
        }

        return const LoginPage();
      },
    );
  }
}

// تسجيل الدخول وإنشاء الحساب
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool isRegister = false;
  bool loading = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      message('أدخل البريد وكلمة مرور من 6 أحرف على الأقل');
      return;
    }

    setState(() => loading = true);

    try {
      if (isRegister) {
        final result = await supabase.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );

        if (result.session == null && mounted) {
          message('تم إنشاء الحساب. تحقق من بريدك لتأكيد التسجيل.');
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      message(e.message);
    } catch (e) {
      message('حدث خطأ أثناء الاتصال: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.sports_soccer, color: gold, size: 65),
              const SizedBox(height: 12),
              const Text(
                'MERO BET',
                style: TextStyle(
                  color: gold,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: Text(
                    loading
                        ? 'يرجى الانتظار...'
                        : isRegister
                            ? 'إنشاء الحساب'
                            : 'دخول',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => isRegister = !isRegister);
                },
                child: Text(
                  isRegister
                      ? 'لديك حساب؟ سجل الدخول'
                      : 'ليس لديك حساب؟ أنشئ حساباً',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// الشاشة الرئيسية
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int page = 0;

  late Future<bool> ownerFuture;
  late Future<double> balanceFuture;

  Timer? balanceRefreshTimer;

  @override
  void initState() {
    super.initState();

    unawaited(initializePushNotifications());

    ownerFuture = checkOwner();
    balanceFuture = getBalance();

    balanceRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted) return;

        setState(() {
          balanceFuture = getBalance();
        });
      },
    );
  }

  @override
  void dispose() {
    balanceRefreshTimer?.cancel();
    super.dispose();
  }

  Future<bool> checkOwner() async {
    final user = supabase.auth.currentUser;

    if (user == null) return false;

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return profile?['role'] == 'owner';
    } catch (_) {
      return false;
    }
  }

  Future<double> getBalance() async {
    final result = await supabase.rpc('mero_balance');

    if (result == null) return 0;
    if (result is num) return result.toDouble();

    return double.tryParse(result.toString()) ?? 0;
  }

  void openDeposit() {
    setState(() {
      page = 2;
      balanceFuture = getBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ownerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isOwner = snapshot.data == true;

        final pages = <Widget>[
          const BettingPage(),
          const CasinoPage(),
          const WalletPage(),
          const AccountPage(),
          if (isOwner) const AdminPage(),
        ];

        final destinations = <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'الرهانات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.casino),
            label: 'الكازينو',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'المحفظة',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
          if (isOwner)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings),
              label: 'الإدارة',
            ),
        ];

        if (page >= pages.length) page = 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: surface,
            leadingWidth: 145,
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 8,
                top: 6,
                bottom: 6,
              ),
              child: OutlinedButton(
                onPressed: openDeposit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: const BorderSide(color: gold),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: FutureBuilder<double>(
                  future: balanceFuture,
                  builder: (context, balanceSnapshot) {
                    final jod = balanceSnapshot.data ?? 0.0;

                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            balanceSnapshot.hasError
                                ? 'تعذر تحميل الرصيد'
                                : 'د.أ ${jod.toStringAsFixed(3)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            title: const Text(
              'MERO BET',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: IndexedStack(
            index: page,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: surface,
            selectedIndex: page,
            indicatorColor: gold.withOpacity(0.2),
            onDestinationSelected: (value) {
              setState(() {
                page = value;

                if (value == 2) {
                  balanceFuture = getBalance();
                }
              });
            },
            destinations: destinations,
          ),
        );
      },
    );
  }
}

// صفحة ألعاب OroPlay
class CasinoPage extends StatefulWidget {
  const CasinoPage({super.key});

  @override
  State<CasinoPage> createState() => _CasinoPageState();
}

class _CasinoPageState extends State<CasinoPage> {
  List<Map<String, dynamic>> vendors = [];
  List<Map<String, dynamic>> games = [];

  String? selectedVendor;
  bool loadingVendors = true;
  bool loadingGames = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadVendors();
  }

  Future<dynamic> callFunction(Map<String, dynamic> body) async {
    final result = await supabase.functions.invoke(
      'oroplay-games',
      body: body,
    );

    return result.data;
  }

  Future<void> loadVendors() async {
    setState(() {
      loadingVendors = true;
      errorMessage = null;
    });

    try {
      final data = await callFunction({'action': 'vendors'});

      if (data is! Map || data['success'] != true) {
        throw Exception('استجابة OroPlay غير ناجحة: $data');
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
          errorMessage = 'لم يتم العثور على شركات ألعاب.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingVendors = false;
        errorMessage = 'تفاصيل الخطأ في تحميل الشركات: $e';
      });
    }
  }

  Future<void> selectVendor(String vendorCode) async {
    setState(() {
      selectedVendor = vendorCode;
      loadingGames = true;
      games = [];
      errorMessage = null;
    });

    try {
      final data = await callFunction({
        'action': 'games',
        'vendorCode': vendorCode,
        'language': 'en',
      });

      if (data is! Map || data['success'] != true) {
        throw Exception('استجابة الألعاب غير ناجحة: $data');
      }

      final list = data['message'];

      if (list is! List) {
        throw Exception('قائمة الألعاب غير صحيحة: $data');
      }

      final loaded = list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((game) => game['underMaintenance'] != true)
          .toList();

      if (!mounted) return;

      setState(() {
        games = loaded;
        loadingGames = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingGames = false;
        errorMessage = 'تفاصيل الخطأ في تحميل الألعاب: $e';
      });
    }
  }

  Future<void> launchGame(Map<String, dynamic> game) async {
    final vendorCode =
        game['vendorCode']?.toString() ?? selectedVendor;
    final gameCode = game['gameCode']?.toString() ?? '';

    if (vendorCode == null || gameCode.isEmpty) {
      showMessage('بيانات اللعبة غير مكتملة');
      return;
    }

    bool dialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: gold),
      ),
    );

    try {
      final data = await callFunction({
        'action': 'launch',
        'vendorCode': vendorCode,
        'gameCode': gameCode,
        'language': 'en',
      });

      if (mounted && dialogOpen) {
        Navigator.of(context).pop();
        dialogOpen = false;
      }

      if (data is! Map || data['success'] != true) {
        throw Exception('استجابة تشغيل اللعبة غير ناجحة: $data');
      }

      final url = data['message']?.toString() ?? '';
      final uri = Uri.tryParse(url);

      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        throw Exception('رابط تشغيل اللعبة غير صالح: $url');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OroPlayGamePage(
            title: game['gameName']?.toString() ?? 'OroPlay',
            url: uri,
          ),
        ),
      );
    } catch (e) {
      if (mounted && dialogOpen) {
        Navigator.of(context).pop();
        dialogOpen = false;
      }

      showMessage('تفاصيل خطأ تشغيل اللعبة: $e');
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadVendors,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'كازينو MERO',
            style: TextStyle(
              color: gold,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ألعاب OroPlay',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),

          if (loadingVendors)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: gold),
              ),
            ),

          if (errorMessage != null)
            Card(
              color: surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SelectableText(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: loadVendors,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),

          if (!loadingVendors && vendors.isNotEmpty) ...[
            const Text(
              'شركات الألعاب',
              style: TextStyle(
                color: gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedVendor,
              isExpanded: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(),
                labelText: 'اختر شركة الألعاب',
              ),
              items: vendors.map((vendor) {
                final code = vendor['vendorCode']?.toString() ?? '';
                final name = vendor['name']?.toString() ?? code;

                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) selectVendor(value);
              },
            ),
            const SizedBox(height: 22),
            const Text(
              'الألعاب المتاحة',
              style: TextStyle(
                color: gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (loadingGames)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: gold),
              ),
            ),

          if (!loadingGames &&
              games.isEmpty &&
              vendors.isNotEmpty &&
              errorMessage == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'لا توجد ألعاب معروضة لهذه الشركة حالياً.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),

          ...games.map((game) {
            final name = game['gameName']?.toString() ?? 'لعبة';
            final imageUrl = game['thumbnail']?.toString() ?? '';

            return Card(
              color: surface,
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.casino,
                          color: gold,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.casino,
                        color: gold,
                        size: 40,
                      ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  game['provider']?.toString() ?? 'OroPlay',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.play_circle_fill,
                  color: gold,
                  size: 32,
                ),
                onTap: () => launchGame(game),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// شاشة عرض اللعبة داخل التطبيق
class OroPlayGamePage extends StatefulWidget {
  final String title;
  final Uri url;

  const OroPlayGamePage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<OroPlayGamePage> createState() => _OroPlayGamePageState();
}

class _OroPlayGamePageState extends State<OroPlayGamePage> {
  late final WebViewController controller;
  bool loading = true;
  String? webError;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                loading = true;
                webError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => loading = false);
            }
          },
          onWebResourceError: (details) {
            if (mounted && details.isForMainFrame == true) {
              setState(() {
                loading = false;
                webError = details.description;
              });
            }
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: surface,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () => controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loading)
            const Center(
              child: CircularProgressIndicator(color: gold),
            ),
          if (webError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'تعذر تحميل اللعبة: $webError',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// صفحة الحساب
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, color: gold, size: 60),
          const SizedBox(height: 12),
          Text(user?.email ?? 'المستخدم'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}