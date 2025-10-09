import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email;      
  final String name;
  final String phone;
  final String address;
  final String? photoUrl;    

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.photoUrl,
  });

  factory UserProfile.empty({required String uid, required String? email}) => UserProfile(
        uid: uid,
        email: email,
        name: '',
        phone: '',
        address: '',
        photoUrl: null,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        email: map['email'] as String?,
        name: (map['name'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        address: (map['address'] ?? '') as String,
        photoUrl: map['photoUrl'] as String?,
      );
}