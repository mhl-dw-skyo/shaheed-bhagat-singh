import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:punjab_tourism/utils.dart';
import 'package:punjab_tourism/views/enable_bt.dart';
import 'package:punjab_tourism/views/mk_button.dart';
import 'package:upgrader/upgrader.dart';

import '../core.dart';

class DashboardView extends GetView<DashboardController> {
  StreamController<BluetoothState> streamController = StreamController();

  DashboardView({Key? key}) : super(key: key) {
    controller.initBeaconService(onUpdate: (state) {
      streamController.add(state);
    });
  }

  late DateTime currentBackPressTime;
  GlobalKey<ScaffoldState> scaffoldDashboardKey =
  GlobalKey<ScaffoldState>(debugLabel: '_scaffoldDashboardKey');
  CommonService commonService = Get.find();
  GuestController guestController = Get.find();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          statusBarColor: Get.theme.primaryColor,
          statusBarIconBrightness: Brightness.dark),
    );
    return UpgradeAlert(
      dialogStyle: Platform.isIOS
          ? UpgradeDialogStyle.cupertino
          : UpgradeDialogStyle.material,
      upgrader: Upgrader(),
      child: Container(
        color: Get.theme.primaryColor,
        child: SafeArea(
          child: Obx(
                () => Scaffold(
              key: scaffoldDashboardKey,
              backgroundColor: Get.theme.primaryColor,
              appBar: AppBar(
                bottomOpacity: 0,
                shadowColor: Colors.transparent,
                backgroundColor: Get.theme.primaryColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: commonService.labelData.value.data.punjabTourism.text
                    .textStyle(
                  headline1().copyWith(
                    color: Get.theme.indicatorColor,
                  ),
                )
                    .make(),
                actions: [
                  InkWell(
                    onTap: () {
                      scaffoldDashboardKey.currentState?.openEndDrawer();
                    },
                    child: SvgPicture.asset(
                      "assets/images/menu.svg",
                      color: Get.theme.indicatorColor,
                    ),
                  ).pOnly(right: 20)
                ],
              ),
              endDrawer: DrawerWidget(),
              body: WillPopScope(
                onWillPop: () {
                  DateTime now = DateTime.now();
                  if (now.difference(currentBackPressTime) >
                      const Duration(seconds: 2)) {
                    currentBackPressTime = now;
                    Fluttertoast.showToast(msg: "Tap again to exit an app.");
                    return Future.value(false);
                  }
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  return Future.value(true);
                },
                child: RefreshIndicator(
                  onRefresh: () => controller.fetchDashboardData(),
                  child: Obx(
                        () => SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 25,
                          ),
                          StreamBuilder<BluetoothState>(
                              stream: streamController.stream,
                              builder: (context, snapshot) {
                                return Visibility(
                                  visible: snapshot.hasData &&
                                      snapshot.data == BluetoothState.stateOff,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 24, left: 20, right: 20),
                                    child: Row(
                                      children: [
                                        Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                commonService.labelData.value.data.enable_bluetooth,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight:
                                                    FontWeight.w600),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                commonService.labelData.value.data.please_enable_bluetoothon_yourdevice,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    fontWeight:
                                                    FontWeight.normal),
                                              ),
                                            ]),
                                        Spacer(),
                                        MkButton(
                                            width: 80,
                                            borderRadius: 4,
                                            padding: EdgeInsets.only(
                                                top: 8, bottom: 8),
                                            onTap: () {
                                              Get.dialog(EnableBt(commonService:commonService));
                                            },
                                            text: commonService.labelData.value.data.enable)
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              commonService.labelData.value.data.welcomeTo.text
                                  .textStyle(
                                headline1().copyWith(
                                  color: Get.theme.indicatorColor
                                      .withOpacity(0.5),
                                ),
                              )
                                  .make(),
                              const SizedBox(
                                width: 40,
                                height: 40,
                              ),
                              InkWell(
                                onTap: () async {
                                  GuestController guestController = Get.find();
                                  guestController.page = 1;
                                  await guestController
                                      .fetchGuestInformationHistory();
                                  Get.toNamed('/guest-information');
                                },
                                child: Container(
                                  height: 35,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: LinearGradient(
                                        colors: [
                                          Get.theme.colorScheme.primary,
                                          Get.theme.colorScheme.secondary,
                                        ],
                                        begin: const FractionalOffset(0.0, 0.0),
                                        end: const FractionalOffset(0.0, 1.0),
                                        stops: const [0.0, 1.0],
                                        tileMode: TileMode.clamp),
                                  ),
                                  child: Row(
                                    children: [
                                      commonService
                                          .labelData.value.data.entryAccess.text
                                          .textStyle(
                                        headline4().copyWith(
                                          color: Get.theme.highlightColor,
                                        ),
                                      )
                                          .make()
                                          .pOnly(right: 2),
                                      SvgPicture.asset(
                                        "assets/images/entry.svg",
                                        color: Get.theme.highlightColor,
                                        width: 22,
                                      )
                                    ],
                                  ).pSymmetric(h: 10),
                                ),
                              ),
                            ],
                          ).pSymmetric(h: 20),
                          SizedBox(height: 8),
                          Transform.translate(
                            offset: Offset(0, -10),
                            child: commonService
                                .labelData.value.data.virastEKhalsa.text
                                .textStyle(
                              headline1().copyWith(
                                color: Get.theme.indicatorColor,
                                fontSize: 35,
                              ),
                            )
                                .make()
                                .pSymmetric(h: 20),
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          ...commonService.dashboardData.value.data
                              .mapIndexed((currentValue, index) {
                            return currentValue.mType == "markup"
                                ? DashboardSliderWidget(
                                attributes: currentValue.attributes)
                                .pOnly(bottom: 30)
                                : DashboardCategoriesWidget(
                              dashboardDataModel: currentValue,
                            );
                          }).toList(),
                        ],
                      ).pOnly(bottom: 35),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: BottomNavWidget(
                onTap: (int index) {
                  Helper.onBottomBarClick(null, index);
                },
              ),
              floatingActionButton: SpeedDialWidget(),
            ),
          ),
        ),
      ),
    );
  }
}