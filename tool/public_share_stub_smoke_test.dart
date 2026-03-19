import 'dart:convert';
import 'dart:io';

import 'public_share_stub_server.dart';

Future<void> main() async {
  final storageFile = File('.public_share_stub/test_public_shares.json');
  if (await storageFile.exists()) {
    await storageFile.delete();
  }

  final server = await startPublicShareStubServer(
    host: '127.0.0.1',
    port: 0,
    storageFile: storageFile,
  );

  final baseUrl = 'http://127.0.0.1:${server.port}';

  try {
    final createPayload = {
      'title': 'Hành hương Chùa Bà Vàng 1 ngày',
      'snapshotVersion': 1,
      'snapshot': _sampleSnapshot(),
    };

    final created = await _requestJson(
      method: 'POST',
      uri: Uri.parse('$baseUrl/public-shares'),
      body: createPayload,
    );
    final shareId = created['shareId']?.toString() ?? '';
    final slug = created['slug']?.toString() ?? '';
    final ownerToken = created['ownerToken']?.toString() ?? '';
    if (shareId.isEmpty || slug.isEmpty || ownerToken.isEmpty) {
      throw StateError('Create response is missing required fields.');
    }

    final publicJson = await _requestJson(
      method: 'GET',
      uri: Uri.parse('$baseUrl/public-shares/$slug'),
    );
    if ((publicJson['title'] ?? '') != 'Hành hương Chùa Bà Vàng 1 ngày') {
      throw StateError('Public JSON returned unexpected title.');
    }

    final publicHtml = await _requestText(
      method: 'GET',
      uri: Uri.parse('$baseUrl/s/$slug'),
    );
    if (!publicHtml.contains('DU XUÂN PLANNER') ||
        !publicHtml.contains('Hành hương Chùa Bà Vàng 1 ngày')) {
      throw StateError('Public page did not render expected content.');
    }

    final updated = await _requestJson(
      method: 'PUT',
      uri: Uri.parse('$baseUrl/public-shares/$shareId'),
      headers: {'X-Owner-Token': ownerToken},
      body: {
        'title': 'Hành hương cập nhật',
        'snapshotVersion': 1,
        'snapshot': {
          ..._sampleSnapshot(),
          'plan': {
            ...(_sampleSnapshot()['plan'] as Map<String, dynamic>),
            'name': 'Hành hương cập nhật',
          },
        },
      },
    );
    if ((updated['shareId'] ?? '') != shareId) {
      throw StateError('Update response returned unexpected shareId.');
    }

    await _requestJson(
      method: 'DELETE',
      uri: Uri.parse('$baseUrl/public-shares/$shareId'),
      headers: {'X-Owner-Token': ownerToken},
    );

    final revokedStatus = await _requestStatus(
      method: 'GET',
      uri: Uri.parse('$baseUrl/public-shares/$slug'),
    );
    if (revokedStatus != HttpStatus.gone) {
      throw StateError('Expected revoked public share to return 410.');
    }

    stdout.writeln('Public share stub smoke test passed.');
  } finally {
    await server.close(force: true);
    if (await storageFile.exists()) {
      await storageFile.delete();
    }
  }
}

Map<String, dynamic> _sampleSnapshot() => {
  'version': 1,
  'generatedAt': DateTime.now().toIso8601String(),
  'plan': {
    'id': 1,
    'name': 'Hành hương Chùa Bà Vàng 1 ngày',
    'displayDate': 'Thứ Ba, 17/03/2026',
    'displayDayCount': '1 ngày',
    'participants': '2 người',
    'description': 'Chuẩn bị khởi hành đầu năm.',
  },
  'overview': {
    'displayEstimatedTotal': '1.100.000đ',
    'displayActualTotal': '302.548đ',
    'displayVariance': '-797.452đ',
  },
  'days': [
    {
      'id': 1,
      'dayNumber': 1,
      'displayDate': '17/03/2026',
      'activities': [
        {
          'title': 'Di chuyển đến Chùa Bà Vàng',
          'timeLabel': '06:00 - 07:00',
          'typeLabel': 'Di chuyển',
          'locationText': 'Ba Vang Pagoda',
          'displayEstimatedCost': '500.000đ',
          'note': null,
        },
      ],
    },
  ],
  'expenseGroups': [
    {
      'title': 'Ngày 1',
      'displayTotalAmount': '302.548đ',
      'items': [
        {'title': 'Vé xe', 'displayAmount': '200.000đ', 'note': null},
        {'title': 'Ăn sáng', 'displayAmount': '102.548đ', 'note': null},
      ],
    },
  ],
  'checklistGroups': [
    {
      'categoryLabel': 'Đồ ăn',
      'itemCount': 1,
      'items': [
        {'name': 'Nước uống', 'quantity': 2, 'note': null},
      ],
    },
  ],
};

Future<Map<String, dynamic>> _requestJson({
  required String method,
  required Uri uri,
  Map<String, String>? headers,
  Object? body,
}) async {
  final response = await _request(
    method: method,
    uri: uri,
    headers: headers,
    body: body,
  );
  final payload = jsonDecode(response.body);
  if (payload is! Map<String, dynamic>) {
    throw StateError('Expected JSON object response from $uri.');
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'HTTP ${response.statusCode}: ${response.body}',
      uri: uri,
    );
  }
  return payload;
}

Future<String> _requestText({
  required String method,
  required Uri uri,
  Map<String, String>? headers,
  Object? body,
}) async {
  final response = await _request(
    method: method,
    uri: uri,
    headers: headers,
    body: body,
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'HTTP ${response.statusCode}: ${response.body}',
      uri: uri,
    );
  }
  return response.body;
}

Future<int> _requestStatus({
  required String method,
  required Uri uri,
  Map<String, String>? headers,
  Object? body,
}) async {
  final response = await _request(
    method: method,
    uri: uri,
    headers: headers,
    body: body,
  );
  return response.statusCode;
}

Future<_SimpleResponse> _request({
  required String method,
  required Uri uri,
  Map<String, String>? headers,
  Object? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers?.forEach(request.headers.set);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    return _SimpleResponse(response.statusCode, responseBody);
  } finally {
    client.close(force: true);
  }
}

class _SimpleResponse {
  final int statusCode;
  final String body;

  const _SimpleResponse(this.statusCode, this.body);
}
