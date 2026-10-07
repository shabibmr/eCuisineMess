import 'package:ecuisine_mess/features/organizations/data/models/organization_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrganizationModel Tests', () {
    test('fromJson and toEntity correctly map all organization fields', () {
      final json = {
        'id': 'org-123',
        'org_name': 'DIT UAE',
        'trn': '100200300400003',
        'address': 'Dubai Investment Park',
        'address_to_print': 'DIT UAE Header En',
        'address_to_print_arabic': 'دي آي تي عربي',
        'currency': 'AED',
        'phone': '+971 4 123 4567',
        'email': 'catering@dituae.com',
        'contact_person': 'Mess Manager',
        'website': 'https://dituae.com',
        'notes': 'Main catering contractor',
        'is_active': 1,
      };

      final model = OrganizationModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.id, 'org-123');
      expect(entity.orgName, 'DIT UAE');
      expect(entity.trn, '100200300400003');
      expect(entity.address, 'Dubai Investment Park');
      expect(entity.addressToPrint, 'DIT UAE Header En');
      expect(entity.addressToPrintArabic, 'دي آي تي عربي');
      expect(entity.currency, 'AED');
      expect(entity.phone, '+971 4 123 4567');
      expect(entity.email, 'catering@dituae.com');
      expect(entity.contactPerson, 'Mess Manager');
      expect(entity.website, 'https://dituae.com');
      expect(entity.notes, 'Main catering contractor');
      expect(entity.isActive, isTrue);
    });

    test('toCreateJson produces expected backend payload', () {
      const model = OrganizationModel(
        id: '',
        orgName: 'New Org',
        trn: 'TRN-999',
        currency: 'USD',
        addressToPrint: 'Print En',
        addressToPrintArabic: 'طباعة عربي',
        isActive: true,
      );

      final json = model.toCreateJson();
      expect(json['org_name'], 'New Org');
      expect(json['trn'], 'TRN-999');
      expect(json['currency'], 'USD');
      expect(json['address_to_print'], 'Print En');
      expect(json['address_to_print_arabic'], 'طباعة عربي');
      expect(json['is_active'], 1);
    });

    test('fromEntity reconstructs model matching original', () {
      final initialModel = OrganizationModel.fromJson({
        'id': 'org-test',
        'org_name': 'Test Entity',
        'currency': 'EUR',
        'is_active': 1,
      });

      final entity = initialModel.toEntity();
      final reconstructed = OrganizationModel.fromEntity(entity);

      expect(reconstructed.id, entity.id);
      expect(reconstructed.orgName, entity.orgName);
      expect(reconstructed.currency, 'EUR');
      expect(reconstructed.isActive, isTrue);
    });
  });
}
