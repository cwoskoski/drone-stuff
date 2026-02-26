enum FinishAction {
  goHome,
  noAction,
  autoLand,
  backToFirstWaypoint;

  String get displayName => switch (this) {
        goHome => 'Go Home',
        noAction => 'No Action',
        autoLand => 'Auto Land',
        backToFirstWaypoint => 'Back to First',
      };

  static FinishAction fromString(String? value) {
    switch (value) {
      case 'goHome':
        return FinishAction.goHome;
      case 'noAction':
        return FinishAction.noAction;
      case 'autoLand':
        return FinishAction.autoLand;
      case 'backToFirstWaypoint':
        return FinishAction.backToFirstWaypoint;
      default:
        return FinishAction.goHome;
    }
  }
}

class MissionConfig {
  final FinishAction finishAction;
  final String flyToWaylineMode;
  final String exitOnRCLost;
  final String executeRCLostAction;
  final double globalTransitionalSpeed;
  final int droneEnumValue;
  final int droneSubEnumValue;

  const MissionConfig({
    this.finishAction = FinishAction.goHome,
    this.flyToWaylineMode = 'safely',
    this.exitOnRCLost = 'goContinue',
    this.executeRCLostAction = 'goBack',
    this.globalTransitionalSpeed = 10.0,
    this.droneEnumValue = 0,
    this.droneSubEnumValue = 0,
  });
}
