import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main() async {
  final host = Platform.environment['PUBLIC_SHARE_STUB_HOST'] ?? '0.0.0.0';
  final port =
      int.tryParse(Platform.environment['PUBLIC_SHARE_STUB_PORT'] ?? '8787') ??
      8787;
  final publicBaseUrl = Platform.environment['PUBLIC_SHARE_PUBLIC_BASE_URL'];

  await startPublicShareStubServer(
    host: host,
    port: port,
    publicBaseUrl: publicBaseUrl,
    storageFile: File('.public_share_stub/public_shares.json'),
    logStartup: true,
  );
}

Future<HttpServer> startPublicShareStubServer({
  String host = '0.0.0.0',
  int port = 8787,
  String? publicBaseUrl,
  File? storageFile,
  bool logStartup = false,
}) async {
  final store = _PublicShareStore(
    file: storageFile ?? File('.public_share_stub/public_shares.json'),
  );
  await store.init();

  final server = await HttpServer.bind(host, port);
  unawaited(_serveLoop(server, store, publicBaseUrl: publicBaseUrl));

  if (logStartup) {
    stdout.writeln(
      'Public share stub is running on http://localhost:${server.port}',
    );
    stdout.writeln(
      'API base URL for Android emulator: http://10.0.2.2:${server.port}',
    );
    stdout.writeln(
      'Stored shares file: ${store.file.path}${publicBaseUrl != null ? '\nPublic page base URL override: $publicBaseUrl' : ''}',
    );
  }

  return server;
}

Future<void> _serveLoop(
  HttpServer server,
  _PublicShareStore store, {
  String? publicBaseUrl,
}) async {
  await for (final request in server) {
    unawaited(_handleRequest(request, store, publicBaseUrl: publicBaseUrl));
  }
}

Future<void> _handleRequest(
  HttpRequest request,
  _PublicShareStore store, {
  String? publicBaseUrl,
}) async {
  try {
    final pathSegments = request.uri.pathSegments;

    if (request.method == 'OPTIONS') {
      _writeCorsHeaders(request.response);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    if (request.method == 'GET' &&
        (pathSegments.isEmpty ||
            (pathSegments.length == 1 && pathSegments.first.isEmpty))) {
      await _serveIndexPage(request, store, publicBaseUrl: publicBaseUrl);
      return;
    }

    if (request.method == 'GET' &&
        pathSegments.length == 2 &&
        pathSegments.first == 's') {
      await _servePublicPage(
        request,
        store,
        slug: pathSegments[1],
        publicBaseUrl: publicBaseUrl,
      );
      return;
    }

    if (request.method == 'GET' &&
        pathSegments.length == 2 &&
        pathSegments.first == 'public-shares') {
      await _servePublicShareJson(
        request,
        store,
        slug: pathSegments[1],
        publicBaseUrl: publicBaseUrl,
      );
      return;
    }

    if (request.method == 'POST' &&
        pathSegments.length == 1 &&
        pathSegments.first == 'public-shares') {
      await _createShare(request, store, publicBaseUrl: publicBaseUrl);
      return;
    }

    if (pathSegments.length == 2 && pathSegments.first == 'public-shares') {
      final shareId = pathSegments[1];

      if (request.method == 'PUT') {
        await _updateShare(
          request,
          store,
          shareId: shareId,
          publicBaseUrl: publicBaseUrl,
        );
        return;
      }

      if (request.method == 'DELETE') {
        await _revokeShare(
          request,
          store,
          shareId: shareId,
          publicBaseUrl: publicBaseUrl,
        );
        return;
      }
    }

    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'Route not found',
    });
  } catch (e, stackTrace) {
    stderr.writeln('Public share stub error: $e');
    stderr.writeln(stackTrace);
    try {
      await _writeJson(request.response, HttpStatus.internalServerError, {
        'error': e.toString(),
      });
    } catch (_) {
      await request.response.close();
    }
  }
}

