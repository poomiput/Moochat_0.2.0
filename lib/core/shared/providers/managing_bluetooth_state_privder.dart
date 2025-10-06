import 'dart:async';
import 'dart:convert'; // Add this import for UTF-8 encoding
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/helpers/shared_prefences.dart';
import 'package:moochat/core/shared/models/nearbay_device_info.dart';
import 'package:moochat/core/shared/services/bluetooth_services_v2.dart';
import 'package:moochat/features/home/services/notifications_service.dart';

// Provider for managing Bluetooth s discovered and connected devices
final nearbayStateProvider =
    StateNotifierProvider<BluetoothStateNotifier, BluetoothState>((ref) {
      return BluetoothStateNotifier();
    });

class BluetoothState {
  final List<NearbayDeviceInfo> discoveredDevices;
  final List<NearbayDeviceInfo> connectedDevices;
  final bool isAdvertising;
  final bool isDiscovering;
  final Stream<Map<String, String>>? messageStream;

  const BluetoothState({
    this.discoveredDevices = const [],
    this.connectedDevices = const [],
    this.isAdvertising = false,
    this.isDiscovering = false,
    this.messageStream,
  });

  BluetoothState copyWith({
    List<NearbayDeviceInfo>? discoveredDevices,
    List<NearbayDeviceInfo>? connectedDevices,
    bool? isAdvertising,
    bool? isDiscovering,
    Stream<Map<String, String>>? messageStream,
  }) {
    return BluetoothState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      messageStream: messageStream ?? this.messageStream,
    );
  }
}

class BluetoothStateNotifier extends StateNotifier<BluetoothState> {
  BluetoothStateNotifier() : super(const BluetoothState()) {
    _initializeListeners();
    // Expose message stream
    state = state.copyWith(messageStream: _bluetoothService.onMessageReceived);
  }

  final BluetoothServicesmoochat _bluetoothService = BluetoothServicesmoochat();

  StreamSubscription<NearbayDeviceInfo>? _deviceFoundSubscription;
  StreamSubscription<String>? _deviceLostSubscription;
  StreamSubscription<NearbayDeviceInfo>? _deviceConnectedSubscription;
  StreamSubscription<Map<String, String>>? _messageReceivedSubscription;

  // Method to get UUID by device ID - delegates to bluetooth service
  String? getUuidByDeviceId(String deviceId) {
    return _bluetoothService.getUuidByDeviceId(deviceId);
  }

  // Method to get discovered device info by device ID
  NearbayDeviceInfo? getDiscoveredDeviceById(String deviceId) {
    return _bluetoothService.getDiscoveredDeviceById(deviceId);
  }

  void _initializeListeners() {
    // Listen for discovered devices
    _deviceFoundSubscription = _bluetoothService.onDeviceFound.listen((device) {
      LoggerDebug.logger.d('Device found: ${device.id}');
      _addDiscoveredDevice(device);
    });

    // Listen for lost devices
    _deviceLostSubscription = _bluetoothService.onDeviceLost.listen((deviceId) {
      LoggerDebug.logger.d('Device lost: $deviceId');
      _removeDevice(deviceId);
    });

    // Listen for connected devices
    _deviceConnectedSubscription = _bluetoothService.onDeviceConnected.listen((
      device,
    ) {
      LoggerDebug.logger.d(
        'Device connected: ${device.id} with UUID: ${device.uuid}',
      );
      _addConnectedDevice(device);
    });

    // Listen for received messages
    _messageReceivedSubscription = _bluetoothService.onMessageReceived.listen((
      messageData,
    ) {
      LoggerDebug.logger.d(
        'Message received: ${messageData['message']} from ${messageData['senderId']}',
      );
      // You can handle received messages here or expose through another stream
    });
  }

