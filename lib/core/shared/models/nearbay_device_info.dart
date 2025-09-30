import 'package:json_annotation/json_annotation.dart';
part 'nearbay_device_info.g.dart';

@JsonSerializable()
class NearbayDeviceInfo {
  final String id;
  final String uuid;
  final String serviceId;

  NearbayDeviceInfo({
    required this.id,
    required this.uuid,
    required this.serviceId,
  });

  factory NearbayDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$NearbayDeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$NearbayDeviceInfoToJson(this);
}
