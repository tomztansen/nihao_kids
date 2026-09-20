import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

enum UpdateStatus {
  upToDate,
  forceUpdateRequired,
  optionalUpdateAvailable,
}

class UpdateInfo {
  final UpdateStatus status;
  final String latestVersion;
  final int latestBuildNumber;
  final String title;
  final String message;
  final String apkDownloadUrl;
  final String webDownloadPage;

  const UpdateInfo({
    required this.status,
    this.latestVersion = '',
    this.latestBuildNumber = 0,
    this.title = '',
    this.message = '',
    this.apkDownloadUrl = '',
    this.webDownloadPage = '',
  });

  factory UpdateInfo.noUpdate() => const UpdateInfo(status: UpdateStatus.upToDate);
  bool get isForceUpdate => status == UpdateStatus.forceUpdateRequired;
  bool get hasUpdate => status != UpdateStatus.upToDate;
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Memeriksa pembaruan versi ke server remote dengan batas waktu 3.5 detik (offline-safe)
  Future<UpdateInfo> checkForUpdate({String? customUrl}) async {
    final checkUrl = customUrl ?? AppConfig.versionCheckUrl;
    HttpClient? client;

    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(milliseconds: 3500);

      final uri = Uri.parse(checkUrl);
      final request = await client.getUrl(uri).timeout(const Duration(milliseconds: 3500));
      final response = await request.close().timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);

        final latestVersion = data['latest_version'] as String? ?? AppConfig.appVersion;
        final latestBuild = data['latest_build_number'] as int? ?? AppConfig.buildNumber;
        final minRequiredBuild = data['min_required_build_number'] as int? ?? AppConfig.buildNumber;
        final forceFlag = data['force_update'] as bool? ?? false;
        final title = data['title'] as String? ?? 'Pembaruan Aplikasi Tersedia! 🚀';
        final message = data['message'] as String? ?? 'Versi terbaru NiHao Kids telah tersedia. Silakan perbarui aplikasi Anda.';
        final apkUrl = data['apk_download_url'] as String? ?? AppConfig.fallbackApkUrl;
        final webUrl = data['web_download_page'] as String? ?? AppConfig.webDownloadPage;

        final currentBuild = AppConfig.buildNumber;

        if (currentBuild < minRequiredBuild || (currentBuild < latestBuild && forceFlag)) {
          return UpdateInfo(
            status: UpdateStatus.forceUpdateRequired,
            latestVersion: latestVersion,
            latestBuildNumber: latestBuild,
            title: title,
            message: message,
            apkDownloadUrl: apkUrl,
            webDownloadPage: webUrl,
          );
        } else if (currentBuild < latestBuild) {
          return UpdateInfo(
            status: UpdateStatus.optionalUpdateAvailable,
            latestVersion: latestVersion,
            latestBuildNumber: latestBuild,
            title: title,
            message: message,
            apkDownloadUrl: apkUrl,
            webDownloadPage: webUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('UpdateService check error (offline/timeout/safe): $e');
    } finally {
      client?.close();
    }

    return UpdateInfo.noUpdate();
  }

  /// Membuka tautan download APK atau browser external
  Future<bool> openUpdateUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
    return false;
  }
}