  void _addDiscoveredDevice(NearbayDeviceInfo device) {
    // Check if device already exists in discovered list
    final existingIndex = state.discoveredDevices.indexWhere(
      (d) => d.id == device.id,
    );

    if (existingIndex == -1) {
      // Add new device
      final updatedDiscovered = [...state.discoveredDevices, device];
      state = state.copyWith(discoveredDevices: updatedDiscovered);

      LoggerDebug.logger.i(
        '🟢 RMX3085 DEBUG: New device discovered: ${device.uuid} (${device.id})',
      );
      LoggerDebug.logger.i(
        '🟢 RMX3085 DEBUG: Total discovered devices: ${updatedDiscovered.length}',
      );

      // Auto-connect immediately for RMX3085
      Future.delayed(const Duration(milliseconds: 500), () {
        LoggerDebug.logger.i(
          '🟢 RMX3085 DEBUG: Auto-connecting to ${device.uuid}',
        );
        connectToDevice(device.id, device.uuid);
      });

      // show notifiication to show user how length of discovered devices
      NotificationService().showNotification(
        id: 1, // Unique ID for the notification
        title: 'device_found_title'.tr(),
        body: '${updatedDiscovered.length} ${'device_found_body'.tr()}',
      );
    }
  }

  void _addConnectedDevice(NearbayDeviceInfo device) {
    // Check if device already exists in connected list
    final existingIndex = state.connectedDevices.indexWhere(
      (d) => d.id == device.id,
    );

    if (existingIndex == -1) {
      // Add to connected devices
      final updatedConnected = [...state.connectedDevices, device];
      // Remove from discovered devices if it exists there
      final updatedDiscovered = state.discoveredDevices
          .where((d) => d.id != device.id)
          .toList();

      state = state.copyWith(
        connectedDevices: updatedConnected,
        discoveredDevices: updatedDiscovered,
      );

      LoggerDebug.logger.i(
        'Device added to connected list: ${device.uuid} (${device.id})',
      );
      LoggerDebug.logger.i(
        'Total connected devices: ${updatedConnected.length}',
      );

      // Send immediate ping to verify connection
      _verifyConnection(device);
    }
  }

