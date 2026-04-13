// lib/models/models.dart

// ─────────────────────────────────────────
// USER ROLE — DB-д 'student', 'club_admin', 'super_admin' гэж хадгална
// ─────────────────────────────────────────
enum UserRole {
  student,
  clubAdmin,
  superAdmin;

  /// DB-ийн string → enum
  static UserRole fromDb(String? value) {
    switch (value) {
      case 'club_admin':
      case 'club_manager': // хуучин нэр
        return UserRole.clubAdmin;
      case 'super_admin':
      case 'admin': // хуучин нэр
        return UserRole.superAdmin;
      default:
        return UserRole.student;
    }
  }

  /// enum → DB string
  String toDb() {
    switch (this) {
      case UserRole.clubAdmin:
        return 'club_admin';
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.student:
        return 'student';
    }
  }

  /// UI-д харуулах нэр
  String get label {
    switch (this) {
      case UserRole.clubAdmin:
        return 'Клубын тэргүүн';
      case UserRole.superAdmin:
        return 'Супер админ';
      case UserRole.student:
        return 'Оюутан';
    }
  }
}

// ─────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String studentCode;
  final String school;
  final String department;
  final String phone;
  final UserRole role;
  final String? managedClubId;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentCode,
    required this.school,
    required this.department,
    required this.phone,
    this.role = UserRole.student,
    this.managedClubId,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> d) {
    return UserModel(
      id:            d['id'] ?? '',
      fullName:      d['full_name'] ?? '',
      email:         d['email'] ?? '',
      studentCode:   d['student_code'] ?? '',
      school:        d['school'] ?? '',
      department:    d['department'] ?? '',
      phone:         d['phone'] ?? '',
      role:          UserRole.fromDb(d['role']),
      managedClubId: d['managed_club_id'],
      avatarUrl:     d['avatar_url'],
      createdAt: d['created_at'] != null
          ? DateTime.parse(d['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'full_name':       fullName,
    'email':           email,
    'student_code':    studentCode,
    'school':          school,
    'department':      department,
    'phone':           phone,
    'role':            role.toDb(),
    'managed_club_id': managedClubId,
  };

  bool get isStudent    => role == UserRole.student;
  bool get isClubAdmin  => role == UserRole.clubAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
}

// ─────────────────────────────────────────
enum RequestStatus { pending, approved, rejected }

class JoinRequestModel {
  final String id;
  final String userId;
  final String clubId;
  final String clubName;
  final String message;
  final RequestStatus status;
  final DateTime requestedAt;

  JoinRequestModel({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.clubName,
    required this.message,
    this.status = RequestStatus.pending,
    required this.requestedAt,
  });

  factory JoinRequestModel.fromMap(Map<String, dynamic> d) {
    return JoinRequestModel(
      id:       d['id'] ?? '',
      userId:   d['user_id'] ?? '',
      clubId:   d['club_id'] ?? '',
      clubName: d['clubs']?['name'] ?? '',
      message:  d['message'] ?? '',
      status: RequestStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      requestedAt: d['requested_at'] != null
          ? DateTime.parse(d['requested_at'])
          : DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────
class EventModel {
  final String id;
  final String clubId;
  final String clubName;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final double hours;

  EventModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.hours,
  });

  factory EventModel.fromMap(Map<String, dynamic> d) {
    return EventModel(
      id:          d['id'] ?? '',
      clubId:      d['club_id'] ?? '',
      clubName:    d['clubs']?['name'] ?? '',
      title:       d['title'] ?? '',
      description: d['description'] ?? '',
      location:    d['location'] ?? '',
      eventDate:   d['event_date'] != null
          ? DateTime.parse(d['event_date'])
          : DateTime.now(),
      hours: (d['hours'] ?? 0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────
class VolunteerHourModel {
  final String id;
  final String userId;
  final String clubId;
  final String clubName;
  final String eventTitle;
  final double hours;
  final DateTime addedAt;

  VolunteerHourModel({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.clubName,
    required this.eventTitle,
    required this.hours,
    required this.addedAt,
  });

  factory VolunteerHourModel.fromMap(Map<String, dynamic> d) {
    return VolunteerHourModel(
      id:         d['id'] ?? '',
      userId:     d['user_id'] ?? '',
      clubId:     d['club_id'] ?? '',
      clubName:   d['clubs']?['name'] ?? '',
      eventTitle: d['event_title'] ?? '',
      hours:      (d['hours'] ?? 0).toDouble(),
      addedAt:    d['added_at'] != null
          ? DateTime.parse(d['added_at'])
          : DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────
class ReviewModel {
  final String id;
  final String userId;
  final String userFullName;
  final String clubId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.clubId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> d) {
    return ReviewModel(
      id:           d['id'] ?? '',
      userId:       d['user_id'] ?? '',
      userFullName: d['users']?['full_name'] ?? '',
      clubId:       d['club_id'] ?? '',
      rating:       (d['rating'] ?? 0).toDouble(),
      comment:      d['comment'] ?? '',
      createdAt:    d['created_at'] != null
          ? DateTime.parse(d['created_at'])
          : DateTime.now(),
    );
  }
}