//TODO Decide regarding null values or not!
import 'package:flutter/foundation.dart';
import 'package:mobileraker/data/dto/config/config_file_entry_enum.dart';
import 'package:mobileraker/data/dto/config/config_gcode_macro.dart';
import 'package:mobileraker/data/dto/config/fan/config_controller_fan.dart';
import 'package:mobileraker/data/dto/config/fan/config_fan.dart';
import 'package:mobileraker/data/dto/config/fan/config_generic_fan.dart';
import 'package:mobileraker/data/dto/config/fan/config_heater_fan.dart';
import 'package:mobileraker/data/dto/config/fan/config_print_cooling_fan.dart';
import 'package:mobileraker/data/dto/config/fan/config_temperature_fan.dart';
import 'package:mobileraker/data/dto/config/led/config_dotstar.dart';
import 'package:mobileraker/data/dto/config/led/config_dumb_led.dart';
import 'package:mobileraker/data/dto/config/led/config_led.dart';
import 'package:mobileraker/data/dto/config/led/config_neopixel.dart';
import 'package:mobileraker/data/dto/config/led/config_pca_led.dart';

import 'config_extruder.dart';
import 'config_heater_bed.dart';
import 'config_output.dart';
import 'config_printer.dart';
import 'config_stepper.dart';

class ConfigFile {
  ConfigPrinter? configPrinter;
  ConfigHeaterBed? configHeaterBed;
  ConfigPrintCoolingFan? configPrintCoolingFan;
  Map<String, ConfigExtruder> extruders = {};
  Map<String, ConfigOutput> outputs = {};
  Map<String, ConfigStepper> steppers = {};
  Map<String, ConfigGcodeMacro> gcodeMacros = {};
  Map<String, ConfigLed> leds = {};
  Map<String, ConfigFan> fans = {};

  ConfigFile();

  ConfigStepper? get stepperX => steppers['x'];

  ConfigStepper? get stepperY => steppers['y'];

  ConfigFile.parse(this.rawConfig) {
    if (rawConfig.containsKey('printer')) {
      configPrinter = ConfigPrinter.parse(rawConfig['printer']);
    }
    if (rawConfig.containsKey('heater_bed')) {
      configHeaterBed = ConfigHeaterBed.parse(rawConfig['heater_bed']);
    }

    for (String key in rawConfig.keys) {
      List<String> split = key.split(" ");
      String object = split[0].toLowerCase();
      String objectName = (split.length > 1) ? split.skip(1).join(" ") : object;

      Map<String, dynamic> jsonChild = Map.of(rawConfig[key]);

      if (object == ConfigFileEntry.extruder.name) {
        if (jsonChild.containsKey('shared_heater')) {
          String sharedHeater = jsonChild['shared_heater'];
          Map<String, dynamic> sharedHeaterConfig =
              Map.of(rawConfig[sharedHeater]);
          sharedHeaterConfig
              .removeWhere((key, value) => jsonChild.containsKey(key));
          jsonChild.addAll(sharedHeaterConfig);
        }
        extruders[object] = ConfigExtruder.parse(object, jsonChild);
      } else if (object == ConfigFileEntry.output_pin.name) {
        outputs[objectName] = ConfigOutput.parse(objectName, jsonChild);
      } else if (object.startsWith(ConfigFileEntry.stepper.name)) {
        List<String> split = key.split("_");
        String name = split.length > 1 ? split.skip(1).join("_") : split[0];
        steppers[name] = ConfigStepper.parse(name, jsonChild);
      } else if (object == ConfigFileEntry.gcode_macro.name) {
        gcodeMacros[objectName] = ConfigGcodeMacro.parse(objectName, jsonChild);
      } else if (object == ConfigFileEntry.dotstar.name) {
        leds[objectName] = ConfigDotstar.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.neopixel.name) {
        leds[objectName] = ConfigNeopixel.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.led.name) {
        leds[objectName] = ConfigDumbLed.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.pca9533.name ||
          object == ConfigFileEntry.pca9632.name) {
        //pca9533 and pcapca9632
        leds[objectName] = ConfigPcaLed.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.fan.name) {
        configPrintCoolingFan = ConfigPrintCoolingFan.fromJson(jsonChild);
      } else if (object == ConfigFileEntry.heater_fan.name) {
        fans[objectName] = ConfigHeaterFan.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.controller_fan.name) {
        fans[objectName] = ConfigControllerFan.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.temperature_fan.name) {
        fans[objectName] = ConfigTemperatureFan.fromJson(objectName, jsonChild);
      } else if (object == ConfigFileEntry.fan_generic.name) {
        fans[objectName] = ConfigGenericFan.fromJson(objectName, jsonChild);
      }
    }
    //ToDo parse the config for e.g. EXTRUDERS (Temp settings), ...
  }

  Map<String, dynamic> rawConfig = {};

  bool saveConfigPending = false;

  bool get hasQuadGantry => rawConfig.containsKey('quad_gantry_level');

  bool get hasBedMesh => rawConfig.containsKey('bed_mesh');

  bool get hasScrewTiltAdjust => rawConfig.containsKey('screws_tilt_adjust');

  bool get hasZTilt => rawConfig.containsKey('z_tilt');

  ConfigExtruder? get primaryExtruder => extruders['extruder'];

  ConfigExtruder? extruderForIndex(int idx) =>
      extruders['extruder${idx > 0 ? idx : ''}'];

  double get maxX => stepperX?.positionMax ?? 300;

  double get minX => stepperX?.positionMin ?? 0;

  double get maxY => stepperY?.positionMax ?? 300;

  double get minY => stepperY?.positionMin ?? 0;

  double get sizeX => maxX + minX.abs();

  double get sizeY => maxY + minY.abs();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigFile &&
          runtimeType == other.runtimeType &&
          configPrinter == other.configPrinter &&
          configHeaterBed == other.configHeaterBed &&
          mapEquals(extruders, other.extruders) &&
          mapEquals(outputs, other.outputs) &&
          mapEquals(steppers, other.steppers) &&
          rawConfig == other.rawConfig &&
          saveConfigPending == other.saveConfigPending;

  @override
  int get hashCode =>
      configPrinter.hashCode ^
      configHeaterBed.hashCode ^
      extruders.hashCode ^
      outputs.hashCode ^
      steppers.hashCode ^
      rawConfig.hashCode ^
      saveConfigPending.hashCode;

  @override
  String toString() {
    return 'ConfigFile{configPrinter: $configPrinter, configHeaterBed: $configHeaterBed, extruders: $extruders, outputs: $outputs, steppers: $steppers, rawConfig: $rawConfig, saveConfigPending: $saveConfigPending}';
  }
}
