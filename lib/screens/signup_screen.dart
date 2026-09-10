import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'status_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  final auth = AuthService();
  final api = ApiService();

  String grade = 'second';
  String? proofPath;
  String? proofName;
  String? error;
  bool loading = false;

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> pickProof() async {
    final file = await FilePicker.pickFile(type: FileType.image);

    if (file == null) return;

    if (file.path == null) {
      setState(() {
        error = 'تعذر قراءة مسار الصورة.';
      });
      return;
    }

    setState(() {
      proofPath = file.path;
      proofName = file.name;
    });
  }

  Future<void> submit() async {
    if (username.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        proofPath == null) {
      setState(() => error = 'أكمل البيانات واختر صورة إثبات الدفع.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final registration = await auth.register(
        username: username.text.trim(),
        email: email.text.trim(),
        password: password.text,
        grade: grade,
      );

      final user = Map<String, dynamic>.from(registration['user'] ?? {});

      final id = user['id'] ?? user['userId'];
      if (id == null) throw Exception('No user id returned');

      await api.createStudent(
        userId: id.toString(),
        username: username.text.trim(),
        email: email.text.trim(),
        grade: grade,
        paymentProofPath: proofPath!,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const StatusScreen(status: 'pending'),
        ),
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

  InputDecoration field(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xD9111827),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(title: const Text('إنشاء حساب')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xE6182235),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '⚛ إنشاء حساب جديد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  if (error != null) ...[
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFECACA)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: username,
                    decoration: field('اسم المستخدم'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: field('البريد الإلكتروني'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: field('كلمة المرور'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: grade,
                    decoration: field('الصف الدراسي'),
                    items: const [
                      DropdownMenuItem(
                        value: 'second',
                        child: Text('الصف الثاني الثانوي'),
                      ),
                      DropdownMenuItem(
                        value: 'third',
                        child: Text('الصف الثالث الثانوي'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => grade = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0x1716A34A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Text('رقم التحويل'),
                        SizedBox(height: 8),
                        Text(
                          '📱 01501600960',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'بعد التحويل ارفع Screenshot واضح لإثبات الدفع.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: pickProof,
                    icon: const Icon(Icons.attach_file),
                    label: Text(proofName ?? 'اختيار صورة إثبات الدفع'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('إرسال طلب التسجيل'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
