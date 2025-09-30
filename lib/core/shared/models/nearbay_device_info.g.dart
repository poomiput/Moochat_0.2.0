// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearbay_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearbayDeviceInfo _$NearbayDeviceInfoFromJson(Map<String, dynamic> json) =>
    NearbayDeviceInfo(
      id: json['id'] as String,
      uuid: json['uuid'] as String,
      serviceId: json['serviceId'] as String,
    );

Map<String, dynamic> _$NearbayDeviceInfoToJson(NearbayDeviceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'serviceId': instance.serviceId,
    };
