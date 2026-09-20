import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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

class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final bool isCompleted;
  final String? error;

  const DownloadProgress({
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.isCompleted = false,
    this.error,
  });

  String get receivedMB => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMB => totalBytes > 0 ? (totalBytes / (1024 * 1024)).toStringAsFixed(1) : '...';
  int get percent => (progress * 100).clamp(0, 100).toInt();
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

  /// Mengunduh file APK langsung di dalam aplikasi dengan streaming progress
  Stream<DownloadProgress> downloadApk({
    required String downloadUrl,
    String fileName = 'nihao_kids_update.apk',
  }) async* {
    HttpClient? client;
    IOSink? sink;
    File? tempFile;

    try {
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/$fileName');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      client = HttpClient()
        ..autoUncompress = true;

      // Ikuti pengalihan URL (GitHub Releases -> AWS/CDN)
      Uri targetUri = Uri.parse(downloadUrl);
      HttpClientRequest request = await client.getUrl(targetUri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      HttpClientResponse response = await request.close();

      while (response.isRedirect) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) break;
        targetUri = Uri.parse(location);
        request = await client.getUrl(targetUri);
        request.followRedirects = true;
        request.maxRedirects = 5;
        response = await request.close();
      }

      if (response.statusCode != 200) {
        yield DownloadProgress(
          error: 'Server mengembalikan status HTTP ${response.statusCode}',
        );
        return;
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;
      sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        yield DownloadProgress(
          progress: progress,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        );
      }

      await sink.flush();
      await sink.close();
      sink = null;

      yield DownloadProgress(
        progress: 1.0,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
        isCompleted: true,
      );
    } catch (e) {
      debugPrint('Error downloading update APK: $e');
      yield DownloadProgress(
        error: 'Gagal mengunduh pembaruan: $e',
      );
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close();
    }
  }

  /// Membuka file APK dan memicu pemasangan langsung (Android Package Installer)
  Future<OpenResult> installDownloadedApk({String fileName = 'nihao_kids_update.apk'}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      if (await file.exists()) {
        return await OpenFilex.open(
          file.path,
          type: 'application/vnd.android.package-archive',
        );
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
    }
    return OpenResult(type: ResultType.fileNotFound, message: 'File APK tidak ditemukan');
  }

  /// Membuka tautan download APK atau browser external (fallback)
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
