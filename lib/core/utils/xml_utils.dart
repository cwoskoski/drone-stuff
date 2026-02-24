import 'package:xml/xml.dart';

import '../constants.dart';

/// Find a single element by local name, trying known wpml namespaces first,
/// then falling back to brute-force local-name matching.
XmlElement? findWpmlElement(XmlNode parent, String localName) {
  for (final ns in wpmlNamespaces) {
    final found = _findDescendant(parent, localName, ns);
    if (found != null) return found;
  }
  // Fallback: match by local name regardless of namespace
  for (final el in parent.descendantElements) {
    if (el.localName == localName) return el;
  }
  return null;
}

/// Find all elements matching the local name across known wpml namespaces.
List<XmlElement> findAllWpml(XmlNode parent, String localName) {
  for (final ns in wpmlNamespaces) {
    final results = _findAllDescendants(parent, localName, ns);
    if (results.isNotEmpty) return results;
  }
  // Fallback: match by local name
  return parent.descendantElements
      .where((el) => el.localName == localName)
      .toList();
}

/// Get text content of a child wpml element, or null if not found.
String? wpmlText(XmlNode parent, String localName) {
  return findWpmlElement(parent, localName)?.innerText;
}

/// Get text content as double, or null if not found/parseable.
double? wpmlDouble(XmlNode parent, String localName) {
  final text = wpmlText(parent, localName);
  if (text == null) return null;
  return double.tryParse(text);
}

/// Get text content as int, or null if not found/parseable.
int? wpmlInt(XmlNode parent, String localName) {
  final text = wpmlText(parent, localName);
  if (text == null) return null;
  return int.tryParse(text);
}

XmlElement? _findDescendant(XmlNode parent, String localName, String ns) {
  for (final el in parent.descendantElements) {
    if (el.localName == localName && el.namespaceUri == ns) {
      return el;
    }
  }
  return null;
}

List<XmlElement> _findAllDescendants(
  XmlNode parent,
  String localName,
  String ns,
) {
  return parent.descendantElements
      .where((el) => el.localName == localName && el.namespaceUri == ns)
      .toList();
}
