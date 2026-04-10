import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../main.dart' show firebaseInitialized;

import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that manages the current user's data from Firestore.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserModel? _currentUser;
  StreamSubscription? _userSub;

  UserModel? get currentUser => _currentUser;

  Future<String?> get _activeUid async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null) return authUid;
    // Fallback for mocked test accounts
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('testUid');
  }

  /// Load (and keep in sync) the profile for the signed-in user.
  Future<void> loadCurrentUser() async {
    if (!firebaseInitialized) return;

    final uid = await _activeUid;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromJson({...doc.data()!, 'id': uid});
      }
    } catch (e) {
      // Silently fail — profile won't be loaded
    }
  }

  /// Listen to real-time updates on the current user's profile.
  void listenToCurrentUser(void Function(UserModel?) onChange) {
    if (!firebaseInitialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSub?.cancel();
    _userSub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        _currentUser = UserModel.fromJson({...snap.data()!, 'id': uid});
      } else {
        _currentUser = null;
      }
      onChange(_currentUser);
    });
  }

  /// Update the current user's profile fields.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (!firebaseInitialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Get any user by their UID.
  Future<UserModel?> getUserById(String uid) async {
    if (!firebaseInitialized) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson({...doc.data()!, 'id': uid});
      }
    } catch (_) {}
    return null;
  }

  /// Set user online status.
  Future<void> setOnlineStatus(bool online) async {
    if (!firebaseInitialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({'isOnline': online});
    } catch (e) {
      // Ignore if document not found
    }
  }

  void dispose() {
    _userSub?.cancel();
  }
}
