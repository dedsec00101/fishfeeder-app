import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz; // Import timezone package
import 'firebase_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<TimeOfDay> scheduledTimes = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseService firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadFeedingTimes();
    _listenFeedTrigger();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadFeedingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTimes = prefs.getStringList('feeding_times') ?? [];
    setState(() {
      scheduledTimes =
          storedTimes.map((timeString) {
            final parts = timeString.split(":");
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }).toList();
    });
  }

  Future<void> _saveFeedingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList =
        scheduledTimes.map((time) => '${time.hour}:${time.minute}').toList();
    await prefs.setStringList('feeding_times', stringList);
    // Save ISO times to Firebase
    final List<String> isoTimes =
        scheduledTimes.map((t) {
          final now = DateTime.now();
          final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
          return dt.toIso8601String();
        }).toList();
    await firebaseService.saveFeedingTimes(isoTimes);
  }

  Future<void> _scheduleNotification(TimeOfDay time, int id) async {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Feeding Time',
      'It\'s time to feed your fish!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'feeding_channel',
          'Feeding Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _addFeedingTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        scheduledTimes.add(pickedTime);
        scheduledTimes.sort(
          (a, b) =>
              a.hour != b.hour
                  ? a.hour.compareTo(b.hour)
                  : a.minute.compareTo(b.minute),
        );
      });
      await _saveFeedingTimes();
      await _scheduleNotification(
        pickedTime,
        scheduledTimes.indexOf(pickedTime),
      );
    }
  }

  void _deleteFeedingTime(int index) async {
    setState(() {
      scheduledTimes.removeAt(index);
    });
    await _saveFeedingTimes();
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateFormat.jm().format(
      DateTime(now.year, now.month, now.day, time.hour, time.minute),
    );
  }

  TimeOfDay? _getNextFeedingTime() {
    final nowDT = DateTime.now();
    final nowTime = TimeOfDay.fromDateTime(nowDT);
    for (final time in scheduledTimes) {
      if (time.hour > nowTime.hour ||
          (time.hour == nowTime.hour && time.minute > nowTime.minute)) {
        return time;
      }
    }
    return scheduledTimes.isNotEmpty ? scheduledTimes.first : null;
  }

  void _listenFeedTrigger() {
    // Listen Firebase trigger for "fish fed"
    firebaseService.feedNowStream().listen((fed) async {
      if (fed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your fish has been fed!')),
          );
        }
        await _clearSchedule();
        await firebaseService.resetFeedNow();
      }
    });
  }

  Future<void> _clearSchedule() async {
    setState(() {
      scheduledTimes.clear();
    });
    await _saveFeedingTimes();
  }

  Future<void> _markFishFed() async {
    await firebaseService.triggerFeedNow();
  }

  @override
  Widget build(BuildContext context) {
    final nextFeeding = _getNextFeedingTime();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding Schedule'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (nextFeeding != null)
              Text(
                'Next Feeding Time: ${_formatTime(nextFeeding)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Feed Time'),
              onPressed: _addFeedingTime,
            ),
            const SizedBox(height: 20),
            const Text(
              'Scheduled Times:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (scheduledTimes.isEmpty)
              const Text('No scheduled times yet.')
            else
              ...scheduledTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                return ListTile(
                  title: Text(_formatTime(time)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFeedingTime(index),
                  ),
                );
              }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _markFishFed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Fish Fed (Confirm)'),
            ),
          ],
        ),
      ),
    );
  }
}
