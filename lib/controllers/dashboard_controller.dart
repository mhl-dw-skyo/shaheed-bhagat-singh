import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:punjab_tourism/controllers/permmisions_controller.dart';
import 'package:punjab_tourism/utils.dart';
import 'package:punjab_tourism/views/permissions_widget.dart';

import '../core.dart';

class Beacon {
  final String proximityUUID;
  final int rssi;

  Beacon({required this.proximityUUID, required this.rssi});
}

class DashboardController extends GetxController {
  ScrollController scrollController = ScrollController();
  var buttonLoader = false.obs;
  var loader = false.obs;
  CommonService commonService = Get.find();
  var name = "".obs;
  var phoneNo = "".obs;
  var title = "".obs;
  var message = "".obs;
  var skipFirstTimeSteamData = true.obs;
  List<Beacon> beaconsJsonData = [];
  StreamSubscription<BluetoothAdapterState>? _streamBluetooth;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool authorizationStatusOk = false;
  bool locationServiceEnabled = false;
  bool bluetoothEnabled = false;
  var catId = 0.obs;
  final _beacons = <Beacon>[];
  final GlobalKey<FormState> complaintFormKey = GlobalKey<FormState>();

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  Future<bool> permissionGranted() async {
    var location = await Permission.location.isGranted;
    var btConnect = await Permission.bluetoothConnect.isGranted;
    var btScan = await Permission.bluetoothScan.isGranted;
    var ble = await Permission.bluetooth.isGranted;
    if (Platform.isAndroid)
      return location && btConnect && btScan && ble;
    else
      return location && ble;
  }

  initBeaconService({required Function(BluetoothAdapterState) onUpdate}) async {
    var permissionsGranted = await permissionGranted();
    if (!permissionsGranted) {
      Get.put(PermissionsController());
      await Get.dialog(PermissionsWidget());
      initBeaconService(onUpdate: onUpdate);
      return;
    }

    _streamBluetooth = FlutterBluePlus.adapterState.listen((state) {
      onUpdate(state);
      if (state == BluetoothAdapterState.on) {
        initScanBeacon();
      } else {
        pauseScanBeacon();
      }
    });
  }

