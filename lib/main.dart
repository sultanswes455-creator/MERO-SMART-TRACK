
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'betting.dart';

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
              const Icon(
                Icons.sports_soccer,
                color: gold,
                size: 65,
              ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                  ),
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const BettingPage(),
      const WalletPage(),
      const AccountPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surface,
        title: const Text(
          'MERO BET',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          setState(() => page = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'الرهانات',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'المحفظة',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  Future<dynamic> getBalance() async {
    return await supabase.rpc('mero_balance');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<dynamic>(
        future: getBalance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text('تعذر جلب الرصيد: ${snapshot.error}'),
            );
          }

          final balance = snapshot.data ?? 0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: gold,
                size: 55,
              ),
              const SizedBox(height: 15),
              const Text('رصيد الحساب'),
              const SizedBox(height: 10),
              Text(
                '$balance JOD',
                style: const TextStyle(
                  color: gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'طلبات الإيداع والسحب ستُضاف في المرحلة التالية.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
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
          const Icon(
            Icons.person,
            color: gold,
            size: 60,
          ),
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
