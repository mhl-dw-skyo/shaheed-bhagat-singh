import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:punjab_tourism/utils.dart';
import 'package:readmore/readmore.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../core.dart';

class DetailView extends GetView<DetailController> {
  DetailView({Key? key}) : super(key: key);
  GlobalKey<ScaffoldState> scaffoldDashboardKey =
      GlobalKey<ScaffoldState>(debugLabel: '_scaffoldDashboardKey');
  CommonService commonService = Get.find();
  Future<bool> _onWillPop() async {
    // Stop all audio players before navigating back
    AssetsAudioPlayer.allPlayers().forEach((key, value) {
      value.stop();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
    );
    return WillPopScope(
        onWillPop: _onWillPop,child:  Container(
      color: Get.theme.primaryColor,
      child: SafeArea(
        child: Scaffold(
          key: scaffoldDashboardKey,
          extendBodyBehindAppBar: true,
          // key: scaffoldDashboardKey,
          backgroundColor: Get.theme.primaryColor,
          appBar: AppBar(
            bottomOpacity: 0,
            shadowColor: Colors.transparent,
            foregroundColor: Get.theme.highlightColor,
            backgroundColor: Colors.transparent,
            elevation: 0,
            // automaticallyImplyLeading: true,
            leading: IconButton(
                onPressed: () {
                  AssetsAudioPlayer.allPlayers().forEach((key, value) {
                    value.stop();
                  });
                  Get.back();
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Get.theme.highlightColor,
                  size: 25,
                )),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  commonService.selectedFileType.value == "V"
                      ? Container(
                          width: Get.width,
                          height: Get.height * 0.45,
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: commonService.ytpController.value != null
                                    ? YoutubePlayer(
                                        controller:
                                            commonService.ytpController.value,
                                      )
                                    : Helper.showLoaderSpinner(),
                              )),
                        )
                      : Container(
                          width: Get.width,
                          height: Get.height * 0.45,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                Helper.localAssetPath(commonService
                                    .locationDetailData
                                    .value
                                    .attributes
                                    .imagePath),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: commonService.locationDetailData.value
                              .attributes.locationName.text
                              .textStyle(
                                headline1().copyWith(
                                  color: Get.theme.indicatorColor,
                                  fontSize: 30,
                                ),
                              )
                              .shadow(1, 1, 5, Get.theme.highlightColor)
                              .make()
                              .pOnly(top: 70, left: 20),
                        ),
                  SizedBox(
                    height: commonService.selectedFileType.value == "A" &&
                            commonService.selectedAudioFile.value.isNotEmpty
                        ? 25
                        : 0,
                  ),
                  commonService.selectedFileType.value == "A" &&
                          commonService.selectedAudioFile.value.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 30,
                              child: commonService.assetsAudioPlayer.value
                                  .builderLoopMode(
                                builder: (context, loopMode) {
                                  return PlayerBuilder.isPlaying(
                                      player:
                                          commonService.assetsAudioPlayer.value,
                                      builder: (context, isPlaying) {
                                        controller.audioSubscriptions.add(
                                            commonService.assetsAudioPlayer
                                                .value.isBuffering
                                                .listen((isBuffering) {
                                          if (isBuffering) {
                                            controller.isBufferingStream.value =
                                                true;
                                          } else {
                                            controller.isBufferingStream.value =
                                                false;
                                          }
                                        }));
                                        return Obx(() => controller
                                                .isBufferingStream.value
                                            ? Helper.showSimpleSpinner(
                                                const Color(0xff1262CC))
                                            : InkWell(
                                                onTap: () {
                                                  AssetsAudioPlayer.allPlayers()
                                                      .forEach((key, value) {
                                                    value.pause();
                                                  });
                                                  commonService
                                                      .assetsAudioPlayer.value
                                                      .playOrPause();
                                                },
                                                child: SvgPicture.asset(
                                                  isPlaying
                                                      ? "assets/images/pause.svg"
                                                      : "assets/images/play.svg",
                                                  width: 25,
                                                  height: 25,
                                                ),
                                              ));
                                      }).pOnly(right: 10);
                                },
                              ),
                            ),
                            Expanded(
                              child: commonService.assetsAudioPlayer.value
                                  .builderRealtimePlayingInfos(builder:
                                      (context, RealtimePlayingInfos infos) {
                                return PositionSeekWidget(
                                  currentPosition: infos.currentPosition,
                                  duration: infos.duration,
                                  seekTo: (to) {
                                    commonService.assetsAudioPlayer.value
                                        .seek(to);
                                  },
                                ).pSymmetric(h: 25);
                              }),
                            ),
                          ],
                        ).pSymmetric(h: 25)
                      : const SizedBox(height: 0),
                  SizedBox(
                    height:  16,
                  ),
                  commonService
                      .locationDetailData.value.attributes.locationName.text
                      .textStyle(
                        headline1().copyWith(
                          color: Get.theme.indicatorColor,
                          fontSize: 22,
                        ),
                      )
                      .shadow(1, 1, 5, Get.theme.highlightColor)
                      .make()
                      .pSymmetric(h: 20),
                  const SizedBox(
                    height: 8,
                  ),
                  commonService.locationDetailData.value.attributes.description
                          .isNotEmpty
                      ? ReadMoreText(
                          commonService
                              .locationDetailData.value.attributes.description,
                          trimLines: commonService
                                      .sameCategoryBeacons.isNotEmpty &&
                                  commonService.sameCategoryBeacons.length > 1
                              ? 4
                              : commonService.locationDetailData.value
                                  .attributes.description.length,
                          colorClickableText: Get.theme.colorScheme.primary,
                          trimMode: TrimMode.Line,
                          style: TextStyle(
                              color: Get.theme.indicatorColor, fontSize: 16),
                          trimCollapsedText:
                              commonService.labelData.value.data.more,
                          trimExpandedText:
                              commonService.labelData.value.data.less,
                          moreStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Get.theme.colorScheme.primary),
                        ).pSymmetric(h: 20)
                      :
                  SizedBox(
                          height: 0,
                        ),
                  SizedBox(
                    height:
                        commonService.sameCategoryBeacons.isNotEmpty ? 30 : 0,
                  ),
                  // commonService.sameCategoryBeacons.isNotEmpty &&
                  //         commonService.sameCategoryBeacons.length > 3
                  //     ? SizedBox(
                  //         width: Get.width,
                  //         height: 210,
                  //         child: ScrollablePositionedList.builder(
                  //             scrollDirection: Axis.horizontal,
                  //             shrinkWrap: true,
                  //             itemCount:
                  //                 commonService.sameCategoryBeacons.length,
                  //             itemScrollController:
                  //                 controller.itemScrollController,
                  //             itemPositionsListener:
                  //                 controller.itemPositionsListener,
                  //             itemBuilder: (context, index) {
                  //               BeaconItem beaconItem = commonService
                  //                   .sameCategoryBeacons
                  //                   .elementAt(index);
                  //               return InkWell(
                  //                 onTap: () {
                  //                   commonService.selectedBeacon.value =
                  //                       beaconItem;
                  //                   commonService.selectedBeacon.refresh();
                  //                   controller.getLocationDetailData(
                  //                       beaconItem.locationId);
                  //                 },
                  //                 child: Column(
                  //                   mainAxisSize: MainAxisSize.min,
                  //                   mainAxisAlignment: MainAxisAlignment.start,
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   children: [
                  //                     Container(
                  //                       width: 150,
                  //                       height: 150,
                  //                       decoration: BoxDecoration(
                  //                         border: Border.all(
                  //                           color: commonService.selectedBeacon
                  //                                       .value.locationId ==
                  //                                   beaconItem.locationId
                  //                               ? Get.theme.colorScheme.primary
                  //                               : Colors.transparent,
                  //                           width: commonService.selectedBeacon
                  //                                       .value.locationId ==
                  //                                   beaconItem.locationId
                  //                               ? 4
                  //                               : 0,
                  //                         ),
                  //                         color: Colors.grey,
                  //                         borderRadius: const BorderRadius.only(
                  //                           topLeft: Radius.circular(50),
                  //                           topRight: Radius.circular(15),
                  //                           bottomLeft: Radius.circular(15),
                  //                           bottomRight: Radius.circular(50),
                  //                         ),
                  //                       ),
                  //                       child: ClipRRect(
                  //                           borderRadius:
                  //                               const BorderRadius.only(
                  //                             topLeft: Radius.circular(50),
                  //                             topRight: Radius.circular(15),
                  //                             bottomLeft: Radius.circular(15),
                  //                             bottomRight: Radius.circular(50),
                  //                           ),
                  //                           child: Image.asset(
                  //                             Helper.localAssetPath(
                  //                                 beaconItem.locationImage),
                  //                             fit: BoxFit.cover,
                  //                             width: 150,
                  //                             height: 150,
                  //                             errorBuilder:
                  //                                 (BuildContext context,
                  //                                     Object exception,
                  //                                     StackTrace? stackTrace) {
                  //                               return Image.asset(
                  //                                 Helper.localAssetPath(
                  //                                     beaconItem.locationImage),
                  //                                 width: 150,
                  //                                 height: 150,
                  //                                 fit: BoxFit.cover,
                  //                               );
                  //                             },
                  //                           )),
                  //                     ).pOnly(bottom: 5),
                  //                     SizedBox(
                  //                       width: 150,
                  //                       child: beaconItem.locationName.text
                  //                           .textStyle(
                  //                             headline3().copyWith(
                  //                               color: Get.theme.indicatorColor,
                  //                             ),
                  //                           )
                  //                           .maxLines(2)
                  //                           .ellipsis
                  //                           .shadow(1, 1, 5,
                  //                               Get.theme.highlightColor)
                  //                           .make(),
                  //                     )
                  //                   ],
                  //                 ).pOnly(right: 20),
                  //               );
                  //             }),
                  //       ).pSymmetric(h: 15)
                  //     :
                  const SizedBox(
                    height: 0,
                  )
                ],
              ).pOnly(bottom: 40),
            ),
          ),

        ),
      ),
    ));
  }
}
