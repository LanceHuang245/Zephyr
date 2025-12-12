// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_advice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIAdvice _$AIAdviceFromJson(Map<String, dynamic> json) => AIAdvice(
      clothing: json['clothing'] as String,
      exercise: json['exercise'] as String,
      travel: json['travel'] as String,
      health: json['health'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      city: json['city'] as String,
    );

Map<String, dynamic> _$AIAdviceToJson(AIAdvice instance) => <String, dynamic>{
      'clothing': instance.clothing,
      'exercise': instance.exercise,
      'travel': instance.travel,
      'health': instance.health,
      'timestamp': instance.timestamp.toIso8601String(),
      'city': instance.city,
    };
