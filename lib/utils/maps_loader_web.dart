import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadGoogleMaps() async {
  final completer = Completer<void>();
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('WARNING: GOOGLE_MAPS_API_KEY not found in .env');
    return;
  }

  // Check if already loaded
  if (html.document.querySelector('#google-maps-script') != null) {
    return;
  }

  final script = html.ScriptElement()
    ..id = 'google-maps-script'
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..async = true
    ..defer = true;

  script.onLoad.listen((_) {
    completer.complete();
  });

  script.onError.listen((_) {
    completer.completeError('Failed to load Google Maps script');
  });

  html.document.head!.append(script);
  
  return completer.future;
}