Future<void> _createShare(
  HttpRequest request,
  _PublicShareStore store, {
  String? publicBaseUrl,
}) async {
  final body = await _decodeJsonBody(request);
  final title = (body['title'] ?? '').toString().trim();
  final snapshotVersion = (body['snapshotVersion'] as int?) ?? 1;
  final snapshot = body['snapshot'];

  if (title.isEmpty) {
    await _writeJson(request.response, HttpStatus.badRequest, {
      'error': 'Missing title',
    });
    return;
  }
  if (snapshot is! Map<String, dynamic>) {
    await _writeJson(request.response, HttpStatus.badRequest, {
      'error': 'Missing snapshot',
    });
    return;
  }

  final now = DateTime.now().toIso8601String();
  final record = _StoredPublicShare(
    shareId: _randomToken(16),
    slug: _randomToken(8),
    ownerToken: _randomToken(32),
    title: title,
    snapshotVersion: snapshotVersion,
    snapshot: snapshot,
    createdAt: now,
    updatedAt: now,
    revokedAt: null,
  );

  await store.upsert(record);

  await _writeJson(request.response, HttpStatus.created, {
    'shareId': record.shareId,
    'slug': record.slug,
    'publicUrl': _publicPageUrl(request, record.slug, publicBaseUrl),
    'ownerToken': record.ownerToken,
    'snapshotVersion': record.snapshotVersion,
  });
}

Future<void> _updateShare(
  HttpRequest request,
  _PublicShareStore store, {
  required String shareId,
  String? publicBaseUrl,
}) async {
  final existing = store.findByShareId(shareId);
  if (existing == null) {
    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'Share not found',
    });
    return;
  }

  final ownerToken = request.headers.value('X-Owner-Token')?.trim() ?? '';
  if (ownerToken.isEmpty || ownerToken != existing.ownerToken) {
    await _writeJson(request.response, HttpStatus.unauthorized, {
      'error': 'Owner token is invalid',
    });
    return;
  }

  final body = await _decodeJsonBody(request);
  final title = (body['title'] ?? '').toString().trim();
  final snapshotVersion = (body['snapshotVersion'] as int?) ?? 1;
  final snapshot = body['snapshot'];

  if (title.isEmpty || snapshot is! Map<String, dynamic>) {
    await _writeJson(request.response, HttpStatus.badRequest, {
      'error': 'Invalid update payload',
    });
    return;
  }

  final updated = existing.copyWith(
    title: title,
    snapshotVersion: snapshotVersion,
    snapshot: snapshot,
    updatedAt: DateTime.now().toIso8601String(),
    revokedAt: null,
  );

  await store.upsert(updated);

  await _writeJson(request.response, HttpStatus.ok, {
    'shareId': updated.shareId,
    'slug': updated.slug,
    'publicUrl': _publicPageUrl(request, updated.slug, publicBaseUrl),
    'ownerToken': updated.ownerToken,
    'snapshotVersion': updated.snapshotVersion,
  });
}

Future<void> _revokeShare(
  HttpRequest request,
  _PublicShareStore store, {
  required String shareId,
  String? publicBaseUrl,
}) async {
  final existing = store.findByShareId(shareId);
  if (existing == null) {
    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'Share not found',
    });
    return;
  }

  final ownerToken = request.headers.value('X-Owner-Token')?.trim() ?? '';
  if (ownerToken.isEmpty || ownerToken != existing.ownerToken) {
    await _writeJson(request.response, HttpStatus.unauthorized, {
      'error': 'Owner token is invalid',
    });
    return;
  }

  final revoked = existing.copyWith(
    updatedAt: DateTime.now().toIso8601String(),
    revokedAt: DateTime.now().toIso8601String(),
  );
  await store.upsert(revoked);

  await _writeJson(request.response, HttpStatus.ok, {
    'shareId': revoked.shareId,
    'slug': revoked.slug,
    'publicUrl': _publicPageUrl(request, revoked.slug, publicBaseUrl),
    'ownerToken': revoked.ownerToken,
    'snapshotVersion': revoked.snapshotVersion,
  });
}

