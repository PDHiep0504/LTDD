import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class Member {
  final String id;
  final String fullName;
  final String? bio;
  final MemberRole role;
  final String? avatarPath;
  final String? email;
  final String? phone;
  final Map<String, dynamic> socials;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    required this.id,
    required this.fullName,
    this.bio,
    required this.role,
    this.avatarPath,
    this.email,
    this.phone,
    this.socials = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      bio: json['bio'],
      role: MemberRole.fromString(json['role'] ?? 'member'),
      avatarPath: json['avatar_path'],
      email: json['email'], // Có thể null nếu cột không tồn tại
      phone: json['phone'], // Có thể null nếu cột không tồn tại
      socials: (json['socials'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'bio': bio,
      'role': role.value,
      'avatar_path': avatarPath,
      'email': email,
      'phone': phone,
      'socials': socials,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get avatar URL from Supabase Storage
  String? get avatarUrl {
    if (avatarPath == null || avatarPath!.isEmpty) {
      print('🚫 No avatar path for member: $fullName');
      return null;
    }

    print('🖼️ Processing avatar for $fullName, path: $avatarPath');

    try {
      // Use getPublicUrl to generate the public URL
      final url = Supabase.instance.client.storage
          .from(SupabaseConfig.avatarsBucket)
          .getPublicUrl(avatarPath!);

      print('✅ Generated avatar URL: $url');
      print('   Full path: ${SupabaseConfig.avatarsBucket}/$avatarPath');

      // Validate URL is not empty and looks like a URL
      if (url.isEmpty || !url.startsWith('http')) {
        print('⚠️ Invalid URL generated, using fallback');
        return null;
      }

      return url;
    } catch (e) {
      print('❌ Error generating avatar URL: $e');
      // Return null to show fallback UI instead of placeholder
      return null;
    }
  }

  // Get social media links
  String? getSocialLink(String platform) {
    return socials[platform]?.toString();
  }

  Member copyWith({
    String? id,
    String? fullName,
    String? bio,
    MemberRole? role,
    String? avatarPath,
    String? email,
    String? phone,
    Map<String, dynamic>? socials,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      socials: socials ?? this.socials,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String? subtitle;
  final String? description;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    this.subtitle,
    this.description,
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subtitle: json['subtitle'],
      description: json['description'],
      coverUrl: json['cover_url'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'description': description,
      'cover_url': coverUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
