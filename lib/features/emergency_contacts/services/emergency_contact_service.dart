import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_contact.dart';

class EmergencyContactServiceException implements Exception {
  const EmergencyContactServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmergencyContactService {
  const EmergencyContactService();

  static const String _collectionName = 'emergency_contacts';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<List<EmergencyContact>> watchEmergencyContacts() {
    final user = _currentUserOrNull;
    if (user == null) {
      return Stream<List<EmergencyContact>>.error(
        const EmergencyContactServiceException(
          'Please log in to view emergency contacts.',
        ),
      );
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final contacts = snapshot.docs
          .map(
            (doc) => EmergencyContact.fromFirestore(doc),
          )
          .toList();

      contacts.sort((a, b) {
        final priorityCompare = a.priority.compareTo(b.priority);
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return contacts;
    });
  }

  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    String relationship = '',
    int priority = 1,
  }) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc();

    await document.set({
      'id': document.id,
      'userId': user.uid,
      'name': name.trim(),
      'phone': phone.trim(),
      'relationship': relationship.trim(),
      'priority': priority,
      'isActive': true,
      'notificationMethods': const ['sms'],
      'metadata': const <String, dynamic>{},
      'schemaVersion': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    final user = _currentUserOrThrow();
    if (contact.userId != user.uid) {
      throw const EmergencyContactServiceException(
        'You can only update your own emergency contacts.',
      );
    }

    await _firestore.collection(_collectionName).doc(contact.id).update({
      'name': contact.name.trim(),
      'phone': contact.phone.trim(),
      'relationship': contact.relationship.trim(),
      'priority': contact.priority,
      'isActive': contact.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc(contactId);
    final snapshot = await document.get();

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();
    if (data == null || data['userId'] != user.uid) {
      throw const EmergencyContactServiceException(
        'You can only delete your own emergency contacts.',
      );
    }

    await document.delete();
  }

  Future<void> setContactActive(String contactId, bool isActive) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc(contactId);
    final snapshot = await document.get();

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();
    if (data == null || data['userId'] != user.uid) {
      throw const EmergencyContactServiceException(
        'You can only update your own emergency contacts.',
      );
    }

    await document.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  User? get _currentUserOrNull => _auth.currentUser;

  User _currentUserOrThrow() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmergencyContactServiceException(
        'Please log in to manage emergency contacts.',
      );
    }
    return user;
  }
}
