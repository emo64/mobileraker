import 'dart:async';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/data/data_source/json_rpc_client.dart';
import 'package:mobileraker/data/dto/jrpc/rpc_response.dart';
import 'package:mobileraker/data/dto/power/power_device.dart';
import 'package:mobileraker/data/dto/power/power_state.dart';
import 'package:mobileraker/logger.dart';
import 'package:mobileraker/service/moonraker/jrpc_client_provider.dart';
import 'package:mobileraker/service/selected_machine_service.dart';
import 'package:mobileraker/util/ref_extension.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'power_service.g.dart';

@riverpod
PowerService powerService(PowerServiceRef ref, String machineUUID) {
  var jsonRpcClient = ref.watch(jrpcClientProvider(machineUUID));
  return PowerService(ref, jsonRpcClient, machineUUID);
}

@riverpod
Stream<List<PowerDevice>> powerDevices(
    PowerDevicesRef ref, String machineUUID) {
  return ref.watch(powerServiceProvider(machineUUID)).devices;
}

@riverpod
PowerService powerServiceSelected(PowerServiceSelectedRef ref) {
  return ref.watch(powerServiceProvider(
      ref.watch(selectedMachineProvider).valueOrNull!.uuid));
}

@riverpod
Stream<List<PowerDevice>> powerDevicesSelected(
    PowerDevicesSelectedRef ref) async* {
  try {
    var machine = await ref.watchWhereNotNull(selectedMachineProvider);

    StreamController<List<PowerDevice>> sc =
        StreamController<List<PowerDevice>>();
    ref.onDispose(() {
      if (!sc.isClosed) {
        sc.close();
      }
    });
    ref.listen<AsyncValue<List<PowerDevice>>>(
        powerDevicesProvider(machine.uuid), (previous, next) {
      next.when(
          data: (data) => sc.add(data),
          error: (err, st) => sc.addError(err, st),
          loading: () {
            if (previous != null) ref.invalidateSelf();
          });
    }, fireImmediately: true);

    yield* sc.stream;
  } on StateError catch (_) {
// Just catch it. It is expected that the future/where might not complete!
  }
}

/// The PowerService handels interactions with Moonraker's Power API
/// For more information check out
/// 1. https://moonraker.readthedocs.io/en/latest/web_api/#power-apis
class PowerService {
  PowerService(AutoDisposeRef ref, this._jRpcClient, String machineUUID) {
    ref.onDispose(dispose);
    _jRpcClient.addMethodListener(_onPowerChanged, "notify_power_changed");
    ref.listen(jrpcClientStateProvider(machineUUID), (previous, next) {
      switch (next.valueOrNull) {
        case ClientState.connected:
          _init();
          break;
        default:
      }
    }, fireImmediately: true);
  }

  final StreamController<List<PowerDevice>> _devicesStreamCtler =
      StreamController();

  List<PowerDevice>? __current;

  set _current(List<PowerDevice> p) {
    __current = p;
    if (!_devicesStreamCtler.isClosed) _devicesStreamCtler.add(p);
  }

  Stream<List<PowerDevice>> get devices => _devicesStreamCtler.stream;

  final JsonRpcClient _jRpcClient;

  /// https://moonraker.readthedocs.io/en/latest/web_api/#get-device-list
  Future<List<PowerDevice>> getDeviceList() async {
    try {
      RpcResponse rpcResponse =
          await _jRpcClient.sendJRpcMethod('machine.device_power.devices');
      logger.i('Fetching [power] devices!');
      List<Map<String, dynamic>> devices =
          rpcResponse.result['devices'].cast<Map<String, dynamic>>();
      return List.generate(
          devices.length, (index) => PowerDevice.fromJson(devices[index]),
          growable: false);
    } on JRpcError catch (e, s) {
      logger.e('Error while trying to fetch [power] devices!', e, s);
      return List.empty();
    }
  }

  /// https://moonraker.readthedocs.io/en/latest/web_api/#set-device-state
  Future<PowerState> setDeviceStatus(
      String deviceName, PowerState state) async {
    try {
      RpcResponse rpcResponse = await _jRpcClient.sendJRpcMethod(
          'machine.device_power.post_device',
          params: {'device': deviceName, 'action': state.name});
      logger.i('Setting [power] device "$deviceName" -> $state!');

      Map<String, dynamic> result = rpcResponse.result;
      return EnumToString.fromString(PowerState.values, result[deviceName]) ??
          PowerState.off;
    } on JRpcError catch (e, s) {
      logger.e(
          'Error while trying to set state of [power] device with name "$deviceName"!',
          s);
      return PowerState.off;
    }
  }

  /// https://moonraker.readthedocs.io/en/latest/web_api/#get-device-status
  Future<PowerState> getDeviceStatus(String deviceName) async {
    try {
      RpcResponse rpcResponse = await _jRpcClient.sendJRpcMethod(
          'machine.device_power.get_device',
          params: {'device': deviceName});
      logger.i('Fetching [power] device state of "$deviceName" !');

      Map<String, dynamic> result = rpcResponse.result;
      return EnumToString.fromString(PowerState.values, result[deviceName]) ??
          PowerState.off;
    } on JRpcError catch (e, s) {
      logger.e(
          'Error while trying to fetch state of [power] device with name "$deviceName"!',
          s);
      return PowerState.off;
    }
  }

  _init() async {
    var devices = await getDeviceList();
    _current = devices;
  }

  _onPowerChanged(Map<String, dynamic> rawMessage) {
    List<Map<String, dynamic>> devices =
        rawMessage['params'].cast<Map<String, dynamic>>();

    List<PowerDevice> parsed = List.generate(
        devices.length, (index) => PowerDevice.fromJson(devices[index]),
        growable: false);
    if (__current == null || __current!.isEmpty) return;

    var result = __current!.map((e) {
      return parsed.firstWhere((p) => p.name == e.name, orElse: () => e);
    }).toList(growable: false);

    logger.v('Updated powerDevices to: $result');
    _current = result;
  }

  dispose() {
    _jRpcClient.removeMethodListener(_onPowerChanged, "notify_power_changed");
    _devicesStreamCtler.close();
  }
}
