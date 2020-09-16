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
  String _name;
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  var markers = [];

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
              stream: Firestore.instance.collection('markers').snapshots(),
              builder: (context, snapshot) {
                dataMarker.clear();
                if (!snapshot.hasData) {
                  return Text("Loading..");
                }
                if (snapshot.data.documents.isNotEmpty) {
                  for (var i = 0; i < snapshot.data.documents.length; i++) {
                    markers.add(snapshot.data.documents[i].data);
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
                            (snapshot.data.documents[i].data['coordinate']
                                .longitude)),
                        infoWindow: InfoWindow(
                          title: (snapshot.data.documents[i].data['location']),
                        )));
                  }
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
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(-8.650000, 115.216667),
                    zoom: 14.0,
                  ),
                  markers: Set<Marker>.of(dataMarker),
                );
              },
            )
          ],
        ));
  }
}
