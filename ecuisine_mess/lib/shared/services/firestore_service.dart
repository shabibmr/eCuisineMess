import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// Service providing typed helper methods and access to Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  FirestoreService({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  /// Direct access to the underlying [FirebaseFirestore] instance.
  FirebaseFirestore get firestore => _firestore;

  /// Get reference to a collection.
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get reference to a document.
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  /// Fetch a document once by collection path and document ID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    String collectionPath,
    String docId,
  ) async {
    try {
      return await _firestore.collection(collectionPath).doc(docId).get();
    } catch (e, st) {
      _logger.e('Firestore getDoc error [$collectionPath/$docId]: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Set document data with optional merge support.
  Future<void> setDoc(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e, st) {
      _logger.e('Firestore setDoc error [$collectionPath/$docId]: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Add a new document with an auto-generated ID.
  Future<DocumentReference<Map<String, dynamic>>> addDoc(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _firestore.collection(collectionPath).add(data);
    } catch (e, st) {
      _logger.e('Firestore addDoc error [$collectionPath]: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Update fields in an existing document.
  Future<void> updateDoc(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e, st) {
      _logger.e('Firestore updateDoc error [$collectionPath/$docId]: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Delete a document.
  Future<void> deleteDoc(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e, st) {
      _logger.e('Firestore deleteDoc error [$collectionPath/$docId]: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Stream updates from a collection query.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }

  /// Stream updates from a single document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(
    String collectionPath,
    String docId,
  ) {
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }
}