  initScanBeacon() {
    print("Scanning started...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      beaconsJsonData.clear();
      for (ScanResult r in results) {
        final beaconId = r.advertisementData.serviceUuids.isNotEmpty
            ? r.advertisementData.serviceUuids.first
            : r.device.remoteId.str;

        beaconsJsonData.add(Beacon(
          proximityUUID: beaconId.toString(),
          rssi: r.rssi,
        ));
      }

      beaconExecutionAlgorithm();
    });
  }

  pauseScanBeacon() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _beacons.clear();
  }

  beaconExecutionAlgorithm() async {
    if (beaconsJsonData.isEmpty) return;

    Beacon beaconItem = beaconsJsonData.first;
    if (commonService.beaconsData.value.data.isEmpty) return;

    if (commonService.lastPlayedMacAddress.value == beaconItem.proximityUUID) {
      return;
    }

    double deviceDistanceInMeter = (beaconItem.rssi != 0)
        ? double.parse(pow(10, (((beaconItem.rssi).abs() - 59) / (10 * 2)))
        .toStringAsFixed(2))
        : 99999999999999;

    int deviceInOurRangeIndex = commonService.beaconsData.value.data.indexWhere(
            (element) =>
        element.uuid.toLowerCase() ==
            beaconItem.proximityUUID.toString().toLowerCase() &&
            (element.startRange <= deviceDistanceInMeter &&
                deviceDistanceInMeter <= element.endRange));

    if (deviceInOurRangeIndex == -1) return;

    BeaconItem beaconItemObj =
    commonService.beaconsData.value.data[deviceInOurRangeIndex];

    if (beaconItemObj.action == '2') {
      commonService.inMuseum.value = false;
      commonService.inMuseum.refresh();
      AssetsAudioPlayer.allPlayers().forEach((_, player) {
        player.stop();
      });
      commonService.assetsAudioPlayer.value.dispose();
      commonService.assetsAudioPlayer.value = AssetsAudioPlayer();
      commonService.sameCategoryBeacons.clear();
      commonService.sameCategoryBeacons.refresh();
      commonService.lastPlayedMacAddress.value = '';
      commonService.lastPlayedMacAddress.refresh();
      return;
    }

    commonService.inMuseum.value = true;
    commonService.inMuseum.refresh();

    if (commonService.lastPlayedMacAddress.value != beaconItemObj.uuid) {
      commonService.selectedBeacon.value = beaconItemObj;
      commonService.selectedBeacon.refresh();

      if (commonService.selectedFileType.value == "V") {
        if (!commonService.isPopSVPopupOpen.value) {
          Helper.skipVideoConfirmation(beaconItemObj.locationId);
        }
        commonService.isPopSVPopupOpen.value = true;
        commonService.isPopSVPopupOpen.refresh();
      } else {
        if (Get.currentRoute != "/detail") {
          DetailController detailController = Get.find();
          detailController.getLocationDetailData(beaconItemObj.locationId);
          Get.toNamed('/detail');
        } else {
          Get.back();
          DetailController detailController = Get.find();
          detailController.getLocationDetailData(beaconItemObj.locationId);
          Get.toNamed('/detail');
        }
      }
      catId.value = beaconItemObj.type;
    }

    for (var element in commonService.beaconsData.value.data) {
      if (element.type == beaconItemObj.type && element.locationId > 0) {
        int sameTypeBeaconIndex = commonService.sameCategoryBeacons
            .indexWhere((ele) => ele.locationId == element.locationId);
        if (sameTypeBeaconIndex == -1) {
          commonService.sameCategoryBeacons.add(element);
          commonService.sameCategoryBeacons.refresh();
        }
      }
    }

    commonService.lastPlayedMacAddress.value = beaconItemObj.uuid;
    commonService.lastPlayedMacAddress.refresh();
  }

  Future<void> fetchEmpDashboardData() async {
    String file = "dashboard.json";
    if (GetStorage().read('language_id') != '' ||
        GetStorage().read('language_id') != null) {
      switch (GetStorage().read('language_id')) {
        case 1:
          file = "dashboard.json";
          break;
        case 2:
          file = "dashboard_hi.json";
          break;
        case 3:
          file = "dashboard_pu.json";
          break;
      }
    }
    try {
      final String data =
      await rootBundle.loadString('assets/data_files/$file');
      var response = jsonDecode(data);
      if (response['status']) {
        commonService.dashboardData.value = DashboardModel.fromJSON(response);
        commonService.dashboardData.refresh();
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  Future<void> fetchDashboardData() async {
    String file = "dashboard.json";
    if (GetStorage().read('language_id') != '' ||
        GetStorage().read('language_id') != null) {
      switch (GetStorage().read('language_id')) {
        case 1:
          file = "dashboard.json";
          break;
        case 2:
          file = "dashboard_hi.json";
          break;
        case 3:
          file = "dashboard_pu.json";
          break;
      }
    }
    try {
      final String data =
      await rootBundle.loadString('assets/data_files/$file');
      var response = jsonDecode(data);
      if (response['status']) {
        commonService.dashboardData.value = DashboardModel.fromJSON(response);
        commonService.dashboardData.refresh();
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  Future<void> fetchLabelData() async {
    String file = "label.json";
    if (GetStorage().read('language_id') != '' ||
        GetStorage().read('language_id') != null) {
      switch (GetStorage().read('language_id')) {
        case 1:
          file = "label.json";
          break;
        case 2:
          file = "label_hi.json";
          break;
        case 3:
          file = "label_pu.json";
          break;
      }
    }
    try {
      final String data =
      await rootBundle.loadString('assets/data_files/$file');
      var response = jsonDecode(data);
      if (response['status']) {
        commonService.labelData.value = LabelModel.fromJSON(response);
        commonService.labelData.refresh();
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  Future<void> fetchBeaconData() async {
    String file = "beacon.json";
    String folderName = "hindi";

    if (GetStorage().read('language_id') != '' ||
        GetStorage().read('language_id') != null) {
      switch (GetStorage().read('language_id')) {
      // case 1:
      //   file = "beacon.json";
      //   folderName = "english";
      //   break;
      // case 2:
      //   file = "beacon_hi.json";
      //   folderName = "hindi";
      //   break;
      // case 3:
      //   file = "beacon_pu.json";
      //   folderName = "punjabi";
      //   break;
      }
    }
    try {
      final String data =
      await rootBundle.loadString('assets/data_files/$file');
      var response = jsonDecode(data);
      if (response['status'] == 200) {
        commonService.soundFiles.value = [];
        commonService.soundFiles.refresh();
        commonService.beaconsData.value = BeaconModel.fromJSON(response);
        commonService.beaconsData.refresh();
        for (var element in commonService.beaconsData.value.data) {
          if (!commonService.soundFiles.contains(element.soundFile) &&
              element.soundFile.isNotEmpty &&
              element.id > 10) {
            commonService.soundFiles.add(element.soundFile);
          }
          if (!commonService.macAddresses.contains(element.macAddress) &&
              element.macAddress.length == 17) {
            commonService.macAddresses.add(element.macAddress);
          }
          if (!commonService.uuid.contains(element.uuid)) {
            commonService.uuid.add(element.uuid);
          }
        }
        commonService.soundFiles.refresh();
        commonService.macAddresses.refresh();
        commonService.uuid.refresh();
        Directory? appDocDir;
        if (Platform.isAndroid) {
          appDocDir = await getExternalStorageDirectory();
        } else {
          appDocDir = await getApplicationDocumentsDirectory();
        }
        String outputDirectory = '${appDocDir?.path}/$folderName';
        await Directory(outputDirectory).create(recursive: true);
        Helper.downloadAudios(folderName);
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  categoryTypesWidget() {
    Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        "Inside Bhagat Singh Museum"
            .text
            .textStyle(
          headline2().copyWith(
            color: Get.theme.indicatorColor.withOpacity(0.5),
          ),
        )
            .make()
            .pSymmetric(h: 20),
        const SizedBox(
          height: 20,
        ),
        SizedBox(
          width: Get.width,
          height: 60,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: 5,
              itemBuilder: (context, index) {
                LocationModel locationModel =
                LocationModel(image: 'assets/images/1.jpg');
                return SmallLocationViewWidget(
                  data: locationModel,
                  onTap: (int) {},
                );
              }),
        ).pSymmetric(h: 20)
      ],
    );
  }

  Future<void> submitComplaint() async {
    DashboardApi dashboardApi = Get.find();
    EasyLoading.show(status: 'loading...');
    Map data = {
      'username': name.value,
      'mobile_no': phoneNo.value,
      'title': title.value,
      'description': message.value,
    };
    var response = await dashboardApi.submitComplaint(data);
    EasyLoading.dismiss();
    if (response['status'] == 200) {
      Fluttertoast.showToast(
        msg: response['message'],
        backgroundColor: Colors.green,
        gravity: ToastGravity.TOP,
      );
      Get.back();
    } else {
      Fluttertoast.showToast(
        msg: response['message'],
        backgroundColor: errorColor,
        gravity: ToastGravity.TOP,
      );
    }
  }
}
