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
      email: json['email'],
      phone: json['phone'],
      socials: json['socials'] ?? {},
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
    if (avatarPath == null) return null;
    try {
      // Try to get from Supabase client if available
      return Supabase.instance.client.storage
          .from(SupabaseConfig.avatarsBucket)
          .getPublicUrl(avatarPath!);
    } catch (e) {
      // Fallback for demo/testing
      return 'https://via.placeholder.com/150?text=${fullName[0]}';
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
