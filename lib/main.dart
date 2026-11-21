
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vdddnvamjsikwmuwghuo.supabase.co',
    anonKey: 'sb_publishable_2pRqaOQ6w0J_tA6zKyGAgQ_fR0eNOjc',
  );

  try {
    await Supabase.instance.client.auth.signInAnonymously();
  } catch (_) {}

  runApp(const MeroAI());
}

const gold = Color(0xFFFFC400);
const bg = Color(0xFF101113);
const panel = Color(0xFF222326);

class MeroAI extends StatelessWidget {
  const MeroAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MERO AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: gold),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final promptController = TextEditingController();
  bool loading = false;
  String result = '';
  String duration = '5';
  String ratio = '16:9';

  Future<void> generateVideo() async {
    final prompt = promptController.text.trim();

    if (prompt.isEmpty) {
      setState(() => result = 'اكتب وصف الفيديو أولاً');
      return;
    }

    setState(() {
      loading = true;
      result = 'جاري إرسال طلب الفيديو... انتظر';
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'mero-video',
        body: {
          'prompt': prompt,
          'duration': duration,
          'aspect_ratio': ratio,
        },
      );

      final data = response.data;

      setState(() {
        result = 'تم إرسال الطلب.\n\nالنتيجة:\n$data';
      });
    } catch (e) {
      setState(() {
        result = 'حدث خطأ أثناء إنشاء الفيديو:\n$e';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Widget sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          color: gold,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget optionButton(
    String value,
    String current,
    Function(String) onSelect,
  ) {
    final selected = value == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? gold : panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        centerTitle: true,
        title: const Text(
          'MERO AI',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withOpacity(0.35)),
            ),
            child: const Column(
              children: [
                Icon(Icons.movie_creation_outlined, color: gold, size: 48),
                SizedBox(height: 10),
                Text(
                  'مولّد الفيديو بالذكاء الاصطناعي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'اكتب فكرتك وحوّلها إلى فيديو',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle('وصف الفيديو'),
          const SizedBox(height: 10),
          TextField(
            controller: promptController,
            minLines: 4,
            maxLines: 7,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'صف الفيديو الذي تريد إنشاءه بالتفصيل...',
              filled: true,
              fillColor: panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          sectionTitle('مدة الفيديو'),
          Row(
            children: [
              optionButton('5', duration, (v) => setState(() => duration = v)),
              optionButton('10', duration, (v) => setState(() => duration = v)),
              optionButton('15', duration, (v) => setState(() => duration = v)),
            ],
          ),
          const SizedBox(height: 16),
          sectionTitle('أبعاد الفيديو'),
          Row(
            children: [
              optionButton('16:9', ratio, (v) => setState(() => ratio = v)),
              optionButton('9:16', ratio, (v) => setState(() => ratio = v)),
              optionButton('1:1', ratio, (v) => setState(() => ratio = v)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : generateVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'إنشاء الفيديو',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SelectableText(
                result,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 30),
          sectionTitle('مساعد MERO'),
          const SizedBox(height: 10),
          const Text(
            'واجهة المساعد جاهزة لإضافة ربط نموذج الذكاء الاصطناعي للمحادثة.',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
