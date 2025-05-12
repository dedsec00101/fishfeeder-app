import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<DateTime> _feedingTimes = [];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadFeedingTimes();
  }

  Future<void> _loadFeedingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTimes = prefs.getStringList('feeding_times') ?? [];
    setState(() {
      _feedingTimes =
          storedTimes.map((s) => DateTime.parse(s)).toList()..sort();
    });
  }

  Future<void> _saveFeedingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStrings = _feedingTimes.map((t) => t.toIso8601String()).toList();
    await prefs.setStringList('feeding_times', timeStrings);
  }

  Future<void> _scheduleNotification(DateTime scheduledTime) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      scheduledTime.hashCode,
      'Fish Feeding Time',
      'It\'s time to feed your fish!',
      tzTime,
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
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _addFeedingTime() async {
    picker.DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      onConfirm: (time) async {
        final now = DateTime.now();
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        setState(() {
          _feedingTimes.add(scheduledTime);
          _feedingTimes.sort();
        });
        await _saveFeedingTimes();
        await _scheduleNotification(scheduledTime);
      },
    );
  }

  Future<void> _removeFeedingTime(int index) async {
    final removed = _feedingTimes.removeAt(index);
    setState(() {});
    await _saveFeedingTimes();
    await flutterLocalNotificationsPlugin.cancel(removed.hashCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feeding Schedule')),
      body: ListView.builder(
        itemCount: _feedingTimes.length,
        itemBuilder: (context, index) {
          final time = _feedingTimes[index];
          return ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(DateFormat('h:mm a').format(time)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFeedingTime(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFeedingTime,
        child: const Icon(Icons.add),
      ),
    );
  }
}
