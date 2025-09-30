import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/member.dart';
import '../services/supabase_service.dart';
import '../config/constants.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({Key? key}) : super(key: key);

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedRole = 'Developer';
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _roles = [
    'Developer',
    'Designer',
    'Tester',
    'Project Manager',
    'Tech Lead',
    'DevOps',
    'Business Analyst',
    'Intern',
  ];

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Xóa ảnh',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;

      // Upload ảnh nếu có
      if (_selectedImage != null) {
        final fileName = 'member_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await SupabaseService.uploadAvatar(
          _selectedImage!.path,
          fileName,
        );
      }

      // Tạo member mới
      final newMember = Member(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: MemberRole.fromString(_selectedRole),
        avatarPath: imageUrl,
        bio: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SupabaseService.addMember(newMember);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã thêm thành viên mới'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thành viên'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            IconButton(onPressed: _saveMember, icon: const Icon(Icons.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ảnh đại diện
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 32,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Thêm ảnh',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tên
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Số điện thoại
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Vai trò
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Vai trò *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn vai trò';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 32),

              // Nút lưu
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMember,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Đang lưu...'),
                        ],
                      )
                    : const Text(
                        'Lưu thành viên',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 16),

              // Ghi chú
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Lưu ý:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Các trường có dấu (*) là bắt buộc\n'
                        '• Ảnh sẽ được tải lên Supabase Storage\n'
                        '• Dữ liệu sẽ được lưu trên Supabase Database',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
