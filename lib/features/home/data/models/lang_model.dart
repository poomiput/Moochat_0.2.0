import 'package:json_annotation/json_annotation.dart';
part 'lang_model.g.dart';

@JsonSerializable()
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
