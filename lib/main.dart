import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Map<MarkerId, Marker> dataMarker = <MarkerId, Marker>{};
  List<Marker> dataMarker = <Marker>[];
  GoogleMapController _mapcontroller;
  Completer<GoogleMapController> _controller = Completer();
  String test;
  var markers = [];
  @override
  void initState() {
    super.initState();
    getLocations();
    setState(() {
      // dataMarker.add(
      //   Marker(
      //       markerId: MarkerId('Test'),
      //       position: LatLng(-8.66123, 115.1954642),
      //       infoWindow: InfoWindow(title: "Mitra IT")),
      // );
      // dataMarker.add(Marker(
      //     markerId: MarkerId('Test1'),
      //     position: LatLng(-8.6673892, 115.1960675),
      //     infoWindow: InfoWindow(title: "Rumah")));
    });
  }

  getLocations() {
    markers = [];
    Firestore.instance.collection('markers').getDocuments().then((value) {
      if (value.documents.isNotEmpty) {
        setState(() {
          test = value.documents.length.toString();
        });
        print(value.documents);
        for (var i = 0; i < value.documents.length; i++) {
          markers.add(value.documents[i].data);
          initMarker(value.documents[i].data, value.documents[i].documentID);
        }
      }
    });
  }

  void initMarker(data, dataid) {
    // if (data == null) {
    //   dataMarker[dads] = null;
    // }
    setState(() {
      dataMarker.add(Marker(
          markerId: MarkerId(dataid),
          position:
              LatLng(data['coordinate'].latitude, data['coordinate'].longitude),
          infoWindow: InfoWindow(title: data['location'])));
    });

    // var markerIdVal = dataid;
    // final MarkerId markerId = MarkerId(markerIdVal);
    // debugPrint(data);
    // // creating a new MARKER
    // final Marker marker = Marker(
    //   markerId: markerId,
    //   position:
    //       LatLng(data['coordinate'].latitude, data['coordinate'].longtitude),
    //   infoWindow: InfoWindow(title: data['location']),
    // );

    // setState(() {
    //   // adding a new marker to map

    //   dataMarker[markerId] = marker;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map App'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          setState(() {
            _mapcontroller = controller;
          });
        },
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(-8.650000, 115.216667),
          zoom: 14.0,
        ),
        markers: Set<Marker>.of(dataMarker),
      ),
    );
  }
}
