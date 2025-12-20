import 'package:google_maps_flutter/google_maps_flutter.dart';

class GridHelper {
  static const double gridOriginLat = -6.8;
  static const double gridOriginLng = 106.5;
  static const double gridSizeDeg = 0.09;

  static String? getGridId(double lat, double lng) {
    if (lat < gridOriginLat || lng < gridOriginLng) {
      return null;
    }

    final row = ((lat - gridOriginLat) / gridSizeDeg).floor();
    final col = ((lng - gridOriginLng) / gridSizeDeg).floor();

    return '$row-$col';
  }

  static Set<String> getVisibleGridIds(LatLngBounds bounds) {
    final visibleIds = <String>{};

    final swLat = bounds.southwest.latitude;
    final swLng = bounds.southwest.longitude;
    final neLat = bounds.northeast.latitude;
    final neLng = bounds.northeast.longitude;

    final startRow = ((swLat - gridOriginLat) / gridSizeDeg).floor();
    final endRow = ((neLat - gridOriginLat) / gridSizeDeg).floor();
    final startCol = ((swLng - gridOriginLng) / gridSizeDeg).floor();
    final endCol = ((neLng - gridOriginLng) / gridSizeDeg).floor();

    for (var row = startRow; row <= endRow; row++) {
      for (var col = startCol; col <= endCol; col++) {
        visibleIds.add('$row-$col');
      }
    }

    return visibleIds;
  }
}
