import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
  });

  test('FirestoreService delegates collection and doc references', () {
    when(() => mockFirestore.collection('test_coll')).thenReturn(mockCollection);
    when(() => mockFirestore.doc('test_coll/item1')).thenReturn(mockDoc);

    final service = FirestoreService(firestore: mockFirestore);

    expect(service.collection('test_coll'), equals(mockCollection));
    expect(service.doc('test_coll/item1'), equals(mockDoc));
    expect(service.firestore, equals(mockFirestore));
  });

  test('configureDependencies registers Firestore and FirestoreService with DI',
      () async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await configureDependencies(firestore: mockFirestore);

    expect(sl.isRegistered<FirebaseFirestore>(), isTrue);
    expect(sl.isRegistered<FirestoreService>(), isTrue);
    expect(sl<FirestoreService>().firestore, equals(mockFirestore));

    await sl.reset();
  });
}
