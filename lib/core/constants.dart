const waypointRoot = '/sdcard/Android/data/dji.go.v5/files/waypoint';
const capabilityDir = '$waypointRoot/capability';

final uuidPattern = RegExp(
  r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-'
  r'[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$',
);

const wpmlNamespaces = [
  'http://www.dji.com/wpmz/1.0.6',
  'http://www.uav.com/wpmz/1.0.2',
];

const kmlNamespace = 'http://www.opengis.net/kml/2.2';

const requiredKmzEntries = [
  'wpmz/template.kml',
  'wpmz/waylines.wpml',
];
