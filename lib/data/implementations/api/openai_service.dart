import 'dart:convert';

import 'package:du_xuan/core/constants/api_constants.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/data/dtos/ai/ai_suggestion_request_dto.dart';
import 'package:du_xuan/data/dtos/ai/ai_suggestion_response_dto.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:http/http.dart' as http;

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

  SuggestedItem copyWith({
    String? name,
    ChecklistCategory? category,
    int? quantity,
    String? reason,
  }) {
    return SuggestedItem(
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
    );
  }

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

  factory SuggestedItem.fromDto(AiSuggestionItemDto dto) {
    return SuggestedItem(
      name: dto.name,
      category: ChecklistCategory.fromString(dto.category),
      quantity: dto.quantity,
      reason: dto.reason,
    );
  }
}

/// Client gọi trực tiếp OpenAI để lấy gợi ý vật dụng từ AI.
class OpenAiService {
  Future<List<SuggestedItem>> suggestItems({
    required Plan plan,
    required Map<PlanDay, List<Activity>> activitiesByDay,
    required List<String> existingItemNames,
  }) async {
    if (!ApiConstants.hasOpenAiApiKey) {
      throw Exception('Chưa cấu hình OPENAI_API_KEY cho bản build này.');
    }

    final requestDto = AiSuggestionRequestDto.fromDomain(
      plan: plan,
      activitiesByDay: activitiesByDay,
      existingItemNames: existingItemNames,
    );

    final response = await http
        .post(
          Uri.parse(ApiConstants.openAiResponsesUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConstants.openAiApiKey}',
          },
          body: jsonEncode(_buildOpenAiRequest(requestDto)),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }

    return _parseResponse(response.body);
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
      // Fall through to generic message.
    }

    return 'OpenAI error ($statusCode)';
  }

  Map<String, dynamic> _buildOpenAiRequest(AiSuggestionRequestDto requestDto) {
    return {
      'model': ApiConstants.openAiModel,
      'input': [
        {
          'role': 'system',
          'content': [
            {'type': 'input_text', 'text': _systemInstruction},
          ],
        },
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': _buildPrompt(requestDto)},
          ],
        },
      ],
      'text': {
        'format': {'type': 'json_object'},
      },
      'max_output_tokens': 900,
    };
  }

  String _buildPrompt(AiSuggestionRequestDto requestDto) {
    return '''
Hãy đề xuất checklist vật dụng cho chuyến đi dưới đây.

Yêu cầu:
- Chỉ trả về JSON object hợp lệ.
- Dùng đúng schema: {"items":[{"name":"string","category":"CLOTHING|TOILETRY|ELECTRONICS|DOCUMENT|MEDICINE|FOOD|OTHER","quantity":1,"reason":"string"}]}
- Trả về khoảng 6 đến 10 items, chỉ thêm khi thực sự cần thiết.
- Không trả về item trùng với existingItemNames.
- Tránh các item gần trùng nghĩa, không chỉ trùng tên y hệt.
- quantity phải là số nguyên >= 1.
- Ưu tiên các vật dụng thật sự hữu ích cho lịch trình.
- Chỉ gợi ý vật dụng mang theo hoặc chuẩn bị trước chuyến đi.
- Không gợi ý địa điểm, hoạt động, công việc phải làm, hay lời khuyên chung chung.
- reason ngắn gọn, thực tế, bằng tiếng Việt.
- Không thêm markdown, không thêm giải thích ngoài JSON.

Dữ liệu chuyến đi:
${jsonEncode(requestDto.toJson())}
''';
  }

  List<SuggestedItem> _parseResponse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      throw Exception('OpenAI không trả về nội dung gợi ý hợp lệ');
    }

    final responseDto = AiSuggestionResponseDto.fromJson(
      jsonDecode(outputText),
    );
    return responseDto.items.map(SuggestedItem.fromDto).toList();
  }

  String? _extractOutputText(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    final directOutput = decoded['output_text'];
    if (directOutput is String && directOutput.trim().isNotEmpty) {
      return directOutput;
    }

    final output = decoded['output'];
    if (output is! List) return null;

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      final content = item['content'];
      if (content is! List) continue;
      for (final part in content) {
        if (part is! Map<String, dynamic>) continue;
        if (part['type'] == 'output_text') {
          final text = part['text'];
          if (text is String && text.trim().isNotEmpty) {
            return text;
          }
        }
      }
    }

    return null;
  }

  static const String _systemInstruction =
      'Bạn là trợ lý gợi ý checklist du lịch. '
      'Luôn trả về JSON object hợp lệ theo schema mà người dùng yêu cầu. '
      'Không thêm markdown, không thêm giải thích ngoài JSON.';
}
