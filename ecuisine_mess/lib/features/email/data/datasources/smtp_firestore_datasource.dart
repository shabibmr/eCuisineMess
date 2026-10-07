import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/features/email/data/models/smtp_settings_model.dart';
import 'package:logger/logger.dart';

abstract class SmtpFirestoreDataSource {
  Future<SmtpSettingsModel> getSmtpSettings({String? projectId});
  Future<void> saveSmtpSettings(SmtpSettingsModel model, {String? projectId});
}

/// Direct client Firestore datasource using the standard Google Cloud Firestore REST API.
/// Works uniformly across Windows Desktop, Web, Android, iOS, macOS, and Linux
/// without native platform plugin compilation dependencies.
class SmtpFirestoreDataSourceImpl implements SmtpFirestoreDataSource {
  SmtpFirestoreDataSourceImpl({
    Dio? dioClient,
    Logger? logger,
  })  : _dio = dioClient ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        )),
        _logger = logger ?? Logger();

  final Dio _dio;
  final Logger _logger;

  String _buildDocUrl(String projectId) {
    return 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/${AppConstants.firestoreSmtpDocPath}';
  }

  @override
  Future<SmtpSettingsModel> getSmtpSettings({String? projectId}) async {
    final effectiveProjectId = (projectId?.trim().isNotEmpty == true)
        ? projectId!.trim()
        : AppConstants.defaultFirebaseProjectId;

    final url = _buildDocUrl(effectiveProjectId);
    _logger.d('Fetching SMTP settings from Firestore at $url');

    try {
      final response = await _dio.get<Map<String, dynamic>>(url);
      if (response.data != null) {
        return SmtpSettingsModel.fromFirestore(
          response.data!,
          firebaseProjectId: effectiveProjectId,
        );
      }
      return SmtpSettingsModel(firebaseProjectId: effectiveProjectId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.i('Firestore document settings/smtp not found; using defaults.');
        return SmtpSettingsModel(firebaseProjectId: effectiveProjectId);
      }
      _logger.w('Failed to fetch SMTP settings from Firestore: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error reading from Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveSmtpSettings(
    SmtpSettingsModel model, {
    String? projectId,
  }) async {
    final effectiveProjectId = (projectId?.trim().isNotEmpty == true)
        ? projectId!.trim()
        : (model.firebaseProjectId.trim().isNotEmpty
            ? model.firebaseProjectId.trim()
            : AppConstants.defaultFirebaseProjectId);

    final url = _buildDocUrl(effectiveProjectId);
    _logger.i('Saving SMTP settings to Firestore at $url');

    try {
      await _dio.patch(
        url,
        data: model.toFirestoreFields(),
      );
      _logger.i('Successfully saved SMTP settings to Firestore.');
    } on DioException catch (e) {
      _logger.e('Failed to save SMTP settings to Firestore: ${e.message}');
      rethrow;
    }
  }
}
