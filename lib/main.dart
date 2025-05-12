import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:syncfusion_flutter_gauges/gauges.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzData.initializeTimeZones(); // Initialize timezone

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DateTime? _nextFeedingTime;

  // Mock sensor values
  double temperature = 26.5;
  double pH = 7.2;
  double ammonia = 0.3;

  @override
  void initState() {
    super.initState();
    _loadNextFeedingTime();
  }

  Future<void> _loadNextFeedingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList('feeding_times') ?? [];
    final now = DateTime.now();

    final times = storedList.map((t) => DateTime.parse(t)).toList();
    times.sort();

    final next =
        times.isNotEmpty
            ? times.firstWhere(
              (time) => time.isAfter(now),
              orElse: () => times.first,
            )
            : DateTime.now();

    setState(() {
      _nextFeedingTime = next;
    });

    _scheduleNotification(next);
  }

  Future<void> _scheduleNotification(DateTime nextFeedingTime) async {
    const androidDetails = AndroidNotificationDetails(
      'feeding_channel',
      'Feeding Time',
      channelDescription: 'Notifications for feeding times',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final tz.TZDateTime nextFeedingTZ = tz.TZDateTime.from(
      nextFeedingTime,
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Feeding Time',
      'It\'s time to feed your fish!',
      nextFeedingTZ,
      notificationDetails,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  Widget buildGauge(
    String label,
    double value,
    double min,
    double max,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 150,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: min,
                maximum: max,
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: min,
                    endValue: (min + max) / 3,
                    color: Colors.red,
                  ),
                  GaugeRange(
                    startValue: (min + max) / 3,
                    endValue: (2 * (min + max) / 3),
                    color: Colors.orange,
                  ),
                  GaugeRange(
                    startValue: (2 * (min + max) / 3),
                    endValue: max,
                    color: Colors.green,
                  ),
                ],
                pointers: <GaugePointer>[NeedlePointer(value: value)],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(
                      value.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 14),
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fish Feeder',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: Scaffold(
        appBar: AppBar(title: const Text('Fish Feeder Dashboard')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Feeding Time:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _nextFeedingTime != null
                    ? DateFormat(
                      'MMM d, yyyy – h:mm a',
                    ).format(_nextFeedingTime!)
                    : 'No upcoming feeding time scheduled.',
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('Reload Feeding Times'),
                onPressed: _loadNextFeedingTime,
              ),
              const SizedBox(height: 40),
              const Divider(thickness: 1),
              const Text(
                'Water Quality Sensors',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildGauge('Temperature (°C)', temperature, 20, 35, Colors.blue),
              buildGauge('pH Level', pH, 5, 9, Colors.green),
              buildGauge('Ammonia (ppm)', ammonia, 0, 5, Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
