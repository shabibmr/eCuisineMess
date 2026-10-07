import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/repositories/organization_repository.dart';
import 'package:equatable/equatable.dart';

class SaveOrganization extends UseCase<void, SaveOrganizationParams> {
  SaveOrganization(this._repository);

  final OrganizationRepository _repository;

  @override
  Future<void> call(SaveOrganizationParams params) async {
    final org = Organization(
      id: params.id ?? '',
      orgName: params.orgName,
      trn: params.trn,
      address: params.address,
      addressToPrint: params.addressToPrint,
      addressToPrintArabic: params.addressToPrintArabic,
      currency: params.currency,
      phone: params.phone,
      email: params.email,
      contactPerson: params.contactPerson,
      website: params.website,
      notes: params.notes,
      isActive: params.isActive,
    );

    if (params.id == null || params.id!.isEmpty) {
      await _repository.createOrganization(org);
    } else {
      await _repository.updateOrganization(org);
    }
  }
}

class SaveOrganizationParams extends Equatable {
  const SaveOrganizationParams({
    this.id,
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

  final String? id;
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
