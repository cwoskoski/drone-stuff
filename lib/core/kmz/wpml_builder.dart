import 'package:xml/xml.dart';

import '../models/mission.dart';
import '../models/waypoint.dart';

const _kmlNs = 'http://www.opengis.net/kml/2.2';
const _wpmlNs = 'http://www.dji.com/wpmz/1.0.6';

String buildWaylines(Mission mission) {
  final config = mission.config;

  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('kml', namespace: _kmlNs, namespaces: {
    _kmlNs: null,
    _wpmlNs: 'wpml',
  }, nest: () {
    builder.element('Document', namespace: _kmlNs, nest: () {
      // Mission config block
      builder.element('missionConfig', namespace: _wpmlNs, nest: () {
        _wpmlEl(builder, 'flyToWaylineMode', config.flyToWaylineMode);
        _wpmlEl(builder, 'finishAction', config.finishAction.name);
        _wpmlEl(builder, 'exitOnRCLost', config.exitOnRCLost);
        _wpmlEl(builder, 'executeRCLostAction', config.executeRCLostAction);
        _wpmlEl(builder, 'globalTransitionalSpeed',
            config.globalTransitionalSpeed.toString());
        builder.element('droneInfo', namespace: _wpmlNs, nest: () {
          _wpmlEl(
              builder, 'droneEnumValue', config.droneEnumValue.toString());
          _wpmlEl(builder, 'droneSubEnumValue',
              config.droneSubEnumValue.toString());
        });
      });

      // Folder containing waypoints
      builder.element('Folder', namespace: _kmlNs, nest: () {
        _wpmlEl(builder, 'templateId', '0');
        _wpmlEl(builder, 'executeHeightMode', 'relativeToStartPoint');
        _wpmlEl(builder, 'waylineId', '0');
        _wpmlEl(builder, 'distance', '0');
        _wpmlEl(builder, 'duration', '0');
        _wpmlEl(builder, 'autoFlightSpeed',
            mission.waypoints.isNotEmpty
                ? mission.waypoints.first.waypointSpeed.toString()
                : '8');

        for (final wp in mission.waypoints) {
          _buildPlacemark(builder, wp);
        }
      });
    });
  });

  return builder.buildDocument().toXmlString(pretty: true);
}

void _buildPlacemark(XmlBuilder builder, Waypoint wp) {
  builder.element('Placemark', namespace: _kmlNs, nest: () {
    builder.element('Point', namespace: _kmlNs, nest: () {
      builder.element('coordinates', namespace: _kmlNs,
          nest: '${wp.longitude},${wp.latitude}');
    });
    _wpmlEl(builder, 'index', wp.index.toString());
    _wpmlEl(builder, 'executeHeight', wp.executeHeight.toString());
    _wpmlEl(builder, 'waypointSpeed', wp.waypointSpeed.toString());

    // Heading params
    builder.element('waypointHeadingParam', namespace: _wpmlNs, nest: () {
      _wpmlEl(builder, 'waypointHeadingMode', wp.heading.mode);
      _wpmlEl(
          builder, 'waypointHeadingAngle', wp.heading.angle.toString());
      _wpmlEl(builder, 'waypointPoiPoint', wp.heading.poiPoint);
      _wpmlEl(builder, 'waypointHeadingAngleEnable',
          wp.heading.angleEnabled ? '1' : '0');
      _wpmlEl(builder, 'waypointHeadingPathMode', wp.heading.pathMode);
      _wpmlEl(builder, 'waypointHeadingPoiIndex',
          wp.heading.poiIndex.toString());
    });

    // Turn params
    builder.element('waypointTurnParam', namespace: _wpmlNs, nest: () {
      _wpmlEl(builder, 'waypointTurnMode', wp.turn.mode);
      _wpmlEl(builder, 'waypointTurnDampingDist',
          wp.turn.dampingDist.toString());
    });

    _wpmlEl(builder, 'useStraightLine', wp.useStraightLine ? '1' : '0');

    // Action groups
    for (final ag in wp.actionGroups) {
      _buildActionGroup(builder, ag);
    }

    // Gimbal heading
    if (wp.gimbalHeading != null) {
      builder.element('waypointGimbalHeadingParam', namespace: _wpmlNs,
          nest: () {
        _wpmlEl(builder, 'waypointGimbalPitchAngle',
            wp.gimbalHeading!.pitchAngle.toString());
        _wpmlEl(builder, 'waypointGimbalYawAngle',
            wp.gimbalHeading!.yawAngle.toString());
      });
    }
  });
}

void _buildActionGroup(
    XmlBuilder builder, dynamic ag) {
  builder.element('actionGroup', namespace: _wpmlNs, nest: () {
    _wpmlEl(builder, 'actionGroupId', ag.groupId.toString());
    _wpmlEl(builder, 'actionGroupStartIndex', ag.startIndex.toString());
    _wpmlEl(builder, 'actionGroupEndIndex', ag.endIndex.toString());
    _wpmlEl(builder, 'actionGroupMode', ag.mode);
    builder.element('actionTrigger', namespace: _wpmlNs, nest: () {
      _wpmlEl(builder, 'actionTriggerType', ag.triggerType);
    });
    for (final action in ag.actions) {
      builder.element('action', namespace: _wpmlNs, nest: () {
        _wpmlEl(builder, 'actionId', action.actionId.toString());
        _wpmlEl(builder, 'actionActuatorFunc', action.actuatorFunc);
        if (action.params.isNotEmpty) {
          builder.element('actionActuatorFuncParam', namespace: _wpmlNs,
              nest: () {
            for (final entry in action.params.entries) {
              _wpmlEl(builder, entry.key, entry.value.toString());
            }
          });
        }
      });
    }
  });
}

void _wpmlEl(XmlBuilder builder, String name, String text) {
  builder.element(name, namespace: _wpmlNs, nest: text);
}
