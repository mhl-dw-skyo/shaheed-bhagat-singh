import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:path_provider/path_provider.dart';
import 'package:punjab_tourism/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core.dart';

class Helper {
  BuildContext? context;
  DateTime? currentBackPressTime;
  Helper.of(BuildContext _context) {
    context = _context;
  }
  static bool isPhoneNumber(String s) {
    // Regular expression for validating Indian phone numbers
    // The pattern allows optional country code (+91), and ensures the number has exactly 10 digits
    final pattern = r'^(\+91[\-\s]?)?[0]?(91)?[789]\d{9}$';

    // Check if the string matches the pattern
    return RegExp(pattern).hasMatch(s);
  }
  static String truncateString(int cutoff, String myString) {
    return (myString.length <= cutoff)
        ? myString
        : '${myString.substring(0, cutoff)}...';
  }

  // static getCurrentUser() async {
  //   if ((Get.find<AuthService>().currentUser.value.token == '') && GetStorage().hasData('current_user')) {
  //     String prefCurrentUser = GetStorage().read('current_user');
  //     try {
  //       var decodedUser = json.decode(prefCurrentUser);
  //       try {
  //         Get.find<AuthService>().currentUser.value = UserModel.fromJSON(decodedUser);
  //         Get.find<AuthService>().currentUser.refresh();
  //       } catch (e) {
  //         print("currentUser: error");
  //       }
  //     } catch (e) {
  //       print("error user $e");
  //     }
  //   }
  // }

  static launchURL(url) async {
    print(url);
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  static String getTimeFromDuration(Duration duration) {
    String time = "";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes =
        twoDigits(duration.inMinutes.remainder(60).round());
    String twoDigitSeconds =
        twoDigits(duration.inSeconds.remainder(60).round());
    if (duration.inHours > 0) {
      time = "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else if (duration.inMinutes.remainder(60) > 0) {
      time = "$twoDigitMinutes:$twoDigitSeconds";
    } else {
      time = "00:$twoDigitSeconds";
    }
    return time;
  }

  // for mapping data retrieved form json array
  static getData(Map<String, dynamic> data) {
    return data['data'] ?? [];
  }

  static DateTime getYourCountryTime(DateTime datetime) {
    DateTime dateTime = DateTime.now();
    Duration timezone = dateTime.timeZoneOffset;
    return datetime.add(timezone);
  }

  static String limitString(String text,
      {int limit = 24, String hiddenText = "..."}) {
    return text.substring(0, min<int>(limit, text.length)) +
        (text.length > limit ? hiddenText : '');
  }

  static Uri getUri(String path) {
    String _path = Uri.parse(GlobalConfiguration().get('base_url')).path;
    if (!_path.endsWith('/')) {
      _path += '/';
    }
    Uri uri = Uri(
        scheme: Uri.parse(GlobalConfiguration().get('base_url')).scheme,
        host: Uri.parse(GlobalConfiguration().get('base_url')).host,
        port: Uri.parse(GlobalConfiguration().get('base_url')).port,
        path: _path + "api1/" + path);
    return uri;
  }

  static Future sendNotification(fcmToken, Map<String, dynamic> notification,
      Map<String, dynamic> data) async {
    print("FCM TOKENing");
    print(fcmToken);
    try {
      var response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=${GlobalConfiguration().get('server_key')}',
        },
        body: jsonEncode({
          'notification': notification,
          'priority': 'high',
          'data': data,
          'to': fcmToken,
        }),
      );
      print('FCM request for device sent!');
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  static String validDob(String year, String month, String day) {
    if (day.length == 1) {
      day = "0$day";
    }
    if (month.length == 1) {
      month = "0$month";
    }
    return "$year-$month-$day";
  }

  // String videoId = "";
  // late YoutubePlayerController youtubePlayerController;
  // Future<void> initPlayer(String? link) {
  //   if (link!.isNotEmpty) {
  //     videoId = YoutubePlayerController.convertUrlToId(link)!;
  //     youtubePlayerController = YoutubePlayerController(
  //       initialVideoId: videoId,
  //       params: const YoutubePlayerParams(
  //         showControls: true,
  //         showFullscreenButton: true,
  //         strictRelatedVideos: false,
  //       ),
  //     );
  //     youtubePlayerController.onEnterFullscreen = () {
  //       SystemChrome.setPreferredOrientations([
  //         DeviceOrientation.landscapeLeft,
  //         DeviceOrientation.landscapeRight,
  //       ]);
  //     };
  //     youtubePlayerController.onExitFullscreen = () {
  //       print('Exited Fullscreen');
  //     };
  //   }
  // }

  static localAssetPath(String url) {
    if (url.isNotEmpty) {
      print("data/${url.replaceAll('https://bhagatsm.dwgroup.in/', '')}"
          .replaceAll('JPG', 'jpg'));
      return "data/${url.replaceAll('https://bhagatsm.dwgroup.in/', '')}"
          .replaceAll('JPG', 'jpg');
    } else {
      return '';
    }
  }

  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    assert(url?.isNotEmpty ?? false, 'Url cannot be empty');
    if (!url.contains("http") && (url.length == 11)) return url;
    if (trimWhitespaces) url = url.trim();

    for (var exp in [
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
    ]) {
      Match? match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }

    return null;
  }

