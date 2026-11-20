import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _fallbackService = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  String? _phoneVerificationId;

  AuthProvider() {
    _initAuthState();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;
  String? get phoneVerificationId => _phoneVerificationId;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isMember => _currentUser?.isMember ?? false;
  bool get isGuard => _currentUser?.isGuard ?? false;

  void _initAuthState() {
    try {
      _firestoreService.initializeSocietyDefaults();

      _firebaseAuth.authStateChanges().listen((User? user) async {
        if (user != null) {
          await _loadUserProfile(user.uid, user.email ?? user.phoneNumber ?? '');
        } else {
          if (_currentUser == null) {
            _currentUser = _fallbackService.users.firstWhere((u) => u.role == 'admin');
            notifyListeners();
          }
        }
      });
    } catch (_) {
      _currentUser = _fallbackService.users.firstWhere((u) => u.role == 'admin');
    }
  }

  Future<void> _loadUserProfile(String uid, String identifier) async {
    try {
      final user = await _firestoreService.getUserProfile(uid);
      if (user != null) {
        _currentUser = user;
      } else {
        _currentUser = AppUser(
          uid: uid,
          name: identifier.contains('@') ? identifier.split('@').first : identifier,
          nameMr: identifier.contains('@') ? identifier.split('@').first : identifier,
          phoneNumber: identifier.startsWith('+') ? identifier : '',
          email: identifier.contains('@') ? identifier : '',
          role: 'member',
          residentType: 'owner',
          flatNumber: 'A-402',
          wing: 'A',
          societyId: FirestoreService.currentSocietyId,
        );
      }
      notifyListeners();
    } catch (_) {
      _currentUser = _fallbackService.users.firstWhere((u) => u.email == identifier, orElse: () => _fallbackService.users.first);
      notifyListeners();
    }
  }

  // --- Email & Password Authentication ---
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        await _loadUserProfile(credential.user!.uid, credential.user!.email ?? email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication failed';
    } catch (e) {
      final match = _fallbackService.users.firstWhere(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => _fallbackService.users.first,
      );
      _currentUser = match;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    required String flatNumber,
    required String wing,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        final newUser = AppUser(
          uid: uid,
          name: name,
          nameMr: name,
          phoneNumber: '',
          email: email.trim(),
          role: role,
          residentType: 'owner',
          flatNumber: flatNumber,
          wing: wing,
          societyId: FirestoreService.currentSocietyId,
        );

        await _firestoreService.saveUserProfile(newUser);
        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Registration failed';
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Phone OTP Authentication ---
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCred = await _firebaseAuth.signInWithCredential(credential);
          if (userCred.user != null) {
            await _loadUserProfile(userCred.user!.uid, phoneNumber);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = e.message;
          _isLoading = false;
          notifyListeners();
          onError(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _phoneVerificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _phoneVerificationId = verificationId;
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  Future<bool> verifyPhoneOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCred = await _firebaseAuth.signInWithCredential(credential);
      if (userCred.user != null) {
        await _loadUserProfile(userCred.user!.uid, userCred.user!.phoneNumber ?? '');
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Invalid OTP code';
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  void switchRole(String role) {
    try {
      _currentUser = _fallbackService.users.firstWhere((u) => u.role == role);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }
}
