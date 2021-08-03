import 'package:hive/hive.dart';
import 'package:mobileraker/WebSocket.dart';
import 'package:mobileraker/app/AppSetup.locator.dart';
import 'package:mobileraker/dto/machine/PrinterSetting.dart';
import 'package:mobileraker/service/KlippyService.dart';
import 'package:mobileraker/service/PrinterService.dart';

import 'SelectedMachineService.dart';

class PrinterSettingsService {
  final SelectedMachineService _selectedMachineService;
  late final _boxPrinterSettings = Hive.box<PrinterSetting>('printers');
  late final _boxUuid = Hive.box<String>('uuidbox');
  PrinterSettingsService(this._selectedMachineService);

  var printersBox = Hive.box<PrinterSetting>('printers');

  Future<PrinterSetting> addPrinter(PrinterSetting printerSetting) async {
    await printersBox.put(printerSetting.uuid, printerSetting);
    await _selectedMachineService.setPrinterActive(printerSetting);
    return printerSetting;
  }

  removePrinter(PrinterSetting printerSetting) async {
    await printerSetting.delete();
    if (_boxUuid.get('selectedPrinter') == printerSetting.uuid) {
      var key = (_boxPrinterSettings.isEmpty)? null: _boxPrinterSettings.keys.first;

        await _selectedMachineService.setPrinterActive(key);
    }
  }
}