  void _verifyConnection(NearbayDeviceInfo device) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final pingMessage = {
        'type': 'connection_verify',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await sendMessageToDevice(device.id, jsonEncode(pingMessage));
      LoggerDebug.logger.i('Connection verification sent to ${device.uuid}');
    } catch (e) {
      LoggerDebug.logger.e('Failed to verify connection to ${device.uuid}: $e');
    }
  }

  void _removeDevice(String deviceId) {
    // Remove from both discovered and connected lists
    final updatedDiscovered = state.discoveredDevices
        .where((d) => d.id != deviceId)
        .toList();
    final updatedConnected = state.connectedDevices
        .where((d) => d.id != deviceId)
        .toList();

    state = state.copyWith(
      discoveredDevices: updatedDiscovered,
      connectedDevices: updatedConnected,
    );
  }

  Future<void> startAdvertising() async {
    // Check if already advertising to prevent multiple calls
    if (state.isAdvertising) {
      LoggerDebug.logger.w('Advertising already in progress');
      return;
    }

    try {
      final String username = await SharedPrefHelper.getString('uuid');
      LoggerDebug.logger.i(
        '🔴 RMX3085 DEBUG: Starting advertising with UUID: $username',
      );

      await _bluetoothService.startAdvertising(username);

      state = state.copyWith(isAdvertising: true);
      LoggerDebug.logger.i(
        '🔴 RMX3085 DEBUG: Advertising started successfully',
      );
    } catch (e) {
      LoggerDebug.logger.e('🔴 RMX3085 DEBUG: Error starting advertising: $e');
      // Reset advertising state if it failed
      state = state.copyWith(isAdvertising: false);
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _bluetoothService.stopAdvertising();
      state = state.copyWith(isAdvertising: false);
      LoggerDebug.logger.d('Stopped advertising');
    } catch (e) {
      LoggerDebug.logger.e('Error stopping advertising: $e');
    }
  }

  Future<void> startDiscovery() async {
    // Check if already discovering to prevent multiple calls
    if (state.isDiscovering) {
      LoggerDebug.logger.w('Discovery already in progress');
      return;
    }

    try {
      final String username = await SharedPrefHelper.getString('uuid');
      LoggerDebug.logger.i(
        '🔵 RMX3085 DEBUG: Starting discovery with UUID: $username',
      );

      await _bluetoothService.startDiscovery(username);

      state = state.copyWith(isDiscovering: true);
      LoggerDebug.logger.i('🔵 RMX3085 DEBUG: Discovery started successfully');
    } catch (e) {
      LoggerDebug.logger.e('🔵 RMX3085 DEBUG: Error starting discovery: $e');
      // Reset discovery state if it failed
      state = state.copyWith(isDiscovering: false);
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _bluetoothService.stopDiscovery();
      state = state.copyWith(isDiscovering: false);
      LoggerDebug.logger.d('Stopped discovery');
    } catch (e) {
      LoggerDebug.logger.e('Error stopping discovery: $e');
    }
  }

  Future<void> connectToDevice(String deviceId, String uuid) async {
    try {
      // Find the device in discovered devices to get its username
      final device = state.discoveredDevices
          .where((d) => d.id == deviceId)
          .firstOrNull;
      if (device == null) {
        LoggerDebug.logger.e(
          '🔴 RMX3085 DEBUG: Device not found in discovered devices: $deviceId',
        );
        return;
      }

      LoggerDebug.logger.i(
        '🟡 RMX3085 DEBUG: Requesting connection to: $deviceId ($uuid)',
      );

      // Get current user name for connection
      final userName = await SharedPrefHelper.getString('uuid') ?? 'MooChat';
      await _bluetoothService.requestConnection(deviceId, userName);

      LoggerDebug.logger.i(
        '🟡 RMX3085 DEBUG: Connection request sent to: $deviceId',
      );
    } catch (e) {
      LoggerDebug.logger.e('🔴 RMX3085 DEBUG: Error connecting to device: $e');
    }
  }

  // Connect to all discovered devices
  Future<void> connectToAllDiscoveredDevices() async {
    LoggerDebug.logger.i('Attempting to connect to all discovered devices');
    for (final device in state.discoveredDevices) {
      // Check if already connected
      final isAlreadyConnected = state.connectedDevices.any(
        (conn) => conn.id == device.id,
      );
      if (!isAlreadyConnected) {
        LoggerDebug.logger.i(
          'Connecting to device: ${device.uuid} (${device.id})',
        );
        await connectToDevice(device.id, device.uuid);
        // Add small delay between connection attempts
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
  }

  // Manual method to trigger connections
  Future<void> tryConnectToDiscoveredDevices() async {
    if (state.discoveredDevices.isNotEmpty && state.connectedDevices.isEmpty) {
      LoggerDebug.logger.i(
        'No connected devices, attempting to connect to discovered devices',
      );
      await connectToAllDiscoveredDevices();
    }
  }

  /// Enhanced message sending with UTF-8 encoding support and retry mechanism
  Future<bool> sendMessageToDevice(String deviceId, String message) async {
    const int maxRetries = 3;

    // Check if device is actually connected
    final isConnected = state.connectedDevices.any((d) => d.id == deviceId);
    LoggerDebug.logger.i(
      '🟡 RMX3085 DEBUG: Device $deviceId connected status: $isConnected',
    );

    if (!isConnected) {
      LoggerDebug.logger.e(
        '🔴 RMX3085 DEBUG: Cannot send message - device $deviceId not connected',
      );
      return false;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Encode message to handle Thai characters properly
        final encodedMessage = _encodeMessage(message);

        LoggerDebug.logger.i(
          '🟡 RMX3085 DEBUG: Sending message to $deviceId (attempt $attempt)',
        );
        LoggerDebug.logger.i(
          '🟡 RMX3085 DEBUG: Message length: ${message.length}, Encoded: ${encodedMessage.length}',
        );

        final result = await _bluetoothService.sendMessage(
          deviceId,
          encodedMessage,
        );

        if (result) {
          LoggerDebug.logger.i(
            '🟢 RMX3085 DEBUG: Message sent successfully to $deviceId on attempt $attempt',
          );
          return true;
        } else {
          LoggerDebug.logger.w(
            '🟠 RMX3085 DEBUG: Message send failed to $deviceId on attempt $attempt',
          );
        }
      } catch (e) {
        LoggerDebug.logger.e(
          'Error sending message to device on attempt $attempt: $e',
        );
      }

      // Wait before retry (except on last attempt)
      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    LoggerDebug.logger.e(
      'Failed to send message to $deviceId after $maxRetries attempts',
    );
    return false;
  }

  /// Enhanced message broadcasting with UTF-8 encoding support
  Future<void> sendMessageToAll(String message) async {
    try {
      // Encode message to handle Thai characters properly
      final encodedMessage = _encodeMessage(message);

      LoggerDebug.logger.d('Broadcasting message: $message');
      LoggerDebug.logger.d('Encoded message length: ${encodedMessage.length}');

      await _bluetoothService.sendMessageToAll(encodedMessage);
      LoggerDebug.logger.d('Message sent to all connected devices');
    } catch (e) {
      LoggerDebug.logger.e('Error sending message to all devices: $e');
    }
  }

  /// Encodes message for proper UTF-8 transmission over Bluetooth
  String _encodeMessage(String message) {
    try {
      // Method 1: Base64 encoding (recommended for Bluetooth)
      final utf8Bytes = utf8.encode(message);
      final base64Encoded = base64Encode(utf8Bytes);

      LoggerDebug.logger.d('Original message: $message');
      LoggerDebug.logger.d('UTF-8 bytes: $utf8Bytes');
      LoggerDebug.logger.d('Base64 encoded: $base64Encoded');

      return base64Encoded;
    } catch (e) {
      LoggerDebug.logger.e('Error encoding message: $e');
      // Fallback to original message
      return message;
    }
  }

  /// Send a structured message (for chat messages with metadata)
  Future<bool> sendChatMessage(
    String deviceId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      // Convert message data to JSON
      final jsonString = jsonEncode(messageData);

      // Encode the JSON string for safe transmission
      final encodedMessage = _encodeMessage(jsonString);

      LoggerDebug.logger.d('Sending chat message to $deviceId');
      LoggerDebug.logger.d('Message data: $messageData');

      return await sendMessageToDevice(deviceId, encodedMessage);
    } catch (e) {
      LoggerDebug.logger.e('Error sending chat message: $e');
      return false;
    }
  }

  /// Broadcast a structured message to all connected devices
  Future<void> broadcastChatMessage(Map<String, dynamic> messageData) async {
    try {
      // Convert message data to JSON
      final jsonString = jsonEncode(messageData);

      // Encode the JSON string for safe transmission
      final encodedMessage = _encodeMessage(jsonString);

      LoggerDebug.logger.d('Broadcasting chat message');
      LoggerDebug.logger.d('Message data: $messageData');

      await sendMessageToAll(encodedMessage);
    } catch (e) {
      LoggerDebug.logger.e('Error broadcasting chat message: $e');
    }
  }

  // Get connected device by username
  NearbayDeviceInfo? getConnectedDeviceByUsername(String username) {
    try {
      return state.connectedDevices.firstWhere(
        (device) => device.uuid == username,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if a specific user is connected
  bool isUserConnected(String username) {
    final isConnected = state.connectedDevices.any(
      (device) => device.uuid == username,
    );
    LoggerDebug.logger.d('Checking connection for $username: $isConnected');
    LoggerDebug.logger.d(
      'Connected devices: ${state.connectedDevices.map((d) => d.uuid).join(", ")}',
    );
    return isConnected;
  }

  // Monitor connection health
  Timer? _connectionMonitor;

  void startConnectionMonitoring() {
    _connectionMonitor?.cancel();
    // Check more frequently for better stability
    _connectionMonitor = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectionHealth();
    });
    LoggerDebug.logger.i(
      'Started aggressive connection monitoring (every 5 seconds)',
    );
  }

  void _checkConnectionHealth() async {
    try {
      LoggerDebug.logger.d('Checking connection health...');
      LoggerDebug.logger.d(
        'Connected devices: ${state.connectedDevices.length}',
      );
      LoggerDebug.logger.d(
        'Discovered devices: ${state.discoveredDevices.length}',
      );

      // If we have discovered devices but no connections, try to reconnect
      if (state.discoveredDevices.isNotEmpty &&
          state.connectedDevices.isEmpty) {
        LoggerDebug.logger.w(
          'No connections but devices discovered, attempting reconnection',
        );
        await tryConnectToDiscoveredDevices();
      }

      // Send keep-alive ping to connected devices
      await _sendKeepAlivePing();

      // Force reconnection if no devices found
      if (state.discoveredDevices.isEmpty && state.connectedDevices.isEmpty) {
        LoggerDebug.logger.w(
          '🔴 RMX3085 DEBUG: No devices found, forcing full restart',
        );
        await _forceFullReconnection();
      }

      // Try to reconnect to discovered devices if not connected
      if (state.discoveredDevices.isNotEmpty &&
          state.connectedDevices.isEmpty) {
        LoggerDebug.logger.w(
          '🟡 RMX3085 DEBUG: Have discovered devices but no connections, reconnecting',
        );
        await tryConnectToDiscoveredDevices();
      }
    } catch (e) {
      LoggerDebug.logger.e('Error in connection health check: $e');
    }
  }

  Future<void> _sendKeepAlivePing() async {
    try {
      for (final device in state.connectedDevices) {
        final pingMessage = {
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        };
        // Don't wait for response, just send ping
        sendMessageToDevice(device.id, jsonEncode(pingMessage));
      }
    } catch (e) {
      LoggerDebug.logger.e('Error sending keep-alive ping: $e');
    }
  }

  Future<void> _forceFullReconnection() async {
    try {
      LoggerDebug.logger.w(
        '🔴 RMX3085 DEBUG: Starting force full reconnection',
      );

      // Stop everything completely
      await stopDiscovery();
      await stopAdvertising();

      // Clear all device lists
      clearAllDevices();

      // Wait longer for complete reset
      await Future.delayed(const Duration(seconds: 5));

      // Restart advertising first
      LoggerDebug.logger.i('🔴 RMX3085 DEBUG: Restarting advertising');
      await startAdvertising();

      // Wait a bit then start discovery
      await Future.delayed(const Duration(seconds: 2));
      LoggerDebug.logger.i('🔵 RMX3085 DEBUG: Restarting discovery');
      await startDiscovery();

      // Schedule auto-connection attempt
      Future.delayed(const Duration(seconds: 10), () {
        LoggerDebug.logger.i(
          '🟡 RMX3085 DEBUG: Attempting auto-reconnection after restart',
        );
        tryConnectToDiscoveredDevices();
      });

      LoggerDebug.logger.i(
        '🟢 RMX3085 DEBUG: Force full reconnection completed',
      );
    } catch (e) {
      LoggerDebug.logger.e(
        '🔴 RMX3085 DEBUG: Error in force full reconnection: $e',
      );
    }
  }

  void clearAllDevices() {
    state = state.copyWith(discoveredDevices: [], connectedDevices: []);
    // Also clear the bluetooth service cache
    _bluetoothService.clearDiscoveredDevices();
    LoggerDebug.logger.i('🔴 RMX3085 DEBUG: All device lists cleared');
  }

  @override
  void dispose() {
    _connectionMonitor?.cancel();
    _deviceFoundSubscription?.cancel();
    _deviceLostSubscription?.cancel();
    _deviceConnectedSubscription?.cancel();
    _messageReceivedSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}
