// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllChat _$AllChatFromJson(Map<String, dynamic> json) => AllChat(
  policy: json['policy'] as String,
  chats: (json['chats'] as List<dynamic>)
      .map((e) => UserChat.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AllChatToJson(AllChat instance) => <String, dynamic>{
  'policy': instance.policy,
  'chats': instance.chats,
};
