// create class FirebaseErrorsCode to handle firebase errors
class FirebaseErrorsCode {
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'The provided credential is invalid. Please check your  information and try again.';

      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An unknown error occurred. Please try again later.';
    }
  }
}
