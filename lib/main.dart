import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofence/geofence.dart';
// import 'package:geofence/geofence.dart';
// import 'package:geofence/geofence_event.dart';
// import 'package:geofence/geofence_region.dart';
// import 'package:geofence/location.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';

import 'toast.dart';

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

  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  Map<PolylineId, Polyline> emptypolylines = {};
  String googleAPiKey = "AIzaSyAK32XxHYjxr9p9wv_K_wE2-2Xgd563bE4";
  PolylineResult result;

  Map<CircleId, Circle> circles = {};
  var currentlocation;
  bool maptoggle = false;
  bool buttonhide = false;
  Location location;
  double distance;
  @override
  void initState() {
    super.initState();

    //flutter_geofence
    // initPlatformState();
    // Geofence.requestPermissions();
    // Geolocation location = Geolocation(
    //     latitude: -8.6678318, longitude: 115.1965159, radius: 25, id: "Rumah");
    // Geofence.addGeolocation(location, GeolocationEvent.entry).then((onValue) {
    //   print("great success");
    // }).catchError((onError) {
    //   print("great failure");
    // });

    getCurrentLocation();
    location = new Location();
    location.onLocationChanged().listen((LocationData cLoc) {
      if (circles[CircleId("rumah")] != null) {
        setState(() {
          distance = distanceBetween(
              cLoc.latitude,
              cLoc.longitude,
              circles[CircleId("rumah")].center.latitude,
              circles[CircleId("rumah")].center.longitude);
        });
        if (distance > circles[CircleId("rumah")].radius) {
          showToast('Keluar', Colors.red);
        } else {
          showToast('Masuk', Colors.green);
        }
      }
    });
  }

  getCurrentLocation() async {
    await GeolocatorPlatform.instance.getCurrentPosition().then((value) {
      setState(() {
        currentlocation = value;
        maptoggle = true;
        setCircles();
      });
    });
  }

  // Future<void> initPlatformState() async {
  //   // If the widget was removed from the tree while the asynchronous platform
  //   // message was in flight, we want to discard the reply rather than calling
  //   // setState to update our non-existent appearance.

  //   Geofence.initialize();
  //   Geofence.startListening(GeolocationEvent.entry, (entry) {
  //     showToast('Masuk', Colors.green);
  //   });

  //   Geofence.startListening(GeolocationEvent.exit, (entry) {
  //     showToast('Keluar', Colors.red);
  //   });
  // }

  //geofence
  // static void callback(Location l, GeofenceEvent e) async {
  //   print('Location $l Event: $e');
  //   final SendPort send =
  //       IsolateNameServer.lookupPortByName('geofencing_send_port');
  //   send?.send(e.toString());
  // }

  // Future<void> initGeofence() async {
  //   try {
  //     bool isInitialized = await Geofence.initialize();
  //     print("Geofence plugin initialzed : $isInitialized");
  //     var region = GeofenceRegion(Location(-8.6678318, 115.1965159), 24);
  //     bool geofenceAdded = await Geofence.registerGeofence(region, callback);
  //     //await Geofence.unRegisterGeofence();
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  getRoute() async {
    // ------- Flutter map polyline--------------
    final value = await Firestore.instance
        .collection("markers")
        .orderBy('date', descending: false)
        .getDocuments();
    if (value.documents.isNotEmpty) {
      for (var i = 0; i < value.documents.length; i++) {
        if (i + 1 != value.documents.length &&
            i + 1 <= value.documents.length) {
          PointLatLng a = PointLatLng(
              value.documents[i].data['coordinate'].latitude,
              value.documents[i].data['coordinate'].longitude);
          PointLatLng b = PointLatLng(
              value.documents[i + 1].data['coordinate'].latitude,
              value.documents[i + 1].data['coordinate'].longitude);
          String c = value.documents[i].data['location'];
          setRoute(a, b, c);
        }
      }
    }
  }

  setRoute(origin, destination, location) async {
    List<LatLng> routeCoords = [];
    result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey, origin, destination,
        travelMode: TravelMode.driving);
    print(result);
    if (result.points.isNotEmpty) {
      // jika result tidak kosong akan muncul draw route
      result.points.forEach((PointLatLng pointcoor) {
        routeCoords.add(LatLng(pointcoor.latitude, pointcoor.longitude));
      });
      PolylineId id = PolylineId(location);
      Polyline polyline =
          Polyline(polylineId: id, color: Colors.red, points: routeCoords);
      setState(() {
        polylines[id] = polyline;
      });
    }
  }

  void setCircles() {
    var circle = Circle(
        circleId: CircleId("rumah"),
        center: LatLng(-8.6678318, 115.1965159),
        radius: 20,
        fillColor: Color.fromRGBO(245, 243, 243, 100),
        strokeWidth: 2);
    circles[CircleId("rumah")] = circle;
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
        title: Text("Map App"),
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
              Timestamp time = new Timestamp(2019, 3);
              if (!snapshot.hasData && !maptoggle) {
                return Text("Loading..");
              }
              if (snapshot.data.documents.isNotEmpty) {
                for (var i = 0; i < snapshot.data.documents.length; i++) {
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
              }

              return GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  setState(() {
                    _mapcontroller = controller;
                  });
                },
                onTap: (coordinate) {
                  popup(context, coordinate.latitude, coordinate.longitude);
                },
                polylines: polyactive
                    ? Set<Polyline>.of(polylines.values)
                    : Set<Polyline>.of(emptypolylines.values),
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: currentlocation == null
                      ? LatLng(0.0, 0.0)
                      : LatLng(
                          currentlocation.latitude, currentlocation.longitude),
                  zoom: 14.0,
                ),
                markers: Set<Marker>.of(dataMarker),
                circles: Set<Circle>.of(circles.values),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
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
                    backgroundColor: polyactive ? Colors.red : Colors.blue,
                    child: polyactive
                        ? Icon(Icons.clear)
                        : Icon(Icons.trending_up),
                    onPressed: () {
                      if (!polyactive) {
                        setState(() {
                          polylines.clear();
                          polyactive = true;
                        });
                        getRoute();
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
