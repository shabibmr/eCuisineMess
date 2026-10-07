import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/models/update_info.dart';
import 'package:ecuisine_mess/core/services/app_update_service.dart';

enum UpdateState {
  prompt,
  downloading,
  readyToInstall,
  installing,
  error,
}

/// Dialog presenting optional or mandatory application updates with live download progress.
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final bool isMandatory;
  final String currentVersion;
  final AppUpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.isMandatory,
    required this.currentVersion,
    required this.updateService,
  });

  /// Static helper to display the update dialog.
  static Future<void> show(
    BuildContext context, {
    required UpdateCheckResult checkResult,
    AppUpdateService? updateService,
  }) async {
    if (!checkResult.hasUpdate || checkResult.updateInfo == null) return;

    final service = updateService ?? sl<AppUpdateService>();

    await showDialog(
      context: context,
      barrierDismissible: !checkResult.isMandatory,
      builder: (ctx) => PopScope(
        canPop: !checkResult.isMandatory,
        child: UpdateDialog(
          updateInfo: checkResult.updateInfo!,
          isMandatory: checkResult.isMandatory,
          currentVersion: checkResult.currentVersion,
          updateService: service,
        ),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateState _state = UpdateState.prompt;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  File? _downloadedFile;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    if (widget.isMandatory) {
      // For mandatory updates, automatically begin the download process
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDownload();
      });
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Dialog dismissed');
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = UpdateState.downloading;
      _progress = 0.0;
      _errorMessage = null;
      _cancelToken = CancelToken();
    });

    try {
      final file = await widget.updateService.downloadUpdate(
        updateInfo: widget.updateInfo,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
            if (total > 0) {
              _progress = received / total;
            }
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _downloadedFile = file;
        _state = UpdateState.readyToInstall;
      });

      // Auto-trigger installation
      await _install();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = UpdateState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _install() async {
    if (_downloadedFile == null) return;
    setState(() {
      _state = UpdateState.installing;
    });

    try {
      await widget.updateService.launchInstaller(
        _downloadedFile!,
        mandatory: widget.isMandatory,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = UpdateState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isMandatory
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isMandatory ? Icons.system_update_alt : Icons.cloud_download,
              color: widget.isMandatory
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isMandatory ? 'Mandatory Update Required' : 'Update Available',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'v${widget.currentVersion} ➔ v${widget.updateInfo.version}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            if (widget.isMandatory)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is critical to counter operations and cannot be skipped.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Release notes section
            if (widget.updateInfo.releaseNotes != null &&
                widget.updateInfo.releaseNotes!.isNotEmpty) ...[
              Text(
                "What's New:",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.updateInfo.releaseNotes!,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // State specific view
            if (_state == UpdateState.downloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _totalBytes > 0 ? _progress : null,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading update...',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _totalBytes > 0
                        ? '${(_progress * 100).toInt()}% (${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)})'
                        : _formatBytes(_receivedBytes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ] else if (_state == UpdateState.installing || _state == UpdateState.readyToInstall) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Launching installer. Application will restart shortly...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_state == UpdateState.error) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 20, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage ?? 'Update failed. Please try again.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_state == UpdateState.downloading) {
      if (widget.isMandatory) return const [];
      return [
        TextButton(
          onPressed: () {
            _cancelToken?.cancel('Cancelled by user');
            setState(() {
              _state = UpdateState.prompt;
            });
          },
          child: const Text('Cancel Download'),
        ),
      ];
    }

    if (_state == UpdateState.installing || _state == UpdateState.readyToInstall) {
      return const [];
    }

    if (_state == UpdateState.error) {
      return [
        if (!widget.isMandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ElevatedButton.icon(
          onPressed: _startDownload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ];
    }

    // Default Prompt State
    return [
      if (!widget.isMandatory)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip / Later'),
        ),
      ElevatedButton.icon(
        onPressed: _startDownload,
        icon: const Icon(Icons.download, size: 18),
        label: Text(widget.isMandatory ? 'Update Now' : 'Update & Restart'),
      ),
    ];
  }
}
