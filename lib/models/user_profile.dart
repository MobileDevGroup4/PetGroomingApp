class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String address;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.address,
    this.photoUrl,
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'address': address,
        'photoUrl': photoUrl,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        name: (map['name'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        address: (map['address'] ?? '') as String,
        photoUrl: map['photoUrl'] as String?,
      );
}