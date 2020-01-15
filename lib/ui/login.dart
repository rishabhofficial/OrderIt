import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 90, bottom: 50, left: 50, right: 50),
              child: Image.asset('asset/Orderit.jpg'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 25, right: 25),
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                // controller: _textFieldController,
                decoration: new InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                labelText: "Email",
                  //errorText: _validate ? "*Required" : null,
                  fillColor: Colors.white,
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(5), 
                  borderSide: new BorderSide(),
  ),
  ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 25, left: 25, right: 25),
              child: TextField(
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                // controller: _textFieldController,
                decoration: new InputDecoration(
                  prefixIcon: Icon(Icons.vpn_key),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                labelText: "Password",
                  //errorText: _validate ? "*Required" : null,
                  fillColor: Colors.white,
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(5), 
                  //borderSide: new BorderSide(),
  ),
  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}