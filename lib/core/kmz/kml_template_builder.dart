import 'package:xml/xml.dart';

import '../models/mission.dart';

const _kmlNs = 'http://www.opengis.net/kml/2.2';
const _wpmlNs = 'http://www.dji.com/wpmz/1.0.6';

String buildTemplate(Mission mission) {
  final config = mission.config;

  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('kml', namespace: _kmlNs, namespaces: {
    _kmlNs: null,
    _wpmlNs: 'wpml',
  }, nest: () {
    builder.element('Document', namespace: _kmlNs, nest: () {
      _wpmlEl(builder, 'author', mission.author ?? '');
      if (mission.createTime != null) {
        _wpmlEl(builder, 'createTime',
            mission.createTime!.millisecondsSinceEpoch.toString());
      }
      if (mission.updateTime != null) {
        _wpmlEl(builder, 'updateTime',
            mission.updateTime!.millisecondsSinceEpoch.toString());
      }
      builder.element('missionConfig', namespace: _wpmlNs, nest: () {
        _wpmlEl(builder, 'flyToWaylineMode', config.flyToWaylineMode);
        _wpmlEl(builder, 'finishAction', config.finishAction.name);
        _wpmlEl(builder, 'exitOnRCLost', config.exitOnRCLost);
        _wpmlEl(builder, 'executeRCLostAction', config.executeRCLostAction);
        _wpmlEl(builder, 'globalTransitionalSpeed',
            _fmtNum(config.globalTransitionalSpeed));
        builder.element('droneInfo', namespace: _wpmlNs, nest: () {
          _wpmlEl(
              builder, 'droneEnumValue', config.droneEnumValue.toString());
          _wpmlEl(builder, 'droneSubEnumValue',
              config.droneSubEnumValue.toString());
        });
      });
    });
  });

  return builder.buildDocument().toXmlString(pretty: true);
}

void _wpmlEl(XmlBuilder builder, String name, String text) {
  builder.element(name, namespace: _wpmlNs, nest: text);
}

String _fmtNum(num value) {
  if (value is int) return value.toString();
  final d = value as double;
  return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}
