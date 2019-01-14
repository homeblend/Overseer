import 'dart:async';

import 'package:app/services/device_readings_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  Dashboard({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DeviceReadingsRepository _deviceReadingRepo =
      DeviceReadingsRepository();
  Stream<QuerySnapshot> _deviceReadingsStream;
  num _gasLevelAverage = 0;
  /// The time the device is allowed to be inactive
  final _inactivityDuration = const Duration(seconds: 5);
  /// When this timer hits 0, the device will be considered offline
  /// until a new reading is received
  Timer _offlineTimer;


  _DashboardState() {
    _deviceReadingsStream = _deviceReadingRepo.getChangestream();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    _attachListener();
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
          padding: EdgeInsets.all(22.0),
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: _buildStatusRows(theme)),
    );
  }

  Widget _buildStatusRows(TextTheme theme) {
    return Row(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.sync),
              tooltip: "Refresh data",
              onPressed: () {
                // could add some UI logic here to indicate progress
                _refreshReadingsAverage();
              },
            ),
          ],
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Gas Levels', style: theme.title),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildStatusIcon(),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  void _attachListener() {
    _deviceReadingsStream.listen((QuerySnapshot event) {
      // this is ugly but sometimes it be like that
      var readings = event.documentChanges
          .map((docChange) => docChange.document.data)
          .map((Map<String, dynamic> dataMap) => dataMap["value"] as num);
      _calculateAverage(readings);
      // start counting down until next reading,
      // if the timer hits 0 and we haven't received one,
      // the device will be considered offline
      _startOfflineTimer();
    });
  }

  void _refreshReadingsAverage() async {
    var documents = await _deviceReadingRepo.getDocuments();
    var readings = documents
        .map((docSnapshot) => docSnapshot.data)
        .map((Map<String, dynamic> dataMap) => dataMap["value"] as num);
    _calculateAverage(readings);
  }

  void _calculateAverage(Iterable<num> readings) {
    setState(() {
      _gasLevelAverage = readings.reduce((value1, value2) => value1 + value2) /
          readings.length;
    });
  }

  /// Start counting down from the allotted inactivity time,
  /// if no readings are received after this duration, the device
  /// will be considered offline.
  void _startOfflineTimer() {
    // if the timer isn't null, then cancel it
    if (_offlineTimer != null) _offlineTimer.cancel();
    _offlineTimer = Timer(_inactivityDuration, () {
      setState(() {
        _gasLevelAverage = 0;
      });
    });
  }

  // TODO: make this user config driven
  Widget _buildStatusIcon() {
    Widget offlineIcon = Icon(
      Icons.cloud_off,
      color: Colors.grey,
    );
    Widget okayIcon = Icon(
      Icons.done,
      color: Colors.green,
    );
    Widget warningIcon = Icon(
      Icons.warning,
      color: Colors.amber,
    );
    Widget dangerIcon = Icon(
      Icons.priority_high,
      color: Colors.red,
    );
    // these numbers are arbitrary at the moment
    if (_gasLevelAverage == 0) {
      return offlineIcon;
    } else if (_gasLevelAverage < 400) {
      return okayIcon;
    } else if (_gasLevelAverage < 700) {
      return warningIcon;
    } else {
      return dangerIcon;
    }
  }
}
