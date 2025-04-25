import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../core.dart';

class DetailController extends GetxController {
  ScrollController scrollController = ScrollController();
  var buttonLoader = false.obs;
  var loader = false.obs;
  CommonService commonService = Get.find();
  final List<StreamSubscription> audioSubscriptions = [];
  var isBufferingStream = false.obs;
  late ItemScrollController itemScrollController;
  late ItemPositionsListener itemPositionsListener;
  var selectedBeaconId = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();
  }

  void openPlayer(String file, int beaconId) async {
    if (file.isNotEmpty) {
      await commonService.assetsAudioPlayer.value.open(
        Audio.network(
          file,
        ),
        showNotification: false,
        autoStart: true,
      );
      commonService.assetsAudioPlayer.value.playlistAudioFinished
          .listen((Playing playing) {
        commonService.isAudioPlaying.value = false;
        commonService.isAudioPlaying.refresh();
      });
    }
  }

  iinitializeAndPlayYTPlayer(String file) async {
    print("KKKKKKK");
    final id = Helper.convertUrlToId(file);

    commonService.ytpController.value = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        loop: false,
        strictRelatedVideos: true,
        enableJavaScript: true,
        playsInline: true,
      ),
    );



    // Play the video after a short delay to ensure it's ready
    Future.delayed(Duration(milliseconds: 300), () {
      commonService.ytpController.value.playVideo();
    });

    // Fullscreen behavior is not natively supported in youtube_player_iframe v5+
    // You must control fullscreen outside of the player using your own UI
    // The following is an optional workaround if you add your own toggle button:
    // toggleFullscreen(true); toggleFullscreen(false);
  }

  void toggleFullscreen(bool enter) {
    if (enter) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      Future.delayed(const Duration(seconds: 1), () {
        commonService.ytpController.value.playVideo();
      });
      Future.delayed(const Duration(seconds: 5), () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      });
    }
  }

  Future<void> getLocationDetailData(int locationId) async {
    commonService.selectedAudioFile.value = "";
    selectedBeaconId.value = 0;
    commonService.selectedFileType.value = "";
    AssetsAudioPlayer.allPlayers().forEach((key, value) {
      value.stop();
    });
    commonService.assetsAudioPlayer.value.dispose();
    commonService.assetsAudioPlayer.value = AssetsAudioPlayer();
    if (commonService.offlineLocationDetailData.value.data.isNotEmpty) {
      int locDataIndex = commonService.offlineLocationDetailData.value.data
          .indexWhere((element) => element.locationId == locationId);
      if (locDataIndex > -1) {
        commonService.selectedLocationName.value = commonService
            .offlineLocationDetailData.value.data
            .elementAt(locDataIndex)
            .locationName;
        commonService.selectedLocationId.value = commonService
            .offlineLocationDetailData.value.data
            .elementAt(locDataIndex)
            .locationId;
        commonService.locationDetailData.value = commonService
            .offlineLocationDetailData.value.data
            .elementAt(locDataIndex)
            .locationDetail;
        int audioFileIndex = commonService.offlineLocationDetailData.value.data
            .elementAt(locDataIndex)
            .locationDetail
            .attributes
            .baconListing
            .indexWhere((element) => element.isPrimary == 1);
        if (audioFileIndex > -1) {
          commonService.selectedFileType.value = commonService
              .offlineLocationDetailData.value.data
              .elementAt(locDataIndex)
              .locationDetail
              .attributes
              .baconListing
              .elementAt(audioFileIndex)
              .fileType;

          if (GetStorage().read('language_id') == 1) {
            commonService.selectedAudioFile.value = commonService
                .offlineLocationDetailData.value.data
                .elementAt(locDataIndex)
                .locationDetail
                .attributes
                .baconListing
                .elementAt(audioFileIndex)
                .englishSoundFile;
          } else if (GetStorage().read('language_id') == 2) {
            commonService.selectedAudioFile.value = commonService
                .offlineLocationDetailData.value.data
                .elementAt(locDataIndex)
                .locationDetail
                .attributes
                .baconListing
                .elementAt(audioFileIndex)
                .hindiSoundFile;
          } else {
            commonService.selectedAudioFile.value = commonService
                .offlineLocationDetailData.value.data
                .elementAt(locDataIndex)
                .locationDetail
                .attributes
                .baconListing
                .elementAt(audioFileIndex)
                .punjabiSoundFile;
          }
          selectedBeaconId.value = commonService
              .offlineLocationDetailData.value.data
              .elementAt(locDataIndex)
              .locationDetail
              .attributes
              .baconListing
              .elementAt(audioFileIndex)
              .id;
          if (commonService.selectedFileType.value == "A") {
            openPlayer(
                commonService.selectedAudioFile.value, selectedBeaconId.value);
          } else {
            iinitializeAndPlayYTPlayer(commonService.selectedAudioFile.value);
          }
        }
      }
    }
  }

  Future getOfflineLocationsData() async {
    String file = "";
    if (GetStorage().read('language_id') != '' ||
        GetStorage().read('language_id') != null) {
      switch (GetStorage().read('language_id')) {
        case 1:
          file = "offline_locations.json";
          break;
        case 2:
          file = "offline_locations_hi.json";
          break;
        case 3:
          file = "offline_locations_pu.json";
          break;
      }
    }
    try {
      final String data =
      await rootBundle.loadString('assets/data_files/$file');
      var response = jsonDecode(data);
      if (response['status']) {
        commonService.offlineLocationDetailData.value =
            OfflineLocationsModel.fromJson(response);
        commonService.offlineLocationDetailData.refresh();
        // print(response['data']);
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }
}
