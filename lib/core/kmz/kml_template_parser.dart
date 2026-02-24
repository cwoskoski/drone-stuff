import 'package:xml/xml.dart';

import '../models/mission_config.dart';
import '../utils/xml_utils.dart';

class TemplateParseResult {
  final String? author;
  final DateTime? createTime;
  final DateTime? updateTime;
  final MissionConfig config;

  const TemplateParseResult({
    this.author,
    this.createTime,
    this.updateTime,
    required this.config,
  });
}

TemplateParseResult parseTemplate(String xmlString) {
  final doc = XmlDocument.parse(xmlString);
  final root = doc.rootElement;

  final author = wpmlText(root, 'author');
  final createTime = _parseTimestamp(wpmlText(root, 'createTime'));
  final updateTime = _parseTimestamp(wpmlText(root, 'updateTime'));

  final configEl = findWpmlElement(root, 'missionConfig');
  final config = configEl != null
      ? _parseMissionConfig(configEl)
      : const MissionConfig();

  return TemplateParseResult(
    author: author,
    createTime: createTime,
    updateTime: updateTime,
    config: config,
  );
}

MissionConfig _parseMissionConfig(XmlElement el) {
  final droneInfo = findWpmlElement(el, 'droneInfo');
  return MissionConfig(
    finishAction: FinishAction.fromString(wpmlText(el, 'finishAction')),
    flyToWaylineMode: wpmlText(el, 'flyToWaylineMode') ?? 'safely',
    exitOnRCLost: wpmlText(el, 'exitOnRCLost') ?? 'goContinue',
    executeRCLostAction: wpmlText(el, 'executeRCLostAction') ?? 'goBack',
    globalTransitionalSpeed:
        wpmlDouble(el, 'globalTransitionalSpeed') ?? 10.0,
    droneEnumValue:
        droneInfo != null ? (wpmlInt(droneInfo, 'droneEnumValue') ?? 0) : 0,
    droneSubEnumValue: droneInfo != null
        ? (wpmlInt(droneInfo, 'droneSubEnumValue') ?? 0)
        : 0,
  );
}

DateTime? _parseTimestamp(String? value) {
  if (value == null) return null;
  final ms = int.tryParse(value);
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}
