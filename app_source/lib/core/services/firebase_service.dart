import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service that encapsulates and centralizes Firebase interactions.
///
/// This acts as a facade over FirebaseAuth and FirebaseFirestore, making the
/// rest of the app cleaner and easier to test.
class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // --- Auth Getters ---

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// The currently signed-in user.
  User? get currentUser => auth.currentUser;

  // --- Auth Methods ---

  /// Signs in a user with the given email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Creates a new user with the given email and password.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() {
    return auth.signOut();
  }

  // --- Firestore Methods ---
  // You can add methods here to interact with Firestore,
  // for example, creating a user document.
  /// Sets up a new user and their organization in Firestore.
  ///
  /// This method creates an organization document and a user document within
  /// a single transaction to ensure atomicity.
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
    final orgRef = firestore.collection('organizations').doc();
    final userRef = firestore.collection('users').doc(user.uid);

    return firestore.runTransaction((transaction) async {
      // Create the organization document
      transaction.set(orgRef, {
        'name': organizationName,
        'createdBy': user.uid,
        'domains': domains,
        'ipRanges': ipRanges,
        'keywords': keywords,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create the user document
      transaction.set(userRef, {
        'fullName': fullName,
        'email': user.email,
        'orgId': orgRef.id,
        'role': 'admin', // First user is the admin
        'settings': {
          'primaryNotificationEmail': primaryNotificationEmail,
          'secondaryNotificationEmail': secondaryNotificationEmail,
          'alertFrequency': alertFrequency,
        },
      });
    });
  }
}
