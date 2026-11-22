
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'betting.dart';
import 'admin.dart';
import 'wallet.dart';
import 'chicken_road.dart';
import 'kamikaze.dart';

const supabaseUrl = 'https://gisiwcwellmuargvijuu.supabase.co';
const supabasePublishableKey =
    'sb_publishable_LFnn8cN7azC0Rl7RTbI_fQ_lVw8zRlc';

const gold = Color(0xFFFFC928);
const background = Color(0xFF10131B);
const surface = Color(0xFF1B202B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const MeroBetApp());
}

final supabase = Supabase.instance.client;

class MeroBetApp extends StatelessWidget {
  const MeroBetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      if (mounted) setState(() => loading = false);
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
                onPressed: () => setState(() => isRegister = !isRegister),
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int page = 0;
  late Future<bool> ownerFuture;
  late Future<int> balanceFuture;

  @override
  void initState() {
    super.initState();
    ownerFuture = checkOwner();
    balanceFuture = getBalance();
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

  // الرصيد مخزن بالدينار الأردني مباشرة.
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
                          const Icon(
                            Icons.add_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'د.أ ${jod.toStringAsFixed(3)}',
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

class CasinoPage extends StatelessWidget {
  const CasinoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        const SizedBox(height: 8),
        const Text(
          'اختر اللعبة التي تريد لعبها',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Card(
          color: surface,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: gold,
              child: Icon(Icons.route, color: Colors.black),
            ),
            title: const Text(
              'Chicken Road',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: const Text('20 خطوة • مخاطرة متوسطة'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChickenRoadPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: surface,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.flight, color: Colors.white),
            ),
            title: const Text(
              'KAMIKAZE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: const Text(
              '12 صفاً • 5 مربعات • اسحب في أي وقت',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KamikazePage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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
