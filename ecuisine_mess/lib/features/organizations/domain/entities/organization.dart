import 'package:equatable/equatable.dart';

class Organization extends Equatable {
  const Organization({
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

  @override
  List<Object?> get props => [
        id,
        orgName,
        trn,
        address,
        addressToPrint,
        addressToPrintArabic,
        currency,
        phone,
        email,
        contactPerson,
        website,
        notes,
        isActive,
      ];
}
