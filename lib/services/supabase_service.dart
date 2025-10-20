import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member.dart';
import '../config/constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Check if Supabase is configured
  static bool _isConfigured() {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      print('🔍 Checking Supabase configuration:');
      print('  URL: ${supabaseUrl.isNotEmpty ? supabaseUrl : "EMPTY"}');
      print(
        '  Key: ${supabaseAnonKey.isNotEmpty ? "Present (${supabaseAnonKey.length} chars)" : "EMPTY"}',
      );
      print('  URL starts with https: ${supabaseUrl.startsWith('https://')}');
      print(
        '  URL contains placeholder: ${supabaseUrl.contains('your-project-id')}',
      );

      final isConfigured =
          supabaseUrl.isNotEmpty &&
          supabaseAnonKey.isNotEmpty &&
          supabaseUrl.startsWith('https://') &&
          !supabaseUrl.contains('your-project-id');

      print('  📊 Configuration valid: $isConfigured');
      return isConfigured;
    } catch (e) {
      print('❌ Error checking configuration: $e');
      return false;
    }
  }

  // Groups operations
  static Future<Group> getGroup() async {
    try {
      if (!_isConfigured()) {
        await Future.delayed(const Duration(milliseconds: 300));
        return Group.fromJson(SampleData.sampleGroup);
      }

      final response = await client
          .from(SupabaseConfig.groupsTable)
          .select()
          .limit(1)
          .single();

      return Group.fromJson(response);
    } catch (e) {
      print('Supabase error, using sample group: $e');
      return Group.fromJson(SampleData.sampleGroup);
    }
  }

  // Members CRUD operations
  static Future<List<Member>> getMembers() async {
    print('📥 Getting members...');
    try {
      if (!_isConfigured()) {
        print('⚠️ Supabase not configured, using sample data');
        await Future.delayed(const Duration(milliseconds: 500));
        return SampleData.sampleMembers
            .map((json) => Member.fromJson(json))
            .toList();
      }

      print(
        '🔄 Fetching members from Supabase table: ${SupabaseConfig.membersTable}',
      );
      final response = await client
          .from(SupabaseConfig.membersTable)
          .select()
          .order('created_at', ascending: false);

      print('✅ Got response from Supabase: ${response.length} members');
      return (response as List).map((json) => Member.fromJson(json)).toList();
    } catch (e) {
      // Fallback to sample data on error
      print('❌ Supabase error, using sample data: $e');
      return SampleData.sampleMembers
          .map((json) => Member.fromJson(json))
          .toList();
    }
  }

  static Future<Member> getMember(String id) async {
    try {
      if (!_isConfigured()) {
        await Future.delayed(const Duration(milliseconds: 300));
        final sampleMember = SampleData.sampleMembers.firstWhere(
          (member) => member['id'] == id,
          orElse: () => SampleData.sampleMembers.first,
        );
        return Member.fromJson(sampleMember);
      }

      final response = await client
          .from(SupabaseConfig.membersTable)
          .select()
          .eq('id', id)
          .single();

      return Member.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch member: $e');
    }
  }

  static Future<Member> addMember(Member member) async {
    try {
      if (!_isConfigured()) {
        await Future.delayed(const Duration(milliseconds: 800));
        // In real app, this would persist to local storage
        return member;
      }

      // Create a copy of member data without id for insert
      final memberData = member.toJson();
      memberData.remove('id'); // Let database generate UUID
      memberData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(SupabaseConfig.membersTable)
          .insert(memberData)
          .select()
          .single();

      return Member.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  static Future<Member> updateMember(Member member) async {
    try {
      if (!_isConfigured()) {
        await Future.delayed(const Duration(milliseconds: 600));
        return member.copyWith(updatedAt: DateTime.now());
      }

      final memberData = member.toJson();
      memberData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(SupabaseConfig.membersTable)
          .update(memberData)
          .eq('id', member.id)
          .select()
          .single();

      return Member.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update member: $e');
    }
  }

  static Future<void> deleteMember(String id) async {
    try {
      if (!_isConfigured()) {
        await Future.delayed(const Duration(milliseconds: 400));
        return;
      }

      await client.from(SupabaseConfig.membersTable).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete member: $e');
    }
  }

  // Upload avatar to Supabase Storage
  static Future<String?> uploadAvatar(String filePath, String fileName) async {
    print('🖼️ Starting avatar upload: $fileName');

    try {
      if (!_isConfigured()) {
        throw Exception(
          'Supabase not configured. Please check .env file and restart app.',
        );
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileBytes = await file.readAsBytes();
      print('📁 File size: ${fileBytes.length} bytes');

      // Try to create bucket first if it doesn't exist
      try {
        await client.storage.createBucket(
          SupabaseConfig.avatarsBucket,
          BucketOptions(public: true, allowedMimeTypes: ['image/*']),
        );
        print('✅ Bucket created: ${SupabaseConfig.avatarsBucket}');
      } catch (bucketError) {
        // Bucket might already exist, ignore error
        print('ℹ️ Bucket creation info: $bucketError');
      }

      print(
        '⬆️ Uploading to bucket: ${SupabaseConfig.avatarsBucket}/$fileName',
      );

      // Upload file
      final response = await client.storage
          .from(SupabaseConfig.avatarsBucket)
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('📤 Upload response: $response');

      if (response.isEmpty) {
        throw Exception('Upload failed - empty response');
      }

      print('✅ Upload successful: $fileName');

      // Verify file exists by getting public URL
      final publicUrl = client.storage
          .from(SupabaseConfig.avatarsBucket)
          .getPublicUrl(fileName);
      print('🔗 Public URL: $publicUrl');

      return fileName; // Return path for database
    } catch (e) {
      print(Exception(e));

      // Re-throw error instead of returning demo path
      rethrow;
    }
  }
}
