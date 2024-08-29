import 'package:coalapp/auth/dashboard.dart';
import 'package:coalapp/auth/login.dart';
import 'package:coalapp/auth/register_page.dart';
import 'package:coalapp/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Role Based Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login', // Set login as the initial route
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/employee', page: () => EmployeeDashboard()),
        GetPage(name: '/head', page: () => HeadDashboard()),
        GetPage(name: '/supervisor', page: () => SupervisorDashboard()),
      ],
    );
  }
}
