import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'controllers/quest_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/game_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/title_screen.dart';
import 'services/audio_service.dart';
import 'services/billing_service.dart';
import 'services/custom_card_service.dart';
import 'services/entitlement_service.dart';
import 'services/save_service.dart';

class RepBattleApp extends StatefulWidget {
  const RepBattleApp({super.key});

  @override
  State<RepBattleApp> createState() => _RepBattleAppState();
}

class _RepBattleAppState extends State<RepBattleApp> with WidgetsBindingObserver {
  late final SaveService _saveService;
  late final AudioService _audioService;
  late final EntitlementService _entitlementService;
  late final BillingService _billingService;
  late final CustomCardService _customCardService;
  late final GameController _gameController;
  late final QuestController _questController;
  bool _ready = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _saveService = SaveService();
    _audioService = AudioService();
    _entitlementService = EntitlementService(_saveService);
    _billingService = BillingService(_entitlementService);
    _customCardService = CustomCardService();
    _gameController = GameController(
      saveService: _saveService,
      audio: _audioService,
      entitlement: _entitlementService,
      customCards: _customCardService,
    );
    _questController = QuestController(
      saveService: _saveService,
      audio: _audioService,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _audioService.init();
    await _customCardService.load();
    await _entitlementService.load();
    await _billingService.init();
    await _gameController.initialize();
    await _questController.initialize();
    await _gameController.tryResumeMatch();
    await _audioService.startAppMusic(proTitle: _entitlementService.isPro);
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _gameController.onAppLifecyclePaused();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioService.dispose();
    _billingService.dispose();
    _gameController.dispose();
    _questController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider.value(value: _saveService),
        Provider.value(value: _audioService),
        ChangeNotifierProvider.value(value: _entitlementService),
        ChangeNotifierProvider.value(value: _billingService),
        ChangeNotifierProvider.value(value: _customCardService),
        ChangeNotifierProvider.value(value: _gameController),
        ChangeNotifierProvider.value(value: _questController),
      ],
      child: MaterialApp(
        title: 'Rep Battle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        builder: (context, child) {
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              context.read<AudioService>().resumeMusicIfBlocked();
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
        routes: {
          '/': (_) => _showSplash
              ? SplashScreen(
                  onDone: () => setState(() => _showSplash = false),
                )
              : const TitleScreen(),
          '/game': (_) => const GameScreen(),
        },
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/game') {
            return MaterialPageRoute(builder: (_) => const GameScreen());
          }
          return null;
        },
      ),
    );
  }
}
