import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// Ngam App — Auth Provider
// Manages authentication state and role switching
// ============================================================

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get userRole => _user?.role ?? 'pemesan';
  bool get isCustomer => userRole == 'pemesan';
  bool get isRunner => userRole == 'runner';

  /// Try to restore session on app start
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.getCurrentUser();
    } catch (e) {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email/password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Switch user role between pemesan and runner
  Future<void> switchRole() async {
    if (_user == null) return;

    final newRole = _user!.role == 'pemesan' ? 'runner' : 'pemesan';

    try {
      await AuthService.updateRole(_user!.id, newRole);
      _user = _user!.copyWith(role: newRole);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to switch role';
      notifyListeners();
    }
  }

  /// Set role directly
  Future<void> setRole(String role) async {
    if (_user == null) return;

    try {
      await AuthService.updateRole(_user!.id, role);
      _user = _user!.copyWith(role: role);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update role';
      notifyListeners();
    }
  }

  /// Submit runner verification
  Future<void> submitRunnerVerification({
    required String fullName,
    required String icNumber,
    required String vehicleType,
    String? plateNumber,
  }) async {
    if (_user == null) return;
    try {
      await AuthService.submitRunnerVerification(
        userId: _user!.id,
        fullName: fullName,
        icNumber: icNumber,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
      );
      _user = _user!.copyWith(isVerifiedRunner: true);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to verify runner';
      notifyListeners();
      throw e;
    }
  }

  /// Update profile details
  Future<String?> updateProfile({
    required String name,
    required String phone,
    String? bio,
    String? gender,
    DateTime? birthDate,
    String? address,
  }) async {
    if (_user == null) return 'User not logged in';
    try {
      final error = await SupabaseService.updateProfile(
        userId: _user!.id,
        name: name,
        phone: phone,
        bio: bio,
        gender: gender,
        birthDate: birthDate,
        address: address,
      );
      if (error == null) {
        _user = _user!.copyWith(
          name: name, 
          phone: phone,
          bio: bio,
          gender: gender,
          birthDate: birthDate,
          address: address,
        );
        notifyListeners();
      }
      return error;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Upload user avatar
  Future<String?> uploadAvatar(File imageFile) async {
    if (_user == null) return 'User not logged in';
    try {
      final String path = '${_user!.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageResponse = await Supabase.instance.client.storage
          .from('avatars')
          .upload(path, imageFile, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      final String publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      final error = await SupabaseService.updateProfile(
        userId: _user!.id,
        avatarUrl: publicUrl,
      );

      if (error == null) {
        _user = _user!.copyWith(avatarUrl: publicUrl);
        notifyListeners();
      }
      return error;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
