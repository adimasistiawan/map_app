import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  String _name;
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  List<Marker> dataMarker = <Marker>[];
  List<PolylineWayPoint> point = [];
  GoogleMapController _mapcontroller;
  Completer<GoogleMapController> _controller = Completer();
  bool polyactive = false;
  List<LatLng> ltlg = List();
  List<LatLng> routeCoords = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  String googleAPiKey = "AIzaSyDtAHkHxL4Sv5GvJranFwSJwrz33aRoTpc";
  GoogleMapPolyline googleMapPolyline =
      new GoogleMapPolyline(apiKey: "AIzaSyDrJN7HOsyZLw6_PucyKTx7LTaMKjEenvg");
  PolylineResult result;
  List<LatLng> result2;
  // LatLng t1 = LatLng(-8.640705240362454, 115.20013488829136);
  // LatLng t2 = LatLng(-8.6673892, 115.1960675);
  // LatLng t3 = LatLng(-8.66123, 115.1954642);
  // LatLng t4 = LatLng(-8.65706064452849, 115.2157885953784);

  @override
  void initState() {
    super.initState();
    drawRoute();
    setState(() {});
  }

  drawRoute() async {
    // ------- Flutter map polyline--------------
    result = await polylinePoints.getRouteBetweenCoordinates(googleAPiKey,
        PointLatLng(-8.66123, 115.1954642), PointLatLng(-8.65706, 115.2157885),
        travelMode: TravelMode.driving);
    print(result);
    if (result.points.isNotEmpty) {
      // jika result tidak kosong akan muncul draw route
      result.points.forEach((PointLatLng point) {
        routeCoords.add(LatLng(point.latitude, point.longitude));
      });
      PolylineId id = PolylineId("poly");
      Polyline polyline =
          Polyline(polylineId: id, color: Colors.red, points: routeCoords);
      polylines[id] = polyline;
    } else {
      // jika result kosong akan membuat polyline biasa
      PolylineId id = PolylineId("poly");
      Polyline polyline = Polyline(polylineId: id, color: Colors.red, points: [
        LatLng(-8.66123, 115.1954642),
        LatLng(-8.65706064452849, 115.2157885953784)
      ]);
      polylines[id] = polyline;
    }

    // ------- Google map polyline-----------
    // result2 = await googleMapPolyline.getCoordinatesWithLocation(
    //     origin: LatLng(-8.65706064452849, 115.2157885953784),
    //     destination: LatLng(-8.66123, 115.1954642),
    //     mode: RouteMode.driving);
    // print(result2);
    // PolylineId id = PolylineId("poly");
    // Polyline polyline =
    //     Polyline(polylineId: id, color: Colors.red, points: result2);
    // polylines[id] = polyline;
  }

  void popup(BuildContext context, latitude, longitude) {
    final textcontroller = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Location'),
            content: Container(
              height: 120,
              child: Form(
                  key: formkey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: textcontroller,
                        decoration: InputDecoration(labelText: 'Location name'),
                        onSaved: (input) => _name = input,
                        validator: (value) {
                          if (value.isEmpty) {
                            return "required";
                          }
                        },
                      ),
                    ],
                  )),
            ),
            actions: [
              FlatButton(
                child: Text('Add'),
                onPressed: () {
                  SaveLocation(latitude, longitude);
                  textcontroller.clear();
                },
              ),
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  textcontroller.clear();
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void edit(BuildContext context, name, id) {
    final editcontroller = TextEditingController(text: name);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Location'),
            content: Container(
              height: 120,
              child: Form(
                  key: formkey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: editcontroller,
                        decoration: InputDecoration(labelText: 'Location name'),
                        onSaved: (input) => _name = input,
                        validator: (value) {
                          if (value.isEmpty) {
                            return "required";
                          }
                        },
                      ),
                    ],
                  )),
            ),
            actions: [
              FlatButton(
                child: Text('Save'),
                onPressed: () {
                  updateLocation(id);
                  editcontroller.clear();

                  _mapcontroller.hideMarkerInfoWindow(MarkerId(id));
                },
              ),
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  editcontroller.clear();
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Future<void> SaveLocation(lat, lng) async {
    final formstate = formkey.currentState;
    if (formstate.validate()) {
      Navigator.of(context).pop();
      formstate.save();
      await Firestore.instance.collection('markers').add({
        'location': _name,
        'coordinate': new GeoPoint(lat, lng),
        'date': FieldValue.serverTimestamp()
      });
    }
  }

  Future<void> updateLocation(id) async {
    final formstate = formkey.currentState;
    if (formstate.validate()) {
      Navigator.of(context).pop();
      formstate.save();
      await Firestore.instance.collection('markers').document(id).updateData({
        'location': _name,
      });
      _mapcontroller.showMarkerInfoWindow(MarkerId(id));
    }
  }

  Future<void> deleteLocation(id) async {
    await Firestore.instance.collection("markers").document(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map App'),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: Firestore.instance
                .collection('markers')
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              dataMarker.clear();
              ltlg.clear();
              Timestamp time = new Timestamp(2019, 3);
              if (!snapshot.hasData) {
                return Text("Loading..");
              }
              if (snapshot.data.documents.isNotEmpty) {
                for (var i = 0; i < snapshot.data.documents.length; i++) {
                  // ltlg.add(LatLng(
                  //     snapshot.data.documents[i].data['coordinate'].latitude,
                  //     snapshot.data.documents[i].data['coordinate'].longitude));
                  // point.add(PolylineWayPoint(
                  //     location: (snapshot
                  //             .data.documents[i].data['coordinate'].latitude
                  //             .toString() +
                  //         ", " +
                  //         snapshot
                  //             .data.documents[i].data['coordinate'].longitude
                  //             .toString())));

                  if (snapshot.data.documents[i].data['date'] != null) {
                    time = snapshot.data.documents[i].data['date'];
                  }

                  dataMarker.add(Marker(
                      markerId:
                          MarkerId((snapshot.data.documents[i].documentID)),
                      onTap: () {
                        showModalBottomSheet(
                            barrierColor: Colors.white.withOpacity(0),
                            context: context,
                            builder: (context) {
                              return Container(
                                height: 120,
                                child: Container(
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text("Edit"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          edit(
                                              context,
                                              snapshot.data.documents[i]
                                                  .data['location'],
                                              (snapshot.data.documents[i]
                                                  .documentID));
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.delete),
                                        title: Text("Delete"),
                                        onTap: () {
                                          deleteLocation(snapshot
                                              .data.documents[i].documentID);
                                          Navigator.pop(context);
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              );
                            });
                      },
                      position: LatLng(
                          (snapshot
                              .data.documents[i].data['coordinate'].latitude),
                          (snapshot
                              .data.documents[i].data['coordinate'].longitude)),
                      infoWindow: InfoWindow(
                        title: (snapshot.data.documents[i].data['location'] +
                            " (" +
                            DateFormat('yyyy-MM-dd – kk:mm')
                                .format(time.toDate())
                                .toString() +
                            ")"),
                      )));
                }
                // var j = snapshot.data.documents.length - 1;
                // PointLatLng a = PointLatLng(
                //     snapshot.data.documents[0].data['coordinate'].latitude,
                //     snapshot.data.documents[0].data['coordinate'].longitude);
                // PointLatLng b = PointLatLng(
                //     snapshot.data.documents[j].data['coordinate'].latitude,
                //     snapshot.data.documents[j].data['coordinate'].longitude);
              }

              return new GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  setState(() {
                    _mapcontroller = controller;
                  });
                },
                onTap: (coordinate) {
                  popup(context, coordinate.latitude, coordinate.longitude);
                },
                polylines: Set<Polyline>.of(polylines.values),
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(-8.650000, 115.216667),
                  zoom: 14.0,
                ),
                markers: Set<Marker>.of(dataMarker),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Container(
                  height: 70.0,
                  width: 70.0,
                  child: FloatingActionButton(
                    child: Icon(Icons.trending_up),
                    onPressed: () {
                      if (!polyactive) {
                        setState(() {
                          polyactive = true;
                        });
                      } else {
                        setState(() {
                          polyactive = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        )
      ]),
    );
  }
}
