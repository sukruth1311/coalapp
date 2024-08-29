import 'package:coalapp/auth/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterPage extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxString selectedRole = 'Employee'.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email')),
            TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true),
            Obx(() => DropdownButton<String>(
                  value: selectedRole.value,
                  onChanged: (value) => selectedRole.value = value!,
                  items: ['Employee', 'Head', 'Supervisor'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                )),
            ElevatedButton(
              onPressed: () {
                authController.register(emailController.text,
                    passwordController.text, selectedRole.value);
              },
              child: Text('Register'),
            ),
            TextButton(
              onPressed: () {
                Get.toNamed('/login'); // Navigate back to login page
              },
              child: Text('Already have an account? Login here'),
            ),
          ],
        ),
      ),
    );
  }
}
