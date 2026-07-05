class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  bool get isConfigured => false;

  Future<void> initialize() async {
    // TODO: Initialize Firebase after platform config files are available.
  }
}
