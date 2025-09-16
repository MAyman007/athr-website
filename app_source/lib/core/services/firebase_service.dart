import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/organization.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Auth ---

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // --- User & Organization ---

  Future<void> setupNewUserAndOrganization({
    required User user,
    required String fullName,
    required String organizationName,
    required List<String> domains,
    required List<String> ipRanges,
    required List<String> keywords,
    required String primaryNotificationEmail,
    required String secondaryNotificationEmail,
    required String alertFrequency,
  }) async {
    // Update user's display name first
    await user.updateDisplayName(fullName);

    // Create a batch write for atomic operation
    final batch = _firestore.batch();

    // 1. Create the organization document reference and model
    final orgRef = _firestore.collection('organizations').doc();
    final newOrganization = Organization(
      id: orgRef.id,
      name: organizationName,
      domains: domains,
      ipRanges: ipRanges,
      keywords: keywords,
      createdBy: user.uid,
    );
    batch.set(orgRef, newOrganization.toMap());

    // 2. Create the user document reference and model
    final userRef = _firestore.collection('users').doc(user.uid);
    final newUser = AppUser(
      uid: user.uid,
      orgId: orgRef.id,
      email: user.email!,
      fullName: fullName,
      role: 'admin', // Default role for creator
      settings: UserSettings(
        primaryNotificationEmail: primaryNotificationEmail,
        secondaryNotificationEmail: secondaryNotificationEmail,
        alertFrequency: alertFrequency,
      ),
    );
    batch.set(userRef, newUser.toMap());

    // Commit the batch
    await batch.commit();
  }
}
