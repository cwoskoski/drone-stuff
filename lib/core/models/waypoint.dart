import 'action_group.dart';

class WaypointHeading {
  final String mode;
  final double angle;
  final String poiPoint;
  final bool angleEnabled;
  final String pathMode;
  final int poiIndex;

  const WaypointHeading({
    this.mode = 'smoothTransition',
    this.angle = 0.0,
    this.poiPoint = '0.000000,0.000000,0.000000',
    this.angleEnabled = true,
    this.pathMode = 'followBadArc',
    this.poiIndex = 0,
  });
}

class WaypointTurn {
  final String mode;
  final double dampingDist;

  const WaypointTurn({
    this.mode = 'toPointAndStopWithContinuityCurvature',
    this.dampingDist = 0.0,
  });
}

class GimbalHeading {
  final double pitchAngle;
  final double yawAngle;

  const GimbalHeading({
    this.pitchAngle = 0.0,
    this.yawAngle = 0.0,
  });
}

class Waypoint {
  final int index;
  final double longitude;
  final double latitude;
  final double executeHeight;
  final double waypointSpeed;
  final WaypointHeading heading;
  final WaypointTurn turn;
  final bool useStraightLine;
  final List<ActionGroup> actionGroups;
  final GimbalHeading? gimbalHeading;

  const Waypoint({
    required this.index,
    required this.longitude,
    required this.latitude,
    required this.executeHeight,
    required this.waypointSpeed,
    this.heading = const WaypointHeading(),
    this.turn = const WaypointTurn(),
    this.useStraightLine = false,
    this.actionGroups = const [],
    this.gimbalHeading,
  });
}
