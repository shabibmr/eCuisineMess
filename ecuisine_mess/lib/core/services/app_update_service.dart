import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ecuisine_mess/core/models/update_info.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';

/// Result of checking for available application updates.
class UpdateCheckResult {
  final bool hasUpdate;
  final bool isMandatory;
  final String currentVersion;
  final int? currentBuildNumber;
  final UpdateInfo? updateInfo;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.isMandatory,
    required this.currentVersion,
    this.currentBuildNumber,
    this.updateInfo,
    this.errorMessage,
  });

  factory UpdateCheckResult.noUpdate({
    required String currentVersion,
    int? currentBuildNumber,
  }) =>
      UpdateCheckResult(
        hasUpdate: false,
        isMandatory: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
      );

  factory UpdateCheckResult.available({
    required String currentVersion,
    int? currentBuildNumber,
    required UpdateInfo updateInfo,
  }) =>
      UpdateCheckResult(
        hasUpdate: true,
        isMandatory: updateInfo.isEnforcedFor(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
        ),
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        updateInfo: updateInfo,
      );

  factory UpdateCheckResult.error({
    required String currentVersion,
    int? currentBuildNumber,
    required String errorMessage,
  }) =>
      UpdateCheckResult(
        hasUpdate: false,
        isMandatory: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        errorMessage: errorMessage,
      );
}

/// Service handling version checks against Cloud Firestore, installer download,
/// checksum verification, and detached process execution.
class AppUpdateService {
  final FirestoreService _firestoreService;
  final Dio _dio;
  final Logger _logger;
  final String collectionPath;

  AppUpdateService({
    required FirestoreService firestoreService,
    Dio? dio,
    Logger? logger,
    this.collectionPath = 'app_updates',
  })  : _firestoreService = firestoreService,
        _dio = dio ?? Dio(),
        _logger = logger ?? Logger();

  /// Returns the target Firestore document ID according to the current host platform.
  String get platformDocId {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows_frontend';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'default';
  }

  /// Checks Firestore for updates against current platform and installed app version.
  Future<UpdateCheckResult> checkForUpdate({
    String? docId,
    String? overrideCurrentVersion,
    int? overrideCurrentBuildNumber,
  }) async {
    String currentVersion = overrideCurrentVersion ?? '1.0.0';
    int? currentBuild = overrideCurrentBuildNumber;

    if (overrideCurrentVersion == null) {
      try {
        final pkg = await PackageInfo.fromPlatform();
        currentVersion = pkg.version;
        currentBuild = int.tryParse(pkg.buildNumber);
      } catch (e) {
        _logger.w('Failed to resolve PackageInfo from platform: $e. Falling back to default.');
      }
    }

    final targetDocId = docId ?? platformDocId;

    try {
      _logger.i('Checking updates for doc: $collectionPath/$targetDocId (current: $currentVersion+$currentBuild)');
      final snapshot = await _firestoreService.getDoc(collectionPath, targetDocId);

      if (!snapshot.exists || snapshot.data() == null) {
        _logger.d('No update document found at $collectionPath/$targetDocId');
        return UpdateCheckResult.noUpdate(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
        );
      }

      final data = snapshot.data()!;
      final updateInfo = UpdateInfo.fromMap(data);

      if (updateInfo.downloadUrl.isEmpty || updateInfo.version.isEmpty) {
        return UpdateCheckResult.noUpdate(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
        );
      }

      final isNewer = updateInfo.isNewerThan(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
      );

      if (isNewer) {
        _logger.i('Newer update detected: ${updateInfo.version} (current: $currentVersion)');
        return UpdateCheckResult.available(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
          updateInfo: updateInfo,
        );
      } else {
        _logger.d('App is up to date ($currentVersion)');
        return UpdateCheckResult.noUpdate(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
        );
      }
    } catch (e, st) {
      _logger.e('Error during update check: $e', error: e, stackTrace: st);
      return UpdateCheckResult.error(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        errorMessage: e.toString(),
      );
    }
  }

  /// Downloads the update package into a temporary staging folder.
  Future<File> downloadUpdate({
    required UpdateInfo updateInfo,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final stagingDir = Directory(p.join(tempDir.path, 'ecuisine_mess_update'));
    if (!await stagingDir.exists()) {
      await stagingDir.create(recursive: true);
    }

    // Determine target file name
    String fileName = updateInfo.fileName?.trim() ?? '';
    if (fileName.isEmpty) {
      final uri = Uri.tryParse(updateInfo.downloadUrl);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        fileName = uri.pathSegments.last;
      }
    }
    if (fileName.isEmpty) {
      fileName = Platform.isAndroid ? 'ecuisine_mess_update.apk' : 'ecuisine_mess_setup.exe';
    }

    final targetFile = File(p.join(stagingDir.path, fileName));
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    _logger.i('Downloading update from ${updateInfo.downloadUrl} to ${targetFile.path}');

    await _dio.download(
      updateInfo.downloadUrl,
      targetFile.path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        onProgress(received, total);
      },
    );

    // Verify Checksum if provided
    if (updateInfo.checksumSha256 != null && updateInfo.checksumSha256!.isNotEmpty) {
      final isValid = await verifyChecksum(targetFile, updateInfo.checksumSha256!);
      if (!isValid) {
        await targetFile.delete();
        throw Exception('SHA-256 checksum mismatch! The downloaded update file may be corrupt.');
      }
    }

    return targetFile;
  }

  /// Validates the SHA-256 checksum of the downloaded file.
  Future<bool> verifyChecksum(File file, String expectedSha256) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final calculated = digest.toString().toLowerCase();
      final expected = expectedSha256.trim().toLowerCase();
      final matches = calculated == expected;
      if (!matches) {
        _logger.w('Checksum mismatch: expected $expected, got $calculated');
      }
      return matches;
    } catch (e) {
      _logger.e('Failed to verify checksum: $e');
      return false;
    }
  }

  /// Triggers the appropriate platform-specific installation handoff.
  Future<void> launchInstaller(File file, {bool mandatory = false}) async {
    if (kIsWeb) {
      throw UnsupportedError('Auto-update installer execution is not supported on Web.');
    }

    if (Platform.isWindows) {
      await _launchWindowsInstaller(file, mandatory: mandatory);
    } else if (Platform.isAndroid) {
      await _launchAndroidInstaller(file);
    } else {
      throw UnsupportedError('Auto-update installer not supported on ${Platform.operatingSystem}');
    }
  }

  Future<void> _launchWindowsInstaller(File file, {required bool mandatory}) async {
    final ext = p.extension(file.path).toLowerCase();
    _logger.i('Launching Windows installer (${file.path}, mandatory: $mandatory)');

    if (ext == '.exe') {
      final args = mandatory
          ? ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART']
          : <String>[];

      await Process.start(
        file.path,
        args,
        mode: ProcessStartMode.detached,
        runInShell: true,
      );

      // Clean exit to release Windows file locks
      _logger.i('Exiting application for installer handoff.');
      exit(0);
    } else {
      throw UnsupportedError('Unsupported Windows package format ($ext). Use an Inno Setup .exe installer.');
    }
  }

  Future<void> _launchAndroidInstaller(File file) async {
    _logger.i('Triggering Android Package Installer for: ${file.path}');
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    _logger.d('OpenFilex result: ${result.type} - ${result.message}');
  }
}
