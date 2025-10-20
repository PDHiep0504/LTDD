import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class TotpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const TotpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<TotpVerificationScreen> createState() => _TotpVerificationScreenState();
}

class _TotpVerificationScreenState extends State<TotpVerificationScreen> {
  final _codeController = TextEditingController();
  String _errorMessage = '';
  bool _isDisposed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực 2 yếu tố'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.security,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nhập mã xác thực',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mở ứng dụng Google Authenticator và nhập mã 6 chữ số',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _codeController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 55,
                fieldWidth: 50,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                activeColor: Theme.of(context).colorScheme.primary,
                selectedColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.grey.shade300,
              ),
              animationDuration: const Duration(milliseconds: 300),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              onChanged: (value) {
                setState(() {
                  _errorMessage = '';
                });
              },
              onCompleted: (code) {
                Navigator.pop(context, code);
              },
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_codeController.text.length == 6) {
                  Navigator.pop(context, _codeController.text);
                } else {
                  setState(() {
                    _errorMessage = 'Vui lòng nhập đủ 6 chữ số';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Go back to login
              },
              child: const Text('Quay lại đăng nhập'),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Mẹo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Mã sẽ thay đổi mỗi 30 giây\n'
                    '• Đảm bảo giờ trên điện thoại chính xác\n'
                    '• Mở Google Authenticator để xem mã',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      try {
        _codeController.dispose();
      } catch (e) {
        // Controller already disposed, ignore
        print('⚠️ Controller already disposed: $e');
      }
    }
    super.dispose();
  }
}
