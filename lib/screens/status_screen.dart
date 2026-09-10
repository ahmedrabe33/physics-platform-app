import 'package:flutter/material.dart';

class StatusScreen extends StatelessWidget {
  final String status;
  final VoidCallback? onBack;

  const StatusScreen({super.key, required this.status, this.onBack});

  @override
  Widget build(BuildContext context) {
    String icon = '⏳';
    String title = 'طلبك قيد المراجعة';
    String message =
        'تم استلام طلبك وإثبات الدفع بنجاح. سيتم التفعيل بعد مراجعة الدعم.';

    if (status == 'rejected') {
      icon = '❌';
      title = 'تعذر تفعيل الحساب';
      message = 'تم رفض طلب التسجيل. تواصل مع المدرس للمراجعة.';
    } else if (status == 'expired') {
      icon = '🔒';
      title = 'انتهت مدة اشتراكك';
      message = 'تواصل مع المدرس لتجديد الاشتراك.';
    } else if (status == 'forgot') {
      icon = '🔐';
      title = 'نسيت كلمة المرور؟';
      message = 'تواصل مع المدرس لإعادة تعيين كلمة المرور.';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [Color(0xFF1E1B4B), Color(0xFF0B1020)],
              stops: [0, .58],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 620),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xE6182235),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Column(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 52)),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              onBack ?? () => Navigator.of(context).pop(),
                          child: const Text('العودة'),
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
