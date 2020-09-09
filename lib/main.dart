import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Gmap(),
    );
  }
}

class Gmap extends StatefulWidget {
  @override
  _GmapState createState() => _GmapState();
}

class _GmapState extends State<Gmap> {
  List<Marker> dataMarker = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      dataMarker.add(
        Marker(
            markerId: MarkerId('Test'),
            position: LatLng(-8.66123, 115.1954642),
            infoWindow: InfoWindow(title: "Mitra IT")),
      );
      dataMarker.add(Marker(
          markerId: MarkerId('Test1'),
          position: LatLng(-8.6673892, 115.1960675),
          infoWindow: InfoWindow(title: "Rumah")));
    });
  }

  GoogleMapController _mapcontroller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map App'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            _mapcontroller = controller;
          });
        },
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(-8.650000, 115.216667),
          zoom: 14.0,
        ),
        markers: Set.from(dataMarker),
      ),
    );
  }
}
