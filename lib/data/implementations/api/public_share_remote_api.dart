import 'dart:convert';

import 'package:du_xuan/core/constants/api_constants.dart';
import 'package:du_xuan/data/dtos/share/create_public_share_request_dto.dart';
import 'package:du_xuan/data/dtos/share/public_share_response_dto.dart';
import 'package:du_xuan/data/dtos/share/update_public_share_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_public_share_remote_api.dart';
import 'package:du_xuan/domain/entities/public_share_link.dart';
import 'package:http/http.dart' as http;

class PublicShareRemoteApi implements IPublicShareRemoteApi {
  final http.Client _client;

  PublicShareRemoteApi({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<PublicShareResponseDto> create(CreatePublicShareRequestDto req) async {
    _ensureConfigured();

    final response = await _client
        .post(
          Uri.parse(_url('/public-shares')),
          headers: _jsonHeaders(),
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  @override
  Future<PublicShareResponseDto> update(
    PublicShareLink link,
    UpdatePublicShareRequestDto req,
  ) async {
    _ensureConfigured();

    final response = await _client
        .put(
          Uri.parse(
            _url('/public-shares/${Uri.encodeComponent(link.shareId)}'),
          ),
          headers: _jsonHeaders(ownerToken: link.ownerToken),
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    final dto = _decodeResponse(response);
    return PublicShareResponseDto(
      shareId: dto.shareId,
      slug: dto.slug,
      publicUrl: dto.publicUrl,
      ownerToken: dto.ownerToken.isNotEmpty ? dto.ownerToken : link.ownerToken,
      snapshotVersion: dto.snapshotVersion,
    );
  }

  @override
  Future<void> revoke(PublicShareLink link) async {
    _ensureConfigured();

    final response = await _client
        .delete(
          Uri.parse(
            _url('/public-shares/${Uri.encodeComponent(link.shareId)}'),
          ),
          headers: _jsonHeaders(ownerToken: link.ownerToken),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  void _ensureConfigured() {
    if (!ApiConstants.hasPublicShareApi) {
      throw Exception('Chưa cấu hình PUBLIC_SHARE_API_URL cho bản build này.');
    }
  }

  String _url(String path) {
    final base = ApiConstants.publicShareApiBaseUrl.trim().replaceAll(
      RegExp(r'/$'),
      '',
    );
    return '$base$path';
  }

  Map<String, String> _jsonHeaders({String? ownerToken}) {
    return {
      'Content-Type': 'application/json',
      if (ownerToken != null && ownerToken.trim().isNotEmpty)
        'X-Owner-Token': ownerToken,
    };
  }

  PublicShareResponseDto _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Public share API trả về dữ liệu không hợp lệ.');
    }

    return PublicShareResponseDto.fromJson(decoded);
  }

  String _extractErrorMessage(String responseBody, int statusCode) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error =
            decoded['error'] ??
            decoded['message'] ??
            decoded['detail'] ??
            decoded['errors'];
        if (error != null) {
          return error.toString();
        }
      }
    } catch (_) {
      // Fall back to generic message.
    }

    return 'Public share error ($statusCode)';
  }
}