  static showVideoOnPopup() {
    //  YoutubePlayerController videoController;
    // videoController = YoutubePlayerController()
    //   ..onInit = () {
    //     videoController.loadVideoById(videoId: 'K18cpp_-gP8', startSeconds: 30);
    //   };
    // AwesomeDialog(
    //   dialogBackgroundColor: Get.theme.primaryColor,
    //   context: Get.context,
    //   animType: AnimType.SCALE,
    //   dialogType: DialogType.noHeader,
    //   body: SizedBox(
    //     width: Get.width,
    //     height: Get.height * 0.4,
    //     child: YoutubePlayerScaffold(
    //       autoFullScreen: true,
    //       controller: videoController,
    //       // aspectRatio: 16 / 9,
    //       builder: (context, player) {
    //         return Scaffold(
    //           body: player,
    //         );
    //       },
    //     ).centered(),
    //   ),
    // ).show();
  }

  // static openVideoPlayer(String? link) async {
  //   late YoutubePlayerController videoController;
  //   videoController = YoutubePlayerController()
  //     ..onInit = () {
  //       videoController.loadVideoById(videoId: 'K18cpp_-gP8', startSeconds: 30);
  //     };
  //   showModalBottomSheet<void>(
  //       isDismissible: true,
  //       isScrollControlled: true,
  //       barrierColor: Colors.black.withOpacity(0.9),
  //       context: Get.context!,
  //       builder: (BuildContext context) {
  //         return StatefulBuilder(builder: (BuildContext context, StateSetter setState /*You can rename this!*/) {
  //           return Container(
  //             height: Get.height * 0.8,
  //             width: Get.width,
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //             ),
  //             child: YoutubePlayerScaffold(
  //               controller: videoController,
  //               aspectRatio: 16 / 9,
  //               builder: (context, player) {
  //                 return Scaffold(
  //                   appBar: AppBar(
  //                     title: Text('YouTube Player'),
  //                   ),
  //                   body: player,
  //                 );
  //               },
  //             ),
  //           );
  //         });
  //       });
  // }

