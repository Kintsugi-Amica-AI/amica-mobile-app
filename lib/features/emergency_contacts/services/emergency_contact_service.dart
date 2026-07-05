import '../models/emergency_contact.dart';

class EmergencyContactService {
  Future<List<EmergencyContact>> fetchContacts(String userId) async {
    // TODO: Read emergency contacts from Firestore.
    return const [];
  }

  Future<void> addContact(EmergencyContact contact) async {
    // TODO: Persist emergency contact in Firestore.
  }

  Future<void> removeContact(String contactId) async {
    // TODO: Remove emergency contact from Firestore.
  }
}
