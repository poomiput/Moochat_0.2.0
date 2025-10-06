import 'dart:async';
import 'dart:typed_data';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/shared/models/nearbay_device_info.dart';
import 'package:nearby_connections/nearby_connections.dart';

class BluetoothServicesmoochat {
  // Streams for device events
  final StreamController<NearbayDeviceInfo> _deviceFoundController =
      StreamController<NearbayDeviceInfo>.broadcast();
  final StreamController<String> _deviceLostController =
      StreamController<String>.broadcast();
  final StreamController<NearbayDeviceInfo> _deviceConnectedController =
      StreamController<NearbayDeviceInfo>.broadcast();
  final StreamController<Map<String, String>> _messageReceivedController =
      StreamController<Map<String, String>>.broadcast();

  // Store discovered devices for UUID lookup
  final Map<String, NearbayDeviceInfo> _discoveredDevices = {};

  // Getters for streams
  Stream<NearbayDeviceInfo> get onDeviceFound => _deviceFoundController.stream;
  Stream<String> get onDeviceLost => _deviceLostController.stream;
  Stream<NearbayDeviceInfo> get onDeviceConnected =>
      _deviceConnectedController.stream;
  Stream<Map<String, String>> get onMessageReceived =>
      _messageReceivedController.stream;

  // Method to get UUID by device ID from discovered devices
  String? getUuidByDeviceId(String deviceId) {
    return _discoveredDevices[deviceId]?.uuid;
  }

  // Method to get discovered device info by device ID
  NearbayDeviceInfo? getDiscoveredDeviceById(String deviceId) {
    return _discoveredDevices[deviceId];
  }

