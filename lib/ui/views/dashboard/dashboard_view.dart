import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:animations/animations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobileraker/app/app_setup.router.dart';
import 'package:mobileraker/dto/machine/print_stats.dart';
import 'package:mobileraker/dto/server/klipper.dart';
import 'package:mobileraker/ui/components/connection/connection_state_view.dart';
import 'package:mobileraker/ui/components/drawer/nav_drawer_view.dart';
import 'package:mobileraker/ui/components/machine_state_indicator.dart';
import 'package:mobileraker/ui/views/dashboard/tabs/control_tab.dart';
import 'package:mobileraker/ui/views/dashboard/tabs/general_tab.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:stacked/stacked.dart';

import 'dashboard_viewmodel.dart';

class DashboardView extends ViewModelBuilderWidget<DashboardViewModel> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, DashboardViewModel model, Widget? child) =>
      Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            child: Text(
              model.title,
              overflow: TextOverflow.fade,
            ),
            onHorizontalDragEnd: model.onHorizontalDragEnd,
          ),
          actions: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: MachineStateIndicator(
                  model.isServerAvailable ? model.server : null),
            ),
            IconButton(
              color: Colors.red,
              icon: Icon(
                Icons.dangerous_outlined,
                size: 30,
              ),
              tooltip: 'pages.dashboard.ems_btn'.tr(),
              onPressed: (model.canUseEms) ? model.onEmergencyPressed : null,
            ),
          ],
        ),
        body: ConnectionStateView(
          body: (model.isPrinterAvailable)
              ? PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 300),
                  reverse: model.reverse,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) {
                    return SharedAxisTransition(
                      child: child,
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                    );
                  },
                  child: _getViewForIndex(model.currentIndex),
                )
              : Center(
                  child: Column(
                    key: UniqueKey(),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitFadingCube(
                        color: Colors.orange,
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      FadingText('pages.dashboard.fetching_printer'.tr()),
                      // Text("Fetching printer ...")
                    ],
                  ),
                ),
        ),
        floatingActionButton: printingStateToFab(model),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: (model.isMachineAvailable &&
                model.isPrinterAvailable &&
                model.isServerAvailable)
            ? AnimatedBottomNavigationBar(
                // ToDo swap with Text
                icons: [
                  FlutterIcons.tachometer_faw,
                  // FlutterIcons.camera_control_mco,
                  FlutterIcons.settings_oct,
                ],
                activeColor: _getActiveTextColor(context),
                gapLocation: GapLocation.end,
                backgroundColor: Theme.of(context).primaryColor,
                notchSmoothness: NotchSmoothness.softEdge,
                activeIndex: model.currentIndex,
                onTap: model.setIndex,
              )
            : null,
        drawer: NavigationDrawerWidget(curPath: Routes.dashboardView),
      );

  @override
  DashboardViewModel viewModelBuilder(BuildContext context) => DashboardViewModel();

  Color? _getActiveTextColor(context) {
    var themeData = Theme.of(context);
    if (themeData.brightness == Brightness.dark)
      return themeData.colorScheme.secondary;
    return Colors.white;
  }

  Widget _getViewForIndex(int index) {
    switch (index) {
      case 0:
        return GeneralTab();
      case 1:
        return ControlTab();
      default:
        return GeneralTab();
    }
  }

  Widget? printingStateToFab(DashboardViewModel model) {
    if (!model.isPrinterAvailable || !model.isServerAvailable) return null;

    if (model.server.klippyState == KlipperState.error) return IdleFAB();

    switch (model.printer.print.state) {
      case PrintState.printing:
        return FloatingActionButton(
          onPressed: model.onPausePrintPressed,
          child: Icon(Icons.pause),
        );
      case PrintState.paused:
        return PausedFAB();
      default:
        return IdleFAB();
    }
  }
}

class IdleFAB extends ViewModelWidget<DashboardViewModel> {
  const IdleFAB({
    Key? key,
  }) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, DashboardViewModel model) {
    return FloatingActionButton(
        child: Icon(Icons.menu), onPressed: () => model.showNonPrintingMenu());
  }
}

class PausedFAB extends ViewModelWidget<DashboardViewModel> {
  const PausedFAB({
    Key? key,
  }) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, DashboardViewModel model) {
    return SpeedDial(
      icon: FlutterIcons.options_vertical_sli,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: Icon(Icons.cleaning_services),
          backgroundColor: Colors.red,
          label: tr('general.cancel'),
          onTap: model.onCancelPrintPressed,
        ),
        SpeedDialChild(
          child: Icon(Icons.play_arrow),
          backgroundColor: Colors.blue,
          label: tr('general.resume'),
          onTap: model.onResumePrintPressed,
        ),
      ],
      spacing: 5,
      overlayOpacity: 0,
    );
  }
}
