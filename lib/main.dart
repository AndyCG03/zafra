import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/start_screen.dart';
import 'services/audio/game_audio.dart';
import 'services/persistence/progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ CONFIGURACIÓN FULLSCREEN - OCULTAR BARRAS
  // Oculta la barra de estado y la barra de navegación
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky, // Las barras se ocultan, aparecen al deslizar
    overlays: [], // Sin overlays
  );

  // ✅ HACER LA BARRA DE NOTIFICACIONES TRANSPARENTE
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  final progress = ProgressService();
  await progress.init();
  GameAudio.instance.ambientVolume = progress.ambientVolume;
  GameAudio.instance.startAmbient();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: ZafraApp()));
}

class ZafraApp extends StatefulWidget {
  const ZafraApp({super.key});
  @override
  State<ZafraApp> createState() => _ZafraAppState();
}

class _ZafraAppState extends State<ZafraApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GameAudio.instance.resumeAmbient();
      // ✅ Reaplicar fullscreen al volver a la app
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    } else {
      GameAudio.instance.pauseAmbient();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Zafra',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const StartScreen(),
  );
}