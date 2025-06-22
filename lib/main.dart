import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  final isLoggedIn = token != null;

  runApp(AbsensiApp(isLoggedIn: isLoggedIn));
}

class AbsensiApp extends StatelessWidget {
  final bool isLoggedIn;
  const AbsensiApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.createRouter(isLoggedIn),
      debugShowCheckedModeBanner: false,
    );
  }
}
