import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:electrum_assignment/Model/userModel.dart';
import 'package:electrum_assignment/Registration/loginScree..dart';
import 'package:electrum_assignment/network/params.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class UserListPage extends StatefulWidget {
  final String username;

  const UserListPage({super.key, required this.username});
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  ScrollController _scrollController = ScrollController();

  bool isloading = false;
  bool lazyLoading = false;
  UserModel? userList;
  int page = 1;
  Timer? _timer;
  int _usageTime = 0;

  Future getUsers() async {
    try {
      isloading = page == 1 ? true : false;
      lazyLoading = page > 1 ? true : false;

      var response =
          await http.get(Uri.parse('https://reqres.in/api/users?page=$page'));

      if (page == 1) {
        setState(() {
          userList = UserModel.fromJson(json.decode(response.body.toString()));
        });
      } else {
        setState(() {
          Iterable list = json.decode(response.body.toString())["data"];
          List<Data> res = list.map((e) => Data.fromJson(e)).toList();
          userList!.data?.addAll(res);
        });
      }
      if (page <= userList!.page!) {
        page++;
      }
      isloading = false;
      lazyLoading = false;
    } catch (e) {
      isloading = false;
      lazyLoading = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _usageTime++;
      });
      Timer _usageTimer = Timer(Duration(seconds: 300), () {
        showLogoutPrompt();
        handleAutomaticLogout();
        // Code to show the logout prompt and handle automatic logout
      });
    });
  }

  void showLogoutPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the prompt
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text(
              'You have been using the application for 5 minutes. We are logging you out.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the prompt
                logoutUser(); // Logout the user
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void handleAutomaticLogout() {
    showLogoutPrompt();

    // Wait for 30 seconds before automatically logging out
    Timer(Duration(seconds: 30), () {
      logoutUser();
      _timer!.cancel(); // Logout the user
    });
  }

  void logoutUser() {
    Navigator.pushReplacement(
      this.context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(preFilledEmail: ''),
      ),
    );
    // Code to perform the logout process (e.g., clear session, navigate to login screen)
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    getUsers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        getUsers();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _timer!.cancel(); // Cancel the current timer
    _startTimer();
    super.dispose();
  }

  void _logout() {
    Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(preFilledEmail: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('User List'),
          actions: [
            IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) => AddUserBottomSheet(),
                  );
                },
                icon: Icon(Icons.add)),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('Hi, ${widget.username}'),
                accountEmail: null,
              ),
              ListTile(
                title: Text('Usage Time: $_usageTime seconds'),
              ),
              ListTile(
                title: Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
        body: isloading
            ? Center(
                child: SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator()))
            : ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: userList!.data?.length,
                itemBuilder: (BuildContext context, int index) {
                  //  productController.updateIswishlist(productController.productsList!.results[index].id,index);
                  return Card(
                      child: Column(children: [
                    Center(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/loading.gif',
                        image: userList!.data![index].avatar!,
                        height: 105,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      userList!.data![index].firstName.toString() +
                          " " +
                          userList!.data![index].lastName.toString(),
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    PopupMenuButton<String>(
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit User'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete User'),
                          ),
                        ];
                      },
                      onSelected: (value) {
                        if (value == 'edit') {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) =>
                                EditUserBottomSheet(
                                    user: userList!,
                                    index: userList!.data![index].id! - 1),
                          );
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ConfirmationDialog(
                                onConfirm: () {
                                  // Call the delete user API
                                  deleteUser(
                                      context,
                                      userList!.data![index]
                                          .id!); // Replace userId with the actual user ID
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
                  ]));
                },
              ));
  }
}

Future<void> deleteUser(BuildContext context, int userId) async {
  final url = Uri.parse(
      'https://reqres.in/api/users/$userId'); // Replace with the delete user API endpoint URL

  final response = await http.delete(url);

  if (response.statusCode == 204) {
    // User deleted successfully
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User deleted successfully')),
    );
    Navigator.of(context).pop(); // Close the dialog
  } else {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: User not deleted')),
    );
  }
}

class AddUserBottomSheet extends StatefulWidget {
  @override
  _AddUserBottomSheetState createState() => _AddUserBottomSheetState();
}

class _AddUserBottomSheetState extends State<AddUserBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();

    super.dispose();
  }

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('https://reqres.in/api/users'),
        body: addUser(firstNameController.text, lastNameController.text,
            emailController.text),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        // User added successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User added successfully')),
        );
        Navigator.of(context).pop(); // Close the bottom sheet
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not added')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter First Name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter Last Name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'email'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter email';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addUser,
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditUserBottomSheet extends StatefulWidget {
  final UserModel user;
  final int index;

  const EditUserBottomSheet({
    super.key,
    required this.user,
    required this.index,
  });

  @override
  _EditUserBottomSheetState createState() => _EditUserBottomSheetState();
}

class _EditUserBottomSheetState extends State<EditUserBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  late int index;

  @override
  void initState() {
    // TODO: implement initState
    index = widget.index;
    firstNameController.text = widget.user.data![index].firstName!;
    lastNameController.text = widget.user.data![index].lastName!;
    emailController.text = widget.user.data![index].email!;

    super.initState();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();

    super.dispose();
  }

  dynamic addUser(String firstName, String lastName, String email) {
    const String EMAIL = "email";
    const String FIRST_NAME = "first_name";
    const String LAST_NAME = "last_name";

    var json = jsonEncode(<String, dynamic>{
      EMAIL: email,
      FIRST_NAME: firstName,
      LAST_NAME: lastName
    });
    print("params =" + json.toString());
    return json;
  }

  Future<void> _editUser() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.put(
        Uri.parse('https://reqres.in/api/users/${index}'),
        body: addUser(firstNameController.text, lastNameController.text,
            emailController.text),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // User added successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated successfully')),
        );
        Navigator.of(context).pop(); // Close the bottom sheet
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User not updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter First Name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter Last Name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'email'),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter mail';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _editUser,
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final Function() onConfirm;

  ConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Delete'),
      content: Text('Are you sure you want to delete this user?'),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('No'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text('Yes'),
        ),
      ],
    );
  }
}
