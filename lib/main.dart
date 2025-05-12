import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  await _initializeFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> _initializeFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for iOS
  await messaging.requestPermission();

  // Get the device token (for sending notifications)
  String? token = await messaging.getToken();
  print("Firebase Messaging Token: $token");

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message while in foreground: ${message.messageId}');
    // Handle the message and show notification if needed
    // You can use flutter_local_notifications here if needed
  });

  // Handle background and terminated state messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!: ${message.messageId}');
    // Navigate or update UI based on message
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fish Feeder App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(), // Replace with your main widget
    );
  }
}

// Your home screen widget here
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // You can listen to Firebase database changes here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fish Feeder')),
      body: Center(child: Text('Your app content here')),
    );
  }
}
