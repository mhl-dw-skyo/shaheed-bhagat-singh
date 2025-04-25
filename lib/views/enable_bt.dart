import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punjab_tourism/services/common_service.dart';
import 'package:punjab_tourism/utils.dart';
import 'package:punjab_tourism/views/mk_button.dart';
import 'package:url_launcher/url_launcher.dart';

class EnableBt extends StatelessWidget {
  final CommonService commonService;
  EnableBt({super.key, required this.commonService});

  Future<void> openBluetoothSettings() async {
    const url = 'bluetooth://';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await launchUrl(Uri.parse("app-settings:"), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: SizedBox(
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/bt.png',
                            width: 140,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Get.back(),
                        child: Transform.rotate(
                            angle: -95, child: Icon(Icons.add_circle, size: 30)),
                      )
                    ],
                  ),
                  SizedBox(height: 34),
                  Text(
                    commonService.labelData.value.data.enable_bluetooth,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    commonService.labelData.value.data.improve_bluetooth_accuracy,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        height: 1.6,
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                commonService.labelData.value.data.steps_toturnon_bluetooth,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text: commonService.labelData.value.data.open_settings,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text:
                      commonService.labelData.value.data.go_toyour_device,
                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.5,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        decorationColor: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text:
                      commonService.labelData.value.data.go_to_Bluetooth_dialog,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text:
                      commonService.labelData.value.data.depending_onyour_device,
                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.5,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        decorationColor: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text:
                      commonService.labelData.value.data.enable_bluetooth_dialog,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: commonService.labelData.value.data.toggle_switch,
                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.5,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        decorationColor: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: Platform.isAndroid,
                child: Column(
                  children: [
                    SizedBox(height: 34),
                    MkButton(
                        color: Get.theme.colorScheme.primary,
                        onTap: () {
                          try {
                            Get.back();
                            openBluetoothSettings();
                          } catch (e) {}
                        },
                        text: commonService.labelData.value.data.go_to_bluetooth),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
