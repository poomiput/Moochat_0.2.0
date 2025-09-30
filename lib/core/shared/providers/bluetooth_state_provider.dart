import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// stream provider that directly listens to FlutterBluePlus
final bluetoothStateStreamProvider = StreamProvider<BluetoothAdapterState>((
  ref,
) {
  return FlutterBluePlus.adapterState;
});

// create provider that returns boolean based on bluetooth state
final isBluetoothOnProvider = Provider<bool>((ref) {
  final bluetoothStateAsync = ref.watch(bluetoothStateStreamProvider);

  return bluetoothStateAsync.when(
    data: (state) => state == BluetoothAdapterState.on,
    loading: () => false, // Default to false while loading
    error: (error, stack) => false, // Default to false on error
  );
});
