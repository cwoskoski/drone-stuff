import 'package:xml/xml.dart';

import '../constants.dart';
import '../models/action_group.dart';
import '../models/waypoint.dart';
import '../utils/xml_utils.dart';

List<Waypoint> parseWaylines(String xmlString) {
  final doc = XmlDocument.parse(xmlString);
  final root = doc.rootElement;

  // Find all Placemark elements (KML namespace)
  final placemarks = root.descendantElements
      .where((el) =>
          el.localName == 'Placemark' &&
          (el.namespaceUri == kmlNamespace || el.namespaceUri == null))
      .toList();

  return placemarks.map(_parsePlacemark).toList();
}

Waypoint _parsePlacemark(XmlElement el) {
  final coords = _parseCoordinates(el);

  return Waypoint(
    index: wpmlInt(el, 'index') ?? 0,
    longitude: coords.$1,
    latitude: coords.$2,
    executeHeight: wpmlDouble(el, 'executeHeight') ?? 0.0,
    waypointSpeed: wpmlDouble(el, 'waypointSpeed') ?? 0.0,
    heading: _parseHeading(el),
    turn: _parseTurn(el),
    useStraightLine: wpmlText(el, 'useStraightLine') == '1',
    actionGroups: _parseActionGroups(el),
    gimbalHeading: _parseGimbalHeading(el),
  );
}

(double, double) _parseCoordinates(XmlElement placemark) {
  final pointEl = placemark.descendantElements
      .where((el) => el.localName == 'coordinates')
      .firstOrNull;
  if (pointEl == null) return (0.0, 0.0);

  final parts = pointEl.innerText.trim().split(',');
  if (parts.length < 2) return (0.0, 0.0);

  return (
    double.tryParse(parts[0]) ?? 0.0,
    double.tryParse(parts[1]) ?? 0.0,
  );
}

WaypointHeading _parseHeading(XmlElement placemark) {
  final headingEl = findWpmlElement(placemark, 'waypointHeadingParam');
  if (headingEl == null) return const WaypointHeading();

  return WaypointHeading(
    mode: wpmlText(headingEl, 'waypointHeadingMode') ?? 'smoothTransition',
    angle: wpmlDouble(headingEl, 'waypointHeadingAngle') ?? 0.0,
    poiPoint: wpmlText(headingEl, 'waypointPoiPoint') ??
        '0.000000,0.000000,0.000000',
    angleEnabled:
        wpmlText(headingEl, 'waypointHeadingAngleEnable') == '1',
    pathMode:
        wpmlText(headingEl, 'waypointHeadingPathMode') ?? 'followBadArc',
    poiIndex: wpmlInt(headingEl, 'waypointHeadingPoiIndex') ?? 0,
  );
}

WaypointTurn _parseTurn(XmlElement placemark) {
  final turnEl = findWpmlElement(placemark, 'waypointTurnParam');
  if (turnEl == null) return const WaypointTurn();

  return WaypointTurn(
    mode: wpmlText(turnEl, 'waypointTurnMode') ??
        'toPointAndStopWithContinuityCurvature',
    dampingDist: wpmlDouble(turnEl, 'waypointTurnDampingDist') ?? 0.0,
  );
}

List<ActionGroup> _parseActionGroups(XmlElement placemark) {
  final groupEls = findAllWpml(placemark, 'actionGroup');
  return groupEls.map(_parseActionGroup).toList();
}

ActionGroup _parseActionGroup(XmlElement el) {
  final triggerEl = findWpmlElement(el, 'actionTrigger');
  final actionEls = findAllWpml(el, 'action');

  return ActionGroup(
    groupId: wpmlInt(el, 'actionGroupId') ?? 0,
    startIndex: wpmlInt(el, 'actionGroupStartIndex') ?? 0,
    endIndex: wpmlInt(el, 'actionGroupEndIndex') ?? 0,
    mode: wpmlText(el, 'actionGroupMode') ?? 'parallel',
    triggerType: triggerEl != null
        ? (wpmlText(triggerEl, 'actionTriggerType') ?? 'reachPoint')
        : 'reachPoint',
    actions: actionEls.map(_parseAction).toList(),
  );
}

WaypointAction _parseAction(XmlElement el) {
  final paramsEl = findWpmlElement(el, 'actionActuatorFuncParam');
  final params = <String, dynamic>{};

  if (paramsEl != null) {
    for (final child in paramsEl.childElements) {
      final text = child.innerText.trim();
      // Try to parse as number, otherwise keep as string
      final intVal = int.tryParse(text);
      if (intVal != null) {
        params[child.localName] = intVal;
      } else {
        final doubleVal = double.tryParse(text);
        if (doubleVal != null) {
          params[child.localName] = doubleVal;
        } else {
          params[child.localName] = text;
        }
      }
    }
  }

  return WaypointAction(
    actionId: wpmlInt(el, 'actionId') ?? 0,
    actuatorFunc: wpmlText(el, 'actionActuatorFunc') ?? '',
    params: params,
  );
}

GimbalHeading? _parseGimbalHeading(XmlElement placemark) {
  final gimbalEl = findWpmlElement(placemark, 'waypointGimbalHeadingParam');
  if (gimbalEl == null) return null;

  return GimbalHeading(
    pitchAngle: wpmlDouble(gimbalEl, 'waypointGimbalPitchAngle') ?? 0.0,
    yawAngle: wpmlDouble(gimbalEl, 'waypointGimbalYawAngle') ?? 0.0,
  );
}
