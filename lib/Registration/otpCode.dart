import 'package:electrum_assignment/Dashboard/userList.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as p;

class OTPCode extends StatefulWidget {
  final String expectedOTP;

  const OTPCode({Key? key, required this.expectedOTP}) : super(key: key);

  @override
  _OTPCodeState createState() => _OTPCodeState();
}

class _OTPCodeState extends State<OTPCode> {
  TextEditingController FirstOTPController = TextEditingController();
  TextEditingController SecondOTPController = TextEditingController();
  TextEditingController ThirdOTPController = TextEditingController();
  TextEditingController ForthOTPController = TextEditingController();
  late String userName;

 Future<Map<String, dynamic>> getUserData(String username) async {
    // Open the database
    String path = p.join(await getDatabasesPath(), 'registration_database.db');
    Database database = await openDatabase(path);

    // Retrieve user data from the database based on the provided email
    List<Map<String, dynamic>> results = await database.query(
      'registration',
      where: 'username = ?',
      whereArgs: [username],
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

@override
  void initState() {
    // TODO: implement initState
   getuserName();
    super.initState();
  }

  getuserName()async{
 SharedPreferences prefs = await SharedPreferences.getInstance();
     userName = prefs.getString('userName') ?? '';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Container(
              height: MediaQuery.of(context).size.height * .75,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5), color: Colors.white),
              child: Column(children: [
                Text("OTP", style: TextStyle(color: Colors.blue, fontSize: 40)),
                const SizedBox(
                  height: 40,
                ),
                Text(
                  "Please check your notifcation and Enter the OTP",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue),
                ),
                const SizedBox(
                  height: 70,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _textFieldOTP(
                        controller: FirstOTPController,
                        first: true,
                        last: false),
                    const SizedBox(width: 10),
                    _textFieldOTP(
                        controller: SecondOTPController,
                        first: false,
                        last: false),
                    const SizedBox(width: 10),
                    _textFieldOTP(
                        controller: ThirdOTPController,
                        first: false,
                        last: false),
                    const SizedBox(width: 10),
                    _textFieldOTP(
                        controller: ForthOTPController,
                        first: false,
                        last: true)
                  ],
                ),
                const SizedBox(
                  height: 70,
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        var otp = (FirstOTPController.text) +
                            (SecondOTPController.text) +
                            (ThirdOTPController.text) +
                            (ForthOTPController.text);
                        widget.expectedOTP == otp
                            ? Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserListPage(username: userName),
                                ),
                              )
                            : ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('OTP not match')),
                              );
                        ;
                        // otpController.Otpcheck(
                        //     context, args.email, otp);
                      },
                      child: Text(
                        "Continue",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                    ))
              ]),
            )
          ],
        ),
      )),
    ));
  }

  Widget _textFieldOTP(
      {required TextEditingController controller, bool? first, last}) {
    return Container(
      height: 65,
      child: AspectRatio(
        aspectRatio: 0.9,
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: (value) {
            if (value.length == 1 && last == false) {
              FocusScope.of(context).nextFocus();
            }
            if (value.isEmpty && first == false) {
              FocusScope.of(context).previousFocus();
            }
          },
          showCursor: false,
          readOnly: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counter: Offstage(),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2, color: Colors.black),
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2, color: Colors.blue),
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
