class SupabaseConfig {
  // Table names
  static const String membersTable = 'members';
  static const String groupsTable = 'groups';
  static const String groupMembersTable = 'group_members';
  static const String profilesTable = 'profiles';

  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String coversBucket = 'covers';
}

// Enum cho member role
enum MemberRole {
  leader('leader'),
  coLead('co_lead'),
  member('member'),
  mentor('mentor'),
  guest('guest');

  const MemberRole(this.value);
  final String value;

  static MemberRole fromString(String value) {
    switch (value) {
      case 'leader':
        return MemberRole.leader;
      case 'co_lead':
        return MemberRole.coLead;
      case 'member':
        return MemberRole.member;
      case 'mentor':
        return MemberRole.mentor;
      case 'guest':
        return MemberRole.guest;
      default:
        return MemberRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case MemberRole.leader:
        return 'Leader';
      case MemberRole.coLead:
        return 'Co-Lead';
      case MemberRole.member:
        return 'Member';
      case MemberRole.mentor:
        return 'Mentor';
      case MemberRole.guest:
        return 'Guest';
    }
  }
}

// Sample data for testing
class SampleData {
  static final List<Map<String, dynamic>> sampleMembers = [
    {
      'id': '550e8400-e29b-41d4-a716-446655440001',
      'full_name': 'Nguyễn Vũ Quang Phúc',
      'bio': 'Team Leader với kinh nghiệm phát triển ứng dụng di động Flutter',
      'role': 'leader',
      'email': 'phuc.nguyen@hutech.edu.vn',
      'phone': '0123456789',
      'socials': {
        'github': 'https://github.com/ngvqphuc2610',
        'facebook': 'https://facebook.com/phuc.nguyen',
        'linkedin': 'https://linkedin.com/in/phuc-nguyen',
      },
      'created_at': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'updated_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
    {
      'id': '550e8400-e29b-41d4-a716-446655440002',
      'full_name': 'Trần Thị Mai',
      'bio': 'Flutter Developer chuyên về UI/UX và state management',
      'role': 'co_lead',
      'email': 'mai.tran@hutech.edu.vn',
      'phone': '0987654321',
      'socials': {
        'github': 'https://github.com/mai.tran',
        'linkedin': 'https://linkedin.com/in/mai-tran',
      },
      'created_at': DateTime.now()
          .subtract(const Duration(days: 25))
          .toIso8601String(),
      'updated_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': '550e8400-e29b-41d4-a716-446655440003',
      'full_name': 'Lê Văn Nam',
      'bio': 'Backend Developer và Database Administrator',
      'role': 'member',
      'email': 'nam.le@hutech.edu.vn',
      'phone': '0369258147',
      'socials': {
        'github': 'https://github.com/nam.le',
        'linkedin': 'https://linkedin.com/in/nam-le',
      },
      'created_at': DateTime.now()
          .subtract(const Duration(days: 20))
          .toIso8601String(),
      'updated_at': DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String(),
    },
    {
      'id': '550e8400-e29b-41d4-a716-446655440004',
      'full_name': 'Phạm Thị Lan',
      'bio': 'QA Engineer và Test Automation specialist',
      'role': 'member',
      'email': 'lan.pham@hutech.edu.vn',
      'phone': '0741852963',
      'socials': {'linkedin': 'https://linkedin.com/in/lan-pham'},
      'created_at': DateTime.now()
          .subtract(const Duration(days: 15))
          .toIso8601String(),
      'updated_at': DateTime.now()
          .subtract(const Duration(days: 4))
          .toIso8601String(),
    },
  ];

  static final Map<String, dynamic> sampleGroup = {
    'id': '550e8400-e29b-41d4-a716-446655440000',
    'name': 'Mobile Development Team',
    'subtitle': 'HUTECH University',
    'description':
        'Nhóm phát triển ứng dụng di động sử dụng Flutter framework. Chuyên về cross-platform development, UI/UX design và backend integration.',
    'created_at': DateTime.now()
        .subtract(const Duration(days: 35))
        .toIso8601String(),
    'updated_at': DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
  };
}
