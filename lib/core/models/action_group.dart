class ActionGroup {
  final int groupId;
  final int startIndex;
  final int endIndex;
  final String mode;
  final String triggerType;
  final List<WaypointAction> actions;

  const ActionGroup({
    required this.groupId,
    required this.startIndex,
    required this.endIndex,
    this.mode = 'parallel',
    this.triggerType = 'reachPoint',
    this.actions = const [],
  });
}

class WaypointAction {
  final int actionId;
  final String actuatorFunc;
  final Map<String, dynamic> params;

  const WaypointAction({
    required this.actionId,
    required this.actuatorFunc,
    this.params = const {},
  });
}
