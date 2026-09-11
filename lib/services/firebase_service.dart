import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  Object? _initializationError;

  bool get isConfigured => Firebase.apps.isNotEmpty;

  Object? get initializationError => _initializationError;

  Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    try {
      // TODO: Generate lib/firebase_options.dart with FlutterFire CLI and pass
      // DefaultFirebaseOptions.currentPlatform when real app configs are ready.
      await Firebase.initializeApp();
    } on FirebaseException catch (error) {
      _initializationError = error;
    } catch (error) {
      _initializationError = error;
    }
  }
}
