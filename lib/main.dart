import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dollar_bills/core/local/data_persistence_service.dart';
import 'package:dollar_bills/pages/home/home_page.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:trinity/trinity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);
  await DataPersistenceService.init();
  runApp(TrinityScope(child: const DollarBillsApp()));
}

class DollarBillsApp extends StatelessWidget {
  const DollarBillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dollar bills',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: HexColor.mintPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: HexColor.mintPrimary,
          primary: HexColor.mintPrimary,
          surface: HexColor.backgroundLight,
        ),
        scaffoldBackgroundColor: HexColor.backgroundLight,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const HomePage(),
    );
  }
}
