import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';

class DetailMemberScreen extends StatelessWidget {
  final Member member;

  const DetailMemberScreen({Key? key, required this.member}) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Cannot make phone call: $e');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Cannot send email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(member.fullName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với ảnh và thông tin cơ bản
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: member.avatarUrl != null
                        ? CachedNetworkImageProvider(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? Text(
                            member.fullName.isNotEmpty
                                ? member.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Tên
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Vai trò
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      member.role.displayName,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thông tin liên hệ
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin liên hệ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Email
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('Email'),
                      subtitle: member.email != null
                          ? Text(member.email!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: member.email != null
                            ? () => _sendEmail(member.email!)
                            : null,
                      ),
                      onTap: member.email != null
                          ? () => _sendEmail(member.email!)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Số điện thoại
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.green),
                      title: const Text('Số điện thoại'),
                      subtitle: member.phone != null
                          ? Text(member.phone!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: member.phone != null
                            ? () => _makePhoneCall(member.phone!)
                            : null,
                      ),
                      onTap: member.phone != null
                          ? () => _makePhoneCall(member.phone!)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mô tả
                  if (member.bio != null && member.bio!.isNotEmpty) ...[
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          member.bio!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],

                  // Thời gian tham gia
                  const Text(
                    'Thông tin khác',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      title: const Text('Ngày tham gia'),
                      subtitle: Text(
                        '${member.createdAt.day}/${member.createdAt.month}/${member.createdAt.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.fingerprint,
                        color: Colors.purple,
                      ),
                      title: const Text('ID'),
                      subtitle: Text(member.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Nút hành động
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: member.phone != null
                    ? () => _makePhoneCall(member.phone!)
                    : null,
                icon: const Icon(Icons.call),
                label: const Text('Gọi điện'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: member.email != null
                    ? () => _sendEmail(member.email!)
                    : null,
                icon: const Icon(Icons.email),
                label: const Text('Gửi email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
