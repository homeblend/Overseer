import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceReadingsRepository {
  static final DeviceReadingsRepository _repo = DeviceReadingsRepository._internal();

  factory DeviceReadingsRepository() {
    return _repo;
  }

  CollectionReference _reference;
  // This limit needs to depend on the update rate
  // Our gas-sensor's update rate is every 15 seconds,
  // so we're using the last 40 readings, which is roughly equivalent
  // to the last 10 minutes
  final num limit = 40;

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
