import 'package:json_annotation/json_annotation.dart';

enum WebcamServiceType {
  @JsonValue('mjpegstreamer')
  mjpegStreamer(true),
  @JsonValue('mjpegstreamer-adaptive')
  mjpegStreamerAdaptive(true),
  @JsonValue('uv4l-mjpeg')
  uv4lMjpeg(true),
  @JsonValue('ipstream')
  ipStream(false),
  @JsonValue('hlsstream')
  hlsStream(false),
  @JsonValue('ipstream')
  ipstream(false),
  @JsonValue('unknown')
  unknown(false);

  final bool supported;

  const WebcamServiceType(this.supported);
}