  // start advertising
  Future<void> startAdvertising(String userName) async {
    final Strategy strategy = Strategy.P2P_STAR;
    try {
      LoggerDebug.logger.i('🟡 Starting advertising with userName: $userName');
      
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          // Called whenever a discoverer requests connection
          LoggerDebug.logger.i(
            '🟡 Connection initiated: $id, UserName: ${info.endpointName}',
          );
          // Automatically accept all connections
          LoggerDebug.logger.i('🟡 Auto-accepting connection from: $id');
          acceptConnection(id);
        },
        onConnectionResult: (String id, Status status) {
          // Called when connection is accepted/rejected
          LoggerDebug.logger.i(
            '🟡 Connection result: $id, Status: ${status.toString()}',
          );
          if (status == Status.CONNECTED) {
            // Try to get the uuid from discovered devices
            String deviceUuid = getUuidByDeviceId(id) ?? '';

            LoggerDebug.logger.i('🟢 Connected device ID: $id, UUID: $deviceUuid');

            // Add connected device to stream
            final device = NearbayDeviceInfo(
              id: id,
              uuid: deviceUuid,
              serviceId: "free.palestine.moochat",
            );

            _deviceConnectedController.add(device);
          } else if (status == Status.REJECTED) {
            LoggerDebug.logger.e('🔴 Connection rejected by: $id');
          } else if (status == Status.ERROR) {
            LoggerDebug.logger.e('🔴 Connection error with: $id');
          }
        },
        onDisconnected: (String id) {
          // Called whenever a discoverer disconnects from advertiser
          LoggerDebug.logger.w('🔴 Disconnected from: $id');
          _deviceLostController.add(id);
          // Remove from discovered devices cache
          _discoveredDevices.remove(id);
        },
        serviceId: "free.palestine.moochat", // uniquely identifies your app
      );
      LoggerDebug.logger.i('🟢 Advertising started successfully');
    } catch (exception) {
      LoggerDebug.logger.e('🔴 Error starting advertising: $exception');
      
      // Provide more specific error messages
      if (exception.toString().contains('PERMISSION')) {
        LoggerDebug.logger.e('🔴 Permission denied - check location and bluetooth permissions');
      } else if (exception.toString().contains('BLUETOOTH')) {
        LoggerDebug.logger.e('🔴 Bluetooth not available or disabled');
      }
      rethrow;
    }
  }

  // start startDiscovery
  Future<void> startDiscovery(String userName) async {
    final Strategy strategy = Strategy.P2P_STAR;

    try {
      LoggerDebug.logger.i('🟡 Starting discovery with userName: $userName');
      
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) {
          // Called whenever an advertiser is found
          LoggerDebug.logger.i(
            '🟢 Endpoint found: $id, UserName: $userName, ServiceId: $serviceId',
          );

          // Create device info and add to stream
          final device = NearbayDeviceInfo(
            id: id,
            uuid: userName, // Using userName as UUID
            serviceId: serviceId,
          );

          // Store in discovered devices cache for later lookup
          _discoveredDevices[id] = device;

          _deviceFoundController.add(device);
        },
        onEndpointLost: (String? id) {
          LoggerDebug.logger.w('🔴 Endpoint lost: $id');
          if (id != null) {
            _deviceLostController.add(id);
            // Remove from discovered devices cache
            _discoveredDevices.remove(id);
          }
        },
        serviceId: "free.palestine.moochat",
      );
      LoggerDebug.logger.i('🟢 Discovery started successfully');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error starting discovery: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('PERMISSION')) {
        LoggerDebug.logger.e('🔴 Permission denied - check location permissions');
      } else if (e.toString().contains('BLUETOOTH')) {
        LoggerDebug.logger.e('🔴 Bluetooth not available or disabled');
      }
      rethrow;
    }
  }

  // Stop advertising
  Future<void> stopAdvertising() async {
    try {
      await Nearby().stopAdvertising();
      LoggerDebug.logger.i('🟢 Stopped advertising');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error stopping advertising: $e');
    }
  }

  // Stop discovery
  Future<void> stopDiscovery() async {
    try {
      await Nearby().stopDiscovery();
      // Clear discovered devices cache when stopping discovery
      _discoveredDevices.clear();
      LoggerDebug.logger.i('🟢 Stopped discovery');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error stopping discovery: $e');
    }
  }

  // Request connection to a device
  Future<void> requestConnection(String deviceId, String userName) async {
    try {
      LoggerDebug.logger.i(
        '🟡 Requesting connection to: $deviceId with userName: $userName',
      );

      // Add a small delay before requesting connection to ensure discovery is stable
      await Future.delayed(const Duration(milliseconds: 1000));

      await Nearby().requestConnection(
        userName,
        deviceId,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          LoggerDebug.logger.i(
            '🟡 Connection initiated to: $id, UserName: ${info.endpointName}',
          );
          // Automatically accept the connection
          LoggerDebug.logger.i('🟡 Auto-accepting connection to: $id');
          acceptConnection(id);
        },
        onConnectionResult: (String id, Status status) {
          LoggerDebug.logger.i('🟡 Connection result: $id, Status: $status');
          if (status == Status.CONNECTED) {
            LoggerDebug.logger.i('🟢 Successfully connected to: $id');
            // Try to get the uuid from discovered devices, fallback to userName parameter
            String deviceUuid = getUuidByDeviceId(id) ?? userName;

            final device = NearbayDeviceInfo(
              id: id,
              uuid: deviceUuid,
              serviceId: "free.palestine.moochat",
            );
            _deviceConnectedController.add(device);
          } else if (status == Status.REJECTED) {
            LoggerDebug.logger.e('🔴 Connection rejected by: $id');
          } else if (status == Status.ERROR) {
            LoggerDebug.logger.e('🔴 Connection error with: $id');
          } else {
            LoggerDebug.logger.w('🟡 Unknown connection status: $status for device: $id');
          }
        },
        onDisconnected: (String id) {
          LoggerDebug.logger.w('🔴 Disconnected from: $id');
          _deviceLostController.add(id);
          // Remove from discovered devices cache
          _discoveredDevices.remove(id);
        },
      );
      LoggerDebug.logger.i('🟢 Connection request sent to: $deviceId');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error requesting connection: $e');
      
      // Try to provide more specific error information
      if (e.toString().contains('PERMISSION')) {
        LoggerDebug.logger.e('🔴 Permission error - check location and bluetooth permissions');
      } else if (e.toString().contains('BLUETOOTH')) {
        LoggerDebug.logger.e('🔴 Bluetooth error - ensure bluetooth is enabled');
      } else if (e.toString().contains('ENDPOINT_NOT_FOUND')) {
        LoggerDebug.logger.e('🔴 Device not found - try refreshing discovery');
      }
      
      rethrow; // Re-throw to let caller handle the error
    }
  }

  // Accept connection
  Future<void> acceptConnection(String deviceId) async {
    try {
      LoggerDebug.logger.i('🟡 Accepting connection from: $deviceId');
      
      await Nearby().acceptConnection(
        deviceId,
        onPayLoadRecieved: (String endpointId, Payload payload) {
          // Handle received messages
          if (payload.type == PayloadType.BYTES) {
            final String message = String.fromCharCodes(payload.bytes!);
            LoggerDebug.logger.i('🟢 Message received from $endpointId: $message');

            // Add received message to stream
            _messageReceivedController.add({
              'senderId': endpointId,
              'message': message,
            });
          } else if (payload.type == PayloadType.FILE) {
            LoggerDebug.logger.i('🟡 File payload received from $endpointId');
            // Handle file payload if needed
          }
        },
      );
      LoggerDebug.logger.i('🟢 Accepted connection from: $deviceId');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error accepting connection: $e');
      rethrow;
    }
  }

  // Send message to a specific device
  Future<bool> sendMessage(String deviceId, String message) async {
    try {
      LoggerDebug.logger.i('🟡 Sending message to $deviceId: $message');
      
      final Uint8List bytes = Uint8List.fromList(message.codeUnits);
      await Nearby().sendBytesPayload(deviceId, bytes);
      
      LoggerDebug.logger.i('🟢 Message sent successfully to $deviceId');
      return true;
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error sending message to $deviceId: $e');
      return false;
    }
  }

  // Send message to all connected devices
  Future<void> sendMessageToAll(String message) async {
    try {
      LoggerDebug.logger.i('🟡 Broadcasting message to all devices: $message');
      
      final Uint8List bytes = Uint8List.fromList(message.codeUnits);
      await Nearby().sendBytesPayload('', bytes); // Empty string sends to all
      
      LoggerDebug.logger.i('🟢 Message broadcasted successfully');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error broadcasting message: $e');
      rethrow;
    }
  }

  // Get all discovered devices
  Map<String, NearbayDeviceInfo> get discoveredDevices =>
      Map.from(_discoveredDevices);

  // Clear discovered devices cache
  void clearDiscoveredDevices() {
    _discoveredDevices.clear();
    LoggerDebug.logger.i('🟢 Cleared discovered devices cache');
  }

  // Get connection status
  bool isDeviceConnected(String deviceId) {
    // This is a simple check - you might want to implement more sophisticated logic
    return _discoveredDevices.containsKey(deviceId);
  }

  // Dispose streams
  void dispose() {
    LoggerDebug.logger.i('🟡 Disposing bluetooth service streams');
    
    _deviceFoundController.close();
    _deviceLostController.close();
    _deviceConnectedController.close();
    _messageReceivedController.close();
    _discoveredDevices.clear();
    
    LoggerDebug.logger.i('🟢 Bluetooth service disposed');
  }
}