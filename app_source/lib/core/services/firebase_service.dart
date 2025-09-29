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

  /// Fetches the current user's settings and their organization's settings.
  Future<Map<String, dynamic>> getUserAndOrgSettings() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated.');
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('User document not found.');
    }

    final userData = userDoc.data()!;
    final orgId = userData['orgId'] as String?;
    if (orgId == null) {
      throw Exception('Organization ID not found for user.');
    }

    final orgDoc = await firestore.collection('organizations').doc(orgId).get();
    if (!orgDoc.exists || orgDoc.data() == null) {
      throw Exception('Organization document not found.');
    }

    final orgData = orgDoc.data()!;

    return {
      'domains': orgData['domains'] ?? [],
      'ipRanges': orgData['ipRanges'] ?? [],
      'keywords': orgData['keywords'] ?? [],
      'alertFrequency':
          userData['settings']?['alertFrequency'] ?? 'Daily Digest',
    };
  }

  /// Updates user and organization settings in Firestore.
  Future<void> updateUserAndOrgSettings({
    required List<String> domains,
    required List<String> ipRanges,
    required List<String> keywords,
    required String alertFrequency,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated.');
    }

    final userRef = firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final orgId = userDoc.data()?['orgId'] as String?;

    if (orgId == null) {
      throw Exception('Organization ID not found for user.');
    }

    final orgRef = firestore.collection('organizations').doc(orgId);

    // Use a batch write to update both documents.
    final batch = firestore.batch();

    batch.update(orgRef, {
      'domains': domains,
      'ipRanges': ipRanges,
      'keywords': keywords,
    });
    batch.update(userRef, {'settings.alertFrequency': alertFrequency});

    await batch.commit();
  }
}
