import 'dart:async';

import 'package:overseer/services/device_readings_repo.dart';
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
  final _inactivityDuration = const Duration(seconds: 60);

  DateTime mostRecentReadingDate = DateTime.now();
  num mostRecentReading;

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
        child: Column(
          children: <Widget>[
            _buildStatusRows(theme),
            Row(
              children: <Widget>[
                Text(
                  mostRecentReadingDate.toLocal().toString(),
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  ":           " + mostRecentReading.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            )
          ],
        ),
      ),
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
      _refreshReadingsAverage();
    });
  }

  void _refreshReadingsAverage() async {
    var documents = await _deviceReadingRepo.getDocuments();
    setState(() {
      // capture most recent reading
      var readingData = documents.first.data;
      mostRecentReadingDate = readingData["timestamp"] as DateTime;
      if (readingData["reading"] is num) {
        mostRecentReading = readingData["reading"] as num;
        var readings = documents
            .map((docSnapshot) => docSnapshot.data)
            .map((Map<String, dynamic> dataMap) => dataMap["reading"] as num);
        _calculateAverage(readings);
        _startOfflineTimer();
      }
    });
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

  // TODO: make this config driven
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
