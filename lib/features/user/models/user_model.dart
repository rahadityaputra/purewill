import 'package:purewill/features/user/models/profile_model.dart';

class UserModel {
  final String id;
  final String email;
  final ProfileModel profile;
  final String? username;

  UserModel({
    required this.id,
    required this.email,
    required this.profile,
    this.username,
  });

  String? get fullName => profile.fullName;

  String? get avatarUrl => profile.avatarUrl;

  String? get bio => profile.bio;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap = profile is Map<String, dynamic>
        ? profile
        : profile is Map
        ? Map<String, dynamic>.from(profile)
        : const <String, dynamic>{};

    return UserModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      profile: ProfileModel(
        fullName:
            json['full_name']?.toString() ??
            json['fullname']?.toString() ??
            profileMap['fullname']?.toString() ??
            profileMap['fullName']?.toString() ??
            '',
        avatarUrl:
            json['avatar_url']?.toString() ??
            json['avatarUrl']?.toString() ??
            profileMap['avatar_url']?.toString() ??
            profileMap['avatarUrl']?.toString(),
        bio:
            json['bio']?.toString() ??
            profileMap['bio']?.toString() ??
            profileMap['about']?.toString(),
      ),
      username: json['username']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'profile': profile.toJson(),
      'username': username,
    };
  }
}
