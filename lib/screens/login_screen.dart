import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'status_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  bool loading = false;
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await auth.login(
        username: username.text.trim(),
        password: password.text,
      );

      final user = Map<String, dynamic>.from(result['user'] ?? {});
      final role = user['role']?.toString();

      if (!mounted) return;

      if (role == 'admin') {
        await auth.logout();

        if (!mounted) return;

        setState(() {
          error = 'حساب الإدارة متاح من لوحة التحكم على الويب فقط';
        });

        return;
      }

      if (role != 'student') {
        await auth.logout();

        if (!mounted) return;

        setState(() {
          error = 'نوع الحساب غير مدعوم في تطبيق الموبايل';
        });

        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> whatsapp() async {
    final uri = Uri.parse(
      'https://wa.me/201501600960?text='
      '%D8%A7%D9%84%D8%B3%D9%84%D8%A7%D9%85%20'
      '%D8%B9%D9%84%D9%8A%D9%83%D9%85%20'
      '%D9%8A%D8%A7%20%D9%85%D8%B3%D8%AA%D8%B1%20'
      '%D8%A3%D8%AD%D9%85%D8%AF',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.25,
              colors: [Color(0xFF1E1B4B), Color(0xFF0B1020)],
              stops: [0, .58],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const Text('⚛', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Physics',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'منصتك لتنظيم دراسة الفيزياء، متابعة الدروس، وحل التدريبات خطوة بخطوة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), height: 1.8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Eng. Ahmed Rabie',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: whatsapp,
                        icon: const Icon(Icons.chat),
                        label: const Text('تواصل معي على واتساب'),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xE6182235),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'جاهز نكمل؟ 👋',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (error != null) ...[
                              Text(
                                error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFECACA),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: username,
                              decoration: const InputDecoration(
                                labelText: 'اسم المستخدم',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: password,
                              obscureText: obscure,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() => obscure = !obscure);
                                  },
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: loading ? null : login,
                                child: loading
                                    ? const CircularProgressIndicator()
                                    : const Text('دخول إلى المنصة'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                              icon: const Text('💳'),
                              label: const Text('إنشاء حساب ورفع إثبات الدفع'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StatusScreen(status: 'forgot'),
                                  ),
                                );
                              },
                              child: const Text('نسيت كلمة المرور؟'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
