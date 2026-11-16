import 'dart:convert';

// Every tile URL remains local. Never use an online tile server as fallback.
String navarraMapStyle(String path) => jsonEncode({
    'version': 8,
    'name': 'Artemis Navarra local',
    'sources': {
      'navarra': {
        'type': 'vector',
        'url': 'mbtiles://$path',
        'attribution': '© OpenStreetMap contributors (ODbL) / Geofabrik',
      },
    },
    'layers': [
      {'id':'base','type':'background','paint':{'background-color':'#e8eee9'}},
      {'id':'land','type':'fill','source':'navarra','source-layer':'land','paint':{'fill-color':'#dce6d6'}},
      {'id':'water','type':'fill','source':'navarra','source-layer':'water_polygons','paint':{'fill-color':'#a7c8dc'}},
      {'id':'rivers','type':'line','source':'navarra','source-layer':'water_lines','paint':{'line-color':'#83b6cf','line-width':1.5}},
      {'id':'buildings','type':'fill','source':'navarra','source-layer':'buildings','minzoom':13,'paint':{'fill-color':'#d2d8d6'}},
      {'id':'streets-base','type':'line','source':'navarra','source-layer':'streets','paint':{'line-color':'#ced4d4','line-width':3}},
      {'id':'streets-top','type':'line','source':'navarra','source-layer':'streets','paint':{'line-color':'#ffffff','line-width':1.7}},
    ],
  });

