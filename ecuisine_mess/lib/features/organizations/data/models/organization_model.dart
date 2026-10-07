import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';

class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.orgName,
    this.trn,
    this.address,
    this.addressToPrint,
    this.addressToPrintArabic,
    this.currency = 'AED',
    this.phone,
    this.email,
    this.contactPerson,
    this.website,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String orgName;
  final String? trn;
  final String? address;
  final String? addressToPrint;
  final String? addressToPrintArabic;
  final String currency;
  final String? phone;
  final String? email;
  final String? contactPerson;
  final String? website;
  final String? notes;
  final bool isActive;

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      orgName: json['org_name']?.toString() ?? '',
      trn: json['trn']?.toString(),
      address: json['address']?.toString(),
      addressToPrint: json['address_to_print']?.toString(),
      addressToPrintArabic: json['address_to_print_arabic']?.toString(),
      currency: json['currency']?.toString() ?? 'AED',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      website: json['website']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'org_name': orgName,
        'trn': trn,
        'address': address,
        'address_to_print': addressToPrint,
        'address_to_print_arabic': addressToPrintArabic,
        'currency': currency,
        'phone': phone,
        'email': email,
        'contact_person': contactPerson,
        'website': website,
        'notes': notes,
        'is_active': isActive ? 1 : 0,
      };

  Map<String, dynamic> toUpdateJson() => {
        'org_name': orgName,
        'trn': trn,
        'address': address,
        'address_to_print': addressToPrint,
        'address_to_print_arabic': addressToPrintArabic,
        'currency': currency,
        'phone': phone,
        'email': email,
        'contact_person': contactPerson,
        'website': website,
        'notes': notes,
        'is_active': isActive ? 1 : 0,
      };

  Organization toEntity() => Organization(
        id: id,
        orgName: orgName,
        trn: trn,
        address: address,
        addressToPrint: addressToPrint,
        addressToPrintArabic: addressToPrintArabic,
        currency: currency,
        phone: phone,
        email: email,
        contactPerson: contactPerson,
        website: website,
        notes: notes,
        isActive: isActive,
      );

  factory OrganizationModel.fromEntity(Organization entity) =>
      OrganizationModel(
        id: entity.id,
        orgName: entity.orgName,
        trn: entity.trn,
        address: entity.address,
        addressToPrint: entity.addressToPrint,
        addressToPrintArabic: entity.addressToPrintArabic,
        currency: entity.currency,
        phone: entity.phone,
        email: entity.email,
        contactPerson: entity.contactPerson,
        website: entity.website,
        notes: entity.notes,
        isActive: entity.isActive,
      );
}
