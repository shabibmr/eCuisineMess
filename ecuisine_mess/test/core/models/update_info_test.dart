import 'package:flutter_test/flutter_test.dart';
import 'package:ecuisine_mess/core/models/update_info.dart';

void main() {
  group('UpdateInfo SemVer comparison', () {
    test('isNewerThan returns true when major/minor/patch is higher', () {
      const update = UpdateInfo(
        version: '1.1.0',
        downloadUrl: 'https://vps.example.com/app.exe',
      );

      expect(update.isNewerThan(currentVersion: '1.0.0'), isTrue);
      expect(update.isNewerThan(currentVersion: '1.0.9'), isTrue);
      expect(update.isNewerThan(currentVersion: '1.1.0'), isFalse);
      expect(update.isNewerThan(currentVersion: '1.2.0'), isFalse);
      expect(update.isNewerThan(currentVersion: '2.0.0'), isFalse);
    });

    test('isNewerThan compares build numbers when version string matches', () {
      const update = UpdateInfo(
        version: '1.0.0',
        buildNumber: 5,
        downloadUrl: 'https://vps.example.com/app.exe',
      );

      expect(update.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 4), isTrue);
      expect(update.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 5), isFalse);
      expect(update.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 6), isFalse);
    });

    test('isNewerThan strips inline build numbers like +1', () {
      const update = UpdateInfo(
        version: '1.0.1+5',
        downloadUrl: 'https://vps.example.com/app.exe',
      );

      expect(update.isNewerThan(currentVersion: '1.0.0+9'), isTrue);
      expect(update.isNewerThan(currentVersion: '1.0.1+1'), isFalse);
    });

    test('isEnforcedFor honors mandatory flag and minimumSupportedVersion', () {
      const optionalUpdate = UpdateInfo(
        version: '1.2.0',
        mandatory: false,
        minimumSupportedVersion: '1.1.0',
        downloadUrl: 'https://vps.example.com/app.exe',
      );

      // Current is below minimum supported -> enforced
      expect(optionalUpdate.isEnforcedFor(currentVersion: '1.0.5'), isTrue);
      // Current is at or above minimum supported -> optional
      expect(optionalUpdate.isEnforcedFor(currentVersion: '1.1.0'), isFalse);
      expect(optionalUpdate.isEnforcedFor(currentVersion: '1.1.5'), isFalse);

      const mandatoryUpdate = UpdateInfo(
        version: '1.2.0',
        mandatory: true,
        downloadUrl: 'https://vps.example.com/app.exe',
      );
      expect(mandatoryUpdate.isEnforcedFor(currentVersion: '1.1.9'), isTrue);
    });

    test('fromMap parses map correctly with snake_case and camelCase', () {
      final map = {
        'version': '2.0.0',
        'build_number': 10,
        'mandatory': true,
        'download_url': 'https://vps.example.com/setup.exe',
        'file_name': 'setup.exe',
        'release_notes': 'New UI',
        'checksum_sha256': 'abc123sha',
        'minimum_supported_version': '1.5.0',
      };

      final update = UpdateInfo.fromMap(map);
      expect(update.version, '2.0.0');
      expect(update.buildNumber, 10);
      expect(update.mandatory, isTrue);
      expect(update.downloadUrl, 'https://vps.example.com/setup.exe');
      expect(update.fileName, 'setup.exe');
      expect(update.releaseNotes, 'New UI');
      expect(update.checksumSha256, 'abc123sha');
      expect(update.minimumSupportedVersion, '1.5.0');
    });
  });
}
