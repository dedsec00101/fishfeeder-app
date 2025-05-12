import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double temperature = 0.0, ph = 0.0, ammonia = 0.0;

  final String nodeMcuIp =
      'http://192.168.1.100'; // Replace with your NodeMCU IP

  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('$nodeMcuIp/sensor'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = data['temperature']?.toDouble() ?? 0.0;
          ph = data['ph']?.toDouble() ?? 0.0;
          ammonia = data['ammonia']?.toDouble() ?? 0.0;
        });
        print('Sensor data fetched: $data');
      } else {
        throw Exception('Failed to load sensor data');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch sensor data')),
      );
    }
  }

  Future<void> triggerFeed() async {
    try {
      final response = await http.get(Uri.parse('$nodeMcuIp/feed'));
      if (response.statusCode == 200) {
        print('Feed triggered');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed triggered successfully')),
        );
      } else {
        throw Exception('Failed to trigger feed');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to trigger feed')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  Widget buildGauge({
    required String title,
    required double value,
    required double min,
    required double max,
    required List<GaugeRange> ranges,
    required String unitLabel,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.blueGrey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.25,
                    thicknessUnit: GaugeSizeUnit.factor,
                    cornerStyle: CornerStyle.bothFlat,
                  ),
                  ranges: ranges,
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: value,
                      needleColor: Colors.black,
                      knobStyle: const KnobStyle(color: Colors.black),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.6,
                      widget: Column(
                        children: [
                          Text(
                            unitLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            value.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fish Feeder Dashboard'),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: fetchSensorData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            buildGauge(
              title: "Temperature (°C)",
              value: temperature,
              min: 0,
              max: 40,
              unitLabel: "TEMP",
              ranges: [
                GaugeRange(startValue: 0, endValue: 20, color: Colors.red),
                GaugeRange(startValue: 20, endValue: 28, color: Colors.green),
                GaugeRange(startValue: 28, endValue: 40, color: Colors.yellow),
              ],
            ),
            buildGauge(
              title: "pH Level",
              value: ph,
              min: 0,
              max: 14,
              unitLabel: "pH",
              ranges: [
                GaugeRange(startValue: 0, endValue: 6.5, color: Colors.red),
                GaugeRange(startValue: 6.5, endValue: 8.0, color: Colors.green),
                GaugeRange(startValue: 8.0, endValue: 14, color: Colors.yellow),
              ],
            ),
            buildGauge(
              title: "Ammonia (ppm)",
              value: ammonia,
              min: 0,
              max: 1,
              unitLabel: "NH₃",
              ranges: [
                GaugeRange(startValue: 0, endValue: 0.02, color: Colors.green),
                GaugeRange(
                  startValue: 0.02,
                  endValue: 0.05,
                  color: Colors.yellow,
                ),
                GaugeRange(startValue: 0.05, endValue: 1, color: Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: triggerFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Feed Now"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Set Feed Schedule"),
            ),
          ],
        ),
      ),
    );
  }
}
