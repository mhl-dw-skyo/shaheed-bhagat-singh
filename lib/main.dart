import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:global_configuration/global_configuration.dart';

import 'core.dart';
import 'routes.dart' as r;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("configuration");
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  // FlutterDownloader.registerCallback(TestClass.callback);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  //await Firebase.initializeApp();
  await initService();

  configLoading();

  runApp(GetMaterialApp(
    title: 'Bhagat Singh Museum',
    debugShowCheckedModeBanner: false,
    defaultTransition: Transition.rightToLeft,
    getPages: r.Router.route,
    initialRoute: '/',
    themeMode: ThemeMode.light,
    builder: (context, widget) {
      widget = EasyLoading.init()(context, widget);
      return MediaQuery(
        child: widget,
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      );
      // return widget;
    },
    theme: ThemeData(
      primaryColor: const Color(0xffFFFFFF),
      primaryColorDark: const Color(0xffFFFFFF),
      indicatorColor: const Color(0xff000000),
      brightness: Brightness.light,
      useMaterial3: false,
      buttonTheme: ButtonThemeData(
          buttonColor: Helper.parseColorCode(Get.find<ConfigService>()
              .configData
              .value
              .btnColorLight), //  <-- dark color
          textTheme: ButtonTextTheme.primary, //
          colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: Helper.parseColorCode(
                  Get.find<ConfigService>().configData.value.btnColorLight),
              secondary: Helper.parseColorCode(Get.find<ConfigService>()
                  .configData
                  .value
                  .btnTextColorLight)) // <-- this auto selects the right color
          ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xffF2660F),
        secondary: const Color(0xffEC9912),
      ),
      highlightColor: Colors.white,
      hintColor: Colors.grey[300],
    ),
  ));
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

initService() async {
  await GetStorage.init();
  Get.put(AuthService(), permanent: true);
  Get.put(ConfigService(), permanent: true);
  Get.put(CommonService(), permanent: true);
  // Get.put(ConfigController(), permanent: true);
  // Get.put(SplashController(), permanent: true);
  Get.put(ConfigApi(), permanent: true);
}

class TestClass {
  static void callback(String id, int status, int progress) {}
}
