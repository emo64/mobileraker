import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'gcode_macro.g.dart';

@HiveType(typeId: 4)
class GCodeMacro {
  @HiveField(0)
  String name;
  @HiveField(1)
  String uuid = Uuid().v4();
  @HiveField(2)
  bool visible = true;
  @HiveField(3)
  bool showWhilePrinting = true;

  GCodeMacro(this.name);

  @override
  String toString() {
    return 'GCodeMacro{name: $name, uuid: $uuid, showWhilePrinting: $showWhilePrinting}';
  }
}
