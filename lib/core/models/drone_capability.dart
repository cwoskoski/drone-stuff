import 'dart:convert';

class ZoomCapability {
  final String name;
  final double maxZoom;

  const ZoomCapability({required this.name, required this.maxZoom});
}

class DroneCapability {
  final double speedMin;
  final double speedMax;
  final double speedDefault;
  final double gimbalPitchMin;
  final double gimbalPitchMax;
  final double gimbalRollMin;
  final double gimbalRollMax;
  final List<String> lostActions;
  final List<ZoomCapability> zoomCapabilities;
  final bool isFromDevice;

  const DroneCapability({
    this.speedMin = 0.1,
    this.speedMax = 15.0,
    this.speedDefault = 10.0,
    this.gimbalPitchMin = -90.0,
    this.gimbalPitchMax = 35.0,
    this.gimbalRollMin = -90.0,
    this.gimbalRollMax = 90.0,
    this.lostActions = const ['goBack', 'goHome', 'hover'],
    this.zoomCapabilities = const [],
    this.isFromDevice = false,
  });

  /// Parses capability from individual JSON file contents.
  /// Each parameter is nullable — null means the file wasn't available.
  /// Per-field try/catch ensures partial failures don't lose all data.
  static DroneCapability fromJsonFiles({
    String? speedJson,
    String? gimbalJson,
    String? lostActionJson,
    String? zoomJson,
    String? generalJson,
  }) {
    const defaults = DroneCapability();

    double speedMin = defaults.speedMin;
    double speedMax = defaults.speedMax;
    double speedDefault = defaults.speedDefault;
    double gimbalPitchMin = defaults.gimbalPitchMin;
    double gimbalPitchMax = defaults.gimbalPitchMax;
    double gimbalRollMin = defaults.gimbalRollMin;
    double gimbalRollMax = defaults.gimbalRollMax;
    List<String> lostActions = defaults.lostActions;
    List<ZoomCapability> zoomCapabilities = defaults.zoomCapabilities;
    bool anyParsed = false;

    // Speed
    if (speedJson != null) {
      try {
        final data = jsonDecode(speedJson);
        if (data is Map<String, dynamic>) {
          final min = _toDouble(data['min']);
          final max = _toDouble(data['max']);
          final def = _toDouble(data['default']);
          if (min != null) speedMin = min;
          if (max != null) speedMax = max;
          if (def != null) speedDefault = def;
          anyParsed = true;
        }
      } catch (_) {}
    }

    // Gimbal
    if (gimbalJson != null) {
      try {
        final data = jsonDecode(gimbalJson);
        if (data is Map<String, dynamic>) {
          final pitchMin = _toDouble(data['pitchMin']);
          final pitchMax = _toDouble(data['pitchMax']);
          final rollMin = _toDouble(data['rollMin']);
          final rollMax = _toDouble(data['rollMax']);
          if (pitchMin != null) gimbalPitchMin = pitchMin;
          if (pitchMax != null) gimbalPitchMax = pitchMax;
          if (rollMin != null) gimbalRollMin = rollMin;
          if (rollMax != null) gimbalRollMax = rollMax;
          anyParsed = true;
        }
      } catch (_) {}
    }

    // Lost actions
    if (lostActionJson != null) {
      try {
        final data = jsonDecode(lostActionJson);
        if (data is Map<String, dynamic> && data['actions'] is List) {
          final actions = (data['actions'] as List)
              .whereType<String>()
              .toList();
          if (actions.isNotEmpty) {
            lostActions = actions;
            anyParsed = true;
          }
        }
      } catch (_) {}
    }

    // Zoom
    if (zoomJson != null) {
      try {
        final data = jsonDecode(zoomJson);
        if (data is Map<String, dynamic> && data['cameras'] is List) {
          final cameras = (data['cameras'] as List)
              .whereType<Map<String, dynamic>>()
              .map((c) => ZoomCapability(
                    name: c['name'] as String? ?? 'Unknown',
                    maxZoom: _toDouble(c['maxZoom']) ?? 1.0,
                  ))
              .toList();
          if (cameras.isNotEmpty) {
            zoomCapabilities = cameras;
            anyParsed = true;
          }
        }
      } catch (_) {}
    }

    return DroneCapability(
      speedMin: speedMin,
      speedMax: speedMax,
      speedDefault: speedDefault,
      gimbalPitchMin: gimbalPitchMin,
      gimbalPitchMax: gimbalPitchMax,
      gimbalRollMin: gimbalRollMin,
      gimbalRollMax: gimbalRollMax,
      lostActions: lostActions,
      zoomCapabilities: zoomCapabilities,
      isFromDevice: anyParsed,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
