class ProfileModel {
  final String fullName;
  final String? avatarUrl;

  ProfileModel({required this.fullName, this.avatarUrl});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap = profile is Map<String, dynamic>
        ? profile
        : profile is Map
        ? Map<String, dynamic>.from(profile)
        : const <String, dynamic>{};

    return ProfileModel(
      fullName:
          json['fullname']?.toString() ??
          json['full_name']?.toString() ??
          profileMap['fullname']?.toString() ??
          profileMap['fullName']?.toString() ??
          '',
      avatarUrl:
          json['avatarUrl']?.toString() ??
          json['avatar_url']?.toString() ??
          profileMap['avatarUrl']?.toString() ??
          profileMap['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'fullname': fullName, 'avatarUrl': avatarUrl};
  }
}
