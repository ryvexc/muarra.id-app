import 'package:flutter/material.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:muarra_app_v1/core/constants/app_safe_area.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          Container(color: Colors.white),

          AppSafeArea(
            child: Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  spacing: 16,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Muarra",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Login to your account",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Please login to using Muarra POS",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    SizedBox(height: 20),
                    Column(
                      spacing: 30,
                      children: [
                        TextField(
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                          ),
                        ),
                        TextField(
                          obscureText: true,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/home');
                            },
                            child: const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
