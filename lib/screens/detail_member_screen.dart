import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';
import 'edit_member_screen.dart';

class DetailMemberScreen extends StatefulWidget {
  final Member member;

  const DetailMemberScreen({Key? key, required this.member}) : super(key: key);

  @override
  State<DetailMemberScreen> createState() => _DetailMemberScreenState();
}

class _DetailMemberScreenState extends State<DetailMemberScreen> {
  late Member _currentMember;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<Member?>(
      context,
      MaterialPageRoute(
        builder: (context) => EditMemberScreen(member: _currentMember),
      ),
    );

    // Nếu update thành công, cập nhật member hiện tại
    if (result != null && mounted) {
      setState(() {
        _currentMember = result;
        _hasChanges = true; // Đánh dấu có thay đổi
      });
    }
  }

  @override
  void dispose() {
    // Khi đóng màn hình, trả về true nếu có thay đổi
    super.dispose();
  }

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
        title: Text(_currentMember.fullName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Nút Edit
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: _navigateToEdit,
          ),
        ],
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
                  // Avatar with border and shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: _currentMember.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _currentMember.avatarUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                errorWidget: (context, url, error) {
                                  // Log error for debugging
                                  debugPrint('❌ Avatar load error: $error');
                                  debugPrint('   URL: $url');
                                  debugPrint(
                                    '   Path: ${_currentMember.avatarPath}',
                                  );

                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red[100],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red[700],
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Load failed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[300]!,
                                    Colors.purple[300]!,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _currentMember.fullName.isNotEmpty
                                      ? _currentMember.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tên
                  Text(
                    _currentMember.fullName,
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
                      _currentMember.role.displayName,
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
                      subtitle: _currentMember.email != null
                          ? Text(_currentMember.email!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _currentMember.email != null
                            ? () => _sendEmail(_currentMember.email!)
                            : null,
                      ),
                      onTap: _currentMember.email != null
                          ? () => _sendEmail(_currentMember.email!)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Số điện thoại
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.green),
                      title: const Text('Số điện thoại'),
                      subtitle: _currentMember.phone != null
                          ? Text(_currentMember.phone!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: _currentMember.phone != null
                            ? () => _makePhoneCall(_currentMember.phone!)
                            : null,
                      ),
                      onTap: _currentMember.phone != null
                          ? () => _makePhoneCall(_currentMember.phone!)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mô tả
                  if (_currentMember.bio != null &&
                      _currentMember.bio!.isNotEmpty) ...[
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
                          _currentMember.bio!,
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
                        '${_currentMember.createdAt.day}/${_currentMember.createdAt.month}/${_currentMember.createdAt.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
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
                onPressed: _currentMember.phone != null
                    ? () => _makePhoneCall(_currentMember.phone!)
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
                onPressed: _currentMember.email != null
                    ? () => _sendEmail(_currentMember.email!)
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
