import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:logger/logger.dart';
import 'package:mobileraker/app/app_setup.dart';
import 'package:mobileraker/app/app_setup.locator.dart';
import 'package:mobileraker/firebase_options.dart';
import 'package:mobileraker/service/notification_service.dart';
import 'package:mobileraker/ui/components/bottomsheet/setup_bottom_sheet_ui.dart';
import 'package:mobileraker/ui/components/dialog/setup_dialog_ui.dart';
import 'package:mobileraker/ui/components/snackbar/setup_snackbar.dart';
import 'package:mobileraker/ui/theme_setup.dart';
import 'package:stacked_services/stacked_services.dart';

import 'app/app_setup.router.dart';
import 'service/setting_service.dart';
import 'ui/views/setting/setting_viewmodel.dart';

Future<void> main() async {
  Logger.level = Level.info;
  // EasyLocalization.logger.enableLevels = [LevelMessages.info];
  WidgetsFlutterBinding.ensureInitialized();
  await setupBoxes();
  setupLocator();
  await locator.allReady();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  await locator<NotificationService>().initialize();
  setupSnackbarUi();
  setupDialogUi();
  setupBottomSheetUi();
  await FirebaseAnalytics.instance.logAppOpen();
  await setupCat();
  runApp(EasyLocalization(
      child: MyApp(),
      supportedLocales: [Locale('en'), Locale('de')],
      fallbackLocale: Locale('en'),
      saveLocale: true,
      useFallbackTranslations: true,
      path: 'assets/translations'));
}

class MyApp extends StatelessWidget {
  final _settingService = locator<SettingService>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobileraker',
      theme: getLightTheme(context),
      darkTheme: getDarkTheme(context),
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: _settingService.readBool(startWithOverviewKey)
          ? Routes.overViewView
          : null,
      localizationsDelegates: [
        FormBuilderLocalizations.delegate,
        ...context.localizationDelegates
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
