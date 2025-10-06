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

  // Track connection states
  final Set<String> _connectedDevices = {};
  final Set<String> _connectingDevices = {};

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

  // Check if device is connected
  bool isConnected(String deviceId) {
    return _connectedDevices.contains(deviceId);
  }

  // Check if device is connecting
  bool isConnecting(String deviceId) {
    return _connectingDevices.contains(deviceId);
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

          _connectingDevices.remove(id);

          if (status == Status.CONNECTED) {
            _connectedDevices.add(id);

            // Try to get the uuid from discovered devices
            String deviceUuid = getUuidByDeviceId(id) ?? '';

            LoggerDebug.logger.i(
              '🟢 Connected device ID: $id, UUID: $deviceUuid',
            );

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
          _connectedDevices.remove(id);
          _connectingDevices.remove(id);
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
        LoggerDebug.logger.e(
          '🔴 Permission denied - check location and bluetooth permissions',
        );
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
            _connectedDevices.remove(id);
            _connectingDevices.remove(id);
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
        LoggerDebug.logger.e(
          '🔴 Permission denied - check location permissions',
        );
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

  // Request connection to a device - ENHANCED VERSION
  Future<bool> requestConnection(String deviceId, String userName) async {
    try {
      LoggerDebug.logger.i(
        '[Bluetooth] 🔄 Starting connection request to: $deviceId',
      );

      // First check if already connected
      if (_connectedDevices.contains(deviceId)) {
        LoggerDebug.logger.i('[Bluetooth] ✅ Already connected to: $deviceId');
        return true;
      }

      // Check if already connecting
      if (_connectingDevices.contains(deviceId)) {
        LoggerDebug.logger.i('[Bluetooth] ⏳ Already connecting to: $deviceId');
        return await _waitForConnection(deviceId);
      }

      // Mark as connecting
      _connectingDevices.add(deviceId);

      // Add longer delay and retry mechanism
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if device is still in discovered list
      if (!_discoveredDevices.containsKey(deviceId)) {
        LoggerDebug.logger.w(
          '[Bluetooth] ⚠️ Device $deviceId not in discovered list, refreshing discovery...',
        );
        await stopDiscovery();
        await Future.delayed(const Duration(milliseconds: 500));
        await startDiscovery(userName);
        await Future.delayed(const Duration(milliseconds: 2000));

        if (!_discoveredDevices.containsKey(deviceId)) {
          LoggerDebug.logger.e(
            '[Bluetooth] ❌ Device $deviceId still not found after refresh',
          );
          _connectingDevices.remove(deviceId);
          return false;
        }
      }

      LoggerDebug.logger.i(
        '[Bluetooth] 📤 Requesting connection to: $deviceId',
      );

      await Nearby().requestConnection(
        userName,
        deviceId,
        onConnectionInitiated: (String endpointId, ConnectionInfo connectionInfo) {
          LoggerDebug.logger.i(
            '[Bluetooth] 🤝 Connection initiated with: $endpointId',
          );
          LoggerDebug.logger.i(
            '[Bluetooth] 🔐 Auth token: ${connectionInfo.authenticationToken}',
          );
          LoggerDebug.logger.i(
            '[Bluetooth] 📱 Device name: ${connectionInfo.endpointName}',
          );
          LoggerDebug.logger.i(
            '[Bluetooth] 🔄 Is incoming: ${connectionInfo.isIncomingConnection}',
          );

          // Auto-accept the connection
          acceptConnection(endpointId);
        },
        onConnectionResult: (String endpointId, Status status) {
          LoggerDebug.logger.i(
            '[Bluetooth] 📊 Connection result for $endpointId: ${status.toString()}',
          );

          _connectingDevices.remove(endpointId);

          if (status == Status.CONNECTED) {
            LoggerDebug.logger.i(
              '[Bluetooth] ✅ Successfully connected to: $endpointId',
            );
            _connectedDevices.add(endpointId);

            // Get device info and add to connected stream
            final deviceInfo = _discoveredDevices[endpointId];
            if (deviceInfo != null) {
              _deviceConnectedController.add(deviceInfo);
            }
          } else {
            LoggerDebug.logger.e(
              '[Bluetooth] ❌ Connection failed to: $endpointId, Status: ${status.toString()}',
            );
            _handleConnectionError(status);
          }
        },
        onDisconnected: (String endpointId) {
          LoggerDebug.logger.w('[Bluetooth] 🔌 Disconnected from: $endpointId');
          _connectedDevices.remove(endpointId);
          _connectingDevices.remove(endpointId);
          _deviceLostController.add(endpointId);
          _discoveredDevices.remove(endpointId);
        },
      );

      // Wait for connection to establish with timeout
      final isConnected = await _waitForConnection(deviceId);

      LoggerDebug.logger.i(
        '[Bluetooth] ${isConnected ? '✅ Connection successful' : '❌ Connection timeout'} for: $deviceId',
      );

      return isConnected;
    } catch (e) {
      LoggerDebug.logger.e('[Bluetooth] ❌ Connection request failed: $e');
      _connectingDevices.remove(deviceId);
      return false;
    }
  }

  // Helper method to wait for connection
  Future<bool> _waitForConnection(String deviceId) async {
    int attempts = 0;
    const maxAttempts = 15; // 15 seconds timeout

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 1000));
      attempts++;

      // Check if connected
      if (_connectedDevices.contains(deviceId)) {
        return true;
      }

      // Check if no longer connecting (failed)
      if (!_connectingDevices.contains(deviceId)) {
        return false;
      }

      LoggerDebug.logger.i(
        '[Bluetooth] ⏳ Waiting for connection... Attempt $attempts/$maxAttempts',
      );
    }

    // Timeout
    _connectingDevices.remove(deviceId);
    return false;
  }

  // Helper method to handle connection errors
  void _handleConnectionError(Status? status, {String? errorMessage}) {
    if (status != null) {
      switch (status) {
        case Status.REJECTED:
          LoggerDebug.logger.e(
            '[Bluetooth] Connection rejected by remote device',
          );
          break;
        case Status.ERROR:
          LoggerDebug.logger.e('[Bluetooth] Connection error occurred');
          break;
        case Status.CONNECTED:
          LoggerDebug.logger.i('[Bluetooth] Connected successfully');
          break;
      }
    }

    if (errorMessage != null) {
      LoggerDebug.logger.e('[Bluetooth] Error: $errorMessage');
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
            LoggerDebug.logger.i(
              '🟢 Message received from $endpointId: $message',
            );

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
        onPayloadTransferUpdate:
            (String endpointId, PayloadTransferUpdate payloadTransferUpdate) {
              LoggerDebug.logger.i(
                '🟡 Payload transfer update: $endpointId - ${payloadTransferUpdate.status}',
              );
            },
      );
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error accepting connection: $e');
    }
  }

  // Send message to a connected device
  Future<bool> sendMessage(String deviceId, String message) async {
    try {
      if (!_connectedDevices.contains(deviceId)) {
        LoggerDebug.logger.e(
          '🔴 Cannot send message: not connected to device $deviceId',
        );
        return false;
      }

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

  // Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      await Nearby().disconnectFromEndpoint(deviceId);
      _connectedDevices.remove(deviceId);
      _connectingDevices.remove(deviceId);
      LoggerDebug.logger.i('🟢 Disconnected from device: $deviceId');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error disconnecting from device $deviceId: $e');
    }
  }

  // Disconnect from all devices
  Future<void> disconnectAll() async {
    try {
      await Nearby().stopAllEndpoints();
      _connectedDevices.clear();
      _connectingDevices.clear();
      _discoveredDevices.clear();
      LoggerDebug.logger.i('🟢 Disconnected from all devices');
    } catch (e) {
      LoggerDebug.logger.e('🔴 Error disconnecting from all devices: $e');
    }
  }

  // Get list of connected devices
  List<String> getConnectedDevices() {
    return _connectedDevices.toList();
  }

  // Get list of discovered devices
  Map<String, NearbayDeviceInfo> getDiscoveredDevices() {
    return Map.from(_discoveredDevices);
  }

  // Send message to all connected devices
  Future<void> sendMessageToAll(String message) async {
    final connectedDevicesList = _connectedDevices.toList();

    for (String deviceId in connectedDevicesList) {
      await sendMessage(deviceId, message);
    }
  }

  // Clear discovered devices (for compatibility)
  void clearDiscoveredDevices() {
    _discoveredDevices.clear();
    LoggerDebug.logger.i('🟢 Cleared discovered devices cache');
  }

  // Dispose streams
  void dispose() {
    _deviceFoundController.close();
    _deviceLostController.close();
    _deviceConnectedController.close();
    _messageReceivedController.close();
  }
}
