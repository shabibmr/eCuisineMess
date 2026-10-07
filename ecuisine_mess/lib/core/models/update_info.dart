import 'package:equatable/equatable.dart';

/// Represents update metadata retrieved from Firestore.
class UpdateInfo extends Equatable {
  final String version;
  final int? buildNumber;
  final bool mandatory;
  final String downloadUrl;
  final String? fileName;
  final String? releaseNotes;
  final String? checksumSha256;
  final String? minimumSupportedVersion;
  final DateTime? releasedAt;

  const UpdateInfo({
    required this.version,
    this.buildNumber,
    this.mandatory = false,
    required this.downloadUrl,
    this.fileName,
    this.releaseNotes,
    this.checksumSha256,
    this.minimumSupportedVersion,
    this.releasedAt,
  });

  factory UpdateInfo.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    final rawDate = map['released_at'] ?? map['releasedAt'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        parsedDate = rawDate;
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      } else {
        // Handle Cloud Firestore Timestamp or dynamic types
        try {
          parsedDate = (rawDate as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
    }

    int? parsedBuildNumber;
    final rawBuild = map['build_number'] ?? map['buildNumber'];
    if (rawBuild != null) {
      parsedBuildNumber = rawBuild is int ? rawBuild : int.tryParse(rawBuild.toString());
    }

    return UpdateInfo(
      version: (map['version'] ?? '').toString().trim(),
      buildNumber: parsedBuildNumber,
      mandatory: map['mandatory'] == true || map['is_mandatory'] == true,
      downloadUrl: (map['download_url'] ?? map['downloadUrl'] ?? '').toString().trim(),
      fileName: (map['file_name'] ?? map['fileName'])?.toString().trim(),
      releaseNotes: (map['release_notes'] ?? map['releaseNotes'])?.toString(),
      checksumSha256: (map['checksum_sha256'] ?? map['checksum'])?.toString().trim(),
      minimumSupportedVersion: (map['minimum_supported_version'] ?? map['min_supported_version'])?.toString().trim(),
      releasedAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'build_number': buildNumber,
      'mandatory': mandatory,
      'download_url': downloadUrl,
      'file_name': fileName,
      'release_notes': releaseNotes,
      'checksum_sha256': checksumSha256,
      'minimum_supported_version': minimumSupportedVersion,
      'released_at': releasedAt?.toIso8601String(),
    };
  }

  /// Compares this remote version against the local [currentVersion] and [currentBuildNumber].
  /// Returns `true` if this update is newer.
  bool isNewerThan({
    required String currentVersion,
    int? currentBuildNumber,
  }) {
    // Clean versions of build suffixes like +1
    final remoteClean = _cleanVersion(version);
    final localClean = _cleanVersion(currentVersion);

    final cmp = _compareSemVer(remoteClean, localClean);
    if (cmp > 0) return true;
    if (cmp < 0) return false;

    // Versions are identical, compare build numbers if remote has one
    if (buildNumber != null && currentBuildNumber != null) {
      return buildNumber! > currentBuildNumber;
    }

    return false;
  }

  /// Determines whether the update must be enforced strictly without allow-skipping.
  bool isEnforcedFor({
    required String currentVersion,
    int? currentBuildNumber,
  }) {
    if (mandatory) return true;
    if (minimumSupportedVersion != null && minimumSupportedVersion!.isNotEmpty) {
      final minClean = _cleanVersion(minimumSupportedVersion!);
      final localClean = _cleanVersion(currentVersion);
      if (_compareSemVer(localClean, minClean) < 0) {
        return true;
      }
    }
    return false;
  }

  static String _cleanVersion(String v) {
    final plusIndex = v.indexOf('+');
    return plusIndex != -1 ? v.substring(0, plusIndex).trim() : v.trim();
  }

  static int _compareSemVer(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  @override
  List<Object?> get props => [
        version,
        buildNumber,
        mandatory,
        downloadUrl,
        fileName,
        releaseNotes,
        checksumSha256,
        minimumSupportedVersion,
        releasedAt,
      ];
}
