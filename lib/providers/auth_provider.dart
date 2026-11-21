import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/society_model.dart';
import '../services/firestore_service.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  needsOnboarding, // Logged into Google, but hasn't created or joined a society
  pendingApproval, // Waiting for society admin to approve membership
  authenticated,   // Fully approved and active in a society
}

class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AppUser? _currentUser;
  SocietyModel? _currentSociety;
  AuthStatus _status = AuthStatus.unauthenticated;
  bool _isLoading = false;
  String? _errorMessage;

  String? _phoneVerificationId;

  AuthProvider() {
    _initAuthState();
  }

  AppUser? get currentUser => _currentUser;
  SocietyModel? get currentSociety => _currentSociety;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null && _currentSociety != null;
  bool get needsOnboarding => _status == AuthStatus.needsOnboarding;
  bool get isPendingApproval => _status == AuthStatus.pendingApproval;
  String? get errorMessage => _errorMessage;
  String? get phoneVerificationId => _phoneVerificationId;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isMember => _currentUser?.isMember ?? false;
  bool get isGuard => _currentUser?.isGuard ?? false;

  void _initAuthState() {
    try {
      _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          await _handleFirebaseUser(firebaseUser);
        } else {
          _currentUser = null;
          _currentSociety = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      });
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _handleFirebaseUser(User firebaseUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await _firestoreService.getUser(firebaseUser.uid);

      if (userDoc == null || userDoc.societyId.isEmpty) {
        // User is logged into Google, but not linked to any society yet
        _currentUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? (firebaseUser.email?.split('@').first ?? 'User'),
          nameMr: firebaseUser.displayName ?? (firebaseUser.email?.split('@').first ?? 'वापरकर्ता'),
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          photoUrl: firebaseUser.photoURL,
          role: 'member',
          societyId: '',
          isApproved: false,
        );
        _currentSociety = null;
        _status = AuthStatus.needsOnboarding;
      } else {
        _currentUser = userDoc;

        if (!userDoc.isApproved) {
          // Joined a society but pending secretary approval
          _status = AuthStatus.pendingApproval;
          _currentSociety = await _firestoreService.getSociety(userDoc.societyId);
        } else {
          // Approved active user
          _currentSociety = await _firestoreService.getSociety(userDoc.societyId);
          _firestoreService.activeSocietyId = userDoc.societyId;
          _status = AuthStatus.authenticated;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 1-Click Primary Sign-In with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled Google prompt
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _handleFirebaseUser(userCredential.user!);
        return true;
      }
      return false;
    } catch (e) {
      // Offline / Developer fallback if Google Play Services is unavailable
      _errorMessage = 'Google Sign-In: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Guest / Demo Quick-Login for Testing without Google account
  Future<void> signInAsDemoUser({String role = 'admin'}) async {
    _isLoading = true;
    notifyListeners();

    final demoSociety = SocietyModel(
      id: 'soc_demo_trial',
      societyCode: 'SOC-999999',
      name: 'Sample Housing Society',
      nameMr: 'नमुना गृहनिर्माण संस्था',
      address: 'Plot 10, MG Road, Pune',
      city: 'Pune',
      pincode: '411001',
      wings: ['A', 'B'],
      totalFlats: 30,
      adminUid: 'usr_demo_admin',
    );

    _currentSociety = demoSociety;
    _firestoreService.activeSocietyId = demoSociety.id;

    _currentUser = AppUser(
      uid: role == 'admin' ? 'usr_demo_admin' : 'usr_demo_member',
      name: role == 'admin' ? 'Demo Admin (Secretary)' : 'Demo Resident',
      nameMr: role == 'admin' ? 'डेमो सचिव' : 'डेमो सभासद',
      email: role == 'admin' ? 'admin@demo.com' : 'resident@demo.com',
      phoneNumber: '+919876543210',
      role: role,
      flatNumber: role == 'admin' ? 'A-101' : 'A-202',
      wing: 'A',
      societyId: demoSociety.id,
      societyCode: demoSociety.societyCode,
      isApproved: true,
    );

    _status = AuthStatus.authenticated;
    _isLoading = false;
    notifyListeners();
  }

  /// Quick Test Sign-In into Onboarding flow without requiring Google Play Services SHA-1
  Future<void> signInForOnboardingTesting({
    String? name,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final testUser = AppUser(
        uid: 'test_${DateTime.now().millisecondsSinceEpoch}',
        name: name ?? 'डॉ. प्रदीप कोळे',
        nameMr: name ?? 'डॉ. प्रदीप कोळे',
        email: email ?? 'pradip.kole@societygate.com',
        phoneNumber: '',
        role: 'admin',
        societyId: '',
        isApproved: false,
      );

      _currentUser = testUser;
      _currentSociety = null;
      _status = AuthStatus.needsOnboarding;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a brand new Society (Creator becomes Admin)
  Future<bool> createNewSociety({
    required String name,
    required String nameMr,
    required String address,
    required String city,
    required String pincode,
    required String registrationNo,
    required List<String> wings,
    required int totalFlats,
    Uint8List? logoBytes,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final society = await _firestoreService.createSociety(
        name: name,
        nameMr: nameMr,
        address: address,
        city: city,
        pincode: pincode,
        registrationNo: registrationNo,
        wings: wings,
        totalFlats: totalFlats,
        adminUser: _currentUser!,
        logoBytes: logoBytes,
      );

      _currentSociety = society;
      _currentUser = _currentUser!.copyWith(
        societyId: society.id,
        societyCode: society.societyCode,
        role: 'admin',
        isApproved: true,
      );

      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request to join an existing society using 6-digit Society Code
  Future<bool> joinSocietyWithCode({
    required String societyCode,
    required String role,
    required String wing,
    required String flatNumber,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final society = await _firestoreService.findSocietyByCode(societyCode);
      if (society == null) {
        _errorMessage = 'Invalid Society Code / अवैध सोसायटी कोड!';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _firestoreService.submitJoinRequest(
        user: _currentUser!,
        societyId: society.id,
        societyCode: society.societyCode,
        role: role,
        wing: wing,
        flatNumber: flatNumber,
        phoneNumber: phoneNumber,
      );

      _currentSociety = society;
      _currentUser = _currentUser!.copyWith(
        societyId: society.id,
        societyCode: society.societyCode,
        role: role,
        wing: wing,
        flatNumber: flatNumber,
        isApproved: false, // Awaiting admin approval
      );

      _status = AuthStatus.pendingApproval;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update society settings (Name, address, UPI ID, Bank, Logo, Mobile login toggle)
  Future<bool> updateSocietySettings({
    String? name,
    String? nameMr,
    String? address,
    String? city,
    String? pincode,
    String? upiId,
    String? upiMerchantName,
    String? bankName,
    String? accountNo,
    String? ifsc,
    double? defaultMaintenanceAmount,
    Uint8List? newLogoBytes,
    bool? allowMobileLogin,
  }) async {
    if (_currentSociety == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _firestoreService.updateSocietySettings(
        currentSociety: _currentSociety!,
        name: name,
        nameMr: nameMr,
        address: address,
        city: city,
        pincode: pincode,
        upiId: upiId,
        upiMerchantName: upiMerchantName,
        bankName: bankName,
        accountNo: accountNo,
        ifsc: ifsc,
        defaultMaintenanceAmount: defaultMaintenanceAmount,
        newLogoBytes: newLogoBytes,
        allowMobileLogin: allowMobileLogin,
      );

      _currentSociety = updated;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Backup Sign-In via Registered Mobile Number
  Future<bool> signInWithPhoneNumber(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _firestoreService.findUserByPhone(phoneNumber);
      if (user == null) {
        _errorMessage = 'हा मोबाईल नंबर नोंदणीकृत नाही. कृपया आधी सोसायटी कोड टाकून सामील व्हा.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      if (user.societyId.isNotEmpty) {
        _currentSociety = await _firestoreService.getSociety(user.societyId);
        _firestoreService.activeSocietyId = user.societyId;
      }

      if (!user.isApproved) {
        _status = AuthStatus.pendingApproval;
      } else {
        _status = AuthStatus.authenticated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'लॉगिन त्रुटी: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh user profile and approval status from server
  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    final user = await _firestoreService.getUser(_currentUser!.uid);
    if (user != null) {
      _currentUser = user;
      if (user.isApproved && user.societyId.isNotEmpty) {
        _currentSociety = await _firestoreService.getSociety(user.societyId);
        _firestoreService.activeSocietyId = user.societyId;
        _status = AuthStatus.authenticated;
      } else if (!user.isApproved && user.societyId.isNotEmpty) {
        _status = AuthStatus.pendingApproval;
      }
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (_) {}
    _currentUser = null;
    _currentSociety = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }
}
