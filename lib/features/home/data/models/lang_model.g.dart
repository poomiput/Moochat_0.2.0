// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lang_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LanguageOption _$LanguageOptionFromJson(Map<String, dynamic> json) =>
    LanguageOption(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['nativeName'] as String,
      flag: json['flag'] as String,
    );

Map<String, dynamic> _$LanguageOptionToJson(LanguageOption instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'nativeName': instance.nativeName,
      'flag': instance.flag,
    };
