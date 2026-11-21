
import 'package:flutter/material.dart';

void main() => runApp(const MeroAI());

const gold = Color(0xFFFFC400);
const bg = Color(0xFF0B0C0F);
const panel = Color(0xFF191A1E);

class MeroAI extends StatelessWidget {
  const MeroAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MERO AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: gold),
        appBarTheme: const AppBarTheme(backgroundColor: bg),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  final saved = <String>[];

  void save(String value) {
    setState(() => saved.insert(0, value));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ChatPage(),
      VideoPage(onSave: save),
      ImagePage(onSave: save),
      HistoryPage(items: saved),
      const SettingsPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '✨ MERO AI',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
        ),
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: NavigationBar(
          backgroundColor: panel,
          selectedIndex: tab,
          indicatorColor: gold.withOpacity(.15),
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat), label: 'محادثة'),
            NavigationDestination(icon: Icon(Icons.movie), label: 'فيديو'),
            NavigationDestination(icon: Icon(Icons.image), label: 'صور'),
            NavigationDestination(icon: Icon(Icons.folder), label: 'أعمالي'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'إعدادات'),
          ],
        ),
      ),
    );
  }
}

// CHAT

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final messages = <String>[
    'أهلًا بك في MERO AI ✨\nاكتب فكرتك أو اسألني أي شيء.',
  ];

  void send() {
    final text = input.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add('👤 $text');
      input.clear();
      messages.add(
        '🤖 وصلت فكرتك!\nهذه نسخة تجريبية. '
        'لإجابات الذكاء الاصطناعي الحقيقية نحتاج ربط نموذج AI بخادم آمن.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) => Card(
              color: panel,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(messages[i]),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      filled: true,
                    ),
                    onSubmitted: (_) => send(),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                  color: gold,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// VIDEO GENERATOR

class VideoPage extends StatefulWidget {
  final ValueChanged<String> onSave;
  const VideoPage({super.key, required this.onSave});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final prompt = TextEditingController();
  String style = 'سينمائي';
  String ratio = '16:9';
  String duration = '5 ثوانٍ';

  Widget choices(List<String> options, String value,
      ValueChanged<String> onChange) {
    return Wrap(
      spacing: 8,
      children: options.map((s) {
        return ChoiceChip(
          label: Text(s),
          selected: value == s,
          selectedColor: gold.withOpacity(.25),
          onSelected: (_) => onChange(s),
        );
      }).toList(),
    );
  }

  void create() {
    if (prompt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب وصف الفيديو أولاً')),
      );
      return;
    }

    widget.onSave('فيديو: ${prompt.text.trim()}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الوصف. التوليد الحقيقي يحتاج ربط خدمة AI.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Heading('🎬 إنشاء فيديو بالذكاء الاصطناعي'),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Icon(Icons.video_camera_back, size: 65, color: gold),
          ),
        ),
        const Heading('وصف الفيديو'),
        TextField(
          controller: prompt,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'صف الفيديو الذي تريد إنشاءه بالتفصيل...',
          ),
        ),
        const Heading('النمط'),
        choices(['سينمائي', 'واقعي', 'أنمي', 'كرتوني', 'إعلاني', 'خيال'],
            style, (v) => setState(() => style = v)),
        const Heading('الأبعاد'),
        choices(['16:9', '9:16', '1:1'], ratio,
            (v) => setState(() => ratio = v)),
        const Heading('المدة'),
        choices(['5 ثوانٍ', '10 ثوانٍ', '15 ثوانٍ'], duration,
            (v) => setState(() => duration = v)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: create,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('إنشاء الفيديو'),
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'التوليد الفعلي يحتاج ربط مزود فيديو.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }
}

// IMAGE GENERATOR

class ImagePage extends StatefulWidget {
  final ValueChanged<String> onSave;
  const ImagePage({super.key, required this.onSave});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  final prompt = TextEditingController();
  String style = 'واقعي';

  void generate() {
    if (prompt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب وصف الصورة')),
      );
      return;
    }

    widget.onSave('صورة: ${prompt.text.trim()}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الوصف محليًا.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Heading('🎨 صانع الصور AI'),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 65, color: gold),
          ),
        ),
        const Heading('وصف الصورة'),
        TextField(
          controller: prompt,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'صف الصورة التي تريد إنشائها...',
          ),
        ),
        const Heading('الأسلوب'),
        Wrap(
          spacing: 8,
          children: ['واقعي', 'أنمي', 'رسم', '3D', 'فن رقمي']
              .map((s) => ChoiceChip(
                    label: Text(s),
                    selected: style == s,
                    selectedColor: gold.withOpacity(.2),
                    onSelected: (_) => setState(() => style = s),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: generate,
          icon: const Icon(Icons.palette),
          label: const Text('إنشاء صورة'),
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(15),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'إنشاء الصور الفعلي يحتاج ربط خدمة.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }
}

// HISTORY

class HistoryPage extends StatelessWidget {
  final List<String> items;
  const HistoryPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('لا توجد أعمال محفوظة حتى الآن'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Heading('📁 أعمالي'),
        ...items.map((s) => Card(
              color: panel,
              child: ListTile(
                leading: const Icon(Icons.description, color: gold),
                title: Text(s),
              ),
            )),
      ],
    );
  }
}

// SETTINGS

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Heading('⚙️ الإعدادات'),
        const Card(
          color: panel,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: gold,
              child: Icon(Icons.person, color: Colors.black),
            ),
            title: Text('MERO AI'),
            subtitle: Text('مساعدك الإبداعي'),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.language, color: gold),
          title: Text('اللغة'),
          subtitle: Text('العربية'),
        ),
        const ListTile(
          leading: Icon(Icons.palette, color: gold),
          title: Text('المظهر'),
          subtitle: Text('أسود وذهبي'),
        ),
        const ListTile(
          leading: Icon(Icons.info, color: gold),
          title: Text('حول التطبيق'),
          subtitle: Text('MERO AI - النسخة التجريبية'),
        ),
        const ListTile(
          leading: Icon(Icons.shield, color: gold),
          title: Text('الخصوصية'),
          subtitle: Text('لا تشارك بيانات حساسة'),
        ),
        const Text(
          'خدمات الذكاء الاصطناعي تحتاج إعداد خادم وربط API.',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}

// SECTION TITLE

class Heading extends StatelessWidget {
  final String text;
  const Heading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          color: gold,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