Future<void> _servePublicShareJson(
  HttpRequest request,
  _PublicShareStore store, {
  required String slug,
  String? publicBaseUrl,
}) async {
  final record = store.findBySlug(slug);
  if (record == null) {
    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'Share not found',
    });
    return;
  }
  if (record.revokedAt != null) {
    await _writeJson(request.response, HttpStatus.gone, {
      'error': 'Share has been revoked',
    });
    return;
  }

  await _writeJson(request.response, HttpStatus.ok, {
    'shareId': record.shareId,
    'slug': record.slug,
    'title': record.title,
    'snapshotVersion': record.snapshotVersion,
    'publicUrl': _publicPageUrl(request, record.slug, publicBaseUrl),
    'createdAt': record.createdAt,
    'updatedAt': record.updatedAt,
    'snapshot': record.snapshot,
  });
}

Future<void> _serveIndexPage(
  HttpRequest request,
  _PublicShareStore store, {
  String? publicBaseUrl,
}) async {
  final shares = store.records.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final items = shares.isEmpty
      ? '<div class="empty">Chưa có public share nào. Hãy tạo link từ app trước.</div>'
      : shares.map((share) {
          final publicUrl = _publicPageUrl(request, share.slug, publicBaseUrl);
          final status = share.revokedAt == null
              ? 'Đang hoạt động'
              : 'Đã thu hồi';
          final statusClass = share.revokedAt == null ? 'ok' : 'muted';
          return '''
          <article class="share-card">
            <div class="share-top">
              <div>
                <h3>${_escapeHtml(share.title)}</h3>
                <p>${_escapeHtml(publicUrl)}</p>
              </div>
              <span class="status $statusClass">$status</span>
            </div>
            <div class="share-meta">
              <span>Slug: ${_escapeHtml(share.slug)}</span>
              <span>Cập nhật: ${_escapeHtml(_shortDateTime(share.updatedAt))}</span>
            </div>
            <div class="share-actions">
              <a href="/s/${Uri.encodeComponent(share.slug)}" target="_blank" rel="noreferrer">Mở public page</a>
              <a href="/public-shares/${Uri.encodeComponent(share.slug)}" target="_blank" rel="noreferrer">Xem JSON</a>
            </div>
          </article>
          ''';
        }).join();

  final html =
      '''
  <!doctype html>
  <html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Public Share Stub</title>
    <style>
      body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#f8f0e6;color:#3f2b26}
      .wrap{max-width:920px;margin:0 auto;padding:32px 20px 60px}
      h1{margin:0 0 8px;font-size:30px}
      .lead{margin:0 0 24px;color:#8f6f5f;line-height:1.5}
      .grid{display:grid;gap:14px}
      .share-card{background:#fff;border:1px solid #efdfd3;border-radius:24px;padding:18px 18px 16px;box-shadow:0 10px 24px rgba(63,43,38,.06)}
      .share-top{display:flex;justify-content:space-between;gap:16px;align-items:flex-start}
      .share-top h3{margin:0 0 6px;font-size:20px}
      .share-top p{margin:0;color:#8f6f5f;word-break:break-all}
      .status{display:inline-flex;align-items:center;padding:7px 12px;border-radius:999px;font-size:12px;font-weight:700}
      .status.ok{background:#e8f6ec;color:#1d7f3b}
      .status.muted{background:#f2ebe7;color:#8f6f5f}
      .share-meta{display:flex;gap:12px;flex-wrap:wrap;margin-top:14px;color:#8f6f5f;font-size:13px}
      .share-actions{display:flex;gap:12px;flex-wrap:wrap;margin-top:16px}
      .share-actions a{display:inline-flex;padding:10px 14px;border-radius:14px;background:#b7312f;color:#fff;text-decoration:none;font-weight:700}
      .share-actions a:last-child{background:#e0a321;color:#4a321a}
      .empty{padding:24px;border-radius:20px;background:#fff;border:1px dashed #e5cdbb;color:#8f6f5f}
      code{background:#fff;padding:2px 6px;border-radius:8px}
    </style>
  </head>
  <body>
    <div class="wrap">
      <h1>Public Share Stub</h1>
      <p class="lead">
        Stub server local để test end-to-end public share. App debug nên trỏ vào
        <code>http://10.0.2.2:${request.connectionInfo?.localPort ?? 8787}</code>,
        còn trình duyệt trên máy có thể mở ngay các link dưới đây.
      </p>
      <section class="grid">$items</section>
    </div>
  </body>
  </html>
  ''';

  request.response.statusCode = HttpStatus.ok;
  request.response.headers.contentType = ContentType.html;
  request.response.write(html);
  await request.response.close();
}

