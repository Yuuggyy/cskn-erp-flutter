import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? map['nom_complet'] ?? '',
      role: map['role'] ?? 'lecteur',
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
    );
  }
}

class AuthService {
  static Future<UserProfile?> signIn(String email, String password) async {
    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      return await fetchProfile(response.user!.id);
    }
    return null;
  }

  static Future<UserProfile?> fetchProfile(String userId) async {
    final response = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response != null) {
      return UserProfile.fromMap(response);
    }
    return null;
  }

  static Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  static User? get currentUser => SupabaseService.client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
}
