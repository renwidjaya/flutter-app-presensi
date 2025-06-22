import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apprendi/constants/api_base.dart';
import 'package:apprendi/services/api_service.dart';
import 'package:apprendi/services/local_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  String? emailError;
  String? passwordError;
  String? apiError;

  Future<void> loginUser() async {
    setState(() {
      emailError = null;
      passwordError = null;
      apiError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validasi lokal
    final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (email.isEmpty || !emailValid) {
      setState(() => emailError = 'Masukkan email yang valid');
      return;
    }
    if (password.isEmpty) {
      setState(() => passwordError = 'Password tidak boleh kosong');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        ApiBase.login,
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final userData = body['data'];
        final token = body['token'];

        await LocalStorageService.saveUserData(userData, token);

        if (!mounted) return;
        context.go('/dashboard');
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          apiError = error['message'] ?? 'Login gagal, coba lagi.';
        });
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() => apiError = 'Gagal terhubung ke server');
    }

    setState(() => isLoading = false);
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Biar pas konten aja
            children: [
              const Text(
                'Login Presensi',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  errorText: emailError,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  errorText: passwordError,
                ),
              ),
              if (apiError != null) ...[
                const SizedBox(height: 12),
                Text(apiError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'LOGIN',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
