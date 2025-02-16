import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/data/data_source/json_rpc_client.dart';
import 'package:mobileraker/data/model/hive/machine.dart';
import 'package:mobileraker/logger.dart';
import 'package:mobileraker/service/machine_service.dart';
import 'package:mobileraker/service/moonraker/jrpc_client_provider.dart';
import 'package:mobileraker/service/moonraker/printer_service.dart';
import 'package:mobileraker/service/selected_machine_service.dart';
import 'package:mobileraker/ui/screens/dashboard/components/control_xyz/control_xyz_card_controller.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class PullToRefreshPrinter extends ConsumerStatefulWidget {
  const PullToRefreshPrinter({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  ConsumerState createState() => _PullToRefreshPrinterState();
}

class _PullToRefreshPrinterState extends ConsumerState<PullToRefreshPrinter> {
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    var onBackground = Theme.of(context).colorScheme.onBackground;
    return SmartRefresher(
      header: ClassicHeader(
        textStyle: TextStyle(color: onBackground),
        failedIcon: Icon(Icons.error, color: onBackground),
        completeIcon: Icon(Icons.done, color: onBackground),
        idleIcon: Icon(Icons.arrow_downward, color: onBackground),
        releaseIcon: Icon(Icons.refresh, color: onBackground),
      ),
      controller: refreshController,
      onRefresh: onRefresh,
      child: widget.child,
    );
  }

  onRefresh() async {
    final Machine? selMachine;
    try {
      ref.invalidate(controlXYZCardControllerProvider);

      selMachine = await ref.read(selectedMachineProvider.future);

      if (selMachine == null) {
        refreshController.refreshFailed();
        return;
      }
    } catch (_) {
      refreshController.refreshFailed();
      return;
    }

    // late ProviderSubscription sub;
    ClientType clientType = ref.read(jrpcClientTypeProvider(selMachine.uuid));

    logger.i('Refreshing $clientType was PULL to REFRESH');

    if (clientType == ClientType.octo) {
      await ref.refresh(machineProvider(selMachine.uuid).future);
      refreshController.refreshCompleted();
      return;
    } else {
      // need to invalidate the printer Service to ensure we get new printer data!
      ref.invalidate(printerServiceProvider(selMachine.uuid));
      await ref.refresh(printerProvider(selMachine.uuid).future);
      refreshController.refreshCompleted();
    }
  }

  @override
  void dispose() {
    super.dispose();
    refreshController.dispose();
  }
}
