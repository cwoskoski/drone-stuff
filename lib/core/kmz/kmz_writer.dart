import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../models/mission.dart';
import '../models/mission_config.dart';
import '../models/waypoint.dart';
import '../utils/xml_utils.dart';
import 'kml_template_builder.dart' as template_builder;
import 'wpml_builder.dart' as wpml_builder;

class KmzWriter {
  /// Build a KMZ from a [Mission] model (full generation).
  static Uint8List buildKmz(Mission mission) {
    final templateXml = template_builder.buildTemplate(mission);
    final waylinesXml = wpml_builder.buildWaylines(mission);
    return _packageKmz(templateXml, waylinesXml);
  }

  /// Rewrite an existing KMZ by modifying specific fields via DOM manipulation.
  /// Preserves unknown elements for round-trip fidelity.
  static Uint8List rewriteKmz(
    Uint8List original, {
    List<Waypoint>? waypoints,
    FinishAction? finishAction,
    double? speed,
  }) {
    final archive = ZipDecoder().decodeBytes(original);

    var templateXml = _extractXml(archive, 'wpmz/template.kml');
    var waylinesXml = _extractXml(archive, 'wpmz/waylines.wpml');

    if (finishAction != null) {
      templateXml = _updateElement(templateXml, 'finishAction', finishAction.name);
      waylinesXml = _updateElement(waylinesXml, 'finishAction', finishAction.name);
    }

    if (speed != null) {
      templateXml = _updateElement(
          templateXml, 'globalTransitionalSpeed', speed.toString());
      waylinesXml = _updateElement(
          waylinesXml, 'globalTransitionalSpeed', speed.toString());
    }

    if (waypoints != null) {
      // For waypoint replacement, regenerate the waylines from the modified
      // mission. Parse the original template to preserve config, then build
      // new waylines with the replacement waypoints.
      final doc = XmlDocument.parse(waylinesXml);
      final root = doc.rootElement;

      // Remove existing Folder (contains Placemarks)
      final folders = root.descendantElements
          .where((el) => el.localName == 'Folder')
          .toList();
      for (final folder in folders) {
        folder.parent?.children.remove(folder);
      }

      // We need to rebuild waylines entirely with new waypoints.
      // Parse the template to get config, create a temp mission, and build.
      // This is acceptable since we're replacing all waypoints.
      final templateDoc = XmlDocument.parse(templateXml);
      final configEl = findWpmlElement(templateDoc.rootElement, 'missionConfig');
      final authorEl = findWpmlElement(templateDoc.rootElement, 'author');

      final mission = Mission(
        id: '',
        config: configEl != null
            ? _parseConfigFromElement(configEl)
            : const MissionConfig(),
        waypoints: waypoints,
        author: authorEl?.innerText,
      );
      waylinesXml = wpml_builder.buildWaylines(mission);
    }

    return _packageKmz(templateXml, waylinesXml);
  }

  static Uint8List _packageKmz(String templateXml, String waylinesXml) {
    final archive = Archive();

    // Add directory entry
    archive.addFile(ArchiveFile('wpmz/', 0, []));

    final templateBytes = utf8.encode(templateXml);
    archive.addFile(
        ArchiveFile('wpmz/template.kml', templateBytes.length, templateBytes));

    final waylinesBytes = utf8.encode(waylinesXml);
    archive.addFile(ArchiveFile(
        'wpmz/waylines.wpml', waylinesBytes.length, waylinesBytes));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  static String _extractXml(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.name == name) {
        return utf8.decode(file.content as List<int>);
      }
    }
    throw StateError('Missing entry: $name');
  }

  /// Update a single element's text content in an XML string by local name.
  static String _updateElement(String xml, String localName, String newValue) {
    final doc = XmlDocument.parse(xml);
    final el = findWpmlElement(doc.rootElement, localName);
    if (el != null) {
      el.children.clear();
      el.children.add(XmlText(newValue));
    }
    return doc.toXmlString(pretty: true);
  }

  static MissionConfig _parseConfigFromElement(XmlElement el) {
    final droneInfo = findWpmlElement(el, 'droneInfo');
    return MissionConfig(
      finishAction:
          FinishAction.fromString(wpmlText(el, 'finishAction')),
      flyToWaylineMode: wpmlText(el, 'flyToWaylineMode') ?? 'safely',
      exitOnRCLost: wpmlText(el, 'exitOnRCLost') ?? 'goContinue',
      executeRCLostAction:
          wpmlText(el, 'executeRCLostAction') ?? 'goBack',
      globalTransitionalSpeed:
          wpmlDouble(el, 'globalTransitionalSpeed') ?? 10.0,
      droneEnumValue: droneInfo != null
          ? (wpmlInt(droneInfo, 'droneEnumValue') ?? 0)
          : 0,
      droneSubEnumValue: droneInfo != null
          ? (wpmlInt(droneInfo, 'droneSubEnumValue') ?? 0)
          : 0,
    );
  }
}
