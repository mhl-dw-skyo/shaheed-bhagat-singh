import 'dart:io';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsController extends GetxController {
  Rx<PermissionStatus> location = PermissionStatus.denied.obs;
  Rx<PermissionStatus> storage = PermissionStatus.denied.obs;
  Rx<PermissionStatus> ble = PermissionStatus.denied.obs;
  Rx<PermissionStatus> bleConnect = PermissionStatus.denied.obs;
  Rx<PermissionStatus> bleScan = PermissionStatus.denied.obs;
  RxString status = "".obs;

  @override
  void onInit() {
    super.onInit();
    checkDefault(init: true);
  }

  Future<void> checkDefault({required bool init}) async {
    // Location
    if (Platform.isIOS) {
      location.value = await Permission.locationWhenInUse.status;
    } else {
      location.value = await Permission.location.status;
    }

    // Storage (Android only, ignored on iOS)
    storage.value = await Permission.storage.status;

    // Bluetooth
    ble.value = await Permission.bluetooth.status;
    bleConnect.value = await Permission.bluetoothConnect.status;
    bleScan.value = await Permission.bluetoothScan.status;
  }

  Future<void> askForLocation() async {
    try {
      if (Platform.isIOS) {
        location.value = await Permission.locationWhenInUse.request();
      } else {
        location.value = await Permission.location.request();
      }
      validate();
    } catch (ee) {
      print("Error requesting location: $ee");
    }
  }

  Future<void> askForStorage() async {
    if (Platform.isAndroid) {
      storage.value = await Permission.storage.request();
    }
  }

  Future<void> askForBluetooth() async {
    try {
      if (Platform.isIOS) {
        // iOS has only generic bluetooth permission
        ble.value = await Permission.bluetooth.request();
      } else {
        // Android 12+ needs scan/connect separately
        bleScan.value = await Permission.bluetoothScan.request();
        bleConnect.value = await Permission.bluetoothConnect.request();
      }
      validate();
    } catch (ee) {
      print("Error requesting bluetooth: $ee");
    }
  }

  Future<void> askForBluetoothConnect() async {
    if (Platform.isAndroid) {
      bleConnect.value = await Permission.bluetoothConnect.request();
      validate();
    }
  }

  Future<void> askForBluetoothScan() async {
    if (Platform.isAndroid) {
      bleScan.value = await Permission.bluetoothScan.request();
      bleConnect.value = await Permission.bluetoothConnect.request();
      validate();
    }
  }

  void validate() {
    if (granted()) {
      Get.back(result: true);
    }
  }

  bool granted() {
    if (Platform.isAndroid) {
      return bleConnect.value == PermissionStatus.granted &&
          bleScan.value == PermissionStatus.granted &&
          location.value == PermissionStatus.granted;
    } else {
      return ble.value == PermissionStatus.granted &&
          location.value == PermissionStatus.granted;
    }
  }
}