Future<void> _servePublicPage(
  HttpRequest request,
  _PublicShareStore store, {
  required String slug,
  String? publicBaseUrl,
}) async {
  final record = store.findBySlug(slug);
  if (record == null) {
    await _writeHtml(
      request.response,
      HttpStatus.notFound,
      _errorPage('Link không tồn tại', 'Public share này chưa được tạo.'),
    );
    return;
  }

  if (record.revokedAt != null) {
    await _writeHtml(
      request.response,
      HttpStatus.gone,
      _errorPage(
        'Link đã bị thu hồi',
        'Public share này không còn truy cập được nữa.',
      ),
    );
    return;
  }

  final html = _renderPublicPage(
    title: record.title,
    publicUrl: _publicPageUrl(request, record.slug, publicBaseUrl),
    snapshot: record.snapshot,
    updatedAt: record.updatedAt,
  );

  await _writeHtml(request.response, HttpStatus.ok, html);
}

String _renderPublicPage({
  required String title,
  required String publicUrl,
  required Map<String, dynamic> snapshot,
  required String updatedAt,
}) {
  final plan = (snapshot['plan'] as Map?)?.cast<String, dynamic>() ?? {};
  final overview =
      (snapshot['overview'] as Map?)?.cast<String, dynamic>() ?? const {};
  final days = ((snapshot['days'] as List?) ?? const [])
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
  final expenseGroups = ((snapshot['expenseGroups'] as List?) ?? const [])
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
  final checklistGroups = ((snapshot['checklistGroups'] as List?) ?? const [])
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();

  final description = plan['description']?.toString().trim() ?? '';
  final participants = plan['participants']?.toString().trim() ?? '';

  final daySections = days.isEmpty
      ? '<p class="empty-text">Chưa có hoạt động nào được chia sẻ.</p>'
      : days.map((day) {
          final activities = ((day['activities'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
          final activityMarkup = activities.isEmpty
              ? '<p class="empty-text">Chưa có hoạt động.</p>'
              : activities.map((activity) {
                  final details = <String>[];
                  final timeLabel =
                      activity['timeLabel']?.toString().trim() ?? '';
                  final typeLabel =
                      activity['typeLabel']?.toString().trim() ?? '';
                  final locationText =
                      activity['locationText']?.toString().trim() ?? '';
                  final displayEstimatedCost =
                      activity['displayEstimatedCost']?.toString().trim() ?? '';
                  final note = activity['note']?.toString().trim() ?? '';

                  if (timeLabel.isNotEmpty) {
                    details.add(
                      '<li><strong>Thời gian:</strong> ${_escapeHtml(timeLabel)}</li>',
                    );
                  }
                  if (typeLabel.isNotEmpty) {
                    details.add(
                      '<li><strong>Loại:</strong> ${_escapeHtml(typeLabel)}</li>',
                    );
                  }
                  if (locationText.isNotEmpty) {
                    details.add(
                      '<li><strong>Địa điểm:</strong> ${_escapeHtml(locationText)}</li>',
                    );
                  }
                  if (displayEstimatedCost.isNotEmpty) {
                    details.add(
                      '<li><strong>Chi phí dự kiến:</strong> ${_escapeHtml(displayEstimatedCost)}</li>',
                    );
                  }
                  if (note.isNotEmpty) {
                    details.add(
                      '<li><strong>Ghi chú:</strong> ${_escapeHtml(note)}</li>',
                    );
                  }

                  return '''
                  <article class="item-card">
                    <h4>${_escapeHtml(activity['title']?.toString() ?? '')}</h4>
                    ${details.isEmpty ? '' : '<ul>${details.join()}</ul>'}
                  </article>
                  ''';
                }).join();

          return '''
          <section class="section-block">
            <div class="section-head">
              <h3>Ngày ${_escapeHtml(day['dayNumber']?.toString() ?? '')}</h3>
              <span>${_escapeHtml(day['displayDate']?.toString() ?? '')}</span>
            </div>
            <div class="item-list">$activityMarkup</div>
          </section>
          ''';
        }).join();

  final expenseSections = expenseGroups.isEmpty
      ? '<p class="empty-text">Chưa có khoản chi thực tế nào được ghi nhận.</p>'
      : expenseGroups.map((group) {
          final items = ((group['items'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
          final itemMarkup = items.map((item) {
            final note = item['note']?.toString().trim() ?? '';
            return '''
            <li>
              <div class="expense-row">
                <span>${_escapeHtml(item['title']?.toString() ?? '')}</span>
                <strong>${_escapeHtml(item['displayAmount']?.toString() ?? '')}</strong>
              </div>
              ${note.isEmpty ? '' : '<p class="sub-note">${_escapeHtml(note)}</p>'}
            </li>
            ''';
          }).join();

          return '''
          <section class="section-block">
            <div class="section-head">
              <h3>${_escapeHtml(group['title']?.toString() ?? '')}</h3>
              <span>${_escapeHtml(group['displayTotalAmount']?.toString() ?? '')}</span>
            </div>
            <ul class="bullet-list">$itemMarkup</ul>
          </section>
          ''';
        }).join();

  final checklistSections = checklistGroups.isEmpty
      ? '<p class="empty-text">Chưa có danh sách đồ cần mang.</p>'
      : checklistGroups.map((group) {
          final items = ((group['items'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
          final itemMarkup = items.map((item) {
            final note = item['note']?.toString().trim() ?? '';
            final quantity = item['quantity']?.toString() ?? '1';
            return '''
            <li>
              <div class="expense-row">
                <span>${_escapeHtml(item['name']?.toString() ?? '')}</span>
                <strong>x${_escapeHtml(quantity)}</strong>
              </div>
              ${note.isEmpty ? '' : '<p class="sub-note">${_escapeHtml(note)}</p>'}
            </li>
            ''';
          }).join();

          return '''
          <section class="section-block">
            <div class="section-head">
              <h3>${_escapeHtml(group['categoryLabel']?.toString() ?? '')}</h3>
              <span>${_escapeHtml(group['itemCount']?.toString() ?? '0')} món</span>
            </div>
            <ul class="bullet-list">$itemMarkup</ul>
          </section>
          ''';
        }).join();

  return '''
  <!doctype html>
  <html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${_escapeHtml(title)}</title>
    <style>
      :root{
        --bg:#f7efe5;--card:#fff;--line:#ecd7c6;--text:#3f2b26;--muted:#8f6f5f;
        --red:#b7312f;--gold:#d39a21;--green:#2b8a4b
      }
      *{box-sizing:border-box}
      body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:linear-gradient(180deg,#fbf3ea 0%,#f6ebdf 100%);color:var(--text)}
      .shell{max-width:980px;margin:0 auto;padding:28px 18px 64px}
      .hero{background:rgba(255,255,255,.94);border:1px solid var(--line);border-radius:28px;padding:24px;box-shadow:0 16px 40px rgba(63,43,38,.08)}
      .eyebrow{display:inline-flex;padding:8px 12px;border-radius:999px;background:#faece3;color:var(--red);font-weight:800;font-size:12px;letter-spacing:.04em}
      h1{margin:14px 0 10px;font-size:34px;line-height:1.1}
      .meta{display:flex;gap:10px;flex-wrap:wrap;margin-top:14px}
      .chip{display:inline-flex;align-items:center;padding:8px 12px;border-radius:999px;background:#fff7f0;border:1px solid var(--line);font-size:13px;color:var(--muted);font-weight:700}
      .content{display:grid;gap:16px;margin-top:18px}
      .section{background:rgba(255,255,255,.96);border:1px solid var(--line);border-radius:24px;padding:20px}
      .section-title{margin:0 0 14px;font-size:20px}
      .overview{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}
      .metric{border-radius:18px;padding:16px;background:#fff7f0;border:1px solid #f0ddcf}
      .metric:nth-child(2){background:#eef8f1}
      .metric:nth-child(3){background:#f1f8f2}
      .metric span{display:block;color:var(--muted);font-size:13px;font-weight:700}
      .metric strong{display:block;margin-top:8px;font-size:22px}
      .section-block + .section-block{margin-top:14px}
      .section-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;margin-bottom:10px}
      .section-head h3{margin:0;font-size:18px}
      .section-head span{color:var(--muted);font-size:13px;font-weight:700}
      .item-list{display:grid;gap:10px}
      .item-card{border-radius:18px;border:1px solid #f0e0d4;background:#fffaf6;padding:14px}
      .item-card h4{margin:0 0 10px;font-size:17px}
      .item-card ul{margin:0;padding-left:18px;color:var(--muted);line-height:1.5}
      .bullet-list{list-style:none;margin:0;padding:0;display:grid;gap:10px}
      .bullet-list li{border-radius:16px;background:#fffaf6;border:1px solid #f0e0d4;padding:12px 14px}
      .expense-row{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}
      .sub-note{margin:6px 0 0;color:var(--muted);font-size:13px;line-height:1.45}
      .empty-text{margin:0;color:var(--muted);line-height:1.5}
      .footer{margin-top:18px;color:var(--muted);font-size:13px}
      a{color:var(--red)}
    </style>
  </head>
  <body>
    <main class="shell">
      <section class="hero">
        <span class="eyebrow">DU XUÂN PLANNER</span>
        <h1>${_escapeHtml(plan['name']?.toString() ?? title)}</h1>
        <div class="meta">
          <span class="chip">Thời gian: ${_escapeHtml(plan['displayDate']?.toString() ?? '')}</span>
          <span class="chip">Số ngày: ${_escapeHtml(plan['displayDayCount']?.toString() ?? '')}</span>
          ${participants.isEmpty ? '' : '<span class="chip">Thành viên: ${_escapeHtml(participants)}</span>'}
        </div>
      </section>
      <div class="content">
        ${description.isEmpty ? '' : '<section class="section"><h2 class="section-title">MÔ TẢ</h2><p class="empty-text">${_escapeHtml(description)}</p></section>'}
        <section class="section">
          <h2 class="section-title">TỔNG QUAN</h2>
          <div class="overview">
            <div class="metric">
              <span>Chi phí dự kiến</span>
              <strong>${_escapeHtml(overview['displayEstimatedTotal']?.toString() ?? '0đ')}</strong>
            </div>
            <div class="metric">
              <span>Chi phí thực tế đã ghi</span>
              <strong>${_escapeHtml(overview['displayActualTotal']?.toString() ?? '0đ')}</strong>
            </div>
            <div class="metric">
              <span>Chênh lệch</span>
              <strong>${_escapeHtml(overview['displayVariance']?.toString() ?? '0đ')}</strong>
            </div>
          </div>
        </section>
        <section class="section">
          <h2 class="section-title">LỊCH TRÌNH THEO NGÀY</h2>
          $daySections
        </section>
        <section class="section">
          <h2 class="section-title">CHI TIÊU ĐÃ GHI NHẬN</h2>
          $expenseSections
        </section>
        <section class="section">
          <h2 class="section-title">ĐỒ CẦN MANG</h2>
          $checklistSections
        </section>
      </div>
      <p class="footer">
        Link công khai: <a href="${_escapeHtml(publicUrl)}">${_escapeHtml(publicUrl)}</a><br>
        Cập nhật lần cuối: ${_escapeHtml(_shortDateTime(updatedAt))}
      </p>
    </main>
  </body>
  </html>
  ''';
}

String _errorPage(String title, String message) {
  return '''
  <!doctype html>
  <html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${_escapeHtml(title)}</title>
    <style>
      body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#f8f0e6;color:#3f2b26;display:grid;place-items:center;min-height:100vh}
      .card{max-width:520px;margin:24px;padding:28px;background:#fff;border:1px solid #ecd7c6;border-radius:26px;box-shadow:0 18px 40px rgba(63,43,38,.08)}
      h1{margin:0 0 12px;font-size:30px}
      p{margin:0;color:#8f6f5f;line-height:1.5}
    </style>
  </head>
  <body>
    <section class="card">
      <h1>${_escapeHtml(title)}</h1>
      <p>${_escapeHtml(message)}</p>
    </section>
  </body>
  </html>
  ''';
}

Future<Map<String, dynamic>> _decodeJsonBody(HttpRequest request) async {
  final raw = await utf8.decoder.bind(request).join();
  if (raw.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('Body must be a JSON object.');
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) async {
  _writeCorsHeaders(response);
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

Future<void> _writeHtml(
  HttpResponse response,
  int statusCode,
  String html,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.html;
  response.write(html);
  await response.close();
}

void _writeCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Content-Type, X-Owner-Token',
  );
  response.headers.set(
    'Access-Control-Allow-Methods',
    'GET, POST, PUT, DELETE, OPTIONS',
  );
}

String _publicPageUrl(HttpRequest request, String slug, String? publicBaseUrl) {
  final base = publicBaseUrl?.trim().isNotEmpty == true
      ? publicBaseUrl!.trim().replaceAll(RegExp(r'/$'), '')
      : _requestBaseUrl(request);
  return '$base/s/$slug';
}

String _requestBaseUrl(HttpRequest request) {
  final rawHost = (request.headers.host ?? '').trim();
  final port = request.connectionInfo?.localPort ?? 8787;

  if (rawHost.isEmpty) {
    return 'http://127.0.0.1:$port';
  }

  if (rawHost.contains(':')) {
    return 'http://$rawHost';
  }

  return 'http://$rawHost:$port';
}

String _randomToken(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _shortDateTime(String isoString) {
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  } catch (_) {
    return isoString;
  }
}

class _PublicShareStore {
  final File file;
  final List<_StoredPublicShare> _records = [];

  _PublicShareStore({required this.file});

  List<_StoredPublicShare> get records => List.unmodifiable(_records);

  Future<void> init() async {
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stored public share file is invalid.');
    }

    _records
      ..clear()
      ..addAll(
        decoded.whereType<Map>().map(
          (item) => _StoredPublicShare.fromJson(item.cast<String, dynamic>()),
        ),
      );
  }

  _StoredPublicShare? findByShareId(String shareId) {
    for (final record in _records) {
      if (record.shareId == shareId) return record;
    }
    return null;
  }

  _StoredPublicShare? findBySlug(String slug) {
    for (final record in _records) {
      if (record.slug == slug) return record;
    }
    return null;
  }

  Future<void> upsert(_StoredPublicShare record) async {
    final index = _records.indexWhere((item) => item.shareId == record.shareId);
    if (index >= 0) {
      _records[index] = record;
    } else {
      _records.add(record);
    }
    await _persist();
  }

  Future<void> _persist() async {
    final payload = _records.map((record) => record.toJson()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }
}

class _StoredPublicShare {
  final String shareId;
  final String slug;
  final String ownerToken;
  final String title;
  final int snapshotVersion;
  final Map<String, dynamic> snapshot;
  final String createdAt;
  final String updatedAt;
  final String? revokedAt;

  const _StoredPublicShare({
    required this.shareId,
    required this.slug,
    required this.ownerToken,
    required this.title,
    required this.snapshotVersion,
    required this.snapshot,
    required this.createdAt,
    required this.updatedAt,
    required this.revokedAt,
  });

  factory _StoredPublicShare.fromJson(Map<String, dynamic> json) {
    return _StoredPublicShare(
      shareId: (json['shareId'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      ownerToken: (json['ownerToken'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      snapshotVersion: (json['snapshotVersion'] as int?) ?? 1,
      snapshot:
          (json['snapshot'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      revokedAt: json['revokedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'slug': slug,
    'ownerToken': ownerToken,
    'title': title,
    'snapshotVersion': snapshotVersion,
    'snapshot': snapshot,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'revokedAt': revokedAt,
  };

  _StoredPublicShare copyWith({
    String? shareId,
    String? slug,
    String? ownerToken,
    String? title,
    int? snapshotVersion,
    Map<String, dynamic>? snapshot,
    String? createdAt,
    String? updatedAt,
    String? revokedAt,
  }) {
    return _StoredPublicShare(
      shareId: shareId ?? this.shareId,
      slug: slug ?? this.slug,
      ownerToken: ownerToken ?? this.ownerToken,
      title: title ?? this.title,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
      snapshot: snapshot ?? this.snapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revokedAt: revokedAt,
    );
  }
}
