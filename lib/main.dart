import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const green = Color(0xFF00F58A);
const dark = Color(0xFF080D0A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SnakApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TrainingOverlay(),
  ));
}

class SnakApp extends StatelessWidget {
  const SnakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNAK TRAINING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: dark,
        colorScheme: const ColorScheme.dark(primary: green),
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
  String status = 'النافذة العائمة متوقفة';

  Future<void> startOverlay() async {
    try {
      var allowed =
          await FlutterOverlayWindow.isPermissionGranted();

      if (!allowed) {
        allowed =
            await FlutterOverlayWindow.requestPermission() ?? false;
      }

      if (!allowed) {
        setState(() {
          status = 'لم يتم منح إذن الظهور فوق التطبيقات';
        });
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        height: 280,
        width: 300,
        enableDrag: true,
        overlayTitle: 'SNAK TRAINING',
        overlayContent: 'أدوات تدريب يدوية',
      );

      setState(() {
        status = 'تم طلب تشغيل النافذة العائمة';
      });
    } catch (e) {
      setState(() {
        status = 'تعذر تشغيل النافذة. تحقق من إعداد Android.';
      });
    }
  }

  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    setState(() {
      status = 'تم إيقاف النافذة العائمة';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SNAK TRAINING',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101A13),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.sports_esports,
            color: green,
            size: 66,
          ),
          const SizedBox(height: 12),
          const Text(
            'مساعد تدريب 8 Ball Pool',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أدوات يدوية لحساب زاوية وقوة الضربة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: startOverlay,
            icon: const Icon(Icons.open_in_new),
            label: const Text('تشغيل النافذة العائمة'),
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: stopOverlay,
            icon: const Icon(Icons.close),
            label: const Text('إيقاف النافذة العائمة'),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF142019),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: green),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingOverlay extends StatefulWidget {
  const TrainingOverlay({super.key});

  @override
  State<TrainingOverlay> createState() => _TrainingOverlayState();
}

class _TrainingOverlayState extends State<TrainingOverlay> {
  double angle = 45;
  double power = 65;
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final radians = angle * math.pi / 180;
    final x = math.cos(radians) * power;
    final y = math.sin(radians) * power;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xF20A120D),
            border: Border.all(color: green, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: green, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'SNAK • تدريب',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => expanded = !expanded);
                    },
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      FlutterOverlayWindow.closeOverlay();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              if (expanded) ...[
                Text(
                  'زاوية: ${angle.round()}°',
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: angle,
                  min: 0,
                  max: 360,
                  onChanged: (v) => setState(() => angle = v),
                ),
                Text(
                  'القوة: ${power.round()}%',
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: power,
                  min: 1,
                  max: 100,
                  onChanged: (v) => setState(() => power = v),
                ),
                Text(
                  'اتجاه تدريبي: X ${x.toStringAsFixed(1)} • Y ${y.toStringAsFixed(1)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: green, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}