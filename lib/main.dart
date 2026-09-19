import 'package:flutter/material.dart';
import 'screens/grade_selection_screen.dart';
import 'services/admob_service.dart';
import 'services/hanzi_data_service.dart';
import 'services/reward_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi penyimpanan reward aman anti-tamper
  await RewardService().initialize();

  // Inisialisasi Google Mobile Ads SDK dengan setelan ramah anak (COPPA)
  await AdMobService().initialize();

  // Inisialisasi data stroke order kaligrafi Hanzi offline
  await HanziDataService().init();

  runApp(const NiHaoKidsApp());
}

class NiHaoKidsApp extends StatelessWidget {
  const NiHaoKidsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NiHao Kids',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const GradeSelectionScreen(),
    );
  }
}
