import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:du_xuan/core/constants/api_constants.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:intl/intl.dart';

/// Item gợi ý từ AI — chưa lưu DB, chỉ hiển thị cho user chọn
class SuggestedItem {
  final String name;
  final ChecklistCategory category;
  final int quantity;
  final String reason;

  const SuggestedItem({
    required this.name,
    required this.category,
    this.quantity = 1,
    required this.reason,
  });

  factory SuggestedItem.fromJson(Map<String, dynamic> json) {
    return SuggestedItem(
      name: (json['name'] ?? '').toString(),
      category: ChecklistCategory.fromString(
        (json['category'] ?? 'OTHER').toString(),
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

/// Service gọi OpenAI API để gợi ý vật dụng
class OpenAiService {
  /// Gợi ý vật dụng dựa trên plan + activities
  Future<List<SuggestedItem>> suggestItems({
    required Plan plan,
    required Map<PlanDay, List<Activity>> activitiesByDay,
    required List<String> existingItemNames,
  }) async {
    final prompt = _buildPrompt(plan, activitiesByDay, existingItemNames);

    final response = await http.post(
      Uri.parse(ApiConstants.openAiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.openAiKey}',
      },
      body: jsonEncode({
        'model': ApiConstants.openAiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'Bạn là trợ lý du lịch Việt Nam thông minh. '
                'Trả lời ĐÚNG JSON array, không markdown, không giải thích thêm.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error']?['message'] ?? 'Lỗi không xác định';
      throw Exception('OpenAI Error: $error');
    }

    return _parseResponse(response.body);
  }

  // ─── PROMPT BUILDER ──────────────────────────────────

  String _buildPrompt(
    Plan plan,
    Map<PlanDay, List<Activity>> activitiesByDay,
    List<String> existingItems,
  ) {
    final dateFmt = DateFormat('dd/MM');
    final buf = StringBuffer();

    buf.writeln('Dựa vào kế hoạch du xuân sau, hãy gợi ý vật dụng cần mang.');
    buf.writeln();
    buf.writeln('📋 KẾ HOẠCH: ${plan.name}');
    buf.writeln(
      '📅 Thời gian: ${dateFmt.format(plan.startDate)} → '
      '${dateFmt.format(plan.endDate)} (${plan.totalDays} ngày)',
    );
    if (plan.participants != null && plan.participants!.isNotEmpty) {
      buf.writeln('👥 Người tham gia: ${plan.participants}');
    }
    if (plan.description != null && plan.description!.isNotEmpty) {
      buf.writeln('📝 Mô tả: ${plan.description}');
    }

    // Lịch trình theo ngày
    buf.writeln();
    buf.writeln('📍 LỊCH TRÌNH:');

    final sortedDays = activitiesByDay.keys.toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    for (final day in sortedDays) {
      final activities = activitiesByDay[day]!;
      buf.writeln(
        'Ngày ${day.dayNumber} (${dateFmt.format(day.date)}):',
      );
      if (activities.isEmpty) {
        buf.writeln('  - (chưa có hoạt động)');
      } else {
        for (final a in activities) {
          buf.write('  - [${a.activityType.label}] ${a.title}');
          if (a.locationText != null && a.locationText!.isNotEmpty) {
            buf.write(' (${a.locationText})');
          }
          buf.writeln();
        }
      }
    }

    // Items đã có
    if (existingItems.isNotEmpty) {
      buf.writeln();
      buf.writeln('✅ ĐÃ CÓ: ${existingItems.join(', ')}');
    }

    // Quy tắc
    buf.writeln();
    buf.writeln('⚠️ QUY TẮC:');
    buf.writeln('- Gợi ý 8-12 items thiết thực nhất, KHÔNG trùng danh sách đã có');
    buf.writeln(
      '- category PHẢI là 1 trong: '
      'CLOTHING, TOILETRY, ELECTRONICS, DOCUMENT, MEDICINE, FOOD, OTHER',
    );
    buf.writeln('- quantity >= 1');
    buf.writeln('- reason ngắn gọn (dưới 30 ký tự), liên quan hoạt động cụ thể');
    buf.writeln();
    buf.writeln(
      'Trả về JSON array: '
      '[{"name":"...","category":"CLOTHING","quantity":1,"reason":"..."}]',
    );

    return buf.toString();
  }

  // ─── RESPONSE PARSER ─────────────────────────────────

  List<SuggestedItem> _parseResponse(String responseBody) {
    final body = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>;
    if (choices.isEmpty) return [];

    final message = choices[0]['message'] as Map<String, dynamic>;
    var content = (message['content'] ?? '').toString().trim();

    // Loại bỏ markdown wrapper nếu có
    if (content.startsWith('```')) {
      content = content
          .replaceFirst(RegExp(r'^```json?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    }

    final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
    return jsonList
        .map((e) => SuggestedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
