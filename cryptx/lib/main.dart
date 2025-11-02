import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wallet/providers/ethereum_provider.dart';
import 'package:wallet/providers/swap_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/screens/home_page.dart';
import 'package:wallet/utils/localization.dart';
import 'screens/login_screen.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EthereumProvider(
              dotenv.env['RPC_URL'] ?? 'http://127.0.0.1:8545', http.Client()),
        ),
        ChangeNotifierProvider(
          create: (_) => SwapProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('en', '');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallet',
      theme: ThemeData(
        
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.deepPurple[50],
        inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.black), // Đặt màu trắng cho hint text // Màu nền cho chế độ sáng
      ),),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Color.fromRGBO(38, 38, 38, 1.0),
        inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.white), // Đặt màu trắng cho hint text// Màu nền cho chế độ tối
      ),),
      themeMode: ThemeMode.system, // Tự động thay đổi theo hệ thống
       // Tự động thay đổi theo hệ thống
      locale: _locale,
      supportedLocales: [
        Locale('en', ''), // English
        Locale('vi', ''), // Vietnamese
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginScreen(),
    );
  }
}
