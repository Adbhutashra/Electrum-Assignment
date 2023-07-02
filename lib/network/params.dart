  import 'dart:convert';

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