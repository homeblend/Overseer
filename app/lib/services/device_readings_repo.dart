import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceReadingsRepository {
  static final DeviceReadingsRepository _repo = DeviceReadingsRepository._internal();

  factory DeviceReadingsRepository() {
    return _repo;
  }

  CollectionReference _reference;
  // This limit needs to depend on the update rate
  // Since the update rate for this gas sensors is set to every 10 seconds,
  // we're just set this to be the last 60 readings, which is roughly equivalent
  // to the last 10 minutes
  final num limit = 60;

  DeviceReadingsRepository._internal() {
    _reference = Firestore.instance.collection('readings');
  }

  Stream<QuerySnapshot> getChangestream() {
    return _reference.limit(limit).orderBy("timestamp", descending: true).snapshots();
  }

  Future<List<DocumentSnapshot>> getDocuments() async {
    var query = await _reference.limit(limit).orderBy("timestamp", descending: true).getDocuments();
    return query.documents;
  }


}