  static openDialPad() async {
    var serialNo = ''.obs;
    var activeButton = 99.obs;
    CommonService commonService =
    Get.find();
    showModalBottomSheet<void>(
        isDismissible: true,
        isScrollControlled: true,
        barrierColor: Colors.black.withOpacity(0.9),
        context: Get.context!,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setState /*You can rename this!*/) {
            return Container(
              height: Get.height * 0.5,
              width: Get.width,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  Container(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Obx(
                    () => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SizedBox(
                              width: Get.width,
                              child: Padding(
                                padding: EdgeInsets.all(Get.height * .015),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            colors: [
                                              Get.theme.colorScheme.primary,
                                              Get.theme.colorScheme.secondary,
                                            ],
                                            begin: const FractionalOffset(
                                                0.0, 0.0),
                                            end: const FractionalOffset(
                                                0.0, 1.0),
                                            stops: const [0.0, 1.0],
                                            tileMode: TileMode.clamp),
                                      ),
                                      height: Get.height * .09,
                                      width: Get.width,
                                      child: Center(
                                        child: Text(
                                          serialNo.value,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 30,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: Get.height * .004,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}1";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "1",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  1
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}2";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "2",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  2
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}3";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "3",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  3
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: Get.height * .004,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}4";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  top: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "4",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  4
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}5";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  top: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "5",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  5
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}6";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  top: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "6",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  6
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: Get.height * .004,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}7";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Get.theme.colorScheme
                                                        .primary,
                                                    Get.theme.colorScheme
                                                        .secondary,
                                                  ],
                                                  begin: const FractionalOffset(
                                                      0.0, 0.0),
                                                  end: const FractionalOffset(
                                                      0.0, 1.0),
                                                  stops: const [0.0, 1.0],
                                                  tileMode: TileMode.clamp,
                                                ),
                                                border: const Border(
                                                  top: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  bottom: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "7",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  7
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}8";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  top: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  bottom: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "8",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  8
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}9";
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  top: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                  bottom: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "9",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 35,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  9
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: Get.height * .004,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value = serialNo.value
                                                  .substring(
                                                      0,
                                                      serialNo.value.length -
                                                          1);
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                                border: const Border(
                                                  right: BorderSide(
                                                      width: 0.5,
                                                      color: Colors.white60),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  commonService.labelData.value.data.delete,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              serialNo.value =
                                                  "${serialNo.value}0";
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 0),
                                              child: Container(
                                                height: Get.height * .09,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        Get.theme.colorScheme
                                                            .primary,
                                                        Get.theme.colorScheme
                                                            .secondary,
                                                      ],
                                                      begin:
                                                          const FractionalOffset(
                                                              0.0, 0.0),
                                                      end:
                                                          const FractionalOffset(
                                                              0.0, 1.0),
                                                      stops: const [0.0, 1.0],
                                                      tileMode: TileMode.clamp),
                                                  border: const Border(
                                                    right: BorderSide(
                                                        width: 0.5,
                                                        color: Colors.white60),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "0",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 35,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: activeButton
                                                                    .value ==
                                                                0
                                                            ? Colors.black
                                                            : Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Get.height * .004,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {

                                              int locDataIndex = commonService
                                                  .offlineLocationDetailData
                                                  .value
                                                  .data
                                                  .indexWhere((element) =>
                                                      element.serialNo.contains(
                                                          serialNo.value));
                                              if (locDataIndex > -1) {
                                                Get.back();
                                                int locationId = commonService
                                                    .offlineLocationDetailData
                                                    .value
                                                    .data
                                                    .elementAt(locDataIndex)
                                                    .locationId;
                                                DetailController
                                                    detailController =
                                                Get.put(DetailController());
                                                detailController
                                                    .getLocationDetailData(
                                                        locationId);
                                                commonService.inMuseum.value = false;
                                                Get.toNamed('/detail');
                                              } else {
                                                Fluttertoast.showToast(
                                                  msg: commonService.labelData.value.data.invalid_serial_code,
                                                  backgroundColor: Colors.red,
                                                  toastLength:
                                                      Toast.LENGTH_LONG,
                                                  gravity: ToastGravity.TOP,
                                                  timeInSecForIosWeb: 5,
                                                );
                                              }
                                            },
                                            child: Container(
                                              height: Get.height * .09,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Get.theme.colorScheme
                                                          .primary,
                                                      Get.theme.colorScheme
                                                          .secondary,
                                                    ],
                                                    begin:
                                                        const FractionalOffset(
                                                            0.0, 0.0),
                                                    end: const FractionalOffset(
                                                        0.0, 1.0),
                                                    stops: const [0.0, 1.0],
                                                    tileMode: TileMode.clamp),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  commonService.labelData.value.data.search,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          activeButton.value ==
                                                                  0
                                                              ? Colors.black
                                                              : Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  static getNumberFormatter(int value) {
    var _formattedNumber = NumberFormat.compactCurrency(
      decimalDigits: 2,
      symbol:
          '', // if you want to add currency symbol then pass that in this else leave it empty.
    ).format(value);
    return _formattedNumber;
  }

  static downloadAudios(String folderName) {
    CommonService commonService = Get.find();
    downloadAudiosProcess(commonService, folderName);
  }

  static downloadAudiosProcess(
      CommonService commonService, String folderName) async {
    if (commonService.soundFiles.isNotEmpty) {
      try {
        Directory? appDocDir;
        if (Platform.isAndroid) {
          appDocDir = await getExternalStorageDirectory();
        } else {
          appDocDir = await getApplicationDocumentsDirectory();
        }
        String outputDirectory = '${appDocDir?.path}/$folderName';
        String fileName = commonService.soundFiles.elementAt(0).split('/').last;
        print(File("$outputDirectory/$fileName").existsSync());
        if (!File("$outputDirectory/$fileName").existsSync()) {
          print(commonService.soundFiles.elementAt(0));
          var tasks = await FlutterDownloader.enqueue(
            url: commonService.soundFiles.elementAt(0),
            savedDir: outputDirectory,
            showNotification:
                false, // show download progress in status bar (for Android)
            openFileFromNotification: false,
            saveInPublicStorage:
                false, // click on notification to open downloaded file (for Android)
          ).whenComplete(() {
            commonService.soundFiles.removeAt(0);
            downloadAudiosProcess(commonService, folderName);
          });
          print(tasks);
        }
      } catch (e) {
        print("EXCEP $e");
      }
    }
  }

  // static cacheAudios() {
  //   CommonService commonService = Get.find();
  //   cacheAudiosProcess(commonService);
  // }
  //
  // static cacheAudiosProcess(CommonService commonService) {
  //   if (commonService.soundFiles.isNotEmpty) {
  //     print("Cache Audio File : ${commonService.soundFiles.length} --- ${commonService.soundFiles.elementAt(0)}");
  //     DefaultCacheManager().getSingleFile(commonService.soundFiles.elementAt(0)).whenComplete(() {
  //       commonService.soundFiles.removeAt(0);
  //       cacheAudiosProcess(commonService);
  //     });
  //   }
  // }

  static barcodeScanner() async {
    //try {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Cancel', true, ScanMode.BARCODE);
    print(barcodeScanRes);
    if (barcodeScanRes.isNotEmpty) {
      var initialLink = await FirebaseDynamicLinks.instance
          .getDynamicLink(Uri.parse(barcodeScanRes));
      print(initialLink);
      var locId = initialLink?.link.queryParameters['loc_id'];
      print(locId);
      if (locId.toString().isNotEmpty) {
        DetailController detailController = Get.find();
        detailController.getLocationDetailData(int.parse(locId.toString()));
        Get.toNamed('/detail');
      } else {
        Fluttertoast.showToast(
          msg: "There is no data for this barcode.",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 5,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Invalid barcode.",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 5,
      );
    }
    // } catch (e) {
    //   Fluttertoast.showToast(
    //     msg: "This feature will work when your internet connection will be on",
    //     backgroundColor: Colors.red,
    //     toastLength: Toast.LENGTH_LONG,
    //     gravity: ToastGravity.TOP,
    //     timeInSecForIosWeb: 5,
    //   );
    // }
  }

  static playWelcomeSound() async {
    AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
    await assetsAudioPlayer.open(
      Audio('data/assets/audios/welcome.mp3'),
      showNotification: false,
      autoStart: true,
      playInBackground: PlayInBackground.enabled,
    );
    await GetStorage().write('welcomeAudioPlayed', 1);
  }

  static deleteAccountConfirmation() {
    CommonService commonService = Get.find();
    AwesomeDialog(
      dialogBackgroundColor: Get.theme.colorScheme.primary,
      context: Get.context!,
      animType: AnimType.scale,
      dialogType: DialogType.question,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            commonService.labelData.value.data.deleteAccount.text.center
                .textStyle(headline1()
                    .copyWith(color: Get.theme.highlightColor, fontSize: 25))
                .make()
                .centered()
                .pOnly(bottom: 10),
            commonService.labelData.value.data.deleteAccountDesc.text.center
                .textStyle(bodyText1
                    .copyWith(color: Get.theme.highlightColor))
                .make()
                .centered()
                .pOnly(bottom: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Get.theme.highlightColor,
                      ),
                      child: commonService.labelData.value.data.cancel.text
                          .size(18)
                          .center
                          .color(Get.theme.indicatorColor)
                          .make()
                          .centered()
                          .pSymmetric(h: 10, v: 10),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                      ConfigApi configApi = Get.find();
                      configApi.deleteAccount();
                      logout();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Get.theme.colorScheme.secondary,
                      ),
                      child: commonService.labelData.value.data.delete.text
                          .size(18)
                          .center
                          .color(Get.theme.highlightColor)
                          .make()
                          .centered()
                          .pSymmetric(h: 10, v: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).show();
  }

  static Color parseColorCode(String colorCode) {
    return colorCode.isNotEmpty
        ? Color(int.parse(colorCode.replaceAll("#", "0xff")))
        : const Color(0xffffffff);
  }

  static logoutConfirmation() {
    CommonService commonService = Get.find();
    AwesomeDialog(
      dialogBackgroundColor: Get.theme.primaryColorDark,
      context: Get.context!,
      animType: AnimType.scale,
      dialogType: DialogType.question,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            commonService.labelData.value.data.signOut.text.center
                .textStyle(headline1()
                    .copyWith(color: Get.theme.indicatorColor, fontSize: 25))
                .make()
                .centered()
                .pOnly(bottom: 10),
            commonService.labelData.value.data.logoutMsg.text.center
                .textStyle(bodyText1
                    .copyWith(color: Get.theme.indicatorColor))
                .make()
                .centered()
                .pOnly(bottom: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: errorColor,
                      ),
                      child: commonService.labelData.value.data.cancel.text
                          .size(18)
                          .center
                          .color(Get.theme.highlightColor)
                          .make()
                          .centered()
                          .pSymmetric(h: 10, v: 10),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                      logout();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Get.theme.colorScheme.primary,
                      ),
                      child: commonService.labelData.value.data.logout.text
                          .size(18)
                          .center
                          .color(Get.theme.highlightColor)
                          .make()
                          .centered()
                          .pSymmetric(h: 10, v: 10),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ).show();
  }

  static skipVideoConfirmation(int locationId) async {
    CommonService commonService = Get.find();
    AwesomeDialog(
      dialogBackgroundColor: Get.theme.primaryColorDark,
      context: Get.context!,
      animType: AnimType.scale,
      dialogType: DialogType.question,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            commonService.labelData.value.data.skipVideo.text.center
                .textStyle(headline3()
                    .copyWith(color: Get.theme.indicatorColor, fontSize: 25))
                .make()
                .centered()
                .pOnly(bottom: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      commonService.isPopSVPopupOpen.value = false;
                      commonService.isPopSVPopupOpen.refresh();
                      Get.back();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: errorColor,
                      ),
                      child: commonService.labelData.value.data.cancel.text
                          .size(18)
                          .center
                          .color(Get.theme.highlightColor)
                          .make()
                          .centered()
                          .pSymmetric(h: 10, v: 10),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      print("Location ID");
                      print(locationId);
                      commonService.isPopSVPopupOpen.value = false;
                      commonService.isPopSVPopupOpen.refresh();
                      Get.back();
                      commonService.selectedFileType.value = "";
                      commonService.selectedFileType.refresh();
                      DetailController detailController = Get.find();
                      detailController.getLocationDetailData(locationId);
                      if (commonService.selectedFileType.value == "V") {
                        Get.back();
                        await Future.delayed(Duration(seconds: 1));
                        commonService.inMuseum.value = false;
                        Get.toNamed('/detail');
                      } else {
                        if (Get.currentRoute != "/detail") {
                          commonService.inMuseum.value = false;
                          Get.toNamed('/detail');
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Get.theme.colorScheme.primary,
                      ),
                      child: commonService.labelData.value.data.skip.text
                          .size(18)
                          .center
                          .color(Get.theme.highlightColor)
                          .make()
                          .centered()
                          .pSymmetric(h: 10, v: 10),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ).show();
  }

  static String parseHtmlString(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String parsedStr = htmlString.replaceAll(exp, ' ');
    return parsedStr;
  }

  static void printLog(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  // static setCurrentUser(userData) async {
  //   await GetStorage().write("current_user", json.encode(userData));
  //   Get.find<AuthService>().currentUser.value = UserModel.fromJSON(userData);
  //   Get.find<AuthService>().currentUser.refresh();
  // }

  static alertDialog(String title, String msg) {
    AwesomeDialog(
      dialogBackgroundColor: Get.theme.colorScheme.secondary,
      context: Get.context!,
      animType: AnimType.scale,
      dialogType: DialogType.warning,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text.center
                .textStyle(headline1()
                    .copyWith(color: Get.theme.highlightColor, fontSize: 25))
                .make()
                .centered()
                .pOnly(bottom: 10),
            msg
                .toString()
                .text
                .center
                .textStyle(bodyText1
                    .copyWith(color: Get.theme.highlightColor))
                .make()
                .centered()
                .pOnly(bottom: 20),
            InkWell(
              onTap: () => Get.back(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Get.theme.highlightColor,
                ),
                child: "Ok"
                    .text
                    .size(18)
                    .center
                    .color(Get.theme.indicatorColor)
                    .make()
                    .centered()
                    .pSymmetric(h: 10, v: 10),
              ),
            )
          ],
        ),
      ),
    ).show();
  }

  static getHMSFromString(String time, String type) {
    int value = 0;
    if (time.isNotEmpty) {
      List result = time.split(":");
      if (type == "H") {
        value = int.parse(result.elementAt(0));
      } else if (type == "M") {
        value = int.parse(result.elementAt(1));
      } else {
        value = int.parse(result.elementAt(2));
      }
    }
    return value;
  }

  static Future<void> logout() async {
    CommonService commonService = Get.find();
    AuthService authService = Get.find();
    await GetStorage().remove('token');
    await GetStorage().remove('username');
    // await GetStorage().remove('fcm_token');
    await GetStorage().remove('user_type');
    commonService.guestInformationData.value = GuestModel();
    commonService.guestInformationData.refresh();
    commonService.guestData.value = GuestItem();
    commonService.guestData.refresh();
    commonService.qrStatus.value = 3;
    commonService.qrStatus.refresh();
    authService.phoneNo.value = "";
    authService.phoneNo.refresh();
    authService.comeFromLogin.value = false;
    authService.comeFromLogin.refresh();
    authService.token.value = "";
    authService.token.refresh();
    Get.toNamed('/login');
  }

  static Color getColor(String colorCode) {
    colorCode = colorCode.replaceAll("#", "");

    try {
      if (colorCode.length == 6) {
        return Color(int.parse("0xFF" + colorCode));
      } else if (colorCode.length == 8) {
        return Color(int.parse("0x" + colorCode));
      } else {
        return const Color(0xFFCCCCCC).withOpacity(1);
      }
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(1);
    }
  }

  static showSimpleSpinner(color, [size]) {
    return SizedBox(
      width: size ?? 20.0,
      height: size ?? 20.0,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Get.theme.colorScheme.secondary),
      ).centered(),
    ).centered();
  }

  static showLoaderSpinner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Get.theme.highlightColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          "Please wait. Loading..."
              .text
              .minFontSize(5)
              .textStyle(bodyText2
                  .copyWith(fontSize: 16, color: Get.theme.indicatorColor))
              .make(),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Get.theme.primaryColor),
            ),
          ),
        ],
      ).pSymmetric(h: 20, v: 28),
    );
  }

  static String formatter(double currentBalance) {
    try {
      // suffix = {' ', 'k', 'M', 'B', 'T', 'P', 'E'};
      // double value = double.parse(currentBalance);
      double value = currentBalance;

      if (value < 1000) {
        // less than a thousand
        return value.toStringAsFixed(0);
      } else if (value >= 1000 && value < (1000 * 100 * 10)) {
        // less than a million
        double result = value / 1000;
        return result.toStringAsFixed(1) + "k";
      } else if (value >= 1000000 && value < (1000000 * 10 * 100)) {
        // less than 100 million
        double result = value / 1000000;
        return result.toStringAsFixed(1) + "M";
      } else if (value >= (1000000 * 10 * 100) &&
          value < (1000000 * 10 * 100 * 100)) {
        // less than 100 billion
        double result = value / (1000000 * 10 * 100);
        return result.toStringAsFixed(1) + "B";
      } else if (value >= (1000000 * 10 * 100 * 100) &&
          value < (1000000 * 10 * 100 * 100 * 100)) {
        // less than 100 trillion
        double result = value / (1000000 * 10 * 100 * 100);
        return result.toStringAsFixed(1) + "T";
      } else {
        return "0";
      }
    } catch (e) {
      /* Helper.printUserLog(*/ print(e);
      return "";
    }
  }

  static String timeAgoSinceDate(String dateString) {
    DateTime notificationDate =
        DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
    final date2 = DateTime.now();
    final difference = date2.difference(notificationDate);
    if (difference.inDays > 365) {
      return (difference.inDays / 365).floor().toString() + " " + "year ago".tr;
    } else if (difference.inSeconds < 3) {
      return 'just now'.tr;
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}' + " " + 'seconds ago'.tr;
    } else if (difference.inMinutes < 60) {
      return difference.inMinutes.toString() + " " + "min ago".tr;
    } else if (difference.inHours < 24) {
      return '${difference.inHours}' + " " + "hour ago".tr;
    } else if (difference.inDays < 30) {
      return difference.inDays.toString() + " " + "day ago".tr;
    } else if (difference.inDays < 365) {
      return (difference.inDays / 30).floor().toString() + " " + "month ago".tr;
    } else {
      return "";
    }
  }

  static onBottomBarClick(GuestController? guestController, int index) async {
    if (index == 0) {
      launchUrlString("tel://01887232592");
    }
    if (GetStorage().read('user_type') == "U") {
      switch (index) {
        case 1:
          Helper.openDialPad();
          break;
        case 2:
          Get.toNamed('/dashboard');
          break;
        case 4:
          GuestController guestController = Get.find();
          guestController.page = 1;
          await guestController.fetchGuestInformationHistory();
          Get.toNamed('/guest-information');
          break;
        case 3:
          Get.toNamed('/nearby');
          break;
      }
    } else {
      switch (index) {
        case 1:
          Get.toNamed('/emp_dashboard');
          break;
        case 2:
          String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
              '#ff6666', 'Cancel', true, ScanMode.BARCODE);

          if (barcodeScanRes.isNotEmpty && barcodeScanRes != "-1" && guestController != null) {
            guestController.scanQR(barcodeScanRes);
          }
          break;
      }
    }
  }
}
