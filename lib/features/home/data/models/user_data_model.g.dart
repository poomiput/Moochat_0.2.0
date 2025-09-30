// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
  username: json['username'] as String,
  uuid: json['uuid'] as String,
  userChats: json['userChats'] == null
      ? null
      : AllChat.fromJson(json['userChats'] as Map<String, dynamic>),
  lang: json['lang'] as String? ?? "en",
);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'username': instance.username,
  'uuid': instance.uuid,
  'userChats': instance.userChats,
  'lang': instance.lang,
};
