import 'package:electrum_assignment/Registration/otpCode.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:otp/otp.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LoginScreen extends StatefulWidget {
  final String? preFilledEmail;

  LoginScreen({this.preFilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<Map<String, dynamic>> getUserData(String email) async {
    // Open the database
    String path = join(await getDatabasesPath(), 'registration_database.db');
    Database database = await openDatabase(path);

    // Retrieve user data from the database based on the provided email
    List<Map<String, dynamic>> results = await database.query(
      'registration',
      where: 'email = ?',
      whereArgs: [email],
    );

    // Close the database
    await database.close();

    // Return the user data as a Map
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return {};
    }
  }

  Future<void> login(String email, String password) async {
    // Retrieve user data from the database based on the email
    Map<String, dynamic> userData = await getUserData(email);

    if (userData.isNotEmpty) {
      // Compare the stored password with the entered password

      String storedPassword = userData['password'];
      if (password == storedPassword) {
        String otp = OTP.generateTOTPCodeString(
            'YOUR_SECRET_KEY', DateTime.now().millisecondsSinceEpoch,
            length: 4);

        // Send the OTP as a mobile notification
        sendNotification(otp);

        // Navigate to the OTP screen
        Navigator.push(
          this.context,
          MaterialPageRoute(
            builder: (context) => OTPCode(expectedOTP: otp),
          ),
        );

        // Passwords match, login successful
        // Proceed with further actions or navigation
      } else {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Password not matched')),
        );
        // Passwords don't match, login failed
        // Display an error message or take appropriate action
      }
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('user not found')),
      );
      // User not found, login failed
      // Display an error message or take appropriate action
    }
  }

  void sendNotification(String otp) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      'channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      'OTP', // notification title
      otp, // notification body
      platformChannelSpecifics,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController =
        TextEditingController(text: widget.preFilledEmail);
    TextEditingController userNameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            // Add other login form fields
            ElevatedButton(
              onPressed: () {
                login(emailController.text, passwordController.text);
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
