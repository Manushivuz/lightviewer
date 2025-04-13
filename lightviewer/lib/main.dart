import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';  // Import login_pin.dart
import 'login_password.dart';  // Import login_password.dart
import 'home.dart';  // Import home.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Ensure binding is initialized before running the app
  final secureStorage = FlutterSecureStorage();
  String? userPin = await secureStorage.read(key: 'user_pin');  // Read the PIN from storage

  runApp(MyApp(userPin: userPin));
}

class MyApp extends StatelessWidget {
  final String? userPin;

  MyApp({required this.userPin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => (userPin?.isNotEmpty ?? false)
            ? LoginWidget()  // If PIN exists, load LoginWidget
            : LoginPasswordWidget(),  // If PIN does not exist, load LoginPasswordWidget
        '/home': (context) => MyHomePage(),
      },
    );
  }
}
