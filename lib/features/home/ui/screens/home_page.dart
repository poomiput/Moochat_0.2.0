import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/core/shared/providers/managing_bluetooth_state_privder.dart';
import 'package:moochat/core/shared/providers/messages_handeler_provider.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/widgets/loading_animation.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';
import 'package:moochat/features/home/services/nearby_premission.dart';
import 'package:moochat/features/home/ui/widgets/add_new_contact_box.dart';
import 'package:moochat/features/home/ui/widgets/add_user_with_keyboard.dart';
import 'package:moochat/features/home/ui/widgets/chat_row_data.dart';
import 'package:moochat/features/home/ui/widgets/custom_app_bar.dart';
import 'package:moochat/features/home/ui/widgets/error_loaded_user_data.dart';
import 'package:moochat/features/home/ui/widgets/header_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/home/ui/widgets/no_chat_yet_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hasStartedBluetooth = false;

  @override
  void initState() {
    super.initState();
    CorePermissionHandler.onBluetoothEnabled();
    _initializeBluetooth();

    // Initialize message handler after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageHandlerInitProvider);
    });
  }

  void _initializeBluetooth() async {
    if (_hasStartedBluetooth) return;

    try {
      // Start advertising using the provider
      await ref.read(nearbayStateProvider.notifier).startAdvertising();

      // Start discovery using the provider
      await ref.read(nearbayStateProvider.notifier).startDiscovery();

      // Start connection monitoring for stability
      ref.read(nearbayStateProvider.notifier).startConnectionMonitoring();

      _hasStartedBluetooth = true;
      LoggerDebug.logger.d('Bluetooth services started successfully');

      // Try to connect to discovered devices after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        ref.read(nearbayStateProvider.notifier).tryConnectToDiscoveredDevices();
      });
    } catch (e) {
      LoggerDebug.logger.e('Error starting bluetooth services: $e');
    }
  }

  // Helper method to check if a user is online based on discovered devices
  bool _isUserOnline(
    String username,
    List<dynamic> discoveredDevices,
    List<dynamic> connectedDevices,
  ) {
    // Priority 1: Check connected devices first (most reliable)
    if (connectedDevices.isNotEmpty) {
      final isConnected = connectedDevices.any(
        (device) => device.uuid == username || device.id == username,
      );
      if (isConnected) {
        LoggerDebug.logger.d(
          '🟦 ONLINE CHECK: $username found in CONNECTED devices',
        );
        return true;
      }
    }

    // Priority 2: Check discovered devices (less reliable but still valid)
    if (discoveredDevices.isNotEmpty) {
      final isDiscovered = discoveredDevices.any(
        (device) => device.uuid == username || device.id == username,
      );
      if (isDiscovered) {
        LoggerDebug.logger.d(
          '🟦 ONLINE CHECK: $username found in DISCOVERED devices',
        );
        return true;
      }
    }

    LoggerDebug.logger.d('🟦 ONLINE CHECK: $username NOT FOUND in any devices');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final bluetoothState = ref.watch(nearbayStateProvider);

    return Scaffold(
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reconnection button
          FloatingActionButton(
            heroTag: "reconnect",
            onPressed: () {
              LoggerDebug.logger.i('🔄 Manual reconnection triggered');
              ref.read(nearbayStateProvider.notifier).clearAllDevices();
              Future.delayed(const Duration(seconds: 1), () {
                ref.read(nearbayStateProvider.notifier).startAdvertising();
                ref.read(nearbayStateProvider.notifier).startDiscovery();
              });
            },
            backgroundColor: const Color.fromARGB(255, 87, 83, 78),
            child: Icon(
              Icons.refresh,
              color: ColorsManager.whiteColor,
              size: 25.sp,
            ),
          ),
          SizedBox(height: 10.h),
          // Add user button
          FloatingActionButton(
            heroTag: "addUser",
            onPressed: () {
              showDialog(context: context, builder: (_) => AddUserDialog());
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: ColorsManager.customGray,
            child: Icon(
              Icons.keyboard,
              color: ColorsManager.whiteColor,
              size: 30.sp,
            ),
          ),
        ],
      ),
      backgroundColor: ColorsManager.backgroundColor,
      appBar: CustomAppBar(),

      body: userDataAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomLoadingAnimation(size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'Loading user data...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: ColorsManager.whiteColor,
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => ErrorLoadedUserData(error: error),
        data: (userData) => SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 0.h),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Header(userName: userData.username),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 220.h),
                child: _buildChatList(
                  userData.userChats.chats,
                  context,
                  bluetoothState.discoveredDevices,
                  bluetoothState.connectedDevices,
                ),
              ),
              SizedBox(height: 100.h), // Spacer for the header
              Positioned(
                bottom: 15.h,
                left: 90.w,
                right: 80.w,
                child: AddNewContactBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(
    List<dynamic> chats,
    BuildContext orContext,
    List<dynamic> discoveredDevices,
    List<dynamic> connectedDevices,
  ) {
    // If no chats exist, show empty state
    if (chats.isEmpty) {
      return NoChatYet();
    }

    return _buildChatListView(
      chats,
      orContext,
      discoveredDevices,
      connectedDevices,
    );
  }

  Widget _buildChatListView(
    List<dynamic> chats,
    BuildContext orContext,
    List<dynamic> discoveredDevices,
    List<dynamic> connectedDevices,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: 80.h,
        left: 5.w,
        right: 5.w,
      ), // Space for the AddNewContactBox
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final UserChat chat = chats[index];

        // Check if this user is online by looking in discovered devices
        final bool isOnline = _isUserOnline(
          chat.uuid2P,
          discoveredDevices,
          connectedDevices,
        );

        // Debug log for UI status
        LoggerDebug.logger.d(
          '🟦 HOME UI DEBUG: User ${chat.username2P} (${chat.uuid2P}) online status: $isOnline',
        );
        LoggerDebug.logger.d(
          '🟦 HOME UI DEBUG: Connected devices: ${connectedDevices.map((d) => d.uuid).join(", ")}',
        );
        LoggerDebug.logger.d(
          '🟦 HOME UI DEBUG: Discovered devices: ${discoveredDevices.map((d) => d.uuid).join(", ")}',
        );

        return ChatRowData(
          userData2P: chat,
          userName: chat.username2P,
          // check if message is location type show location word else that message text
          lastMessage: chat.messages.isNotEmpty
              ? chat.messages.last.type == MessageType.location
                    ? '⟟ ${orContext.tr("location")}'
                    : chat.messages.last.text
              : orContext.tr("no_messages"),
          time: chat.messages.isNotEmpty ? chat.messages.last.timestamp : null,
          isOnline: isOnline, // Now dynamically set based on discovery
          unreadCount: 0, // Replace with actual data
          messageStatus: chat.messages.isNotEmpty
              ? chat.messages.last.status
              : MessageStatus.sent, // Replace with actual data
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up bluetooth services when page is disposed
    if (_hasStartedBluetooth) {
      ref.read(nearbayStateProvider.notifier).stopAdvertising();
      ref.read(nearbayStateProvider.notifier).stopDiscovery();
    }
    super.dispose();
  }
}
