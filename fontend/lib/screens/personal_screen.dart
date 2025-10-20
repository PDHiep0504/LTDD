import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({Key? key}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _savedPhoneNumber = '0123456789'; // Số điện thoại mặc định

  @override
  void initState() {
    super.initState();
    _phoneController.text = _savedPhoneNumber;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorDialog(
          'Không thể gọi điện',
          'Thiết bị không hỗ trợ gọi điện hoặc không có ứng dụng điện thoại.',
        );
      }
    } catch (e) {
      _showErrorDialog('Lỗi', 'Không thể thực hiện cuộc gọi: $e');
    }
  }

  Future<void> _openYouTubeApp() async {
    // Thử mở YouTube app trước
    final Uri youtubeAppUri = Uri.parse('youtube://');
    final Uri youtubeWebUri = Uri.parse('https://www.youtube.com');

    try {
      if (await canLaunchUrl(youtubeAppUri)) {
        await launchUrl(youtubeAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(youtubeWebUri)) {
        await launchUrl(youtubeWebUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog(
          'Không thể mở YouTube',
          'Thiết bị không có ứng dụng YouTube hoặc không thể truy cập web.',
        );
      }
    } catch (e) {
      _showErrorDialog('Lỗi', 'Không thể mở YouTube: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _savePhoneNumber() {
    setState(() {
      _savedPhoneNumber = _phoneController.text;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu số điện thoại')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lê Đức Thịnh',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sinh viên HUTECH',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Phone Number Setting
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Cài đặt số điện thoại',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Nhập số điện thoại',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _savePhoneNumber,
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu số điện thoại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Call Phone Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(_savedPhoneNumber),
                        icon: const Icon(Icons.call),
                        label: Text('Gọi điện đến $_savedPhoneNumber'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Open YouTube Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openYouTubeApp,
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Mở ứng dụng YouTube'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin khác',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('Email'),
                      subtitle: const Text('thinh.le@student.hutech.edu.vn'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.school, color: Colors.blue),
                      title: const Text('Trường'),
                      subtitle: const Text('Đại học Công nghệ TP.HCM (HUTECH)'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.class_, color: Colors.purple),
                      title: const Text('Lớp'),
                      subtitle: const Text('Mobile App Development'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
