import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Saves a list of feeding times to the database under 'feeding_schedule/feed_times'
  Future<void> saveFeedingTimes(List<String> times) async {
    try {
      await _dbRef.child('feeding_schedule/feed_times').set(times);
    } catch (e) {
      // Handle or log error as needed
      print('Error saving feeding times: $e');
    }
  }

  /// Retrieves the list of feeding times from the database
  Future<List<String>> getFeedingTimes() async {
    try {
      final snapshot = await _dbRef.child('feeding_schedule/feed_times').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is List<dynamic>) {
          return data.map((e) => e.toString()).toList();
        } else {
          // Handle case where data isn't a List
          print('Unexpected data format for feeding times');
        }
      }
    } catch (e) {
      print('Error fetching feeding times: $e');
    }
    return [];
  }

  /// Triggers the feed now command by setting 'feed_now' to true
  Future<void> triggerFeedNow() async {
    try {
      await _dbRef.child('feed_now').set(true);
    } catch (e) {
      print('Error triggering feed now: $e');
    }
  }

  /// Resets the 'feed_now' flag to false
  Future<void> resetFeedNow() async {
    try {
      await _dbRef.child('feed_now').set(false);
    } catch (e) {
      print('Error resetting feed now: $e');
    }
  }

  /// Listens for changes to the 'feed_now' flag
  Stream<bool> feedNowStream() {
    return _dbRef.child('feed_now').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      // Default to false if value is null or unexpected
      return false;
    });
  }
}
