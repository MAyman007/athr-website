import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:athr/core/services/firebase_service.dart';
import 'package:athr/core/locator.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = locator<FirebaseService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordObscured = true;
  bool get isPasswordObscured => _isPasswordObscured;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // State for the form
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    _isPasswordObscured = !_isPasswordObscured;
    notifyListeners();
  }

  Future<bool> login() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      _isLoading = false;
      notifyListeners();
      return true; // Success
    } on FirebaseAuthException catch (e) {
      // 'invalid-credential' is a common error for wrong email or password.
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        _errorMessage = 'Invalid credentials. Please try again.';
      } else {
        _errorMessage = 'An error occurred. Please check your credentials.';
      }
      _isLoading = false;
      notifyListeners();
      return false; // Failure
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
      throw 'Could not launch $url';
    }
  }
}
