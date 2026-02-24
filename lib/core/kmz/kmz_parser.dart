import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../models/mission.dart';
import 'kml_template_parser.dart';
import 'wpml_parser.dart';

class KmzParseException implements Exception {
  final String message;
  const KmzParseException(this.message);

  @override
  String toString() => 'KmzParseException: $message';
}

class KmzParser {
  static const _uuid = Uuid();

  /// Parse a KMZ file from raw bytes into a [Mission].
  static Mission parseBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final templateFile = _findEntry(archive, 'wpmz/template.kml');
    final waylinesFile = _findEntry(archive, 'wpmz/waylines.wpml');

    if (templateFile == null || waylinesFile == null) {
      final missing = <String>[];
      if (templateFile == null) missing.add('wpmz/template.kml');
      if (waylinesFile == null) missing.add('wpmz/waylines.wpml');
      throw KmzParseException(
        'Missing required entries: ${missing.join(', ')}',
      );
    }

    final templateXml = utf8.decode(templateFile.content as List<int>);
    final waylinesXml = utf8.decode(waylinesFile.content as List<int>);

    final template = parseTemplate(templateXml);
    final waypoints = parseWaylines(waylinesXml);

    return Mission(
      id: _uuid.v4(),
      config: template.config,
      waypoints: waypoints,
      author: template.author,
      createTime: template.createTime,
      updateTime: template.updateTime,
      rawKmzBytes: bytes,
    );
  }

  /// Validate that bytes represent a valid KMZ with required entries.
  static void validate(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw KmzParseException('Not a valid ZIP/KMZ file');
    }

    for (final required in requiredKmzEntries) {
      if (_findEntry(archive, required) == null) {
        throw KmzParseException("Missing required entry '$required'");
      }
    }
  }

  static ArchiveFile? _findEntry(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.name == name) return file;
    }
    return null;
  }
}
