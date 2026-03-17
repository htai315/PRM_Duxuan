class AiSuggestionResponseDto {
  final List<AiSuggestionItemDto> items;

  const AiSuggestionResponseDto({required this.items});

  factory AiSuggestionResponseDto.fromJson(dynamic decoded) {
    if (decoded is List) {
      return AiSuggestionResponseDto(
        items: decoded
            .whereType<Map<String, dynamic>>()
            .map(AiSuggestionItemDto.fromJson)
            .toList(),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('OpenAI trả về dữ liệu không hợp lệ');
    }

    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw Exception('OpenAI không trả về danh sách gợi ý');
    }

    return AiSuggestionResponseDto(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(AiSuggestionItemDto.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class AiSuggestionItemDto {
  final String name;
  final String category;
  final int quantity;
  final String reason;

  const AiSuggestionItemDto({
    required this.name,
    required this.category,
    required this.quantity,
    required this.reason,
  });

  factory AiSuggestionItemDto.fromJson(Map<String, dynamic> json) {
    return AiSuggestionItemDto(
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'OTHER').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      reason: (json['reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'quantity': quantity,
    'reason': reason,
  };
}
