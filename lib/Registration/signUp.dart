import 'package:electrum_assignment/Registration/loginScree..dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    getNotification();

    super.initState();
  }

  getNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    // Initialize the plugin

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    String? payloadScreen = notificationAppLaunchDetails?.payload;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('userEmail') ?? '';
    payloadScreen == 'login' ? navigateToLoginScreen(email) : null;
  }

  void navigateToLoginScreen(String? email) {
    Navigator.pushReplacement(
      this.context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(preFilledEmail: email),
      ),
    );
  }

  Future<void> showNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Change this to a unique channel ID
      'Your Channel Name', // Change this to a unique channel name
      'Your Channel Description', // Change this to a unique channel description
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Change this to a unique notification ID
      'Registration Successful', // Notification title
      'To login, click on the notification', // Notification body
      platformChannelSpecifics,
      payload: 'login', // Payload for handling notification click event
    );
  }

  Future<void> _saveUserInformation() async {
    final database = openDatabase(
      // Specify the database path and name
      join(await getDatabasesPath(), 'registration_database.db'),
      onCreate: (db, version) {
        // Create the registration table
        return db.execute(
          'CREATE TABLE registration(id INTEGER PRIMARY KEY, firstName TEXT, lastName TEXT, userName TEXT, email TEXT, password TEXT)',
        );
      },
      version: 1,
    );

    final db = await database;

    await db.insert(
      'registration',
      {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'userName': _userNameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void _registerUser(BuildContext context, String email, String userName) {
    if (_formKey.currentState!.validate()) {
      _saveUserInformation().then((_) async {
        // Registration successful, close the app
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userEmail', email);
        prefs.setString('userName', userName);
        showNotification();

        SystemNavigator.pop();
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registration')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _userNameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email';
                  }
                  // You can add additional email validation here if needed
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
                obscureText: true,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: () {
                  _registerUser(context, _emailController.text, _userNameController.text);
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
