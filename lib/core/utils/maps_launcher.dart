import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:du_xuan/core/constants/app_colors.dart';

/// Hỗ trợ mở ứng dụng bản đồ gốc (Google Maps / Apple Maps) để chỉ đường
class MapsLauncher {
  MapsLauncher._();

  /// Mở bản đồ bằng toạ độ lat/lng và có tên đánh dấu (label)
  static Future<void> launchCoordinates(
    BuildContext context,
    double lat,
    double lng, [
    String? label,
  ]) async {
    final messenger = ScaffoldMessenger.of(context);
    bool launched = false;

    // Build query cho map
    final query = label != null ? Uri.encodeComponent(label) : '$lat,$lng';

    if (Platform.isIOS) {
      // Thử mở Apple Maps trước trên iOS
      final appleMapsUrl = Uri.parse('http://maps.apple.com/?q=$query&ll=$lat,$lng');
      if (await canLaunchUrl(appleMapsUrl)) {
        launched = await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
    }

    // Nếu không phải iOS, hoặc Apple Maps lỗi → Fallback Google Maps
    if (!launched) {
      final googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(googleMapsUrl)) {
        launched = await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    }

    if (!launched) {
      _showError(messenger);
    }
  }

  /// Mở bản đồ bằng tên địa điểm (query string)
  static Future<void> launchQuery(BuildContext context, String queryText) async {
    final messenger = ScaffoldMessenger.of(context);
    final query = Uri.encodeComponent(queryText);
    bool launched = false;

    if (Platform.isIOS) {
      final appleMapsUrl = Uri.parse('http://maps.apple.com/?q=$query');
      if (await canLaunchUrl(appleMapsUrl)) {
        launched = await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
    }

    if (!launched) {
      final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(googleMapsUrl)) {
        launched = await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    }

    if (!launched) {
      _showError(messenger);
    }
  }

  static void _showError(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Không thể mở ứng dụng Bản đồ'),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
